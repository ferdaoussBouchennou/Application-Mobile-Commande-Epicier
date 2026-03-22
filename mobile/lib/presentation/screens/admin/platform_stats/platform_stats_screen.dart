import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../../data/services/api_service.dart';
import '../../../../providers/auth_provider.dart';
import '../../../widgets/admin/admin_bottom_nav.dart';

class PlatformStatsScreen extends StatefulWidget {
  const PlatformStatsScreen({super.key});

  @override
  State<PlatformStatsScreen> createState() => _PlatformStatsScreenState();
}

class _PlatformStatsScreenState extends State<PlatformStatsScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  Map<String, dynamic>? _data;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final auth = context.read<AuthProvider>();
      final data = await _apiService.getDashboardStats(auth.token!);
      setState(() {
        _data = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFFDF6F0),
        body: Center(child: CircularProgressIndicator(color: Color(0xFF2D5016))),
      );
    }

    if (_error != null) {
      return Scaffold(
        backgroundColor: Color(0xFFFDF6F0),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Erreur: $_error', textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: _loadData, child: const Text('Réessayer')),
            ],
          ),
        ),
      );
    }

    final summary = _data!['summary'];

    return Scaffold(
      backgroundColor: const Color(0xFFFDF6F0),
      appBar: AppBar(
        title: const Text('Tableau de Bord', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF2D5016),
        foregroundColor: Colors.white,
        actions: [
          IconButton(onPressed: _loadData, icon: const Icon(Icons.refresh)),
        ],
      ),
      bottomNavigationBar: const AdminBottomNav(currentIndex: 0),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Summary Cards row 1
            Row(
              children: [
                Expanded(
                  child: _buildSummaryCard(
                    'Épiciers actifs',
                    summary['epiciers']['total'].toString(),
                    '+${summary['epiciers']['growth']} ce mois',
                    Icons.store,
                    const Color(0xFF2D5016),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildSummaryCard(
                    'Clients inscrits',
                    _toInt(summary['clients']['total']).toString(),
                    '+${_toInt(summary['clients']['growth'])}',
                    Icons.people,
                    const Color(0xFFC06C1E),
                    isGrowthPositive: true,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Summary Cards row 2
            Row(
              children: [
                Expanded(
                  child: _buildSummaryCard(
                    'Commandes / jour',
                    _toInt(summary['ordersPerDay']).toString(),
                    '+12%', // Static for now
                    Icons.shopping_bag,
                    const Color(0xFFE67E22),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildSummaryCard(
                    'Litiges ouverts',
                    _toInt(summary['disputes']).toString(),
                    '-3 vs hier', // Static for now
                    Icons.gavel,
                    const Color(0xFF3498DB),
                    isGrowthPositive: false,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            _buildSectionHeader('Commandes par jour', subtitle: '— 7 derniers jours'),
            const SizedBox(height: 12),
            _buildOrdersBarChart(),
            
            const SizedBox(height: 24),
            _buildSectionHeader('Statut des commandes'),
            const SizedBox(height: 12),
            _buildStatusDonutChart(),

            const SizedBox(height: 24),
            _buildSectionHeader('Catégories les plus commandées'),
            const SizedBox(height: 12),
            _buildCategoriesProgress(),

            const SizedBox(height: 24),
            _buildSectionHeader('Top épiceries du mois'),
            const SizedBox(height: 12),
            _buildTopStoresList(),

            const SizedBox(height: 24),
            _buildSectionHeader('Nouvelles inscriptions', subtitle: '— 30 jours'),
            const SizedBox(height: 12),
            _buildRegTrendLineChart(),
            
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, {String? subtitle}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
          if (subtitle != null) ...[
            const SizedBox(width: 8),
            Text(subtitle, style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
          ]
        ],
      ),
    );
  }

  Widget _buildSummaryCard(String title, String value, String growth, IconData icon, Color color, {bool isGrowthPositive = true}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: TextStyle(fontSize: 13, color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                child: Icon(icon, size: 16, color: color),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87)),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(
                isGrowthPositive ? Icons.arrow_upward : Icons.arrow_downward,
                size: 12,
                color: isGrowthPositive ? Colors.green : Colors.red,
              ),
              const SizedBox(width: 4),
              Text(
                growth,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isGrowthPositive ? Colors.green : Colors.red,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOrdersBarChart() {
    final trend = _data!['orderTrend'] as List;
    // Grouping by day
    final Map<String, Map<String, int>> dayMap = {};
    for (var item in trend) {
      final day = item['day'];
      final status = item['statut'];
      final count = _toInt(item['count']);
      if (!dayMap.containsKey(day)) dayMap[day] = {};
      dayMap[day]![status] = count;
    }

    final days = dayMap.keys.toList()..sort();
    final List<BarChartGroupData> groups = [];

    for (int i = 0; i < days.length; i++) {
      final dayData = dayMap[days[i]]!;
      final delivered = _toDouble(dayData['livrée']);
      final ongoing = _toDouble(dayData['reçue']) + _toDouble(dayData['prête']);
      final cancelled = _toDouble(dayData['refusee']) + _toDouble(dayData['refusée']);

      groups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: delivered + ongoing + cancelled,
              width: 16,
              borderRadius: BorderRadius.circular(4),
              rodStackItems: [
                BarChartRodStackItem(0, delivered, const Color(0xFF2D5016)),
                BarChartRodStackItem(delivered, delivered + ongoing, const Color(0xFFC06C1E)),
                BarChartRodStackItem(delivered + ongoing, delivered + ongoing + cancelled, const Color(0xFFE53935)),
              ],
            ),
          ],
        ),
      );
    }

    return Container(
      height: 250,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Expanded(
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: 20, // Should be dynamic based on max value
                barTouchData: BarTouchData(enabled: true),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() >= days.length) return const Text('');
                        final date = DateTime.parse(days[value.toInt()]);
                        final label = DateFormat('E').format(date); // Mon, Tue...
                        return Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: FlGridData(show: true, drawVerticalLine: false, horizontalInterval: 5),
                borderData: FlBorderData(show: false),
                barGroups: groups,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegend('Livrées', const Color(0xFF2D5016)),
              const SizedBox(width: 16),
              _buildLegend('En cours', const Color(0xFFC06C1E)),
              const SizedBox(width: 16),
              _buildLegend('Annulées', const Color(0xFFE53935)),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildLegend(String label, Color color) {
    return Row(
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3))),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.black54)),
      ],
    );
  }

  Widget _buildStatusDonutChart() {
    final dist = _data!['statusDist'] as List;
    int total = 0;
    for (var item in dist) total += _toInt(item['count']);

    final List<PieChartSectionData> sections = [];
    final Map<String, Color> statusColors = {
      'livrée': const Color(0xFF2D5016),
      'prête': const Color(0xFFC06C1E),
      'reçue': const Color(0xFFE67E22),
      'refusee': const Color(0xFFE53935),
    };

    for (var item in dist) {
      final status = item['statut'];
      final count = _toInt(item['count']);
      final percentage = total > 0 ? (count / total * 100).round() : 0;
      
      sections.add(
        PieChartSectionData(
          color: statusColors[status] ?? Colors.grey,
          value: count.toDouble(),
          title: '$percentage%',
          radius: 50,
          titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
        ),
      );
    }

    return Container(
      height: 200,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Row(
        children: [
          Expanded(
            child: PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 40,
                sections: sections,
              ),
            ),
          ),
          const SizedBox(width: 24),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: statusColors.entries.map((e) {
              final count = _toInt(dist.firstWhere((item) => item['statut'] == e.key, orElse: () => {'count': 0})['count']);
              final percentage = total > 0 ? (count / total * 100).round() : 0;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Container(width: 10, height: 10, decoration: BoxDecoration(color: e.value, shape: BoxShape.circle)),
                    const SizedBox(width: 8),
                    Text(e.key.capitalize(), style: const TextStyle(fontSize: 13, color: Colors.black87)),
                    const SizedBox(width: 8),
                    Text('$percentage%', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black54)),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoriesProgress() {
    final categories = _data!['topCategories'] as List;
    double maxQty = 0;
    for (var c in categories) {
      if (_toDouble(c['total_qty']) > maxQty) maxQty = _toDouble(c['total_qty']);
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: categories.map((c) {
          final qty = _toDouble(c['total_qty']);
          final percentage = maxQty > 0 ? qty / maxQty : 0.0;
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(c['nom'], style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                    Text('${(percentage * 100).round()}%', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black54)),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: percentage,
                    color: const Color(0xFF2D5016),
                    backgroundColor: Colors.grey.shade100,
                    minHeight: 8,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTopStoresList() {
    final stores = _data!['topStores'] as List;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: List.generate(stores.length, (index) {
          final s = stores[index];
          return Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              border: index == stores.length - 1 ? null : Border(bottom: BorderSide(color: Colors.grey.shade100)),
            ),
            child: Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: const Color(0xFF2D5016).withOpacity(0.1), shape: BoxShape.circle),
                  child: Text('${index + 1}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF2D5016))),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(s['epicier']['nom_boutique'] ?? 'N/A', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
                ),
                Text('${_toInt(s['orderCount'])} cmd.', style: const TextStyle(fontSize: 14, color: Colors.grey)),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(color: Colors.yellow.shade100, borderRadius: BorderRadius.circular(8)),
                  child: Text(
                    _toDouble(s['epicier']['rating'] ?? 0.0).toStringAsFixed(1),
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFFF1C40F)),
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildRegTrendLineChart() {
    final trend = _data!['regTrend'] as List;
    final Map<String, Map<String, int>> dayMap = {};
    for (var item in trend) {
      final day = item['day'];
      final role = item['role'];
      final count = _toInt(item['count']);
      if (!dayMap.containsKey(day)) dayMap[day] = {};
      dayMap[day]![role] = count;
    }

    final days = dayMap.keys.toList()..sort();
    final List<FlSpot> clientSpots = [];
    final List<FlSpot> epicierSpots = [];

    for (int i = 0; i < days.length; i++) {
        final dayData = dayMap[days[i]]!;
        clientSpots.add(FlSpot(i.toDouble(), _toDouble(dayData['CLIENT'])));
        epicierSpots.add(FlSpot(i.toDouble(), _toDouble(dayData['EPICIER'])));
    }

    if (days.isEmpty) {
      return Container(
        height: 200,
        alignment: Alignment.center,
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
        child: const Text('Pas de données'),
      );
    }

    return Container(
      height: 250,
      padding: const EdgeInsets.fromLTRB(16, 24, 24, 16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(show: true, drawVerticalLine: false, horizontalInterval: 5),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                interval: (days.length / 4).clamp(1, 30).toDouble(),
                getTitlesWidget: (value, meta) {
                  int index = value.toInt();
                  if (index < 0 || index >= days.length) return const Text('');
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(DateFormat('dd/MM').format(DateTime.parse(days[index])), style: const TextStyle(fontSize: 9, color: Colors.grey)),
                  );
                },
              ),
            ),
            leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 30, getTitlesWidget: (v, m) => Text(v.toInt().toString(), style: const TextStyle(fontSize: 10)))),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: clientSpots,
              isCurved: true,
              color: const Color(0xFF2D5016),
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: FlDotData(show: true),
              belowBarData: BarAreaData(show: true, color: const Color(0xFF2D5016).withOpacity(0.05)),
            ),
            LineChartBarData(
              spots: epicierSpots,
              isCurved: true,
              color: const Color(0xFFC06C1E),
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: FlDotData(show: true),
              belowBarData: BarAreaData(show: true, color: const Color(0xFFC06C1E).withOpacity(0.05)),
            ),
          ],
        ),
      ),
    );
  }

  int _toInt(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }
}

extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}
