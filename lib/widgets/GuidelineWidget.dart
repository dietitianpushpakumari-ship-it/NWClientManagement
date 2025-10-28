import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:nutricare_client_management/modules/master/model/guidelines.dart';
import 'package:nutricare_client_management/modules/master/service/guideline_service.dart';

class GuidelineMultiSelect extends StatefulWidget {
  final List<String> initialSelectedIds;

  const GuidelineMultiSelect({super.key, required this.initialSelectedIds});

  @override
  State<GuidelineMultiSelect> createState() => _GuidelineMultiSelectState();
}

class _GuidelineMultiSelectState extends State<GuidelineMultiSelect> {
  final TextEditingController _searchController = TextEditingController();
  List<Guideline> _allGuidelines = [];
  List<Guideline> _filteredGuidelines = [];
  Set<String> _selectedIds = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _selectedIds = Set.from(widget.initialSelectedIds);
    _fetchGuidelines();
    _searchController.addListener(_filterGuidelines);
  }

  @override
  void dispose() {
    _searchController.removeListener(_filterGuidelines);
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchGuidelines() async {
    try {
      // NOTE: Placeholder for your actual service call
      final fetched = await GuidelineService().streamAllGuidelines().first;
      setState(() {
        _allGuidelines = fetched;
        _filteredGuidelines = fetched;
        _isLoading = false;
      });
    } catch (e) {
      // Handle error fetching guidelines
      setState(() => _isLoading = false);
      // Optional: Show error
    }
  }

  void _filterGuidelines() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredGuidelines = _allGuidelines.where((g) {
        return g.enTitle.toLowerCase().contains(query);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Select Guidelines'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // --- Search Field (Filter) ---
            Padding(
              padding: const EdgeInsets.only(bottom: 10.0),
              child: TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  labelText: 'Filter Guidelines',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                ),
              ),
            ),

            // --- Guideline List ---
            Flexible(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _filteredGuidelines.isEmpty
                  ? const Center(child: Text('No matching guidelines found.'))
                  : ListView.builder(
                shrinkWrap: true,
                itemCount: _filteredGuidelines.length,
                itemBuilder: (context, index) {
                  final guideline = _filteredGuidelines[index];
                  final isSelected = _selectedIds.contains(guideline.id);
                  return CheckboxListTile(
                    title: Text(guideline.enTitle),
                    value: isSelected,
                    onChanged: (bool? value) {
                      setState(() {
                        if (value == true) {
                          _selectedIds.add(guideline.id);
                        } else {
                          _selectedIds.remove(guideline.id);
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
        TextButton(
          onPressed: () => Navigator.of(context).pop(null), // Cancel
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          // Return the final selected list of IDs
          onPressed: () => Navigator.of(context).pop(_selectedIds.toList()),
          child: const Text('Confirm'),
        ),
      ],
    );
  }
}