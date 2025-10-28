import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
// 🎯 NOTE: Since AuthWrapper handles navigation on success,
// you technically don't need this import for navigation,
// but keep it if you use the screen elsewhere.
// import 'package:nutricare_client_management/admin/admin_dashboard_Screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance; // 🎯 Firebase Auth Instance

  bool _isLoading = false;
  bool _isPasswordVisible = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // 🎯 CORE LOGIN LOGIC (Asynchronous)
  void _handleLogin() async {
    if (_formKey.currentState?.validate() == true) {
      // 1. Start Loading
      setState(() {
        _isLoading = true;
      });

      try {
        // 2. Perform actual Firebase sign-in
        await _auth.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );

        // 3. SUCCESS: Authentication succeeded
        // The AuthWrapper will detect the session change and navigate automatically.
        // We just show a quick message and stop loading.
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Login successful! Redirecting...'),
            backgroundColor: Colors.green,
          ),
        );

        // DO NOT manually navigate here: AuthWrapper handles it.

      } on FirebaseAuthException catch (e) {
        // 4. FAILURE: Catch specific Firebase errors
        String errorMessage = 'Login failed. Please check your credentials.';

        if (e.code == 'user-not-found' || e.code == 'wrong-password') {
          errorMessage = 'Invalid email or password.';
        } else if (e.code == 'invalid-email') {
          errorMessage = 'The email address is not valid.';
        } else if (e.code == 'network-request-failed') {
          errorMessage = 'Network error. Check your connection.';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
        );

      } catch (e) {
        // 5. General error handling (e.g., network issues)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('An unexpected error occurred: ${e.toString()}'), backgroundColor: Colors.red),
        );
      } finally {
        // 6. Stop Loading (always runs)
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Login'),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: colorScheme.primary,
          statusBarIconBrightness: Brightness.light,
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // --- 1. App Icon/Logo Placeholder ---
                Icon(
                  Icons.lock_person,
                  size: 100,
                  color: colorScheme.primary,
                ),
                const SizedBox(height: 16),
                Text(
                  'Sign In to NutriCare Admin',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 32),

                // --- 2. Email Field ---
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    prefixIcon: const Icon(Icons.email),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    filled: true,
                    fillColor: colorScheme.surfaceVariant.withOpacity(0.2),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your email';
                    }
                    if (!value.contains('@') || !value.contains('.')) {
                      return 'Please enter a valid email';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // --- 3. Password Field ---
                TextFormField(
                  controller: _passwordController,
                  obscureText: !_isPasswordVisible,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() {
                          _isPasswordVisible = !_isPasswordVisible;
                        });
                      },
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    filled: true,
                    fillColor: colorScheme.surfaceVariant.withOpacity(0.2),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your password';
                    }
                    if (value.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                // --- 4. Login Button ---
                ElevatedButton(
                  onPressed: _isLoading ? null : _handleLogin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: colorScheme.onPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 5,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 3,
                    ),
                  )
                      : const Text(
                    'LOGIN',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 12),

                // --- Forgot Password Link ---
                TextButton(
                  onPressed: () {
                    // Implement Forgot Password navigation
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Forgot Password link clicked')),
                    );
                  },
                  child: Text(
                    'Forgot Password?',
                    style: TextStyle(color: colorScheme.secondary),
                  ),
                ),
                const SizedBox(height: 60),

                // --- 5. Footer/Sign Up Link ---
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Don't have an account?",
                      style: TextStyle(color: colorScheme.onSurfaceVariant),
                    ),
                    TextButton(
                      onPressed: () {
                        // Implement Sign Up navigation
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Sign Up link clicked')),
                        );
                      },
                      child: Text(
                        'Sign Up',
                        style: TextStyle(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.bold
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}