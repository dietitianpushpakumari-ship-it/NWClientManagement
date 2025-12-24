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
import 'package:nutricare_client_management/admin/patient_service.dart';

// =============================================================================
// 1. PERSONAL & CONTACT INFO SHEET
// =============================================================================
class ClientPersonalInfoSheet extends ConsumerStatefulWidget {
  final ClientModel? client;
  final Function(ClientModel)? onSave;

  const ClientPersonalInfoSheet({super.key, this.client, this.onSave});

  @override
  ConsumerState<ClientPersonalInfoSheet> createState() => _ClientPersonalInfoSheetState();
}

class _ClientPersonalInfoSheetState extends ConsumerState<ClientPersonalInfoSheet> {
  final _formKey = GlobalKey<FormState>();
  FirebaseFirestore get _firestore => ref.watch(firestoreProvider);
  final ImagePicker _picker = ImagePicker();

  bool get _isReadOnly => widget.onSave == null;

  late TextEditingController _nameCtrl;
  late TextEditingController _mobileCtrl;
  late TextEditingController _altMobileCtrl;
  late TextEditingController _whatsappCtrl;
  late TextEditingController _emailCtrl;
  late TextEditingController _addressCtrl;
  late TextEditingController _ageCtrl;

  late TextEditingController _sourceCtrl;
  late TextEditingController _occupationCtrl;
  late TextEditingController _eContactNameCtrl;
  late TextEditingController _eContactPhoneCtrl;

  String? _gender;
  DateTime? _dob;
  File? _imageFile;
  String? _currentPhotoUrl;
  bool _isSaving = false;

  final List<String> _genders = ['Male', 'Female', 'Other'];
  // 🎯 Quick Email Domains
  final List<String> _emailDomains = ['@gmail.com', '@yahoo.com', '@outlook.com', '@icloud.com'];

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

    if (widget.client != null) {
      _ageCtrl = TextEditingController(text: widget.client!.age?.toString() ?? '');
      bool isDobMeaningful = widget.client!.dob.year != DateTime.now().year;
      if (widget.client!.age != null && widget.client!.age! > 0 && !isDobMeaningful) {
        _dob = null;
      } else {
        _dob = isDobMeaningful ? widget.client!.dob : null;
      }
    } else {
      _dob = null;
      _ageCtrl = TextEditingController(text: '');
    }

    _gender = _initialClientData.gender;
    _currentPhotoUrl = _initialClientData.photoUrl;

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
    if (_isReadOnly) return;
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
    if (_isReadOnly) return;
    if (!_formKey.currentState!.validate() || _gender == null) {
      if (_gender == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please select a Gender."), backgroundColor: Colors.red));
      }
      return;
    }

    setState(() => _isSaving = true);

    try {
      final bool isNewClient = widget.client == null || widget.client!.id.isEmpty;
      // 🎯 FIX: Ensure ID is never empty
      final String clientId = isNewClient ? _firestore.collection('clients').doc().id : widget.client!.id;
      final String patientId = isNewClient
          ? await ref.read(patientIdServiceProvider).getNextPatientId()
          : (widget.client!.patientId ?? await ref.read(patientIdServiceProvider).getNextPatientId());

      String? photoUrl = await _uploadImage(clientId);
      final int ageValue = int.tryParse(_ageCtrl.text) ?? 0;
      DateTime? finalDob = _dob;
      int finalAge = ageValue;
      if (finalAge > 0 && finalDob == null) finalDob = null;

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

      // 🎯 FIX: Construct object explicitly to guarantee ID is set
      final updatedClient = ClientModel(
        id: clientId,
        name: updates['name'] as String,
        mobile: updates['mobile'] as String,
        email: updates['email'] as String,
        gender: updates['gender'] as String,
        dob: finalDob ?? _initialClientData.dob,
        patientId: patientId,
        loginId: _mobileCtrl.text.trim(),
        altMobile: updates['altMobile'] as String,
        whatsappNumber: updates['whatsappNumber'] as String,
        address: updates['address'] as String,
        age: finalAge,
        photoUrl: photoUrl,
        source: updates['source'] as String?,
        occupation: updates['occupation'] as String?,
        emergencyContactName: updates['emergencyContactName'] as String?,
        emergencyContactPhone: updates['emergencyContactPhone'] as String?,
        // Preserve other fields
        clientType: _initialClientData.clientType,
        status: _initialClientData.status,
      );

      if (widget.onSave != null) widget.onSave!(updatedClient);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Widget _buildAgeField(BuildContext context) {
    final bool isEnabled = !_isReadOnly && _dob == null;
    return _buildTextField(
        context,
        "Age",
        _ageCtrl,
        Icons.numbers,
        isNumber: true,
        isEnabled: isEnabled,
        customValidator: (v) {
          if (!isEnabled) return null;
          final isAgeEmpty = v == null || v.isEmpty;
          final ageValue = int.tryParse(v ?? '');
          if (isAgeEmpty) return "Required if DOB is empty";
          if (ageValue == null || ageValue <= 0 || ageValue > 120) return "Invalid Age (1-120)";
          return null;
        },
        onChanged: (v) {
          if (v.isNotEmpty && isEnabled) {
            setState(() => _dob = null);
          }
        }
    );
  }

  // 🎯 Quick Add Email Domain Widget
  Widget _buildEmailQuickAdd() {
    if (_isReadOnly) return const SizedBox.shrink();
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.only(top: 8, bottom: 4),
      child: Row(
        children: _emailDomains.map((domain) => Padding(
          padding: const EdgeInsets.only(right: 8.0),
          child: ActionChip(
            label: Text(domain, style: TextStyle(fontSize: 11, color: Theme.of(context).primaryColor)),
            backgroundColor: Theme.of(context).primaryColor.withOpacity(0.05),
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
            onPressed: () {
              String current = _emailCtrl.text;
              if (current.contains('@')) {
                // If @ exists, replace everything after it
                final parts = current.split('@');
                if (parts.isNotEmpty) {
                  _emailCtrl.text = parts[0] + domain;
                }
              } else {
                // If no @, just append
                _emailCtrl.text = current + domain;
              }
              // Move cursor to end
              _emailCtrl.selection = TextSelection.fromPosition(TextPosition(offset: _emailCtrl.text.length));
            },
          ),
        )).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final double safeAreaBottom = MediaQuery.of(context).padding.bottom;

    return Material(
      color: Colors.transparent,
      child: Container(
        height: MediaQuery.of(context).size.height * 0.9,
        decoration: const BoxDecoration(
          color: Color(0xFFF8F9FE),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 40, height: 4,
              decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
            ),
            _buildHeader(context, _isReadOnly ? "View Personal Info" : "Edit Personal Info"),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.fromLTRB(24, 0, 24, bottomInset + safeAreaBottom + 30),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      GestureDetector(
                        onTap: _pickImage,
                        child: CircleAvatar(
                          radius: 50,
                          backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(.1),
                          backgroundImage: _imageFile != null
                              ? FileImage(_imageFile!)
                              : (_currentPhotoUrl != null ? NetworkImage(_currentPhotoUrl!) as ImageProvider : null),
                          child: (_imageFile == null && _currentPhotoUrl == null)
                              ? Icon(Icons.person, size: 50, color: Theme.of(context).colorScheme.primary)
                              : null,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (!_isReadOnly) const Text("Tap to change photo", style: TextStyle(fontSize: 12, color: Colors.grey)),
                      const SizedBox(height: 24),

                      _buildSectionTitle("Identity"),
                      const SizedBox(height: 10),
                      _buildTextField(context, "Full Name", _nameCtrl, Icons.person, isEnabled: !_isReadOnly),
                      const SizedBox(height: 12),

                      Row(children: [
                        Expanded(child: _buildDatePicker(context)),
                        const SizedBox(width: 12),
                        Expanded(child: _buildAgeField(context)),
                      ]),
                      const SizedBox(height: 12),
                      _buildGenderDropdown(),
                      const SizedBox(height: 24),

                      _buildSectionTitle("Background & Referrals"),
                      const SizedBox(height: 10),
                      _buildTextField(context, "Source/Referral", _sourceCtrl, Icons.person_pin, required: false, isEnabled: !_isReadOnly),
                      const SizedBox(height: 12),
                      _buildTextField(context, "Occupation", _occupationCtrl, Icons.work, required: false, isEnabled: !_isReadOnly),
                      const SizedBox(height: 24),

                      _buildSectionTitle("Contact Details"),
                      const SizedBox(height: 10),
                      _buildTextField(context, "Primary Mobile", _mobileCtrl, Icons.phone, isNumber: true, isEnabled: !_isReadOnly),
                      const SizedBox(height: 12),
                      _buildTextField(context, "WhatsApp Number", _whatsappCtrl, Icons.chat, isNumber: true, required: false, isEnabled: !_isReadOnly),
                      const SizedBox(height: 12),
                      _buildTextField(context, "Alt Mobile", _altMobileCtrl, Icons.phone_android, isNumber: true, required: false, isEnabled: !_isReadOnly),
                      const SizedBox(height: 12),

                      // 🎯 MODIFIED: Added email validator & Quick Buttons
                      _buildTextField(
                          context,
                          "Email",
                          _emailCtrl,
                          Icons.email,
                          required: false,
                          isEnabled: !_isReadOnly,
                          customValidator: (val) {
                            if (val == null || val.isEmpty) return null; // Not required
                            // Simple regex for email validation
                            final bool emailValid = RegExp(r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+").hasMatch(val);
                            return emailValid ? null : "Invalid email format";
                          }
                      ),
                      _buildEmailQuickAdd(),

                      const SizedBox(height: 12),
                      _buildTextField(context, "Address", _addressCtrl, Icons.location_on, maxLines: 3, required: true, isEnabled: !_isReadOnly),
                      const SizedBox(height: 24),

                      _buildSectionTitle("Emergency Contact"),
                      const SizedBox(height: 10),
                      _buildTextField(context, "Contact Name", _eContactNameCtrl, Icons.person_search, required: false, isEnabled: !_isReadOnly),
                      const SizedBox(height: 12),
                      _buildTextField(context, "Contact Phone", _eContactPhoneCtrl, Icons.phone, isNumber: true, required: false, isEnabled: !_isReadOnly),

                      if (!_isReadOnly) ...[
                        const SizedBox(height: 40),
                        _buildSaveButton(context, _isSaving, _save),
                      ],
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

  Widget _buildDatePicker(BuildContext context) {
    final bool isEnabled = !_isReadOnly && _ageCtrl.text.isEmpty;

    return GestureDetector(
      onTap: isEnabled ? () async {
        final d = await showDatePicker(context: context, initialDate: _dob ?? DateTime(1990), firstDate: DateTime(1900), lastDate: DateTime.now());
        if (d != null) {
          setState(() {
            _dob = d;
            _ageCtrl.text = (DateTime.now().year - d.year).toString();
            _formKey.currentState?.validate();
          });
        }
      } : null,
      child: Container(
        height: 56, padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
            color: isEnabled ? Colors.white : Colors.grey.shade200,
            borderRadius: BorderRadius.circular(16)
        ),
        child: Row(children: [
          Icon(Icons.cake, color: Theme.of(context).colorScheme.primary.withOpacity(.4)),
          const SizedBox(width: 10),
          Text(
            _dob == null ? "DOB" : DateFormat('dd MMM yyyy').format(_dob!),
            style: TextStyle(fontWeight: FontWeight.w500, color: isEnabled ? Colors.black : Colors.grey.shade600),
          )
        ]),
      ),
    );
  }

  Widget _buildGenderDropdown() {
    return Container(
      height: 56, padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
          color: _isReadOnly ? Colors.grey.shade200 : Colors.white,
          borderRadius: BorderRadius.circular(16)
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _gender, hint: const Text("Gender"), isExpanded: true,
          onChanged: _isReadOnly ? null : (v) => setState(() => _gender = v),
          items: _genders.map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
        ),
      ),
    );
  }
}

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
          _buildSaveButton(context, _isSaving, _save),
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
      widget.onSave(widget.client.copyWith(status: newStatus));
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
          _buildSaveButton(context, _isSaving, _save),
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