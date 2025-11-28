import 'package:flutter/material.dart';
import 'package:nutricare_client_management/modules/client/screen/supplement_master_entry_dialog.dart';
import 'package:nutricare_client_management/modules/client/screen/suppliment_master_model.dart';
import 'package:nutricare_client_management/modules/client/screen/Suppliment_master_service.dart';

class SupplementationMasterScreen extends StatefulWidget {
  const SupplementationMasterScreen({super.key});

  @override
  State<SupplementationMasterScreen> createState() => _SupplementationMasterScreenState();
}

class _SupplementationMasterScreenState extends State<SupplementationMasterScreen> {
  final SupplimentMasterService _service = SupplimentMasterService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showDialog(context: context, builder: (_) => const SupplementationMasterEntryDialog()),
        backgroundColor: Colors.green,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context, "Supplements"),
            Expanded(
              child: StreamBuilder<List<SupplimentMasterModel>>(
                stream: _service.getSupplimentMaster(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                  final list = snapshot.data!;
                  return ListView.separated(
                    padding: const EdgeInsets.all(20),
                    itemCount: list.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final item = list[index];
                      return Container(
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 5)]),
                        child: ListTile(
                          leading: const Icon(Icons.medication, color: Colors.green),
                          title: Text(item.enName, style: const TextStyle(fontWeight: FontWeight.bold)),
                          trailing: IconButton(icon: const Icon(Icons.edit, color: Colors.grey), onPressed: () => showDialog(context: context, builder: (_) => SupplementationMasterEntryDialog(supplementation: item))),
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
    );
  }

  Widget _buildHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(children: [
        GestureDetector(onTap: () => Navigator.pop(context), child: const Icon(Icons.arrow_back, size: 24)),
        const SizedBox(width: 16),
        Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
      ]),
    );
  }
}