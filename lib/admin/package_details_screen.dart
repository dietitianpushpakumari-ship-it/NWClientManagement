import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:nutricare_client_management/admin/labvital/global_service_provider.dart';
import 'package:nutricare_client_management/modules/package/model/package_model.dart';
import 'package:nutricare_client_management/modules/package/service/package_Service.dart';
import 'package:nutricare_client_management/screens/package_entry_page.dart'; // For Edit/Duplicate

class PackageDetailScreen extends ConsumerWidget {
  final PackageModel package;

  const PackageDetailScreen({super.key, required this.package});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currency = NumberFormat.currency(symbol: '₹', decimalDigits: 0, locale: 'en_IN');
    final themeColor = package.colorCode != null
        ? Color(int.parse(package.colorCode!))
        : Colors.deepPurple;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      body: CustomScrollView(
        slivers: [
          // 1. Dynamic Header with Price & Basic Info
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            backgroundColor: themeColor,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.copy, color: Colors.white),
                onPressed: () {
                  ref.read(packageServiceProvider).duplicatePackage(package);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Package Duplicated to Drafts")));
                  Navigator.pop(context);
                },
                tooltip: "Duplicate Package",
              ),
              if (!package.isFinalized)
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.white),
                  onPressed: () => Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => PackageEntryPage(packageToEdit: package))
                  ),
                  tooltip: "Edit Draft",
                ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [themeColor, themeColor.withOpacity(0.8)],
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 40),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(20)),
                      child: Text(
                        package.category.displayName.toUpperCase(),
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      package.name,
                      style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          currency.format(package.price),
                          style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
                        ),
                        if (package.originalPrice != null && package.originalPrice! > package.price) ...[
                          const SizedBox(width: 8),
                          Text(
                            currency.format(package.originalPrice),
                            style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 16, decoration: TextDecoration.lineThrough),
                          ),
                        ]
                      ],
                    ),
                    if (!package.isTaxInclusive)
                      Text("+ GST Applicable", style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12)),
                  ],
                ),
              ),
            ),
          ),

          // 2. Stats Grid
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  _buildStatCard("Validity", "${package.durationDays} Days", Icons.calendar_today, Colors.blue),
                  const SizedBox(width: 10),
                  _buildStatCard("Sessions", "${package.consultationCount}", Icons.video_call, Colors.orange),
                  const SizedBox(width: 10),
                  _buildStatCard("Free", "${package.freeSessions}", Icons.card_giftcard, Colors.green),
                ],
              ),
            ),
          ),

          // 3. Tabbed Content (Description, Inclusions, Features)
          SliverFillRemaining(
            child: DefaultTabController(
              length: 3,
              child: Column(
                children: [
                  Container(
                    color: Colors.white,
                    child: TabBar(
                      labelColor: themeColor,
                      unselectedLabelColor: Colors.grey,
                      indicatorColor: themeColor,
                      tabs: const [
                        Tab(text: "Overview"),
                        Tab(text: "Inclusions"),
                        Tab(text: "Features"),
                      ],
                    ),
                  ),
                  Expanded(
                    child: TabBarView(
                      children: [
                        // TAB 1: OVERVIEW
                        SingleChildScrollView(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildSectionHeader("Marketing Description"),
                              Text(package.description, style: const TextStyle(fontSize: 15, height: 1.5, color: Colors.black87)),
                              const SizedBox(height: 20),

                              _buildSectionHeader("Target Conditions"),
                              if (package.targetConditions.isEmpty)
                                const Text("No specific conditions.", style: TextStyle(color: Colors.grey))
                              else
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: package.targetConditions.map((e) => Chip(
                                    label: Text(e),
                                    backgroundColor: Colors.blue.shade50,
                                    labelStyle: TextStyle(color: Colors.blue.shade800),
                                  )).toList(),
                                ),

                              const SizedBox(height: 20),
                              _buildSectionHeader("Status"),
                              _buildStatusRow(package),
                            ],
                          ),
                        ),

                        // TAB 2: INCLUSIONS
                        _buildListComponent(package.inclusions, Icons.check_circle_outline, Colors.teal),

                        // TAB 3: FEATURES (Program Features)
                        _buildListComponent(package.programFeatureIds, Icons.star_border, Colors.deepPurple),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- HELPERS ---

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(title.toUpperCase(), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.1)),
    );
  }

  Widget _buildStatusRow(PackageModel pkg) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(10)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(children: [
            Icon(pkg.isFinalized ? Icons.lock : Icons.edit_note, size: 20, color: pkg.isFinalized ? Colors.green : Colors.orange),
            const SizedBox(width: 10),
            Text(pkg.isFinalized ? "Finalized Package" : "Draft Mode", style: const TextStyle(fontWeight: FontWeight.bold)),
          ]),
          if (pkg.isActive)
            const Chip(label: Text("Active", style: TextStyle(color: Colors.white, fontSize: 10)), backgroundColor: Colors.green, padding: EdgeInsets.zero, visualDensity: VisualDensity.compact)
          else
            const Chip(label: Text("Inactive", style: TextStyle(color: Colors.white, fontSize: 10)), backgroundColor: Colors.grey, padding: EdgeInsets.zero, visualDensity: VisualDensity.compact)
        ],
      ),
    );
  }

  Widget _buildListComponent(List<String> items, IconData icon, Color color) {
    if (items.isEmpty) {
      return const Center(child: Text("No items listed.", style: TextStyle(color: Colors.grey)));
    }
    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: items.length,
      separatorBuilder: (_,__) => const Divider(height: 1),
      itemBuilder: (context, index) {
        return ListTile(
          leading: Icon(icon, color: color),
          title: Text(items[index], style: const TextStyle(fontWeight: FontWeight.w500)),
          contentPadding: EdgeInsets.zero,
        );
      },
    );
  }
}