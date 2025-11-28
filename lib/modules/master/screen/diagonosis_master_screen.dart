import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:nutricare_client_management/modules/master/model/diagonosis_master.dart';
import 'package:nutricare_client_management/modules/master/screen/DiagonosisEntryPage.dart';
import 'package:nutricare_client_management/modules/master/service/diagonosis_master_service.dart';

class DiagnosisListPage extends StatefulWidget {
  const DiagnosisListPage({super.key});

  @override
  State<DiagnosisListPage> createState() => _DiagnosisListPageState();
}

class _DiagnosisListPageState extends State<DiagnosisListPage> {
  final DiagnosisMasterService _service = DiagnosisMasterService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DiagnosisEntryPage())),
        backgroundColor: Colors.redAccent,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context, "Diagnosis Master"),
            Expanded(
              child: StreamBuilder<List<DiagnosisMasterModel>>(
                stream: _service.getDiagnoses(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                  final list = snapshot.data!;
                  return ListView.separated(
                    padding: const EdgeInsets.all(20),
                    itemCount: list.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final item = list[index];
                      return Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: ListTile(
                          leading: const Icon(Icons.local_hospital, color: Colors.red),
                          title: Text(item.enName, style: const TextStyle(fontWeight: FontWeight.bold)),
                          trailing: IconButton(icon: const Icon(Icons.edit, color: Colors.grey), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => DiagnosisEntryPage(diagnosisToEdit: item)))),
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