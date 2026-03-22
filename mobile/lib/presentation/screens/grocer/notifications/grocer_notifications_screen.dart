import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../../data/models/grocer_notification_model.dart';
import '../../../../data/services/api_service.dart';
import '../../../../providers/auth_provider.dart';
import '../grocer_theme.dart';

class GrocerNotificationsScreen extends StatefulWidget {
  const GrocerNotificationsScreen({
    super.key,
    this.onNavigateToOrders,
    this.onUnreadCount,
    this.onRegisterRefresh,
  });

  final VoidCallback? onNavigateToOrders;
  final void Function(int count)? onUnreadCount;
  final void Function(VoidCallback fn)? onRegisterRefresh;

  @override
  State<GrocerNotificationsScreen> createState() => _GrocerNotificationsScreenState();
}

class _GrocerNotificationsScreenState extends State<GrocerNotificationsScreen> {
  final ApiService _api = ApiService();
  List<GrocerNotificationModel> _notifications = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _load();
      widget.onRegisterRefresh?.call(_load);
    });
  }

  String? get _token => context.read<AuthProvider>().token;

  Future<void> _load() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final token = _token;
      final data = await _api.get('/epicier/notifications', token: token);
      final list = (data as List)
          .map((j) => GrocerNotificationModel.fromJson(j as Map<String, dynamic>))
          .toList();
      if (!mounted) return;
      setState(() {
        _notifications = list;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _markRead(int id) async {
    try {
      await _api.patch('/epicier/notifications/$id/read', {}, token: _token);
      if (!mounted) return;
      setState(() {
        final idx = _notifications.indexWhere((n) => n.id == id);
        if (idx != -1) _notifications[idx].lue = true;
        widget.onUnreadCount?.call(_notifications.where((n) => !n.lue).length);
      });
    } catch (_) {}
  }

  Future<void> _markAllRead() async {
    try {
      await _api.patch('/epicier/notifications/read-all', {}, token: _token);
      if (!mounted) return;
      setState(() {
        for (final n in _notifications) {
          n.lue = true;
        }
        widget.onUnreadCount?.call(0);
      });
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
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return 'À l\'instant';
    if (diff.inMinutes < 60) return 'Il y a ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'Il y a ${diff.inHours} h';
    if (diff.inDays < 7) return 'Il y a ${diff.inDays} j';
    return DateFormat('dd/MM/yyyy').format(date);
  }

  void _gotoOrders() {
    widget.onNavigateToOrders?.call();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (_notifications.any((n) => !n.lue)) _buildMarkAllBar(),
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
          Icon(Icons.check_circle_outline, size: 16, color: GrocerTheme.primary),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'Vous avez des notifications non lues',
              style: TextStyle(fontSize: 13, color: GrocerTheme.textDark),
            ),
          ),
          TextButton(
            onPressed: _markAllRead,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              foregroundColor: GrocerTheme.primary,
            ),
            child: const Text('Tout lire', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: GrocerTheme.primary),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.wifi_off_rounded, size: 64, color: Colors.grey.shade400),
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
                onPressed: _load,
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
      onRefresh: _load,
      color: GrocerTheme.primary,
      child: ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          ...grouped.entries
              .where((e) => e.value.isNotEmpty)
              .expand((e) => [
                    _buildSectionHeader(e.key),
                    ...e.value.map(_buildCard),
                  ]),
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
          _markRead(n.id);
          if (n.isOrderRelated) _gotoOrders();
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
                : Border.all(color: GrocerTheme.primary.withOpacity(0.3), width: 1.5),
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
                              fontWeight: n.lue ? FontWeight.w600 : FontWeight.bold,
                              color: GrocerTheme.textDark,
                            ),
                          ),
                        ),
                        if (!n.lue)
                          Container(
                            width: 9,
                            height: 9,
                            margin: const EdgeInsets.only(left: 6),
                            decoration: const BoxDecoration(
                              color: GrocerTheme.trendNegative,
                              shape: BoxShape.circle,
                            ),
                          ),
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
                        Icon(Icons.access_time_rounded,
                            size: 12, color: Colors.grey.shade500),
                        const SizedBox(width: 4),
                        Text(
                          _relativeTime(n.dateEnvoi),
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade500,
                          ),
                        ),
                        if (n.isOrderRelated) ...[
                          const SizedBox(width: 12),
                          GestureDetector(
                            onTap: () {
                              _markRead(n.id);
                              _gotoOrders();
                            },
                            child: const Text(
                              '→ Voir les commandes',
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
          const Text(
            'Aucune notification',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: GrocerTheme.textDark,
            ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 48),
            child: Text(
              'Vous serez alerté ici pour les nouvelles commandes, avis, réclamations et réponses de vos clients (acceptation/refus de produits).',
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
