import 'package:flutter/material.dart';
import 'package:nutricare_client_management/admin/admin_dashboard_Screen.dart';
import 'package:nutricare_client_management/admin/client_package_list_screen.dart';
import 'package:nutricare_client_management/admin/client_personal_info_form.dart';
import 'package:nutricare_client_management/admin/consultation_data_service.dart';
import 'package:nutricare_client_management/modules/client/model/client_diet_plan_model.dart';
import 'package:nutricare_client_management/modules/client/model/client_model.dart';
import 'package:nutricare_client_management/modules/client/model/vitals_model.dart';
import 'package:nutricare_client_management/modules/client/screen/assigned_diet_plan_entry_screen.dart';
import 'package:nutricare_client_management/modules/client/screen/assigned_diet_plan_list.dart';
import 'package:nutricare_client_management/modules/client/screen/master_plan_assignment_page.dart';
import 'package:nutricare_client_management/modules/client/services/client_diet_plan_service.dart';
import 'package:nutricare_client_management/modules/client/services/client_service.dart';
import 'package:nutricare_client_management/modules/client/services/vitals_service.dart';
import 'package:nutricare_client_management/modules/package/model/package_assignment_model.dart';
import 'package:nutricare_client_management/screens/dash/client_dashboard_screenv2.dart';
import 'package:nutricare_client_management/screens/package_assignment_page.dart';
import 'package:nutricare_client_management/screens/package_status_card.dart';
import 'package:nutricare_client_management/screens/payment_ledger_screen.dart';
import 'package:nutricare_client_management/screens/vitals_history_page.dart';
import 'package:nutricare_client_management/admin/custom_gradient_app_bar.dart';
import '../screens/vitals_entry_form_screen.dart';

enum ConsultationStep {
  personalInfo,
  vitals,
  masterPlanAssign,
  mealPlan,
  Booking,
  Profile,
  OnBoard,
}

class ClientConsultationChecklistScreen extends StatefulWidget {
  // 🎯 NEW: Accept an optional existing profile for resuming
  final ClientModel? initialProfile;

  const ClientConsultationChecklistScreen({super.key, this.initialProfile});

  @override
  State<ClientConsultationChecklistScreen> createState() =>
      _ClientConsultationChecklistScreenState();
}

class _ClientConsultationChecklistScreenState
    extends State<ClientConsultationChecklistScreen> {
  ClientModel? _clientProfile;
  List<VitalsModel>? _vitalsModels;
  List<ClientDietPlanModel>? _clientAssignedPlan;
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
      // Load and update completion status for existing client
      _loadExistingConsultationData();
    }
  }

  // 🎯 NEW: Logic to determine the checklist state based on saved data
  Future<void> _loadExistingConsultationData() async {
    // This part requires a service to query Firestore for saved steps
    final dataService =
        ConsultationDataService(); // Assuming this service exists


    _vitalsModels = await VitalsService().getClientVitals(_clientProfile!.id);
    final vitalsCompleted = _vitalsModels?.isNotEmpty ?? false;


    final mealAssignmentCompleted = await dataService
        .checkMealAssignmentCompletion(_clientProfile!.id);

    final dietPlanCompleted = await dataService.checkMealPlanCompletion(
      _clientProfile!.id,
    );
    _clientAssignedPlan = await ClientDietPlanService().fetchAllActivePlans(
      _clientProfile!.id,
    );


    final packageAssigned = await ClientService().checkAssignmentCompleted(_clientProfile!.id);

    setState(() {
      // Step 1 is always complete if an initial profile is passed
      _completionStatus[ConsultationStep.personalInfo] = true;
      _completionStatus[ConsultationStep.vitals] = vitalsCompleted;
      _completionStatus[ConsultationStep.masterPlanAssign] =
          mealAssignmentCompleted;
      _completionStatus[ConsultationStep.mealPlan] = mealAssignmentCompleted;
      // Report preview is ready if meal plan is done
      _completionStatus[ConsultationStep.Booking] = packageAssigned;
    });
  }

  // --- Callbacks to update state ---

  void _onPersonalInfoSaved(ClientModel profile) {
    setState(() {
      _clientProfile = profile;
      _completionStatus[ConsultationStep.personalInfo] = true;
    });
    _showSnackbar('Client Info Saved. Vitals Step Unlocked!', isError: false);
  }

  void _onVitalsSaved() {
    setState(() {
      _completionStatus[ConsultationStep.vitals] = true;
      // Automatically unlock the next step
      _completionStatus[ConsultationStep.mealPlan] = false;
    });
    _showSnackbar('Vitals Saved. Meal Plan Step Unlocked!', isError: false);
  }

  void _onMasterPlanAssigned() {
    setState(() {
      _completionStatus[ConsultationStep.masterPlanAssign] = true;
      _completionStatus[ConsultationStep.mealPlan] = true;
    });
    _showSnackbar(
      'Master Plan Assigned. Meal plan Step Unlocked!',
      isError: false,
    );
  }

  void _onMealPlanSaved() {
    setState(() {
      _completionStatus[ConsultationStep.mealPlan] = true;
      _completionStatus[ConsultationStep.Booking] = true;
    });
    _showSnackbar('Meal Plan Saved. Report Step Unlocked!', isError: false);
  }

  void _showSnackbar(String message, {bool isError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  // --- Navigation & Action Methods ---

  void _navigateToForm(ConsultationStep step) async {
    // ... (form navigation logic, now using updated Vitals and MealPlan forms) ...
    if (_clientProfile == null && step != ConsultationStep.personalInfo) {
      _showSnackbar('Please complete Step 1 first.', isError: true);
      return;
    }

    Widget formWidget;
    String title;

    switch (step) {
      case ConsultationStep.personalInfo:
        formWidget = ClientPersonalInformationForm(
          initialProfile: _clientProfile,
          onProfileSaved: _onPersonalInfoSaved,
        );
        title = '1. Client Personal Information';
        break;
      case ConsultationStep.vitals:
        formWidget = VitalsHistoryPage(
          clientId: _clientProfile!.id,
          clientName: _clientProfile!.name,
          //  vitalsToEdit: _vitalsModels?.first,
          //   isFirstConsultation: true,
          //  onVitalsSaved: _onVitalsSaved,
        );
        title = '2. Lab & Vitals Entry';
        break;
      case ConsultationStep.masterPlanAssign:
        formWidget = MasterPlanSelectionPage(
          client: _clientProfile!,

          onMasterPlanAssigned: _onMasterPlanAssigned,
        );
        title = '3. Master plan Assignment';
        break;
      case ConsultationStep.mealPlan:
        formWidget = AssignedDietPlanListScreen(
          client: _clientProfile!,
          onMealPlanSaved: _onMealPlanSaved,
        );
        title = '4. Meal Planning & Report Generation';
        break;
      case ConsultationStep.Booking:
        // formWidget = _buildPackageStatusSection(_clientProfile!.id);

        formWidget = ClientPackageListScreen(
          client: _clientProfile!,

          // onPackageAssignment: _onPackageAssignment,

          //_onMealPlanSaved: _onMealPlanSaved,
        );
        title = '4. Booking and payments';
        break;
      case ConsultationStep.Profile:
        formWidget = ClientDashboardScreen(
          client: _clientProfile!,
          //_onMealPlanSaved: _onMealPlanSaved,/
        );
        title = '5. profile management';
        break;
      case ConsultationStep.OnBoard:
        // TODO: Handle this case.
        throw UnimplementedError();
    }

    // Navigate to a new screen to present the full-screen form/report
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => Scaffold(
          body: formWidget,
          // SingleChildScrollView(
          // padding: const EdgeInsets.all(16.0),
          //child: formWidget,
          //  ),
        ),
      ),
    );

    // Refresh the UI after returning from the form
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    return  Scaffold(
        appBar: CustomGradientAppBar(
          title: const Text('New Consultation'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const AdminDashboardScreen()),
            ),
          ),
        ),
        body: SafeArea(
          child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            // If resuming, display a clear message
            if (widget.initialProfile != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 20.0),
                child: Text(
                  'RESUMING CONSULTATION for ID: ${widget.initialProfile!.patientId}',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(color: Colors.orange),
                  textAlign: TextAlign.center,
                ),
              ),

            // Step 1 Card: Personal Info
            _buildCardTile(
              step: ConsultationStep.personalInfo,
              title: '1. Capture Personal Data',
              subtitle: _clientProfile == null
                  ? 'Required fields: Name, Age, Mobile, Gender.'
                  : 'Patient ID: ${_clientProfile!.patientId}',
              isActive: true,
              // Always active
              onTap: () => _navigateToForm(ConsultationStep.personalInfo),
            ),

            // Step 2 Card: Vitals (Unlocks if Step 1 is done)
            _buildCardTile(
              step: ConsultationStep.vitals,
              title: '2. Enter Vitals & Lab Reports',
              subtitle: 'Anthropometrics, Labs, Clinical Diagnosis.',
              isActive: _completionStatus[ConsultationStep.personalInfo]!,
              onTap: _completionStatus[ConsultationStep.personalInfo]!
                  ? () => _navigateToForm(ConsultationStep.vitals)
                  : null,
            ),

            // Step 3 Card: Meal Plan (Unlocks if Step 2 is done)
            _buildCardTile(
              step: ConsultationStep.masterPlanAssign,
              title: '3. Assign Master Meal Plan',
              subtitle: 'Generate diet chart based on diagnosis and client data.',
              isActive: _completionStatus[ConsultationStep.vitals]!,
              onTap: _completionStatus[ConsultationStep.vitals]!
                  ? () => _navigateToForm(ConsultationStep.masterPlanAssign)
                  : null,
            ),
            _buildCardTile(
              step: ConsultationStep.mealPlan,
              title: '4. Meal Plan',
              subtitle: 'Manage diet plan based on diagnosis and client data.',
              isActive: _completionStatus[ConsultationStep.masterPlanAssign]!,
              onTap: _completionStatus[ConsultationStep.masterPlanAssign]!
                  ? () => _navigateToForm(ConsultationStep.mealPlan)
                  : null,
            ),

            // Step 4 Card: Report Preview (Unlocks if Step 3 is done)
            _buildCardTile(
              step: ConsultationStep.Booking,
              title: '4.Make booking for Single consultation or package',
              subtitle: 'Manage booking',
              isActive: _completionStatus[ConsultationStep.mealPlan]!,
              onTap: _completionStatus[ConsultationStep.mealPlan]!
                  ? () => _navigateToForm(ConsultationStep.Booking)
                  : null,
              trailing: _buildFinalActionButtons(),
            ),
            _buildCardTile(
              step: ConsultationStep.Profile,
              title: '5. Manage Profile',
              subtitle: 'managing profile, onboard client ,set password',
              isActive: _completionStatus[ConsultationStep.mealPlan]!,
              onTap: _completionStatus[ConsultationStep.mealPlan]!
                  ? () => _navigateToForm(ConsultationStep.Profile)
                  : null,
              trailing: _buildFinalActionButtons(),
            ),

            const SizedBox(height: 30),
            if (_clientProfile != null &&
                !_completionStatus[ConsultationStep.mealPlan]!)
              const Padding(
                padding: EdgeInsets.all(8.0),
                child: Text(
                  'Complete all steps to generate the final report.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // Helper to build the interactive card tiles
  Widget _buildCardTile({
    required ConsultationStep step,
    required String title,
    required String subtitle,
    required bool isActive,
    required VoidCallback? onTap,
    Widget? trailing,
  }) {
    final bool isCompleted = _completionStatus[step]!;
    final Color iconColor = isCompleted
        ? Colors.green
        : (isActive ? Colors.indigo : Colors.grey);

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 15),
      child: ListTile(
        leading: Icon(
          isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
          color: iconColor,
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isActive ? Colors.black87 : Colors.grey,
            decoration: isCompleted ? TextDecoration.lineThrough : null,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              subtitle,
              style: TextStyle(color: isActive ? Colors.black54 : Colors.grey),
            ),
            if (step == ConsultationStep.personalInfo && _clientProfile != null)
              Text(
                'Patient ID: ${_clientProfile!.patientId}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.indigo,
                ),
              ),
          ],
        ),
        trailing: trailing ?? _buildCardActions(step, isActive),
        onTap: isActive
            ? onTap
            : () => _showSnackbar('Please complete the previous step first.'),
      ),
    );
  }

  Widget _buildCardActions(ConsultationStep step, bool isActive) {
    if (!isActive) {
      return const Icon(Icons.lock, color: Colors.grey);
    }

    if (step == ConsultationStep.personalInfo && _completionStatus[step]!) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.indigo),
            onPressed: () => _navigateToForm(ConsultationStep.personalInfo),
          ),
          IconButton(
            icon: const Icon(Icons.delete_forever, color: Colors.red),
            onPressed: () {
              // TODO: Implement soft delete logic for temporary record
              _showSnackbar('Delete action triggered (soft delete pending).');
            },
          ),
        ],
      );
    }
    return const Icon(Icons.arrow_forward_ios, color: Colors.indigo);
  }

  Widget _buildFinalActionButtons() {
    return _completionStatus[ConsultationStep.mealPlan]!
        ? const Icon(Icons.remove_red_eye, color: Colors.green)
        : const Icon(Icons.lock, color: Colors.grey);
  }

  void _onPackageAssignment() {
    setState(() {
      _completionStatus[ConsultationStep.Booking] = true;
      _completionStatus[ConsultationStep.Profile] = true;
    });
    _showSnackbar('Package booked. Payment Step Unlocked!', isError: false);
  }

  // --- Package Status Card Builder (Stream Logic) ---
  Widget _buildPackageStatusSection(String clientId) {
    return StreamBuilder<List<PackageAssignmentModel>>(
      stream: ClientService().streamClientAssignments(clientId),

      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32.0),
              child: CircularProgressIndicator(),
            ),
          );
        }
        if (snapshot.hasError) {
          return Text('Error loading packages: ${snapshot.error}');
        }

        final assignments = snapshot.data ?? [];

        return PackageStatusCard(
          assignments: assignments,
          onAssignTap: () {
            Navigator.of(context)
                .push(
                  MaterialPageRoute(
                    builder: (context) => PackageAssignmentPage(
                      clientId: clientId,
                      clientName: _clientProfile!.name,
                      onPackageAssignment: () {},
                    ),
                  ),
                )
                .then((_) => setState(() {}));
          },

          onEditTap: (assignment) {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => PaymentLedgerScreen(
                  assignment: assignment,
                  clientName: _clientProfile!.name,
                  initialCollectedAmount:
                      0.0, // Placeholder - needs actual service call
                ),
              ),
            );
          },

          onDeleteTap: (assignment) {
            // TODO: Implement delete confirmation and call service method
          },
        );
      },
    );
  }
}
