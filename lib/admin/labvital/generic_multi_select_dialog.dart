import 'package:flutter/material.dart';
import 'package:nutricare_client_management/admin/labvital/clinical_master_service.dart';
class GenericClinicalMultiSelectDialog extends StatefulWidget {
  final String title;
  final String collectionName;
  final List<String> initialSelectedItems;

  const GenericClinicalMultiSelectDialog({
    super.key,
    required this.title,
    required this.collectionName,
    required this.initialSelectedItems,
  });

  @override
  State<GenericClinicalMultiSelectDialog> createState() => _GenericClinicalMultiSelectDialogState();
}

class _GenericClinicalMultiSelectDialogState extends State<GenericClinicalMultiSelectDialog> {
  final ClinicalMasterService _service = ClinicalMasterService();
  final TextEditingController _searchController = TextEditingController();

  List<String> _allItems = [];
  List<String> _filteredItems = [];
  Set<String> _selectedItems = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _selectedItems = Set.from(widget.initialSelectedItems);
    _searchController.addListener(_filterList);
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Fetch Master Data
  Future<void> _loadData() async {
    // Note: In a real app, you might want to optimize this to not fetch ALL items if the list is huge.
    // For now, we stream the names.
    final stream = _service.streamItemNames(widget.collectionName);
    stream.listen((data) {
      if (mounted) {
        setState(() {
          _allItems = data;
          _filterList(); // Re-apply filter
          _isLoading = false;
        });
      }
    });
  }

  void _filterList() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredItems = _allItems;
      } else {
        _filteredItems = _allItems.where((item) => item.toLowerCase().contains(query)).toList();
      }
    });
  }

  Future<void> _addNewItem() async {
    final text = _searchController.text.trim();
    if (text.isEmpty) return;

    // Check if already exists locally to avoid duplicate call
    if (_allItems.contains(text)) {
      if (!_selectedItems.contains(text)) {
        setState(() => _selectedItems.add(text));
      }
      return;
    }

    // Add to Firestore Master
    try {
      await _service.addItem(widget.collectionName, text);
      // Select it automatically once added
      setState(() {
        _selectedItems.add(text);
        _searchController.clear();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      contentPadding: const EdgeInsets.only(top: 16, bottom: 0),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      decoration: const InputDecoration(
                          hintText: "Search or Add New...",
                          prefixIcon: Icon(Icons.search),
                          border: OutlineInputBorder(),
                          isDense: true,
                          contentPadding: EdgeInsets.all(12)
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Quick Add Button
                  IconButton(
                    onPressed: _addNewItem,
                    icon: const Icon(Icons.add_circle, color: Colors.indigo, size: 32),
                    tooltip: "Add to Master",
                  ),
                ],
              ),
            ),
            const Divider(),

            // List
            Flexible(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.builder(
                shrinkWrap: true,
                itemCount: _filteredItems.length,
                itemBuilder: (context, index) {
                  final item = _filteredItems[index];
                  final isSelected = _selectedItems.contains(item);
                  return CheckboxListTile(
                    title: Text(item),
                    value: isSelected,
                    onChanged: (bool? value) {
                      setState(() {
                        if (value == true) {
                          _selectedItems.add(item);
                        } else {
                          _selectedItems.remove(item);
                        }
                      });
                    },
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
          onPressed: () => Navigator.pop(context, _selectedItems.toList()),
          child: const Text("Confirm"),
        ),
      ],
    );
  }
}