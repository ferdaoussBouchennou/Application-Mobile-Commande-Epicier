import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../data/models/grocer_order.dart';
import '../../../../data/services/api_service.dart';
import '../../../../providers/auth_provider.dart';
import '../grocer_theme.dart';

/// Écran Mes Commandes — onglets Nouvelles / Prêtes.
/// Badge nouvelles commandes, acceptation/refus, bon de préparation, confirmation récupération.
class GrocerOrdersScreen extends StatefulWidget {
  final void Function(int)? onNewOrdersCount;
  final int? orderIdToOpen;
  final VoidCallback? onOpenOrderHandled;
  final void Function(VoidCallback fn)? onRegisterRefresh;

  const GrocerOrdersScreen({
    super.key,
    this.onNewOrdersCount,
    this.orderIdToOpen,
    this.onOpenOrderHandled,
    this.onRegisterRefresh,
  });

  @override
  State<GrocerOrdersScreen> createState() => _GrocerOrdersScreenState();
}

class _GrocerOrdersScreenState extends State<GrocerOrdersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ApiService _api = ApiService();
  Timer? _pollTimer;

  static const List<String> _tabLabels = [
    'Nouvelles',
    'Prêtes',
    'Historique',
  ];
  static const List<String> _statuts = ['reçue', 'prête', 'historique'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, initialIndex: 0, vsync: this);
    _fetchNewCount();
    _pollTimer = Timer.periodic(const Duration(seconds: 30), (_) => _fetchNewCount());
    widget.onRegisterRefresh?.call(_fetchNewCount);
    WidgetsBinding.instance.addPostFrameCallback((_) => _openTicketIfNeeded());
  }

  @override
  void didUpdateWidget(covariant GrocerOrdersScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.orderIdToOpen != oldWidget.orderIdToOpen && widget.orderIdToOpen != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _openTicketIfNeeded());
    }
  }

  Future<void> _openTicketIfNeeded() async {
    final orderId = widget.orderIdToOpen;
    if (orderId == null || !mounted) return;
    final token = context.read<AuthProvider>().token;
    if (token == null) return;
    widget.onOpenOrderHandled?.call();
    final detail = await _fetchOrderDetail(token, orderId);
    if (!mounted || detail == null) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _TicketSheet(
        orderId: orderId,
        initialDetail: detail,
        fetchDetail: (id) => _fetchOrderDetail(token, id),
        markRupture: (id, detailId) => _markRupture(token, id, detailId),
        onAction: _onOrderAction,
      ),
    );
    _onOrderAction();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchNewCount() async {
    final token = context.read<AuthProvider>().token;
    if (token == null) return;
    try {
      final data = await _api.get('/epicier/commandes/count-new', token: token);
      final count = (data as Map<String, dynamic>?)?['count'] as int? ?? 0;
      if (mounted) {
        widget.onNewOrdersCount?.call(count);
      }
    } catch (_) {}
  }

  Future<List<GrocerOrder>> _fetchOrders(String? token, String statut) async {
    if (token == null) return [];
    final list = await _api.get(
      '/epicier/commandes?statut=$statut',
      token: token,
    ) as List<dynamic>?;
    return list
            ?.map((e) => GrocerOrder.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList() ??
        [];
  }

  Future<GrocerOrderDetail?> _fetchOrderDetail(String? token, int orderId) async {
    if (token == null) return null;
    try {
      final data = await _api.get('/epicier/commandes/$orderId', token: token);
      return GrocerOrderDetail.fromJson(Map<String, dynamic>.from(data as Map));
    } catch (_) {
      return null;
    }
  }

  Future<void> _acceptOrder(String? token, int orderId) async {
    if (token == null) return;
    await _api.post('/epicier/commandes/$orderId/accepter', {}, token: token);
  }

  Future<void> _refuseOrder(String? token, int orderId, String message) async {
    if (token == null) return;
    await _api.post(
      '/epicier/commandes/$orderId/refuser',
      {'message': message},
      token: token,
    );
  }

  Future<void> _updateStatut(String? token, int orderId, String statut) async {
    if (token == null) return;
    await _api.patch(
      '/epicier/commandes/$orderId/statut',
      {'statut': statut},
      token: token,
    );
  }

  Future<void> _markRupture(String? token, int orderId, int detailId) async {
    if (token == null) return;
    await _api.patch(
      '/epicier/commandes/$orderId/items/$detailId/rupture',
      {},
      token: token,
    );
  }

  void _onOrderAction() {
    _fetchNewCount();
  }

  @override
  Widget build(BuildContext context) {
    final token = context.watch<AuthProvider>().token;
    // On évite un Scaffold/AppBar interne pour ne pas ajouter une hauteur
    // supplémentaire (GrocerMainScreen a déjà un AppBar).
    return SafeArea(
      top: false,
      child: Container(
        color: GrocerTheme.background,
        child: Column(
          children: [
            Material(
              color: GrocerTheme.primary,
              elevation: 0,
              child: TabBar(
                controller: _tabController,
                indicatorColor: Colors.white,
                indicatorWeight: 3,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white70,
                labelStyle: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
                tabs: _tabLabels.map((l) => Tab(text: l)).toList(),
              ),
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _OrdersList(
                    token: token,
                    statut: 'reçue',
                    fetchOrders: () => _fetchOrders(token, 'reçue'),
                    fetchDetail: (id) => _fetchOrderDetail(token, id),
                    acceptOrder: (id) => _acceptOrder(token, id),
                    refuseOrder: (id, msg) => _refuseOrder(token, id, msg),
                    updateStatut: (id, s) => _updateStatut(token, id, s),
                    markRupture: (id, detailId) =>
                        _markRupture(token, id, detailId),
                    onAction: _onOrderAction,
                  ),
                  _OrdersList(
                    token: token,
                    statut: 'prête',
                    fetchOrders: () => _fetchOrders(token, 'prête'),
                    fetchDetail: (id) => _fetchOrderDetail(token, id),
                    acceptOrder: (id) => _acceptOrder(token, id),
                    refuseOrder: (id, msg) => _refuseOrder(token, id, msg),
                    updateStatut: (id, s) => _updateStatut(token, id, s),
                    markRupture: (id, detailId) =>
                        _markRupture(token, id, detailId),
                    onAction: _onOrderAction,
                  ),
                  _HistoriqueWithFilter(
                    token: token,
                    fetchOrders: (statut) => _fetchOrders(token, statut),
                    fetchDetail: (id) => _fetchOrderDetail(token, id),
                    acceptOrder: (id) => _acceptOrder(token, id),
                    refuseOrder: (id, msg) => _refuseOrder(token, id, msg),
                    updateStatut: (id, s) => _updateStatut(token, id, s),
                    markRupture: (id, detailId) =>
                        _markRupture(token, id, detailId),
                    onAction: _onOrderAction,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HistoriqueWithFilter extends StatefulWidget {
  final String? token;
  final Future<List<GrocerOrder>> Function(String statut) fetchOrders;
  final Future<GrocerOrderDetail?> Function(int) fetchDetail;
  final Future<void> Function(int orderId) acceptOrder;
  final Future<void> Function(int, String) refuseOrder;
  final Future<void> Function(int, String) updateStatut;
  final Future<void> Function(int, int) markRupture;
  final VoidCallback onAction;

  const _HistoriqueWithFilter({
    required this.token,
    required this.fetchOrders,
    required this.fetchDetail,
    required this.acceptOrder,
    required this.refuseOrder,
    required this.updateStatut,
    required this.markRupture,
    required this.onAction,
  });

  @override
  State<_HistoriqueWithFilter> createState() => _HistoriqueWithFilterState();
}

class _HistoriqueWithFilterState extends State<_HistoriqueWithFilter> {
  int _filterIndex = 0; // 0=tous, 1=refusee, 2=recuperer
  static const List<String> _filterLabels = ['Tous', 'Refusée', 'Récupérées'];
  static const List<String> _filterStatuts = ['historique', 'refusee', 'livrée'];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Row(
            children: List.generate(_filterLabels.length, (i) {
              final selected = _filterIndex == i;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(_filterLabels[i]),
                  selected: selected,
                  onSelected: (_) => setState(() {
                    _filterIndex = i;
                  }),
                  backgroundColor: Colors.white,
                  selectedColor: GrocerTheme.primary.withOpacity(0.2),
                  checkmarkColor: GrocerTheme.primary,
                  labelStyle: TextStyle(
                    color: selected ? GrocerTheme.primary : GrocerTheme.textMuted,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              );
            }),
          ),
        ),
        Expanded(
          child: _OrdersList(
            key: ValueKey(_filterStatuts[_filterIndex]),
            token: widget.token,
            statut: _filterStatuts[_filterIndex],
            fetchOrders: () => widget.fetchOrders(_filterStatuts[_filterIndex]),
            fetchDetail: widget.fetchDetail,
            acceptOrder: widget.acceptOrder,
            refuseOrder: widget.refuseOrder,
            updateStatut: widget.updateStatut,
            markRupture: widget.markRupture,
            onAction: widget.onAction,
          ),
        ),
      ],
    );
  }
}

class _OrdersList extends StatefulWidget {
  final String? token;
  final String statut;
  final Future<List<GrocerOrder>> Function() fetchOrders;
  final Future<GrocerOrderDetail?> Function(int) fetchDetail;
  final Future<void> Function(int orderId) acceptOrder;
  final Future<void> Function(int, String) refuseOrder;
  final Future<void> Function(int, String) updateStatut;
  final Future<void> Function(int, int) markRupture;
  final VoidCallback onAction;

  const _OrdersList({
    super.key,
    required this.token,
    required this.statut,
    required this.fetchOrders,
    required this.fetchDetail,
    required this.acceptOrder,
    required this.refuseOrder,
    required this.updateStatut,
    required this.markRupture,
    required this.onAction,
  });

  @override
  State<_OrdersList> createState() => _OrdersListState();
}

class _OrdersListState extends State<_OrdersList> {
  List<GrocerOrder> _orders = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await widget.fetchOrders();
      if (mounted) {
        setState(() {
          _orders = list;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceFirst('Exception: ', '');
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.token == null) {
      return const Center(
        child: Text('Connectez-vous pour voir vos commandes.'),
      );
    }
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: GrocerTheme.primary),
      );
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: GrocerTheme.trendNegative)),
              const SizedBox(height: 16),
              TextButton.icon(
                onPressed: _load,
                icon: const Icon(Icons.refresh),
                label: const Text('Réessayer'),
              ),
            ],
          ),
        ),
      );
    }
    if (_orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long_outlined, size: 56, color: GrocerTheme.primary.withValues(alpha: 0.6)),
            const SizedBox(height: 16),
            Text(
              'Aucune commande',
              style: TextStyle(fontSize: 16, color: GrocerTheme.textMuted),
            ),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      color: GrocerTheme.primary,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
        itemCount: _orders.length,
        itemBuilder: (context, index) => _OrderCard(
          order: _orders[index],
          statut: widget.statut,
          onAction: () {
            _load();
            widget.onAction();
          },
          fetchDetail: widget.fetchDetail,
          acceptOrder: widget.acceptOrder,
          refuseOrder: widget.refuseOrder,
          updateStatut: widget.updateStatut,
          markRupture: widget.markRupture,
        ),
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final GrocerOrder order;
  final String statut;
  final VoidCallback onAction;
  final Future<GrocerOrderDetail?> Function(int) fetchDetail;
  final Future<void> Function(int) acceptOrder;
  final Future<void> Function(int, String) refuseOrder;
  final Future<void> Function(int, String) updateStatut;
  final Future<void> Function(int, int) markRupture;

  const _OrderCard({
    required this.order,
    required this.statut,
    required this.onAction,
    required this.fetchDetail,
    required this.acceptOrder,
    required this.refuseOrder,
    required this.updateStatut,
    required this.markRupture,
  });

  static String _formatPrice(double v) => v.toStringAsFixed(2).replaceAll('.', ',');

  @override
  Widget build(BuildContext context) {
    final isRecue = order.statut == 'reçue';
    final isPrete = order.statut == 'prête';
    final isLivree = order.statut == 'livrée';

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 2,
      shadowColor: Colors.black12,
      color: const Color(0xFFF8F4EE),
      child: InkWell(
        onTap: () => _showTicket(context),
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '#CMD-${order.id}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: GrocerTheme.textDark,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(Icons.person_outline, size: 16, color: GrocerTheme.textMuted),
                            const SizedBox(width: 6),
                            Text(
                              'Client : ${order.clientDisplay}',
                              style: TextStyle(fontSize: 14, color: GrocerTheme.textMuted),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${order.articleCount} article${order.articleCount > 1 ? 's' : ''} · ${_formatPrice(order.montantTotal)} MAD · Créneau ${order.creneau}',
                          style: TextStyle(fontSize: 13, color: GrocerTheme.textMuted),
                        ),
                      ],
                    ),
                  ),
                  _StatusChip(statut: order.statut),
                ],
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (isRecue) ...[
                    if ((!order.hasRupture || order.clientAccepteModification) && !order.hasPendingAcceptance)
                      _ActionButton(
                        label: 'Accepter',
                        icon: Icons.check_circle_outline,
                        primary: true,
                        onPressed: () => _acceptOrder(context),
                      ),
                    _ActionButton(
                      label: 'Refuser',
                      icon: Icons.cancel_outlined,
                      primary: false,
                      onPressed: () => _refuseOrder(context),
                    ),
                    _ActionButton(
                      label: 'Ticket',
                      icon: Icons.description_outlined,
                      primary: false,
                      onPressed: () => _showTicket(context),
                    ),
                  ],
                  if (isPrete) ...[
                    _ActionButton(
                      label: 'Confirmer récupération',
                      icon: Icons.check_circle_outline,
                      primary: true,
                      onPressed: () => _setStatut(context, 'livrée'),
                    ),
                    _ActionButton(
                      label: 'Ticket',
                      icon: Icons.description_outlined,
                      primary: false,
                      onPressed: () => _showTicket(context),
                    ),
                  ],
                  if (isLivree || order.statut == 'refusee')
                    _ActionButton(
                      label: 'Voir détails',
                      icon: Icons.visibility_outlined,
                      primary: false,
                      onPressed: () => _showTicket(context),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _acceptOrder(BuildContext context) async {
    try {
      await acceptOrder(order.id);
      onAction();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Commande acceptée et prête')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
        );
      }
    }
  }

  Future<void> _refuseOrder(BuildContext context) async {
    final controller = TextEditingController(text: order.messageRefus ?? '');
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Refuser la commande'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Message au client (obligatoire) :'),
              const SizedBox(height: 8),
              TextField(
                controller: controller,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'Ex: Produit indisponible, réessayez plus tard',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, controller.text.trim()),
              style: ElevatedButton.styleFrom(
                backgroundColor: GrocerTheme.trendNegative,
                foregroundColor: Colors.white,
              ),
              child: const Text('Refuser'),
            ),
          ],
        );
      },
    );
    if (result != null && result.isNotEmpty) {
      try {
        await refuseOrder(order.id, result);
        onAction();
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Commande refusée, le client a été notifié')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
          );
        }
      }
    } else if (result != null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Veuillez saisir un message pour le client')),
        );
      }
    }
  }

  Future<void> _setStatut(BuildContext context, String newStatut) async {
    try {
      await updateStatut(order.id, newStatut);
      onAction();
      if (context.mounted) {
        final msg = newStatut == 'prête'
            ? 'Commande marquée prête'
            : 'Récupération confirmée';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg)),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
        );
      }
    }
  }

  Future<void> _showTicket(BuildContext context) async {
    final detail = await fetchDetail(order.id);
    if (!context.mounted || detail == null) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _TicketSheet(
        orderId: order.id,
        initialDetail: detail,
        fetchDetail: fetchDetail,
        markRupture: markRupture,
        onAction: onAction,
      ),
    );
    onAction();
  }
}

class _TicketSheet extends StatefulWidget {
  final int orderId;
  final GrocerOrderDetail initialDetail;
  final Future<GrocerOrderDetail?> Function(int) fetchDetail;
  final Future<void> Function(int, int) markRupture;
  final VoidCallback onAction;

  const _TicketSheet({
    required this.orderId,
    required this.initialDetail,
    required this.fetchDetail,
    required this.markRupture,
    required this.onAction,
  });

  @override
  State<_TicketSheet> createState() => _TicketSheetState();
}

class _TicketSheetState extends State<_TicketSheet> {
  late GrocerOrderDetail _detail;
  Timer? _refreshTimer;

  static String _formatPrice(double v) => v.toStringAsFixed(2).replaceAll('.', ',');

  String _getStatusLabel(String statut) {
    switch (statut) {
      case 'reçue': return 'Nouvelle';
      case 'prête': return 'Prête';
      case 'refusee': return 'Refusée';
      case 'livrée': return 'Récupérée';
      default: return statut;
    }
  }

  bool get _hasRupture => _detail.details.any((d) => d.rupture);
  bool get _hasPendingAcceptance => _detail.details.any((d) => d.enAttenteAcceptationClient);

  @override
  void initState() {
    super.initState();
    _detail = widget.initialDetail;
    _refreshTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (mounted) _refreshDetail();
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _refreshDetail() async {
    final d = await widget.fetchDetail(widget.orderId);
    if (mounted && d != null) {
      setState(() => _detail = d);
    }
  }

  Future<void> _onToggleRupture(GrocerOrderDetailLine line) async {
    final isRupture = line.rupture;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isRupture ? 'Produit à nouveau en stock' : 'Rupture de stock'),
        content: Text(
          isRupture
              ? 'Remettre "${line.nom}" en stock?\n\nLe client sera notifié que ce produit est à nouveau disponible.'
              : 'Marquer "${line.nom}" en rupture?\n\nLe client sera notifié et cet article sera retiré du total. Souhaitez-vous continuer la commande sans ce produit?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: isRupture ? GrocerTheme.primary : GrocerTheme.trendNegative,
              foregroundColor: Colors.white,
            ),
            child: Text(isRupture ? 'Remettre en stock' : 'Marquer rupture'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    try {
      await widget.markRupture(widget.orderId, line.id);
      widget.onAction();
      await _refreshDetail();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isRupture ? 'Produit remis en stock. Client notifié.' : 'Produit marqué en rupture. Client notifié.',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final canEdit = ['reçue', 'prête'].contains(_detail.statut);
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (_, scrollController) => Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: GrocerTheme.cardBackground,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: ListView(
          controller: scrollController,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text(
              'Ticket #CMD-${_detail.id}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
                color: GrocerTheme.textDark,
              ),
            ),
            const SizedBox(height: 12),
            _DetailRow('Client', '${_detail.clientPrenom} ${_detail.clientNom}'),
            if (_detail.clientTelephone != null && _detail.clientTelephone!.isNotEmpty)
              _DetailRow('Téléphone', _detail.clientTelephone!),
            if (_detail.clientEmail != null && _detail.clientEmail!.isNotEmpty)
              _DetailRow('Email', _detail.clientEmail!),
            if (_detail.dateRecuperation != null && _detail.dateRecuperation!.isNotEmpty)
              _DetailRow('Date', _formatPickupDate(_detail.dateRecuperation!)),
            _DetailRow('Créneau', _detail.creneau),
            _DetailRow('Statut', _getStatusLabel(_detail.statut)),
            if (_hasPendingAcceptance) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.amber.shade700),
                ),
                child: Row(
                  children: [
                    Icon(Icons.hourglass_empty, color: Colors.amber.shade700, size: 24),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'Produit(s) remis en stock. En attente de l\'acceptation du client. Vous ne pouvez pas accepter la commande.',
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (_hasRupture && _detail.statut == 'reçue') ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _detail.clientAccepteModification
                      ? GrocerTheme.primary.withValues(alpha: 0.15)
                      : Colors.orange.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _detail.clientAccepteModification ? GrocerTheme.primary : Colors.orange,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _detail.clientAccepteModification ? Icons.check_circle : Icons.schedule,
                      color: _detail.clientAccepteModification ? GrocerTheme.primary : Colors.orange,
                      size: 24,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _detail.clientAccepteModification
                            ? 'Client a accepté la commande malgré les ruptures.'
                            : 'En attente de l\'acceptation du client pour les ruptures.',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: _detail.clientAccepteModification ? GrocerTheme.primary : Colors.orange.shade800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (_detail.statut == 'refusee' && _detail.messageRefus != null && _detail.messageRefus!.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Text('Motif de l\'annulation', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: GrocerTheme.textDark)),
              const SizedBox(height: 4),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFEBEE),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFEF9A9A)),
                ),
                child: Text(_detail.messageRefus!, style: const TextStyle(fontSize: 14, color: Color(0xFFC62828))),
              ),
            ],
            if (_detail.notes != null && _detail.notes!.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Text('Notes client', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: GrocerTheme.textDark)),
              const SizedBox(height: 4),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Text(_detail.notes!, style: const TextStyle(fontSize: 14)),
              ),
            ],
            const Divider(height: 24),
            const Text(
              'Articles',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16, color: GrocerTheme.textDark),
            ),
            const SizedBox(height: 8),
            ..._detail.details.map((d) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (d.imagePrincipale != null && d.imagePrincipale!.isNotEmpty)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        ApiConstants.formatImageUrl(d.imagePrincipale!),
                        width: 48,
                        height: 48,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const SizedBox(width: 48, height: 48),
                      ),
                    )
                  else
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.inventory_2_outlined),
                    ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                d.nom,
                                style: TextStyle(
                                  fontWeight: FontWeight.w500,
                                  decoration: d.rupture ? TextDecoration.lineThrough : null,
                                  color: d.rupture ? Colors.grey : null,
                                ),
                              ),
                            ),
                            if (d.enAttenteAcceptationClient)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.amber.shade100,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.amber.shade700),
                                ),
                                child: Text('En attente client', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.amber.shade900)),
                              )
                            else if (d.rupture)
                              canEdit
                                  ? InkWell(
                                      onTap: () => _onToggleRupture(d),
                                      borderRadius: BorderRadius.circular(8),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: GrocerTheme.trendNegative.withValues(alpha: 0.2),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: const Text('Rupture', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: GrocerTheme.trendNegative)),
                                      ),
                                    )
                                  : Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: GrocerTheme.trendNegative.withValues(alpha: 0.2),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Text('Rupture', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: GrocerTheme.trendNegative)),
                                    )
                            else if (canEdit)
                              TextButton(
                                onPressed: () => _onToggleRupture(d),
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 8),
                                  minimumSize: Size.zero,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: const Text('Rupture', style: TextStyle(fontSize: 12, color: GrocerTheme.trendNegative)),
                              ),
                          ],
                        ),
                        Text(
                          '${d.quantite} × ${_formatPrice(d.prixUnitaire)} = ${_formatPrice(d.totalLigne)} MAD',
                          style: TextStyle(
                            fontSize: 12,
                            color: d.rupture ? Colors.grey : GrocerTheme.textMuted,
                            decoration: d.rupture ? TextDecoration.lineThrough : null,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Text(
                  '${_formatPrice(_detail.montantTotal)} MAD',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: GrocerTheme.primary),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

  String _formatPickupDate(String? iso) {
  if (iso == null || iso.isEmpty) return '';
  try {
    final d = DateTime.parse(iso);
    const mois = ['janv', 'févr', 'mars', 'avr', 'mai', 'juin', 'juill', 'août', 'sept', 'oct', 'nov', 'déc'];
    const jours = ['Lundi', 'Mardi', 'Mercredi', 'Jeudi', 'Vendredi', 'Samedi', 'Dimanche'];
    final sem = jours[d.weekday - 1];
    final m = mois[d.month - 1];
    return '$sem ${d.day} $m ${d.year}';
  } catch (_) {
    return '';
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(label, style: TextStyle(color: GrocerTheme.textMuted, fontSize: 13)),
          ),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 14))),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String statut;

  const _StatusChip({required this.statut});

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    String label;
    switch (statut) {
      case 'reçue':
        bg = const Color(0xFFFFE4D4);
        fg = const Color(0xFFB85C38);
        label = 'Nouvelle';
        break;
      case 'prête':
        bg = const Color(0xFFD4EDDA);
        fg = const Color(0xFF1A7F6E);
        label = 'Prête';
        break;
      case 'refusee':
        bg = const Color(0xFFFFEBEE);
        fg = const Color(0xFFC62828);
        label = 'Refusée';
        break;
      case 'livrée':
        bg = const Color(0xFFE8F4E8);
        fg = GrocerTheme.primary;
        label = 'Récupérée';
        break;
      default:
        bg = Colors.grey.shade200;
        fg = Colors.grey.shade800;
        label = statut;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: fg),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool primary;
  final VoidCallback onPressed;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.primary,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: primary ? GrocerTheme.primary : const Color(0xFFF0EDE8),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: primary ? Colors.white : GrocerTheme.textDark),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: primary ? Colors.white : GrocerTheme.textDark,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
