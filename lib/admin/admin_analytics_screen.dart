import 'dart:ui';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:nutricare_client_management/admin/admin_analytics_service.dart';
import 'package:nutricare_client_management/screens/dash/client_dashboard_screenv2.dart';
import 'package:nutricare_client_management/modules/client/services/client_service.dart'; // To fetch full client model for navigation

class AdminAnalyticsScreen extends StatefulWidget {
  const AdminAnalyticsScreen({super.key});

  @override
  State<AdminAnalyticsScreen> createState() => _AdminAnalyticsScreenState();
}

class _AdminAnalyticsScreenState extends State<AdminAnalyticsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final AdminAnalyticsService _service = AdminAnalyticsService();
  final ClientService _clientService = ClientService();

  String _timeFilter = 'This Month';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  // --- ACTIONS ---
  void _navigateToClient(String clientId) async {
    final client = await _clientService.getClientById(clientId);
    if (mounted) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => ClientDashboardScreen(client: client)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      body: Stack(
        children: [
          Positioned(top: -100, right: -80, child: Container(width: 400, height: 400, decoration: BoxDecoration(shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.red.withOpacity(0.05), blurRadius: 100, spreadRadius: 40)]))),

          SafeArea(
            child: Column(
              children: [
                _buildHeader(),

                // Filter & Tabs
                Container(
                  height: 50,
                  margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.6), borderRadius: BorderRadius.circular(25), border: Border.all(color: Colors.white)),
                  child: TabBar(
                    controller: _tabController,
                    indicator: BoxDecoration(color: Colors.indigo, borderRadius: BorderRadius.circular(25), boxShadow: [BoxShadow(color: Colors.indigo.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 3))]),
                    labelColor: Colors.white, unselectedLabelColor: Colors.grey.shade600,
                    labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                    tabs: const [Tab(text: "CLINICAL & RISK"), Tab(text: "BUSINESS GROWTH")],
                  ),
                ),

                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildClinicalTab(), // 🎯 NEW TAB
                      _buildBusinessTab(), // (Placeholder for previous business logic)
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

  // =================================================================
  // 🏥 TAB 1: CLINICAL INSIGHTS
  // =================================================================
  Widget _buildClinicalTab() {
    return FutureBuilder(
        future: Future.wait([
          _service.fetchAverageWeightVelocity(),
          _service.fetchAtRiskClients(),
          _service.fetchWellnessStats(),
        ]),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());

          final data = snapshot.data as List;
          final double avgVelocity = data[0] as double;
          final List<Map<String, dynamic>> atRiskList = data[1] as List<Map<String, dynamic>>;
          final Map<String, dynamic> wellnessStats = data[2] as Map<String, dynamic>;

          return ListView(
            padding: const EdgeInsets.all(20),
            physics: const BouncingScrollPhysics(),
            children: [
              // 1. Outcome Metrics
              Row(children: [
                Expanded(child: _buildKPICard("Weight Velocity", "${avgVelocity.toStringAsFixed(2)} kg/wk", avgVelocity < 0 ? "On Track" : "Slowing", Icons.show_chart, avgVelocity < 0 ? Colors.green : Colors.orange)),
                const SizedBox(width: 16),
                Expanded(child: _buildKPICard("Clients at Risk", "${atRiskList.length}", "Needs Action", Icons.warning_amber, Colors.red)),
              ]),
              const SizedBox(height: 24),

              // 2. "At Risk" Watchlist
              if (atRiskList.isNotEmpty) ...[
                const Text("⚠️ Priority Attention Needed", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1A1A1A))),
                const SizedBox(height: 12),
                ...atRiskList.map((c) => _buildRiskTile(c)).toList(),
                const SizedBox(height: 24),
              ],

              // 3. Wellness Usage (Engagement)
              _buildChartContainer(
                title: "Wellness Tool Usage",
                subtitle: "Most popular features this week",
                child: SizedBox(
                  height: 200,
                  child: BarChart(
                    BarChartData(
                      barGroups: wellnessStats.entries.toList().asMap().entries.map((e) {
                        return BarChartGroupData(x: e.key, barRods: [BarChartRodData(toY: (e.value.value as int).toDouble(), color: Colors.teal, width: 16, borderRadius: BorderRadius.circular(4))]);
                      }).toList(),
                      titlesData: FlTitlesData(
                        leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (val, meta) {
                          final keys = wellnessStats.keys.toList();
                          if (val.toInt() >= keys.length) return const SizedBox();
                          return Padding(padding: const EdgeInsets.only(top: 8), child: Text(keys[val.toInt()].substring(0,3), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)));
                        })),
                      ),
                      borderData: FlBorderData(show: false),
                      gridData: const FlGridData(show: false),
                    ),
                  ),
                ),
              ),
            ],
          );
        }
    );
  }

  Widget _buildBusinessTab() {
    return const Center(child: Text("Business Metrics (Coming Soon)"));
  }

  // --- WIDGET HELPERS ---

  Widget _buildKPICard(String label, String value, String sub, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 15, offset: const Offset(0, 5))], border: Border.all(color: color.withOpacity(0.1))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Icon(icon, color: color, size: 20),
            Text(sub, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color))
          ]),
          const SizedBox(height: 12),
          Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.black87)),
          Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
        ],
      ),
    );
  }

  Widget _buildRiskTile(Map<String, dynamic> client) {
    return GestureDetector(
      onTap: () => _navigateToClient(client['id']),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.red.withOpacity(0.1)), boxShadow: [BoxShadow(color: Colors.red.withOpacity(0.05), blurRadius: 10)]),
        child: Row(
          children: [
            CircleAvatar(backgroundColor: Colors.red.shade50, backgroundImage: client['photoUrl'] != null ? NetworkImage(client['photoUrl']) : null, child: client['photoUrl'] == null ? Text(client['name'][0], style: TextStyle(color: Colors.red.shade800, fontWeight: FontWeight.bold)) : null),
            const SizedBox(width: 16),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(client['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                Text(client['reason'], style: const TextStyle(fontSize: 12, color: Colors.red)),
              ]),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildChartContainer({required String title, required String subtitle, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 15, offset: const Offset(0, 5))]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        Text(subtitle, style: const TextStyle(fontSize: 11, color: Colors.grey)),
        const SizedBox(height: 24),
        child
      ]),
    );
  }

  Widget _buildHeader() {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
          decoration: BoxDecoration(color: Colors.white.withOpacity(0.8), border: Border(bottom: BorderSide(color: Colors.grey.withOpacity(0.1)))),
          child: Row(children: [
            GestureDetector(onTap: () => Navigator.pop(context), child: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]), child: const Icon(Icons.arrow_back, size: 20))),
            const SizedBox(width: 16),
            const Text("Analytics Center", style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF1A1A1A))),
          ]),
        ),
      ),
    );
  }
}