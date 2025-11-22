// lib/screens/serving_unit_list_page.dart

import 'package:flutter/material.dart';
import 'package:nutricare_client_management/meal_planner/screen/serving_unit_entry_page.dart';
import 'package:nutricare_client_management/modules/master/service/serving_unit_service.dart';
import 'package:provider/provider.dart';

import '../../modules/master/model/ServingUnit.dart';
import 'package:nutricare_client_management/admin/custom_gradient_app_bar.dart';



class ServingUnitListPage extends StatelessWidget {
  const ServingUnitListPage({super.key});

  // --- NAVIGATION ---
  void _navigateToEntry(BuildContext context, ServingUnit? unit) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ServingUnitEntryPage(unitToEdit: unit),
      ),
    );
  }

  // --- DELETE/DEACTIVATE ACTION (WITH CONFIRMATION) ---
  Future<void> _softDeleteUnit(BuildContext context, ServingUnit unit) async {
    final unitService = Provider.of<ServingUnitService>(context, listen: false);

    try {
      // 🎯 Soft-delete the unit
      await unitService.softDeleteUnit(unit.id);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${unit.enName} marked as deleted.'),
          backgroundColor: Colors.orange,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete unit: ${e.toString()}')),
      );
    }
  }

  // --- UI Builder for Each List Item with SWIPE-TO-DELETE ---
  Widget _buildUnitCard(BuildContext context, ServingUnit unit) {
    // 🎯 Use Dismissible for Swipe-to-Delete
    return Dismissible(
      key: Key(unit.id), // Unique key is required for Dismissible
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
              content: Text("Are you sure you want to mark '${unit.enName}' as deleted? You can reactivate it later."),
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
          _softDeleteUnit(context, unit);
        }
      },
      child: Card(
        elevation: 2,
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: ListTile(
          onTap: () => _navigateToEntry(context, unit), // Tap to Edit
          leading: Icon(Icons.scale, color: Colors.blueGrey.shade700),
          title: Text(
            '${unit.enName} (${unit.abbreviation})',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Text(
            'Base: ${unit.baseUnit.toUpperCase()} | Translations: ${unit.nameLocalized.length} languages',
          ),
          trailing: const Icon(Icons.edit, color: Colors.blue),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final unitService = Provider.of<ServingUnitService>(context);
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: CustomGradientAppBar(
        title: const Text('Serving Units Master'),
      ),

      // Use a StreamBuilder for real-time list updates
      body: SafeArea(
        child: StreamBuilder<List<ServingUnit>>(
          stream: unitService.streamAllActiveUnits(), // Fetch active units
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('Error loading units: ${snapshot.error}'));
            }
            final units = snapshot.data ?? [];
            if (units.isEmpty) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(20.0),
                  child: Text('No active serving units found. Tap + to add the first one.'),
                ),
              );
            }

            return ListView.builder(
              itemCount: units.length,
              itemBuilder: (context, index) {
                final unit = units[index];
                return _buildUnitCard(context, unit);
              },
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToEntry(context, null),
        child: const Icon(Icons.add),
        backgroundColor: colorScheme.primary,
        tooltip: 'Add New Serving Unit',
      ),
    );
  }
}