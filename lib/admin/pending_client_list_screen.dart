import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nutricare_client_management/admin/client_consultation_checlist_screen.dart';
import 'package:nutricare_client_management/admin/custom_gradient_app_bar.dart';
import 'package:nutricare_client_management/modules/client/model/client_model.dart';

class PendingClientListScreen extends StatefulWidget {
  const PendingClientListScreen({super.key});

  @override
  State<PendingClientListScreen> createState() => _PendingClientListScreenState();
}

class _PendingClientListScreenState extends State<PendingClientListScreen> {
  bool _isArchiveExpanded = false;

  // --- Core Firestore Update Logic ---

  Future<void> _updateArchiveStatus(ClientModel client, bool isArchiving) async {
    final String action = isArchiving ? 'Archiving' : 'Activating';

    try {
      await FirebaseFirestore.instance
          .collection('clients')
          .doc(client.id)
          .update({'isArchived': isArchiving});

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${client.name} successfully ${isArchiving ? 'archived' : 'activated'}.'),
            backgroundColor: isArchiving ? Colors.orange : Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$action failed: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _handleArchiveToggle(ClientModel client, bool isArchiving) {
    final String actionTitle = isArchiving ? 'Archive' : 'Activate';
    final String actionVerb = isArchiving ? 'archive' : 'activate';
    final Color confirmColor = isArchiving ? Colors.orange.shade700 : Colors.green.shade700;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('$actionTitle Patient'),
          content: Text('Are you sure you want to $actionVerb ${client.name}?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: confirmColor,
                foregroundColor: Colors.white,
              ),
              child: Text(actionTitle),
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
                _updateArchiveStatus(client, isArchiving); // Execute the update
              },
            ),
          ],
        );
      },
    );
  }

  // --- Navigation & Helper Widgets ---

  void _startNewConsultation() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const ClientConsultationChecklistScreen(initialProfile: null),
      ),
    );
  }

  Widget _buildClientTile(ClientModel client) {
    final bool isArchived = client.isArchived ?? false;
    final bool isSoftDeleted = client.isSoftDeleted ?? false;

    if (isSoftDeleted) return const SizedBox.shrink();

    final IconData archiveIcon = isArchived ? Icons.unarchive : Icons.archive;
    final Color archiveColor = isArchived ? Colors.blue.shade700 : Colors.orange.shade700;
    final String archiveTooltip = isArchived ? 'Activate Patient' : 'Archive Patient';
    final Color tileColor = isArchived ? Colors.grey.shade50 : Colors.white;

    return Card(
      elevation: 1,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      color: tileColor,
      child: ListTile(
        title: Text(
          client.name,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isArchived ? Colors.black54 : Colors.black,
          ),
        ),
        subtitle: Text(
          'ID: ${client.patientId} | Mobile: ${client.mobile}',
          style: TextStyle(color: isArchived ? Colors.black45 : Colors.black54),
        ),
        leading: Icon(
          isArchived ? Icons.folder_zip : Icons.person_pin,
          color: isArchived ? Colors.orange.shade300 : Colors.indigo,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(archiveIcon, color: archiveColor),
              tooltip: archiveTooltip,
              onPressed: () => _handleArchiveToggle(client, !isArchived),
            ),
            IconButton(
              icon: const Icon(Icons.play_circle_fill, color: Colors.green),
              tooltip: 'Resume Consultation',
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ClientConsultationChecklistScreen(initialProfile: client),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // --- Main Build Method ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomGradientAppBar(title: const Text('Resume Consultation')),
      body: SafeArea(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('clients')
                .where('isSoftDeleted', isEqualTo: false)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(child: Text('No client records found.'));
              }

              final allClients = snapshot.data!.docs.map((doc) => ClientModel.fromFirestore(doc)).toList();

              final activeClients = allClients.where((c) => c.isArchived != true).toList();
              final archivedClients = allClients.where((c) => c.isArchived == true).toList();

              return ListView(
                // 🎯 FIX: Added bottom padding to prevent FAB overlap
                padding: const EdgeInsets.only(bottom: 80),
                children: [
                  if (activeClients.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        'Active Consultations (${activeClients.length})',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.indigo.shade700),
                      ),
                    ),
                  ...activeClients.map((client) => _buildClientTile(client)).toList(),

                  const Divider(),

                  ExpansionTile(
                    initiallyExpanded: _isArchiveExpanded,
                    onExpansionChanged: (expanded) {
                      setState(() {
                        _isArchiveExpanded = expanded;
                      });
                    },
                    leading: const Icon(Icons.archive, color: Colors.orange),
                    title: Text(
                      'Archived Patients (${archivedClients.length})',
                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange.shade700),
                    ),
                    children: archivedClients.isEmpty
                        ? [const Padding(padding: EdgeInsets.all(16.0), child: Text('No patients in archive.'))]
                        : archivedClients.map((client) => _buildClientTile(client)).toList(),
                  ),
                ],
              );
            },
          )),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: _startNewConsultation,
        label: const Text('New Consultation'),
        icon: const Icon(Icons.person_add),
        backgroundColor: Colors.green,
      ),
    );
  }
}