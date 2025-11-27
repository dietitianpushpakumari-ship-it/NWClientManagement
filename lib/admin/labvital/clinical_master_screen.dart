import 'package:flutter/material.dart';
import 'package:nutricare_client_management/admin/custom_gradient_app_bar.dart';
import 'package:nutricare_client_management/admin/labvital/clinical_master_service.dart';
import 'package:nutricare_client_management/admin/labvital/clinical_model.dart';


class ClinicalMasterScreen extends StatefulWidget {
  const ClinicalMasterScreen({super.key});

  @override
  State<ClinicalMasterScreen> createState() => _ClinicalMasterScreenState();
}

class _ClinicalMasterScreenState extends State<ClinicalMasterScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ClinicalMasterService _service = ClinicalMasterService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomGradientAppBar(
        title: const Text("Clinical Master Data"),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: "Complaints", icon: Icon(Icons.sick)),
            Tab(text: "Allergies", icon: Icon(Icons.warning_amber)),
            Tab(text: "Medicines", icon: Icon(Icons.medication)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildMasterList(ClinicalMasterService.colComplaints, "Complaint"),
          _buildMasterList(ClinicalMasterService.colAllergies, "Allergy"),
          _buildMasterList(ClinicalMasterService.colMedicines, "Medicine"),
        ],
      ),
    );
  }

  Widget _buildMasterList(String collection, String label) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showEntryDialog(collection, label),
        label: Text("Add New $label"),
        icon: const Icon(Icons.add),
        backgroundColor: Colors.indigo,
      ),
      body: StreamBuilder<List<ClinicalItemModel>>(
        stream: _service.streamActiveItems(collection),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.folder_off, size: 48, color: Colors.grey.shade400),
                  const SizedBox(height: 10),
                  Text("No $label records found.", style: TextStyle(color: Colors.grey.shade600)),
                ],
              ),
            );
          }

          final items = snapshot.data!;
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final item = items[index];
              return Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.indigo.shade50,
                    child: Text(item.name[0].toUpperCase(), style: const TextStyle(color: Colors.indigo)),
                  ),
                  title: Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () => _showEntryDialog(collection, label, item: item),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _confirmDelete(collection, item),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showEntryDialog(String collection, String label, {ClinicalItemModel? item}) {
    final controller = TextEditingController(text: item?.name ?? '');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(item == null ? "Add New $label" : "Edit $label"),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: "$label Name",
            border: const OutlineInputBorder(),
            hintText: "Enter name...",
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              try {
                await _service.saveItem(collection, ClinicalItemModel(id: item?.id ?? '', name: controller.text));
                if (mounted) Navigator.pop(ctx);
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
              }
            },
            child: const Text("Save"),
          )
        ],
      ),
    );
  }

  void _confirmDelete(String collection, ClinicalItemModel item) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Confirm Delete"),
        content: Text("Are you sure you want to delete '${item.name}'?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              _service.deleteItem(collection, item.id);
              Navigator.pop(ctx);
            },
            child: const Text("Delete"),
          ),
        ],
      ),
    );
  }
}