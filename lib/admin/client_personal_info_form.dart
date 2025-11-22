import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:nutricare_client_management/admin/patient_service.dart';
import 'package:nutricare_client_management/modules/client/model/client_model.dart';
import 'package:nutricare_client_management/admin/custom_gradient_app_bar.dart';


class ClientPersonalInformationForm extends StatefulWidget {
  final Function(ClientModel) onProfileSaved;
  final ClientModel? initialProfile;

  const ClientPersonalInformationForm({
    super.key,
    this.initialProfile,
    required this.onProfileSaved,
  });

  @override
  State<ClientPersonalInformationForm> createState() =>
      _ClientPersonalInformationFormState();
}

class _ClientPersonalInformationFormState
    extends State<ClientPersonalInformationForm> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final PatientIdService _patientIdService = PatientIdService();

  final TextEditingController _clientNameController = TextEditingController();
  final TextEditingController _mobileNumberController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();

  String? _gender;
  bool _isSaving = false;
  bool _isEditing = false;

  final List<String> _genders = ['Male', 'Female', 'Other'];
  static const String _collectionName = 'clients'; // Temporary collection

  @override
  void initState() {
    super.initState();
    _initializeForm();
  }

  void _initializeForm() {
    if (widget.initialProfile != null) {
      _isEditing = true;
      final p = widget.initialProfile!;

      _clientNameController.text = p.name;
      _mobileNumberController.text = p.mobile;
      _addressController.text = p.address!;
      _gender = p.gender;
      _ageController.text = p.age.toString();
    }
  }

  Future<void> _saveClient() async {
    if (!_formKey.currentState!.validate() || _gender == null) {
      _showSnackbar('Please complete all required fields.', isError: true);
      return;
    }
    final String creatorUid = '';
    /* final String? creatorUid = FirebaseAuth.instance.currentUser?.uid;
    if (creatorUid == null) {
      _showSnackbar('Error: Admin not logged in.', isError: true);
      return;
    }*/

    setState(() {
      _isSaving = true;
    });

    try {
      String patientId;
      String profileId = '';

      if (_isEditing) {
        patientId = widget.initialProfile!.patientId!;
        profileId = widget.initialProfile!.id;
      } else {
        // --- NEW: GENERATE UNIQUE 5-DIGIT PATIENT ID ---
        patientId = await _patientIdService.getNextPatientId();
      }

      final clientData = {
        'name': _clientNameController.text.trim(),
        'mobile': _mobileNumberController.text.trim(),
        'age': int.tryParse(_ageController.text) ?? 0,
        'gender': _gender,
        'address': _addressController.text.trim(),
        'patientId': patientId,
        // 'isAuthenticatable': false,
        'isSoftDeleted': false,
        'createdBy': creatorUid,
        'lastModifiedBy': creatorUid,
        'isArchived': false,
      };

      if (_isEditing) {
        await _firestore.collection(_collectionName).doc(profileId).update({
          ...clientData,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } else {
        final docRef = await _firestore.collection(_collectionName).add({
          ...clientData,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
        profileId = docRef.id;
      }

      _showSnackbar('Client profile saved. Patient ID: $patientId');

      // 2. Construct and return the temporary profile object to the Stepper
      final tempProfile = ClientModel(
        id: profileId,
        patientId: patientId,
        email: '',
        loginId: '',
        // Stubbed
        name: clientData['name'] as String,
        age: clientData['age'] as int,
        mobile: clientData['mobile'] as String,
        gender: clientData['gender'] as String,
        address: clientData['address'] as String,
        dob: Timestamp.now().toDate(),
        // Stub
        createdAt: Timestamp.now(),
        updatedAt: Timestamp.now(),
        createdBy: creatorUid,
        lastModifiedBy: creatorUid,
        isArchived: false,
      );

      widget.onProfileSaved(tempProfile);
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      _showSnackbar('Save failed: ${e.toString()}', isError: true);
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  void _showSnackbar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  // 🎯 REVAMPED BUILD METHOD
  @override
  Widget build(BuildContext context) {
    // 🎯 Use theme color for consistency
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
        appBar: CustomGradientAppBar(
          title: const Text('Personal Information'), // Text color on primary background
        ),
        // 🎯 ADD PADDING TO THE BODY
        body:  SafeArea(
          child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0), // Consistent padding
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch, // Stretch fields full width
              children: <Widget>[
                // Display Patient ID if editing
                if (_isEditing)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 24.0), // More spacing
                    child: Text(
                      'Patient ID: ${widget.initialProfile!.patientId}',
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall // Use a slightly larger, bold style
                          ?.copyWith(color: colorScheme.primary),
                    ),
                  ),

                // --- Full Name ---
                TextFormField(
                  controller: _clientNameController,
                  decoration: const InputDecoration(
                    labelText: 'Client Full Name *',
                    prefixIcon: Icon(Icons.person),
                    border: OutlineInputBorder(), // Use OutlineInputBorder for definition
                  ),
                  validator: (v) => v!.isEmpty ? 'Name is required.' : null,
                ),
                const SizedBox(height: 16), // Consistent spacing

                // --- Age ---
                TextFormField(
                  controller: _ageController,
                  decoration: const InputDecoration(
                    labelText: 'Age *',
                    prefixIcon: Icon(Icons.cake),
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (v) => v!.isEmpty || int.tryParse(v) == null
                      ? 'Valid age is required.'
                      : null,
                ),
                const SizedBox(height: 16),

                // --- Mobile Number ---
                TextFormField(
                  controller: _mobileNumberController,
                  decoration: const InputDecoration(
                    labelText: 'Mobile Number *',
                    prefixIcon: Icon(Icons.phone_android),
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.phone,
                  validator: (v) => v!.isEmpty ? 'Mobile is required.' : null,
                ),
                const SizedBox(height: 16),

                // --- Gender Dropdown ---
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: 'Gender *',
                    prefixIcon: Icon(Icons.accessibility),
                    border: OutlineInputBorder(),
                  ),
                  value: _gender,
                  items: _genders.map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      _gender = newValue;
                    });
                  },
                  validator: (v) => v == null ? 'Gender is required.' : null,
                ),
                const SizedBox(height: 16),

                // --- Address ---
                TextFormField(
                  controller: _addressController,
                  decoration: const InputDecoration(
                    labelText: 'Address (Optional)',
                    prefixIcon: Icon(Icons.location_on),
                    border: OutlineInputBorder(),
                    alignLabelWithHint: true, // Centers the label text vertically for multiline
                  ),
                  maxLines: 3, // Increased maxLines for a better look
                ),

                const SizedBox(height: 40),

                // --- Save Button ---
                ElevatedButton.icon(
                  onPressed: _isSaving ? null : _saveClient,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: colorScheme.onPrimary,
                    minimumSize: const Size.fromHeight(50), // Full width, decent height
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  icon: _isSaving
                      ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                      : Icon(_isEditing ? Icons.edit : Icons.save),
                  label: Text(
                    _isEditing ? 'UPDATE PROFILE' : 'SAVE & PROCEED',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}