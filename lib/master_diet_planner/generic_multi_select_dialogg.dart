import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nutricare_client_management/admin/database_provider.dart';

class GenericMultiSelectDialog extends ConsumerStatefulWidget {
  final String title;
  final List<String> items;
  final Map<String, String> itemNameIdMap;
  final List<String> initialSelectedItems;
  final bool singleSelect;

  // 🎯 Option A: Direct Firestore Collection (Standard Masters)
  final String? collectionPath;
  final AutoDisposeFutureProvider<Map<String, String>>? providerToRefresh;

  // 🎯 Option B: Custom Logic Callback (Special Cases like Staff)
  final Future<void> Function(String)? onAddNewItem;

  const GenericMultiSelectDialog({
    Key? key,
    required this.title,
    required this.items,
    required this.itemNameIdMap,
    required this.initialSelectedItems,
    this.collectionPath,
    this.providerToRefresh,
    this.onAddNewItem, // 🎯 New Callback
    this.singleSelect = false,
  }) : super(key: key);

  @override
  ConsumerState<GenericMultiSelectDialog> createState() => _GenericMultiSelectDialogState();
}

class _GenericMultiSelectDialogState extends ConsumerState<GenericMultiSelectDialog> {
  late List<String> _selectedItems;
  late List<String> _filteredItems;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedItems = List.from(widget.initialSelectedItems);
    _filteredItems = List.from(widget.items);
    _searchController.addListener(_filterItems);
  }

  @override
  void didUpdateWidget(covariant GenericMultiSelectDialog oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Sync if parent list updates (e.g. Stream updates)
    if (oldWidget.items != widget.items) {
      setState(() {
        final currentLocal = Set<String>.from(_filteredItems);
        currentLocal.addAll(widget.items);
        _filteredItems = currentLocal.toList();
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterItems() {
    setState(() {});
  }

  void _handleSelection(String item, bool selected) {
    if (widget.singleSelect) {
      setState(() => _selectedItems = selected ? [item] : []);
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

  // 🎯 UNIFIED INTERNAL ADD LOGIC
  void _showAddDialog() {
    String newItem = '';
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Add New ${widget.title.replaceAll("Select ", "")}'),
        content: TextField(
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Name', hintText: 'Enter name'),
          onChanged: (v) => newItem = v,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final val = newItem.trim();
              if (val.isEmpty) return;

              // 1. Duplicate Check
              final exists = _filteredItems.any((k) => k.toLowerCase() == val.toLowerCase());
              if (exists) {
                ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("'$val' already exists."), backgroundColor: Colors.orange)
                );
                return;
              }

              // 2. Formatting
              final finalName = val.length > 1
                  ? val[0].toUpperCase() + val.substring(1)
                  : val.toUpperCase();

              try {
                // 3a. Option A: Direct Firestore Add
                if (widget.collectionPath != null) {
                  await ref.read(firestoreProvider).collection(widget.collectionPath!).add({
                    'name': finalName,
                    'isActive': true,
                    'createdAt': FieldValue.serverTimestamp()
                  });
                  if (widget.providerToRefresh != null) {
                    ref.invalidate(widget.providerToRefresh!);
                  }
                }
                // 3b. Option B: Custom Callback
                else if (widget.onAddNewItem != null) {
                  await widget.onAddNewItem!(finalName);
                }

                if (mounted) {
                  Navigator.pop(ctx); // Close Input Dialog

                  // 4. Update Local UI immediately (Optimistic update)
                  setState(() {
                    if (!_filteredItems.contains(finalName)) {
                      _filteredItems.insert(0, finalName);
                    }
                    if (widget.singleSelect) {
                      _selectedItems = [finalName];
                    } else {
                      if (!_selectedItems.contains(finalName)) _selectedItems.add(finalName);
                    }
                  });
                }
              } catch (e) {
                debugPrint("Error adding master: $e");
                ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red)
                );
              }
            },
            child: const Text('Add & Select'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final query = _searchController.text.toLowerCase();
    final displayList = _filteredItems.where((i) => i.toLowerCase().contains(query)).toList();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        height: MediaQuery.of(context).size.height * 0.85,
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
                  Expanded(
                    child: Text(
                      widget.title + (widget.singleSelect ? ' (Single)' : ''),
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                    ),
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
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        labelText: 'Search',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // 🎯 ENABLE ADD BUTTON if either method is provided
                  if (widget.collectionPath != null || widget.onAddNewItem != null)
                    IconButton(
                      icon: const Icon(Icons.add_circle, color: Colors.indigo, size: 32),
                      tooltip: 'Add New',
                      onPressed: _showAddDialog,
                    ),
                ],
              ),
            ),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                itemCount: displayList.length,
                separatorBuilder: (c, i) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final item = displayList[index];
                  final isSelected = _selectedItems.contains(item);
                  return CheckboxListTile(
                    title: Text(item),
                    value: isSelected,
                    onChanged: (bool? selected) => _handleSelection(item, selected ?? false),
                    activeColor: Colors.indigo,
                    controlAffinity: ListTileControlAffinity.leading,
                    dense: true,
                  );
                },
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(16, 8, 16, MediaQuery.of(context).padding.bottom + 16),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  backgroundColor: Colors.indigo,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text('Done (${_selectedItems.length} selected)'),
                onPressed: () => Navigator.pop(context, _selectedItems),
              ),
            ),
          ],
        ),
      ),
    );
  }
}