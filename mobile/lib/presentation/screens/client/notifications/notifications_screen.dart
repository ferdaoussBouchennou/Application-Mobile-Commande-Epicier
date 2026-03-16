import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../../data/models/notification_model.dart';
import '../../../../data/services/api_service.dart';
import '../../../../providers/auth_provider.dart';

/// NotificationsScreen — fetches real notifications from the backend
/// and displays them grouped by date.
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final ApiService _api = ApiService();
  List<NotificationModel> _notifications = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  String? get _token =>
      context.read<AuthProvider>().token;

  // ── Data loading ──────────────────────────────────────────────────────────

  Future<void> _load() async {
    if (!mounted) return;
    setState(() { _isLoading = true; _error = null; });
    try {
      final token = _token;
      final data = await _api.get('/notifications', token: token);
      final list = (data as List)
          .map((j) => NotificationModel.fromJson(j as Map<String, dynamic>))
          .toList();
      if (!mounted) return;
      setState(() { _notifications = list; _isLoading = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  Future<void> _markRead(int id) async {
    try {
      await _api.patch('/notifications/$id/read', {}, token: _token);
      if (!mounted) return;
      setState(() {
        final idx = _notifications.indexWhere((n) => n.id == id);
        if (idx != -1) _notifications[idx].lue = true;
      });
    } catch (_) {}
  }

  Future<void> _markAllRead() async {
    try {
      await _api.patch('/notifications/read-all', {}, token: _token);
      if (!mounted) return;
      setState(() {
        for (final n in _notifications) {
          n.lue = true;
        }
      });
    } catch (_) {}
  }

  // ── Grouping helpers ──────────────────────────────────────────────────────

  Map<String, List<NotificationModel>> _grouped() {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final yesterdayStart = todayStart.subtract(const Duration(days: 1));
    final groups = <String, List<NotificationModel>>{
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

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Top action bar — "Tout marquer comme lu"
        if (_notifications.any((n) => !n.lue))
          _buildMarkAllBar(),
        Expanded(child: _buildBody()),
      ],
    );
  }

  Widget _buildMarkAllBar() {
    return Container(
      color: const Color(0xFFF5EBE0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          const Icon(Icons.check_circle_outline, size: 16, color: Color(0xFF2D5016)),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'Vous avez des notifications non lues',
              style: TextStyle(fontSize: 13, color: Color(0xFF4A3728)),
            ),
          ),
          TextButton(
            onPressed: _markAllRead,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              foregroundColor: const Color(0xFF2D5016),
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
        child: CircularProgressIndicator(color: Color(0xFF2D5016)),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.wifi_off_rounded, size: 64, color: Color(0xFFCCBBAA)),
              const SizedBox(height: 16),
              const Text(
                'Impossible de charger les notifications',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF4A3728),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12, color: Color(0xFF999999)),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _load,
                icon: const Icon(Icons.refresh),
                label: const Text('Réessayer'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2D5016),
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
      color: const Color(0xFF2D5016),
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
          color: Color(0xFF8B7355),
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.3,
        ),
      ),
    );
  }

  Widget _buildCard(NotificationModel n) {
    return Dismissible(
      key: Key('notif_${n.id}'),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => _markRead(n.id),
      background: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFF2D5016),
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.check, color: Colors.white, size: 24),
      ),
      child: GestureDetector(
        onTap: () => _markRead(n.id),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: n.lue ? Colors.white : const Color(0xFFFFF8F0),
            borderRadius: BorderRadius.circular(16),
            border: n.lue
                ? Border.all(color: const Color(0xFFEEE5D8))
                : Border.all(color: const Color(0xFFFFB366), width: 1.5),
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
              // Icon
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
              // Content
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
                              color: const Color(0xFF1A1A1A),
                            ),
                          ),
                        ),
                        if (!n.lue)
                          Container(
                            width: 9,
                            height: 9,
                            margin: const EdgeInsets.only(left: 6),
                            decoration: const BoxDecoration(
                              color: Color(0xFFFF6B35),
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
                            ? const Color(0xFF777777)
                            : const Color(0xFF333333),
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.access_time_rounded,
                            size: 12, color: Color(0xFFAAAAAA)),
                        const SizedBox(width: 4),
                        Text(
                          _relativeTime(n.dateEnvoi),
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFFAAAAAA),
                          ),
                        ),
                        if (n.isOrderReady) ...[
                          const SizedBox(width: 12),
                          const Text(
                            '→ Voir mes commandes',
                            style: TextStyle(
                              fontSize: 11,
                              color: Color(0xFF2D5016),
                              fontWeight: FontWeight.w700,
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
              color: const Color(0xFFF0EAE2),
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
              color: Color(0xFF2D5016),
            ),
          ),
          const SizedBox(height: 28),
          const Text(
            'Aucune notification',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D2D2D),
            ),
          ),
          const SizedBox(height: 10),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 48),
            child: Text(
              'Vous serez alerté ici dès qu\'un épicier met à jour le statut de votre commande.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF8B7355),
                height: 1.6,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
