import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nutricare_client_management/admin/system_config_service.dart';

class SystemConfigScreen extends ConsumerStatefulWidget {
  const SystemConfigScreen({super.key});

  @override
  ConsumerState<SystemConfigScreen> createState() => _SystemConfigScreenState();
}

class _SystemConfigScreenState extends ConsumerState<SystemConfigScreen> {
  final _apiKeyController = TextEditingController();
  final _modelController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final config = await ref.read(systemConfigServiceProvider).getConfigOnce();
    setState(() {
      _apiKeyController.text = config.translationApiKey;
      _modelController.text = config.translationModel;
    });
  }

  Future<void> _save() async {
    setState(() => _isLoading = true);
    try {
      final newConfig = SystemConfigModel(
        translationApiKey: _apiKeyController.text.trim(),
        translationModel: _modelController.text.trim().isEmpty ? 'gemini-1.5-flash' : _modelController.text.trim(),
      );

      await ref.read(systemConfigServiceProvider).updateConfig(newConfig);

      if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Configuration Saved!")));
    } catch (e) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if(mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      appBar: AppBar(title: const Text("System Configuration")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("AI Translation Settings", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.indigo)),
            const SizedBox(height: 8),
            const Text("Configure the credentials for auto-translation features.", style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 20),

            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
              child: Column(
                children: [
                  TextField(
                    controller: _apiKeyController,
                    decoration: const InputDecoration(
                      labelText: "Gemini API Key",
                      border: OutlineInputBorder(),
                      helperText: "Get from aistudio.google.com",
                      prefixIcon: Icon(Icons.vpn_key),
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _modelController,
                    decoration: const InputDecoration(
                      labelText: "Model Name",
                      hintText: "gemini-1.5-flash",
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.smart_toy),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _save,
                icon: const Icon(Icons.save),
                label: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text("Save Configuration"),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white),
              ),
            )
          ],
        ),
      ),
    );
  }
}