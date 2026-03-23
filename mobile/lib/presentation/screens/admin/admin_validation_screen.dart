import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../data/services/api_service.dart';
import '../../../data/models/user_model.dart';
import '../../../core/theme/app_theme.dart';
import '../../../providers/auth_provider.dart';
import '../../../screens/auth/welcome_screen.dart';
import 'add_epicier_screen.dart';
import 'admin_orders_screen.dart';
import 'admin_categories_screen.dart';
import 'admin_epicier_profile_screen.dart';
import 'admin_disputes_screen.dart';
import 'admin_store_catalogue_screen.dart';
import '../../../core/constants/api_constants.dart';
import '../../widgets/admin/admin_bottom_nav.dart';
import 'admin_notifications_screen.dart';
import '../../../providers/notification_provider.dart';
import '../../widgets/admin/admin_header.dart';

class AdminValidationScreen extends StatefulWidget {
  const AdminValidationScreen({super.key});

  @override
  State<AdminValidationScreen> createState() => _AdminValidationScreenState();
}

class _AdminValidationScreenState extends State<AdminValidationScreen> {
  final ApiService _apiService = ApiService();
  final TextEditingController _searchController = TextEditingController();
  String _selectedFilter = 'Tous';
  String _selectedRole = 'Client'; // Default to Client as requested "lorsque je la coche une autre fois je vois les epicier"
  bool _isLoading = true;
  
  int _pendingCount = 0;
  int _activeCount = 0;
  int _suspendedCount = 0;
  
  List<UserModel> _users = [];
  int _currentPage = 0;
  static const int _usersPerPage = 5;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    await Future.wait([
      _fetchStats(),
      _fetchUsers(),
      Provider.of<NotificationProvider>(context, listen: false).fetchNotifications(
        Provider.of<AuthProvider>(context, listen: false).token
      ),
    ]);
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _fetchStats() async {
    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final token = auth.token;
      debugPrint('AdminValidationScreen DEBUG: FETCH STATS token=$token, isLoggedIn=${auth.isLoggedIn}');
      
      String roleParam = '';
      if (_selectedRole == 'Client') roleParam = 'CLIENT';
      else if (_selectedRole == 'Épicier') roleParam = 'EPICIER';

      final stats = await _apiService.get('/admin/stats?role=$roleParam', token: token);
      if (mounted) {
        setState(() {
          _pendingCount = stats['pending'];
          _activeCount = stats['active'];
          _suspendedCount = stats['suspended'];
        });
      }
    } catch (e) {
      debugPrint('Error fetching stats: $e');
    }
  }

  Future<void> _fetchUsers() async {
    try {
      String status = '';
      if (_selectedFilter == 'En attente') status = 'EN_ATTENTE';
      else if (_selectedFilter == 'Actifs') status = 'Actif';
      else if (_selectedFilter == 'Suspendus') status = 'Suspendu';

      String roleParam = '';
      if (_selectedRole == 'Client') roleParam = 'CLIENT';
      else if (_selectedRole == 'Épicier') roleParam = 'EPICIER';

      final String search = _searchController.text.trim();
      final token = Provider.of<AuthProvider>(context, listen: false).token;

      final List<dynamic> data = await _apiService.get('/admin/users?status=$status&role=$roleParam&search=$search', token: token);
      if (mounted) {
        setState(() {
          _users = data.map((json) => UserModel.fromJson(json)).toList();
        });
      }
    } catch (e) {
      debugPrint('Error fetching users: $e');
    }
  }

  Future<void> _updateStatus(int userId, {String? status, bool? isActive}) async {
    try {
      final token = Provider.of<AuthProvider>(context, listen: false).token;
      await _apiService.patch('/admin/users/$userId/status', {
        if (status != null) 'statut_inscription': status,
        if (isActive != null) 'is_active': isActive,
      }, token: token);
      _loadData(); // Reload everything
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDF6F0),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: _isLoading 
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF2D5016)))
                : RefreshIndicator(
                    onRefresh: _loadData,
                    color: const Color(0xFF2D5016),
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            _buildRoleToggle(),
                            const SizedBox(height: 16),
                            if (_selectedRole == 'Épicier') ...[
                              _buildStatsRow(),
                              const SizedBox(height: 20),
                            ],
                            _buildFilterBar(),
                            const SizedBox(height: 20),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  _selectedRole == 'Client' ? 'Clients' : 'Épiceries',
                                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF2D1A0E), fontFamily: 'Outfit'),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            _buildStoreList(),
                            const SizedBox(height: 100),
                          ],
                        ),
                      ),
                    ),
                  ),
            ),
          ],
        ),
      ),
      floatingActionButton: _selectedRole == 'Épicier' ? FloatingActionButton.extended(
        backgroundColor: const Color(0xFF2D5016),
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddEpicierScreen()),
          );
          if (result == true) _loadData();
        },
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Ajouter', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ) : null,
      bottomNavigationBar: const AdminBottomNav(currentIndex: 1),
    );
  }

  Widget _buildHeader() {
    return AdminHeader(
      title: _selectedRole == 'Client' ? 'Gestion des clients' : 'Gestion des épiceries',
      showSearchBar: true,
      searchHint: _selectedRole == 'Client' ? 'Rechercher un client...' : 'Rechercher une épicerie...',
      searchController: _searchController,
      onSearch: (val) {
        setState(() => _currentPage = 0);
        _fetchUsers();
      },
    );
  }

  Widget _buildRoleToggle() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF5EDDA),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        children: [
          _buildToggleOption('Client', _selectedRole == 'Client'),
          _buildToggleOption('Épicier', _selectedRole == 'Épicier'),
        ],
      ),
    );
  }

  Widget _buildToggleOption(String label, bool isSelected) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedRole = label;
            _currentPage = 0;
            _loadData();
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF2D5016) : Colors.transparent,
            borderRadius: BorderRadius.circular(25),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : const Color(0xFF2D5016),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatsRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildStatCard(_pendingCount.toString(), 'En attente', const Color(0xFFF2A93B)),
        _buildStatCard(_activeCount.toString(), 'Actifs', const Color(0xFF4CBB5E)),
        _buildStatCard(_suspendedCount.toString(), 'Suspendus', const Color(0xFFF26444)),
      ],
    );
  }

  Widget _buildStatCard(String count, String label, Color color) {
    return Container(
      width: (MediaQuery.of(context).size.width - 48) / 3,
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Column(
        children: [
          Text(
            count,
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: ['Tous', 'En attente', 'Actifs', 'Suspendus'].map((f) {
          final isSelected = _selectedFilter == f;
          String label = f;
          if (f == 'En attente') label = 'En attente ($_pendingCount)';
          else if (f == 'Actifs') label = 'Actives ($_activeCount)'; // Match image plural
          else if (f == 'Suspendus') label = 'Inactives ($_suspendedCount)'; // Match image style
          else if (f == 'Tous') label = 'Toutes (${_pendingCount + _activeCount + _suspendedCount})';

          return Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: ChoiceChip(
              label: Text(label),
              selected: isSelected,
              onSelected: (val) {
                setState(() {
                  _selectedFilter = f;
                  _currentPage = 0;
                });
                _fetchUsers();
              },
              backgroundColor: Colors.white,
              selectedColor: const Color(0xFF2D5016),
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : Colors.black87,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(color: isSelected ? Colors.transparent : Colors.grey.shade200),
              ),
              showCheckmark: false,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildStoreList() {
    if (_users.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Text('Aucun utilisateur trouvé.'),
      );
    }
    final int totalPages = (_users.length / _usersPerPage).ceil();
    final int start = _currentPage * _usersPerPage;
    final int end = (start + _usersPerPage < _users.length) 
        ? start + _usersPerPage 
        : _users.length;
    final List<UserModel> paginatedUsers = _users.sublist(start, end);

    return Column(
      children: [
        ...paginatedUsers.map<Widget>((user) => _buildUserCard(user)).toList(),
        if (totalPages > 1)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: Icon(Icons.arrow_back_ios, size: 18, color: _currentPage > 0 ? const Color(0xFF2D5016) : Colors.grey),
                  onPressed: _currentPage > 0 ? () => setState(() => _currentPage--) : null,
                ),
                Text(
                  'Page ${_currentPage + 1} sur $totalPages',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF2D5016)),
                ),
                IconButton(
                  icon: Icon(Icons.arrow_forward_ios, size: 18, color: _currentPage < totalPages - 1 ? const Color(0xFF2D5016) : Colors.grey),
                  onPressed: _currentPage < totalPages - 1 ? () => setState(() => _currentPage++) : null,
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildUserCard(UserModel user) {
    if (_selectedRole == 'Épicier') {
      return _buildEpicierCard(user);
    }
    
    // Default Client Card (Simplified for now or kept as is)
    final String name = user.fullName;
    final String email = user.email;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 25,
                backgroundColor: Colors.blue.withOpacity(0.1),
                child: const Icon(Icons.person, color: Colors.blue),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    Text(email, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                  ],
                ),
              ),
              _buildStatusBadge(user),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Spacer(),
              _buildActionBtn(
                user.isActive ? 'Désactiver le compte' : 'Activer le compte', 
                user.isActive ? const Color(0xFFFFEBEE) : const Color(0xFF2D5016),
                user.isActive ? Icons.remove_circle_outline : Icons.lock_open,
                textColor: user.isActive ? Colors.red : Colors.white,
                onTap: () => _updateStatus(user.id, isActive: !user.isActive),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEpicierCard(UserModel user) {
    final String storeName = user.store?['nom_boutique'] ?? user.fullName;
    final String address = user.store?['adresse'] ?? 'Lieu non renseigné';
    final String ownerName = user.fullName;
    final String? imageUrl = user.store?['image_url'];
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Thumbnail
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  color: const Color(0xFFFDF6F0),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: imageUrl != null 
                    ? Image.network(
                        ApiConstants.formatImageUrl(imageUrl),
                        fit: BoxFit.cover,
                        errorBuilder: (_,__,___) => const Icon(Icons.store, color: Color(0xFFF26444), size: 35),
                      )
                    : const Icon(Icons.store, color: Color(0xFFF26444), size: 35),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            storeName, 
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2D1A0E), fontFamily: 'Outfit'),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        _buildStatusBadge(user),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.location_on_rounded, size: 14, color: Color(0xFFF26444)),
                        const SizedBox(width: 4),
                        Expanded(child: Text(address, style: TextStyle(color: Colors.grey.shade600, fontSize: 13), overflow: TextOverflow.ellipsis)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.person_rounded, size: 14, color: Color(0xFF2D5016)),
                        const SizedBox(width: 4),
                        Text(ownerName, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Stats row
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFFDF6F0),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatColumn(user.produitsCount.toString(), 'Produits'),
                _buildStatColumn(user.commandesCount.toString(), 'Commandes'),
                _buildStatColumn(user.rating.toStringAsFixed(1), 'Note', isRating: true),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Actions row
          Row(
            children: user.statutInscription == 'EN_ATTENTE'
              ? [
                  _buildActionBtn('Profil', const Color(0xFFF5EDDA), Icons.person_search_outlined, textColor: const Color(0xFF2D1A0E), onTap: () async {
                    final result = await Navigator.push(
                      context, 
                      MaterialPageRoute(builder: (_) => AdminEpicierProfileScreen(user: user))
                    );
                    if (result == true) {
                      _loadData();
                    }
                  }),
                  const SizedBox(width: 8),
                  _buildActionBtn('Accepter', const Color(0xFFE8F5E9), Icons.check_circle_outline, textColor: const Color(0xFF4CBB5E), onTap: () {
                    _updateStatus(user.id, isActive: true, status: 'ACCEPTE');
                  }),
                  const SizedBox(width: 8),
                  _buildActionBtn('Refuser', const Color(0xFFFFEBEE), Icons.cancel_outlined, textColor: Colors.red, onTap: () {
                    _updateStatus(user.id, isActive: false, status: 'REFUSE');
                  }),
                ]
              : [
                  _buildActionBtn('Catalogue', const Color(0xFF2D5016), Icons.category_outlined, onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => AdminStoreCatalogueScreen(storeOwner: user)),
                    ).then((_) => _loadData());
                  }),
                  const SizedBox(width: 8),
                  _buildActionBtn('Modifier', const Color(0xFFF5EDDA), Icons.edit_outlined, textColor: const Color(0xFF2D1A0E), onTap: () async {
                    final result = await Navigator.push(
                      context, 
                      MaterialPageRoute(builder: (_) => AdminEpicierProfileScreen(user: user))
                    );
                    if (result == true) {
                      _loadData();
                    }
                  }),
                  const SizedBox(width: 8),
                  _buildActionBtn(
                    user.isActive ? 'Désact.' : 'Activer', 
                    user.isActive ? const Color(0xFFFFEBEE) : const Color(0xFF2D5016),
                    user.isActive ? Icons.remove_circle_outline : Icons.lock_open,
                    textColor: user.isActive ? Colors.red : Colors.white,
                    onTap: () => _updateStatus(user.id, isActive: !user.isActive),
                  ),
                ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(UserModel user) {
    Color bg;
    Color text;
    String label;

    if (user.statutInscription == 'EN_ATTENTE') {
      bg = Colors.orange.shade50;
      text = Colors.orange.shade700;
      label = 'En attente';
    } else if (user.isActive) {
      bg = const Color(0xFFE8F5E9);
      text = const Color(0xFF4CBB5E);
      label = 'Actif';
    } else {
      bg = const Color(0xFFFFEBEE);
      text = Colors.red;
      label = 'Inactif';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(color: text, fontSize: 12, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildStatColumn(String count, String label, {bool isRating = false}) {
    return Column(
      children: [
        Row(
          children: [
            Text(count, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF2D1A0E))),
            if (isRating) ...[
              const SizedBox(width: 2),
              const Icon(Icons.star, size: 16, color: Colors.orange),
            ],
          ],
        ),
        Text(label, style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
      ],
    );
  }

  Widget _buildActionBtn(String label, Color bg, IconData icon, {Color? textColor, VoidCallback? onTap}) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: textColor ?? Colors.white),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  color: textColor ?? Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDoc(UserModel user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Document de vérification'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (user.docVerf != null && user.docVerf!.isNotEmpty)
              Image.network(
                ApiConstants.formatImageUrl(user.docVerf),
                errorBuilder: (_, __, ___) => const Icon(Icons.description, size: 100, color: Colors.grey),
              )
            else
              const Text('Aucun document fourni.'),
            const SizedBox(height: 20),
            Text('Demandeur: ${user.fullName}'),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Fermer')),
        ],
      ),
    );
  }


}
