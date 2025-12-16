import 'package:flutter/cupertino.dart';
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

  void _filterItems() {
    final query = _searchController.text.toLowerCase();
    setState(() {
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


  @override
  Widget build(BuildContext context) {
    return Container(
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
                  child: TextFormField(
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
                    // Close the bottom sheet, then navigate to the master entry screen
                    Navigator.pop(context);
                    widget.onAddMaster();
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              itemCount: _filteredItems.length,
              itemBuilder: (context, index) {
                final item = _filteredItems[index];
                final isSelected = _selectedItems.contains(item);
                // Note: The document ID lookup (widget.itemNameIdMap[item]) is not used here
                // but is now available for future use (like advanced filtering or audit logging).
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
    );
  }
}