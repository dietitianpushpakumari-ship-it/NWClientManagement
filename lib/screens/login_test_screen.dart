// lib/screens/login_test_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../modules/client/model/client_model.dart';
import '../modules/client/services/client_service.dart';

class LoginTestScreen extends StatefulWidget {
  final ClientModel client;
  const LoginTestScreen({super.key, required this.client});

  @override
  State<LoginTestScreen> createState() => _LoginTestScreenState();
}

class _LoginTestScreenState extends State<LoginTestScreen> {
  final TextEditingController _idController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final ClientService _clientService = ClientService();

  String _testStatus = 'Awaiting Test...';
  Color _statusColor = Colors.grey;

  @override
  void initState() {
    super.initState();
    _idController.text = widget.client.loginId;
  }

  void _showSnackbar(String message, {Color color = Colors.red}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
      ),
    );
  }

  void _testLogin(ClientModel liveClient) async {
    final loginId = _idController.text.trim();
    final password = _passwordController.text.trim();

    setState(() {
      _testStatus = 'Testing credentials with Firebase Auth...';
      _statusColor = Colors.blue;
    });

    try {
      if (loginId.isEmpty || password.isEmpty) {
        throw Exception('Login ID and Password are required.');
      }

      // Pass credentials and the live client object for checks
      await _clientService.testLoginCredentials(loginId, password, liveClient);

      setState(() {
        _testStatus = 'SUCCESS: Credentials verified by Firebase Auth!';
        _statusColor = Colors.green;
      });

    } catch (e) {
      setState(() {
        _testStatus = 'FAILURE: ${e.toString().replaceAll('Exception: ', '')}';
        _statusColor = Colors.red;
      });
      _showSnackbar(_testStatus, color: Colors.red);
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('clients').doc(widget.client.id).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return Scaffold(appBar: AppBar(title: const Text('Login Test Error')), body: const Center(child: Text('Client record not found.')));
        }

        final liveClient = ClientModel.fromFirestore(snapshot.data!);
        final liveStatusColor = liveClient.status == 'Active' && liveClient.hasPasswordSet ? Colors.green : Colors.red;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Client Login Test Simulation'),
            backgroundColor: _statusColor,
          ),
          body: Center(
            child: Container(
              width: 400,
              padding: const EdgeInsets.all(24.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(color: Colors.grey.withOpacity(0.2), spreadRadius: 2, blurRadius: 5),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Testing Client: ${liveClient.name}', style: Theme.of(context).textTheme.headlineSmall, textAlign: TextAlign.center,),
                  Text(
                    'LIVE Status: ${liveClient.status} | Credential Set: ${liveClient.hasPasswordSet ? 'Yes' : 'No'}',
                    style: TextStyle(color: liveStatusColor, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const Divider(height: 30),

                  TextFormField(
                    controller: _idController,
                    decoration: const InputDecoration(
                      labelText: 'Client Login ID',
                      prefixIcon: Icon(Icons.person),
                      border: OutlineInputBorder(),
                    ),
                    readOnly: false,
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Password (Must Match Manually Set Password)',
                      prefixIcon: Icon(Icons.lock),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 24),

                  ElevatedButton.icon(
                    onPressed: () => _testLogin(liveClient),
                    icon: const Icon(Icons.login),
                    label: const Text('Test Login'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _statusColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                    ),
                  ),
                  const SizedBox(height: 24),

                  Text('Test Result:', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),

                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: _statusColor),
                    ),
                    child: Text(
                      _testStatus,
                      style: TextStyle(color: _statusColor, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}