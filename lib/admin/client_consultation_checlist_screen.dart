import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nutricare_client_management/admin/admin_profile_model.dart';
import 'package:nutricare_client_management/admin/admin_provider.dart';
import 'package:nutricare_client_management/admin/client_history_manager.dart';
import 'package:nutricare_client_management/admin/client_package_list_screen.dart';
import 'package:nutricare_client_management/admin/configuration/app_module_config.dart';
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
import 'package:nutricare_client_management/modules/client/services/vitals_service.dart';
import 'package:nutricare_client_management/admin/labvital/global_service_provider.dart';
import 'package:nutricare_client_management/modules/package/service/package_payment_service.dart';

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
  ConsultationType _consultationType = ConsultationType.initial;
  ClientModel? _currentClient;
  VitalsModel? _latestVitals;

  // Financial State
  double _pendingDues = 0.0;
  bool _isLoadingFinance = true;

  @override
  void initState() {
    super.initState();
    _currentClient = widget.client;
    _latestVitals = widget.latestVitals;
    _isFollowupMode = widget.isFollowup;
    _consultationType = _isFollowupMode ? ConsultationType.followup : ConsultationType.initial;

    _resumeActiveSession().then((_) => _refreshStatusAndSync());
    _checkFinancialStatus();

    if (_currentClient != null && _currentClient!.id.isNotEmpty && _latestVitals == null) {
      _fetchLatestVitals();
    }
  }

  Future<void> _checkFinancialStatus() async {
    if (_currentClient == null) return;
    try {
      //final dues = await ref.read(packagePaymentServiceProvider).getClientPendingAmount(_currentClient!.id);
      if (mounted) {
        setState(() {
          _pendingDues = 10;
          _isLoadingFinance = false;
        });
        _refreshStatusAndSync();
      }
    } catch (e) {
      debugPrint("Error checking finance: $e");
    }
  }

  // ===========================================================================
  // 🎯 1. STATUS SYNC ENGINE (UPDATED)
  // ===========================================================================

  void _refreshStatusAndSync() {
    // 1. Calculate Status Locally
    // We check if data exists LOCALLY or in the Session Record
    // (We default to session.steps for things we don't track locally like Clinical/Rx)

    final bool isRxStepDone = _activeSession?.steps['prescription'] == true;
    final bool isPlanStepDone = _activeSession?.steps['plan'] == true;
    final bool isVitalsComplete = _latestVitals != null && _latestVitals!.date.difference(DateTime.now()).inHours.abs() < 24; // Simple check: Vitals taken today?
    // OR fallback to what the session says if we haven't fetched vitals
    final bool isVitalsEffective = isVitalsComplete || (_activeSession?.steps['vitals'] == true);

    final bool isHistoryComplete = _activeSession?.steps['history'] == true;
    final bool isClinicalComplete = _activeSession?.steps['clinical'] == true;

    // Profile is valid if name/mobile exist
    final bool isProfileComplete = _isFollowupMode ? true : (_currentClient != null && _currentClient!.name.isNotEmpty && _currentClient!.mobile.isNotEmpty);

    // Payment Logic
    final bool isSubscriptionStepDone = _activeSession?.steps['subscription'] == true;
    final bool isPaymentComplete = (isSubscriptionStepDone || (widget.activePackage != null && widget.activePackage!.id.isNotEmpty)) && _pendingDues <= 0;

    // 2. Update UI State
    final newStatus = {
      'profile': isProfileComplete ? ModuleStatus.complete : ModuleStatus.pending,
      'vitals': isVitalsEffective ? ModuleStatus.complete : ModuleStatus.pending,
      'history': isHistoryComplete ? ModuleStatus.complete : ModuleStatus.pending,
      'clinical': isClinicalComplete ? ModuleStatus.complete : ModuleStatus.pending,
      'prescription': isRxStepDone ? ModuleStatus.complete : ModuleStatus.pending,
      'plan': isPlanStepDone ? ModuleStatus.complete : ModuleStatus.pending,
      'payment': isPaymentComplete
          ? ModuleStatus.complete
          : (_pendingDues > 0 ? ModuleStatus.requiredAttention : ModuleStatus.pending),
    };

    if (mounted) {
      setState(() => _moduleStatus = newStatus);
    }

    // 🎯 3. SYNC TO FIRESTORE (The Fix)
    if (_activeSession != null) {
      _syncStepsToFirestore(newStatus);
    }
  }

  Future<void> _syncStepsToFirestore(Map<String, ModuleStatus> statusMap) async {
    if (_activeSession == null) return;

    // Convert UI Status to Database Boolean
    final Map<String, bool> dbSteps = {
      'profile': statusMap['profile'] == ModuleStatus.complete,
      'vitals': statusMap['vitals'] == ModuleStatus.complete,
      'history': statusMap['history'] == ModuleStatus.complete,
      'clinical': statusMap['clinical'] == ModuleStatus.complete,
      'prescription': statusMap['prescription'] == ModuleStatus.complete,
      'plan': statusMap['plan'] == ModuleStatus.complete,
      'payment': statusMap['payment'] == ModuleStatus.complete,
    };

    // Update Firestore without triggering a full rebuild loop
    try {
      await ref.read(firestoreProvider)
          .collection('consultation_sessions')
          .doc(_activeSession!.id)
          .update({'steps': dbSteps});
    } catch (e) {
      debugPrint("Failed to sync steps: $e");
    }
  }

  // ===========================================================================
  // 🎯 2. SESSION LOGIC
  // ===========================================================================

// ... [Existing Imports and Class Declaration]

  // ===========================================================================
  // 🎯 2. SESSION LOGIC (FIXED)
  // ===========================================================================

  Future<void> _resumeActiveSession() async {
    if (_currentClient != null && _currentClient!.id.isNotEmpty) {
      final sessionService = ref.read(consultationServiceProvider);
      ConsultationSessionModel? session;

      if (widget.forceNew) {
        // "Force New" usually implies we WANT a new session.
        // But if there's an 'Ongoing' one, we might need to hijack it.
        session = await sessionService.getActiveSession(_currentClient!.id);

        // 🎯 HIJACK & FIX LOGIC (Moved Here)
        if (session != null && widget.isFollowup) {
          // If we found an ongoing session but we are starting a Follow-up...
          // Check if it's missing the parent link (i.e., it was a stale Initial)
          if (session.parentId != widget.parentSessionId) {
            debugPrint("⚠️ Found stale session ${session.id} during resume. Fixing links...");

            await sessionService.updateSessionLinks(
                session.id,
                parentId: widget.parentSessionId,
                consultationType: 'Followup'
            );

            // Reload the fixed session
            session = await sessionService.getSessionById(session.id);
          }
        } else if (session == null) {
          // No active session found, and we are forcing new?
          // We can either start it now or wait for _ensureSessionActive.
          // Let's leave it null so _ensureSessionActive starts it when needed.
        }

      } else if (widget.viewSessionId != null) {
        try { session = await sessionService.getSessionById(widget.viewSessionId!); } catch (e) { debugPrint("Error: $e"); }
      } else {
        session = await sessionService.getActiveSession(_currentClient!.id);
      }

      if (session != null && mounted) {
        setState(() {
          _isFollowupMode = session!.consultationType == 'Followup';
          _consultationType = _isFollowupMode ? ConsultationType.followup : ConsultationType.initial;
          _activeSession = session;
        });
      } else if (mounted) {
        // Fallback if no session exists yet (UI setup only)
        setState(() {
          _isFollowupMode = widget.isFollowup;
          _consultationType = _isFollowupMode ? ConsultationType.followup : ConsultationType.initial;
        });
      }
    }
  }

  Future<String?> _ensureSessionActive() async {
    // 1. If we already have a session (loaded by resume), return it.
    // Since _resumeActiveSession now handles the "Fix", this is safe.
    if (_activeSession != null) return _activeSession!.id;

    if (_currentClient == null) return null;
    final uid = ref.read(authServiceProvider).currentUser?.uid;
    if (uid == null) return null;

    final sessionService = ref.read(consultationServiceProvider);

    // 2. Double-check DB (in case resume failed or didn't run)
    var session = await sessionService.getActiveSession(_currentClient!.id);

    // 3. Late-Check Fix (Safety Net)
    if (session != null && widget.forceNew && widget.isFollowup) {
      if (session.parentId != widget.parentSessionId) {
        await sessionService.updateSessionLinks(
            session.id,
            parentId: widget.parentSessionId,
            consultationType: 'Followup'
        );
        session = await sessionService.getSessionById(session.id);
      }
    }

    // 4. Create New if absolutely nothing found
    if (session == null) {
      final sid = await sessionService.startSession(
          _currentClient!.id,
          uid,
          isFollowup: _isFollowupMode,
          parentId: widget.parentSessionId
      );
      session = await sessionService.getSessionById(sid);
    }

    if (mounted) setState(() => _activeSession = session);
    return session?.id;
  }

  Future<void> _fetchLatestVitals() async {
    if (_currentClient == null || !mounted) return;
    try {
      final v = await ref.read(vitalsServiceProvider).getLatestVitals(_currentClient!.id);
      if (v != null && mounted) setState(() => _latestVitals = v);
    } catch (_) {}
  }


  void _handleCardTap(ConsultationModule module) async {
    final bool isSessionClosed = _activeSession?.status == 'complete' || _activeSession?.status == 'Closed';

    // ... [Same navigation logic as previous version] ...
    // Note: I am simplifying the copy-paste here, but ensure the logic inside switch(module.key) matches your existing file.
    // The KEY CHANGE is calling _refreshStatusAndSync() at the end.

    if (module.key == 'profile') {
      await Navigator.push(context, MaterialPageRoute(builder: (_) => ClientPersonalInfoSheet(
        client: _currentClient,
        onSave: (isSessionClosed || _isFollowupMode) ? null : (ClientModel updatedClient) async {
          if (updatedClient.id.isEmpty) return;
          setState(() => _currentClient = updatedClient);
          if (mounted && !_isFollowupMode && _activeSession == null && updatedClient.id.isNotEmpty) {
            _ensureSessionActive();
          }
        },
      )));
      _refreshStatusAndSync(); // 🎯 Sync after return
      return;
    }

    if (_currentClient == null) return;
    final sid = await _ensureSessionActive();
    if (sid == null) return;
    final ClientModel client = _currentClient!;

    switch (module.key) {
      case 'vitals':
        await Navigator.push(context, MaterialPageRoute(builder: (_) => VitalsHistoryPage(clientId: client.id, clientName: client.name, activeSessionId: isSessionClosed ? null : sid)));
        await _fetchLatestVitals();
        // 🎯 For Vitals, we assume if you visited the page and data exists, it's done.
        // We can force mark the session step true here if needed:
        if (_activeSession != null) {
          // You might want to explicitly update local session object's step here to avoid waiting for fetch
          _activeSession!.steps['vitals'] = true;
        }
        break;

      case 'history':
        await Navigator.push(context, MaterialPageRoute(builder: (_) => ClientHistoryManager(client: client, sessionId: sid, latestVitals: _latestVitals, isReadOnly: isSessionClosed, isFollowup: _isFollowupMode, onSaveComplete: (_){})));
        if (_activeSession != null) _activeSession!.steps['history'] = true;
        break;

      case 'clinical':
        await Navigator.push(context, MaterialPageRoute(builder: (_) => ClientClinicalAssessmentSheet(sessionId: sid, client: client, latestVitals: _latestVitals, isReadOnly: isSessionClosed, onSaveAssessment: (_){})));
        if (_activeSession != null) _activeSession!.steps['clinical'] = true;
        break;

      case 'plan':
        await Navigator.push(context, MaterialPageRoute(builder: (_) => AssignedDietPlanListScreen(clientId: client.id, clientName: client.name, client: client, sessionId: sid, isReadOnly: isSessionClosed)));
        if (_activeSession != null) _activeSession!.steps['plan'] = true;
        break;

      case 'payment':
        await Navigator.push(context, MaterialPageRoute(builder: (_) => ClientPackageListScreen(client: client, sessionId: sid, isReadOnly: isSessionClosed)));
        await _checkFinancialStatus();
        if (_activeSession != null) _activeSession!.steps['payment'] = true;
        break;
    }

    await _resumeActiveSession(); // Reload session to get any backend changes
    _refreshStatusAndSync(); // 🎯 Triggers the DB Update for the Live Board
  }

  Future<void> _finalizeConsultation(List<ConsultationModule> activeModules) async {
    bool allDone = true;
    for (var m in activeModules) {
      if (m.requiredForConsult && _moduleStatus[m.key] == ModuleStatus.pending) {
        allDone = false;
        break;
      }
    }

    if (!allDone) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Complete required modules first!"), backgroundColor: Colors.red));
      return;
    }

    if (_activeSession != null) {
      final batch = ref.read(firestoreProvider).batch();
      batch.update(ref.read(firestoreProvider).collection('clients').doc(_currentClient!.id), {'status': 'active', 'lastConsultationDate': FieldValue.serverTimestamp()});

      // Ensure all steps are marked true on completion
      final finalSteps = _activeSession!.steps;
      finalSteps.updateAll((key, value) => true);

      batch.update(ref.read(firestoreProvider).collection('consultation_sessions').doc(_activeSession!.id), {
        'status': 'complete',
        'endTime': FieldValue.serverTimestamp(),
        'steps': finalSteps
      });

      await batch.commit();
      if (mounted) Navigator.pop(context);
    }
  }

  List<ConsultationModule> _buildModulesForUser(AdminProfileModel user) {
    List<ConsultationModule> modules = [
      ConsultationModule(key: 'profile', title: "1. Personal & Contact Info", icon: Icons.person_pin, color: Colors.indigo, requiredForConsult: false),
      ConsultationModule(key: 'vitals', title: "2. Body Vitals & Measurements", icon: Icons.monitor_heart, color: Colors.deepOrange, requiredForConsult: true),
      ConsultationModule(key: 'history', title: "3. Medical & Lifestyle History", icon: Icons.library_books, color: Colors.teal, requiredForConsult: false),
      ConsultationModule(key: 'clinical', title: "4. Clinical Assessment & Diagnosis", icon: Icons.local_hospital, color: Colors.redAccent, requiredForConsult: true),
    ];
    if (user.hasAccess(AppModule.dietPlanning.id)) {
      bool isRequired = !user.hasAccess(AppModule.prescription.id);
      modules.add(ConsultationModule(key: 'plan', title: user.hasAccess(AppModule.prescription.id) ? "6. Diet Plan (Optional)" : "5. Diet Plan Assignment", icon: AppModule.dietPlanning.icon, color: Colors.green, requiredForConsult: isRequired));
    }
    if (user.hasAccess(AppModule.billing.id) || user.role == AdminRole.clinicAdmin) {
      modules.add(ConsultationModule(key: 'payment', title: "Payment & Package", icon: AppModule.billing.icon, color: Colors.grey, requiredForConsult: true));
    }
    return modules;
  }

  // UI Build Method
  @override
  Widget build(BuildContext context) {
    final adminAsync = ref.watch(currentAdminProvider);

    return adminAsync.when(
      loading: () => const Scaffold(backgroundColor: Color(0xFFF8F9FE), body: Center(child: CircularProgressIndicator())),
      error: (e, s) => Scaffold(body: Center(child: Text("Error: $e"))),
      data: (admin) {
        if (admin == null) return const Scaffold(body: Center(child: Text("Access Denied")));

        final modules = _buildModulesForUser(admin);
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
                    ...modules.map((m) => _buildModuleCard(m)).toList(),
                    if (!isSessionClosed) ...[
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () => _finalizeConsultation(modules),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, minimumSize: const Size(double.infinity, 55), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                        child: const Text("FINALIZE CONSULTATION", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                      ),
                    ] else ...[
                      const SizedBox(height: 20),
                      Center(child: Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(20)), child: const Text("Session Completed", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)))),
                    ],
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildModuleCard(ConsultationModule module) {
    final status = _moduleStatus[module.key] ?? ModuleStatus.pending;
    final isComplete = status == ModuleStatus.complete;
    final isAttention = status == ModuleStatus.requiredAttention;
    final Color borderColor = isAttention ? Colors.orange : (isComplete ? Colors.green : module.color);
    final Color iconColor = isAttention ? Colors.orange : (isComplete ? Colors.green : Colors.grey.shade400);
    final IconData statusIcon = isAttention ? Icons.warning_amber_rounded : (isComplete ? Icons.check_circle : Icons.circle_outlined);

    return GestureDetector(
      onTap: () => _handleCardTap(module),
      child: Container(
        padding: const EdgeInsets.all(20), margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: borderColor.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4))], border: Border.all(color: borderColor.withOpacity(0.3), width: 1.5)),
        child: Row(children: [
          Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: module.color.withOpacity(0.1), shape: BoxShape.circle), child: Icon(module.icon, color: module.color, size: 24)),
          const SizedBox(width: 15),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(module.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(isAttention ? "Payment Pending" : (isComplete ? "Completed" : (module.requiredForConsult ? "Required" : "Optional")), style: TextStyle(fontSize: 12, color: isAttention ? Colors.orange : (isComplete ? Colors.green : Colors.grey.shade600), fontWeight: isAttention ? FontWeight.bold : FontWeight.normal))
          ])),
          Icon(statusIcon, color: iconColor, size: 28)
        ]),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return ClipRRect(child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10), child: Container(padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 10, 20, 16), decoration: BoxDecoration(color: Colors.white.withOpacity(0.9), border: Border(bottom: BorderSide(color: Colors.grey.withOpacity(0.1)))), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [GestureDetector(onTap: () => Navigator.pop(context), child: const Icon(Icons.arrow_back)), const SizedBox(width: 16), Expanded(child: Text(_isFollowupMode ? "Follow-up Visit" : "Initial Consultation", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)))]), const SizedBox(height: 12), Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(12)), child: Row(children: [CircleAvatar(radius: 20, backgroundImage: NetworkImage(_currentClient?.photoUrl ?? ''), child: _currentClient?.photoUrl == null ? Text(_currentClient?.name[0] ?? 'C') : null), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(_currentClient?.name ?? 'New Client', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)), Text("Wt: ${_latestVitals?.weightKg ?? '-'} kg", style: const TextStyle(fontSize: 12))]))]))]))));
  }
}