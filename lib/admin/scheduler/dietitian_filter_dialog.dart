import 'package:flutter/material.dart';
import 'package:nutricare_client_management/admin/admin_profile_model.dart';

class DietitianFilterDialog extends StatefulWidget {
  final List<AdminProfileModel> allStaff;
  final List<String> selectedIds;
  final Function(List<String>) onApply;

  const DietitianFilterDialog({
    super.key,
    required this.allStaff,
    required this.selectedIds,
    required this.onApply,
  });

  @override
  State<DietitianFilterDialog> createState() => _DietitianFilterDialogState();
}

class _DietitianFilterDialogState extends State<DietitianFilterDialog> {
  late List<String> _tempSelected;
  String _searchQuery = "";

  @override
  void initState() {
    super.initState();
    _tempSelected = List.from(widget.selectedIds);
  }

  @override
  Widget build(BuildContext context) {
    final filteredStaff = widget.allStaff.where((s) => s.fullName.toLowerCase().contains(_searchQuery.toLowerCase())).toList();

    return AlertDialog(
      title: const Text("Filter Dietitians"),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              onChanged: (val) => setState(() => _searchQuery = val.toLowerCase()),
              decoration: const InputDecoration(
                hintText: "Search...",
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(onPressed: () => setState(() => _tempSelected = widget.allStaff.map((e) => e.id).toList()), child: const Text("Select All")),
                TextButton(onPressed: () => setState(() => _tempSelected = []), child: const Text("Clear")),
              ],
            ),
            const Divider(),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: filteredStaff.length,
                itemBuilder: (context, index) {
                  final staff = filteredStaff[index];
                  final isSelected = _tempSelected.contains(staff.id);
                  return CheckboxListTile(
                    title: Text(staff.fullName),
                    subtitle: Text(staff.designation),
                    value: isSelected,
                    onChanged: (val) => setState(() => val! ? _tempSelected.add(staff.id) : _tempSelected.remove(staff.id)),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
        ElevatedButton(
          onPressed: () {
            widget.onApply(_tempSelected);
            Navigator.pop(context);
          },
          child: const Text("Apply"),
        ),
      ],
    );
  }
}