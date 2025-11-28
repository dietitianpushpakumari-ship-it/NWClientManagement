import 'package:flutter/material.dart';

/// A reusable premium sheet for multi-selecting items from a master list.
/// Supports Add, Edit, Delete, Search, and Multi-select.
class PremiumMasterSelectSheet<T> extends StatefulWidget {
  final String title;
  final String itemLabel; // e.g. "Diagnosis", "Complaint"

  // Data Source
  final Stream<List<T>> stream;

  // Mappers
  final String Function(T) getName;
  final String Function(T) getId;

  // Actions
  final Future<void> Function(String name) onAdd;
  final Future<void> Function(T item, String newName) onEdit;
  final Future<void> Function(T item) onDelete;

  // Initial State
  final List<String> selectedIds; // IDs of currently selected items

  const PremiumMasterSelectSheet({
    super.key,
    required this.title,
    required this.itemLabel,
    required this.stream,
    required this.getName,
    required this.getId,
    required this.onAdd,
    required this.onEdit,
    required this.onDelete,
    required this.selectedIds,
  });

  @override
  State<PremiumMasterSelectSheet<T>> createState() => _PremiumMasterSelectSheetState<T>();
}

class _PremiumMasterSelectSheetState<T> extends State<PremiumMasterSelectSheet<T>> {
  final TextEditingController _searchCtrl = TextEditingController();
  Set<String> _selectedIds = {};
  String _query = "";

  @override
  void initState() {
    super.initState();
    _selectedIds = Set.from(widget.selectedIds);
  }

  void _showAddEditDialog({T? item}) {
    final isEdit = item != null;
    final textCtrl = TextEditingController(text: isEdit ? widget.getName(item) : _searchCtrl.text);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isEdit ? "Edit ${widget.itemLabel}" : "Add New ${widget.itemLabel}"),
        content: TextField(
          controller: textCtrl,
          autofocus: true,
          decoration: InputDecoration(
            labelText: "${widget.itemLabel} Name",
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              if (textCtrl.text.trim().isNotEmpty) {
                if (isEdit) {
                  await widget.onEdit(item, textCtrl.text.trim());
                } else {
                  await widget.onAdd(textCtrl.text.trim());
                  // Auto-select logic could go here if we could resolve the new ID easily
                }
                if (mounted) Navigator.pop(ctx);
              }
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(T item) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Confirm Delete"),
        content: Text("Delete '${widget.getName(item)}' from master list?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              await widget.onDelete(item);
              if (mounted) Navigator.pop(ctx);
            },
            child: const Text("Delete"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // 1. Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(widget.title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          // 2. Search & Add Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchCtrl,
                    decoration: InputDecoration(
                      hintText: "Search or Add...",
                      prefixIcon: const Icon(Icons.search),
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                    onChanged: (v) => setState(() => _query = v.toLowerCase()),
                  ),
                ),
                const SizedBox(width: 10),
                FloatingActionButton.small(
                  onPressed: () => _showAddEditDialog(),
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  child: const Icon(Icons.add, color: Colors.white),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // 3. List
          Expanded(
            child: StreamBuilder<List<T>>(
              stream: widget.stream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                if (snapshot.hasError) return Center(child: Text("Error: ${snapshot.error}"));

                final allItems = snapshot.data ?? [];
                final filtered = _query.isEmpty
                    ? allItems
                    : allItems.where((i) => widget.getName(i).toLowerCase().contains(_query)).toList();

                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.search_off, size: 48, color: Colors.grey),
                        const SizedBox(height: 10),
                        Text("No ${widget.itemLabel} found.", style: const TextStyle(color: Colors.grey)),
                        if (_query.isNotEmpty)
                          TextButton(onPressed: () => _showAddEditDialog(), child: Text("Create '$_query'"))
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.only(bottom: 80),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const Divider(height: 1, indent: 16, endIndent: 16),
                  itemBuilder: (context, index) {
                    final item = filtered[index];
                    final id = widget.getId(item);
                    final name = widget.getName(item);
                    final isSelected = _selectedIds.contains(id);

                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                      title: Text(name, style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, color: isSelected ? Theme.of(context).colorScheme.primary : Colors.black87)),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (isSelected)  Icon(Icons.check_circle, color: Theme.of(context).colorScheme.primary),
                          PopupMenuButton<String>(
                            icon: const Icon(Icons.more_vert, color: Colors.grey, size: 20),
                            onSelected: (v) => v == 'edit' ? _showAddEditDialog(item: item) : _confirmDelete(item),
                            itemBuilder: (context) => [
                              const PopupMenuItem(value: 'edit', child: Text("Edit")),
                              const PopupMenuItem(value: 'delete', child: Text("Delete", style: TextStyle(color: Colors.red))),
                            ],
                          ),
                        ],
                      ),
                      onTap: () {
                        setState(() {
                          if (isSelected) _selectedIds.remove(id);
                          else _selectedIds.add(id);
                        });
                      },
                    );
                  },
                );
              },
            ),
          ),

          // 4. Footer
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))],
            ),
            child: SafeArea(
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context, _selectedIds.toList()),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text("Done (${_selectedIds.length} Selected)", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}