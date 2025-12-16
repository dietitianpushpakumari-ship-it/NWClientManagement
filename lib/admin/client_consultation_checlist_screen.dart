import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nutricare_client_management/master_diet_planner/client_clinical_assessment_sheet.dart';
import 'package:nutricare_client_management/master_diet_planner/client_history_sheet.dart';
import 'package:nutricare_client_management/modules/client/model/client_model.dart';
import 'package:nutricare_client_management/modules/client/model/vitals_model.dart';
import 'package:nutricare_client_management/modules/client/screen/master_plan_assignment_page.dart';
// Placeholder route imports (Replace with actual routes when implementing the modules)
import 'package:nutricare_client_management/screens/vitals_history_page.dart';
import 'package:nutricare_client_management/screens/dash/client-personal_info_sheet.dart';
import 'package:nutricare_client_management/modules/client/screen/assigned_diet_plan_entry_screen.dart';
import 'package:nutricare_client_management/modules/package/model/package_assignment_model.dart';
import 'package:intl/intl.dart';
import 'package:nutricare_client_management/modules/client/services/vitals_service.dart';
import 'package:nutricare_client_management/admin/labvital/global_service_provider.dart';
// 🎯 NEW IMPORTS for refactored sheets



// --- ENUMS & MODULE DEFINITIONS (Retained) ---
enum ModuleStatus { pending, complete, requiredAttention }
enum ConsultationType { initial, followup }
class ConsultationModule {
  final String key;
  final String title;
  final IconData icon;
  final Color color;
  final bool requiredForConsult;
  ConsultationModule({required this.key, required this.title, required this.icon, required this.color, this.requiredForConsult = true});
}

class ClientConsultationChecklistScreen extends ConsumerStatefulWidget {
  final ClientModel? client;
  final VitalsModel? latestVitals;
  final PackageAssignmentModel? activePackage;

  const ClientConsultationChecklistScreen({
    super.key,
    this.client, // Made nullable
    this.latestVitals,
    this.activePackage,
  });

  @override
  ConsumerState<ClientConsultationChecklistScreen> createState() => _ClientConsultationChecklistScreenState();
}

class _ClientConsultationChecklistScreenState extends ConsumerState<ClientConsultationChecklistScreen> {
  Map<String, ModuleStatus> _moduleStatus = {};

  final List<ConsultationModule> _modules = [
    ConsultationModule(key: 'profile', title: "1. Personal & Contact Info", icon: Icons.person_pin, color: Colors.indigo, requiredForConsult: false),
    ConsultationModule(key: 'vitals', title: "2. Body Vitals & Measurements", icon: Icons.monitor_heart, color: Colors.deepOrange, requiredForConsult: true),
    ConsultationModule(key: 'history', title: "3. Medical & Lifestyle History", icon: Icons.library_books, color: Colors.teal, requiredForConsult: false),
    ConsultationModule(key: 'clinical', title: "4. Clinical Assessment & Diagnosis", icon: Icons.local_hospital, color: Colors.redAccent, requiredForConsult: true),
    ConsultationModule(key: 'plan', title: "5. Final Diet Plan Assignment", icon: Icons.assignment_turned_in, color: Colors.blueAccent, requiredForConsult: true),
    ConsultationModule(key: 'payment', title: "6. Package & Payment Status", icon: Icons.payment, color: Colors.green, requiredForConsult: true),
  ];

  late ConsultationType _consultationType;

  // 🎯 State to hold the current, mutable client model
  ClientModel? _currentClient;
  VitalsModel? _latestVitals;


  @override
  void initState() {
    super.initState();
    _currentClient = widget.client; // Initialize with widget client
    _latestVitals = widget.latestVitals; // Initialize Vitals
    _consultationType = _latestVitals != null ? ConsultationType.followup : ConsultationType.initial;

    if (_currentClient != null && _currentClient!.id.isNotEmpty && _latestVitals == null) {
      _fetchLatestVitals();
    }

    _initializeStatus();
  }

  Future<void> _fetchLatestVitals() async {
    if (_currentClient == null || _currentClient!.id.isEmpty || !mounted) return;

    final vitalsService = ref.read(vitalsServiceProvider);

    try {
      // Assuming VitalsService has a method to get the *absolute latest* vital record
      final VitalsModel? fetchedVitals = await vitalsService.getLatestVitals(_currentClient!.id);

      if (fetchedVitals != null && mounted) {
        setState(() {
          _latestVitals = fetchedVitals;
          _consultationType = ConsultationType.followup;
          _initializeStatus(); // Rerun status check with fresh data
        });
      }
    } catch (e) {
      debugPrint('Error fetching latest vitals: $e');
    }
  }


  void _initializeStatus() {
    final hasActivePackage = widget.activePackage != null && widget.activePackage!.id.isNotEmpty;

    // Vitals status relies on the current _latestVitals state
    final isVitalsComplete = _latestVitals != null;
    final isHistoryComplete = _latestVitals != null; // Proxy: History is complete if Vitals is complete

    // Use _currentClient for status checks
    final isProfileComplete = _currentClient != null &&
        _currentClient!.name.isNotEmpty &&
        _currentClient!.mobile.isNotEmpty;
    // Check if Plan was explicitly completed
    final isPlanComplete = _moduleStatus['plan'] == ModuleStatus.complete;
    // Check if Clinical was explicitly completed
    final isClinicalComplete = _moduleStatus['clinical'] == ModuleStatus.complete;

    setState(() {
      _moduleStatus = {
        'profile': isProfileComplete ? ModuleStatus.complete : ModuleStatus.pending,
        'vitals': isVitalsComplete ? ModuleStatus.complete : ModuleStatus.pending, // 🎯 Uses fetched data
        'history': isHistoryComplete ? ModuleStatus.complete : ModuleStatus.pending, // 🎯 FIX: History completion based on fetched vitals status
        'clinical': isClinicalComplete ? ModuleStatus.complete : ModuleStatus.pending,
        'plan': isPlanComplete ? ModuleStatus.complete : ModuleStatus.pending,
        'payment': hasActivePackage ? (widget.activePackage!.id.isNotEmpty ? ModuleStatus.complete : ModuleStatus.requiredAttention) : ModuleStatus.pending,
      };
    });
  }

  // --- UI/STATE HELPERS (Omitted for brevity) ---
  String _getModuleSubtitle(ConsultationModule module) {
    final isFollowup = _consultationType == ConsultationType.followup;
    switch (module.key) {
      case 'profile':
      // Use _currentClient for display checks
        return (_currentClient == null || _currentClient!.name.isEmpty) ? "Client record missing or incomplete. Fill details now." : (isFollowup ? "Details locked for follow-up. Review only." : "Attendant task: Fill all primary details.");
      case 'vitals':
        if (_latestVitals == null) return "Record current body measurements.";
        final date = DateFormat('MMM d, yyyy').format(_latestVitals!.date);
        return "Last recorded: ${_latestVitals!.weightKg}kg on $date. Tap to add new.";
      case 'history':
        return _moduleStatus['history'] == ModuleStatus.complete ? "Medical and lifestyle history recorded." : "Comprehensive medical history review required.";
      case 'payment':
        if (widget.activePackage == null) return "Admin task: Assign package and process payment/due status.";
        final hasRemainingSessions = widget.activePackage!.id.isNotEmpty;
        final status = hasRemainingSessions ? "Active" : "Renewal Due";
        return "Package assigned: ${widget.activePackage!.packageName}. Status: $status.";
      case 'clinical':
        return _moduleStatus['clinical'] == ModuleStatus.complete ? "Clinical assessment and diagnosis recorded." : "Doctor task: Document diagnosis, complaints, and new notes.";
      case 'plan':
        return "Doctor task: Create/modify and assign the final diet plan.";
      default:
        return "";
    }
  }

  IconData _getStatusIcon(ModuleStatus status) {
    switch (status) {
      case ModuleStatus.complete: return Icons.check_circle_outline;
      case ModuleStatus.requiredAttention: return Icons.warning_amber;
      case ModuleStatus.pending: default: return Icons.radio_button_unchecked;
    }
  }

  Color _getStatusColor(ModuleStatus status) {
    switch (status) {
      case ModuleStatus.complete: return Colors.green;
      case ModuleStatus.requiredAttention: return Colors.orange;
      case ModuleStatus.pending: default: return Colors.grey.shade500;
    }
  }

  // --- NAVIGATION & ACTION HANDLERS ---

  void _handleCardTap(ConsultationModule module) async {

    // Case 1: Always allow profile navigation.
    if (module.key == 'profile') {
      await Navigator.push(context, MaterialPageRoute(builder: (_) => ClientPersonalInfoSheet(
        client: _currentClient,
        onSave: (ClientModel updatedClient) {
          setState(() {
            _currentClient = updatedClient;
          });
        },
      )));
      _initializeStatus();
      return;
    }

    // Case 2: Guard access for all other modules if client record is not established.
    if (_currentClient == null || _currentClient!.id.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Error: Cannot proceed. Please complete and save Personal Info first."), backgroundColor: Colors.red));
      return;
    }

    final ClientModel client = _currentClient!;
    bool? savedSuccessfully;

    switch (module.key) {
      case 'vitals':
        _moduleStatus['clinical'] = ModuleStatus.pending;
        _initializeStatus();

        await Navigator.push(context, MaterialPageRoute(builder: (_) => VitalsHistoryPage(clientId: client.id, clientName: client.name,)));

        await _fetchLatestVitals();
        break;

      case 'history':
      // 🎯 NEW: Navigate to History Sheet
        savedSuccessfully = await Navigator.push(context, MaterialPageRoute<bool>(
          builder: (_) => ClientHistorySheet(
            client: client,
            latestVitals: _latestVitals,
            onSave: (isSaved) {
              if (isSaved) {
                // If Vitals exists, update its underlying history fields and mark history complete.
                _moduleStatus['history'] = ModuleStatus.complete;
                // Since this updates Vitals fields, refetch to update _latestVitals
                _fetchLatestVitals();
              }
            },
          ),
        ));
        if (savedSuccessfully == true) {
          _moduleStatus['history'] = ModuleStatus.complete; // Ensures immediate visual update
          _initializeStatus();
        }
        break;

      case 'clinical':
      // 🎯 NEW: Navigate to Clinical Assessment Sheet
        savedSuccessfully = await Navigator.push(context, MaterialPageRoute<bool>(
          builder: (_) => ClientClinicalAssessmentSheet(
            //client: client,
            latestVitals: _latestVitals,
            onSaveAssessment: (isSaved) {
              if (isSaved != null) {
             //   _moduleStatus['clinical'] = ModuleStatus.complete;
                // Refetch vitals if clinical data is considered part of the latest vital record
              //  _fetchLatestVitals();
              }
            },
          ),
        ));
        if (savedSuccessfully == true) {
          _moduleStatus['clinical'] = ModuleStatus.complete; // Ensures immediate visual update
          _initializeStatus();
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Diagnosis Recorded. Status Updated."), backgroundColor: Colors.lightGreen));
        } else if (savedSuccessfully == false) {
          _initializeStatus();
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Clinical assessment cancelled/failed."), backgroundColor: Colors.orange));
        }
        break;

      case 'plan':
        await Navigator.push(context, MaterialPageRoute(builder: (_) => MasterPlanAssignmentPage(
            client: client
        )));
        break;
      case 'payment':
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Opening: Package & Payment Form.")));
        break;
    }
  }

  void _finalizeConsultation() {
    bool allRequiredDone = true;
    for (var module in _modules) {
      if (module.requiredForConsult && _moduleStatus[module.key] == ModuleStatus.pending) {
        allRequiredDone = false;
        break;
      }
    }

    if (!allRequiredDone) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please complete all REQUIRED modules (Pending status) before finalizing."), backgroundColor: Colors.red));
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Consultation Finalized! Ready for follow-up."), backgroundColor: Colors.lightGreen));
    Navigator.pop(context);
  }

  // --- UI COMPONENTS (ULTRA PREMIUM) ---
  Widget _buildModuleCard(ConsultationModule module) {
    final status = _moduleStatus[module.key] ?? ModuleStatus.pending;
    final statusColor = _getStatusColor(status);
    final statusIcon = _getStatusIcon(status);

    return GestureDetector(
      onTap: () => _handleCardTap(module),
      child: Container(
        padding: const EdgeInsets.all(20),
        margin: const EdgeInsets.only(bottom: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: statusColor.withOpacity(0.1), blurRadius: 15, offset: const Offset(0, 5))],
          border: Border.all(color: statusColor.withOpacity(0.4), width: 2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: module.color.withOpacity(0.1), shape: BoxShape.circle),
                  child: Icon(module.icon, color: module.color, size: 24),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(module.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(_getModuleSubtitle(module), style: TextStyle(fontSize: 12, color: Colors.grey.shade600), maxLines: 2, overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey.shade400),
              ],
            ),
            const SizedBox(height: 15),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(status.toString().split('.').last.toUpperCase(), style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: statusColor, letterSpacing: 0.5)),
                Icon(statusIcon, color: statusColor, size: 20),
              ],
            ),
          ],
        ),
      ),
    );
  }
// ... (rest of the build and header methods)
// ... (rest of the build and header methods)

  Widget _buildHeader(BuildContext context) {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 10, 20, 16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.9),
            border: Border(bottom: BorderSide(color: Colors.grey.withOpacity(0.1))),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  GestureDetector(onTap: () => Navigator.pop(context), child: const Icon(Icons.arrow_back)),
                  const SizedBox(width: 16),
                  Expanded(child: Text("Client Consultation Checklist", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold))),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: Colors.teal.withOpacity(.1), shape: BoxShape.circle),
                    child: Icon(_consultationType == ConsultationType.initial ? Icons.person_add : Icons.sync, color: Colors.teal),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.only(left: 40.0),
                child: Text(
                  // Use local state for display
                  "Client: ${_currentClient?.name ?? 'New Client'}",
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 40.0),
                child: Text(
                  _consultationType == ConsultationType.initial ? "Initial Consultation" : "Follow-up Consultation",
                  style: TextStyle(fontSize: 12, color: Colors.teal.shade700),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      body: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // 1. Consultation Module Cards
                ..._modules.map((module) => _buildModuleCard(module)).toList(),

                const SizedBox(height: 40),

                // 2. Finalization Button
                ElevatedButton(
                  onPressed: _finalizeConsultation,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    minimumSize: const Size(double.infinity, 55),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text("FINALIZE CONSULTATION", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }
}