
import 'package:flutter/material.dart';

class GenericMultiSelectDialog extends StatefulWidget {
  final String title;
  final List<String> items;
  // 🎯 ADDED: Map of Name -> Document ID to correctly handle service data structure
  final Map<String, String> itemNameIdMap;
  final List<String> initialSelectedItems;
  final VoidCallback onAddMaster;
  final bool singleSelect;

  const GenericMultiSelectDialog({
    Key? key,
    required this.title,
    required this.items,
    required this.itemNameIdMap, // 🎯 REQUIRED in constructor
    required this.initialSelectedItems,
    required this.onAddMaster,
    this.singleSelect = false,
  }) : super(key: key);

  @override
  _GenericMultiSelectDialogState createState() => _GenericMultiSelectDialogState();
}

class _GenericMultiSelectDialogState extends State<GenericMultiSelectDialog> {
  late List<String> _selectedItems;
  final TextEditingController _searchController = TextEditingController();
  List<String> _filteredItems = [];

  @override
  void initState() {
    super.initState();
    _selectedItems = List.from(widget.initialSelectedItems);
    _filteredItems = widget.items;
    _searchController.addListener(_filterItems);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
  // lib/master_diet_planner/generic_multi_select_dialogg.dart

// lib/master_diet_planner/generic_multi_select_dialogg.dart

// 🎯 Change the build method to use a StreamBuilder or rebuild on item additions.
// However, the easiest fix to your existing code is to ensure the list passed in is reactive.
// lib/master_diet_planner/generic_multi_select_dialogg.dart

  @override
  void didUpdateWidget(covariant GenericMultiSelectDialog oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Re-filter the list if the source items changed
    if (oldWidget.items != widget.items) {
      _filterItems();
    }
  }

  void _filterItems() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      // 🎯 Always use widget.items as the source of truth
      _filteredItems = widget.items
          .where((item) => item.toLowerCase().contains(query))
          .toList();
    });
  }

  void _handleSelection(String item, bool selected) {
    if (widget.singleSelect) {
      setState(() {
        _selectedItems = selected ? [item] : [];
      });
    } else {
      setState(() {
        if (selected) {
          _selectedItems.add(item);
        } else {
          _selectedItems.remove(item);
        }
      });
    }
  }


  // lib/master_diet_planner/generic_multi_select_dialogg.dart

  @override
  Widget build(BuildContext context) {
    // Wrap the entire content in a Scaffold to provide Material context
    return Scaffold(
      backgroundColor: Colors.transparent, // Keeps the underlying bottom sheet look
      body: Container(
        height: MediaQuery.of(context).size.height * 0.9,
        decoration: const BoxDecoration(
          color: Color(0xFFF8F9FE),
          borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.title + (widget.singleSelect ? ' (Single Select)' : ''),
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextFormField( // 🎯 Now has the required Material ancestor
                      controller: _searchController,
                      decoration: InputDecoration(
                        labelText: 'Search ${widget.title.split(' ').last}',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.add_circle, color: Colors.green, size: 30),
                    tooltip: 'Add New Master',
                    onPressed: () {
                     // Navigator.pop(context);
                      widget.onAddMaster();
                    },
                  ),
                ],
              ),
            ),
            Expanded( // 🎯 Correctly constrains the ListView to prevent overflow
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                itemCount: _filteredItems.length,
                itemBuilder: (context, index) {
                  final item = _filteredItems[index];
                  final isSelected = _selectedItems.contains(item);
                  return CheckboxListTile(
                    title: Text(item),
                    value: isSelected,
                    onChanged: (bool? selected) => _handleSelection(item, selected ?? false),
                    activeColor: Theme.of(context).colorScheme.primary,
                  );
                },
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(16, 8, 16, MediaQuery.of(context).padding.bottom + 16),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Confirm Selection'),
                onPressed: () => Navigator.pop(context, _selectedItems),
              ),
            ),
          ],
        ),
      ),
    );
  }
}