import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:nutricare_client_management/master/model/diagonosis_master.dart';

class DiagnosisMultiSelectDialog extends StatefulWidget {
  final List<DiagnosisMasterModel> allDiagnoses;
  final List<String> initialSelectedIds;

  const DiagnosisMultiSelectDialog({
    super.key,
    required this.allDiagnoses,
    required this.initialSelectedIds,
  });

  @override
  State<DiagnosisMultiSelectDialog> createState() =>
      _DiagnosisMultiSelectDialogState();
}

class _DiagnosisMultiSelectDialogState
    extends State<DiagnosisMultiSelectDialog> {
  final TextEditingController _searchController = TextEditingController();
  List<String> _currentSelectedIds = [];
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _currentSelectedIds = List.from(widget.initialSelectedIds);
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.toLowerCase();
    });
  }

  List<DiagnosisMasterModel> get _filteredDiagnoses {
    if (_searchQuery.isEmpty) {
      return widget.allDiagnoses;
    }
    return widget.allDiagnoses.where((diag) {
      return diag.enName.toLowerCase().contains(_searchQuery) ||
          diag.id.toLowerCase().contains(_searchQuery);
    }).toList();
  }

  void _toggleSelection(String diagnosisId) {
    setState(() {
      if (_currentSelectedIds.contains(diagnosisId)) {
        _currentSelectedIds.remove(diagnosisId);
      } else {
        _currentSelectedIds.add(diagnosisId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Select Diagnoses'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Search Bar
            Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  labelText: 'Search Diagnosis',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(
                    vertical: 10,
                    horizontal: 10,
                  ),
                ),
              ),
            ),

            // List of Diagnoses
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _filteredDiagnoses.length,
                itemBuilder: (context, index) {
                  final diagnosis = _filteredDiagnoses[index];
                  final isSelected = _currentSelectedIds.contains(diagnosis.id);
                  return CheckboxListTile(
                    title: Text(diagnosis.enName),
                    subtitle: Text(
                      diagnosis.id,
                      style: const TextStyle(fontSize: 10, color: Colors.grey),
                    ),
                    value: isSelected,
                    onChanged: (bool? newValue) {
                      if (newValue != null) {
                        _toggleSelection(diagnosis.id);
                      }
                    },
                    secondary: isSelected
                        ? const Icon(Icons.check_circle, color: Colors.red)
                        : null,
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(null), // Cancel/Close
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(_currentSelectedIds),
          child: Text('Confirm (${_currentSelectedIds.length})'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red.shade700,
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }
}
