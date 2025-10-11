// lib/screens/client_form_screen_old.dart
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import '../models/client_model.dart';
import '../services/client_service.dart';

class ClientFormScreen_old extends StatefulWidget {
  final ClientModel? clientToEdit;
  const ClientFormScreen_old({super.key, this.clientToEdit});

  @override
  State<ClientFormScreen_old> createState() => _ClientFormScreen_oldState();
}

class _ClientFormScreen_oldState extends State<ClientFormScreen_old> {
  final _formKey = GlobalKey<FormState>();
  final ClientService _clientService = ClientService();
  final List<String> _genders = ['Male', 'Female', 'Other'];

  bool isEditing = false;

  late TextEditingController _nameController;
  late TextEditingController _mobileController;
  late TextEditingController _emailController;
  late TextEditingController _dobController;
  String _gender = 'Male';
  DateTime? _selectedDob;
  PlatformFile? _selectedPhotoFile;

  String _loginIdType = 'mobile';
  String _generatedSystemId = '';

  @override
  void initState() {
    super.initState();
    isEditing = widget.clientToEdit != null;
    final client = widget.clientToEdit;

    _nameController = TextEditingController(text: client?.name ?? '');
    _mobileController = TextEditingController(text: client?.mobile ?? '');
    _emailController = TextEditingController(text: client?.email ?? '');
    _gender = client?.gender ?? _genders.first;

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
  }

  void _updateLoginIdPreview() {
    if (_loginIdType == 'mobile' && mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _mobileController.removeListener(_updateLoginIdPreview);
    _nameController.dispose();
    _mobileController.dispose();
    _emailController.dispose();
    _dobController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDob ?? DateTime.now(),
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
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png'],
      withData: kIsWeb,
    );

    if (result != null && result.files.single.bytes != null) {
      setState(() {
        _selectedPhotoFile = result.files.single;
      });
    }
  }

  Widget _buildPhotoPreview(ClientModel? client) {
    if (_selectedPhotoFile != null) {
      if (kIsWeb) {
        return Image.memory(_selectedPhotoFile!.bytes!, width: 60, height: 60, fit: BoxFit.cover);
      } else if (_selectedPhotoFile!.path != null) {
        return Image.file(File(_selectedPhotoFile!.path!), width: 60, height: 60, fit: BoxFit.cover);
      }
    } else if (client?.photoUrl != null) {
      return Image.network(client!.photoUrl!, width: 60, height: 60, fit: BoxFit.cover);
    }
    return const Icon(Icons.account_circle, size: 60, color: Colors.blueGrey);
  }

  void _showSnackbar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  Future<void> _saveForm() async {
    if (_formKey.currentState!.validate() && _selectedDob != null) {
      _formKey.currentState!.save();

      final String finalLoginId = _loginIdType == 'mobile'
          ? _mobileController.text.trim()
          : _generatedSystemId;

      if (_loginIdType == 'mobile' && _mobileController.text.trim().length < 10) {
        _showSnackbar('Mobile number must be at least 10 digits.', isError: true);
        return;
      }

      final newClient = ClientModel(
        id: widget.clientToEdit?.id ?? '',
        name: _nameController.text.trim(),
        mobile: _mobileController.text.trim(),
        email: _emailController.text.trim(),
        gender: _gender,
        dob: _selectedDob!,
        photoUrl: widget.clientToEdit?.photoUrl,
        loginId: finalLoginId,
        status: widget.clientToEdit?.status ?? 'Inactive',
        hasPasswordSet: widget.clientToEdit?.hasPasswordSet ?? false,
      );

      try {
        if (isEditing) {
          //await _clientService.updateClient(newClient, _selectedPhotoFile);
          _showSnackbar('Client updated successfully! 📝');
        } else {
        //  await _clientService.addClient(newClient, _selectedPhotoFile);
          _showSnackbar('Client added successfully! 🎉');
        }
        if (mounted) Navigator.pop(context);
      } catch (e) {
        _showSnackbar('Error saving client: ${e.toString()}', isError: true);
        print('--- SAVE ERROR ---: $e');
      }
    } else if (_selectedDob == null) {
      _showSnackbar('Date of Birth is required.', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool canChangeIdType = !isEditing;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Client: ${widget.clientToEdit!.name}' : 'Add New Client'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              // --- CORE CLIENT DETAILS ---
              TextFormField(controller: _nameController, decoration: const InputDecoration(labelText: 'Client Name'), validator: (value) => value!.isEmpty ? 'Name is required.' : null,),
              TextFormField(controller: _mobileController, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Mobile Number'), validator: (value) => value!.isEmpty || value.length < 10 ? 'Valid mobile number (min 10 digits) is required.' : null,),
              TextFormField(controller: _emailController, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'Email'), validator: (value) => value!.isEmpty || !value.contains('@') ? 'Valid email is required.' : null,),
              GestureDetector(onTap: () => _selectDate(context), child: AbsorbPointer(child: TextFormField(controller: _dobController, decoration: const InputDecoration(labelText: 'Date of Birth (DOB)', suffixIcon: Icon(Icons.calendar_today)), validator: (value) => value!.isEmpty ? 'DOB is required.' : null,)),),
              DropdownButtonFormField<String>(value: _gender, decoration: const InputDecoration(labelText: 'Gender'), items: _genders.map((String value) => DropdownMenuItem<String>(value: value, child: Text(value))).toList(), onChanged: (String? newValue) => setState(() => _gender = newValue!),),
              const SizedBox(height: 16),

              // --- LOGIN ID GENERATION OPTIONS ---
              if (canChangeIdType) ...[
                const Divider(),
                const Text('Choose Login ID Type:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Row(
                  children: [
                    Expanded(
                      child: RadioListTile<String>(
                        title: const Text('Mobile Number'),
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
                Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Text(
                    _loginIdType == 'mobile'
                        ? 'Login ID will be: ${_mobileController.text.trim().isEmpty ? '[Enter Mobile Number]' : _mobileController.text.trim()}'
                        : 'Login ID will be: $_generatedSystemId',
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey),
                  ),
                ),
                const Divider(),
              ],

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
            ],
          ),
        ),
      ),
    );
  }
}