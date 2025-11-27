import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:nutricare_client_management/admin/admin_analytics_service.dart';

class AdminAnalyticsScreen extends StatefulWidget {
  const AdminAnalyticsScreen({super.key});

  @override
  State<AdminAnalyticsScreen> createState() => _AdminAnalyticsScreenState();
}

class _AdminAnalyticsScreenState extends State<AdminAnalyticsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _timeFilter = 'This Month';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      appBar: AppBar(
        title: const Text("Practice Analytics", style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        actions: [
          // Time Filter Dropdown
          Container(
            margin: const EdgeInsets.only(right: 16, top: 10, bottom: 10),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(20),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _timeFilter,
                icon: const Icon(Icons.keyboard_arrow_down, size: 16, color: Colors.indigo),
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.indigo),
                items: ['Last 7 Days', 'This Month', 'Last 3 Months', 'Year To Date']
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (v) => setState(() => _timeFilter = v!),
              ),
            ),
          )
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.indigo,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Colors.indigo,
          indicatorWeight: 3,
          tabs: const [
            Tab(text: "BUSINESS & GROWTH"),
            Tab(text: "QUALITY & HEALTH"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildBusinessTab(),
          _buildQualityTab(),
        ],
      ),
    );
  }

  // =================================================================
  // 📊 TAB 1: BUSINESS (Revenue, Leads, Churn)
  // =================================================================
  // ... inside _AdminAnalyticsScreenState

  final AdminAnalyticsService _service = AdminAnalyticsService();

  Widget _buildBusinessTab() {
    return FutureBuilder(
        future: Future.wait([
          _service.fetchBusinessSnapshot(),
          _service.fetchRevenueTrend(),
          _service.fetchPlanDistribution(),
        ]),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) return Center(child: Text("Error: ${snapshot.error}"));

          final data = snapshot.data as List;
          final kpi = data[0] as Map<String, dynamic>;
          final revenueSpots = data[1] as List<FlSpot>;
          final pieSections = data[2] as List<PieChartSectionData>;

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Row(
                  children: [
                    Expanded(child: _buildKPICard("Total Revenue", "₹${(kpi['revenue']/1000).toStringAsFixed(1)}k", "MoM", Icons.currency_rupee, Colors.green)),
                    const SizedBox(width: 12),
                    Expanded(child: _buildKPICard("Active Clients", "${kpi['activeClients']}", "+${kpi['leads']} new", Icons.people, Colors.blue)),
                  ]
              ),
              const SizedBox(width: 20),
              // Legend
              const SizedBox(height: 24),

              // 2. Revenue Trend Chart
              _buildChartContainer(
                title: "Revenue Trajectory",
                action: "View Ledger",
                child: AspectRatio(
                  aspectRatio: 1.7,
                  child: LineChart(_mockRevenueData(revenueSpots)),
                ),
              ),
              const SizedBox(height: 20),

              // 3. Plan Popularity (Pie)
              _buildChartContainer(
                title: "Plan Distribution",
                child: Row(
                  children: [
                    Expanded(
                      child: AspectRatio(
                        aspectRatio: 1,
                        child: PieChart(_mockPlanData(pieSections)),
                      ),
                    ),
                    const SizedBox(width: 20),
                    // Legend
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildLegendItem(Colors.blue, "Weight Loss (45%)"),
                          _buildLegendItem(Colors.purple, "Diabetes Rev. (30%)"),
                          _buildLegendItem(Colors.orange, "PCOS (15%)"),
                          _buildLegendItem(Colors.teal, "General (10%)"),
                        ],
                      ),
                    )
                  ],
                ),
              ),
            ],

          );
        }
    );
  }

  // =================================================================
  // ❤️ TAB 2: QUALITY (Adherence, Mood, Outcomes)
  // =================================================================
  Widget _buildQualityTab() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // 1. KPI Row
        Row(
          children: [
            Expanded(child: _buildKPICard("Avg Adherence", "84%", "High", Icons.check_circle_outline, Colors.teal)),
            const SizedBox(width: 12),
            Expanded(child: _buildKPICard("Client Happiness", "4.8/5", "Stable", Icons.sentiment_very_satisfied, Colors.orange)),
          ],
        ),
        const SizedBox(height: 24),

        // 2. Adherence Trend
        _buildChartContainer(
          title: "Daily Log Compliance",
          subtitle: "How many clients are logging meals vs goals?",
          child: AspectRatio(
            aspectRatio: 1.7,
            child: BarChart(_mockAdherenceData()),
          ),
        ),

        const SizedBox(height: 20),

        // 3. At-Risk Clients List
        const Text("⚠ At-Risk Clients (Low Activity)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 10),
        _buildRiskClientTile("Sarah Mike", "No logs for 3 days", 0.2),
        _buildRiskClientTile("John Doe", "Missed 2 check-ins", 0.4),
        _buildRiskClientTile("Priya K.", "Dropped Weight Goal", 0.3),
      ],
    );
  }

  // --- WIDGET HELPERS ---

  Widget _buildKPICard(String label, String value, String trend, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
        border: Border.all(color: color.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
                  child: Icon(icon, color: color, size: 18)
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                child: Text(trend, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color)),
              )
            ],
          ),
          const SizedBox(height: 12),
          Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.black87)),
          Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildChartContainer({required String title, String? subtitle, String? action, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 15, offset: const Offset(0, 5))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  if (subtitle != null) Text(subtitle, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                ],
              ),
              if (action != null)
                Text(action, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.indigo)),
            ],
          ),
          const SizedBox(height: 24),
          child,
        ],
      ),
    );
  }

  Widget _buildRiskClientTile(String name, String reason, double activityLevel) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.red.shade100)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.red.shade50,
          child: Text(name[0], style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red.shade900)),
        ),
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        subtitle: Text(reason, style: const TextStyle(fontSize: 12, color: Colors.red)),
        trailing: SizedBox(
          width: 80,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text("Activity", style: TextStyle(fontSize: 10, color: Colors.grey)),
              const SizedBox(height: 4),
              LinearProgressIndicator(value: activityLevel, color: Colors.red, backgroundColor: Colors.red.shade50, minHeight: 4),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLegendItem(Color color, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 8),
          Text(text, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  // --- MOCK DATA GENERATORS (Replace with Real Service Later) ---

  LineChartData _mockRevenueData(List<FlSpot> revenueSpots) {
    return LineChartData(
      gridData: const FlGridData(show: false),
      titlesData: const FlTitlesData(show: false),
      borderData: FlBorderData(show: false),
      lineBarsData: [
        LineChartBarData(
          spots: revenueSpots,
          isCurved: true,
          color: Colors.indigo,
          barWidth: 3,
          dotData: const FlDotData(show: false),
          belowBarData: BarAreaData(show: true, color: Colors.indigo.withOpacity(0.1)),
        )
      ],
    );
  }

  PieChartData _mockPlanData(List<PieChartSectionData> pieSections) {
    return PieChartData(
      sectionsSpace: 2,
      centerSpaceRadius: 30,
      sections: pieSections
    );
  }

  BarChartData _mockAdherenceData() {
    return BarChartData(
      gridData: const FlGridData(show: false),
      borderData: FlBorderData(show: false),
      titlesData: const FlTitlesData(show: false),
      barGroups: List.generate(7, (i) => BarChartGroupData(
        x: i,
        barRods: [
          BarChartRodData(toY: (i % 2 == 0 ? 8 : 6).toDouble(), color: i == 6 ? Colors.teal : Colors.teal.shade200, width: 16, borderRadius: BorderRadius.circular(4)),
        ],
      )),
    );
  }
}