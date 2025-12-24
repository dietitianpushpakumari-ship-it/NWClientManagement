import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:nutricare_client_management/admin/consultation_summary_page.dart';
import 'package:nutricare_client_management/admin/database_provider.dart';
import 'package:nutricare_client_management/master/model/master_constants.dart';
import 'package:nutricare_client_management/master_diet_planner/client_history_sheet.dart';
import 'package:nutricare_client_management/master_diet_planner/complex_input_widgets.dart';
import 'package:nutricare_client_management/master_diet_planner/generic_multi_select_dialogg.dart';
import 'package:nutricare_client_management/modules/client/model/client_model.dart';
import 'package:nutricare_client_management/modules/client/model/vitals_model.dart';
import 'package:nutricare_client_management/admin/labvital/global_service_provider.dart';

class ClientHistoryManager extends ConsumerStatefulWidget {
  final ClientModel client;
  final VitalsModel? latestVitals;
  final Function(bool) onSaveComplete;
  final String? sessionId;
  final bool isReadOnly;
  final bool isFollowup; // 🎯 NEW

  const ClientHistoryManager({
    super.key,
    required this.client,
    this.latestVitals,
    required this.onSaveComplete,
    this.sessionId,
    this.isReadOnly = false,
    this.isFollowup = false, // Default false
  });

  @override
  ConsumerState<ClientHistoryManager> createState() => _ClientHistoryManagerState();
}

class _ClientHistoryManagerState extends ConsumerState<ClientHistoryManager> {
  final _formKey = GlobalKey<FormState>();
  bool _isSaving = false;

  VitalsModel? _previousHistoryVitals;
  bool _isLoadingHistory = true;
  String? _historyFetchError;
  bool _dataWasCopied = false;

  late Map<String, String> _medicalHistory;
  late Map<String, String> _medications;
  late Map<String, String> _giDetails;
  late Map<String, String> _caffeineIntake;
  late Map<String, String> _habits;
  late Map<String, String> _waterIntake;
  List<String> _selectedAllergies = [];
  String? _foodHabit;
  String? _activityType;
  String? _sleepQuality;
  int _stressLevel = 5;
  String? _menstrualStatus;

  @override
  void initState() {
    super.initState();
    _initializeData();
    _fetchPreviousHistory();
  }

  void _initializeData() {
    // 🎯 IF latestVitals passed as NULL (New Consultation), this creates empty maps.
    final v = widget.latestVitals;
    _medicalHistory = Map<String, String>.from(v?.medicalHistory ?? {});
    _medications = Map<String, String>.from(v?.prescribedMedications ?? {});
    _giDetails = Map<String, String>.from(v?.giDetails ?? {});
    _caffeineIntake = Map<String, String>.from(v?.caffeineIntake ?? {});
    _habits = Map<String, String>.from(v?.otherLifestyleHabits ?? {});
    _waterIntake = Map<String, String>.from(v?.waterIntake ?? {});
    _selectedAllergies = List<String>.from(v?.foodAllergies ?? []);
    _foodHabit = v?.foodHabit;
    _activityType = v?.activityType;
    _sleepQuality = v?.sleepQuality;
    _stressLevel = v?.stressLevel ?? 5;
    _menstrualStatus = v?.menstrualStatus;
  }

  Future<void> _fetchPreviousHistory() async {
    try {
      final firestore = ref.read(firestoreProvider);
      Query query = firestore.collection('vitals')
          .where('clientId', isEqualTo: widget.client.id)
          .orderBy('date', descending: true)
          .limit(5);

      final snapshot = await query.get();

      if (snapshot.docs.isNotEmpty) {
        VitalsModel? foundPrev;
        for (var doc in snapshot.docs) {
          if ((widget.latestVitals?.id != null && widget.latestVitals!.id == doc.id) ||
              (widget.sessionId != null && doc['sessionId'] == widget.sessionId)) {
            continue;
          }
          foundPrev = VitalsModel.fromFirestore(doc);
          break;
        }

        if (foundPrev != null && mounted) {
          setState(() {
            _previousHistoryVitals = foundPrev;
            // 🎯 ONLY AUTO-COPY IF FOLLOW-UP
            if (widget.isFollowup) {
              _autoFillIfEmpty();
            }
          });
        }
      }
    } catch (e) {
      if (mounted) setState(() => _historyFetchError = "Could not load history.");
    } finally {
      if (mounted) setState(() => _isLoadingHistory = false);
    }
  }

  // 🎯 MANUAL COPY FUNCTION
  void _autoFillIfEmpty() {
    final p = _previousHistoryVitals;
    if (p == null) return;

    setState(() {
      if (_medicalHistory.isEmpty) _medicalHistory = Map.from(p.medicalHistory ?? {});
      if (_medications.isEmpty) _medications = Map.from(p.prescribedMedications ?? {});
      if (_giDetails.isEmpty) _giDetails = Map.from(p.giDetails ?? {});
      if (_caffeineIntake.isEmpty) _caffeineIntake = Map.from(p.caffeineIntake ?? {});
      if (_habits.isEmpty) _habits = Map.from(p.otherLifestyleHabits ?? {});
      if (_waterIntake.isEmpty) _waterIntake = Map.from(p.waterIntake ?? {});
      if (_selectedAllergies.isEmpty) _selectedAllergies = List.from(p.foodAllergies ?? []);

      _foodHabit ??= p.foodHabit;
      _activityType ??= p.activityType;
      _sleepQuality ??= p.sleepQuality;
      _menstrualStatus ??= p.menstrualStatus;

      _dataWasCopied = true;
    });
  }

  void _updateEntry(String section, String key, String value) {
    if (widget.isReadOnly) return;
    if (SchedulerBinding.instance.schedulerPhase != SchedulerPhase.idle) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _updateEntry(section, key, value));
      return;
    }
    setState(() {
      switch (section) {
        case 'medical': _medicalHistory[key] = value; break;
        case 'medication': _medications[key] = value; break;
        case 'gi': _giDetails[key] = value; break;
        case 'caffeine': _caffeineIntake[key] = value; break;
        case 'habit': _habits[key] = value; break;
        case 'water': _waterIntake[key] = value; break;
      }
    });
  }

  void _openSelection({required String title, required Map<String, String> masterData, required Map<String, String> currentMap, required String defaultValue, bool singleSelect = false, String? currentSingleValue, Function(String)? onSingleResult}) async {
    if (widget.isReadOnly) return;
    final result = await showModalBottomSheet<List<String>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => GenericMultiSelectDialog(
        title: title,
        items: masterData.keys.toList(),
        itemNameIdMap: masterData,
        initialSelectedItems: singleSelect ? (currentSingleValue != null && currentSingleValue.isNotEmpty ? [currentSingleValue] : []) : currentMap.keys.toList(),
        onAddMaster: () {},
        singleSelect: singleSelect,
      ),
    );

    if (result != null) {
      setState(() {
        if (singleSelect && onSingleResult != null) {
          onSingleResult(result.isNotEmpty ? result.first : '');
        } else if (!singleSelect) {
          for (var key in result) {
            if (!currentMap.containsKey(key)) currentMap[key] = defaultValue;
          }
          currentMap.removeWhere((k, v) => !result.contains(k));
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final diseases = ref.watch(diseaseMasterProvider).value ?? {};
    final medsMaster = ref.watch(supplimentMasterProvider).value ?? {};
    final giMaster = ref.watch(giMasterProvider).value ?? {};
    final habitsMaster = ref.watch(lifeStyleHabitMasterProvider).value ?? {};
    final cafMaster = ref.watch(caffeineMasterProvider).value ?? {};
    final waterMaster = ref.watch(waterIntakeMasterProvider).value ?? {};
    final allergyMaster = ref.watch(allergiesMasterProvider).value ?? {};
    final foodMaster = ref.watch(foodHabitMasterProvider).value ?? {};
    final activityMaster = ref.watch(activityMasterProvider).value ?? {};
    final sleepMaster = ref.watch(sleepMasterProvider).value ?? {};
    final menstrualMaster = ref.watch(menstrualMasterProvider).value ?? {};

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FF),
      body: CustomScrollView(
        slivers: [
          _buildUltraHeader(),

          if (_historyFetchError != null)
            SliverToBoxAdapter(
              child: Container(margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10), padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(8)), child: Row(children: [const Icon(Icons.warning, color: Colors.red), const SizedBox(width: 8), Expanded(child: Text(_historyFetchError!, style: const TextStyle(color: Colors.red)))])),
            ),

          if (_previousHistoryVitals != null)
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.fromLTRB(20, 10, 20, 0),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.blue.withOpacity(0.3))),
                child: Row(
                  children: [
                    const Icon(Icons.history_edu, color: Colors.blue),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _dataWasCopied
                                ? "Data copied from ${DateFormat('dd MMM').format(_previousHistoryVitals!.date)}"
                                : "Previous history found (${DateFormat('dd MMM').format(_previousHistoryVitals!.date)})",
                            style: const TextStyle(fontSize: 12, color: Colors.blue, fontWeight: FontWeight.bold),
                          ),
                          // 🎯 SHOW "Tap Copy" hint if not copied and editable
                          if (!_dataWasCopied && !widget.isReadOnly)
                            const Text("Tap 'Copy' to fill this form", style: TextStyle(fontSize: 10, color: Colors.grey)),
                        ],
                      ),
                    ),
                    // 🎯 MANUAL COPY BUTTON
                    if (!_dataWasCopied && !widget.isReadOnly)
                      TextButton.icon(
                        icon: const Icon(Icons.copy, size: 14),
                        label: const Text("Copy"),
                        onPressed: _autoFillIfEmpty,
                        style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                      ),
                    TextButton(onPressed: _showComparisonSheet, child: const Text("Compare"))
                  ],
                ),
              ),
            ),

          SliverToBoxAdapter(
            child: Form(
              key: _formKey,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    _buildPremiumCard("Diet & Hydration", Icons.restaurant, Colors.orange, [
                      _buildPickerTile("Food Habit", _foodHabit ?? "Select", () => _openSelection(title: "Food Habit", masterData: foodMaster, currentMap: {}, defaultValue: '', singleSelect: true, currentSingleValue: _foodHabit, onSingleResult: (v) => _foodHabit = v)),
                      _buildPickerTile("Water Intake", _waterIntake.keys.isEmpty ? "Select" : _waterIntake.keys.first, () => _openSelection(title: "Water Intake", masterData: waterMaster, currentMap: _waterIntake, defaultValue: "Selected", singleSelect: true, currentSingleValue: _waterIntake.keys.isEmpty ? null : _waterIntake.keys.first, onSingleResult: (v) { setState(() { _waterIntake.clear(); if (v.isNotEmpty) _waterIntake[v] = "Selected"; }); })),
                      const SizedBox(height: 12),
                      const Text("Food Allergies", style: TextStyle(fontWeight: FontWeight.bold)),
                      Wrap(spacing: 8, children: _selectedAllergies.map((a) => Chip(label: Text(a), onDeleted: widget.isReadOnly ? null : () => setState(() => _selectedAllergies.remove(a)))).toList()),
                      _buildAddAction("Select Allergies", () async {
                        final res = await showModalBottomSheet<List<String>>(context: context, isScrollControlled: true, builder: (ctx) => GenericMultiSelectDialog(title: "Allergies", items: allergyMaster.keys.toList(), itemNameIdMap: allergyMaster, initialSelectedItems: _selectedAllergies, onAddMaster: () {}));
                        if (res != null) setState(() => _selectedAllergies = res);
                      }),
                    ]),
                    _buildPremiumCard("Clinical History", Icons.health_and_safety, Colors.blue, [
                      _buildAddAction("Select Medical Conditions", () => _openSelection(title: "Conditions", masterData: diseases, currentMap: _medicalHistory, defaultValue: "Not specified")),
                      ..._medicalHistory.keys.map((k) => MedicalDurationInput(key: ValueKey('med_$k'), condition: k, initialDetail: _medicalHistory[k]!, onChanged: (m) => _updateEntry('medical', k, m[k]!), onDelete: widget.isReadOnly ? null : () => setState(() => _medicalHistory.remove(k)))),
                      const Divider(height: 32),
                      _buildAddAction("Select Medications", () => _openSelection(title: "Medications", masterData: medsMaster, currentMap: _medications, defaultValue: "Not specified, Once a Day")),
                      ..._medications.keys.map((k) => MedicationDosageInput(key: ValueKey('supp_$k'), medication: k, initialDetail: _medications[k]!, onChanged: (m) => _updateEntry('medication', k, m[k]!), onDelete: widget.isReadOnly ? null : () => setState(() => _medications.remove(k)))),
                      const Divider(height: 32),
                      _buildAddAction("Select GI Details", () => _openSelection(title: "GI Symptoms", masterData: giMaster, currentMap: _giDetails, defaultValue: "Not specified")),
                      ..._giDetails.keys.map((k) => GIDetailInput(key: ValueKey('gi_$k'), detail: k, initialDetail: _giDetails[k]!, onChanged: (m) => _updateEntry('gi', k, m[k]!), onDelete: widget.isReadOnly ? null : () => setState(() => _giDetails.remove(k)))),
                    ]),
                    _buildPremiumCard("Lifestyle & Habits", Icons.psychology, Colors.purple, [
                      _buildPickerTile("Activity Level", _activityType ?? "Select", () => _openSelection(title: "Activity Level", masterData: activityMaster, currentMap: {}, defaultValue: '', singleSelect: true, currentSingleValue: _activityType, onSingleResult: (v) => _activityType = v)),
                      _buildPickerTile("Sleep Quality", _sleepQuality ?? "Select", () => _openSelection(title: "Sleep Quality", masterData: sleepMaster, currentMap: {}, defaultValue: '', singleSelect: true, currentSingleValue: _sleepQuality, onSingleResult: (v) => _sleepQuality = v)),
                      const SizedBox(height: 12),
                      Text("Stress Level: $_stressLevel/10", style: const TextStyle(fontWeight: FontWeight.bold)),
                      Slider(value: _stressLevel.toDouble(), min: 1, max: 10, divisions: 9, label: "$_stressLevel", onChanged: widget.isReadOnly ? null : (v) => setState(() => _stressLevel = v.toInt())),
                      const Divider(height: 32),
                      _buildAddAction("Manage Habits", () => _openSelection(title: "Habits", masterData: habitsMaster, currentMap: _habits, defaultValue: "1|Day")),
                      ..._habits.keys.map((k) => HabitFrequencyInput(key: ValueKey('hab_$k'), habit: k, initialDetail: _habits[k]!, onChanged: (m) => _updateEntry('habit', k, m[k]!), onDelete: widget.isReadOnly ? null : () => setState(() => _habits.remove(k)))),
                      const Divider(height: 32),
                      _buildAddAction("Caffeine Sources", () => _openSelection(title: "Caffeine", masterData: cafMaster, currentMap: _caffeineIntake, defaultValue: "1 per Day")),
                      ..._caffeineIntake.keys.map((k) => CaffeineInput(key: ValueKey('caf_$k'), source: k, initialDetail: _caffeineIntake[k]!, onChanged: (m) => _updateEntry('caffeine', k, m[k]!), onDelete: widget.isReadOnly ? null : () => setState(() => _caffeineIntake.remove(k)))),
                    ]),
                    if (widget.client.gender != 'Male')
                      _buildPremiumCard("Women's Health", Icons.female, Colors.pink, [
                        _buildPickerTile("Menstrual Status", _menstrualStatus ?? "Select", () => _openSelection(title: "Menstrual Status", masterData: menstrualMaster, currentMap: {}, defaultValue: '', singleSelect: true, currentSingleValue: _menstrualStatus, onSingleResult: (v) => _menstrualStatus = v)),
                      ]),

                    const SizedBox(height: 40),
                    if (!widget.isReadOnly) _buildSaveButton(),
                    const SizedBox(height: 50),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showComparisonSheet() {
    if (_previousHistoryVitals == null) return;
    showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Colors.transparent, builder: (context) => Container(height: MediaQuery.of(context).size.height * 0.7, decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(25))), padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text("History Comparison", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)), const SizedBox(height: 16), Expanded(child: ListView(children: [_buildCompareRow("Medical", _medicalHistory, _previousHistoryVitals!.medicalHistory ?? {}), _buildCompareRow("Medications", _medications, _previousHistoryVitals!.prescribedMedications ?? {}), _buildCompareRow("Habits", _habits, _previousHistoryVitals!.otherLifestyleHabits ?? {}), const Divider(), _buildCompareText("Food Habit", _foodHabit, _previousHistoryVitals!.foodHabit), _buildCompareText("Activity", _activityType, _previousHistoryVitals!.activityType), _buildCompareText("Sleep", _sleepQuality, _previousHistoryVitals!.sleepQuality)]))])));
  }

  Widget _buildCompareRow(String title, Map current, Map previous) { return Padding(padding: const EdgeInsets.only(bottom: 16.0), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo)), Row(children: [Expanded(child: _buildInfoBox("Current", current.keys.join(", "))), const SizedBox(width: 10), Expanded(child: _buildInfoBox("Previous", previous.keys.join(", "), isOld: true))])])); }
  Widget _buildCompareText(String title, String? current, String? previous) { return Padding(padding: const EdgeInsets.only(bottom: 12.0), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(title, style: const TextStyle(fontWeight: FontWeight.w600)), Column(crossAxisAlignment: CrossAxisAlignment.end, children: [Text(current ?? "-", style: const TextStyle(fontWeight: FontWeight.bold)), if (current != previous) Text("Was: ${previous ?? '-'}", style: const TextStyle(fontSize: 11, color: Colors.grey, decoration: TextDecoration.lineThrough))])])); }
  Widget _buildInfoBox(String label, String content, {bool isOld = false}) { return Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: isOld ? Colors.grey[100] : Colors.blue[50], borderRadius: BorderRadius.circular(8)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: TextStyle(fontSize: 10, color: isOld ? Colors.grey : Colors.blue)), Text(content.isEmpty ? "-" : content, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold))])); }
  Widget _buildUltraHeader() => SliverAppBar(expandedHeight: 100, pinned: true, automaticallyImplyLeading: false, backgroundColor: Colors.white, flexibleSpace: FlexibleSpaceBar(titlePadding: const EdgeInsets.only(left: 20, bottom: 16, right: 20), title: Row(children: [GestureDetector(onTap: () => Navigator.pop(context), child: const Icon(Icons.arrow_back_ios, size: 20, color: Colors.black)), const SizedBox(width: 12), const Expanded(child: Text("Comprehensive History", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18))), IconButton(icon: const Icon(Icons.manage_search, color: Colors.blueAccent), onPressed: () { Navigator.push(context, MaterialPageRoute(builder: (context) => ConsultationSummaryPage(clientId: widget.client.id, clientName: widget.client.name))); })])));
  Widget _buildPremiumCard(String t, IconData i, Color c, List<Widget> ch) => Container(margin: const EdgeInsets.only(bottom: 24), padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: c.withOpacity(0.08), blurRadius: 20, offset: const Offset(0, 8))]), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [Icon(i, color: c, size: 22), const SizedBox(width: 12), Text(t, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold))]), const Divider(height: 32), ...ch]));
  Widget _buildPickerTile(String l, String v, VoidCallback t) => ListTile(contentPadding: EdgeInsets.zero, title: Text(l, style: const TextStyle(fontSize: 13, color: Colors.grey)), subtitle: Text(v, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)), trailing: widget.isReadOnly ? null : const Icon(Icons.chevron_right), onTap: widget.isReadOnly ? null : t);
  Widget _buildAddAction(String l, VoidCallback t) => widget.isReadOnly ? const SizedBox.shrink() : TextButton.icon(onPressed: t, icon: const Icon(Icons.add_circle_outline, size: 18), label: Text(l));
  Widget _buildSaveButton() => ElevatedButton(onPressed: _isSaving ? null : _save, style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent, foregroundColor: Colors.white, minimumSize: const Size(double.infinity, 56), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))), child: _isSaving ? const CircularProgressIndicator(color: Colors.white) : const Text("SAVE ALL 12 ATTRIBUTES", style: TextStyle(fontWeight: FontWeight.bold)));

  Future<void> _save() async {
    if (widget.isReadOnly) return;
    setState(() => _isSaving = true);
    try {
      await ref.read(vitalsServiceProvider).updateHistoryData(
        clientId: widget.client.id,
        updateData: {
          'medicalHistory': _medicalHistory,
          'prescribedMedications': _medications,
          'giDetails': _giDetails,
          'caffeineIntake': _caffeineIntake,
          'otherLifestyleHabits': _habits,
          'waterIntake': _waterIntake,
          'foodAllergies': _selectedAllergies,
          'foodHabit': _foodHabit,
          'activityType': _activityType,
          'sleepQuality': _sleepQuality,
          'stressLevel': _stressLevel,
          'menstrualStatus': _menstrualStatus,
          'sessionId': widget.sessionId,
        },
      );

      // 識 UPDATE SESSION STATUS
      if (widget.sessionId != null) {
        final firestore = ref.read(firestoreProvider);
        await firestore.collection('consultation_sessions').doc(widget.sessionId).update({
          'steps.history': true,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
      widget.onSaveComplete(true);
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}