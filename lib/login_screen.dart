import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nutricare_client_management/admin/labvital/global_service_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

// 識 ADMIN SERVICES & MODELS
import 'package:nutricare_client_management/admin/admin_auth_service.dart';
import 'package:nutricare_client_management/admin/admin_dashboard_Screen.dart';
import 'package:nutricare_client_management/admin/database_provider.dart';
import 'package:nutricare_client_management/admin/tenant_model.dart';
import 'package:nutricare_client_management/modules/client/services/client_service.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> with SingleTickerProviderStateMixin {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();

  bool _isCheckingUser = false;
  bool _emailVerified = false;
  TenantModel? _detectedTenant;
  bool _isLoading = false;
  bool _showPassword = false;

  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000));
    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic));
    _animController.forward();
  }

  // --- LOGIC ---

  Future<void> _handleContinue() async {
    final email = _emailCtrl.text.trim();
    if (!email.contains('@')) { _showSnack("Invalid Email Address", true); return; }

    setState(() => _isCheckingUser = true);

    try {
      final service = ref.read(adminAuthServiceProvider);
      final tenant = await service.resolveTenant(email);

      if (tenant != null) {
        ref.read(currentTenantConfigProvider.notifier).state = tenant;
        await ref.read(firebaseAppProvider.future);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('last_tenant_id', tenant.id);
      } else {
        ref.read(currentTenantConfigProvider.notifier).state = null;
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('last_tenant_id');
      }

      setState(() {
        _detectedTenant = tenant;
        _emailVerified = true;
        _isCheckingUser = false;
      });

    } catch (e) {
      _showSnack("Connection Error: $e", true);
      setState(() => _isCheckingUser = false);
    }
  }

// lib/login_screen.dart

// ... (omitted imports and class definition)

  Future<void> _handleLogin() async {
    if (_passCtrl.text.isEmpty) { _showSnack("Enter Password", true); return; }

    setState(() => _isLoading = true);
    try {
      final service = ref.read(adminAuthServiceProvider);

      // 🎯 DEBUG STEP: Print the currently configured Firebase App Project ID
      final currentApp = ref.read(firebaseAppProvider).value; // Use .value to get the Future's result if available
      final String projectId = currentApp?.options.projectId ?? 'DEFAULT_APP';
      print("🎯 ATTEMPTING LOGIN ON PROJECT: $projectId");

      // The actual login call
      await service.signIn(_emailCtrl.text.trim(), _passCtrl.text.trim());

      if(mounted) {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const AdminDashboardScreen()));
      }
    } catch (e) {
      _showSnack("Login Failed. Check password. Error: ${e.toString()}", true);
    } finally {
      if(mounted) setState(() => _isLoading = false);
    }
  }

// ... (rest of the file)
  Future<void> _handleGuestDemo() async {
    setState(() => _isLoading = true);
    try {
      final clientService = ref.read(clientServiceProvider);
      final guestConfig = await clientService.fetchTenantConfig('guest');

      ref.read(currentTenantConfigProvider.notifier).state = guestConfig;
      await ref.read(firebaseAppProvider.future);

      final auth = ref.read(authProvider);
      await auth.signInWithEmailAndPassword(email: "guest@demo.com", password: "guestpassword");

      if(mounted) {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const AdminDashboardScreen()));
      }
    } catch(e) {
      _showSnack("Demo Access Failed: $e", true);
    } finally {
      if(mounted) setState(() => _isLoading = false);
    }
  }

  void _resetFlow() {
    setState(() {
      _emailVerified = false;
      _passCtrl.clear();
      _detectedTenant = null;
      _showPassword = false;
      ref.read(currentTenantConfigProvider.notifier).state = null;
    });
  }

  void _showSnack(String msg, bool isError) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: isError ? Colors.red : Colors.green));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          // 1. Background Gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFE0F7FA), Color(0xFFF3E5F5), Colors.white],
              ),
            ),
          ),

          // 2. Ambient Orbs (Fixed using ImageFiltered)
          Positioned(
            top: -100, right: -100,
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
              child: Container(
                width: 400, height: 400,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: theme.colorScheme.primary.withOpacity(0.15),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -100, left: -100,
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
              child: Container(
                width: 300, height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.purple.withOpacity(0.1),
                ),
              ),
            ),
          ),

          // 3. Main Content
          Center(
            child: SingleChildScrollView(
              // 🎯 OPTIMIZATION: Reduced Horizontal Padding (24 -> 16)
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: FadeTransition(
                opacity: _fadeAnim,
                child: SlideTransition(
                  position: _slideAnim,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // --- Logo Section ---
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 30, offset: const Offset(0, 10))],
                        ),
                        child: Icon(_detectedTenant == null ? Icons.admin_panel_settings_rounded : Icons.business_rounded, size: 56, color: theme.colorScheme.primary),
                      ),
                      const SizedBox(height: 32),

                      // --- Headings ---
                      Text(
                        _detectedTenant?.name ?? "Admin Portal",
                        style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.blueGrey.shade900, letterSpacing: -0.5),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _emailVerified ? _emailCtrl.text : "Secure Access for Staff",
                        style: TextStyle(fontSize: 14, color: Colors.blueGrey.shade600, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 40),

                      // --- The Glass Card ---
                      ClipRRect(
                        borderRadius: BorderRadius.circular(30),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                          child: Container(
                            width: double.infinity,
                            // 🎯 OPTIMIZATION: Reduced Card Padding (32 -> 24)
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.6),
                              borderRadius: BorderRadius.circular(30),
                              border: Border.all(color: Colors.white.withOpacity(0.8), width: 1.5),
                              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 10))],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                if (!_emailVerified) ...[
                                  // STEP 1: EMAIL
                                  _buildPremiumInput(
                                    controller: _emailCtrl,
                                    label: "Email Address",
                                    icon: Icons.email_outlined,
                                    hint: "admin@clinic.com",
                                  ),
                                  const SizedBox(height: 24),
                                  _buildPremiumButton(
                                    label: "CONTINUE",
                                    isLoading: _isCheckingUser,
                                    onTap: _handleContinue,
                                  ),
                                ] else ...[
                                  // STEP 2: PASSWORD
                                  _buildPremiumInput(
                                    controller: _passCtrl,
                                    label: "Password",
                                    icon: Icons.lock_outline,
                                    isPassword: true,
                                    showPassword: _showPassword,
                                    onTogglePassword: () => setState(() => _showPassword = !_showPassword),
                                  ),
                                  const SizedBox(height: 24),
                                  _buildPremiumButton(
                                    label: "LOGIN",
                                    isLoading: _isLoading,
                                    onTap: _handleLogin,
                                  ),
                                  const SizedBox(height: 16),
                                  TextButton(
                                    onPressed: _resetFlow,
                                    child: Text("Switch Account", style: TextStyle(color: Colors.blueGrey.shade600, fontWeight: FontWeight.w600)),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),

                      if (!_emailVerified) ...[
                        const SizedBox(height: 30),
                        TextButton(
                          onPressed: _handleGuestDemo,
                          style: TextButton.styleFrom(foregroundColor: theme.colorScheme.primary),
                          child: const Text("Try Guest Demo", style: TextStyle(fontWeight: FontWeight.bold)),
                        )
                      ]
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 🎯 OPTIMIZED INPUT FIELD
  Widget _buildPremiumInput({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hint,
    bool isPassword = false,
    bool showPassword = false,
    VoidCallback? onTogglePassword,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
          ),
          child: TextField(
            controller: controller,
            obscureText: isPassword && !showPassword,
            // 🎯 OPTIMIZATION: Reduced Font Size (16 -> 15) to fit more chars
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.black87),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: Colors.grey.shade400, fontWeight: FontWeight.normal),
              prefixIcon: Icon(icon, color: Colors.blueGrey.shade300, size: 20),
              suffixIcon: isPassword
                  ? IconButton(
                icon: Icon(showPassword ? Icons.visibility : Icons.visibility_off, color: Colors.blueGrey.shade300),
                onPressed: onTogglePassword,
              )
                  : null,
              border: InputBorder.none,
              // 🎯 OPTIMIZATION: Reduced Content Padding (20 -> 16)
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPremiumButton({required String label, required bool isLoading, required VoidCallback onTap}) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Theme.of(context).colorScheme.primary.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 6))],
      ),
      child: ElevatedButton(
        onPressed: isLoading ? null : onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 0,
        ),
        child: isLoading
            ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
            : Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
      ),
    );
  }
}