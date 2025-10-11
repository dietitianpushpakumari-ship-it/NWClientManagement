// lib/screens/package_status_card.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/package_assignment_model.dart';

class PackageStatusCard extends StatelessWidget {
  final List<PackageAssignmentModel> assignments;
  final VoidCallback onAssignTap;
  final Function(PackageAssignmentModel assignment) onEditTap;
  final Function(PackageAssignmentModel assignment) onDeleteTap;


  const PackageStatusCard({
    super.key,
    required this.assignments,
    required this.onAssignTap,
    required this.onEditTap,
    required this.onDeleteTap,
  });

  @override
  Widget build(BuildContext context) {
    // Note: The input 'assignments' is the raw list fetched from the subcollection.
    final List<PackageAssignmentModel> currentPackages = assignments
        .where((p) => p.isActive)
        .toList();

    if (currentPackages.isEmpty) {
      return _buildNoPackageWidget(context);
    } else {
      return _buildActivePackageList(context, currentPackages);
    }
  }

  // --- Widget Builders ---

  Widget _buildNoPackageWidget(BuildContext context) {
    return Card(
      elevation: 4,
      color: Colors.red.shade50,
      margin: const EdgeInsets.symmetric(vertical: 10),
      child: InkWell(
        onTap: onAssignTap, // Action to assign a package
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'No Active Package Assigned',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.red.shade900,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Tap here or click the button to assign a new package.',
                style: TextStyle(color: Colors.red),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: onAssignTap,
                icon: const Icon(Icons.add_circle_outline),
                label: const Text('Assign First Package'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red.shade600,
                  side: BorderSide(color: Colors.red.shade200),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActivePackageList(
      BuildContext context, List<PackageAssignmentModel> packages) {

    // Currency formatter for Indian Rupees
    final currencyFormatter = NumberFormat.currency(locale: 'en_IN', symbol: '₹');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 8.0, bottom: 4.0,left: 4.0),
          child: Text('Active Packages:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        ),
        ...packages.map((pkg) {
          final isExpiringSoon = pkg.expiryDate.difference(DateTime.now()).inDays < 7;

          return Card(
            elevation: 2,
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              onTap: () => onEditTap(pkg),
              leading: Icon(
                isExpiringSoon ? Icons.access_time_filled : Icons.check_circle_outline,
                color: isExpiringSoon ? Colors.orange : Colors.green,
              ),
              title:
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text( pkg.packageName,
                    style:  TextStyle( fontWeight: FontWeight.w600),
                  ),
                  _buildCategoryBadge(pkg.category),
                ],
              ),
              // --- REVAMPED SUBTITLE ---
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Purchased: ${DateFormat.yMMMd().format(pkg.purchaseDate)}',
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        // Display Net Booked Amount
                        'Booked: ${currencyFormatter.format(pkg.bookedAmount)}',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo),
                      ),
                      if (pkg.discount > 0)
                        Text(
                          // Display Discount Amount
                          'Discount: ${currencyFormatter.format(pkg.discount)}',
                          style: TextStyle(fontSize: 12, color: Colors.red.shade700),
                        ),
                    ],
                  ),
                ],
              ),
              // --- END REVAMP ---
              trailing: PopupMenuButton<String>(
                onSelected: (String result) {
                  if (result == 'edit') {
                    onEditTap(pkg);
                  } else if (result == 'delete') {
                    onDeleteTap(pkg);
                  }
                },
                itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                  const PopupMenuItem<String>(
                    value: 'edit',
                    child: Text('Edit/View Details'),
                  ),
                  const PopupMenuItem<String>(
                    value: 'delete',
                    child: Text('Delete Assignment', style: TextStyle(color: Colors.red)),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: onAssignTap,
          icon: const Icon(Icons.add_circle_outline),
          label: const Text('Add New Package'),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(double.infinity, 40),
            foregroundColor: Colors.green,
            side: BorderSide(color: Colors.green.shade200),
          ),
        ),
        const SizedBox(height: 10),
      ],
    );
  }

  Widget _buildCategoryBadge(String category) {
    Color backgroundColor;
    Color textColor = Colors.white;
    FontWeight fontWeight = FontWeight.normal;

    // Use the suggested color scheme
    switch (category.toLowerCase()) {
      case 'premium':
        backgroundColor = Colors.deepPurple.shade700;
        fontWeight = FontWeight.bold;
        break;
      case 'standard':
        backgroundColor = Colors.blue.shade600;
        break;
      case 'basic':
        backgroundColor = Colors.lightGreen.shade400;
        break;
      default:
      // Fallback for unknown categories
        backgroundColor = Colors.grey.shade600;
        category = 'Unknown';
        break;
    }

    return Chip(
      label: Text(
        category,
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: fontWeight,
        ),
      ),
      backgroundColor: backgroundColor,
      // Minimize padding for a compact badge look
      padding: EdgeInsets.zero,
      labelPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}