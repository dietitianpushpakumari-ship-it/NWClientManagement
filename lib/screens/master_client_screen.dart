import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:nutricare_client_management/models/client_model.dart';
import 'package:nutricare_client_management/screens/client_dashboard_screenv2.dart';
import 'package:nutricare_client_management/screens/client_form_screen.dart' hide ClientModel;

import '../services/client_service.dart';
import 'client_dashboard_screen.dart';
import 'client_form_screen_old.dart';

class MasterClientScreen extends StatefulWidget {
  const MasterClientScreen({super.key});

  @override
  State<MasterClientScreen> createState() => _MasterClientScreenState();
}

class _MasterClientScreenState extends State<MasterClientScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchText = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    // FR-1.6: Update search text to filter list
    setState(() {
      _searchText = _searchController.text.toLowerCase();
    });
  }

  // FR-1.5: Implementation of Soft Delete
  void _softDeleteClient(String clientId, String clientName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Soft Delete'),
        content: Text('Are you sure you want to soft delete client "$clientName"? \n\nThis client will be hidden from the active list.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              try {
                await FirebaseFirestore.instance.collection('clients').doc(clientId).update({
                  'isSoftDeleted': true,
                  'status': 'Deactivated', // Deactivate upon soft delete for consistency
                });
                if (mounted) Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('$clientName has been soft deleted.')),
                );
              } catch (e) {
                if (mounted) Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error soft deleting client: $e')),
                );
              }
            },
            child: const Text('Soft Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Master Client List'),
        actions: [
          // FR-1.2: Hook to Add Client Form (Need to implement AddClientScreen separately)
          IconButton(
            icon: const Icon(Icons.person_add),
            onPressed: () {
               Navigator.push(context, MaterialPageRoute(builder: (_) => const ClientFormScreen()));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Navigation to Add Client Form...')),
              );
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(64.0),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            // FR-1.6: Search Bar
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Search by Name, Mobile, or Email...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
            ),
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        // FR-1.1: Fetch client list (filter out soft-deleted clients)
        stream: FirebaseFirestore.instance
            .collection('clients')
            .where('isSoftDeleted', isEqualTo: false)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return const Center(child: Text('Error loading clients.'));
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());

          final clientDocs = snapshot.data!.docs;

          // FR-1.6: Apply search filter locally (Efficient for moderate lists)
          final filteredClients = clientDocs.where((doc) {
            final client = ClientModel.fromFirestore(doc);
            final searchLower = _searchText;
            return client.name.toLowerCase().contains(searchLower) ||
                client.mobile.contains(searchLower) ||
                client.email.toLowerCase().contains(searchLower);
          }).toList();

          if (filteredClients.isEmpty) {
            return Center(child: Text(_searchText.isEmpty ? 'No active clients found.' : 'No clients match "$_searchText".'));
          }

          return ListView.builder(
            itemCount: filteredClients.length,
            itemBuilder: (context, index) {
              final client = ClientModel.fromFirestore(filteredClients[index]);

              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.blueGrey,
                  backgroundImage: client.photoUrl != null ? NetworkImage(client.photoUrl!) : null,
                  child: client.photoUrl == null ? Text(client.name[0]) : null,
                ),
                title: Text(client.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('Mobile: ${client.mobile} | Status: ${client.status}\nDOB: ${DateFormat('MMM dd, yyyy').format(client.dob)}'),
                isThreeLine: true,
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // FR-1.4: Edit Button Hook
                    IconButton(
                      icon: const Icon(Icons.edit_note, color: Colors.blue),
                      onPressed: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => ClientFormScreen(clientToEdit: client)));
                      },
                    ),
                    // FR-1.5: Soft Delete Button
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      onPressed: () => _softDeleteClient(client.id, client.name),
                    ),
                  ],
                ),
                onTap: () {
                  // Navigate to Client Dashboard Sub-Module (Section 5)
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => ClientDashboardScreen(client: client)),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}