import 'package:flutter/material.dart';
import 'package:nutricare_client_management/meal_planner/screen/disease_master_entry_screen.dart';
import 'package:nutricare_client_management/meal_planner/screen/disease_master_model.dart';
import 'package:nutricare_client_management/meal_planner/screen/disease_master_service.dart';
import 'package:nutricare_client_management/admin/custom_gradient_app_bar.dart';

class DiseaseMasterListScreen extends StatefulWidget {
  const DiseaseMasterListScreen({super.key});

  @override
  State<DiseaseMasterListScreen> createState() =>
      _DiseaseMasterListScreenState();
}

class _DiseaseMasterListScreenState extends State<DiseaseMasterListScreen> {
  final DiseaseMasterService _service = DiseaseMasterService();

  // Navigation to Add/Edit screen
  void _navigateToAddEdit({DiseaseMasterModel? disease}) async {
    // Navigating and waiting for a result (true if saved successfully)
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => DiseaseMasterEntryScreen(diseaseToEdit: disease),
      ),
    );

    if (result == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            disease == null ? 'Disease added successfully!' : 'Disease updated successfully!',
          ),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  // Confirmation dialog for soft delete (Swipe to Delete implementation)
  void _confirmSoftDelete(DiseaseMasterModel disease) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Deletion'),
        content: Text(
          'Are you sure you want to delete the disease: "${disease.enName}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              // Perform the soft delete
              _service.softDeleteDisease(disease.id).then((_) {
                Navigator.of(ctx).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${disease.enName} marked as deleted.'),
                    backgroundColor: Colors.orange,
                  ),
                );
              }).catchError((e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Failed to delete: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              });
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: CustomGradientAppBar(
        title: const Text('Disease Master Record'),
      ),
      // --- List (LIVT) Screen with real-time updates ---
      body: SafeArea(
        child: StreamBuilder<List<DiseaseMasterModel>>(
          stream: _service.getActiveDiseases(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(
                child: Text(
                  'No diseases found. Tap the "+" button to add one.',
                  style: TextStyle(color: Colors.grey),
                ),
              );
            }

            final diseases = snapshot.data!;

            return ListView.builder(
              itemCount: diseases.length,
              itemBuilder: (context, index) {
                final disease = diseases[index];

                // --- Swipe to Delete (Swipe to Delete) ---
                return Dismissible(
                  key: ValueKey(disease.id),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    color: Colors.red,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    child: const Icon(Icons.delete_forever, color: Colors.white),
                  ),
                  confirmDismiss: (direction) async {
                    _confirmSoftDelete(disease);
                    return false; // Prevent immediate dismissal, handle deletion via dialog
                  },
                  child: Card(
                    margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    child: ListTile(
                      leading: const Icon(Icons.healing, color: Colors.red),
                      title: Text(
                        disease.enName,
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      subtitle: disease.nameLocalized.isNotEmpty
                          ? Text('Localized: ${disease.nameLocalized.values.join(', ')}')
                          : null,

                      // --- Edit (LIVT) ---
                      trailing: const Icon(Icons.edit, color: Colors.indigo),
                      onTap: () => _navigateToAddEdit(disease: disease),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
      // --- Add (Add) Button ---
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToAddEdit(),
        backgroundColor: colorScheme.secondary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}