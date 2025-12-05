import 'dart:ui';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'admin/staff_management_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _staffService = StaffManagementService();

  // 🎯 RENAMED: Generic Controller
  final _idController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _isPasswordVisible = false;

  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _animController.forward();
  }

  @override
  void dispose() {
    _idController.dispose();
    _passwordController.dispose();
    _animController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      // 🎯 CALL NEW SMART LOGIN
      await _staffService.login(
        _idController.text.trim(),
        _passwordController.text,
      );
    } catch (e) {
      _showSnack(e.toString().replaceAll("Exception: ", ""), isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showActivationSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ActivationSheet(service: _staffService),
    );
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: isError ? Colors.red : Colors.green));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [primaryColor.withOpacity(0.1), Colors.white, Colors.blueGrey.shade50],
              ),
            ),
          ),

          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: FadeTransition(
                opacity: _fadeAnim,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: primaryColor.withOpacity(0.2), blurRadius: 20, offset: const Offset(0, 10))]),
                      child: Icon(Icons.local_hospital_rounded, size: 48, color: primaryColor),
                    ),
                    const SizedBox(height: 30),
                    Text("Staff Portal", style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w900, color: const Color(0xFF1A1A1A))),
                    const SizedBox(height: 8),
                    Text("Secure access for Dietitians & Admin", style: theme.textTheme.bodyLarge?.copyWith(color: Colors.grey.shade600)),
                    const SizedBox(height: 40),

                    ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        child: Container(
                          padding: const EdgeInsets.all(32),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.7),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: Colors.white),
                            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 30, offset: const Offset(0, 10))],
                          ),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              children: [
                                // 🎯 UPDATED INPUT FIELD
                                _buildTextField(
                                  controller: _idController,
                                  label: "Mobile Number or Email",
                                  icon: Icons.account_circle_outlined,
                                ),
                                const SizedBox(height: 20),
                                _buildTextField(
                                    controller: _passwordController,
                                    label: "Password",
                                    icon: Icons.lock_outline,
                                    isPassword: true,
                                    isVisible: _isPasswordVisible,
                                    onVisibilityToggle: () => setState(() => _isPasswordVisible = !_isPasswordVisible)
                                ),
                                const SizedBox(height: 16),

                                Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton(
                                    onPressed: _showActivationSheet,
                                    child: Text("Activate / Forgot Password?", style: TextStyle(fontWeight: FontWeight.w600, color: primaryColor, fontSize: 13)),
                                  ),
                                ),

                                const SizedBox(height: 30),

                                SizedBox(
                                  width: double.infinity,
                                  height: 56,
                                  child: ElevatedButton(
                                    onPressed: _isLoading ? null : _handleLogin,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: primaryColor,
                                      foregroundColor: Colors.white,
                                      elevation: 8,
                                      shadowColor: primaryColor.withOpacity(0.4),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                    ),
                                    child: _isLoading
                                        ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
                                        : const Text("LOGIN", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 30),
                    Text("v1.0.0 • NutriCare Enterprise", style: TextStyle(color: Colors.grey.shade400, fontSize: 12)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({required TextEditingController controller, required String label, required IconData icon, bool isPassword = false, bool isVisible = false, VoidCallback? onVisibilityToggle}) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword && !isVisible,
      style: const TextStyle(fontWeight: FontWeight.w600),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.grey.shade600),
        prefixIcon: Icon(icon, color: Colors.grey.shade500),
        suffixIcon: isPassword
            ? IconButton(icon: Icon(isVisible ? Icons.visibility : Icons.visibility_off, color: Colors.grey), onPressed: onVisibilityToggle)
            : null,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        filled: true,
        fillColor: Colors.grey.shade50,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      ),
      validator: (v) => v!.isEmpty ? "Required" : null,
    );
  }
}

// --- ACTIVATION SHEET (Same as before, reused here for completeness) ---
class _ActivationSheet extends StatefulWidget {
  final StaffManagementService service;

  const _ActivationSheet({required this.service});

  @override
  State<_ActivationSheet> createState() => _ActivationSheetState();
}

class _ActivationSheetState extends State<_ActivationSheet> {
  final _empCtrl = TextEditingController();
  final _mobileCtrl = TextEditingController();
  final _lastCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  DateTime? _dob;
  bool _isVerifying = false;
  bool _isVerified = false;
  String? _verifiedUid;

  Future<void> _verify() async {
    if (_empCtrl.text.isEmpty ||
        _mobileCtrl.text.isEmpty ||
        _lastCtrl.text.isEmpty ||
        _dob == null)
      return;
    setState(() => _isVerifying = true);
    try {
      final uid = await widget.service.verifyStaffIdentity(
        empId: _empCtrl.text.trim(),
        mobile: _mobileCtrl.text.trim(),
        lastName: _lastCtrl.text.trim(),
        dob: _dob!,
      );
      if (uid != null) {
        setState(() {
          _isVerified = true;
          _verifiedUid = uid;
          _isVerifying = false;
        });
      } else {
        _showError("Details do not match records.");
        setState(() => _isVerifying = false);
      }
    } catch (e) {
      _showError("Error: $e");
      setState(() => _isVerifying = false);
    }
  }

  Future<void> _setPassword() async {
    if (_passCtrl.text.length < 6 || _passCtrl.text != _confirmCtrl.text) {
      _showError("Check password.");
      return;
    }
    setState(() => _isVerifying = true);
    try {
      await widget.service.activateStaffAccount(
        uid: _verifiedUid!,
        newPassword: _passCtrl.text.trim(),
      );
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Account Activated! Login now."),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      _showError(e.toString().replaceAll("Exception: ", ""));
    } finally {
      if (mounted) setState(() => _isVerifying = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        24,
        24,
        24,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _isVerified ? "Set New Password" : "Activate Account",
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            if (!_isVerified) ...[
              TextField(
                controller: _empCtrl,
                decoration: const InputDecoration(
                  labelText: "Employee ID",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _mobileCtrl,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: "Mobile Number",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _lastCtrl,
                decoration: const InputDecoration(
                  labelText: "Last Name",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              InkWell(
                onTap: () async {
                  final d = await showDatePicker(
                    context: context,
                    initialDate: DateTime(1990),
                    firstDate: DateTime(1950),
                    lastDate: DateTime.now(),
                  );
                  if (d != null) setState(() => _dob = d);
                },
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: "Date of Birth",
                    border: OutlineInputBorder(),
                  ),
                  child: Text(
                    _dob != null
                        ? DateFormat('dd/MM/yyyy').format(_dob!)
                        : "Select Date",
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isVerifying ? null : _verify,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo,
                    foregroundColor: Colors.white,
                  ),
                  child: _isVerifying
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text("VERIFY"),
                ),
              ),
            ] else ...[
              TextField(
                controller: _passCtrl,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: "New Password",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _confirmCtrl,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: "Confirm Password",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isVerifying ? null : _setPassword,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                  child: _isVerifying
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text("ACTIVATE"),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
