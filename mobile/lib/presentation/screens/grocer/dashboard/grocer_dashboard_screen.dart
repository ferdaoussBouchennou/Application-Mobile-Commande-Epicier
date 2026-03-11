import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../data/services/api_service.dart';
import '../grocer_theme.dart';

/// Tableau de bord Épicier — données réelles depuis l'API (base epicier_ecommerce).
class GrocerDashboardScreen extends StatefulWidget {
  const GrocerDashboardScreen({super.key});

  @override
  State<GrocerDashboardScreen> createState() => _GrocerDashboardScreenState();
}

class _GrocerDashboardScreenState extends State<GrocerDashboardScreen> {
  Map<String, dynamic>? _dashboardData;
  bool _loading = true;
  String? _error;

  static const List<Color> _chartColors = [
    GrocerTheme.border,
    GrocerTheme.textMuted,
    GrocerTheme.primary,
    GrocerTheme.textMuted,
    GrocerTheme.primary,
    GrocerTheme.border,
    GrocerTheme.textMuted,
  ];

  static const List<Color> _productColors = [
    GrocerTheme.primary,
    GrocerTheme.textMuted,
    GrocerTheme.border,
    Colors.grey,
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
      backgroundColor: GrocerTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            if (_loading)
              const Expanded(
                child: Center(child: CircularProgressIndicator(color: GrocerTheme.primary)),
              )
            else if (_error != null)
              Expanded(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _error!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: GrocerTheme.trendNegative),
                        ),
                        const SizedBox(height: 16),
                        TextButton.icon(
                          onPressed: _loadDashboard,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Réessayer'),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else ...[
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _loadDashboard,
                  color: GrocerTheme.primary,
                  child: ListView(
                    padding: const EdgeInsets.only(top: 12, bottom: 24),
                    children: [
                      _buildKpiGrid(),
                      _buildChartCard(),
                      _buildTopProductsCard(),
                      const SizedBox(height: 80),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildKpiGrid() {
    final kpis = _dashboardData?['kpis'] as Map<String, dynamic>? ?? {};
    final totalCommandes = kpis['totalCommandes'] is int
        ? kpis['totalCommandes'] as int
        : (kpis['totalCommandes'] is num ? (kpis['totalCommandes'] as num).toInt() : 0);
    final caTotal = kpis['caTotal'] is num ? (kpis['caTotal'] as num).toDouble() : 0.0;
    final noteMoyenne = kpis['noteMoyenne'] is num ? (kpis['noteMoyenne'] as num).toDouble() : 0.0;
    final annulations = kpis['annulations'] is int
        ? kpis['annulations'] as int
        : (kpis['annulations'] is num ? (kpis['annulations'] as num).toInt() : 0);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 6,
        crossAxisSpacing: 6,
        childAspectRatio: 1.7,
        children: [
          _kpiCard('🛒', '$totalCommandes', 'Commandes', null),
          _kpiCard('💰', _formatCa(caTotal), 'CA (MAD)', null),
          _kpiCard('⭐', noteMoyenne.toStringAsFixed(1), 'Note moy.', null),
          _kpiCard('❌', '$annulations', 'Annulations', true),
        ],
      ),
    );
  }

  String _formatCa(double value) {
    if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)} k';
    }
    return value.toStringAsFixed(0);
  }

  Widget _kpiCard(String icon, String value, String label, bool? trendDown) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: GrocerTheme.cardBackground,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(icon, style: const TextStyle(fontSize: 14)),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: GrocerTheme.textDark,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              fontSize: 8,
              color: GrocerTheme.textMuted,
              letterSpacing: 0.2,
            ),
          ),
          if (trendDown != null)
            Text(
              trendDown ? '—' : 'Ce mois',
              style: TextStyle(
                fontSize: 8,
                fontWeight: FontWeight.w600,
                color: trendDown ? GrocerTheme.trendNegative : GrocerTheme.trendPositive,
              ),
            ),
        ],
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

    return Container(
      margin: const EdgeInsets.fromLTRB(14, 10, 14, 0),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: GrocerTheme.cardBackground,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Commandes par jour',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: GrocerTheme.textDark,
                ),
              ),
              Text(
                '7 derniers jours',
                style: const TextStyle(fontSize: 10, color: GrocerTheme.textMuted),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 68,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(chartData.length, (i) {
                final e = chartData[i];
                final nb = e is Map ? (e['nb'] is int ? e['nb'] as int : (e['nb'] is num ? (e['nb'] as num).toInt() : 0)) : 0;
                final label = e is Map ? (e['label'] as String? ?? '') : '';
                final h = (nb / maxH).clamp(0.0, 1.0);
                const barMaxHeight = 50.0;
                const labelHeight = 14.0;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Container(
                          height: barMaxHeight * h,
                          decoration: BoxDecoration(
                            color: i < _chartColors.length ? _chartColors[i] : GrocerTheme.border,
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                          ),
                        ),
                        SizedBox(height: nb > 0 ? 4 : 2),
                        SizedBox(
                          height: labelHeight,
                          child: Text(
                            label,
                            style: const TextStyle(fontSize: 8, color: GrocerTheme.textMuted),
                            maxLines: 1,
                            overflow: TextOverflow.clip,
                          ),
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
      return Container(
        margin: const EdgeInsets.fromLTRB(14, 10, 14, 0),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: GrocerTheme.cardBackground,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Text(
          'Aucune vente sur la période',
          style: TextStyle(fontSize: 12, color: GrocerTheme.textMuted),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(14, 10, 14, 0),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: GrocerTheme.cardBackground,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Top produits vendus',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: GrocerTheme.textDark,
                ),
              ),
              const Text(
                'Ce mois',
                style: TextStyle(fontSize: 10, color: GrocerTheme.textMuted),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              SizedBox(
                width: 70,
                height: 70,
                child: CustomPaint(
                  painter: _DonutPainter(segments: segments),
                  size: const Size(70, 70),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: segments
                      .map((e) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2),
                            child: Row(
                              children: [
                                Container(
                                  width: 7,
                                  height: 7,
                                  decoration: BoxDecoration(
                                    color: e['color'] as Color,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 5),
                                Expanded(
                                  child: Text(
                                    '${e['label']} (${e['pct']}%)',
                                    style: const TextStyle(
                                      fontSize: 9.5,
                                      color: GrocerTheme.textDark,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ))
                      .toList(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DonutPainter extends CustomPainter {
  final List<Map<String, dynamic>> segments;

  _DonutPainter({required this.segments});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    const radius = 14.0;
    const strokeWidth = 5.5;
    double startAngle = -1.5708;

    for (final seg in segments) {
      int pct = seg['pct'] is int ? seg['pct'] as int : (seg['pct'] is num ? (seg['pct'] as num).toInt() : 0);
      final sweepAngle = (pct / 100) * 2 * 3.14159;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        false,
        Paint()
          ..color = seg['color'] as Color
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth,
      );
      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
