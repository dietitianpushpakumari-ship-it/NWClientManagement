import 'dart:io'; // Required for File (though we'll only use it for kIsWeb check now)
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
// 🎯 CORRECT IMPORTS for Model and Service
import 'package:nutricare_client_management/modules/client/model/client_model.dart';
import 'package:nutricare_client_management/modules/client/services/client_service.dart'; // Use the actual ClientService

// ----------------------------------------------------------------------------------
// 🎯 ENUM DEFINITION (Kept from old structure)
// ----------------------------------------------------------------------------------

enum ClientFormSection { personal, password, agreement }

// ----------------------------------------------------------------------------------
// CLIENT FORM SCREEN
// ----------------------------------------------------------------------------------

class ClientFormScreen extends StatefulWidget {
  final ClientModel? clientToEdit;
  final ClientFormSection? initialFocusSection;

  const ClientFormScreen({
    super.key,
    this.clientToEdit, // Made nullable for Add Mode
    this.initialFocusSection,
  });

  @override
  State<ClientFormScreen> createState() => _ClientFormScreenState();
}

class _ClientFormScreenState extends State<ClientFormScreen> {
  // --- Controllers & Keys ---
  final _formKey = GlobalKey<FormState>();
  final ScrollController _scrollController = ScrollController();

  final Map<ClientFormSection, GlobalKey> _sectionKeys = {
    ClientFormSection.personal: GlobalKey(),
    ClientFormSection.password: GlobalKey(),
    ClientFormSection.agreement: GlobalKey(),
  };

  // Text Controllers
  final TextEditingController _mobileController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _testMobileController = TextEditingController();
  final TextEditingController _testPasswordController = TextEditingController();

  // 🎯 ADDED: WhatsApp Number Controller
  final TextEditingController _whatsappNumberController = TextEditingController();


  // --- State Variables ---
  String? _selectedGender;
  DateTime? _selectedDOB;

  // 🎯 CHANGED: Use PlatformFile to match ClientService signature
  PlatformFile? _agreementFile;

  bool _isSaving = false;
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isTestPasswordVisible = false;
  String _testResult = '';


  final ClientService _clientService = ClientService();
  // 🎯 REMOVED MOCK: Retain test method logic, but use real service/Auth logic if possible

  bool get isEditMode => widget.clientToEdit != null;

  @override
  void initState() {
    super.initState();
    if (isEditMode) {
      final client = widget.clientToEdit!;
      _nameController.text = client.name;
      _mobileController.text = client.mobile;
      _selectedDOB = client.dob;
      _selectedGender = client.gender;

      // 🎯 INITIALIZED: WhatsApp Number field
      _whatsappNumberController.text = client.whatsappNumber ?? client.mobile;

      _testMobileController.text = client.mobile;

      if (widget.initialFocusSection != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollToSection(widget.initialFocusSection!);
        });
      }
    }
  }

  @override
  void dispose() {
    _mobileController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _testMobileController.dispose();
    _testPasswordController.dispose();
    _nameController.dispose();
    _scrollController.dispose();
    _whatsappNumberController.dispose();
    super.dispose();
  }

  // =================================================================
  // CORE METHODS
  // =================================================================

  void _scrollToSection(ClientFormSection section) {
    final key = _sectionKeys[section];
    if (key?.currentContext != null) {
      Scrollable.ensureVisible(
        key!.currentContext!,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
        alignment: 0.1,
      );
    }
  }

  void _scrollToFirstInvalidField() {
    if (_selectedDOB == null) {
      _scrollToSection(ClientFormSection.personal);
      return;
    }

    // 🎯 CHECK: Use the new _agreementFile variable
    if (!isEditMode && _agreementFile == null) {
      _scrollToSection(ClientFormSection.agreement);
      return;
    }

    if (_formKey.currentState?.validate() == false) {
      _scrollToSection(ClientFormSection.personal);
      return;
    }
  }

  // 🎯 UPDATED: Unified method to handle both Add and Edit
  void _handleClientSave() async {
    final bool isFormValid = _formKey.currentState?.validate() == true;
    final bool isDobValid = _selectedDOB != null;
    final bool isPhotoValid = isEditMode || _agreementFile != null;

    // Check if new client is missing password
    if (!isEditMode && _passwordController.text.isEmpty) {
      _formKey.currentState?.validate();
      _scrollToSection(ClientFormSection.password);
    }

    if (!isFormValid || !isDobValid || !isPhotoValid) {
      _scrollToFirstInvalidField();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please correct the highlighted errors.')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final String mobile = _mobileController.text.trim();
      final String password = _passwordController.text;
      final String clientName = _nameController.text.trim();
      final String clientId = isEditMode
          ? widget.clientToEdit!.id
          : _clientService.generateFixedRandomSystemId(); // Using a fixed random ID generator

      // --- 1. PREPARE CLIENT MODEL ---
      final clientToSave = ClientModel(
        id: clientId,
        mobile: mobile,
        name: clientName,
        dob: _selectedDOB!,
        gender: _selectedGender ?? '',
        // Use existing client data for fields not in the form when editing
        createdAt: isEditMode ? widget.clientToEdit!.createdAt : Timestamp.now(),
        email: widget.clientToEdit?.email ?? '',
        loginId: widget.clientToEdit?.loginId ?? mobile,
        patientId: widget.clientToEdit?.patientId ?? '',
        // 🎯 SAVE WHATSAPP NUMBER
        whatsappNumber: _whatsappNumberController.text.trim().isNotEmpty
            ? _whatsappNumberController.text.trim()
            : mobile,
        // Default other required fields from Model
        hasPasswordSet: isEditMode ? widget.clientToEdit!.hasPasswordSet : false,
        updatedAt: Timestamp.now(),
        createdBy: isEditMode ? widget.clientToEdit!.createdBy : (FirebaseAuth.instance.currentUser?.uid ?? 'Admin'),
        lastModifiedBy: FirebaseAuth.instance.currentUser?.uid ?? 'Admin',
      );

      // --- 2. SAVE DATA TO FIRESTORE ---
      if (isEditMode) {
        // Update client document and optionally files
        await _clientService.updateClient(
          clientToSave,
          null, // photo (assuming separate photo field is not implemented yet)
          _agreementFile, // agreement
        );
        // Handle password change separately (via the dedicated service method)
        if (password.isNotEmpty) {
          await _clientService.changePassword(clientId, password);
        }
      } else {
        // 🎯 ADD MODE: Create client document and set password via Cloud Function
        await _clientService.addClient(
          clientToSave,
          password,
          null, // photo (assuming separate photo field is not implemented yet)
          _agreementFile, // agreement
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Client ${clientToSave.name} ${isEditMode ? 'updated' : 'added'} successfully!')),
        );
        Navigator.of(context).pop();
      }

    } on Exception catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save client: ${e.toString().replaceFirst('Exception: ', '')}')),
        );
      }
    } finally {
      setState(() => _isSaving = false);
    }
  }

  // 🎯 NOTE: Keeping testCredentials logic as a mock since the real ClientAuthService
  // is not fully exposed here, but replacing mock service reference with a basic check.
  void _testCredentials() async {
    // This is typically done via a real Firebase Auth sign-in to test the credentials.
    // Given the complexity of admin-side testing, this will remain a UI placeholder
    // or call the ClientService.testLoginCredentials if available/working.

    if (_testMobileController.text.isEmpty || _testPasswordController.text.isEmpty) {
      setState(() {
        _testResult = 'Please enter both mobile and password to test.';
      });
      return;
    }

    setState(() {
      _testResult = 'Testing...';
    });

    // Mocking the check for demonstration, replace with a real call if the method is available:
    try {
      // NOTE: Replace this with a real service call like _clientService.testLoginCredentials
      // once you have the live client model available.
      await Future.delayed(const Duration(milliseconds: 500));
      final success = _testPasswordController.text == '123456';
      setState(() {
        _testResult = success
            ? '✅ Mock Test successful! Credentials work for login.'
            : '❌ Mock Test failed. Double-check password and mobile number.';
      });
    } catch (e) {
      setState(() {
        _testResult = '❌ Test failed due to an error: ${e.toString()}';
      });
    }
  }

  // =================================================================
  // UI SECTION BUILDERS
  // =================================================================

  Widget _buildPersonalDetailsSection() {
    Future<void> _selectDate(BuildContext context) async {
      final DateTime? picked = await showDatePicker(
        context: context,
        initialDate: _selectedDOB ?? DateTime.now().subtract(const Duration(days: 365 * 20)),
        firstDate: DateTime(1900),
        lastDate: DateTime.now(),
      );
      if (picked != null && picked != _selectedDOB) {
        setState(() {
          _selectedDOB = picked;
        });
      }
    }

    return Column(
      key: _sectionKeys[ClientFormSection.personal],
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader(
          title: 'Personal Details',
          icon: Icons.person_outline,
        ),

        TextFormField(
          controller: _nameController,
          decoration: const InputDecoration(labelText: 'Client Name'),
          validator: (value) => value == null || value.isEmpty ? 'Client name is required.' : null,
        ),
        const SizedBox(height: 10),

        // --- Gender Dropdown (Placeholder) ---
        // Assuming this exists from your old code
        DropdownButtonFormField<String>(
          decoration: const InputDecoration(labelText: 'Gender *'),
          value: _selectedGender,
          items: ['Male', 'Female', 'Other'].map((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value),
            );
          }).toList(),
          onChanged: (String? newValue) {
            setState(() {
              _selectedGender = newValue;
            });
          },
          validator: (v) => v == null ? 'Gender is required.' : null,
        ),
        const SizedBox(height: 10),


        ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(
            _selectedDOB == null
                ? 'Date of Birth (Required)'
                : 'DOB: ${DateFormat('dd MMM yyyy').format(_selectedDOB!)}',
            style: TextStyle(
              color: _selectedDOB == null ? Theme.of(context).colorScheme.error : Theme.of(context).textTheme.bodyLarge?.color,
              fontWeight: FontWeight.w500,
            ),
          ),
          trailing: const Icon(Icons.calendar_today),
          onTap: () => _selectDate(context),
        ),
        const SizedBox(height: 10),
      ],
    );
  }

  Widget _buildPasswordSection() {
    return Column(
      key: _sectionKeys[ClientFormSection.password],
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader(
          title: 'Client Authentication (Login Setup)',
          icon: Icons.lock_outline,
        ),

        // 1. Mobile Number (The Login ID)
        TextFormField(
          controller: _mobileController,
          readOnly: isEditMode,
          decoration: InputDecoration(
            labelText: 'Mobile Number (Login ID) *',
            hintText: 'e.g., 9876543210',
            prefixIcon: const Icon(Icons.phone),
            filled: isEditMode,
            fillColor: isEditMode ? Colors.grey.shade200 : null,
          ),
          keyboardType: TextInputType.phone,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          validator: (value) {
            if (value == null || value.isEmpty || value.length < 10) {
              return 'Please enter a valid 10-digit mobile number.';
            }
            return null;
          },
        ),
        const SizedBox(height: 15),

        // 🎯 ADDED: WhatsApp Number Field
        TextFormField(
          controller: _whatsappNumberController,
          decoration: const InputDecoration(
            labelText: 'WhatsApp Number (if different from Mobile)',
            hintText: 'Defaults to Mobile if empty',
            prefixIcon:  Icon(Icons.whatshot, color: Colors.green),
          ),
          keyboardType: TextInputType.phone,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        ),
        const SizedBox(height: 15),


        // Explanation for password fields in Edit Mode
        if (isEditMode)
          const Padding(
            padding: EdgeInsets.only(bottom: 10.0),
            child: Text(
              'Leave password fields blank to keep the current password. If a new password is set, it will be securely updated.',
              style: TextStyle(fontStyle: FontStyle.italic, color: Colors.blueGrey),
            ),
          ),

        // 2. Password Field
        TextFormField(
          controller: _passwordController,
          obscureText: !_isPasswordVisible,
          decoration: InputDecoration(
            labelText: isEditMode ? 'New Password (Optional)' : 'Set Password (Required)',
            prefixIcon: const Icon(Icons.vpn_key),
            suffixIcon: IconButton(
              icon: Icon(_isPasswordVisible ? Icons.visibility : Icons.visibility_off),
              onPressed: () {
                setState(() {
                  _isPasswordVisible = !_isPasswordVisible;
                });
              },
            ),
          ),
          validator: (value) {
            if (!isEditMode && (value == null || value.isEmpty)) {
              return 'Password is required for a new client.';
            }
            if (value != null && value.isNotEmpty && value.length < 6) {
              return 'Password must be at least 6 characters long.';
            }
            return null;
          },
        ),
        const SizedBox(height: 15),

        // 3. Confirm Password Field
        TextFormField(
          controller: _confirmPasswordController,
          obscureText: !_isConfirmPasswordVisible,
          decoration: InputDecoration(
            labelText: 'Confirm Password',
            prefixIcon: const Icon(Icons.vpn_key),
            suffixIcon: IconButton(
              icon: Icon(_isConfirmPasswordVisible ? Icons.visibility : Icons.visibility_off),
              onPressed: () {
                setState(() {
                  _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                });
              },
            ),
          ),
          validator: (value) {
            if (_passwordController.text.isNotEmpty && (value == null || value.isEmpty)) {
              return 'Please confirm the new password.';
            }
            if (_passwordController.text.isNotEmpty && value != _passwordController.text) {
              return 'Passwords do not match.';
            }
            return null;
          },
        ),
        const Divider(height: 30),
        _buildCredentialsTestSection(),
      ],
    );
  }

  Widget _buildCredentialsTestSection() {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Test Credentials (Optional)',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.blueGrey),
          ),
          const SizedBox(height: 10),
          // Test Mobile
          TextFormField(
            controller: _testMobileController,
            decoration: const InputDecoration(
              labelText: 'Mobile to Test',
              hintText: 'Enter client\'s mobile',
            ),
            keyboardType: TextInputType.phone,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          ),
          const SizedBox(height: 10),
          // Test Password
          TextFormField(
            controller: _testPasswordController,
            obscureText: !_isTestPasswordVisible,
            decoration: InputDecoration(
              labelText: 'Password to Test',
              suffixIcon: IconButton(
                icon: Icon(_isTestPasswordVisible ? Icons.visibility : Icons.visibility_off),
                onPressed: () {
                  setState(() {
                    _isTestPasswordVisible = !_isTestPasswordVisible;
                  });
                },
              ),
            ),
          ),
          const SizedBox(height: 15),
          // Test Button
          ElevatedButton.icon(
            onPressed: _testCredentials,
            icon: const Icon(Icons.security),
            label: const Text('TEST LOGIN'),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 45),
            ),
          ),
          const SizedBox(height: 10),
          // Test Result
          Text(_testResult, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }


  Widget _buildAgreementPhotoSection() {
    return Column(
      key: _sectionKeys[ClientFormSection.agreement],
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader(
          title: 'Agreement Photo',
          icon: Icons.camera_alt_outlined,
        ),
        ElevatedButton.icon(
          onPressed: () async {
            // 🎯 FIXED: Retrieve PlatformFile directly from FilePicker
            FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.image);
            if (result != null) {
              setState(() {
                // Store the PlatformFile
                _agreementFile = result.files.single;
              });
            }
          },
          icon: const Icon(Icons.upload_file),
          label: Text(_agreementFile == null ? 'Upload Agreement Photo' : 'Photo Selected'),
        ),
        if (_agreementFile != null)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            // 🎯 FIXED: Use PlatformFile name property
            child: Text('File: ${_agreementFile!.name}', style: const TextStyle(fontStyle: FontStyle.italic)),
          ),
        const SizedBox(height: 10),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24.0),
      child: ElevatedButton.icon(
        onPressed: _isSaving ? null : _handleClientSave,
        icon: _isSaving ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.save),
        label: Text(_isSaving ? 'Saving Client...' : 'Save Client'),
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(double.infinity, 50),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
    );
  }


  // --- Build Method ---
  @override
  Widget build(BuildContext context) {
    final titleText = isEditMode
        ? 'Edit Client: ${_nameController.text.isNotEmpty ? _nameController.text : '...loading...'}'
        : 'Add New Client';

    final List<Widget> sections = [
      _buildPersonalDetailsSection(),
      _buildPasswordSection(),
      _buildAgreementPhotoSection(),
      _buildSubmitButton(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(titleText),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          controller: _scrollController,
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: sections,
          ),
        ),
      ),
    );
  }
}

// ----------------------------------------------------------------------
// COMMON SECTION HEADER
// ----------------------------------------------------------------------

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;

  const _SectionHeader({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10.0, bottom: 12.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.indigo.shade500, size: 24),
          const SizedBox(width: 10),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.indigo.shade700,
            ),
          ),
        ],
      ),
    );
  }
}