import 'package:flutter/material.dart';
import 'package:nutricare_client_management/master/model/disease_master_model.dart';
import 'package:nutricare_client_management/master/service/disease_master_service.dart';

class MedicalHistoryMultiSelectDialog extends StatefulWidget {
  final List<String> initialSelectedNames;

  const MedicalHistoryMultiSelectDialog({
    super.key,
    required this.initialSelectedNames,
  });

  @override
  State<MedicalHistoryMultiSelectDialog> createState() => _MedicalHistoryMultiSelectDialogState();
}

class _MedicalHistoryMultiSelectDialogState extends State<MedicalHistoryMultiSelectDialog> {
  final TextEditingController _searchController = TextEditingController();
  List<DiseaseMasterModel> _allDiseases = [];
  List<DiseaseMasterModel> _filteredDiseases = [];
  Set<String> _selectedNames = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _selectedNames = Set.from(widget.initialSelectedNames);
    _fetchData();
    _searchController.addListener(_filterData);
  }

  Future<void> _fetchData() async {
    try {
      // Use the updated service to get list
      final list = await DiseaseMasterService().getActiveDiseasesList();
      if (mounted) {
        setState(() {
          _allDiseases = list;
          _filteredDiseases = list;
          _isLoading = false;
        });
      }
    } catch (e) {
      if(mounted) setState(() => _isLoading = false);
    }
  }

  void _filterData() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredDiseases = _allDiseases;
      } else {
        _filteredDiseases = _allDiseases.where((d) =>
            d.enName.toLowerCase().contains(query)
        ).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Select Medical Conditions'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                labelText: 'Search',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            Flexible(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _filteredDiseases.isEmpty
                  ? const Padding(padding: EdgeInsets.all(20), child: Text("No conditions found"))
                  : ListView.builder(
                shrinkWrap: true,
                itemCount: _filteredDiseases.length,
                itemBuilder: (context, index) {
                  final disease = _filteredDiseases[index];
                  final isSelected = _selectedNames.contains(disease.enName);
                  return CheckboxListTile(
                    title: Text(disease.enName),
                    value: isSelected,
                    onChanged: (bool? value) {
                      setState(() {
                        if (value == true) {
                          _selectedNames.add(disease.enName);
                        } else {
                          _selectedNames.remove(disease.enName);
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
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, _selectedNames.toList()),
          child: const Text('Confirm'),
        ),
      ],
    );
  }
}