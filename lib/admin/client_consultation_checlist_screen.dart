import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nutricare_client_management/admin/client_history_manager.dart';
import 'package:nutricare_client_management/admin/client_package_list_screen.dart';
import 'package:nutricare_client_management/admin/consultation_session_model.dart';
import 'package:nutricare_client_management/admin/consultation_session_service.dart';
import 'package:nutricare_client_management/admin/database_provider.dart';
import 'package:nutricare_client_management/helper/auth_service.dart';
import 'package:nutricare_client_management/master_diet_planner/client_clinical_assessment_sheet.dart';
import 'package:nutricare_client_management/modules/client/model/client_model.dart';
import 'package:nutricare_client_management/modules/client/model/vitals_model.dart';
import 'package:nutricare_client_management/modules/client/screen/assigned_diet_plan_list.dart';
import 'package:nutricare_client_management/screens/vitals_history_page.dart';
import 'package:nutricare_client_management/screens/dash/client-personal_info_sheet.dart';
import 'package:nutricare_client_management/modules/package/model/package_assignment_model.dart';
import 'package:intl/intl.dart';
import 'package:nutricare_client_management/modules/client/services/vitals_service.dart';
import 'package:nutricare_client_management/admin/labvital/global_service_provider.dart';

// --- ENUMS & MODULE DEFINITIONS ---
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
  final bool isFollowup;
  final bool forceNew;
  final String? parentSessionId;
  final String? viewSessionId;

  const ClientConsultationChecklistScreen({
    super.key,
    this.client,
    this.latestVitals,
    this.activePackage,
    this.isFollowup = false,
    this.forceNew = false,
    this.parentSessionId,
    this.viewSessionId,
  });

  @override
  ConsumerState<ClientConsultationChecklistScreen> createState() => _ClientConsultationChecklistScreenState();
}

class _ClientConsultationChecklistScreenState extends ConsumerState<ClientConsultationChecklistScreen> {
  Map<String, ModuleStatus> _moduleStatus = {};
  ConsultationSessionModel? _activeSession;
  bool _isFollowupMode = false;

  final List<ConsultationModule> _modules = [
    ConsultationModule(key: 'profile', title: "1. Personal & Contact Info", icon: Icons.person_pin, color: Colors.indigo, requiredForConsult: false),
    ConsultationModule(key: 'vitals', title: "2. Body Vitals & Measurements", icon: Icons.monitor_heart, color: Colors.deepOrange, requiredForConsult: true),
    ConsultationModule(key: 'history', title: "3. Medical & Lifestyle History", icon: Icons.library_books, color: Colors.teal, requiredForConsult: false),
    ConsultationModule(key: 'clinical', title: "4. Clinical Assessment & Diagnosis", icon: Icons.local_hospital, color: Colors.redAccent, requiredForConsult: true),
    ConsultationModule(key: 'plan', title: "5. Final Diet Plan Assignment", icon: Icons.assignment_turned_in, color: Colors.blueAccent, requiredForConsult: true),
    ConsultationModule(key: 'payment', title: "6. Package & Payment Status", icon: Icons.payment, color: Colors.green, requiredForConsult: true),
  ];

  late ConsultationType _consultationType;
  ClientModel? _currentClient;
  VitalsModel? _latestVitals;

  @override
  void initState() {
    super.initState();
    _currentClient = widget.client;
    _latestVitals = widget.latestVitals;
    _isFollowupMode = widget.isFollowup;
    _consultationType = _isFollowupMode ? ConsultationType.followup : ConsultationType.initial;

    _resumeActiveSession().then((_) => _initializeStatus());

    if (_currentClient != null && _currentClient!.id.isNotEmpty && _latestVitals == null) {
      _fetchLatestVitals();
    }
  }

  Future<void> _resumeActiveSession() async {
    if (_currentClient != null && _currentClient!.id.isNotEmpty) {
      final sessionService = ref.read(consultationServiceProvider);
      ConsultationSessionModel? session;

      if (widget.viewSessionId != null) {
        try {
          session = await sessionService.getSessionById(widget.viewSessionId!);
        } catch (e) {
          debugPrint("Error loading requested session: $e");
        }
      } else {
        session = await sessionService.getActiveSession(_currentClient!.id);

        if (session == null) {
          if (widget.isFollowup || widget.forceNew) {
            session = null;
          } else {
            session = await sessionService.getLatestSession(_currentClient!.id);
          }
        }
      }

      if (session != null) {
        if (mounted) {
          setState(() {
            _isFollowupMode = session!.consultationType == 'Followup';
            _consultationType = _isFollowupMode ? ConsultationType.followup : ConsultationType.initial;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _isFollowupMode = widget.isFollowup;
            _consultationType = _isFollowupMode ? ConsultationType.followup : ConsultationType.initial;
          });
        }
      }

      if (mounted) {
        setState(() => _activeSession = session);
        _initializeStatus();
      }
    }
  }

  Future<void> _fetchLatestVitals() async {
    if (_currentClient == null || _currentClient!.id.isEmpty || !mounted) return;
    final vitalsService = ref.read(vitalsServiceProvider);
    try {
      final VitalsModel? fetchedVitals = await vitalsService.getLatestVitals(_currentClient!.id);
      if (fetchedVitals != null && mounted) {
        setState(() {
          _latestVitals = fetchedVitals;
          _initializeStatus();
        });
      }
    } catch (e) {
      debugPrint('Error fetching latest vitals: $e');
    }
  }

  void _initializeStatus() {

    // 1. VITALS & HISTORY: Use explicit step flags from session (consistent with others)
    final bool isVitalsComplete = _activeSession?.steps['vitals'] == true;
    final bool isHistoryComplete = _activeSession?.steps['history'] == true;

    // 2. CLINICAL & PLAN: Use explicit step flags
    final bool isPlanComplete = _activeSession?.steps['plan'] == true;
    final bool isClinicalComplete = _activeSession?.steps['clinical'] == true;

    // 3. PROFILE: Client data check
    final bool isProfileComplete = _isFollowupMode
        ? true
        : (_currentClient != null && _currentClient!.name.isNotEmpty && _currentClient!.mobile.isNotEmpty);

    // 4. PAYMENT: Hybrid (Step flag OR Package existence)
    final bool isSubscriptionStepDone = _activeSession?.steps['subscription'] == true;
    final bool isPaymentComplete = _isFollowupMode
        ? true
        : (isSubscriptionStepDone || (widget.activePackage != null && widget.activePackage!.id.isNotEmpty));

    setState(() {
      _moduleStatus = {
        'profile': isProfileComplete ? ModuleStatus.complete : ModuleStatus.pending,
        'vitals': isVitalsComplete ? ModuleStatus.complete : ModuleStatus.pending,
        'history': isHistoryComplete ? ModuleStatus.complete : ModuleStatus.pending,
        'clinical': isClinicalComplete ? ModuleStatus.complete : ModuleStatus.pending,
        'plan': isPlanComplete ? ModuleStatus.complete : ModuleStatus.pending,
        'payment': isPaymentComplete ? ModuleStatus.complete : ModuleStatus.pending,
      };
    });
  }

  Future<String?> _ensureSessionActive() async {
    if (_activeSession != null) return _activeSession!.id;

    if (_currentClient == null || _currentClient!.id.isEmpty) return null;
    final String? currentUserId = ref.read(authServiceProvider).currentUser?.uid;

    if (currentUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Error: Dietitian not authenticated.")));
      return null;
    }

    final sessionService = ref.read(consultationServiceProvider);
    var session = await sessionService.getActiveSession(_currentClient!.id);

    if (session == null) {
      final sessionId = await sessionService.startSession(
        _currentClient!.id,
        currentUserId,
        isFollowup: _isFollowupMode,
        parentId: widget.parentSessionId,
      );
      session = await sessionService.getSessionById(sessionId);
    }

    if (mounted) setState(() => _activeSession = session);
    return session?.id;
  }

  void _handleCardTap(ConsultationModule module) async {
    final bool isSessionClosed = _activeSession?.status == 'complete' || _activeSession?.status == 'Closed';

    // PROFILE
    if (module.key == 'profile') {
      await Navigator.push(context, MaterialPageRoute(builder: (_) => ClientPersonalInfoSheet(
        client: _currentClient,
        onSave: (isSessionClosed || _isFollowupMode)
            ? null
            : (ClientModel updatedClient) async {
          if (updatedClient.id.isEmpty) return;
          setState(() => _currentClient = updatedClient);
          if (mounted && !_isFollowupMode && _activeSession == null && updatedClient.id.isNotEmpty) {
            _ensureSessionActive();
          }
        },
      )));
      _initializeStatus();
      return;
    }

    if (_currentClient == null || _currentClient!.id.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Error: Cannot proceed."), backgroundColor: Colors.red));
      return;
    }

    final ClientModel client = _currentClient!;
    final sid = await _ensureSessionActive();

    switch (module.key) {
      case 'vitals':
      // 🎯 FIX: Used 'client' (updated) instead of 'widget.client' (stale)
        await Navigator.push(context, MaterialPageRoute(
            builder: (context) => VitalsHistoryPage(
                clientId: client.id,
                clientName: client.name,
                activeSessionId: isSessionClosed ? null : sid
            )
        ));
        await _fetchLatestVitals();
        await _resumeActiveSession();
        _initializeStatus();
        break;

      case 'history':
        VitalsModel? historyDataToEdit;
        if (_latestVitals != null && _latestVitals!.sessionId == sid) {
          historyDataToEdit = _latestVitals;
        } else if (_isFollowupMode) {
          historyDataToEdit = _latestVitals;
        } else {
          historyDataToEdit = null;
        }

        await Navigator.push(context, MaterialPageRoute<bool>(
            builder: (_) => ClientHistoryManager(
                client: client,
                sessionId: sid,
                latestVitals: historyDataToEdit,
                isReadOnly: isSessionClosed,
                isFollowup: _isFollowupMode,
                onSaveComplete: (isSaved) {}
            )
        ));
        await _fetchLatestVitals();
        await _resumeActiveSession();
        _initializeStatus();
        break;

      case 'clinical':
        VitalsModel? clinicalDataToEdit;
        if (_latestVitals != null && _latestVitals!.sessionId == sid) {
          clinicalDataToEdit = _latestVitals;
        } else {
          clinicalDataToEdit = null;
        }

        await Navigator.push(context, MaterialPageRoute<bool>(
            builder: (_) => ClientClinicalAssessmentSheet(
                sessionId: sid,
                clientId: client.id,
                latestVitals: clinicalDataToEdit,
                isReadOnly: isSessionClosed,
                onSaveAssessment: (data) {}
            )
        ));

        await _fetchLatestVitals();
        await _resumeActiveSession();
        _initializeStatus();
        break;

      case 'plan':
        await Navigator.push(context, MaterialPageRoute(
            builder: (_) => AssignedDietPlanListScreen(
                clientId: client.id,
                clientName: client.name,
                client: client,
                sessionId: sid,
                isReadOnly: isSessionClosed
            )
        ));
        await _resumeActiveSession();
        _initializeStatus();
        break;

      case 'payment':
        await Navigator.push(context, MaterialPageRoute(
            builder: (_) => ClientPackageListScreen(
                client: _currentClient!,
                sessionId: sid,
                isReadOnly: isSessionClosed
            )
        ));
        await _resumeActiveSession();
        _initializeStatus();
        break;
    }
  }

  // ... [Rest of the file remains unchanged] ...
  Future<void> _finalizeConsultation() async {
    bool allRequiredDone = true;
    for (var module in _modules) {
      if (module.requiredForConsult && _moduleStatus[module.key] == ModuleStatus.pending) {
        allRequiredDone = false;
        break;
      }
    }

    if (!allRequiredDone) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please complete all REQUIRED modules before finalizing."), backgroundColor: Colors.red));
      return;
    }

    if (_activeSession != null && _currentClient != null) {
      try {
        final firestore = ref.read(firestoreProvider);
        final batch = firestore.batch();
        final clientRef = firestore.collection('clients').doc(_currentClient!.id);
        batch.update(clientRef, {'status': 'active', 'clientType': 'active', 'lastConsultationDate': FieldValue.serverTimestamp()});
        final sessionRef = firestore.collection('consultation_sessions').doc(_activeSession!.id);
        batch.update(sessionRef, {'status': 'complete', 'endTime': FieldValue.serverTimestamp()});
        await batch.commit();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Consultation Finalized!"), backgroundColor: Colors.green));
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red));
      }
    }
  }

  String _getModuleSubtitle(ConsultationModule module) {
    final isComplete = _moduleStatus[module.key] == ModuleStatus.complete;

    switch (module.key) {
      case 'profile': return isComplete ? "Client profile verified." : "Verify personal details.";
      case 'vitals': return isComplete ? "Vitals recorded for this session." : "Record current body measurements.";
      case 'history': return isComplete ? "History updated." : "Medical history review.";
      case 'payment': return isComplete ? "Subscription active/verified." : "Check payment status.";
      case 'clinical': return isComplete ? "Diagnosis documented." : "Doctor task: Document diagnosis.";
      case 'plan': return isComplete ? "Plan assigned." : "Doctor task: Assign diet plan.";
      default: return "";
    }
  }

  IconData _getStatusIcon(ModuleStatus status) {
    switch (status) { case ModuleStatus.complete: return Icons.check_circle_outline; case ModuleStatus.requiredAttention: return Icons.warning_amber; case ModuleStatus.pending: default: return Icons.radio_button_unchecked; }
  }
  Color _getStatusColor(ModuleStatus status) {
    switch (status) { case ModuleStatus.complete: return Colors.green; case ModuleStatus.requiredAttention: return Colors.orange; case ModuleStatus.pending: default: return Colors.grey.shade500; }
  }

  Widget _buildModuleCard(ConsultationModule module) {
    final status = _moduleStatus[module.key] ?? ModuleStatus.pending;
    final statusColor = _getStatusColor(status);
    return GestureDetector(
      onTap: () => _handleCardTap(module),
      child: Container(
        padding: const EdgeInsets.all(20), margin: const EdgeInsets.only(bottom: 20),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: statusColor.withOpacity(0.1), blurRadius: 15, offset: const Offset(0, 5))], border: Border.all(color: statusColor.withOpacity(0.4), width: 2)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: module.color.withOpacity(0.1), shape: BoxShape.circle), child: Icon(module.icon, color: module.color, size: 24)), const SizedBox(width: 15), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(module.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)), const SizedBox(height: 4), Text(_getModuleSubtitle(module), style: TextStyle(fontSize: 12, color: Colors.grey.shade600), maxLines: 2, overflow: TextOverflow.ellipsis)])), Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey.shade400)]), const SizedBox(height: 15), Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(status.toString().split('.').last.toUpperCase(), style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: statusColor, letterSpacing: 0.5)), Icon(_getStatusIcon(status), color: statusColor, size: 20)])]),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return ClipRRect(child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10), child: Container(padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 10, 20, 16), decoration: BoxDecoration(color: Colors.white.withOpacity(0.9), border: Border(bottom: BorderSide(color: Colors.grey.withOpacity(0.1)))), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [GestureDetector(onTap: () => Navigator.pop(context), child: const Icon(Icons.arrow_back)), const SizedBox(width: 16), Expanded(child: Text("Consultation Checklist", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold))), Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.teal.withOpacity(.1), shape: BoxShape.circle), child: Icon(_consultationType == ConsultationType.initial ? Icons.person_add : Icons.sync, color: Colors.teal))]), const SizedBox(height: 8), Padding(padding: const EdgeInsets.only(left: 40.0), child: Text("Client: ${_currentClient?.name ?? 'New Client'}", style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87))), Padding(padding: const EdgeInsets.only(left: 40.0), child: Text(_consultationType == ConsultationType.initial ? "Initial Consultation" : "Follow-up Consultation", style: TextStyle(fontSize: 12, color: Colors.teal.shade700))),]))));
  }

  @override
  Widget build(BuildContext context) {
    final bool isSessionClosed = _activeSession?.status == 'complete' || _activeSession?.status == 'Closed';

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      body: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                ..._modules.map((module) => _buildModuleCard(module)).toList(),

                if (!isSessionClosed) ...[
                  const SizedBox(height: 40),
                  ElevatedButton(
                    onPressed: _finalizeConsultation,
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, minimumSize: const Size(double.infinity, 55), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                    child: const Text("FINALIZE CONSULTATION", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                ] else ...[
                  const SizedBox(height: 20),
                  Center(child: Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(20)), child: const Text("Session Completed / Read-Only", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)))),
                ],
                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }
}