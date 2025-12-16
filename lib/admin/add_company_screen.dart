import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nutricare_client_management/admin/tenant_model.dart';
import 'package:nutricare_client_management/admin/tenant_service.dart';
import 'package:nutricare_client_management/admin/qr_scanner_screen.dart';
import 'package:url_launcher/url_launcher.dart';

class AddCompanyScreen extends StatefulWidget {
  final TenantModel? draftTenant;
  const AddCompanyScreen({super.key, this.draftTenant});

  @override
  State<AddCompanyScreen> createState() => _AddCompanyScreenState();
}

class _AddCompanyScreenState extends State<AddCompanyScreen> {
  final _formKey = GlobalKey<FormState>();
  final _service = TenantOnboardingService();

  bool _isTesting = false;
  bool _connectionVerified = false;
  bool _isSaving = false;

  // Controllers
  final _nameCtrl = TextEditingController();
  final _slugCtrl = TextEditingController();
  final _ownerNameCtrl = TextEditingController();
  final _ownerEmailCtrl = TextEditingController();
  final _ownerPhoneCtrl = TextEditingController();
  final _projectIdCtrl = TextEditingController();
  final _apiKeyCtrl = TextEditingController();
  final _messagingIdCtrl = TextEditingController();
  final _bucketCtrl = TextEditingController();
  final _webAppIdCtrl = TextEditingController();
  final _androidAppIdCtrl = TextEditingController();
  final _iosAppIdCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.draftTenant != null) {
      final t = widget.draftTenant!;
      _nameCtrl.text = t.name;
      _slugCtrl.text = t.id;
      _ownerNameCtrl.text = t.ownerName;
      _ownerEmailCtrl.text = t.ownerEmail;
      _ownerPhoneCtrl.text = t.ownerPhone;
      _projectIdCtrl.text = t.projectId;
      _apiKeyCtrl.text = t.apiKey;
      _messagingIdCtrl.text = t.messagingSenderId;
      _bucketCtrl.text = t.storageBucket;
      _webAppIdCtrl.text = t.appId;
      _androidAppIdCtrl.text = t.androidAppId;
      _iosAppIdCtrl.text = t.iosAppId;

      if (t.status == TenantStatus.active) _connectionVerified = true;
    }
  }

  // ... (Keep existing _generateStrongPassword, _parseAndFillConfig, _handleScanQR) ...
  String _generateStrongPassword() {
    const length = 12;
    const chars = 'AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz1234567890!@#\$%^&*';
    final rnd = Random();
    return String.fromCharCodes(Iterable.generate(
        length, (_) => chars.codeUnitAt(rnd.nextInt(chars.length))));
  }

  void _parseAndFillConfig(String text) {
    String? getValue(String key) {
      final regex = RegExp('''$key['"]?\\s*[:=]\\s*['"]([^'"]+)['"]''', caseSensitive: false, multiLine: true);
      final match = regex.firstMatch(text);
      return match?.group(1);
    }
    final apiKey = getValue('apiKey');
    final appId = getValue('appId');
    final projectId = getValue('projectId');
    final messagingSenderId = getValue('messagingSenderId');
    final storageBucket = getValue('storageBucket');
    final androidId = getValue('androidAppId');
    final iosId = getValue('iosAppId');

    if (apiKey != null || projectId != null) {
      setState(() {
        if (apiKey != null) _apiKeyCtrl.text = apiKey;
        if (projectId != null) _projectIdCtrl.text = projectId;
        if (messagingSenderId != null) _messagingIdCtrl.text = messagingSenderId;
        if (storageBucket != null) _bucketCtrl.text = storageBucket;
        if (appId != null) _webAppIdCtrl.text = appId;
        if (androidId != null) _androidAppIdCtrl.text = androidId;
        if (iosId != null) _iosAppIdCtrl.text = iosId;
        _connectionVerified = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Config Parsed!"), backgroundColor: Colors.green));
    }
  }

  Future<void> _handleScanQR() async {
    final result = await Navigator.push<String>(context, MaterialPageRoute(builder: (_) => const QRScannerScreen()));
    if (result != null && result.isNotEmpty) _parseAndFillConfig(result);
  }

  TenantModel _buildModel() {
    return TenantModel(
      id: _slugCtrl.text.trim().toLowerCase(),
      name: _nameCtrl.text.trim(),
      ownerName: _ownerNameCtrl.text.trim(),
      ownerEmail: _ownerEmailCtrl.text.trim(),
      ownerPhone: _ownerPhoneCtrl.text.trim(),
      apiKey: _apiKeyCtrl.text.trim(),
      appId: _webAppIdCtrl.text.trim(),
      androidAppId: _androidAppIdCtrl.text.trim(),
      iosAppId: _iosAppIdCtrl.text.trim(),
      messagingSenderId: _messagingIdCtrl.text.trim(),
      projectId: _projectIdCtrl.text.trim(),
      storageBucket: _bucketCtrl.text.trim(),
      invitedAt: DateTime.now(),
      status: widget.draftTenant?.status ?? TenantStatus.pending, // Keep pending if failed
    );
  }

  // 💾 SAVE DRAFT (Safe)
  Future<void> _saveDraft() async {
    // Minimal Validation
    if (_nameCtrl.text.isEmpty || _slugCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Name and ID are required for draft."), backgroundColor: Colors.orange));
      return;
    }

    setState(() => _isSaving = true);
    try {
      await _service.saveDraftTenant(_buildModel());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Draft Saved!"), backgroundColor: Colors.grey));
        Navigator.pop(context);
      }
    } catch (e) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Save Error: $e")));
    } finally {
      if(mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _performTest() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please fill required fields.")));
      return;
    }
    setState(() => _isTesting = true);

    final config = _buildModel();
    final success = await _service.testConnection(config); // This now auto-saves draft too!

    if (mounted) {
      setState(() {
        _isTesting = false;
        _connectionVerified = success;
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(success ? "Verified! ✅" : "Connection Failed. ❌"),
        backgroundColor: success ? Colors.green : Colors.red,
      ));
    }
  }

  // 🚀 ONBOARD (Risky)
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    // Only check verification if this is a NEW active attempt
    if (!_connectionVerified && (widget.draftTenant?.status != TenantStatus.active)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please Test Connection first.")));
      return;
    }

    setState(() => _isSaving = true);
    final model = _buildModel();

    try {
      // If just updating an existing active tenant
      if (widget.draftTenant?.status == TenantStatus.active) {
        await _service.updateTenantDetails(model);
        if(mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Updated!"), backgroundColor: Colors.green));
          Navigator.pop(context);
        }
      }
      // If Onboarding New
      else {
        final pass = _generateStrongPassword();
        await _service.onboardAndInvite(model, pass);

        if (mounted) {
          await showDialog(
            context: context,
            barrierDismissible: false,
            builder: (ctx) => AlertDialog(
              title: const Text("Success! 🎉"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Client Onboarded. What would you like to do?"),
                  const SizedBox(height: 20),
                  _buildCopyRow("Email", _ownerEmailCtrl.text),
                  const SizedBox(height: 5),
                  _buildCopyRow("Password", pass),
                ],
              ),
              actions: [
                // 1. Send Email Button (Primary Action)
                ElevatedButton.icon(
                  icon: const Icon(Icons.email),
                  label: const Text("Open Gmail & Send"),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
                  onPressed: () {
                    _sendInviteEmail(_ownerEmailCtrl.text, pass, _ownerNameCtrl.text);
                  },
                ),
                // 2. Close Button
                TextButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      Navigator.pop(context);
                    },
                    child: const Text("Close")
                )
              ],
            ),
          );
        }
      }
    } catch (e) {
      // 🎯 ERROR HANDLING: Data IS saved as draft.
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("Onboarding Failed: $e\nData saved as Draft."),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ));
      }
    } finally {
      if(mounted) setState(() => _isSaving = false);
    }
  }

  // ... (Keep Helper Widgets from previous code) ...
  Widget _buildField(TextEditingController ctrl, String label, {bool isEmail = false, bool enabled = true}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: ctrl,
        enabled: enabled,
        keyboardType: isEmail ? TextInputType.emailAddress : TextInputType.text,
        decoration: InputDecoration(labelText: label, border: const OutlineInputBorder(), isDense: true, filled: !enabled, fillColor: enabled ? null : Colors.grey.shade200),
        validator: (v) => (!enabled || label.contains("Optional") || label.contains("App ID")) ? null : (v!.isEmpty ? "Required" : null),
      ),
    );
  }

  Widget _buildCopyRow(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(4)),
      child: Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)), SelectableText(value, style: const TextStyle(fontWeight: FontWeight.bold))])),
        IconButton(icon: const Icon(Icons.copy, size: 16), onPressed: () => Clipboard.setData(ClipboardData(text: value)))
      ]),
    );
  }

  Widget _sectionHeader(String title) => Padding(padding: const EdgeInsets.only(bottom: 12), child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.indigo)));

  @override
  Widget build(BuildContext context) {
    bool isEditingActive = widget.draftTenant?.status == TenantStatus.active;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditingActive ? "Edit Clinic" : "Onboard Clinic"),
        actions: [
          if(!isEditingActive) TextButton(onPressed: _isSaving ? null : _saveDraft, child: const Text("Save Draft"))
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          onChanged: () { if (_connectionVerified) setState(() => _connectionVerified = false); },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionHeader("Company Profile"),
              _buildField(_nameCtrl, "Clinic Name"),
              _buildField(_slugCtrl, "Unique ID", enabled: !isEditingActive),
              const SizedBox(height: 20),
              _sectionHeader("Admin Owner"),
              _buildField(_ownerNameCtrl, "Owner Name"),
              _buildField(_ownerEmailCtrl, "Owner Email", isEmail: true, enabled: !isEditingActive),
              _buildField(_ownerPhoneCtrl, "Owner Phone"),
              const SizedBox(height: 20),

              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                _sectionHeader("Firebase Configuration"),
                Row(children: [
                  IconButton(onPressed: () async { final d = await Clipboard.getData(Clipboard.kTextPlain); if(d?.text!=null) _parseAndFillConfig(d!.text!); }, icon: const Icon(Icons.paste, color: Colors.blue)),
                  IconButton(onPressed: _handleScanQR, icon: const Icon(Icons.qr_code, color: Colors.purple)),
                ])
              ]),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
                child: Column(children: [
                  _buildField(_projectIdCtrl, "Project ID"),
                  _buildField(_apiKeyCtrl, "API Key"),
                  _buildField(_webAppIdCtrl, "Web App ID"),
                  _buildField(_androidAppIdCtrl, "Android App ID (Optional)"),
                  _buildField(_iosAppIdCtrl, "iOS App ID (Optional)"),
                  _buildField(_messagingIdCtrl, "Messaging Sender ID"),
                  _buildField(_bucketCtrl, "Storage Bucket"),
                ]),
              ),

              const SizedBox(height: 30),
              Row(children: [
                Expanded(child: OutlinedButton.icon(onPressed: _isSaving ? null : _performTest, icon: _isTesting ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.wifi), label: const Text("Test Config"))),
                const SizedBox(width: 16),
                Expanded(child: ElevatedButton.icon(onPressed: _isSaving ? null : _submit, icon: const Icon(Icons.rocket_launch), label: Text(_isSaving ? "Working..." : (isEditingActive ? "Update" : "Onboard")))),
              ]),
            ],
          ),
        ),
      ),
    );
  }


  Future<void> _sendInviteEmail(String email, String password, String name) async {
    final String subject = Uri.encodeComponent("Welcome to NutriCare Wellness - Login Credentials");
    final String body = Uri.encodeComponent(
        "Hello $name,\n\n"
            "Your clinic has been successfully onboarded to NutriCare Wellness.\n\n"
            "Here are your login details:\n"
            "--------------------------------\n"
            "Email: $email\n"
            "Temporary Password: $password\n"
            "--------------------------------\n\n"
            "Please log in and change your password immediately.\n\n"
            "Regards,\n"
            "NutriCare Admin Team"
    );

    final Uri emailUri = Uri.parse("mailto:$email?subject=$subject&body=$body");

    try {
      await launchUrl(emailUri);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Could not open email app. Please check if one is installed.")),
      );
    }
  }
}