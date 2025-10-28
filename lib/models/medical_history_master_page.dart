import 'package:flutter/material.dart';
import 'package:nutricare_client_management/models/medical_history_master_model.dart';
import 'package:nutricare_client_management/models/medical_history_master_service.dart';

class MedicalHistoryMasterPage extends StatefulWidget {
  const MedicalHistoryMasterPage({super.key});

  @override
  State<MedicalHistoryMasterPage> createState() => _MedicalHistoryMasterPageState();
}

class _MedicalHistoryMasterPageState extends State<MedicalHistoryMasterPage> {
  final MedicalHistoryMasterService _service = MedicalHistoryMasterService();
  late Future<List<MedicalHistoryMasterModel>> _historyFuture;

  @override
  void initState() {
    super.initState();
    _historyFuture = _loadHistory();
  }

  Future<List<MedicalHistoryMasterModel>> _loadHistory() {
    return _service.fetchAllMedicalHistory();
  }

  void _showEntryForm({MedicalHistoryMasterModel? history}) {
    final TextEditingController controller = TextEditingController(text: history?.name);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(history == null ? 'Add New Condition' : 'Edit Condition'),
        content: TextFormField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Condition Name'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.trim().isEmpty) return;

              final newHistory = MedicalHistoryMasterModel(
                id: history?.id ?? '', // empty ID for new record
                name: controller.text.trim(),
                createdAt: history?.createdAt ?? DateTime.now(),
              );

              await _service.saveMedicalHistory(newHistory);
              Navigator.of(context).pop();
              setState(() => _historyFuture = _loadHistory());
            },
            child: Text(history == null ? 'Add' : 'Save'),
          ),
        ],
      ),
    );
  }

  void _deleteHistory(String id) async {
    await _service.deleteMedicalHistory(id);
    setState(() => _historyFuture = _loadHistory());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Medical History Master'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<List<MedicalHistoryMasterModel>>(
        future: _historyFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final historyList = snapshot.data ?? [];

          return ListView.builder(
            padding: const EdgeInsets.only(bottom: 80.0), // Space for FAB
            itemCount: historyList.length,
            itemBuilder: (context, index) {
              final history = historyList[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                child: ListTile(
                  title: Text(history.name),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () => _showEntryForm(history: history),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _deleteHistory(history.id),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showEntryForm(),
        backgroundColor: Colors.indigo,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}