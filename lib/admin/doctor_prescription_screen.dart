import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// 🎯 IMPORTS
import 'package:nutricare_client_management/admin/database_provider.dart';
import 'package:nutricare_client_management/helper/auth_service.dart';
import 'package:nutricare_client_management/modules/medical/models/prescription_model.dart';
import 'package:nutricare_client_management/modules/client/model/vitals_model.dart';

// Constants
const Color kMedicalBlue = Color(0xFF0D47A1);
const Color kMedicalLight = Color(0xFFE3F2FD);

class DoctorPrescriptionScreen extends ConsumerStatefulWidget {
  final String sessionId;
  final String clientId;
  final String clientName;
  final VitalsModel? latestVitals;
  final bool isReadOnly;
  final Function(dynamic)? onSaveAssessment;

  const DoctorPrescriptionScreen({
    super.key,
    required this.sessionId,
    required this.clientId,
    this.clientName = "Patient",
    this.latestVitals,
    this.isReadOnly = false,
    this.onSaveAssessment,
  });

  @override
  ConsumerState<DoctorPrescriptionScreen> createState() => _DoctorPrescriptionScreenState();
}

class _DoctorPrescriptionScreenState extends ConsumerState<DoctorPrescriptionScreen> {
  // Controllers
  final _diagnosisCtrl = TextEditingController();
  final _symptomsCtrl = TextEditingController();
  final _adviceCtrl = TextEditingController();
  final _labSearchCtrl = TextEditingController();

  // State
  List<PrescribedMedicine> _medications = [];
  List<String> _selectedLabs = [];
  bool _isSaving = false;

  // ===========================================================================
  // 1. VITALS HEADER WIDGET
  // ===========================================================================
  Widget _buildVitalsStrip() {
    if (widget.latestVitals == null) return const SizedBox.shrink();
    final v = widget.latestVitals!;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange.shade100),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildVitalItem("BP", "${v.bloodPressureSystolic}/${v.bloodPressureDiastolic}", Icons.favorite),
          _buildVitalItem("Weight", "${v.weightKg} kg", Icons.monitor_weight),
        //  _buildVitalItem("Sugar (F)", "${v.bloodSugarFasting ?? '-'}", Icons.water_drop),
          //_buildVitalItem("Sugar (PP)", "${v.bloodSugarPP ?? '-'}", Icons.restaurant),
        ],
      ),
    );
  }

  Widget _buildVitalItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Row(children: [Icon(icon, size: 14, color: Colors.orange.shade800), const SizedBox(width: 4), Text(label, style: TextStyle(fontSize: 10, color: Colors.orange.shade900))]),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
      ],
    );
  }

  // ===========================================================================
  // 2. ADD MEDICINE SHEET
  // ===========================================================================
  void _openAddMedicineSheet() {
    String name = '';
    String dosage = '500mg';
    String freq = '1-0-1'; // Default
    String duration = '5 Days';
    String instruction = 'After Food';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Add Medication", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: kMedicalBlue)),
              const SizedBox(height: 16),

              // Name Input
              TextFormField(
                autofocus: true,
                decoration: InputDecoration(
                  labelText: "Medicine Name",
                  hintText: "e.g., Paracetamol",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.medication),
                ),
                onChanged: (v) => name = v,
              ),
              const SizedBox(height: 16),

              // Frequency Toggles
              const Text("Frequency", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: ["1-0-1", "1-1-1", "1-0-0", "0-0-1", "SOS"].map((f) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(f),
                      selected: freq == f,
                      selectedColor: kMedicalBlue,
                      labelStyle: TextStyle(color: freq == f ? Colors.white : Colors.black),
                      onSelected: (v) => setModalState(() => freq = f),
                    ),
                  )).toList(),
                ),
              ),
              const SizedBox(height: 16),

              // Dosage & Duration Row
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      initialValue: dosage,
                      decoration: const InputDecoration(labelText: "Dosage", border: OutlineInputBorder()),
                      onChanged: (v) => dosage = v,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      initialValue: duration,
                      decoration: const InputDecoration(labelText: "Duration", border: OutlineInputBorder()),
                      onChanged: (v) => duration = v,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Instruction
              DropdownButtonFormField<String>(
                value: instruction,
                decoration: const InputDecoration(labelText: "Instruction", border: OutlineInputBorder()),
                items: ["After Food", "Before Food", "Empty Stomach", "Before Sleep"].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                onChanged: (v) => instruction = v!,
              ),

              const SizedBox(height: 24),
              SizedBox(width: double.infinity, height: 50, child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: kMedicalBlue, foregroundColor: Colors.white),
                onPressed: () {
                  if (name.isNotEmpty) {
                    setState(() {
                      _medications.add(PrescribedMedicine(name: name, dosage: dosage, frequency: freq, duration: duration, instruction: instruction));
                    });
                    Navigator.pop(ctx);
                  }
                },
                child: const Text("ADD TO PRESCRIPTION"),
              )),
            ],
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // 3. SAVE LOGIC
  // ===========================================================================
  Future<void> _savePrescription() async {
    if (_medications.isEmpty && _diagnosisCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Prescription is empty! Add diagnosis or meds.")));
      return;
    }

    setState(() => _isSaving = true);

    try {
      final doctorId = ref.read(authServiceProvider).currentUser?.uid ?? 'unknown';
      final prescription = PrescriptionModel(
        id: '', // Auto-gen by Firestore
        sessionId: widget.sessionId,
        clientId: widget.clientId,
        doctorId: doctorId,
        date: DateTime.now(),
        diagnosis: _diagnosisCtrl.text,
        chiefComplaints: _symptomsCtrl.text,
        medications: _medications,
        labTests: _selectedLabs,
        advice: _adviceCtrl.text,
      );

      // 1. Save to 'prescriptions' collection
      await ref.read(firestoreProvider).collection('prescriptions').add(prescription.toMap());

      // 2. Update Session Step
      await ref.read(firestoreProvider).collection('consultation_sessions').doc(widget.sessionId).update({
        'steps.prescription': true,
        'status': 'in_progress',
      });

      // 3. Trigger Callback
      if (widget.onSaveAssessment != null) {
        widget.onSaveAssessment!(true);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Prescription Saved Successfully!"), backgroundColor: Colors.green));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // ===========================================================================
  // 4. MAIN BUILD
  // ===========================================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      appBar: AppBar(
        title: const Text("Write Prescription", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          TextButton(
            onPressed: (widget.isReadOnly || _isSaving) ? null : _savePrescription,
            child: _isSaving ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text("SAVE & SEND", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // A. VITALS
            _buildVitalsStrip(),

            // B. PATIENT HEADER
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: kMedicalBlue.withOpacity(0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: kMedicalBlue.withOpacity(0.2))),
              child: Row(children: [
                const Icon(Icons.person, color: kMedicalBlue, size: 30),
                const SizedBox(width: 12),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text("Patient: ${widget.clientName}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: kMedicalBlue)),
                  Text("Date: ${DateFormat('dd MMM yyyy').format(DateTime.now())}", style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
                ])
              ]),
            ),
            const SizedBox(height: 24),

            // C. DIAGNOSIS & SYMPTOMS
            _buildSectionTitle("Diagnosis & Clinical Notes"),
            _buildTextField(_diagnosisCtrl, "Provisional Diagnosis", Icons.local_hospital),
            const SizedBox(height: 12),
            _buildTextField(_symptomsCtrl, "Chief Complaints / Symptoms", Icons.sick, maxLines: 2),
            const SizedBox(height: 24),

            // D. MEDICATIONS
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildSectionTitle("Rx Medications"),
                ElevatedButton.icon(
                  onPressed: _openAddMedicineSheet,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text("Add Medicine"),
                  style: ElevatedButton.styleFrom(backgroundColor: kMedicalBlue, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
                )
              ],
            ),
            const SizedBox(height: 8),
            if (_medications.isEmpty)
              Container(padding: const EdgeInsets.all(20), width: double.infinity, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade300)), child: const Center(child: Text("No medications added yet.", style: TextStyle(color: Colors.grey)))),

            ..._medications.asMap().entries.map((entry) {
              final i = entry.key;
              final med = entry.value;
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5)]),
                child: Row(
                  children: [
                    CircleAvatar(backgroundColor: kMedicalLight, child: Text("${i + 1}", style: const TextStyle(color: kMedicalBlue, fontWeight: FontWeight.bold))),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(med.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 4),
                        Row(children: [
                          _buildTag(med.dosage, Colors.blue),
                          const SizedBox(width: 8),
                          _buildTag(med.frequency, Colors.purple),
                          const SizedBox(width: 8),
                          _buildTag(med.duration, Colors.orange),
                        ]),
                        const SizedBox(height: 4),
                        Text(med.instruction, style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.grey)),
                      ]),
                    ),
                    IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => setState(() => _medications.removeAt(i)))
                  ],
                ),
              );
            }).toList(),
            const SizedBox(height: 24),

            // E. LAB ORDERS
            _buildSectionTitle("Lab Tests & Investigations"),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade300)),
              child: Row(children: [
                const Icon(Icons.science, color: Colors.grey),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _labSearchCtrl,
                    decoration: const InputDecoration(border: InputBorder.none, hintText: "Type test name (e.g. Thyroid Profile)"),
                    onSubmitted: (val) {
                      if(val.isNotEmpty) {
                        setState(() { _selectedLabs.add(val); _labSearchCtrl.clear(); });
                      }
                    },
                  ),
                ),
                IconButton(icon: const Icon(Icons.add_circle, color: kMedicalBlue), onPressed: () {
                  if(_labSearchCtrl.text.isNotEmpty) setState(() { _selectedLabs.add(_labSearchCtrl.text); _labSearchCtrl.clear(); });
                })
              ]),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: _selectedLabs.map((lab) => Chip(
                label: Text(lab),
                backgroundColor: kMedicalLight,
                labelStyle: const TextStyle(color: kMedicalBlue, fontWeight: FontWeight.bold),
                deleteIcon: const Icon(Icons.close, size: 16, color: kMedicalBlue),
                onDeleted: () => setState(() => _selectedLabs.remove(lab)),
              )).toList(),
            ),
            const SizedBox(height: 24),

            // F. ADVICE
            _buildSectionTitle("General Advice"),
            _buildTextField(_adviceCtrl, "Dietary or lifestyle instructions...", Icons.lightbulb, maxLines: 3),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // --- HELPERS ---
  Widget _buildSectionTitle(String title) => Padding(padding: const EdgeInsets.only(bottom: 12), child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)));

  Widget _buildTextField(TextEditingController c, String label, IconData icon, {int maxLines = 1}) {
    return TextField(
      controller: c, maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label, prefixIcon: Icon(icon, color: Colors.grey),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
        filled: true, fillColor: Colors.white, enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
      ),
    );
  }

  Widget _buildTag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
      child: Text(text, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
    );
  }
}