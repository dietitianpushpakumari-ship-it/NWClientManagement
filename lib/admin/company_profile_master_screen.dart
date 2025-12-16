// lib/admin/company_profile_master_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nutricare_client_management/admin/database_provider.dart';
import 'package:nutricare_client_management/admin/company_profile_model.dart';
import 'package:nutricare_client_management/admin/company_profile_service.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'dart:ui'; // Used for BackdropFilter

// FutureProvider to fetch the single company document
final companyProfileProvider = FutureProvider.autoDispose<CompanyProfileModel>((ref) async {
  return ref.watch(companyProfileServiceProvider).fetchCompanyProfile();
});

class CompanyProfileMasterScreen extends ConsumerStatefulWidget {
  const CompanyProfileMasterScreen({super.key});

  @override
  ConsumerState<CompanyProfileMasterScreen> createState() => _CompanyProfileMasterScreenState();
}

class _CompanyProfileMasterScreenState extends ConsumerState<CompanyProfileMasterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _stateCtrl = TextEditingController();
  final _pincodeCtrl = TextEditingController();
  final _contactPhoneCtrl = TextEditingController();
  final _contactEmailCtrl = TextEditingController();
  final _patientIdPrefixCtrl = TextEditingController();
  final _gstinCtrl = TextEditingController();
  final _bankNameCtrl = TextEditingController();
  final _bankAccNoCtrl = TextEditingController();
  final _bankIfscCtrl = TextEditingController();

  File? _logoFile;
  String? _currentLogoUrl;
  bool _isLoading = false;

  bool _isControllersPopulated = false;

  final String _tenantId = 'default_tenant_id';

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _addressCtrl.dispose();
    _cityCtrl.dispose();
    _stateCtrl.dispose();
    _pincodeCtrl.dispose();
    _contactPhoneCtrl.dispose();
    _contactEmailCtrl.dispose();
    _patientIdPrefixCtrl.dispose();
    _gstinCtrl.dispose();
    _bankNameCtrl.dispose();
    _bankAccNoCtrl.dispose();
    _bankIfscCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final XFile? pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (pickedFile != null) setState(() => _logoFile = File(pickedFile.path));
  }

  Future<String?> _uploadLogo() async {
    if (_logoFile == null) return _currentLogoUrl;
    try {
      final ref = FirebaseStorage.instance.ref().child('company_logos/$_tenantId.jpg');
      await ref.putFile(_logoFile!);
      return await ref.getDownloadURL();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error uploading logo: $e")));
      return null;
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final logoUrl = await _uploadLogo();
      if (logoUrl == null && _logoFile != null) {
        throw Exception("Failed to get logo URL after upload.");
      }

      final data = {
        'name': _nameCtrl.text.trim(),
        'address': _addressCtrl.text.trim(),
        'city': _cityCtrl.text.trim(),
        'state': _stateCtrl.text.trim(),
        'pincode': _pincodeCtrl.text.trim(),
        'contactPhone': _contactPhoneCtrl.text.trim(),
        'contactEmail': _contactEmailCtrl.text.trim(),
        'patientIdPrefix': _patientIdPrefixCtrl.text.trim(),
        'gstin': _gstinCtrl.text.trim(),
        'bankName': _bankNameCtrl.text.trim(),
        'bankAccNo': _bankAccNoCtrl.text.trim(),
        'bankIfsc': _bankIfscCtrl.text.trim(),
        'logoUrl': logoUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      final service = ref.read(companyProfileServiceProvider);
      await service.saveCompanyProfile(data);

      ref.invalidate(companyProfileProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Company Profile saved successfully!")));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error saving profile: $e")));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // 🎯 NEW: Custom Header implementation
  Widget _buildCustomHeader(BuildContext context) {
    const String title = "Company/Clinic Profile";

    return ClipRRect(
      // Use BackdropFilter for a soft blur effect over content if it scrolls behind
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: Container(
          // Padding handles system status bar
          padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 10, 20, 16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.95), // Slightly transparent white
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              )
            ],
            border: Border(bottom: BorderSide(color: Colors.grey.withOpacity(0.1))),
          ),
          child: Row(
              children: [
                // Back Button
                GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.arrow_back_ios, color: Color(0xFF1A1A1A), size: 20)
                ),
                const SizedBox(width: 16),
                // Title
                Expanded(
                    child: Text(
                        title,
                        style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1A1A1A)
                        )
                    )
                ),
                // Save Button (Icon only)
                IconButton(
                  onPressed: _isLoading ? null : _saveProfile,
                  icon: _isLoading
                      ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.deepPurple))
                      : const Icon(Icons.check_circle, color: Colors.deepPurple, size: 28),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ]
          ),
        ),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    final tenantAsync = ref.watch(companyProfileProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      // ❌ REMOVED APP BAR
      body: SafeArea(
        top: false, // Handle top padding in custom header
        child: Column(
          children: [
            _buildCustomHeader(context), // 🎯 Custom Premium Header

            Expanded(
              child: tenantAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, stack) {
                  // Show form even on error (e.g., first run, no document)
                  return _buildForm(context);
                },
                data: (tenant) {
                  // FIX: Populate controllers only once when data is successfully loaded
                  if (!_isControllersPopulated) {
                    _nameCtrl.text = tenant.name ?? '';
                    _addressCtrl.text = tenant.address ?? '';
                    _cityCtrl.text = tenant.city ?? '';
                    _stateCtrl.text = tenant.state ?? '';
                    _pincodeCtrl.text = tenant.pincode ?? '';
                    _contactPhoneCtrl.text = tenant.contactPhone ?? '';
                    _contactEmailCtrl.text = tenant.contactEmail ?? '';
                    _patientIdPrefixCtrl.text = tenant.patientIdPrefix ?? '';
                    _gstinCtrl.text = tenant.gstin ?? '';
                    _bankNameCtrl.text = tenant.bankName ?? '';
                    _bankAccNoCtrl.text = tenant.bankAccNo ?? '';
                    _bankIfscCtrl.text = tenant.bankIfsc ?? '';
                    _currentLogoUrl = tenant.logoUrl;

                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) setState(() { _isControllersPopulated = true; });
                    });
                  }

                  return _buildForm(context);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildForm(BuildContext context) {
    // ❌ Removed the large save button from the end of the form as it's now in the header
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // --- 1. Company Identity & Logo ---
          _buildCard(
            title: "Identity & Branding",
            icon: Icons.business,
            color: Colors.indigo,
            children: [
              _buildLogoUploader(context),
              const SizedBox(height: 15),
              _buildField("Clinic/Hospital Name", _nameCtrl, Icons.apartment, required: true),
              const SizedBox(height: 10),
              _buildField("Patient ID Prefix (e.g., NC)", _patientIdPrefixCtrl, Icons.vpn_key, required: true, hint: "Used for auto-generating Patient IDs"),
              const SizedBox(height: 10),
              _buildField("GSTIN (Optional)", _gstinCtrl, Icons.receipt, required: false),
            ],
          ),

          // --- 2. Contact Information ---
          _buildCard(
            title: "Contact & Location",
            icon: Icons.location_on,
            color: Colors.orange,
            children: [
              _buildField("Primary Contact Phone", _contactPhoneCtrl, Icons.phone, isNumber: true, required: true),
              const SizedBox(height: 10),
              _buildField("Primary Contact Email", _contactEmailCtrl, Icons.email, required: true),
              const SizedBox(height: 10),
              _buildField("Address Line", _addressCtrl, Icons.location_city, maxLines: 2, required: true),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(child: _buildField("City", _cityCtrl, Icons.location_pin, required: true)),
                  const SizedBox(width: 10),
                  Expanded(child: _buildField("State", _stateCtrl, Icons.map, required: true)),
                ],
              ),
              const SizedBox(height: 10),
              _buildField("Pincode", _pincodeCtrl, Icons.numbers, isNumber: true, required: true),
            ],
          ),

          // --- 3. Payment Details ---
          _buildCard(
            title: "Bank & Payment Details",
            icon: Icons.account_balance,
            color: Colors.green,
            children: [
              const Text("Required for payment processing and invoices.", style: TextStyle(color: Colors.grey, fontSize: 12)),
              const SizedBox(height: 10),
              _buildField("Bank Name", _bankNameCtrl, Icons.account_balance_wallet, required: false),
              const SizedBox(height: 10),
              _buildField("Account Number", _bankAccNoCtrl, Icons.credit_card, isNumber: true, required: false),
              const SizedBox(height: 10),
              _buildField("IFSC Code", _bankIfscCtrl, Icons.code, required: false),
            ],
          ),

          const SizedBox(height: 40), // Added spacing for bottom scroll
        ],
      ),
    );
  }

  // --- Helper Widgets ---

  Widget _buildLogoUploader(BuildContext context) {
    final logoWidget = _logoFile != null
        ? Image.file(_logoFile!, fit: BoxFit.cover)
        : (_currentLogoUrl != null
        ? Image.network(_currentLogoUrl!, fit: BoxFit.cover, errorBuilder: (c, e, s) => Icon(Icons.image, size: 50, color: Colors.grey.shade400))
        : Icon(Icons.business_center, size: 50, color: Colors.grey.shade400));

    return Center(
      child: Column(
        children: [
          GestureDetector(
            onTap: _pickImage,
            child: Container(
              width: 120, height: 120,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.indigo.shade100),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: logoWidget,
              ),
            ),
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: _pickImage,
            icon: const Icon(Icons.upload_file, size: 18),
            label: const Text("Upload Clinic Logo", style: TextStyle(fontSize: 14)),
          ),
        ],
      ),
    );
  }

  Widget _buildCard({required String title, required IconData icon, required Color color, required List<Widget> children}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 20),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color),
                const SizedBox(width: 8),
                Text(title, style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: color)),
              ],
            ),
            const Divider(height: 20),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildField(String label, TextEditingController ctrl, IconData icon, {bool isNumber = false, int maxLines = 1, bool required = true, String? hint}) {
    return TextFormField(
      controller: ctrl,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, size: 20),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
      validator: (v) => required && (v == null || v.isEmpty) ? "$label is required." : null,
    );
  }
}