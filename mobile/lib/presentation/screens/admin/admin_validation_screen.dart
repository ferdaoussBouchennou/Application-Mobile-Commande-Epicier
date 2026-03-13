import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../data/services/api_service.dart';
import '../../../data/models/user_model.dart';
import '../../../core/theme/app_theme.dart';
import '../../../providers/auth_provider.dart';
import '../auth/login_screen.dart';
import 'add_epicier_screen.dart';
import 'admin_orders_screen.dart';
import 'admin_categories_screen.dart';
import 'admin_epicier_profile_screen.dart';
import 'admin_disputes_screen.dart';

class AdminValidationScreen extends StatefulWidget {
  const AdminValidationScreen({super.key});

  @override
  State<AdminValidationScreen> createState() => _AdminValidationScreenState();
}

class _AdminValidationScreenState extends State<AdminValidationScreen> {
  final ApiService _apiService = ApiService();
  String _selectedFilter = 'Tous';
  String _selectedRole = 'Tous'; // 'Tous', 'CLIENT', 'EPICIER'
  bool _isLoading = true;
  
  int _pendingCount = 0;
  int _activeCount = 0;
  int _suspendedCount = 0;
  
  List<UserModel> _users = [];

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
    ]);
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _fetchStats() async {
    try {
      final stats = await _apiService.get('/admin/stats');
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

      final List<dynamic> data = await _apiService.get('/admin/users?status=$status&role=$roleParam');
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
      await _apiService.patch('/admin/users/$userId/status', {
        if (status != null) 'statut_inscription': status,
        if (isActive != null) 'is_active': isActive,
      });
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
                            if (_selectedRole == 'Tous' || _selectedRole == 'Épicier') ...[
                              _buildStatsRow(),
                              const SizedBox(height: 20),
                            ],
                            _buildFilterBar(),
                            const SizedBox(height: 20),
                            _buildStoreList(),
                            const SizedBox(height: 20),
                            if (_selectedRole == 'Tous' || _selectedRole == 'Épicier') ...[
                              _buildCreateAccountButton(),
                              const SizedBox(height: 100),
                            ]
                          ],
                        ),
                      ),
                    ),
                  ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      color: const Color(0xFF2D5016),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.store, color: Colors.white, size: 30),
                  SizedBox(width: 8),
                  Text(
                    'MyHanut',
                    style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF26444),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text('ADMIN', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.logout_rounded, color: Colors.white, size: 24),
                    onPressed: () {
                      context.read<AuthProvider>().logout();
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (_) => LoginScreen()),
                        (route) => false,
                      );
                    },
                    tooltip: 'Déconnexion',
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Validation comptes',
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
          ),
        ],
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Filtrer par statut :', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2D5016))),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: ['Tous', 'En attente', 'Actifs', 'Suspendus'].map((f) {
              final isSelected = _selectedFilter == f;
              return Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: FilterChip(
                  label: Text(f == 'En attente' ? 'En attente ($_pendingCount)' : f),
                  selected: isSelected,
                  onSelected: (val) {
                    setState(() => _selectedFilter = f);
                    _fetchUsers();
                  },
                  backgroundColor: Colors.white,
                  selectedColor: const Color(0xFF2D5016),
                  labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  showCheckmark: false,
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 12),
        const Text('Filtrer par type :', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2D5016))),
        const SizedBox(height: 8),
        Row(
          children: ['Tous', 'Client', 'Épicier'].map((r) {
            final isSelected = _selectedRole == r;
            return Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: FilterChip(
                label: Text(r),
                selected: isSelected,
                onSelected: (val) {
                  setState(() => _selectedRole = r);
                  _fetchUsers();
                },
                backgroundColor: Colors.white,
                selectedColor: const Color(0xFFF26444),
                labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                showCheckmark: false,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildStoreList() {
    if (_users.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Text('Aucun utilisateur trouvé.'),
      );
    }
    return Column(
      children: _users.map<Widget>((user) => _buildUserCard(user)).toList(),
    );
  }

  Widget _buildUserCard(UserModel user) {
    final bool isEpicier = user.role == 'EPICIER';
    final String storeName = user.store?['nom_boutique'] ?? user.fullName;
    final String address = user.store?['adresse'] ?? 'Client Standard';
    final String phone = user.store?['telephone'] ?? 'N/A';
    
    Color statusColor;
    String statusLabel;
    Color? textColor;
    List<Widget> actions = [];

    if (user.statutInscription == 'EN_ATTENTE') {
      statusColor = const Color(0xFFF2A93B).withOpacity(0.2);
      statusLabel = 'En attente';
      textColor = Colors.orange.shade800;
      actions = [
        _buildActionBtn('Valider', const Color(0xFF2D5016), Icons.check, onTap: () => _updateStatus(user.id, status: 'ACCEPTE', isActive: true)),
        const SizedBox(width: 8),
        _buildActionBtn('Refuser', const Color(0xFFFFEBEE), Icons.close, textColor: Colors.red, onTap: () => _updateStatus(user.id, status: 'REFUSE')),
        const SizedBox(width: 8),
        _buildActionBtn('Voir', const Color(0xFFF5EDDA), Icons.visibility, textColor: const Color(0xFF2D5016), onTap: () => _showDoc(user)),
      ];
    } else if (user.isActive) {
      statusColor = const Color(0xFFE8F5E9);
      statusLabel = 'Actif';
      textColor = const Color(0xFF4CBB5E);
      actions = [
        _buildActionBtn('Suspendre', const Color(0xFFFFEBEE), Icons.remove_circle_outline, textColor: Colors.red, onTap: () => _updateStatus(user.id, isActive: false)),
        const SizedBox(width: 8),
        _buildActionBtn('Voir profil', const Color(0xFFF5EDDA), Icons.visibility, textColor: const Color(0xFF2D5016), onTap: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => AdminEpicierProfileScreen(user: user)));
        }),
      ];
    } else {
      statusColor = const Color(0xFFFFEBEE);
      statusLabel = 'Suspendu';
      textColor = Colors.red;
      actions = [
        _buildActionBtn('Réactiver', const Color(0xFF2D5016), Icons.lock_open, onTap: () => _updateStatus(user.id, isActive: true)),
        const SizedBox(width: 8),
        _buildActionBtn('Voir profil', const Color(0xFFF5EDDA), Icons.visibility, textColor: const Color(0xFF2D5016), onTap: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => AdminEpicierProfileScreen(user: user)));
        }),
      ];
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: isEpicier ? const Color(0xFFFFEBEE) : const Color(0xFFE3F2FD),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isEpicier ? Icons.storefront : Icons.person,
                  color: isEpicier ? const Color(0xFFF26444) : Colors.blue,
                  size: 30
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(storeName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.location_on, size: 14, color: Colors.grey),
                        const SizedBox(width: 4),
                        Expanded(child: Text(address, style: const TextStyle(color: Colors.grey, fontSize: 13), overflow: TextOverflow.ellipsis)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.phone, size: 14, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(phone, style: const TextStyle(color: Colors.grey, fontSize: 13)),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  statusLabel,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(children: actions),
        ],
      ),
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
                user.docVerf!, // Need to handle relative paths if necessary
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

  Widget _buildCreateAccountButton() {
    return InkWell(
      onTap: () async {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AddEpicierScreen()),
        );
        if (result == true) {
          _loadData(); // Refresh list
        }
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFFF5EDDA).withOpacity(0.5),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF2D5016), style: BorderStyle.solid, width: 2),
        ),
        child: Column(
          children: [
            const Icon(Icons.add_circle, color: Color(0xFF2D5016), size: 40),
            const SizedBox(height: 12),
            const Text(
              'Créer un compte épicier',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2D5016)),
            ),
            Text(
              'Inscription manuelle par l\'admin',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNav() {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      currentIndex: 1,
      selectedItemColor: const Color(0xFF2D5016),
      unselectedItemColor: Colors.grey,
      onTap: (index) {
        if (index == 0) {
          Navigator.popUntil(context, (route) => route.isFirst);
        } else if (index == 2) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const AdminOrdersScreen()),
          );
        } else if (index == 3) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const AdminCategoriesScreen()),
          );
        } else if (index == 4) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const AdminDisputesScreen()),
          );
        }
      },
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Dashboard'),
        BottomNavigationBarItem(icon: Icon(Icons.store), label: 'Épiciers'),
        BottomNavigationBarItem(icon: Icon(Icons.shopping_cart), label: 'Commandes'),
        BottomNavigationBarItem(icon: Icon(Icons.category), label: 'Catégories'),
        BottomNavigationBarItem(icon: Icon(Icons.warning_amber_rounded), label: 'Litiges'),
      ],
    );
  }
}
