// lib/screens/serving_unit_list_page.dart

import 'package:flutter/material.dart';
import 'package:nutricare_client_management/modules/master/model/diagonosis_master.dart';
import 'package:nutricare_client_management/modules/master/screen/DiagonosisEntryPage.dart';
import 'package:nutricare_client_management/modules/master/service/diagonosis_master_service.dart';
import 'package:provider/provider.dart';



class DiagnosisListPage extends StatelessWidget {
  const DiagnosisListPage({super.key});

  // --- NAVIGATION ---
  void _navigateToEntry(BuildContext context, DiagnosisMasterModel? diagonosis) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => DiagnosisEntryPage(diagnosisToEdit: diagonosis),
      ),
    );
  }

  // --- DELETE/DEACTIVATE ACTION (WITH CONFIRMATION) ---
  Future<void> _softDeletediagonosis(BuildContext context, DiagnosisMasterModel diagonosis) async {
    final diagonosisService = Provider.of<DiagnosisMasterService>(context, listen: false);

    try {
      // 🎯 Soft-delete the diagonosis
      await diagonosisService.softDeleteDiagnosis(diagonosis.id);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${diagonosis.enName} marked as deleted.'),
          backgroundColor: Colors.orange,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete diagnosis: ${e.toString()}')),
      );
    }
  }

  // --- UI Builder for Each List Item with SWIPE-TO-DELETE ---
  Widget _builddiagonosisCard(BuildContext context, DiagnosisMasterModel diagonosis) {
    // 🎯 Use Dismissible for Swipe-to-Delete
    return Dismissible(
      key: Key(diagonosis.id), // Unique key is required for Dismissible
      direction: DismissDirection.endToStart,
      background: Container(
        color: Colors.red.shade700,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: const Icon(Icons.delete_forever, color: Colors.white, size: 30),
      ),
      // 🎯 CONFIRMATION DIALOG
      confirmDismiss: (direction) async {
        return await showDialog<bool>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text("Confirm Deletion"),
              content: Text("Are you sure you want to mark '${diagonosis.enName}' as deleted? You can reactivate it later."),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text("CANCEL"),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  child: const Text("DELETE", style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
      onDismissed: (direction) {
        if (direction == DismissDirection.endToStart) {
          _softDeletediagonosis(context, diagonosis);
        }
      },
      child: Card(
        elevation: 2,
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: ListTile(
          onTap: () => _navigateToEntry(context, diagonosis), // Tap to Edit
          leading: Icon(Icons.scale, color: Colors.blueGrey.shade700),
          title: Text(
            '${diagonosis.enName}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Text(
            ' Translations: ${diagonosis.nameLocalized.length} languages',
          ),
          trailing: const Icon(Icons.edit, color: Colors.blue),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final diagonosisService = Provider.of<DiagnosisMasterService>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Diagnosis Master'),
        backgroundColor: Colors.blueGrey,
      ),

      // Use a StreamBuilder for real-time list updates
      body: StreamBuilder<List<DiagnosisMasterModel>>(
        stream: diagonosisService.getDiagnoses(), // Fetch active diagonosiss
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error loading diagnosis: ${snapshot.error}'));
          }
          final diagonosiss = snapshot.data ?? [];
          if (diagonosiss.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(20.0),
                child: Text('No active serving diagnosis found. Tap + to add the first one.'),
              ),
            );
          }

          return ListView.builder(
            itemCount: diagonosiss.length,
            itemBuilder: (context, index) {
              final diagonosis = diagonosiss[index];
              return _builddiagonosisCard(context, diagonosis);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToEntry(context, null),
        child: const Icon(Icons.add),
        backgroundColor: Colors.blueGrey,
        tooltip: 'Add New Serving diagnosis',
      ),
    );
  }
}