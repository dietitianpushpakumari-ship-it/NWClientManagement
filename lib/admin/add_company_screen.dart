import 'dart:math'; // 🎯 Import for Random
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:nutricare_client_management/admin/tenant_model.dart';
import 'package:nutricare_client_management/admin/tenant_service.dart';

class AddCompanyScreen extends StatefulWidget {
  final TenantModel? draftTenant; // If null, we are creating NEW
  const AddCompanyScreen({super.key, this.draftTenant});

  @override
  State<AddCompanyScreen> createState() => _AddCompanyScreenState();
}

class _AddCompanyScreenState extends State<AddCompanyScreen> {
  final _formKey = GlobalKey<FormState>();
  final TenantOnboardingService _service = TenantOnboardingService();
  bool _isLoading = false;

  // Controllers
  final _nameCtrl = TextEditingController();
  final _ownerNameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();

  // 🎯 GENERATOR HELPER
  String _generateSystemPassword() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZabcdefghjkmnpqrstuvwxyz23456789@#'; // No confusing chars (I, l, 1, 0, O)
    final rnd = Random();

    // Generate 8 character string
    return String.fromCharCodes(Iterable.generate(
        10, (_) => chars.codeUnitAt(rnd.nextInt(chars.length))));
  }

  @override
  void initState() {
    super.initState();
    if (widget.draftTenant != null) {
      _nameCtrl.text = widget.draftTenant!.name;
      _ownerNameCtrl.text = widget.draftTenant!.ownerName;
      _emailCtrl.text = widget.draftTenant!.ownerEmail;
      _phoneCtrl.text = widget.draftTenant!.ownerPhone;
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final String tenantId = widget.draftTenant?.id ??
          "clinic_${DateTime.now().millisecondsSinceEpoch}";

      final newTenant = TenantModel(
        id: tenantId,
        name: _nameCtrl.text.trim(),
        ownerName: _ownerNameCtrl.text.trim(),
        ownerEmail: _emailCtrl.text.trim(),
        ownerPhone: _phoneCtrl.text.trim(),
        status: widget.draftTenant?.status ?? 'pending',
        createdAt: widget.draftTenant?.createdAt ?? DateTime.now(),
      );

      if (widget.draftTenant == null) {
        // 🚀 NEW ONBOARDING: Generate Password & Call Service
        final String sysPassword = _generateSystemPassword();

        await _service.onboardNewTenant(
            tenant: newTenant,
            password: sysPassword // Passing the system generated one
        );
      } else {
        // ✏️ EDITING: Just updates details
        await FirebaseFirestore.instance.collection('tenants').doc(tenantId).update(newTenant.toMap());
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Success! Account Created."), backgroundColor: Colors.green));
        Navigator.pop(context);
      }

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red));
      }
    } finally {
      if(mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.draftTenant != null;

    return Scaffold(
      appBar: AppBar(title: Text(isEditing ? "Edit Clinic" : "Onboard New Clinic")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _header("Company Profile"),
              _input(_nameCtrl, "Clinic Name", Icons.business),

              const SizedBox(height: 20),
              _header("Administrator"),
              _input(_ownerNameCtrl, "Owner Name", Icons.person),
              _input(_emailCtrl, "Owner Email", Icons.email, isEmail: true, isReadOnly: isEditing),
              _input(_phoneCtrl, "Owner Phone", Icons.phone),

              // 🎯 INFO CARD (Instead of Password Input)
              if (!isEditing) ...[
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.shade100)
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.lock_clock_outlined, color: Colors.blue.shade700),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          "A secure password will be generated automatically. You can view and email it from the Company Details screen after onboarding.",
                          style: TextStyle(fontSize: 12, color: Colors.blueGrey),
                        ),
                      ),
                    ],
                  ),
                )
              ],

              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _submit,
                  icon: _isLoading
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.check),
                  label: Text(_isLoading ? "CREATING..." : (isEditing ? "UPDATE DETAILS" : "GENERATE & ONBOARD")),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
    );
  }

  Widget _input(TextEditingController ctrl, String label, IconData icon, {bool isEmail = false, bool isReadOnly = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: ctrl,
        readOnly: isReadOnly,
        validator: (v) => v!.isEmpty ? "Required" : null,
        keyboardType: isEmail ? TextInputType.emailAddress : TextInputType.text,
        decoration: InputDecoration(
            labelText: label,
            prefixIcon: Icon(icon, color: Colors.grey),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: isReadOnly ? Colors.grey.shade200 : Colors.grey.shade50
        ),
      ),
    );
  }
}