import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nutricare_client_management/services/client_service.dart';

import '../models/client_model.dart';

// =================================================================
// LOCAL/MOCK DEFINITIONS FOR RUNNABILITY (Replace with actual imports)
// =================================================================

// 1. ClientFormSection Enum (Must be shared between dashboard and form)
enum ClientFormSection { personal, password, agreement }

/*class ClientModel {
  final String id; final String name; final String mobile; final String email;
  final DateTime dob; final String gender; final String loginId;
  final String? address; final String? altMobile;
  final bool hasPasswordSet; final String? agreementUrl; final String? photoUrl;
  final Map<String, PackageAssignmentModel> packageAssignments;

  ClientModel({
    required this.id, required this.name, required this.mobile, required this.email, required this.gender, required this.dob, required this.loginId,
    this.address, this.altMobile, this.hasPasswordSet = false, this.agreementUrl, this.photoUrl,
    this.packageAssignments = const {},
  });
}*/



// =================================================================
// CLIENT FORM SCREEN IMPLEMENTATION
// =================================================================

class ClientFormScreen extends StatefulWidget {
  final ClientModel? clientToEdit;
  final ClientFormSection? focusSection;

  const ClientFormScreen({
    super.key,
    this.clientToEdit,
    this.focusSection
  });

  @override
  State<ClientFormScreen> createState() => _ClientFormScreenState();
}

class _ClientFormScreenState extends State<ClientFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final ClientService _clientService = ClientService();
  final List<String> _genders = ['Male', 'Female', 'Other'];

  bool isEditing = false;

  // Scroll controller and GlobalKeys for sections
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _personalKey = GlobalKey();
  final GlobalKey _passwordKey = GlobalKey();
  final GlobalKey _agreementKey = GlobalKey();

  late TextEditingController _nameController;
  late TextEditingController _mobileController;
  late TextEditingController _emailController;
  late TextEditingController _dobController;
  late TextEditingController _addressController;
  late TextEditingController _altMobileController;
  late TextEditingController _passwordController;
  // 🎯 NEW: Confirm Password Controller
  late TextEditingController _confirmPasswordController;

  String _gender = 'Male';
  DateTime? _selectedDob;
  PlatformFile? _selectedPhotoFile;
  PlatformFile? _selectedAgreementFile;
  String? _existingAgreementUrl;

  String _loginIdType = 'mobile';
  String _generatedSystemId = '';


  @override
  void initState() {
    super.initState();
    isEditing = widget.clientToEdit != null;
    final client = widget.clientToEdit;

    // --- Controller Initialization ---
    _nameController = TextEditingController(text: client?.name ?? '');
    _mobileController = TextEditingController(text: client?.mobile ?? '');
    _emailController = TextEditingController(text: client?.email ?? '');
    _addressController = TextEditingController(text: client?.address ?? '');
    _altMobileController = TextEditingController(text: client?.altMobile ?? '');
    _passwordController = TextEditingController();
    // 🎯 Initialize new controller
    _confirmPasswordController = TextEditingController();

    _gender = client?.gender ?? _genders.first;
    _existingAgreementUrl = client?.agreementUrl;

    // DOB and Login ID Logic
    if (client != null) {
      _selectedDob = client.dob;
      _dobController = TextEditingController(text: DateFormat('yyyy-MM-dd').format(client.dob));
      if (client.loginId != client.mobile) {
        _loginIdType = 'system';
        _generatedSystemId = client.loginId;
      } else {
        _loginIdType = 'mobile';
      }
    } else {
      _dobController = TextEditingController();
      _generatedSystemId = _clientService.generateSystemId();
    }
    _mobileController.addListener(_updateLoginIdPreview);

    // Schedule a scroll after the first frame is rendered
    if (widget.focusSection != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToSection(widget.focusSection!);
      });
    }
  }


  @override
  void dispose() {
    _mobileController.removeListener(_updateLoginIdPreview);
    _scrollController.dispose();
    _nameController.dispose();
    _mobileController.dispose();
    _emailController.dispose();
    _dobController.dispose();
    _addressController.dispose();
    _altMobileController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose(); // 🎯 Dispose new controller
    super.dispose();
  }

  void _scrollToSection(ClientFormSection section) {
    final keyMap = {
      ClientFormSection.personal: _personalKey,
      ClientFormSection.password: _passwordKey,
      ClientFormSection.agreement: _agreementKey,
    };

    final context = keyMap[section]?.currentContext;
    if (context != null) {
      Scrollable.ensureVisible(
        context,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
        alignment: 0.0,
      );
    }
  }

  void _updateLoginIdPreview() {
    if (_loginIdType == 'mobile') {
      setState(() {});
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDob ?? DateTime.now().subtract(const Duration(days: 365 * 18)),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDob) {
      setState(() {
        _selectedDob = picked;
        _dobController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  Future<void> _pickPhoto() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
    );

    if (result != null) {
      setState(() {
        _selectedPhotoFile = result.files.first;
      });
    }
  }

  Future<void> _pickAgreement() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx'],
      allowMultiple: false,
    );

    if (result != null) {
      setState(() {
        _selectedAgreementFile = result.files.first;
      });
    }
  }

  void _showSnackbar(String message, {Color color = Colors.green}) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: color),
      );
    }
  }

  // 🎯 Password Change Logic (Existing Client)
  Future<void> _changePassword() async {
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (password.isEmpty || confirmPassword.isEmpty) {
      return _showSnackbar('Password fields cannot be empty.', color: Colors.red);
    }
    if (password != confirmPassword) {
      return _showSnackbar('Password and Confirm Password must match.', color: Colors.red);
    }
    if (password.length < 6) {
      return _showSnackbar('Password must be at least 6 characters long.', color: Colors.red);
    }
    if (widget.clientToEdit == null) {
      return _showSnackbar('Error: Client ID missing for password change.', color: Colors.red);
    }

    try {
      await _clientService.changePassword(widget.clientToEdit!.id, password);
      _showSnackbar('✅ Password updated successfully!');
      _passwordController.clear();
      _confirmPasswordController.clear();
      // In a real app, you would also trigger a data refresh on the dashboard
    } catch (e) {
      _showSnackbar('❌ Failed to update password: ${e.toString()}', color: Colors.red);
    }
  }

  // 🎯 Save Form Logic (New or Existing Client)
  Future<void> _saveForm() async {
    if (!_formKey.currentState!.validate() || _selectedDob == null) {
      _showSnackbar('Please fill all required fields and select a valid DOB.', color: Colors.orange);
      return;
    }

    // New client requires password match validation
    if (!isEditing) {
      final password = _passwordController.text;
      final confirmPassword = _confirmPasswordController.text;

      if (password.isEmpty || confirmPassword.isEmpty) {
        return _showSnackbar('Initial password fields are required.', color: Colors.red);
      }
      if (password != confirmPassword) {
        return _showSnackbar('Password and Confirm Password must match.', color: Colors.red);
      }
      if (password.length < 6) {
        return _showSnackbar('Initial password must be at least 6 characters long.', color: Colors.red);
      }
    }

    final clientData = ClientModel(
      id: isEditing ? widget.clientToEdit!.id : UniqueKey().toString(),
      name: _nameController.text.trim(),
      mobile: _mobileController.text.trim(),
      email: _emailController.text.trim(),
      gender: _gender,
      dob: _selectedDob!,
      address: _addressController.text.trim(),
      altMobile: _altMobileController.text.trim().isEmpty ? null : _altMobileController.text.trim(),
      loginId: _loginIdType == 'mobile' ? _mobileController.text.trim() : _generatedSystemId,
      hasPasswordSet: widget.clientToEdit?.hasPasswordSet ?? false,
      photoUrl: widget.clientToEdit?.photoUrl,
      agreementUrl: _existingAgreementUrl,
    );

    try {
      if (isEditing) {
        await _clientService.updateClient(clientData, _selectedPhotoFile, _selectedAgreementFile);
        _showSnackbar('✅ Client updated successfully!');
      } else {
        await _clientService.addClient(clientData, _passwordController.text, _selectedPhotoFile, _selectedAgreementFile);
        _showSnackbar('✅ New client added successfully!');
      }
      if (mounted) Navigator.of(context).pop();

    } catch (e) {
      _showSnackbar('❌ Save failed: ${e.toString()}', color: Colors.red);
    }
  }

  // UI Helper methods
  Widget _buildSectionHeader(String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        const Divider(),
        Text(
          title,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).primaryColor,
          ),
        ),
        const Divider(),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, {TextInputType type = TextInputType.text, String? Function(String?)? validator, Widget? suffix, bool obscureText = false, int maxLines = 1, bool isPassword = false, TextEditingController? matchController}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: TextFormField(
        controller: controller,
        keyboardType: type,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          suffixIcon: suffix,
        ),
        validator: (value) {
          if (isPassword && value!.isNotEmpty && value.length < 6) {
            return 'Password must be at least 6 characters.';
          }
          if (matchController != null && value != matchController.text) {
            return 'Passwords do not match.';
          }
          return validator?.call(value);
        },
        maxLines: maxLines,
        obscureText: obscureText,
      ),
    );
  }

  Widget _buildPhotoPreview(ClientModel? client) {
    final imageWidget = _selectedPhotoFile != null
        ? Image.file(
      File(_selectedPhotoFile!.path!),
      fit: BoxFit.cover,
    )
        : (client?.photoUrl != null
        ? Image.network(
      client!.photoUrl!,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return const Center(child: CircularProgressIndicator());
      },
    )
        : const Center(child: Icon(Icons.person, size: 50, color: Colors.grey)));

    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.blueGrey, width: 2),
      ),
      clipBehavior: Clip.antiAlias,
      child: imageWidget,
    );
  }


  @override
  Widget build(BuildContext context) {
    final bool canChangeIdType = !isEditing;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Client: ${widget.clientToEdit!.name}' : 'Add New Client'),
      ),
      // Attach ScrollController
      body: SingleChildScrollView(
        controller: _scrollController,
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              // --- PHOTO UPLOAD ---
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _buildPhotoPreview(widget.clientToEdit),
                  const SizedBox(width: 16),
                  ElevatedButton.icon(
                    onPressed: _pickPhoto,
                    icon: const Icon(Icons.photo_camera),
                    label: Text(_selectedPhotoFile != null ? 'Change Photo' : 'Select Client Photo'),
                  ),
                ],
              ),
              const SizedBox(height: 16),


              // --- 🎯 1. PERSONAL INFORMATION SECTION ---
              // Attach Key for targeted scrolling
              Container(key: _personalKey, child: _buildSectionHeader('1. Personal Information')),

              _buildTextField(_nameController, 'Client Name', validator: (value) => value!.isEmpty ? 'Name is required.' : null),
              _buildTextField(_mobileController, 'Mobile Number (Primary)', type: TextInputType.phone, validator: (value) => value!.isEmpty || value.length < 10 ? 'Valid mobile number (min 10 digits) is required.' : null),
              _buildTextField(_altMobileController, 'Alternative Mobile Number (Optional)', type: TextInputType.phone, validator: (value) => value!.isNotEmpty && value.length < 10 ? 'Alternative number must be 10 digits.' : null),
              _buildTextField(_emailController, 'Email Address', type: TextInputType.emailAddress, validator: (value) => value!.isEmpty || !value.contains('@') ? 'Valid email is required.' : null),

              // DOB Field
              GestureDetector(
                onTap: () => _selectDate(context),
                child: AbsorbPointer(
                  child: _buildTextField(
                    _dobController,
                    'Date of Birth (DOB)',
                    suffix: const Icon(Icons.calendar_today),
                    validator: (value) => value!.isEmpty ? 'DOB is required.' : null,
                  ),
                ),
              ),

              // Gender Dropdown
              Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: DropdownButtonFormField<String>(
                  value: _gender,
                  decoration: const InputDecoration(labelText: 'Gender', border: OutlineInputBorder()),
                  items: _genders.map((String value) => DropdownMenuItem<String>(value: value, child: Text(value))).toList(),
                  onChanged: (String? newValue) => setState(() => _gender = newValue!),
                ),
              ),

              // Address Field
              _buildTextField(
                  _addressController,
                  'Residential Address',
                  type: TextInputType.multiline,
                  maxLines: 3,
                  validator: (value) => value!.isEmpty ? 'Address is required.' : null
              ),


              // --- 2. LOGIN ID CONFIGURATION & INITIAL PASSWORD ---

              _buildSectionHeader(isEditing ? '2. Login ID Configuration' : '2. Login ID & Initial Password'),

              // Login ID Type Selection (New Client Only)
              if (canChangeIdType)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: RadioListTile<String>(
                          title: const Text('Mobile No.'),
                          value: 'mobile',
                          groupValue: _loginIdType,
                          onChanged: (val) => setState(() => _loginIdType = val!),
                        ),
                      ),
                      Expanded(
                        child: RadioListTile<String>(
                          title: const Text('System ID'),
                          value: 'system',
                          groupValue: _loginIdType,
                          onChanged: (val) => setState(() => _loginIdType = val!),
                        ),
                      ),
                    ],
                  ),
                ),

              // Login ID Preview
              Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: Text(
                  _loginIdType == 'mobile'
                      ? 'Login ID will be: ${_mobileController.text.trim().isNotEmpty ? _mobileController.text.trim() : 'Mobile Number'}'
                      : 'Login ID will be: $_generatedSystemId',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey),
                ),
              ),
              const Divider(),

              // Initial Password (New Client)
              if (!isEditing) ...[
                _buildTextField(
                  _passwordController,
                  'Set Initial Password',
                  isPassword: true,
                  obscureText: true,
                  validator: (value) => value!.isEmpty ? 'Initial password is required.' : null,
                ),
                // 🎯 NEW: Confirm Password for New Client
                _buildTextField(
                  _confirmPasswordController,
                  'Confirm Initial Password',
                  isPassword: true,
                  obscureText: true,
                  matchController: _passwordController,
                  validator: (value) => value!.isEmpty ? 'Confirmation is required.' : null,
                ),
              ],

              // --- 🎯 3. PASSWORD MANAGEMENT SECTION (Existing Client Only) ---
              if (isEditing) ...[
                // Attach Key
                Container(key: _passwordKey, child: _buildSectionHeader('3. Password Management')),

                _buildTextField(
                  _passwordController,
                  'New Password (min 6 chars)',
                  isPassword: true,
                  obscureText: true,
                  validator: (value) => value!.isNotEmpty && value.length < 6 ? 'Minimum 6 characters required.' : null,
                ),
                // 🎯 NEW: Confirm Password for Existing Client
                _buildTextField(
                  _confirmPasswordController,
                  'Confirm New Password',
                  isPassword: true,
                  obscureText: true,
                  matchController: _passwordController,
                  suffix: IconButton(
                    icon: const Icon(Icons.send),
                    onPressed: _changePassword,
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: Text(
                    widget.clientToEdit!.hasPasswordSet
                        ? 'Current status: Password already set.'
                        : 'Current status: Password not yet set.',
                    style: TextStyle(color: widget.clientToEdit!.hasPasswordSet ? Colors.green : Colors.red),
                  ),
                ),
              ],

              // --- 🎯 4. AGREEMENT UPLOAD SECTION ---
              // Attach Key
              Container(key: _agreementKey, child: _buildSectionHeader('4. Agreement Management')),

              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Text(
                      _selectedAgreementFile != null
                          ? 'Selected: ${_selectedAgreementFile!.name}'
                          : (_existingAgreementUrl != null
                          ? 'Existing: Agreement already uploaded.'
                          : 'No agreement file selected.'),
                      style: TextStyle(color: _selectedAgreementFile != null || _existingAgreementUrl != null ? Colors.black87 : Colors.red),
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: _pickAgreement,
                    icon: const Icon(Icons.upload_file),
                    label: Text(_existingAgreementUrl != null ? 'Replace File' : 'Upload Agreement'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
              if (_existingAgreementUrl != null && _selectedAgreementFile == null)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text('Note: Uploading a new file will replace the existing one.', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                ),

              const SizedBox(height: 32),


              // --- SAVE BUTTON ---
              Center(
                child: ElevatedButton(
                  onPressed: _saveForm,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                    backgroundColor: Colors.blueAccent,
                  ),
                  child: Text(
                    isEditing ? 'Save Changes' : 'Add Client',
                    style: const TextStyle(fontSize: 18, color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}