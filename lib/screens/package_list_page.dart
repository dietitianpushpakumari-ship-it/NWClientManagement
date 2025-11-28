import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:nutricare_client_management/modules/package/model/package_model.dart';
import 'package:nutricare_client_management/modules/package/service/package_Service.dart';
import 'package:nutricare_client_management/screens/package_entry_page.dart';

class PackageListPage extends StatefulWidget {
  const PackageListPage({super.key});

  @override
  State<PackageListPage> createState() => _PackageListPageState();
}

class _PackageListPageState extends State<PackageListPage> {
  final PackageService _service = PackageService();

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(symbol: '₹', decimalDigits: 0, locale: 'en_IN');

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PackageEntryPage())),
        backgroundColor: Colors.purple,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text("Create Package", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: Stack(
        children: [
          Positioned(top: -100, right: -100, child: Container(width: 300, height: 300, decoration: BoxDecoration(shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.purple.withOpacity(0.1), blurRadius: 80, spreadRadius: 30)]))),
          SafeArea(
            child: Column(
              children: [
                _buildHeader(context, "Service Packages"),
                Expanded(
                  child: StreamBuilder<List<PackageModel>>(
                    stream: _service.streamPackages(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                      final list = snapshot.data ?? [];
                      if (list.isEmpty) return const Center(child: Text("No packages found."));

                      return ListView.builder(
                        padding: const EdgeInsets.all(20),
                        itemCount: list.length,
                        itemBuilder: (context, index) {
                          final pkg = list[index];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 15, offset: const Offset(0, 5))]),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(color: Colors.purple.shade50, borderRadius: BorderRadius.circular(12)),
                                  child: const Icon(Icons.card_giftcard, color: Colors.purple, size: 28),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(pkg.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                      Text("${pkg.durationDays} Days • ${pkg.category.displayName}", style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(currency.format(pkg.price), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green)),
                                    const SizedBox(height: 8),
                                    InkWell(
                                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => PackageEntryPage(packageToEdit: pkg))),
                                      child: Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: Colors.grey.shade100, shape: BoxShape.circle), child: const Icon(Icons.edit, size: 16, color: Colors.black54)),
                                    )
                                  ],
                                )
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]), child: const Icon(Icons.arrow_back, size: 20)),
          ),
          const SizedBox(width: 16),
          Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1A1A1A))),
        ],
      ),
    );
  }
}