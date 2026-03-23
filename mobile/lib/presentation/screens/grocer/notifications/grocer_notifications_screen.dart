import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../../data/models/grocer_notification_model.dart';
import '../../../../data/services/api_service.dart';
import '../../../../providers/auth_provider.dart';
import '../grocer_theme.dart';
import '../reclamations/grocer_reclamation_detail_screen.dart';

class GrocerNotificationsScreen extends StatefulWidget {
  const GrocerNotificationsScreen({
    super.key,
    this.onNavigateToOrders,
    this.onNavigateToOrder,
    this.onNavigateToProfileAvis,
    this.onUnreadCount,
    this.onRegisterRefresh,
  });

  final VoidCallback? onNavigateToOrders;
  final void Function(int orderId)? onNavigateToOrder;
  /// Onglet Profil + scroll vers la section « Avis des clients » (litiges type AVIS).
  final VoidCallback? onNavigateToProfileAvis;
  final void Function(int count)? onUnreadCount;
  final void Function(VoidCallback fn)? onRegisterRefresh;

  @override
  State<GrocerNotificationsScreen> createState() =>
      _GrocerNotificationsScreenState();
}

class _GrocerNotificationsScreenState extends State<GrocerNotificationsScreen>
    with SingleTickerProviderStateMixin {
  final ApiService _api = ApiService();
  List<GrocerNotificationModel> _notifications = [];
  bool _isLoading = true;
  String? _error;
  int _selectedTabIndex = 0; // 0 = Non lues, 1 = Historique
  late TabController _tabController;
  int _currentPage = 1;
  int _totalCount = 0;
  int _totalPages = 1;
  Timer? _timeUpdateTimer;
  static const int _pageSize = 20;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _load();
      widget.onRegisterRefresh?.call(_load);
    });
    _timeUpdateTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted && _notifications.isNotEmpty) setState(() {});
    });
  }

  @override
  void dispose() {
    _timeUpdateTimer?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  String? get _token => context.read<AuthProvider>().token;

  bool get _showUnreadOnly => _selectedTabIndex == 0;

  Future<void> _load({bool reset = false}) async {
    if (!mounted) return;
    if (reset) {
      _currentPage = 1;
    }
    setState(() {
      _isLoading = true;
      _error = null;
      if (reset) _notifications = [];
    });
    try {
      final token = _token;
      final lueParam = _showUnreadOnly ? '&lue=0' : '&lue=1';
      final data =
          await _api.get(
                '/epicier/notifications?page=$_currentPage&limit=$_pageSize$lueParam',
                token: token,
              )
              as Map<String, dynamic>;
      final items =
          (data['items'] as List<dynamic>?)
              ?.map(
                (j) =>
                    GrocerNotificationModel.fromJson(j as Map<String, dynamic>),
              )
              .toList() ??
          [];
      final pagination = data['pagination'] as Map<String, dynamic>?;
      final total = pagination?['total'] as int? ?? 0;
      final limit = (pagination?['limit'] as int?) ?? _pageSize;
      final totalPages = total > 0 ? (total + limit - 1) ~/ limit : 1;

      if (!mounted) return;

      if (total > 0 && _currentPage > totalPages) {
        setState(() => _currentPage = totalPages);
        await _load();
        return;
      }
      if (items.isEmpty && total > 0 && _currentPage > 1) {
        setState(() => _currentPage = 1);
        await _load();
        return;
      }

      setState(() {
        _notifications = items;
        _isLoading = false;
        _totalCount = total;
        _totalPages = totalPages;
      });
      _fetchUnreadCount();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _goToPreviousPage() async {
    if (_currentPage <= 1 || _isLoading) return;
    setState(() {
      _currentPage--;
      _notifications = [];
    });
    await _load();
  }

  Future<void> _goToNextPage() async {
    if (_currentPage >= _totalPages || _isLoading) return;
    setState(() {
      _currentPage++;
      _notifications = [];
    });
    await _load();
  }

  Future<void> _fetchUnreadCount() async {
    try {
      final data = await _api.get(
        '/epicier/notifications/unread-count',
        token: _token,
      );
      final count = (data as Map<String, dynamic>?)?['count'] as int? ?? 0;
      if (mounted) widget.onUnreadCount?.call(count);
    } catch (_) {}
  }

  Future<void> _markRead(int id) async {
    try {
      await _api.patch('/epicier/notifications/$id/read', {}, token: _token);
      if (!mounted) return;
      setState(() {
        final idx = _notifications.indexWhere((n) => n.id == id);
        if (idx != -1) {
          _notifications[idx].lue = true;
          if (_showUnreadOnly) {
            _notifications.removeAt(idx);
          }
        }
      });
      _fetchUnreadCount();
    } catch (_) {}
  }

  Future<void> _markAllRead() async {
    try {
      await _api.patch('/epicier/notifications/read-all', {}, token: _token);
      if (!mounted) return;
      setState(() {
        if (_showUnreadOnly) _notifications = [];
      });
      _fetchUnreadCount();
    } catch (_) {}
  }

  Map<String, List<GrocerNotificationModel>> _grouped() {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final yesterdayStart = todayStart.subtract(const Duration(days: 1));
    final groups = <String, List<GrocerNotificationModel>>{
      "AUJOURD'HUI": [],
      'HIER': [],
      'PLUS ANCIEN': [],
    };
    for (final n in _notifications) {
      if (!n.dateEnvoi.isBefore(todayStart)) {
        groups["AUJOURD'HUI"]!.add(n);
      } else if (!n.dateEnvoi.isBefore(yesterdayStart)) {
        groups['HIER']!.add(n);
      } else {
        groups['PLUS ANCIEN']!.add(n);
      }
    }
    return groups;
  }

  String _relativeTime(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.isNegative || diff.inSeconds < 60) return 'à l\'instant';
    final minutes = diff.inMinutes;
    final hours = diff.inHours;
    final days = diff.inDays;
    if (minutes < 60) return 'il y a $minutes min';
    if (hours < 24) return 'il y a $hours h';
    if (days < 7) return 'il y a $days j';
    return DateFormat('dd/MM/yyyy').format(date);
  }

  String _buildPaginationSummary() {
    final n = _notifications.length;
    final total = _totalCount;
    if (total <= 0) {
      return n == 0
          ? 'Aucune notification'
          : '$n notification${n > 1 ? 's' : ''}';
    }
    if (_totalPages <= 1) {
      return '$n sur $total';
    }
    return 'Page $_currentPage sur $_totalPages · $n sur $total';
  }

  Widget _buildPaginationBar() {
    final canPrev = _currentPage > 1 && !_isLoading;
    final canNext = _currentPage < _totalPages && !_isLoading;
    final showArrows = _totalPages > 1;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (showArrows)
          IconButton(
            tooltip: 'Page précédente',
            onPressed: canPrev ? _goToPreviousPage : null,
            icon: const Icon(Icons.chevron_left),
            color: GrocerTheme.primary,
            iconSize: 32,
          ),
        Flexible(
          child: Text(
            _buildPaginationSummary(),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: GrocerTheme.textMuted,
            ),
          ),
        ),
        if (showArrows)
          IconButton(
            tooltip: 'Page suivante',
            onPressed: canNext ? _goToNextPage : null,
            icon: const Icon(Icons.chevron_right),
            color: GrocerTheme.primary,
            iconSize: 32,
          ),
      ],
    );
  }

  void _gotoOrder(GrocerNotificationModel n) {
    final orderId = n.commandeId;
    if (orderId != null) {
      widget.onNavigateToOrder?.call(orderId);
    } else {
      widget.onNavigateToOrders?.call();
    }
  }

  void _gotoReclamation(GrocerNotificationModel n) {
    final reclamationId = n.reclamationId;
    if (reclamationId != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              GrocerReclamationDetailScreen(reclamationId: reclamationId),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TabBar(
          controller: _tabController,
          onTap: (i) {
            setState(() => _selectedTabIndex = i);
            _load(reset: true);
          },
          indicatorColor: GrocerTheme.primary,
          labelColor: GrocerTheme.primary,
          unselectedLabelColor: GrocerTheme.textMuted,
          tabs: const [
            Tab(text: 'Non lues'),
            Tab(text: 'Historique'),
          ],
        ),
        if (_showUnreadOnly && _notifications.any((n) => !n.lue))
          _buildMarkAllBar(),
        Expanded(child: _buildBody()),
      ],
    );
  }

  Widget _buildMarkAllBar() {
    return Container(
      color: GrocerTheme.primary.withOpacity(0.08),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Icon(
            Icons.check_circle_outline,
            size: 16,
            color: GrocerTheme.primary,
          ),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'Marquer tout comme lu',
              style: TextStyle(fontSize: 13, color: GrocerTheme.textDark),
            ),
          ),
          TextButton(
            onPressed: _markAllRead,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              foregroundColor: GrocerTheme.primary,
            ),
            child: const Text(
              'Tout lire',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading && _notifications.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: GrocerTheme.primary),
      );
    }

    if (_error != null && _notifications.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.wifi_off_rounded,
                size: 64,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: 16),
              const Text(
                'Impossible de charger les notifications',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: GrocerTheme.textDark,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => _load(reset: true),
                icon: const Icon(Icons.refresh),
                label: const Text('Réessayer'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: GrocerTheme.primary,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_notifications.isEmpty) return _buildEmpty();

    final grouped = _grouped();

    return RefreshIndicator(
      onRefresh: () => _load(reset: false),
      color: GrocerTheme.primary,
      child: ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          ...grouped.entries
              .where((e) => e.value.isNotEmpty)
              .expand(
                (e) => [
                  _buildSectionHeader(e.key),
                  ...e.value.map((n) => _buildCard(n)),
                ],
              ),
          if (_totalCount > 0 || _notifications.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 16, 8, 24),
              child: _buildPaginationBar(),
            ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
      child: Text(
        title,
        style: const TextStyle(
          color: GrocerTheme.textMuted,
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.3,
        ),
      ),
    );
  }

  Widget _buildCard(GrocerNotificationModel n) {
    return Dismissible(
      key: Key('notif_${n.id}'),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => _markRead(n.id),
      background: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: GrocerTheme.primary,
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.check, color: Colors.white, size: 24),
      ),
      child: GestureDetector(
        onTap: () {
          if (!n.lue) _markRead(n.id);
          if (n.isStatutReclamationAvis) {
            widget.onNavigateToProfileAvis?.call();
          } else if (n.isReclamationRelated && n.reclamationId != null) {
            _gotoReclamation(n);
          } else if (n.isOrderRelated) {
            _gotoOrder(n);
          }
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: n.lue ? Colors.white : GrocerTheme.primary.withOpacity(0.04),
            borderRadius: BorderRadius.circular(16),
            border: n.lue
                ? Border.all(color: GrocerTheme.border)
                : Border.all(
                    color: GrocerTheme.primary.withOpacity(0.3),
                    width: 1.5,
                  ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(n.lue ? 10 : 20),
                blurRadius: n.lue ? 6 : 12,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: n.iconBgColor,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(n.icon, color: n.iconColor, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            n.shortTitle,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: n.lue
                                  ? FontWeight.w600
                                  : FontWeight.bold,
                              color: GrocerTheme.textDark,
                            ),
                          ),
                        ),
                        if (!n.lue) ...[
                          TextButton(
                            onPressed: () => _markRead(n.id),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              minimumSize: Size.zero,
                              foregroundColor: GrocerTheme.primary,
                            ),
                            child: const Text(
                              'Marquer lu',
                              style: TextStyle(fontSize: 11),
                            ),
                          ),
                          Container(
                            width: 9,
                            height: 9,
                            margin: const EdgeInsets.only(left: 4),
                            decoration: const BoxDecoration(
                              color: GrocerTheme.trendNegative,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      n.message,
                      style: TextStyle(
                        fontSize: 13,
                        color: n.lue
                            ? GrocerTheme.textMuted
                            : GrocerTheme.textDark,
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.access_time_rounded,
                          size: 12,
                          color: Colors.grey.shade500,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _relativeTime(n.dateEnvoi),
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade500,
                          ),
                        ),
                        if (n.isStatutReclamationAvis) ...[
                          const SizedBox(width: 12),
                          GestureDetector(
                            onTap: () {
                              if (!n.lue) _markRead(n.id);
                              widget.onNavigateToProfileAvis?.call();
                            },
                            child: const Text(
                              '→ Voir AVIS',
                              style: TextStyle(
                                fontSize: 11,
                                color: GrocerTheme.primary,
                                fontWeight: FontWeight.bold,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        ] else if (n.isReclamationRelated &&
                            n.reclamationId != null) ...[
                          const SizedBox(width: 12),
                          GestureDetector(
                            onTap: () {
                              if (!n.lue) _markRead(n.id);
                              _gotoReclamation(n);
                            },
                            child: const Text(
                              '→ Voir réclamation',
                              style: TextStyle(
                                fontSize: 11,
                                color: GrocerTheme.primary,
                                fontWeight: FontWeight.bold,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        ] else if (n.isOrderRelated) ...[
                          const SizedBox(width: 12),
                          GestureDetector(
                            onTap: () {
                              if (!n.lue) _markRead(n.id);
                              _gotoOrder(n);
                            },
                            child: const Text(
                              '→ Voir commande',
                              style: TextStyle(
                                fontSize: 11,
                                color: GrocerTheme.primary,
                                fontWeight: FontWeight.bold,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 110,
            height: 110,
            decoration: BoxDecoration(
              color: GrocerTheme.primary.withOpacity(0.08),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(15),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Icon(
              Icons.notifications_none_rounded,
              size: 52,
              color: GrocerTheme.primary,
            ),
          ),
          const SizedBox(height: 28),
          Text(
            _showUnreadOnly
                ? 'Aucune notification non lue'
                : 'Aucune notification dans l\'historique',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: GrocerTheme.textDark,
            ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 48),
            child: Text(
              _showUnreadOnly
                  ? 'Vos nouvelles commandes, avis et réclamations apparaîtront ici.'
                  : 'Les notifications lues sont affichées ici.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: GrocerTheme.textMuted,
                height: 1.6,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
