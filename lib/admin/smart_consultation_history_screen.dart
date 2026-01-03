import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:nutricare_client_management/admin/clinical_prescription_printer.dart'; // 🎯 Added Printer Import
import 'package:nutricare_client_management/admin/consultation_session_model.dart';
import 'package:nutricare_client_management/admin/consultation_session_service.dart';
import 'package:nutricare_client_management/admin/database_provider.dart';
import 'package:nutricare_client_management/admin/diet_plan_comparasion_screen.dart';
import 'package:nutricare_client_management/admin/labvital/global_service_provider.dart';
import 'package:nutricare_client_management/admin/labvital/vitals_comprasion_screen.dart';
import 'package:nutricare_client_management/admin/plan_report_view_screen.dart';
import 'package:nutricare_client_management/modules/client/model/client_diet_plan_model.dart';
import 'package:nutricare_client_management/modules/client/model/client_model.dart';
import 'package:nutricare_client_management/modules/client/model/vitals_model.dart';
import 'package:nutricare_client_management/modules/medical/models/prescription_model.dart';

class SmartConsultationHistoryScreen extends ConsumerStatefulWidget {
  final ClientModel client;
  final String? currentSessionId;

  const SmartConsultationHistoryScreen({
    super.key,
    required this.client,
    this.currentSessionId,
  });

  @override
  ConsumerState<SmartConsultationHistoryScreen> createState() => _SmartConsultationHistoryScreenState();
}

class _SmartConsultationHistoryScreenState extends ConsumerState<SmartConsultationHistoryScreen> {
  final Map<String, VitalsModel?> _vitalsCache = {};
  final Map<String, ClientDietPlanModel?> _dietCache = {};

  Stream<List<ConsultationSessionModel>>? _historyStream;
  String? _expandedSessionId;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _initStream();
  }

  void _initStream() {
    _historyStream = ref.read(consultationServiceProvider).streamSessionHistory(widget.client.id);
  }

  @override
  Widget build(BuildContext context) {
    if (_historyStream == null) _initStream();

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FC),
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            sliver: StreamBuilder<List<ConsultationSessionModel>>(
              stream: _historyStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SliverFillRemaining(child: Center(child: CircularProgressIndicator()));
                }

                final sessions = snapshot.data ?? [];
                if (sessions.isEmpty) {
                  return const SliverFillRemaining(child: Center(child: Text("No history available", style: TextStyle(color: Colors.grey))));
                }

                final pastSessions = sessions
                    .where((s) => widget.currentSessionId == null || s.id != widget.currentSessionId)
                    .sorted((a, b) => b.sessionDate.compareTo(a.sessionDate))
                    .toList();

                return SliverList(
                  delegate: SliverChildBuilderDelegate(
                        (context, index) {
                      final session = pastSessions[index];
                      final isLast = index == pastSessions.length - 1;
                      return _buildTimelineItem(session, isLast);
                    },
                    childCount: pastSessions.length,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 100,
      pinned: true,
      backgroundColor: Colors.white,
      foregroundColor: Colors.black87,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.only(left: 50, bottom: 16),
        title: Text(
          "Consultation Timeline",
          style: TextStyle(
            color: Colors.blueGrey.shade900,
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
      ),
    );
  }

  Widget _buildTimelineItem(ConsultationSessionModel session, bool isLast) {
    final bool isExpanded = _expandedSessionId == session.id;
    final date = session.sessionDate.toDate();

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 50,
            child: Column(
              children: [
                _buildDateBadge(date),
                Expanded(
                  child: isLast ? const SizedBox() : Container(
                    width: 2,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.indigo.withOpacity(0.2), Colors.transparent],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: _buildSessionCard(session, isExpanded),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateBadge(DateTime date) {
    return Column(
      children: [
        Text(DateFormat('MMM').format(date).toUpperCase(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
        Container(
          margin: const EdgeInsets.only(top: 4),
          width: 36, height: 36,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.indigo.shade100, width: 2),
            boxShadow: [BoxShadow(color: Colors.indigo.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, 4))],
          ),
          alignment: Alignment.center,
          child: Text(
            DateFormat('dd').format(date),
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.indigo),
          ),
        ),
        Text(DateFormat('yyyy').format(date), style: const TextStyle(fontSize: 9, color: Colors.grey)),
      ],
    );
  }

  Widget _buildSessionCard(ConsultationSessionModel session, bool isExpanded) {
    final isFollowup = session.consultationType == 'Followup';
    final typeColor = isFollowup ? Colors.purple : Colors.teal;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.blueGrey.withOpacity(isExpanded ? 0.15 : 0.05),
            blurRadius: isExpanded ? 20 : 10,
            offset: const Offset(0, 5),
          ),
        ],
        border: Border.all(color: isExpanded ? typeColor.withOpacity(0.3) : Colors.transparent),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () {
              setState(() {
                _expandedSessionId = isExpanded ? null : session.id;
              });
              if (!isExpanded) _fetchSessionDetails(session);
            },
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: typeColor.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                    child: Icon(isFollowup ? Icons.cached_rounded : Icons.medical_services_rounded, color: typeColor, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isFollowup ? "Follow-up Visit" : "Initial Consultation",
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black87),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          DateFormat('hh:mm a').format(session.sessionDate.toDate()),
                          style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                    color: Colors.grey.shade400,
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: _buildDetailContent(session),
            crossFadeState: isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 300),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailContent(ConsultationSessionModel session) {
    if (!_vitalsCache.containsKey(session.id)) {
      return const Padding(
        padding: EdgeInsets.all(30),
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }

    final vitals = _vitalsCache[session.id];
    final diet = _dietCache[session.id];
    final hasActions = widget.currentSessionId != null;

    if (vitals == null && diet == null) {
      return Padding(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.content_paste_off, color: Colors.grey.shade300, size: 40),
              const SizedBox(height: 8),
              Text("No data recorded for this session", style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
            ],
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAFA),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
        border: Border(top: BorderSide(color: Colors.grey.shade100)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (vitals != null) _buildPremiumVitalsBar(vitals),
          const SizedBox(height: 20),

          // --- RX SECTION ---
          if (vitals != null)
            _buildPremiumSection(
              title: "PRESCRIPTION",
              icon: Icons.medication_rounded,
              color: Colors.blue,
              // 🎯 ACTION BUTTONS
              actions: [
                _buildActionChip("Print Rx", Icons.print, Colors.indigo, () => _printPrescription(vitals)),
                if (hasActions) _buildActionChip("Clone", Icons.copy_all, Colors.blue, () => _cloneRx(vitals)),
              ],
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (vitals.nutritionDiagnoses != null && vitals.nutritionDiagnoses!.isNotEmpty)
                    Padding(padding: const EdgeInsets.only(bottom: 8), child: _buildTags("Dx", vitals.nutritionDiagnoses!.keys.toList(), Colors.redAccent)),

                  if (vitals.medications.isNotEmpty)
                    ...vitals.medications.map((m) => _buildMedicationTile(m)),

                  if (vitals.medications.isEmpty && (vitals.nutritionDiagnoses == null || vitals.nutritionDiagnoses!.isEmpty))
                    const Text("No prescriptions or diagnosis recorded.", style: TextStyle(color: Colors.grey, fontSize: 12, fontStyle: FontStyle.italic)),
                ],
              ),
            ),

          // --- DIET SECTION ---
          if (diet != null)
            _buildPremiumSection(
              title: "DIET PLAN",
              icon: Icons.restaurant_menu_rounded,
              color: Colors.green,
              // 🎯 ACTION BUTTONS
              actions: [
                _buildActionChip("Report", Icons.picture_as_pdf, Colors.orange, () => _viewDietReport(diet, vitals)),
                _buildActionChip("Compare", Icons.compare_arrows, Colors.indigo, () => _compareDiet(diet)),
                if (hasActions) _buildActionChip("Clone", Icons.copy_all, Colors.green, () => _cloneDiet(diet)),
              ],
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green.withOpacity(0.2)),
                  boxShadow: [BoxShadow(color: Colors.green.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: Colors.green.shade50, shape: BoxShape.circle),
                      child: const Icon(Icons.description, size: 18, color: Colors.green),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(diet.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          Text("${diet.targetCalories?.toInt() ?? 0} kcal • ${diet.dietType ?? 'Standard'}", style: TextStyle(color: Colors.grey.shade600, fontSize: 11)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  // --- PREMIUM WIDGETS ---

  Widget _buildPremiumSection({
    required String title,
    required IconData icon,
    required Color color,
    List<Widget>? actions,
    required Widget child
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(icon, size: 14, color: color),
                  const SizedBox(width: 6),
                  Text(title, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: color, letterSpacing: 0.8)),
                ],
              ),
              if (actions != null) Row(children: actions.map((a) => Padding(padding: const EdgeInsets.only(left: 8), child: a)).toList()),
            ],
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }

  Widget _buildActionChip(String label, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: _isProcessing ? null : onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
        child: Row(
          children: [
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 4),
            Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
      ),
    );
  }

  Widget _buildPremiumVitalsBar(VitalsModel v) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _vitalMetric("Weight", "${v.weightKg}", "kg", Colors.indigo),
          Container(width: 1, height: 24, color: Colors.grey.shade200),
          _vitalMetric("BMI", v.bmi.toStringAsFixed(1), "", v.bmi > 25 ? Colors.orange : Colors.green),
          Container(width: 1, height: 24, color: Colors.grey.shade200),
          _vitalMetric("BP", "${v.bloodPressureSystolic ?? '--'}/${v.bloodPressureDiastolic ?? '--'}", "", Colors.redAccent),
          Container(width: 1, height: 24, color: Colors.grey.shade200),
          InkWell(
            onTap: () => _compareVitals(v),
            child: const Icon(Icons.bar_chart_rounded, color: Colors.blue, size: 22),
          ),
        ],
      ),
    );
  }

  Widget _vitalMetric(String label, String val, String unit, Color color) {
    return Column(
      children: [
        Text(label.toUpperCase(), style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.grey.shade400)),
        RichText(
          text: TextSpan(
            children: [
              TextSpan(text: val, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: color)),
              if (unit.isNotEmpty) TextSpan(text: " $unit", style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: color.withOpacity(0.7))),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTags(String label, List<String> tags, Color color) {
    return Wrap(
      spacing: 6,
      children: [
        Text("$label:", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color)),
        ...tags.map((t) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
          child: Text(t, style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w600)),
        )),
      ],
    );
  }

  Widget _buildMedicationTile(PrescribedMedicine m) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.blue.shade50)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: Text(m.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
          Text("${m.dosage}  •  ${m.frequency}", style: TextStyle(fontSize: 11, color: Colors.grey.shade700, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  // --- ACTIONS ---

  Future<void> _fetchSessionDetails(ConsultationSessionModel session) async {
    if (_vitalsCache.containsKey(session.id)) return;

    final vitalsService = ref.read(vitalsServiceProvider);
    final dietService = ref.read(clientDietPlanServiceProvider);

    VitalsModel? v;
    if (session.linkedVitalsId != null) {
      v = await vitalsService.getVitalsById(session.linkedVitalsId!);
    } else {
      final allVitals = await vitalsService.getClientVitals(widget.client.id);
      v = allVitals.firstWhereOrNull((vt) => vt.sessionId == session.id);
    }

    ClientDietPlanModel? d;
    final allPlans = await dietService.getPlansForHistory(widget.client.id);
    d = allPlans.firstWhereOrNull((p) => p.sessionId == session.id);
    if (d == null && session.linkedDietPlanId != null) {
      d = allPlans.firstWhereOrNull((p) => p.id == session.linkedDietPlanId);
    }

    if (mounted) {
      setState(() {
        _vitalsCache[session.id] = v;
        _dietCache[session.id] = d;
      });
    }
  }

  // 🎯 PRINT RX
  void _printPrescription(VitalsModel vitals) {
    Navigator.push(context, MaterialPageRoute(
        builder: (_) => ClinicalPrescriptionPrinter(client: widget.client, vitals: vitals)
    ));
  }

  // 🎯 COMPARE DIET
  void _compareDiet(ClientDietPlanModel oldPlan) async {
    final dietService = ref.read(clientDietPlanServiceProvider);
    final allPlans = await dietService.getPlansForHistory(widget.client.id);

    // Logic: Compare against Current Session Plan (Draft) OR Active Plan (Live)
    ClientDietPlanModel? targetPlan;

    if (widget.currentSessionId != null) {
      targetPlan = allPlans.firstWhereOrNull((p) => p.sessionId == widget.currentSessionId);
    } else {
      // If viewed from dashboard, compare against latest active plan
      targetPlan = allPlans.firstWhereOrNull((p) => p.isActive == true);
    }

    if (targetPlan == null) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("No active/current plan found to compare with.")));
      return;
    }

    if(mounted) {
      Navigator.push(context, MaterialPageRoute(
          builder: (_) => DietPlanComparisonScreen(activePlan: targetPlan!, oldPlan: oldPlan, clientId: widget.client.id)
      ));
    }
  }

  void _viewDietReport(ClientDietPlanModel plan, VitalsModel? vitals) {
    Navigator.push(context, MaterialPageRoute(
        builder: (_) => PlanReportViewScreen(
          client: widget.client,
          plan: plan,
          vitals: vitals,
          isMasterPreview: false,
        )
    ));
  }

  void _compareVitals(VitalsModel oldVitals) {
    Navigator.push(context, MaterialPageRoute(
        builder: (_) => VitalsComparisonScreen(clientId: widget.client.id, clientName: widget.client.name)
    ));
  }

  Future<void> _cloneRx(VitalsModel oldVitals) async {
    if (widget.currentSessionId == null) return;
    // ... [Previous clone Rx logic remains same]
    final confirm = await _showConfirmDialog("Clone Prescription?", "Overwrite current session Rx?");
    if (!confirm) return;

    setState(() => _isProcessing = true);
    try {
      final vitalsService = ref.read(vitalsServiceProvider);
      VitalsModel? currentVitals = await vitalsService.getVitalsBySessionId(widget.currentSessionId!);
      currentVitals ??= await vitalsService.getLatestVitals(widget.client.id);

      if (currentVitals == null) throw "No active vitals for current session.";

      await vitalsService.updateHistoryData(
          clientId: widget.client.id,
          updateData: {
            'medications': oldVitals.medications.map((m) => m.toMap()).toList(),
            'clinicalGuidelines': oldVitals.clinicalGuidelines,
            'nutritionDiagnoses': oldVitals.nutritionDiagnoses,
            'clinicalComplaints': oldVitals.clinicalComplaints,
            'clinicalNotes': oldVitals.clinicalNotes,
          },
          existingVitals: currentVitals
      );

      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Rx Cloned!"), backgroundColor: Colors.green));
        Navigator.pop(context, true);
      }
    } catch (e) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if(mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _cloneDiet(ClientDietPlanModel oldPlan) async {
    if (widget.currentSessionId == null) return;
    // ... [Previous clone Diet logic remains same]
    final confirm = await _showConfirmDialog("Clone Diet?", "Create new draft based on this plan?");
    if (!confirm) return;

    setState(() => _isProcessing = true);
    try {
      final dietService = ref.read(clientDietPlanServiceProvider);
      final allPlans = await dietService.getPlansForHistory(widget.client.id);
      final existingPlan = allPlans.firstWhereOrNull((p) => p.sessionId == widget.currentSessionId);

      if (existingPlan != null) await dietService.deletePlan(existingPlan.id);

      final newPlan = oldPlan.copyWith(
        id: '',
        sessionId: widget.currentSessionId,
        assignedDate: Timestamp.now(),
        isProvisional: true,
        name: "${oldPlan.name} (Cloned)",
      );

      await dietService.savePlan(newPlan);

      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Plan Cloned!"), backgroundColor: Colors.green));
        Navigator.pop(context, true);
      }
    } catch (e) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if(mounted) setState(() => _isProcessing = false);
    }
  }

  Future<bool> _showConfirmDialog(String title, String content) async {
    return await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("CANCEL")),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("PROCEED")),
        ],
      ),
    ) ?? false;
  }
}