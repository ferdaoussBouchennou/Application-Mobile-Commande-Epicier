import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../data/services/api_service.dart';
import '../grocer_theme.dart';
import 'grocer_reports_screen.dart';

/// Tableau de bord Épicier — design inspiré des apps e-commerce pro (seller hub).
class GrocerDashboardScreen extends StatefulWidget {
  const GrocerDashboardScreen({super.key});

  @override
  State<GrocerDashboardScreen> createState() => _GrocerDashboardScreenState();
}

class _GrocerDashboardScreenState extends State<GrocerDashboardScreen> {
  Map<String, dynamic>? _dashboardData;
  bool _loading = true;
  String? _error;

  static final List<Color> _barGradient = [
    GrocerTheme.primary.withValues(alpha: 0.35),
    GrocerTheme.primary,
  ];

  static const List<Color> _productColors = [
    GrocerTheme.primary,
    GrocerTheme.accentBlue,
    GrocerTheme.accentAmber,
    GrocerTheme.accentPurple,
    GrocerTheme.border,
  ];

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  Future<void> _loadDashboard() async {
    if (!mounted) return;
    final auth = context.read<AuthProvider>();
    final token = auth.token;
    if (token == null) {
      setState(() {
        _loading = false;
        _error = 'Non connecté';
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final api = ApiService();
      final data = await api.get('/epicier/dashboard', token: token);
      if (mounted) {
        setState(() {
          _dashboardData = data as Map<String, dynamic>?;
          _loading = false;
          _error = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = e.toString().replaceAll('Exception: ', '');
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GrocerTheme.surfaceMuted,
      body: SafeArea(
        child: Column(
          children: [
            if (_loading)
              Expanded(
                child: _buildLoadingState(),
              )
            else if (_error != null)
              Expanded(child: _buildErrorState())
            else
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _loadDashboard,
                  color: GrocerTheme.primary,
                  edgeOffset: 8,
                  child: CustomScrollView(
                    physics: const AlwaysScrollableScrollPhysics(
                      parent: BouncingScrollPhysics(),
                    ),
                    slivers: [
                      SliverToBoxAdapter(child: _buildHeroHeader(context)),
                      SliverToBoxAdapter(
                        child: _buildSectionHeading(
                          'Synthèse',
                          'Catalogue et clients — CA et commandes (30 j) dans le bandeau vert',
                        ),
                      ),
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        sliver: SliverGrid(
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisSpacing: 10,
                            crossAxisSpacing: 10,
                            childAspectRatio: 1.72,
                          ),
                          delegate: SliverChildListDelegate(_buildMetricTiles()),
                        ),
                      ),
                      SliverToBoxAdapter(child: _buildMergedStatusesCard()),
                      SliverToBoxAdapter(child: _buildSectionHeading('Tendance', 'Commandes sur 7 jours')),
                      SliverToBoxAdapter(child: _buildChartCard()),
                      SliverToBoxAdapter(child: _buildSectionHeading('Catalogue', 'Produits les plus vendus')),
                      SliverToBoxAdapter(child: _buildTopProductsCard()),
                      const SliverToBoxAdapter(child: SizedBox(height: 88)),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: GrocerTheme.primary.withValues(alpha: 0.12),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const CircularProgressIndicator(
              color: GrocerTheme.primary,
              strokeWidth: 3,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Chargement du tableau de bord…',
            style: TextStyle(
              fontSize: 14,
              color: GrocerTheme.textMuted,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: GrocerTheme.trendNegative.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.cloud_off_rounded, size: 48, color: GrocerTheme.trendNegative.withValues(alpha: 0.85)),
            ),
            const SizedBox(height: 20),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: GrocerTheme.textDark,
                fontSize: 15,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _loadDashboard,
              style: FilledButton.styleFrom(
                backgroundColor: GrocerTheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Réessayer'),
            ),
          ],
        ),
      ),
    );
  }

  int _intOf(Map<String, dynamic> m, String k) {
    final v = m[k];
    if (v is int) return v;
    if (v is num) return v.toInt();
    return 0;
  }

  double _doubleOf(Map<String, dynamic> m, String k) {
    final v = m[k];
    if (v is num) return v.toDouble();
    return 0.0;
  }

  String _formatCa(double value) {
    if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)} k';
    }
    return value.toStringAsFixed(0);
  }

  Widget _buildHeroHeader(BuildContext context) {
    final kpis = _dashboardData?['kpis'] as Map<String, dynamic>? ?? {};
    final caJour = _doubleOf(kpis, 'caJournalier');
    final caMois = _doubleOf(kpis, 'caMensuel');
    final cmd30 = _intOf(kpis, 'totalCommandes');
    final noteMoy = _doubleOf(kpis, 'noteMoyenne');

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            GrocerTheme.primary,
            GrocerTheme.primary.withValues(alpha: 0.78),
            const Color(0xFF1A3A0D),
          ],
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: GrocerTheme.primary.withValues(alpha: 0.35),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20,
            top: -20,
            child: Icon(
              Icons.storefront_rounded,
              size: 140,
              color: Colors.white.withValues(alpha: 0.08),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.insights_rounded, size: 16, color: Colors.white.withValues(alpha: 0.95)),
                          const SizedBox(width: 6),
                          Text(
                            'Performance boutique',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.95),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    Material(
                      color: Colors.white.withValues(alpha: 0.22),
                      borderRadius: BorderRadius.circular(12),
                      child: InkWell(
                        onTap: () {
                          Navigator.push<void>(
                            context,
                            MaterialPageRoute<void>(
                              builder: (_) => const GrocerReportsScreen(),
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.description_outlined, size: 18, color: Colors.white.withValues(alpha: 0.95)),
                              const SizedBox(width: 6),
                              Text(
                                'Rapports',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.95),
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Icon(
                      Icons.star_rounded,
                      color: const Color(0xFFFFD54F),
                      size: 20,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      noteMoy.toStringAsFixed(1),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      ' / 5',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.75),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '·',
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.4)),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Note moyenne clients',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.88),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  'Chiffre d\'affaires aujourd\'hui',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      _formatCa(caJour),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 36,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'MAD',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.75),
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                  ),
                  child: Row(
                    children: [
                      _heroMiniStat(Icons.calendar_month_rounded, 'Ce mois', '${_formatCa(caMois)} MAD'),
                      Container(width: 1, height: 36, color: Colors.white.withValues(alpha: 0.2)),
                      _heroMiniStat(Icons.shopping_bag_outlined, 'Cmd. (30 j)', '$cmd30'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _heroMiniStat(IconData icon, String label, String value) {
    return Expanded(
      child: Row(
        children: [
          Icon(icon, size: 22, color: Colors.white.withValues(alpha: 0.9)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 11,
                  ),
                ),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeading(String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Container(
            width: 4,
            height: 22,
            decoration: BoxDecoration(
              color: GrocerTheme.primary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: GrocerTheme.textDark,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: GrocerTheme.textMuted.withValues(alpha: 0.9),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildMetricTiles() {
    final kpis = _dashboardData?['kpis'] as Map<String, dynamic>? ?? {};
    final rupt = _intOf(kpis, 'produitsEnRupture');
    final clients = _intOf(kpis, 'nbClients');
    final rec = _intOf(kpis, 'reclamationsTotal');

    final specs = <_MetricSpec>[
      _MetricSpec(
        Icons.inventory_2_outlined,
        'Catalogue',
        '${_intOf(kpis, 'nbProduits')}',
        const Color(0xFF00897B),
        detail: rupt > 0 ? '$rupt en rupture' : 'Aucune rupture',
      ),
      _MetricSpec(
        Icons.groups_outlined,
        'Clients',
        '$clients',
        GrocerTheme.accentPurple,
        detail: rec > 0 ? '$rec réclamation(s)' : 'Aucune réclamation',
      ),
    ];
    return specs.map((s) => _MetricCard(spec: s)).toList();
  }

  Widget _buildMergedStatusesCard() {
    final kpis = _dashboardData?['kpis'] as Map<String, dynamic>? ?? {};
    final cmd = kpis['commandesParStatut'];
    final rec = kpis['reclamationsParStatut'];
    final cmdEntries = cmd is Map ? cmd.entries.toList() : <MapEntry<dynamic, dynamic>>[];
    final recEntries = rec is Map ? rec.entries.toList() : <MapEntry<dynamic, dynamic>>[];
    if (cmdEntries.isEmpty && recEntries.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: _SoftCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.dashboard_customize_outlined, size: 22, color: GrocerTheme.primary.withValues(alpha: 0.9)),
                const SizedBox(width: 8),
                const Text(
                  'Répartition',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: GrocerTheme.textDark,
                  ),
                ),
              ],
            ),
            if (cmdEntries.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                'Commandes',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: GrocerTheme.textMuted.withValues(alpha: 0.95),
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: cmdEntries.map((e) {
                  final n = e.value is num ? (e.value as num).toInt() : 0;
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: GrocerTheme.primarySoft,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: GrocerTheme.primary.withValues(alpha: 0.12)),
                    ),
                    child: Text(
                      '${e.key} · $n',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: GrocerTheme.textDark,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
            if (cmdEntries.isNotEmpty && recEntries.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: Divider(height: 1, color: Colors.grey.shade200),
              ),
            if (recEntries.isNotEmpty) ...[
              Text(
                'Réclamations',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: GrocerTheme.textMuted.withValues(alpha: 0.95),
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: recEntries.map((e) {
                  final n = e.value is num ? (e.value as num).toInt() : 0;
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF8E1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFFFB74D).withValues(alpha: 0.5)),
                    ),
                    child: Text(
                      '${e.key} · $n',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: GrocerTheme.textDark,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildChartCard() {
    final chartData = _dashboardData?['chartData'] as List<dynamic>? ?? [];
    final maxNb = chartData.fold<int>(0, (m, e) {
      final n = e is Map ? (e['nb'] is int ? e['nb'] as int : (e['nb'] is num ? (e['nb'] as num).toInt() : 0)) : 0;
      return n > m ? n : m;
    });
    final maxH = maxNb > 0 ? maxNb.toDouble() : 1.0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
      child: _SoftCard(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Volume de commandes',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: GrocerTheme.textDark,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: GrocerTheme.surfaceMuted,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    '7 jours',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: GrocerTheme.textMuted),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 108,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: List.generate(chartData.length, (i) {
                  final e = chartData[i];
                  final nb = e is Map ? (e['nb'] is int ? e['nb'] as int : (e['nb'] is num ? (e['nb'] as num).toInt() : 0)) : 0;
                  final label = e is Map ? (e['label'] as String? ?? '') : '';
                  final h = (nb / maxH).clamp(0.0, 1.0);
                  const barMaxHeight = 54.0;
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          if (nb > 0)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 2),
                              child: Text(
                                '$nb',
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  color: GrocerTheme.primary.withValues(alpha: 0.9),
                                ),
                              ),
                            ),
                          Container(
                            height: barMaxHeight * h < 3 ? 3.0 : barMaxHeight * h,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                                colors: _barGradient,
                              ),
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                              boxShadow: nb > 0
                                  ? [
                                      BoxShadow(
                                        color: GrocerTheme.primary.withValues(alpha: 0.2),
                                        blurRadius: 6,
                                        offset: const Offset(0, 3),
                                      ),
                                    ]
                                  : null,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            label,
                            style: const TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                              color: GrocerTheme.textMuted,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopProductsCard() {
    final topProducts = _dashboardData?['topProducts'] as List<dynamic>? ?? [];
    final segments = <Map<String, dynamic>>[];
    for (var i = 0; i < topProducts.length; i++) {
      final p = topProducts[i];
      if (p is! Map) continue;
      final nom = p['nom'] as String? ?? '';
      final percentage = p['percentage'] is int
          ? p['percentage'] as int
          : (p['percentage'] is num ? (p['percentage'] as num).toInt() : 0);
      segments.add({
        'label': nom,
        'pct': percentage,
        'color': i < _productColors.length ? _productColors[i] : Colors.grey,
      });
    }

    if (segments.isEmpty) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
        child: _SoftCard(
          child: Row(
            children: [
              Icon(Icons.inventory_outlined, size: 40, color: GrocerTheme.textMuted.withValues(alpha: 0.5)),
              const SizedBox(width: 16),
              const Expanded(
                child: Text(
                  'Aucune vente sur les 30 derniers jours. Vos best-sellers apparaîtront ici.',
                  style: TextStyle(fontSize: 13, color: GrocerTheme.textMuted, height: 1.35),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
      child: _SoftCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Répartition des ventes',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: GrocerTheme.textDark,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Part relative sur 30 jours',
              style: TextStyle(fontSize: 11, color: GrocerTheme.textMuted.withValues(alpha: 0.95)),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                SizedBox(
                  width: 96,
                  height: 96,
                  child: CustomPaint(
                    painter: _DonutPainter(segments: segments),
                    size: const Size(96, 96),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: segments
                        .map(
                          (e) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: e['color'] as Color,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    '${e['label']}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: GrocerTheme.textDark,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Text(
                                  '${e['pct']}%',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: GrocerTheme.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricSpec {
  final IconData icon;
  final String label;
  final String value;
  final Color accent;
  final String? detail;

  _MetricSpec(
    this.icon,
    this.label,
    this.value,
    this.accent, {
    this.detail,
  });
}

class _MetricCard extends StatelessWidget {
  final _MetricSpec spec;

  const _MetricCard({required this.spec});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFEEEEEE)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: spec.accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(spec.icon, color: spec.accent, size: 19),
            ),
            const SizedBox(height: 8),
            Text(
              spec.value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: GrocerTheme.textDark,
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              spec.label,
              maxLines: 2,
              style: TextStyle(
                fontSize: 10,
                height: 1.15,
                fontWeight: FontWeight.w600,
                color: GrocerTheme.textMuted.withValues(alpha: 0.95),
              ),
            ),
            if (spec.detail != null) ...[
              const SizedBox(height: 3),
              Text(
                spec.detail!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  color: spec.accent.withValues(alpha: 0.85),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SoftCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const _SoftCard({
    required this.child,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFEEEEEE)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _DonutPainter extends CustomPainter {
  final List<Map<String, dynamic>> segments;

  _DonutPainter({required this.segments});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    const radius = 22.0;
    const strokeWidth = 10.0;
    double startAngle = -1.5708;

    for (final seg in segments) {
      final pct = seg['pct'] is int ? seg['pct'] as int : (seg['pct'] is num ? (seg['pct'] as num).toInt() : 0);
      final sweepAngle = (pct / 100) * 2 * 3.14159;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        false,
        Paint()
          ..color = seg['color'] as Color
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.round,
      );
      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
