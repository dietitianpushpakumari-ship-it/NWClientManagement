import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nutricare_client_management/admin/configuration/app_module_config.dart';
import 'package:nutricare_client_management/admin/configuration/company_config_model.dart';
import 'package:nutricare_client_management/admin/configuration/company_config_services.dart';


class CompanyModuleSettingsScreen extends ConsumerStatefulWidget {
  final String tenantId;
  final String companyName;

  const CompanyModuleSettingsScreen({
    super.key,
    required this.tenantId,
    required this.companyName,
  });

  @override
  ConsumerState<CompanyModuleSettingsScreen> createState() => _CompanyModuleSettingsScreenState();
}

class _CompanyModuleSettingsScreenState extends ConsumerState<CompanyModuleSettingsScreen> {
  Set<String> _enabledModuleIds = {};
  bool _isInit = true;
  bool _isSaving = false;
  bool _hasChanges = false;

  void _toggleModule(String moduleId, bool isEnabled) {
    setState(() {
      if (isEnabled) {
        _enabledModuleIds.add(moduleId);
      } else {
        _enabledModuleIds.remove(moduleId);
      }
      _hasChanges = true;
    });
  }

  Future<void> _saveChanges() async {
    setState(() => _isSaving = true);
    try {
      final service = ref.read(companyConfigServiceProvider);

      await service.updateEnabledModules(widget.tenantId, _enabledModuleIds.toList());

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Settings saved successfully!')));
        setState(() => _hasChanges = false);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final service = ref.watch(companyConfigServiceProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      // 🎯 NO APP BAR - Custom Safe Area Header
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: StreamBuilder<CompanyConfigModel>(
                stream: service.streamCompanyConfig(widget.tenantId),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (_isInit && snapshot.hasData) {
                    _enabledModuleIds = Set.from(snapshot.data!.enabledModules);
                    _isInit = false;
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.all(20),
                    itemCount: AppModule.values.length,
                    separatorBuilder: (ctx, index) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final module = AppModule.values[index];
                      final isEnabled = _enabledModuleIds.contains(module.id);

                      return Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: isEnabled ? Colors.blue.withOpacity(0.3) : Colors.transparent),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
                        ),
                        child: SwitchListTile(
                          value: isEnabled,
                          onChanged: (val) => _toggleModule(module.id, val),
                          activeColor: Colors.blue,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          secondary: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                                color: isEnabled ? Colors.blue.withOpacity(0.1) : Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(12)
                            ),
                            child: Icon(module.icon, color: isEnabled ? Colors.blue : Colors.grey),
                          ),
                          title: Text(module.label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 4.0),
                            child: Text(module.description, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 🎯 Custom Header Widget
  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200)
                  ),
                  child: const Icon(Icons.arrow_back, size: 20, color: Colors.black87),
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Module Config", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
                  Text(widget.companyName, style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
                ],
              ),
            ],
          ),

          // Save Action
          InkWell(
            onTap: (_hasChanges && !_isSaving) ? _saveChanges : null,
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: _hasChanges ? Colors.blue : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(20),
              ),
              child: _isSaving
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Text("SAVE", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: _hasChanges ? Colors.white : Colors.grey)),
            ),
          )
        ],
      ),
    );
  }
}