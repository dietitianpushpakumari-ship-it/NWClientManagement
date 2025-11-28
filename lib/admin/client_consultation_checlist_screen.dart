import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:nutricare_client_management/admin/admin_dashboard_Screen.dart';
import 'package:nutricare_client_management/admin/client_package_list_screen.dart';
import 'package:nutricare_client_management/admin/client_personal_info_form.dart';
import 'package:nutricare_client_management/admin/consultation_data_service.dart';
// AdminGoalSettingScreen import removed
import 'package:nutricare_client_management/modules/client/model/client_diet_plan_model.dart';
import 'package:nutricare_client_management/modules/client/model/client_model.dart';
import 'package:nutricare_client_management/modules/client/model/vitals_model.dart';
import 'package:nutricare_client_management/modules/client/screen/assigned_diet_plan_list.dart';
import 'package:nutricare_client_management/modules/client/screen/master_plan_assignment_page.dart';
import 'package:nutricare_client_management/modules/client/services/client_diet_plan_service.dart';
import 'package:nutricare_client_management/modules/client/services/client_service.dart';
import 'package:nutricare_client_management/modules/client/services/vitals_service.dart';
import 'package:nutricare_client_management/screens/dash/client_dashboard_screenv2.dart';
import 'package:nutricare_client_management/screens/vitals_history_page.dart';

enum ConsultationStep {
  personalInfo,
  vitals,
  masterPlanAssign,
  mealPlan,
  // habitAssignment removed
  Booking,
  Profile,
}

class ClientConsultationChecklistScreen extends StatefulWidget {
  final ClientModel? initialProfile;

  const ClientConsultationChecklistScreen({super.key, this.initialProfile});

  @override
  State<ClientConsultationChecklistScreen> createState() =>
      _ClientConsultationChecklistScreenState();
}

class _ClientConsultationChecklistScreenState extends State<ClientConsultationChecklistScreen> {
  ClientModel? _clientProfile;
  bool _isLoading = true;

  Map<ConsultationStep, bool> _completionStatus = {
    ConsultationStep.personalInfo: false,
    ConsultationStep.vitals: false,
    ConsultationStep.masterPlanAssign: false,
    ConsultationStep.mealPlan: false,
    ConsultationStep.Booking: false,
    ConsultationStep.Profile: false,
  };

  @override
  void initState() {
    super.initState();
    if (widget.initialProfile != null) {
      _clientProfile = widget.initialProfile;
      _loadExistingConsultationData();
    } else {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadExistingConsultationData() async {
    if (_clientProfile == null) return;
    setState(() => _isLoading = true);

    try {
      final dataService = ConsultationDataService();
      final vitals = await VitalsService().getClientVitals(_clientProfile!.id);
      final mealAssignmentCompleted = await dataService.checkMealAssignmentCompletion(_clientProfile!.id);
      final packageAssigned = await ClientService().checkAssignmentCompleted(_clientProfile!.id);

      if (mounted) {
        setState(() {
          _completionStatus[ConsultationStep.personalInfo] = true;
          _completionStatus[ConsultationStep.vitals] = vitals.isNotEmpty;
          _completionStatus[ConsultationStep.masterPlanAssign] = mealAssignmentCompleted;
          _completionStatus[ConsultationStep.mealPlan] = mealAssignmentCompleted;
          _completionStatus[ConsultationStep.Booking] = packageAssigned;
          _completionStatus[ConsultationStep.Profile] = packageAssigned;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _navigateToForm(ConsultationStep step) async {
    if (_clientProfile == null && step != ConsultationStep.personalInfo) {
      _showSnackbar('Complete Step 1 first.', isError: true);
      return;
    }

    Widget? formWidget;
    switch (step) {
      case ConsultationStep.personalInfo:
        formWidget = ClientPersonalInformationForm(
          initialProfile: _clientProfile,
          onProfileSaved: (profile) {
            setState(() => _clientProfile = profile);
            _loadExistingConsultationData();
          },
        );
        break;
      case ConsultationStep.vitals:
        formWidget = VitalsHistoryPage(clientId: _clientProfile!.id, clientName: _clientProfile!.name);
        break;
      case ConsultationStep.masterPlanAssign:
        formWidget = MasterPlanSelectionPage(client: _clientProfile!, onMasterPlanAssigned: () => _loadExistingConsultationData());
        break;
      case ConsultationStep.mealPlan:
        formWidget = AssignedDietPlanListScreen(client: _clientProfile!, onMealPlanSaved: () => _loadExistingConsultationData());
        break;
      case ConsultationStep.Booking:
        formWidget = ClientPackageListScreen(client: _clientProfile!);
        break;
      case ConsultationStep.Profile:
        formWidget = ClientDashboardScreen(client: _clientProfile!);
        break;
    }

    if (formWidget != null) {
      await Navigator.of(context).push(MaterialPageRoute(builder: (_) => formWidget!));
      _loadExistingConsultationData();
    }
  }

  void _showSnackbar(String message, {bool isError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: isError ? Colors.red : Colors.green,
      behavior: SnackBarBehavior.floating,
    ));
  }

  @override
  Widget build(BuildContext context) {
    int completedSteps = _completionStatus.values.where((v) => v).length;
    double progress = _completionStatus.isEmpty ? 0 : completedSteps / _completionStatus.length;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      body: Stack(
        children: [
          Positioned(top: -100, right: -80, child: Container(width: 300, height: 300, decoration: BoxDecoration(shape: BoxShape.circle, boxShadow: [BoxShadow(color: Theme.of(context).colorScheme.primary.withOpacity(0.1), blurRadius: 80, spreadRadius: 30)]))),

          SafeArea(
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const AdminDashboardScreen())),
                        child: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]), child: const Icon(Icons.arrow_back, size: 20, color: Colors.black87)),
                      ),
                      const SizedBox(width: 16),
                      const Text("Consultation", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1A1A1A))),
                    ],
                  ),
                ),

                // Progress
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                  child: Column(
                    children: [
                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                        Text("Consultation Progress", style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.bold, fontSize: 12)),
                        Text("${(progress * 100).toInt()}%", style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold, fontSize: 12)),
                      ]),
                      const SizedBox(height: 8),
                      ClipRRect(borderRadius: BorderRadius.circular(4), child: LinearProgressIndicator(value: progress, minHeight: 6, backgroundColor: Colors.grey.shade200, color: Theme.of(context).colorScheme.primary)),
                    ],
                  ),
                ),

                // Steps
                Expanded(
                  child: _isLoading ? const Center(child: CircularProgressIndicator()) : ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      if (_clientProfile != null)
                        Center(child: Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), margin: const EdgeInsets.only(bottom: 20), decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.orange.shade100)), child: Text('Patient ID: ${_clientProfile!.patientId ?? "Pending"}', style: TextStyle(color: Colors.orange.shade800, fontWeight: FontWeight.bold, fontSize: 12)))),

                      _buildStepTile(ConsultationStep.personalInfo, "1", "Personal Data", "Name, Age, Mobile"),
                      _buildStepTile(ConsultationStep.vitals, "2", "Vitals & Labs", "Weight, BP, Reports"),
                      _buildStepTile(ConsultationStep.masterPlanAssign, "3", "Assign Plan", "Select Template"),
                      _buildStepTile(ConsultationStep.mealPlan, "4", "Customize & Goals", "Diet, Habits, Water"),
                      _buildStepTile(ConsultationStep.Booking, "5", "Booking", "Packages & Payments"),
                      _buildStepTile(ConsultationStep.Profile, "6", "Dashboard", "Client View Preview", isLast: true),

                      const SizedBox(height: 50),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepTile(ConsultationStep step, String number, String title, String subtitle, {bool isLast = false}) {
    final bool isCompleted = _completionStatus[step] ?? false;
    bool isLocked = false;
    if (step != ConsultationStep.personalInfo) {
      final index = ConsultationStep.values.indexOf(step);
      final prevStep = ConsultationStep.values[index - 1];
      if (!(_completionStatus[prevStep] ?? false)) isLocked = true;
    }

    return GestureDetector(
      onTap: isLocked ? () => _showSnackbar("Complete previous step first.", isError: true) : () => _navigateToForm(step),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))], border: Border.all(color: isCompleted ? Colors.green.withOpacity(0.3) : Colors.transparent)),
        child: Row(
          children: [
            Container(width: 40, height: 40, decoration: BoxDecoration(color: isCompleted ? Colors.green : (isLocked ? Colors.grey.shade200 : Theme.of(context).colorScheme.primary), shape: BoxShape.circle), child: Center(child: isCompleted ? const Icon(Icons.check, color: Colors.white, size: 20) : Text(number, style: TextStyle(color: isLocked ? Colors.grey : Colors.white, fontWeight: FontWeight.bold, fontSize: 16)))),
            const SizedBox(width: 16),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isLocked ? Colors.grey : Colors.black87)), Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.grey))])),
            Icon(isLocked ? Icons.lock : Icons.arrow_forward_ios, size: 16, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }
}