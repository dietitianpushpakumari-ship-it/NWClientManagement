import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:nutricare_client_management/admin/database_provider.dart';
import 'package:nutricare_client_management/admin/labvital/global_service_provider.dart';
import 'package:nutricare_client_management/modules/client/model/client_model.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:nutricare_client_management/admin/patient_service.dart';

// =============================================================================
// 1. PERSONAL & CONTACT INFO SHEET
// =============================================================================
class ClientPersonalInfoSheet extends ConsumerStatefulWidget {
  final ClientModel? client;
  final Function(ClientModel) onSave;

  const ClientPersonalInfoSheet({super.key, this.client, required this.onSave});

  @override
  ConsumerState<ClientPersonalInfoSheet> createState() => _ClientPersonalInfoSheetState();
}

class _ClientPersonalInfoSheetState extends ConsumerState<ClientPersonalInfoSheet> {
  final _formKey = GlobalKey<FormState>();
  FirebaseFirestore  get _firestore => ref.watch(firestoreProvider);
  final ImagePicker _picker = ImagePicker();

  // Existing controllers
  late TextEditingController _nameCtrl;
  late TextEditingController _mobileCtrl;
  late TextEditingController _altMobileCtrl;
  late TextEditingController _whatsappCtrl;
  late TextEditingController _emailCtrl;
  late TextEditingController _addressCtrl;
  late TextEditingController _ageCtrl;

  // NEW FIELD CONTROLLERS
  late TextEditingController _sourceCtrl;
  late TextEditingController _occupationCtrl;
  late TextEditingController _eContactNameCtrl;
  late TextEditingController _eContactPhoneCtrl;


  String? _gender;
  DateTime? _dob; // Nullable DOB
  File? _imageFile;
  String? _currentPhotoUrl;
  bool _isSaving = false;

  final List<String> _genders = ['Male', 'Female', 'Other'];

  late ClientModel _initialClientData;

  @override
  void initState() {
    super.initState();
    _initialClientData = widget.client ?? ClientModel(id: '', name: '', mobile: '', email: '', gender: 'Male', dob: DateTime.now(), loginId: '', patientId: '');

    _nameCtrl = TextEditingController(text: _initialClientData.name);
    _mobileCtrl = TextEditingController(text: _initialClientData.mobile);
    _altMobileCtrl = TextEditingController(text: _initialClientData.altMobile ?? '');
    _whatsappCtrl = TextEditingController(text: _initialClientData.whatsappNumber ?? '');
    _emailCtrl = TextEditingController(text: _initialClientData.email);
    _addressCtrl = TextEditingController(text: _initialClientData.address ?? '');

    // Correctly initialize DOB and Age to allow Age entry initially for new clients.
    if (widget.client != null) {
      _ageCtrl = TextEditingController(text: widget.client!.age?.toString() ?? '');

      // Determine if stored DOB is meaningful (not the ClientModel default filler)
      bool isDobMeaningful = widget.client!.dob.year != DateTime.now().year;

      if (widget.client!.age != null && widget.client!.age! > 0 && !isDobMeaningful) {
        _dob = null; // Prioritize Age if DOB is default filler
      } else {
        _dob = isDobMeaningful ? widget.client!.dob : null;
      }

    } else {
      _dob = null; // New client: start with neither set to allow user choice.
      _ageCtrl = TextEditingController(text: '');
    }

    _gender = _initialClientData.gender;
    _currentPhotoUrl = _initialClientData.photoUrl;

    // NEW CONTROLLERS INITIALIZED
    _sourceCtrl = TextEditingController(text: _initialClientData.source ?? '');
    _occupationCtrl = TextEditingController(text: _initialClientData.occupation ?? '');
    _eContactNameCtrl = TextEditingController(text: _initialClientData.emergencyContactName ?? '');
    _eContactPhoneCtrl = TextEditingController(text: _initialClientData.emergencyContactPhone ?? '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _mobileCtrl.dispose();
    _altMobileCtrl.dispose();
    _whatsappCtrl.dispose();
    _emailCtrl.dispose();
    _addressCtrl.dispose();
    _ageCtrl.dispose();
    _sourceCtrl.dispose();
    _occupationCtrl.dispose();
    _eContactNameCtrl.dispose();
    _eContactPhoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 60);
    if (pickedFile != null) setState(() => _imageFile = File(pickedFile.path));
  }

  Future<String?> _uploadImage(String clientId) async {
    if (_imageFile == null) return _currentPhotoUrl;
    try {
      final ref = FirebaseStorage.instance.ref().child('client_profiles/$clientId.jpg');
      await ref.putFile(_imageFile!);
      return await ref.getDownloadURL();
    } catch (e) {
      return null;
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || _gender == null) {
      if (_gender == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please select a Gender."), backgroundColor: Colors.red));
      }
      return;
    }

    setState(() => _isSaving = true);

    try {
      final bool isNewClient = widget.client == null || widget.client!.id.isEmpty;
      final String clientId = isNewClient ? _firestore.collection('clients').doc().id : widget.client!.id;

      final String patientId = isNewClient
          ? await ref.read(patientIdServiceProvider).getNextPatientId()
          : widget.client!.patientId!;

      String? photoUrl = await _uploadImage(clientId);
      final int ageValue = int.tryParse(_ageCtrl.text) ?? 0;

      // Determine final DOB/Age state for saving:
      DateTime? finalDob = _dob;
      int finalAge = ageValue;

      // If Age is set manually, ensure finalDob is null for saving
      if (finalAge > 0 && finalDob == null) {
        finalDob = null;
      }

      final updates = {
        'name': _nameCtrl.text.trim(),
        'mobile': _mobileCtrl.text.trim(),
        'altMobile': _altMobileCtrl.text.trim(),
        'whatsappNumber': _whatsappCtrl.text.trim(),
        'email': _emailCtrl.text.trim(),
        'address': _addressCtrl.text.trim(),
        'gender': _gender,
        'dob': finalDob != null ? Timestamp.fromDate(finalDob) : null,
        'age': finalAge,
        'photoUrl': photoUrl,
        'patientId': patientId,
        // NEW FIELDS SAVING:
        'source': _sourceCtrl.text.trim(),
        'occupation': _occupationCtrl.text.trim(),
        'emergencyContactName': _eContactNameCtrl.text.trim(),
        'emergencyContactPhone': _eContactPhoneCtrl.text.trim(),
      };

      if (isNewClient) {
        await _firestore.collection('clients').doc(clientId).set({
          ...updates,
          'id': clientId,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
          'loginId': _mobileCtrl.text.trim(),
        });
      } else {
        await _firestore.collection('clients').doc(clientId).update({
          ...updates,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }


      // Create the updated client model for local state/callback
      final updatedClient = _initialClientData.copyWith(
        id: clientId,
        name: updates['name'] as String,
        mobile: updates['mobile'] as String,
        email: updates['email'] as String,
        gender: updates['gender'] as String,
        dob: finalDob,
        patientId: patientId,
        loginId: _mobileCtrl.text.trim(),

        altMobile: updates['altMobile'] as String,
        whatsappNumber: updates['whatsappNumber'] as String,
        address: updates['address'] as String,
        age: finalAge,
        photoUrl: photoUrl,
        // NEW FIELDS COPIED:
        source: updates['source'] as String?,
        occupation: updates['occupation'] as String?,
        emergencyContactName: updates['emergencyContactName'] as String?,
        emergencyContactPhone: updates['emergencyContactPhone'] as String?,
      );

      widget.onSave(updatedClient);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // Mutual Exclusivity Logic: Build Age Field
  Widget _buildAgeField(BuildContext context) {
    // Age field is disabled if DOB is set, enforcing mutual exclusivity.
    final bool isEnabled = _dob == null;

    return _buildTextField(
        context,
        "Age",
        _ageCtrl,
        Icons.numbers,
        isNumber: true,
        isEnabled: isEnabled,
        // Validation: Required IF DOB is null.
        customValidator: (v) {
          // If Age is disabled (DOB is set), validation is ignored.
          if (!isEnabled) return null;

          final isAgeEmpty = v == null || v.isEmpty;
          final ageValue = int.tryParse(v ?? '');

          if (isAgeEmpty) {
            return "Required if DOB is empty";
          }
          if (ageValue == null || ageValue <= 0 || ageValue > 120) {
            return "Invalid Age (1-120)";
          }
          return null;
        },
        onChanged: (v) {
          // If the user types an age, clear DOB
          if (v.isNotEmpty && isEnabled) {
            setState(() {
              _dob = null;
            });
          }
        }
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        height: MediaQuery.of(context).size.height * 0.9,
        decoration: const BoxDecoration(color: Color(0xFFF8F9FE), borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        child: Column(
          children: [
            _buildHeader(context, "Edit Personal Info"),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      // Photo
                      GestureDetector(
                        onTap: _pickImage,
                        child: CircleAvatar(
                          radius: 50,
                          backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(.1),
                          backgroundImage: _imageFile != null ? FileImage(_imageFile!) : (_currentPhotoUrl != null ? NetworkImage(_currentPhotoUrl!) as ImageProvider : null),
                          child: (_imageFile == null && _currentPhotoUrl == null) ?  Icon(Icons.person, size: 50, color: Theme.of(context).colorScheme.primary) : null,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text("Tap to change photo", style: TextStyle(fontSize: 12, color: Colors.grey)),
                      const SizedBox(height: 24),

                      _buildSectionTitle("Identity"),
                      _buildTextField(context,"Full Name", _nameCtrl, Icons.person),
                      const SizedBox(height: 12),

                      // EITHER/OR Validation Row (DOB or Age)
                      Row(children: [
                        Expanded(child: _buildDatePicker(context)), // Modified to be disabled
                        const SizedBox(width: 12),
                        Expanded(child: _buildAgeField(context)), // Modified with mutual exclusivity
                      ]),
                      const SizedBox(height: 12),
                      Row(children: [
                        Expanded(child: _buildGenderDropdown()),
                      ]),
                      const SizedBox(height: 24),

                      // NEW SECTION: Background Details
                      _buildSectionTitle("Background & Referrals"),
                      _buildTextField(context,"Source/Referral", _sourceCtrl, Icons.person_pin, required: false),
                      const SizedBox(height: 12),
                      _buildTextField(context,"Occupation", _occupationCtrl, Icons.work, required: false),
                      const SizedBox(height: 24),

                      _buildSectionTitle("Contact Details"),
                      // Primary mobile is only editable on new client creation (when widget.client is null)
                      _buildTextField(context,"Primary Mobile", _mobileCtrl, Icons.phone, isNumber: true, isEnabled: widget.client == null || widget.client!.mobile.isEmpty),
                      const SizedBox(height: 12),
                      _buildTextField(context,"WhatsApp Number", _whatsappCtrl, FontAwesomeIcons.whatsapp, isNumber: true, required: false),
                      const SizedBox(height: 12),
                      _buildTextField(context,"Alt Mobile", _altMobileCtrl, Icons.phone_android, isNumber: true, required: false),
                      const SizedBox(height: 12),
                      // 🎯 FIX: Email is NOT required
                      _buildTextField(context,"Email", _emailCtrl, Icons.email, required: false),
                      const SizedBox(height: 12),
                      // 🎯 FIX: Address IS required
                      _buildTextField(context,"Address", _addressCtrl, Icons.location_on, maxLines: 3, required: true),
                      const SizedBox(height: 24),

                      // NEW SECTION: Emergency Contact
                      _buildSectionTitle("Emergency Contact"),
                      _buildTextField(context,"Contact Name", _eContactNameCtrl, Icons.person_search, required: false),
                      const SizedBox(height: 12),
                      _buildTextField(context,"Contact Phone", _eContactPhoneCtrl, Icons.phone, isNumber: true, required: false),


                      const SizedBox(height: 40),
                      _buildSaveButton(context,_isSaving, _save),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Helper Methods (Modified for DOB/Age mutual exclusion) ---

  Widget _buildDatePicker(BuildContext context) {
    // Date Picker is disabled if Age field has content
    final bool isEnabled = _ageCtrl.text.isEmpty;

    return GestureDetector(
      onTap: isEnabled ? () async {
        final d = await showDatePicker(context: context, initialDate: _dob ?? DateTime(1990), firstDate: DateTime(1900), lastDate: DateTime.now());
        if (d != null) {
          setState(() {
            _dob = d;
            // Age is calculated and set when DOB is picked, clearing manual age input
            _ageCtrl.text = (DateTime.now().year - d.year).toString();
            _formKey.currentState?.validate();
          });
        }
      } : null, // Disable the tap gesture if age is entered
      child: Container(
        height: 56, padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
            color: isEnabled ? Colors.white : Colors.grey.shade200, // Visual indication of disabled state
            borderRadius: BorderRadius.circular(16)
        ),
        child: Row(children: [
          Icon(Icons.cake, color: Theme.of(context).colorScheme.primary.withOpacity(.4)),
          const SizedBox(width: 10),
          Text(
            _dob == null ? "DOB" : DateFormat('dd MMM yyyy').format(_dob!),
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: isEnabled ? Colors.black : Colors.grey.shade600,
            ),
          )
        ]),
      ),
    );
  }

  Widget _buildGenderDropdown() {
    return Container(
      height: 56, padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _gender, hint: const Text("Gender"), isExpanded: true,
          items: _genders.map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
          onChanged: (v) => setState(() => _gender = v),
        ),
      ),
    );
  }
}

// ... (ClientTypeSheet, ClientSecuritySheet, and shared helpers are omitted but exist in the context)
// =============================================================================
// 2. CLIENT TYPE SHEET
// =============================================================================
class ClientTypeSheet extends ConsumerStatefulWidget {
  final ClientModel client;
  final Function(ClientModel) onSave;

  const ClientTypeSheet({super.key, required this.client, required this.onSave});

  @override
  ConsumerState<ClientTypeSheet> createState() => _ClientTypeSheetState();
}

class _ClientTypeSheetState extends ConsumerState<ClientTypeSheet> {
  late String _selectedType;
  bool _isSaving = false;

  final Map<String, String> _types = {
    'new': 'New / Pending',
    'active': 'Active Member',
    'one_time': 'One-Time Consult',
    'expired': 'Expired / Past'
  };

  @override
  void initState() {
    super.initState();
    _selectedType = widget.client.clientType;
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    try {
      await ref.read(firestoreProvider).collection('clients').doc(widget.client.id).update({'clientType': _selectedType});
      widget.onSave(widget.client.copyWith(clientType: _selectedType));
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Change Client Status", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          ..._types.entries.map((e) => RadioListTile<String>(
            title: Text(e.value, style: const TextStyle(fontWeight: FontWeight.w600)),
            value: e.key,
            groupValue: _selectedType,
            activeColor: Theme.of(context).colorScheme.primary,
            contentPadding: EdgeInsets.zero,
            onChanged: (v) => setState(() => _selectedType = v!),
          )),
          const SizedBox(height: 20),
          _buildSaveButton(context,_isSaving, _save),
        ],
      ),
    );
  }
}

// =============================================================================
// 3. SECURITY SHEET
// =============================================================================
class ClientSecuritySheet extends ConsumerStatefulWidget {
  final ClientModel client;
  final Function(ClientModel) onSave;

  const ClientSecuritySheet({super.key, required this.client, required this.onSave});

  @override
  ConsumerState<ClientSecuritySheet> createState() => _ClientSecuritySheetState();
}

class _ClientSecuritySheetState extends ConsumerState<ClientSecuritySheet> {
  late bool _isLoginActive;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _isLoginActive = widget.client.status == 'Active';
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    try {
      final newStatus = _isLoginActive ? 'Active' : 'Inactive';
      await ref.read(firestoreProvider).collection('clients').doc(widget.client.id).update({'status': newStatus});
      widget.onSave(widget.client.copyWith(status: newStatus)); // Note: Model update is simplistic here
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // NOTE: Password reset logic should typically be server-side or via auth service
  // For this UI, we assume a button to trigger it.

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Security Settings", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(12)),
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text("App Login Access", style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(_isLoginActive ? "User can login" : "User blocked", style: TextStyle(fontSize: 12, color: _isLoginActive ? Colors.green : Colors.red)),
                  value: _isLoginActive,
                  activeColor: Colors.green,
                  contentPadding: EdgeInsets.zero,
                  onChanged: (v) => setState(() => _isLoginActive = v),
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),
          _buildSaveButton(context,_isSaving, _save),
        ],
      ),
    );
  }
}

// =============================================================================
// SHARED WIDGET HELPERS
// =============================================================================

Widget _buildHeader(BuildContext context, String title) {
  return Padding(
    padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
      ],
    ),
  );
}

Widget _buildSectionTitle(String title) {
  return Align(alignment: Alignment.centerLeft, child: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey)));
}

// 🎯 FIX: Modified _buildTextField to include 'required' parameter and 'onChanged'
Widget _buildTextField(BuildContext context,String label, TextEditingController ctrl, IconData icon, {bool isNumber = false, int maxLines = 1, bool isEnabled = true, bool required = true, String? Function(String?)? customValidator, Function(String)? onChanged}) {
  return Container(
    decoration: BoxDecoration(color: isEnabled ? Colors.white : Colors.grey.shade200, borderRadius: BorderRadius.circular(16)),
    child: TextFormField(
      controller: ctrl,
      enabled: isEnabled,
      keyboardType: isNumber ? TextInputType.phone : TextInputType.text,
      maxLines: maxLines,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label, prefixIcon: Icon(icon, color: Theme.of(context).colorScheme.primary.withOpacity(.4), size: 20),
        border: InputBorder.none, contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      ),
      // Use customValidator if provided, otherwise use default required validation based on 'required' flag
      validator: customValidator ?? ((v) => isEnabled && required && (v == null || v.isEmpty) ? "Required" : null),
    ),
  );
}

Widget _buildSaveButton(BuildContext context,bool isSaving, VoidCallback onPressed) {
  return SizedBox(
    width: double.infinity, height: 56,
    child: ElevatedButton(
      onPressed: isSaving ? null : onPressed,
      style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), elevation: 0),
      child: isSaving ? const CircularProgressIndicator(color: Colors.white) : const Text("SAVE CHANGES", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
    ),
  );
}