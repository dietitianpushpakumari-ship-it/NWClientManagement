import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:nutricare_client_management/meal_planner/screen/guideline_entry_page.dart';
import 'package:nutricare_client_management/modules/master/model/guidelines.dart';
import 'package:nutricare_client_management/modules/master/service/guideline_service.dart';

class GuidelineListPage extends StatefulWidget {
  const GuidelineListPage({super.key});

  @override
  State<GuidelineListPage> createState() => _GuidelineListPageState();
}

class _GuidelineListPageState extends State<GuidelineListPage> {
  final GuidelineService _service = GuidelineService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      body: Stack(
        children: [
          Positioned(top: -100, right: -100, child: Container(width: 300, height: 300, decoration: BoxDecoration(shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.blueGrey.withOpacity(0.1), blurRadius: 80, spreadRadius: 30)]))),
          SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: StreamBuilder<List<Guideline>>(
                    stream: _service.streamAllActive(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                      final items = snapshot.data!;

                      if(items.isEmpty) return const Center(child: Text("No guidelines found."));

                      return ListView.separated(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 80),
                        itemCount: items.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final item = items[index];
                          return Container(
                            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 3))]),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                              title: Text(item.enTitle, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                              trailing: IconButton(
                                icon: const Icon(Icons.edit_outlined, color: Colors.blueGrey),
                                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => GuidelineEntryPage(itemToEdit: item))),
                              ),
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const GuidelineEntryPage())),
        backgroundColor: Colors.blueGrey,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text("Add Rule", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildHeader() {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
          decoration: BoxDecoration(color: Colors.white.withOpacity(0.8), border: Border(bottom: BorderSide(color: Colors.grey.withOpacity(0.1)))),
          child: Row(
            children: [
              GestureDetector(onTap: () => Navigator.pop(context), child: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]), child: const Icon(Icons.arrow_back, size: 20))),
              const SizedBox(width: 16),
              const Text("Guidelines", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1A1A1A))),
            ],
          ),
        ),
      ),
    );
  }
}