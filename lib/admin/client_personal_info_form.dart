import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nutricare_client_management/admin/patient_service.dart';
import 'package:nutricare_client_management/modules/client/model/client_model.dart';

class ClientPersonalInformationForm extends StatefulWidget {
  final Function(ClientModel) onProfileSaved;
  final ClientModel? initialProfile;

  const ClientPersonalInformationForm({
    super.key,
    this.initialProfile,
    required this.onProfileSaved,
  });

  @override
  State<ClientPersonalInformationForm> createState() => _ClientPersonalInformationFormState();
}

class _ClientPersonalInformationFormState extends State<ClientPersonalInformationForm> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final PatientIdService _patientIdService = PatientIdService();

  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _mobileCtrl = TextEditingController();
  final TextEditingController _addressCtrl = TextEditingController();
  final TextEditingController _ageCtrl = TextEditingController();

  String? _gender;
  bool _isSaving = false;
  bool _isEditing = false;
  final List<String> _genders = ['Male', 'Female', 'Other'];

  @override
  void initState() {
    super.initState();
    if (widget.initialProfile != null) {
      _isEditing = true;
      _nameCtrl.text = widget.initialProfile!.name;
      _mobileCtrl.text = widget.initialProfile!.mobile;
      _addressCtrl.text = widget.initialProfile!.address ?? '';
      _gender = widget.initialProfile!.gender;
      _ageCtrl.text = widget.initialProfile!.age.toString();
    }
  }

  Future<void> _saveClient() async {
    if (!_formKey.currentState!.validate() || _gender == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Fill all required fields."), backgroundColor: Colors.red));
      return;
    }
    setState(() => _isSaving = true);

    try {
      String patientId = _isEditing ? widget.initialProfile!.patientId! : await _patientIdService.getNextPatientId();
      String profileId = _isEditing ? widget.initialProfile!.id : "";

      final data = {
        'name': _nameCtrl.text.trim(),
        'mobile': _mobileCtrl.text.trim(),
        'age': int.tryParse(_ageCtrl.text) ?? 0,
        'gender': _gender,
        'address': _addressCtrl.text.trim(),
        'patientId': patientId,
        'isSoftDeleted': false,
        'isArchived': false,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (_isEditing) {
        await _firestore.collection('clients').doc(profileId).update(data);
      } else {
        final doc = await _firestore.collection('clients').add({...data, 'createdAt': FieldValue.serverTimestamp()});
        profileId = doc.id;
      }

      final tempProfile = ClientModel(
          id: profileId, patientId: patientId, loginId: _mobileCtrl.text,
          name: _nameCtrl.text, age: int.parse(_ageCtrl.text), mobile: _mobileCtrl.text,
          gender: _gender!, address: _addressCtrl.text, dob: DateTime.now(), email: ''
      );

      widget.onProfileSaved(tempProfile);
      if(mounted) Navigator.pop(context);

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red));
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      body: Stack(
        children: [
          Positioned(top: -100, right: -100, child: Container(width: 300, height: 300, decoration: BoxDecoration(shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.blue.withOpacity(0.1), blurRadius: 80, spreadRadius: 20)]))),

          SafeArea(
            child: Column(
              children: [
                // 1. GLASS HEADER
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)]), child: const Icon(Icons.arrow_back, size: 20)),
                      ),
                      const SizedBox(width: 16),
                      Text(_isEditing ? "Edit Profile" : "New Client", style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),

                // 2. FORM
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (_isEditing)
                            Container(
                              margin: const EdgeInsets.only(bottom: 20),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(8)),
                              child: Text("ID: ${widget.initialProfile!.patientId}", style: TextStyle(color: Colors.blue.shade800, fontWeight: FontWeight.bold)),
                            ),

                          _buildField("Full Name", _nameCtrl, Icons.person),
                          const SizedBox(height: 16),
                          Row(children: [
                            Expanded(child: _buildField("Age", _ageCtrl, Icons.cake, isNumber: true)),
                            const SizedBox(width: 16),
                            Expanded(child: _buildDropdown()),
                          ]),
                          const SizedBox(height: 16),
                          _buildField("Mobile Number", _mobileCtrl, Icons.phone, isNumber: true),
                          const SizedBox(height: 16),
                          _buildField("Address", _addressCtrl, Icons.home, maxLines: 3),

                          const SizedBox(height: 40),
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton(
                              onPressed: _isSaving ? null : _saveClient,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Theme.of(context).colorScheme.primary,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                elevation: 4,
                              ),
                              child: _isSaving ? const CircularProgressIndicator(color: Colors.white) : const Text("SAVE PROFILE", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            ),
                          )
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildField(String label, TextEditingController ctrl, IconData icon, {bool isNumber = false, int maxLines = 1}) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)]),
      child: TextFormField(
        controller: ctrl,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: Theme.of(context).colorScheme.primary.withOpacity(.4)),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        validator: (v) => v!.isEmpty ? "Required" : null,
      ),
    );
  }

  Widget _buildDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)]),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _gender,
          hint: const Text("Gender"),
          isExpanded: true,
          items: _genders.map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
          onChanged: (v) => setState(() => _gender = v),
        ),
      ),
    );
  }
}