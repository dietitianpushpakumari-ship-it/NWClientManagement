import 'package:flutter/material.dart';
import 'package:nutricare_client_management/admin/labvital/clinical_model.dart';
import 'package:nutricare_client_management/admin/labvital/generic_multi_select_dialog.dart';
import 'package:nutricare_client_management/admin/labvital/medical_history_multiselect_dialog.dart';
import 'package:nutricare_client_management/meal_planner/screen/disease_master_entry_screen.dart';
import 'package:nutricare_client_management/modules/master/screen/DiagonosisEntryPage.dart';
import 'package:nutricare_client_management/modules/master/service/diagonosis_master_service.dart';
import 'package:nutricare_client_management/widgets/diagonosis_multi_select_dialog.dart';

import 'clinical_master_service.dart';
class ClinicalProfileSection extends StatefulWidget {
  final List<String> selectedDiagnosisIds;
  final Map<String, String> medicalHistoryWithDuration;
  final List<String> selectedComplaints;
  final List<String> selectedAllergies;

  final List<PrescribedMedication> prescribedMedications;
  final Function(List<PrescribedMedication>) onMedicationsChanged;

  final Function(List<String>) onDiagnosesChanged;
  final Function(Map<String, String>) onHistoryChanged;
  final Function(String) onAddComplaint;
  final Function(String) onRemoveComplaint;
  final Function(String) onAddAllergy;
  final Function(String) onRemoveAllergy;

  // Helper to bulk update complaints/allergies from dialog
  final Function(List<String>) onComplaintsListChanged;
  final Function(List<String>) onAllergiesListChanged;

  const ClinicalProfileSection({
    super.key,
    required this.selectedDiagnosisIds,
    required this.medicalHistoryWithDuration,
    required this.selectedComplaints,
    required this.selectedAllergies,
    required this.prescribedMedications,
    required this.onMedicationsChanged,
    required this.onDiagnosesChanged,
    required this.onHistoryChanged,
    required this.onAddComplaint,
    required this.onRemoveComplaint,
    required this.onAddAllergy,
    required this.onRemoveAllergy,
    required this.onComplaintsListChanged, // 🎯 You need to add this to parent
    required this.onAllergiesListChanged, required TextEditingController medicationController,  // 🎯 You need to add this to parent
  });

  @override
  State<ClinicalProfileSection> createState() => _ClinicalProfileSectionState();
}

class _ClinicalProfileSectionState extends State<ClinicalProfileSection> {
  // 1. Diagnosis Handlers (Existing)
  Future<void> _openDiagnosisSelect() async {
    final allDiagnoses = await DiagnosisMasterService().fetchAllDiagnosisMaster();
    final result = await showDialog<List<String>>(
      context: context,
      builder: (context) => DiagnosisMultiSelectDialog(allDiagnoses: allDiagnoses, initialSelectedIds: widget.selectedDiagnosisIds),
    );
    if (result != null) widget.onDiagnosesChanged(result);
  }

  // 2. History Handlers (Existing)
  Future<void> _openHistorySelect() async {
    final result = await showDialog<List<String>>(
      context: context,
      builder: (context) => MedicalHistoryMultiSelectDialog(initialSelectedNames: widget.medicalHistoryWithDuration.keys.toList()),
    );
    if (result != null) {
      final Map<String, String> newMap = {};
              // Preserve durations for existing keys
      for (String name in result) {
        newMap[name] = widget.medicalHistoryWithDuration[name] ?? "";
      }
      widget.onHistoryChanged(newMap);
    }
  }

  // 3. Generic Handlers (Complaints & Allergies)
  Future<void> _openGenericSelect(
      String title,
      String collection,
      List<String> currentSelection,
      Function(List<String>) onUpdate
      ) async {
    final result = await showDialog<List<String>>(
      context: context,
      builder: (context) => GenericClinicalMultiSelectDialog(
        title: title,
        collectionName: collection,
        initialSelectedItems: currentSelection,
      ),
    );

    if (result != null) {
      onUpdate(result);
    }
  }

  // 4. Medicine Handler (Advanced)
  Future<void> _openMedicineSelect() async {
    // Get current medicine names
    final currentNames = widget.prescribedMedications.map((m) => m.medicineName).toList();

    final result = await showDialog<List<String>>(
      context: context,
      builder: (context) => GenericClinicalMultiSelectDialog(
        title: "Select Prescribed Medicines",
        collectionName: ClinicalMasterService.colMedicines,
        initialSelectedItems: currentNames,
      ),
    );

    if (result != null) {
      // Logic:
      // 1. Keep existing meds if name is in result
      // 2. Add new meds with default values for new names in result
      final List<PrescribedMedication> newList = [];

      for (var name in result) {
        final existing = widget.prescribedMedications.where((m) => m.medicineName == name).firstOrNull;
        if (existing != null) {
          newList.add(existing);
        } else {
          // Add new with defaults
          newList.add(PrescribedMedication(
              medicineName: name,
              frequency: "1-0-1",
              timing: "After Food"
          ));
        }
      }
      widget.onMedicationsChanged(newList);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- DIAGNOSIS ---
          _buildSectionHeader("Diagnosis / Conditions", Icons.local_hospital, Colors.purple),
          _buildControlRow("Select Diagnosis", _openDiagnosisSelect, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DiagnosisEntryPage()))),
          _buildDiagnosisChips(),

          const SizedBox(height: 30),

          // --- HISTORY ---
          _buildSectionHeader("Medical History", Icons.history, Colors.blueGrey),
          _buildControlRow("Select History", _openHistorySelect, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DiseaseMasterEntryScreen()))),
          _buildHistoryList(),

          const SizedBox(height: 30),

          // --- COMPLAINTS ---
          _buildSectionHeader("Chief Complaints", Icons.sick, Colors.orange),
          _buildControlRow(
              "Select Complaints",
                  () => _openGenericSelect(
                  "Select Complaints",
                  ClinicalMasterService.colComplaints,
                  widget.selectedComplaints,
                  widget.onComplaintsListChanged
              ),
              // For quick add, the dialog itself handles add. This button can point to master screen or just be hidden.
              null
          ),
          _buildStringChips(widget.selectedComplaints, widget.onRemoveComplaint),

          const SizedBox(height: 30),

          // --- ALLERGIES ---
          _buildSectionHeader("Allergies", Icons.warning_amber, Colors.red),
          _buildControlRow(
              "Select Allergies",
                  () => _openGenericSelect(
                  "Select Allergies",
                  ClinicalMasterService.colAllergies,
                  widget.selectedAllergies,
                  widget.onAllergiesListChanged
              ),
              null
          ),
          _buildStringChips(widget.selectedAllergies, widget.onRemoveAllergy),

          const SizedBox(height: 30),

          // --- MEDICINE ---
          _buildSectionHeader("Prescribed Medication", Icons.medication, Colors.teal),
          _buildControlRow("Select Medicines", _openMedicineSelect, null), // Add button is inside dialog
          const SizedBox(height: 10),
          _buildMedicationList(),
        ],
      ),
    );
  }

  // --- WIDGET BUILDERS ---

  Widget _buildMedicationList() {
    if (widget.prescribedMedications.isEmpty) {
      return const Text("No medications added.", style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic));
    }
    return Column(
      children: widget.prescribedMedications.asMap().entries.map((entry) {
        final index = entry.key;
        final med = entry.value;

        // Editable row
        return Card(
          elevation: 2,
          color: Colors.teal.shade50,
          margin: const EdgeInsets.only(bottom: 10),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(med.medicineName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.teal)),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.red, size: 20),
                      onPressed: () {
                        final list = List<PrescribedMedication>.from(widget.prescribedMedications)..removeAt(index);
                        widget.onMedicationsChanged(list);
                      },
                      constraints: const BoxConstraints(),
                      padding: EdgeInsets.zero,
                    )
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: med.frequency,
                        isDense: true,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          labelText: "Freq",
                        ),
                        items: ["1-0-0", "0-1-0", "0-0-1", "1-0-1", "1-1-1", "SOS", "Once a week"].map((e)=>DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontSize: 13)))).toList(),
                        onChanged: (v) {
                          final updated = PrescribedMedication(medicineName: med.medicineName, frequency: v!, timing: med.timing);
                          final list = List<PrescribedMedication>.from(widget.prescribedMedications);
                          list[index] = updated;
                          widget.onMedicationsChanged(list);
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: med.timing,
                        isDense: true,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          labelText: "Timing",
                        ),
                        items: ["Before Food", "After Food", "With Food", "Empty Stomach"].map((e)=>DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontSize: 13)))).toList(),
                        onChanged: (v) {
                          final updated = PrescribedMedication(medicineName: med.medicineName, frequency: med.frequency, timing: v!);
                          final list = List<PrescribedMedication>.from(widget.prescribedMedications);
                          list[index] = updated;
                          widget.onMedicationsChanged(list);
                        },
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildStringChips(List<String> items, Function(String) onRemove) {
    if (items.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: items.map((e) => Chip(
          label: Text(e),
          onDeleted: () => onRemove(e),
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: BorderSide(color: Colors.grey.shade300)),
        )).toList(),
      ),
    );
  }

  Widget _buildControlRow(String btnLabel, VoidCallback onSelect, VoidCallback? onAdd) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: onSelect,
            icon: const Icon(Icons.list),
            label: Text(btnLabel),
            style: OutlinedButton.styleFrom(
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            ),
          ),
        ),
        if (onAdd != null) ...[
          const SizedBox(width: 10),
          InkWell(
            onTap: onAdd,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.green.shade200)),
              child: const Icon(Icons.add, color: Colors.green),
            ),
          ),
        ]
      ],
    );
  }

  Widget _buildDiagnosisChips() {
    /* Use FutureBuilder to resolve names like before */
    // (Implementation same as previous step, just ensuring it's here)
    return widget.selectedDiagnosisIds.isEmpty
        ? const Text("None selected", style: TextStyle(color: Colors.grey, fontSize: 12))
        : FutureBuilder(
      // ... future builder logic for names ...
        future: DiagnosisMasterService().fetchAllDiagnosisMasterByIds(widget.selectedDiagnosisIds),
        builder: (ctx, snap) => Wrap(spacing: 8, children: (snap.data ?? []).map((d) => Chip(label: Text(d.enName), onDeleted: () => widget.onDiagnosesChanged(List.from(widget.selectedDiagnosisIds)..remove(d.id)))).toList())
    );
  }

  Widget _buildHistoryList() {
    // (Same as previous step logic for Duration inputs)
    return Column(
      children: widget.medicalHistoryWithDuration.entries.map((e) =>
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(e.key, style: const TextStyle(fontWeight: FontWeight.bold)),
            trailing: SizedBox(width: 100, child: TextFormField(initialValue: e.value, decoration: const InputDecoration(hintText: "Duration", isDense: true), onChanged: (v) {
              var map = Map<String, String>.from(widget.medicalHistoryWithDuration);
              map[e.key] = v;
              widget.onHistoryChanged(map);
            })),
            leading: IconButton(icon: const Icon(Icons.close, color: Colors.red), onPressed: () {
              var map = Map<String, String>.from(widget.medicalHistoryWithDuration);
              map.remove(e.key);
              widget.onHistoryChanged(map);
            }),
          )
      ).toList(),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(width: 10),
        Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueGrey.shade800))
      ]),
    );
  }
}