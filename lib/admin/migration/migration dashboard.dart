import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nutricare_client_management/admin/migration/db_migration_service.dart';
import 'package:nutricare_client_management/admin/migration/migration_config.dart';
import 'package:nutricare_client_management/admin/migration/migration_state.dart';


class MigrationDashboard extends StatefulWidget {
  const MigrationDashboard({super.key});

  @override
  State<MigrationDashboard> createState() => _MigrationDashboardState();
}

class _MigrationDashboardState extends State<MigrationDashboard> {
  // UI State
  late List<MigrationTask> _tasks;
  String? _selectedTenantId;
  String? _selectedTenantName;
  Map<String, dynamic>? _selectedTenantConfig; // Stores the full document data (API Keys)
  bool _isMigrating = false;

  @override
  void initState() {
    super.initState();
    // Initialize tasks from the config file list
    _tasks = kMigrationCollections
        .map((config) => MigrationTask(config: config))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("DB Migration Tool"),
        backgroundColor: Colors.indigoAccent,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          _buildTenantHeader(),
          const Divider(height: 1, thickness: 1),
          Expanded(child: _buildTaskList()),
          _buildBottomBar(),
        ],
      ),
    );
  }

  // --- STEP 1: Tenant Selector (Dynamic) ---
  Widget _buildTenantHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
      color: Colors.grey[50],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.dns, size: 16, color: Colors.indigo),
              const SizedBox(width: 8),
              const Text(
                  "TARGET ENVIRONMENT",
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.indigo)
              ),
            ],
          ),
          const SizedBox(height: 12),

          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('tenants').snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) return Text("Error: ${snapshot.error}", style: const TextStyle(color: Colors.red));
              if (!snapshot.hasData) return const LinearProgressIndicator(minHeight: 2);

              final docs = snapshot.data!.docs;

              if (docs.isEmpty) {
                return const Text("No tenants found in 'tenants' collection.");
              }

              return DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                  helperText: "Select the project to copy data TO.",
                ),
                hint: const Text("Select Target Project..."),
                value: _selectedTenantId,
                isExpanded: true,
                items: docs.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final name = data['name'] ?? 'Unknown Tenant';

                  return DropdownMenuItem<String>(
                    value: doc.id, // Use ID as the value to ensure uniqueness
                    child: Text(name),
                  );
                }).toList(),
                onChanged: _isMigrating ? null : (val) {
                  if (val == null) return;

                  // 🔍 DEBUG: Find the document and store ALL data
                  final selectedDoc = docs.firstWhere((d) => d.id == val);
                  final data = selectedDoc.data() as Map<String, dynamic>;

                  print("✅ Tenant Selected: ${data['name']}");

                  setState(() {
                    _selectedTenantId = val;
                    _selectedTenantName = data['name'];
                    _selectedTenantConfig = data; // <--- Critical: Capture API Keys here
                  });
                },
              );
            },
          ),
        ],
      ),
    );
  }

  // --- STEP 2: Task List ---
  Widget _buildTaskList() {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _tasks.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final task = _tasks[index];
        final isProcessing = task.status == 'Copying...';
        final isError = task.status == 'Error';

        return Card(
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: BorderSide(
                color: isProcessing ? Colors.indigoAccent : Colors.transparent,
                width: 1.5
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(4.0),
            child: ListTile(
              enabled: !_isMigrating,
              leading: Checkbox(
                activeColor: Colors.indigo,
                value: task.isSelected,
                onChanged: _isMigrating ? null : (v) => setState(() => task.isSelected = v!),
              ),
              title: Text(task.config.label, style: const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(task.config.path, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                  if (task.status != 'Idle') ...[
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: task.progress,
                        minHeight: 6,
                        color: isError ? Colors.red : Colors.green,
                        backgroundColor: Colors.grey[200],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                        "${task.status} ${(task.progress * 100).toStringAsFixed(0)}%",
                        style: TextStyle(
                            fontSize: 10,
                            color: isError ? Colors.red : Colors.green[700],
                            fontWeight: FontWeight.bold
                        )
                    ),
                  ]
                ],
              ),
              trailing: _getStatusIcon(task.status),
            ),
          ),
        );
      },
    );
  }

  Widget _getStatusIcon(String status) {
    switch (status) {
      case 'Done': return const Icon(Icons.check_circle, color: Colors.green);
      case 'Error': return const Icon(Icons.error, color: Colors.red);
      case 'Copying...': return const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2));
      default: return const Icon(Icons.circle_outlined, color: Colors.grey);
    }
  }

  // --- STEP 3: Action Button ---
  Widget _buildBottomBar() {
    final selectedCount = _tasks.where((t) => t.isSelected).length;
    final bool canStart = !_isMigrating && selectedCount > 0 && _selectedTenantId != null;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: const Offset(0, -4))]
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.indigo,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              elevation: canStart ? 4 : 0,
            ),
            icon: _isMigrating
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Icon(Icons.cloud_upload_outlined),
            label: Text(
                _isMigrating ? "MIGRATING DATA..." : "START MIGRATION ($selectedCount)",
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)
            ),
            onPressed: canStart ? _runMigration : null,
          ),
        ),
      ),
    );
  }

  // --- LOGIC: The Migration Runner ---
  Future<void> _runMigration() async {
    // 1. Validate Config Exists
    if (_selectedTenantConfig == null) {
      _showSnack("Please select a tenant first.", isError: true);
      return;
    }

    // 🔍 DEBUG: Print the keys found in Firestore
    print("--------------------------------------------------");
    print("🔍 DEBUG: Checking Keys for '$_selectedTenantName'...");
    print("🔍 KEYS FOUND: ${_selectedTenantConfig!.keys.toList()}");
    print("--------------------------------------------------");

    // 2. Extract Keys Robustly (Check both 'api_key' and 'apiKey')
    final apiKey = _selectedTenantConfig!['api_key'] ?? _selectedTenantConfig!['apiKey'];
    final appId = _selectedTenantConfig!['app_id'] ?? _selectedTenantConfig!['appId'];
    final projectId = _selectedTenantConfig!['project_id'] ?? _selectedTenantConfig!['projectId'];
    final senderId = _selectedTenantConfig!['messaging_sender_id'] ?? _selectedTenantConfig!['messagingSenderId'];

    // 3. Validate Keys Not Null
    if (apiKey == null || appId == null || projectId == null) {
      print("❌ ERROR: Missing one or more required keys.");
      _showSnack("Database Missing Keys: 'api_key', 'app_id', or 'project_id' not found in Tenant doc.", isError: true);
      return;
    }

    // 4. Create a Clean Config Map for the Service
    final cleanConfig = {
      'api_key': apiKey,
      'app_id': appId,
      'project_id': projectId,
      'messaging_sender_id': senderId,
    };

    setState(() => _isMigrating = true);
    final service = DbMigrationService();

    try {
      // 5. Connect Dynamically
      await service.connectToTarget(cleanConfig);

      // 6. Process Selected Tasks
      final tasksToRun = _tasks.where((t) => t.isSelected).toList();

      for (var task in tasksToRun) {
        setState(() {
          task.status = 'Copying...';
          task.progress = 0.05;
        });

        // Run the copy logic
        await service.copyCollection(
          path: task.config.path,
          onProgress: (percent) {
            setState(() => task.progress = percent);
          },
        );

        setState(() {
          task.status = 'Done';
          task.progress = 1.0;
        });
      }

      _showSnack("✅ Migration to $_selectedTenantName completed successfully!");

    } catch (e) {
      print("❌ Migration Critical Error: $e");
      _showSnack("Error: ${e.toString()}", isError: true);

      // Mark current processing task as Error
      for (var t in _tasks) {
        if (t.status == 'Copying...') t.status = 'Error';
      }

    } finally {
      setState(() => _isMigrating = false);
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
      ),
    );
  }
}