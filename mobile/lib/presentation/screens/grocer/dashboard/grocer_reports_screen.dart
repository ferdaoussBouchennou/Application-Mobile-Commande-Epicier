import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../data/services/api_service.dart';
import '../../../../providers/auth_provider.dart';
import '../grocer_theme.dart';

/// Rapports et exports PDF — même langage visuel que le tableau de bord.
class GrocerReportsScreen extends StatefulWidget {
  const GrocerReportsScreen({super.key});

  @override
  State<GrocerReportsScreen> createState() => _GrocerReportsScreenState();
}

class _GrocerReportsScreenState extends State<GrocerReportsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ApiService _api = ApiService();
  late String _from;
  late String _to;
  int _periodDays = 30;
  bool _loading = false;
  String? _error;

  Map<String, dynamic>? _sales;
  Map<String, dynamic>? _orders;
  Map<String, dynamic>? _products;
  Map<String, dynamic>? _reclamations;

  String? _statutFilter;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _setPeriodDays(30);
    _loadAll();
  }

  void _setPeriodDays(int days) {
    final to = DateTime.now();
    final from = to.subtract(Duration(days: days));
    _from = DateFormat('yyyy-MM-dd').format(from);
    _to = DateFormat('yyyy-MM-dd').format(to);
    _periodDays = days;
  }

  String? get _token => context.read<AuthProvider>().token;

  Future<void> _loadAll() async {
    final t = _token;
    if (t == null) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await Future.wait([
        _loadSales(silent: true),
        _loadOrders(silent: true),
        _loadProducts(silent: true),
        _loadReclamations(silent: true),
      ]);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadSales({bool silent = false}) async {
    final t = _token;
    if (t == null) return;
    if (!silent) setState(() => _loading = true);
    try {
      final data = await _api.get(
        '/epicier/reports/sales?from=$_from&to=$_to',
        token: t,
      );
      if (mounted) setState(() => _sales = data as Map<String, dynamic>?);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (!silent && mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadOrders({bool silent = false}) async {
    final t = _token;
    if (t == null) return;
    if (!silent) setState(() => _loading = true);
    try {
      final st = _statutFilter;
      final q = st != null && st.isNotEmpty
          ? '/epicier/reports/orders?from=$_from&to=$_to&statut=$st'
          : '/epicier/reports/orders?from=$_from&to=$_to';
      final data = await _api.get(q, token: t);
      if (mounted) setState(() => _orders = data as Map<String, dynamic>?);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (!silent && mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadProducts({bool silent = false}) async {
    final t = _token;
    if (t == null) return;
    if (!silent) setState(() => _loading = true);
    try {
      final data = await _api.get(
        '/epicier/reports/products?from=$_from&to=$_to',
        token: t,
      );
      if (mounted) setState(() => _products = data as Map<String, dynamic>?);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (!silent && mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadReclamations({bool silent = false}) async {
    final t = _token;
    if (t == null) return;
    if (!silent) setState(() => _loading = true);
    try {
      final data = await _api.get(
        '/epicier/reports/reclamations?from=$_from&to=$_to',
        token: t,
      );
      if (mounted) setState(() => _reclamations = data as Map<String, dynamic>?);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (!silent && mounted) setState(() => _loading = false);
    }
  }

  Future<void> _downloadAndShare(String endpoint, String filename) async {
    final t = _token;
    if (t == null) return;
    setState(() => _loading = true);
    try {
      final bytes = await _api.getBytes(endpoint, token: t);
      // XFile.fromData évite path_provider / getTemporaryDirectory (MissingPluginException au hot reload ou sur Web).
      final xfile = XFile.fromData(
        bytes,
        mimeType: 'application/pdf',
        name: filename,
      );
      await Share.shareXFiles([xfile], subject: filename);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$e'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GrocerTheme.surfaceMuted,
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: GrocerTheme.primary,
        foregroundColor: Colors.white,
        centerTitle: false,
        title: const Text(
          'Rapports',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20,
              letterSpacing: -0.3),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(52),
          child: Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 8),
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              indicatorSize: TabBarIndicatorSize.tab,
              indicator: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.22),
                borderRadius: BorderRadius.circular(12),
              ),
              indicatorPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
              labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
              unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
              tabs: const [
                Tab(text: 'Ventes'),
                Tab(text: 'Commandes'),
                Tab(text: 'Produits'),
                Tab(text: 'Réclamations'),
              ],
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          Column(
            children: [
              _buildPeriodCard(),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: _ReportErrorBanner(message: _error!),
                ),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildSalesTab(),
                    _buildOrdersTab(),
                    _buildProductsTab(),
                    _buildReclamationsTab(),
                  ],
                ),
              ),
            ],
          ),
          if (_loading)
            const Positioned.fill(
              child: ModalBarrier(
                color: Color(0x33000000),
                dismissible: false,
              ),
            ),
          if (_loading)
            const Center(
              child: Card(
                elevation: 8,
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(color: GrocerTheme.primary),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPeriodCard() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFEEEEEE)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Période d\'analyse',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: GrocerTheme.textMuted.withValues(alpha: 0.95),
                letterSpacing: 0.4,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                _periodChip('7 j', 7),
                const SizedBox(width: 8),
                _periodChip('30 j', 30),
                const SizedBox(width: 8),
                _periodChip('90 j', 90),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(Icons.date_range_rounded, size: 16, color: GrocerTheme.primary.withValues(alpha: 0.8)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    '$_from  →  $_to',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: GrocerTheme.textDark,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _periodChip(String label, int days) {
    final selected = _periodDays == days;
    return Expanded(
      child: Material(
        color: selected
            ? GrocerTheme.primary
            : GrocerTheme.surfaceMuted,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: () {
            setState(() => _setPeriodDays(days));
            _loadAll();
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Center(
              child: Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                  color: selected ? Colors.white : GrocerTheme.textDark,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSalesTab() {
    if (_loading && _sales == null) {
      return const SizedBox.shrink();
    }
    final totaux = _sales?['totaux'] as Map<String, dynamic>?;
    final parJour = _sales?['parJour'] as List<dynamic>? ?? [];
    final ca = totaux?['ca'] is num ? (totaux!['ca'] as num).toDouble() : 0.0;
    final nb = totaux?['nbCommandes'] is num
        ? (totaux!['nbCommandes'] as num).toInt()
        : 0;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
      children: [
        _PdfActionTile(
          icon: Icons.picture_as_pdf_rounded,
          title: 'Exporter PDF',
          subtitle: 'Ventes jour par jour',
          onTap: () => _downloadAndShare(
            '/epicier/export/sales/pdf?from=$_from&to=$_to',
            'rapport_ventes_${_from}_$_to.pdf',
          ),
        ),
        const SizedBox(height: 12),
        _SummaryCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${ca.toStringAsFixed(2)} MAD',
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: GrocerTheme.textDark,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'CA total sur la période · $nb commande(s)',
                style: TextStyle(
                  fontSize: 13,
                  color: GrocerTheme.textMuted.withValues(alpha: 0.95),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Text(
          'Détail par jour',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: GrocerTheme.textMuted.withValues(alpha: 0.95),
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 8),
        ...parJour.map((e) {
          if (e is! Map) return const SizedBox.shrink();
          final jour = e['jour']?.toString() ?? '';
          final c = e['ca'] is num ? (e['ca'] as num).toDouble() : 0.0;
          final n = e['nbCommandes'] is num ? (e['nbCommandes'] as num).toInt() : 0;
          return _DataRowTile(
            label: jour,
            value: '${c.toStringAsFixed(2)} MAD',
            trailing: '$n cmd.',
          );
        }),
      ],
    );
  }

  Widget _buildOrdersTab() {
    if (_loading && _orders == null) {
      return const SizedBox.shrink();
    }
    final list = _orders?['commandes'] as List<dynamic>? ?? [];
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFEEEEEE)),
          ),
          child: DropdownButtonFormField<String?>(
            key: ValueKey('${_from}_${_to}_${_statutFilter ?? "all"}'),
            initialValue: _statutFilter,
            decoration: const InputDecoration(
              labelText: 'Statut',
              border: InputBorder.none,
              labelStyle: TextStyle(fontWeight: FontWeight.w600),
            ),
            items: const [
              DropdownMenuItem<String?>(value: null, child: Text('Tous les statuts')),
              DropdownMenuItem(value: 'reçue', child: Text('reçue')),
              DropdownMenuItem(value: 'prête', child: Text('prête')),
              DropdownMenuItem(value: 'livrée', child: Text('livrée')),
              DropdownMenuItem(value: 'refusee', child: Text('refusee')),
            ],
            onChanged: (v) {
              setState(() => _statutFilter = v);
              _loadOrders();
            },
          ),
        ),
        const SizedBox(height: 12),
        _PdfActionTile(
          icon: Icons.summarize_rounded,
          title: 'Résumé PDF',
          subtitle: 'Totaux et répartition par statut',
          onTap: () => _downloadAndShare(
            '/epicier/export/summary/pdf?from=$_from&to=$_to',
            'resume_commandes_${_from}_$_to.pdf',
          ),
        ),
        const SizedBox(height: 8),
        _PdfActionTile(
          icon: Icons.list_alt_rounded,
          title: 'Liste détaillée PDF',
          subtitle: 'Commandes avec lignes produits',
          onTap: () {
            final st = _statutFilter;
            final q = st != null && st.isNotEmpty
                ? '/epicier/export/commandes/pdf?from=$_from&to=$_to&statut=$st'
                : '/epicier/export/commandes/pdf?from=$_from&to=$_to';
            _downloadAndShare(q, 'commandes_${_from}_$_to.pdf');
          },
        ),
        const SizedBox(height: 16),
        Text(
          'Liste (${list.length})',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: GrocerTheme.textMuted.withValues(alpha: 0.95),
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 8),
        ...list.map((e) {
          if (e is! Map) return const SizedBox.shrink();
          final id = e['id'];
          final st = e['statut']?.toString() ?? '';
          final mt = e['montant_total'] is num
              ? (e['montant_total'] as num).toDouble()
              : 0.0;
          final client = e['client_nom']?.toString() ?? '';
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              child: InkWell(
                onTap: () => _downloadAndShare(
                  '/epicier/export/commande/$id/pdf',
                  'commande_$id.pdf',
                ),
                borderRadius: BorderRadius.circular(14),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: GrocerTheme.primarySoft,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.receipt_long_rounded, color: GrocerTheme.primary, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '#$id · $st',
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 14,
                                color: GrocerTheme.textDark,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              client,
                              style: TextStyle(
                                fontSize: 12,
                                color: GrocerTheme.textMuted.withValues(alpha: 0.95),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '${mt.toStringAsFixed(2)} MAD',
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                          color: GrocerTheme.textDark,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400),
                    ],
                  ),
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildProductsTab() {
    if (_loading && _products == null) {
      return const SizedBox.shrink();
    }
    final top = _products?['topProduits'] as List<dynamic>? ?? [];
    final cat = _products?['nbProduitsCatalogue'];
    final rupt = _products?['produitsEnRupture'];

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
      children: [
        _SummaryCard(
          child: Row(
            children: [
              Expanded(
                child: _MiniStat(
                  icon: Icons.inventory_2_outlined,
                  label: 'Au catalogue',
                  value: '$cat',
                  color: GrocerTheme.primary,
                ),
              ),
              Container(width: 1, height: 44, color: Colors.grey.shade200),
              Expanded(
                child: _MiniStat(
                  icon: Icons.warning_amber_rounded,
                  label: 'En rupture',
                  value: '$rupt',
                  color: GrocerTheme.accentAmber,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Top produits',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: GrocerTheme.textMuted.withValues(alpha: 0.95),
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 8),
        ...top.map((e) {
          if (e is! Map) return const SizedBox.shrink();
          final nom = e['nom']?.toString() ?? '';
          final qte = e['quantiteVendue'] is num
              ? (e['quantiteVendue'] as num).toInt()
              : 0;
          return _DataRowTile(
            label: nom,
            value: '$qte',
            trailing: 'vendus',
          );
        }),
      ],
    );
  }

  Widget _buildReclamationsTab() {
    if (_loading && _reclamations == null) {
      return const SizedBox.shrink();
    }
    final list = _reclamations?['reclamations'] as List<dynamic>? ?? [];
    final par = _reclamations?['parStatut'] as List<dynamic>? ?? [];

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
      children: [
        _PdfActionTile(
          icon: Icons.picture_as_pdf_rounded,
          title: 'Exporter PDF',
          subtitle: 'Synthèse des réclamations',
          onTap: () => _downloadAndShare(
            '/epicier/export/reclamations/pdf?from=$_from&to=$_to',
            'reclamations_${_from}_$_to.pdf',
          ),
        ),
        const SizedBox(height: 12),
        if (par.isNotEmpty)
          _SummaryCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Par statut',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: GrocerTheme.textDark,
                  ),
                ),
                const SizedBox(height: 10),
                ...par.map((e) {
                  if (e is! Map) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${e['statut']}',
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: GrocerTheme.surfaceMuted,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${e['nombre']}',
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        const SizedBox(height: 12),
        Text(
          'Dernières réclamations',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: GrocerTheme.textMuted.withValues(alpha: 0.95),
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 8),
        ...list.map((e) {
          if (e is! Map) return const SizedBox.shrink();
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFEEEEEE)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '#${e['id']} · ${e['statut']}',
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    e['motif']?.toString() ?? '',
                    style: TextStyle(
                      fontSize: 13,
                      color: GrocerTheme.textMuted.withValues(alpha: 0.95),
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}

class _ReportErrorBanner extends StatelessWidget {
  final String message;

  const _ReportErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: GrocerTheme.trendNegative.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: GrocerTheme.trendNegative.withValues(alpha: 0.25)),
      ),
      child: Text(
        message,
        style: const TextStyle(
          color: GrocerTheme.trendNegative,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _PdfActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _PdfActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFEEEEEE)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: GrocerTheme.trendNegative.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: GrocerTheme.trendNegative.withValues(alpha: 0.9), size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                        color: GrocerTheme.textDark,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: GrocerTheme.textMuted.withValues(alpha: 0.95),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.download_rounded, color: GrocerTheme.primary.withValues(alpha: 0.7)),
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final Widget child;

  const _SummaryCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEEEEEE)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _DataRowTile extends StatelessWidget {
  final String label;
  final String value;
  final String trailing;

  const _DataRowTile({
    required this.label,
    required this.value,
    required this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFEEEEEE)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              ),
            ),
            Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
            ),
            const SizedBox(width: 8),
            Text(
              trailing,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: GrocerTheme.textMuted.withValues(alpha: 0.9),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _MiniStat({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: GrocerTheme.textDark,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: GrocerTheme.textMuted.withValues(alpha: 0.95),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
