import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../data/models/client_order.dart';
import '../../../data/models/client_order_detail.dart';
import '../../../data/services/api_service.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/cart_provider.dart';
import '../../widgets/rate_order_sheet.dart';

/// Liste des commandes du client (onglet Commandes).
class ClientOrdersScreen extends StatefulWidget {
  const ClientOrdersScreen({super.key});

  @override
  State<ClientOrdersScreen> createState() => _ClientOrdersScreenState();
}

class _ClientOrdersScreenState extends State<ClientOrdersScreen> {
  static const Color _primary = Color(0xFF2D5016);
  static const Color _bgBeige = Color(0xFFFDF6F0);
  static const Color _textDark = Color(0xFF2C2C2C);
  static const Color _textMuted = Color(0xFF7A5C44);
  static const Color _totalOrange = Color(0xFFB85C38);

  final ApiService _api = ApiService();
  List<ClientOrder> _orders = [];
  bool _loading = true;
  String? _error;
  int _selectedFilterIndex = 0;
  static const List<String> _filterLabels = ['Toutes', 'Reçue', 'Prête', 'Livrée'];
  static const List<String?> _filterStatuts = [null, 'reçue', 'prête', 'livrée'];

  List<ClientOrder> get _filteredOrders {
    final statut = _filterStatuts[_selectedFilterIndex];
    if (statut == null) return _orders;
    return _orders.where((o) => o.statut == statut).toList();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final token = context.read<AuthProvider>().token;
    if (token == null || token.isEmpty) {
      if (mounted) {
        setState(() {
          _loading = false;
          _orders = [];
        });
      }
      return;
    }
    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final response = await _api.get('/commandes', token: token);
      if (!mounted) return;
      List<ClientOrder> orders = [];
      if (response is List) {
        for (final e in response) {
          if (e is Map) {
            try {
              orders.add(ClientOrder.fromJson(Map<String, dynamic>.from(e as Map)));
            } catch (_) {}
          }
        }
      }
      setState(() {
        _orders = orders;
        _loading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceFirst('Exception: ', '');
          _loading = false;
        });
      }
    }
  }

  static String _formatPrice(double v) => v.toStringAsFixed(2).replaceAll('.', ',');

  Future<ClientOrderDetail?> _fetchOrderDetail(int orderId) async {
    final token = context.read<AuthProvider>().token;
    if (token == null) return null;
    try {
      final res = await _api.get('/commandes/$orderId', token: token);
      return ClientOrderDetail.fromJson(Map<String, dynamic>.from(res as Map));
    } catch (_) {
      return null;
    }
  }

  Future<void> _showOrderDetail(ClientOrder order) async {
    final detail = await _fetchOrderDetail(order.id);
    if (!mounted || detail == null) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Impossible de charger le détail')));
      return;
    }
    final dateText = detail.dateCommande != null && detail.dateCommande!.isNotEmpty
        ? _formatDateHour(detail.dateCommande) : null;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.65,
        minChildSize: 0.35,
        maxChildSize: 0.92,
        builder: (_, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Color(0xFFFDF8F5),
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 10),
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade400,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  'Détails #CMD-${detail.id}',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: _textDark),
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                  children: [
                    // Card: Résumé commande
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 8, offset: const Offset(0, 2))],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              if (detail.nomBoutique.isNotEmpty)
                                Expanded(
                                  child: Row(
                                    children: [
                                      Icon(Icons.store_outlined, color: _primary, size: 22),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          detail.nomBoutique,
                                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: _textDark),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              _StatutChip(statut: detail.statut),
                            ],
                          ),
                          if (dateText != null && dateText.isNotEmpty) ...[
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Icon(Icons.calendar_today_outlined, size: 18, color: _textMuted),
                                const SizedBox(width: 8),
                                Text(dateText!, style: TextStyle(fontSize: 14, color: _textMuted)),
                              ],
                            ),
                          ],
                          if (detail.creneau.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(Icons.schedule_outlined, size: 18, color: _textMuted),
                                const SizedBox(width: 8),
                                Text('Créneau ${detail.creneau}', style: TextStyle(fontSize: 14, color: _textMuted)),
                              ],
                            ),
                          ],
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${detail.articleCount} article${detail.articleCount > 1 ? 's' : ''}',
                                style: TextStyle(fontSize: 14, color: _textMuted),
                              ),
                              Text(
                                'Total ${_formatPrice(detail.montantTotal)} MAD',
                                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: _totalOrange),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Section: Articles
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        children: [
                          Icon(Icons.receipt_long_outlined, color: _primary, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Articles',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: _textDark),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 6, offset: const Offset(0, 2))],
                      ),
                      child: Column(
                        children: [
                          for (int i = 0; i < detail.lignes.length; i++) ...[
                            if (i > 0) Padding(
                              padding: const EdgeInsets.only(top: 12, bottom: 12),
                              child: Divider(height: 1, color: Colors.grey.shade200),
                            ),
                            _buildDetailLine(detail.lignes[i]),
                          ],
                        ],
                      ),
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

  Widget _buildDetailLine(ClientOrderLine l) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l.nom, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: _textDark)),
              const SizedBox(height: 4),
              Text(
                '${l.quantite} × ${_formatPrice(l.prixUnitaire)} MAD',
                style: TextStyle(fontSize: 13, color: _textMuted),
              ),
            ],
          ),
        ),
        Text(
          '${_formatPrice(l.totalLigne)} MAD',
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: _textDark),
        ),
      ],
    );
  }

  void _showSuivre(ClientOrder order) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _SuivreOrderSheet(
        orderId: order.id,
        initialStatut: order.statut,
        nomBoutique: order.nomBoutique,
        creneau: order.creneau,
        dateCommandeFormatted: order.dateCommandeFormatted,
        formatDateHour: _formatDateHour,
        dateCommande: order.dateCommande,
        fetchOrderDetail: _fetchOrderDetail,
        primary: _primary,
        textDark: _textDark,
        textMuted: _textMuted,
      ),
    ).then((_) {
      // Rafraîchir la liste à la fermeture du modal pour afficher le bon statut sur la carte
      if (mounted) _load();
    });
  }

  Future<void> _orderAgain(ClientOrder order) async {
    final token = context.read<AuthProvider>().token;
    if (token == null) return;
    try {
      final cart = context.read<CartProvider>();
      final res = await cart.reorderFromCommande(token, order.id);
      if (!mounted) return;
      final added = res['added_count'] as int? ?? 0;
      final skipped = res['skipped_products'] as List? ?? [];
      if (added > 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$added article(s) ajouté(s) au panier.')),
        );
      }
      if (skipped.isNotEmpty) {
        final names = skipped
            .map((e) => (e is Map) ? (e['nom'] ?? 'Produit') : 'Produit')
            .join(', ');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Rupture de stock: $names n\'ont pas été ajoutés.',
            ),
            duration: const Duration(seconds: 5),
            backgroundColor: Colors.orange.shade800,
          ),
        );
      }
      if (added == 0 && skipped.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Aucun article à ajouter.')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
        );
      }
    }
  }

  void _showRateOrder(ClientOrder order) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => RateOrderSheet(
        orderId: order.id,
        nomBoutique: order.nomBoutique.isNotEmpty ? order.nomBoutique : 'Épicerie',
        onSubmitted: () {},
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final token = context.watch<AuthProvider>().token;
    if (token == null || token.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'Connectez-vous pour voir vos commandes.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: _textMuted),
          ),
        ),
      );
    }
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: _primary));
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.red)),
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
            Icon(Icons.receipt_long_outlined, size: 56, color: _primary.withValues(alpha: 0.6)),
            const SizedBox(height: 16),
            Text(
              'Aucune commande',
              style: TextStyle(fontSize: 16, color: _textMuted),
            ),
            const SizedBox(height: 8),
            Text(
              'Vos commandes apparaîtront ici.',
              style: TextStyle(fontSize: 14, color: _textMuted),
            ),
          ],
        ),
      );
    }
    return Column(
      children: [
        // Filter chips (Toutes, Reçue, Prête, Livrée)
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List.generate(_filterLabels.length, (i) {
                final selected = _selectedFilterIndex == i;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => setState(() => _selectedFilterIndex = i),
                      borderRadius: BorderRadius.circular(20),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: selected ? _primary : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: selected ? _primary : Colors.grey.shade300,
                            width: 1.2,
                          ),
                          boxShadow: selected ? null : [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 4, offset: const Offset(0, 1))],
                        ),
                        child: Text(
                          _filterLabels[i],
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: selected ? Colors.white : _textDark,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
        Expanded(
          child: _filteredOrders.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.receipt_long_outlined, size: 48, color: _primary.withValues(alpha: 0.6)),
                      const SizedBox(height: 12),
                      Text(
                        'Aucune commande dans cette catégorie',
                        style: TextStyle(fontSize: 15, color: _textMuted),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  color: _primary,
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                    itemCount: _filteredOrders.length,
                    itemBuilder: (context, index) {
                      final o = _filteredOrders[index];
                      final isLivree = o.statut == 'livrée';
                      final dateTimeText = o.dateCommandeFormatted?.isNotEmpty == true
                          ? o.dateCommandeFormatted!
                          : _formatDateHour(o.dateCommande);
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 1,
                        shadowColor: Colors.black.withValues(alpha: 0.06),
                        color: const Color(0xFFFAFAF8),
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
                                        Row(
                                          children: [
                                            Icon(Icons.store_outlined, size: 20, color: _textMuted),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                o.nomBoutique.isNotEmpty ? o.nomBoutique : 'Épicerie',
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                  color: _textDark,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 6),
                                        if (dateTimeText.isNotEmpty)
                                          Text(
                                            dateTimeText,
                                            style: TextStyle(fontSize: 13, color: _textMuted),
                                          ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '${o.articleCount} article${o.articleCount > 1 ? 's' : ''} · #CMD-${o.id}',
                                          style: TextStyle(fontSize: 13, color: _textMuted),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      _StatutChip(statut: o.statut),
                                      const SizedBox(height: 8),
                                      Text(
                                        '${_formatPrice(o.montantTotal)} MAD',
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: _totalOrange,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: () => _showOrderDetail(o),
                                      icon: const Icon(Icons.visibility_outlined, size: 18),
                                      label: const Text('Voir détails'),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: _primary,
                                        side: const BorderSide(color: _primary),
                                        padding: const EdgeInsets.symmetric(vertical: 12),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  if (!isLivree)
                                    Expanded(
                                      child: FilledButton.icon(
                                        onPressed: () => _showSuivre(o),
                                        icon: const Icon(Icons.location_on_outlined, size: 18),
                                        label: const Text('Suivre'),
                                        style: FilledButton.styleFrom(
                                          backgroundColor: _primary,
                                          padding: const EdgeInsets.symmetric(vertical: 12),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                        ),
                                      ),
                                    )
                                  else ...[
                                    Expanded(
                                      child: OutlinedButton.icon(
                                        onPressed: () => _showRateOrder(o),
                                        icon: const Icon(Icons.star_outline_rounded, size: 18),
                                        label: const Text('Noter'),
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: _primary,
                                          side: const BorderSide(color: _primary),
                                          padding: const EdgeInsets.symmetric(vertical: 12),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: FilledButton.icon(
                                        onPressed: () => _orderAgain(o),
                                        icon: const Icon(Icons.replay, size: 18),
                                        label: const Text('Commander à nouveau'),
                                        style: FilledButton.styleFrom(
                                          backgroundColor: _primary,
                                          padding: const EdgeInsets.symmetric(vertical: 12),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }

  static String _formatDateHour(String? iso) {
    if (iso == null || iso.isEmpty) return '';
    try {
      final d = DateTime.parse(iso);
      const mois = ['janv', 'févr', 'mars', 'avr', 'mai', 'juin', 'juill', 'août', 'sept', 'oct', 'nov', 'déc'];
      final m = mois[d.month - 1];
      final h = d.hour.toString().padLeft(2, '0');
      final min = d.minute.toString().padLeft(2, '0');
      return '${d.day} $m ${d.year} · $h:$min';
    } catch (_) {
      return '';
    }
  }
}

/// Bottom sheet: suivi de commande avec timeline et données API.
class _SuivreOrderSheet extends StatefulWidget {
  final int orderId;
  final String initialStatut;
  final String nomBoutique;
  final String creneau;
  final String? dateCommandeFormatted;
  final String? dateCommande;
  final String Function(String? iso) formatDateHour;
  final Future<ClientOrderDetail?> Function(int id) fetchOrderDetail;
  final Color primary;
  final Color textDark;
  final Color textMuted;

  const _SuivreOrderSheet({
    required this.orderId,
    required this.initialStatut,
    required this.nomBoutique,
    required this.creneau,
    this.dateCommandeFormatted,
    this.dateCommande,
    required this.formatDateHour,
    required this.fetchOrderDetail,
    required this.primary,
    required this.textDark,
    required this.textMuted,
  });

  @override
  State<_SuivreOrderSheet> createState() => _SuivreOrderSheetState();
}

class _SuivreOrderSheetState extends State<_SuivreOrderSheet> {
  ClientOrderDetail? _detail;
  bool _loading = true;
  String _error = '';

  /// Statut affiché: toujours celui de l’API une fois chargé, sinon initial (avec normalisation minuscule).
  String get _statut {
    final s = _detail?.statut ?? widget.initialStatut;
    return s.toLowerCase();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = '';
    });
    final detail = await widget.fetchOrderDetail(widget.orderId);
    if (!mounted) return;
    setState(() {
      _detail = detail;
      _loading = false;
      if (detail == null) _error = 'Impossible de charger le suivi';
    });
  }

  @override
  void initState() {
    super.initState();
    // Charger tout de suite pour afficher le vrai statut (ex. « Prête ») sans avoir à actualiser
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final steps = [
      _StepInfo('reçue', 'Commande reçue', 'Votre commande a bien été enregistrée.', Icons.receipt_long_rounded),
      _StepInfo('prête', 'Prête', 'L\'épicier prépare votre commande.', Icons.inventory_2_outlined),
      _StepInfo('livrée', 'Récupérée', 'Vous avez récupéré votre commande.', Icons.check_circle_outline_rounded),
    ];
    final currentIndex = steps.indexWhere((s) => s.statut == _statut);
    final index = currentIndex >= 0 ? currentIndex : 0;
    final isLoadingStatus = _loading && _detail == null;

    return DraggableScrollableSheet(
      initialChildSize: 0.65,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      builder: (context, scrollController) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFFFDF8F5),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 10),
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'Suivi #CMD-${widget.orderId}',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: widget.textDark),
              ),
            ),
            if (_error.isNotEmpty) ...[
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(_error, style: const TextStyle(color: Colors.red, fontSize: 13)),
              ),
            ],
            const SizedBox(height: 12),
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                children: [
                  // Card: Récupération
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 8, offset: const Offset(0, 2))],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.store_outlined, color: widget.primary, size: 22),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                widget.nomBoutique.isNotEmpty ? widget.nomBoutique : 'Épicerie',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: widget.textDark),
                              ),
                            ),
                          ],
                        ),
                        if (widget.creneau.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(Icons.schedule_outlined, size: 18, color: widget.textMuted),
                              const SizedBox(width: 8),
                              Text('Créneau ${widget.creneau}', style: TextStyle(fontSize: 14, color: widget.textMuted)),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Section: État de la commande
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      children: [
                        Icon(Icons.timeline, color: widget.primary, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'État de la commande',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: widget.textDark),
                        ),
                        if (isLoadingStatus) ...[
                          const SizedBox(width: 8),
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: widget.primary),
                          ),
                          const SizedBox(width: 6),
                          Text('Actualisation…', style: TextStyle(fontSize: 12, color: widget.textMuted)),
                        ],
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 6, offset: const Offset(0, 2))],
                    ),
                    child: isLoadingStatus
                        ? Padding(
                            padding: const EdgeInsets.symmetric(vertical: 20),
                            child: Center(
                              child: Text(
                                'Chargement du statut en cours…',
                                style: TextStyle(fontSize: 14, color: widget.textMuted),
                              ),
                            ),
                          )
                        : Column(
                            children: List.generate(steps.length, (i) {
                              final step = steps[i];
                              final isDone = i < index;
                              final isCurrent = i == index;
                              return _TimelineStep(
                                title: step.title,
                                subtitle: step.subtitle,
                                icon: step.icon,
                                isDone: isDone,
                                isCurrent: isCurrent,
                                isLast: i == steps.length - 1,
                                dateText: i == 0 && (widget.dateCommandeFormatted?.isNotEmpty == true || widget.dateCommande != null)
                                    ? (widget.dateCommandeFormatted ?? widget.formatDateHour(widget.dateCommande))
                                    : null,
                                primary: widget.primary,
                                textDark: widget.textDark,
                                textMuted: widget.textMuted,
                              );
                            }),
                          ),
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: TextButton.icon(
                      onPressed: _loading ? null : _load,
                      icon: _loading
                          ? SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: widget.primary))
                          : Icon(Icons.refresh_rounded, size: 20, color: widget.primary),
                      label: Text('Actualiser le statut', style: TextStyle(color: widget.primary, fontWeight: FontWeight.w600, fontSize: 14)),
                    ),
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

class _StepInfo {
  final String statut;
  final String title;
  final String subtitle;
  final IconData icon;

  _StepInfo(this.statut, this.title, this.subtitle, this.icon);
}

class _TimelineStep extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool isDone;
  final bool isCurrent;
  final bool isLast;
  final String? dateText;
  final Color primary;
  final Color textDark;
  final Color textMuted;

  const _TimelineStep({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.isDone,
    required this.isCurrent,
    required this.isLast,
    this.dateText,
    required this.primary,
    required this.textDark,
    required this.textMuted,
  });

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: isDone ? primary : (isCurrent ? primary.withValues(alpha: 0.15) : Colors.grey.shade200),
                  shape: BoxShape.circle,
                  border: isCurrent ? Border.all(color: primary, width: 2) : null,
                ),
                child: Icon(
                  isDone ? Icons.check_rounded : icon,
                  size: 24,
                  color: isDone ? Colors.white : (isCurrent ? primary : Colors.grey.shade600),
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    color: isDone ? primary : Colors.grey.shade300,
                  ),
                ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isDone || isCurrent ? textDark : textMuted,
                    ),
                  ),
                  if (subtitle.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(fontSize: 13, color: textMuted),
                    ),
                  ],
                  if (dateText != null && dateText!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      dateText!,
                      style: TextStyle(fontSize: 12, color: primary, fontWeight: FontWeight.w500),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatutChip extends StatelessWidget {
  final String statut;

  const _StatutChip({required this.statut});

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    String label;
    switch (statut) {
      case 'reçue':
        label = 'Reçue';
        bg = const Color(0xFFFFE4D4);
        fg = const Color(0xFFB85C38);
        break;
      case 'prête':
        label = 'Prête';
        bg = const Color(0xFFFFE8D4);
        fg = const Color(0xFFC76B39);
        break;
      case 'livrée':
        label = 'Récupérée';
        bg = const Color(0xFFD4EDDA);
        fg = const Color(0xFF1A7F6E);
        break;
      default:
        label = statut;
        bg = Colors.grey.shade200;
        fg = Colors.grey.shade800;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: fg)),
    );
  }
}
