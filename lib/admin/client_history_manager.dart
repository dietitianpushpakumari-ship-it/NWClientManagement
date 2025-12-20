import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

  const ClientHistoryManager({
    super.key,
    required this.client,
    this.latestVitals,
    required this.onSaveComplete,
  });

  @override
  ConsumerState<ClientHistoryManager> createState() => _ClientHistoryManagerState();
}

class _ClientHistoryManagerState extends ConsumerState<ClientHistoryManager> {
  final _formKey = GlobalKey<FormState>();
  bool _isSaving = false;

  // --- THE 12 ATTRIBUTES ---
  late Map<String, String> _medicalHistory;       // 1
  late Map<String, String> _medications;          // 2
  late Map<String, String> _giDetails;            // 3
  late Map<String, String> _caffeineIntake;       // 4
  late Map<String, String> _habits;               // 5
  late Map<String, String> _waterIntake;          // 6
  List<String> _selectedAllergies = [];           // 7
  String? _foodHabit;                             // 8
  String? _activityType;                          // 9
  String? _sleepQuality;                          // 10
  int _stressLevel = 5;                           // 11
  String? _menstrualStatus;                       // 12

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  void _initializeData() {
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

  void _updateEntry(String section, String key, String value) {
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

  // 🎯 FIX: Corrected initialSelectedItems logic for single-select fields
  void _openSelection({
    required String title,
    required Map<String, String> masterData,
    required Map<String, String> currentMap,
    required String defaultValue,
    bool singleSelect = false,
    String? currentSingleValue, // Pass the current String value for pre-selection
    Function(String)? onSingleResult,
  }) async {
    final result = await showModalBottomSheet<List<String>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => GenericMultiSelectDialog(
        title: title,
        items: masterData.keys.toList(),
        itemNameIdMap: masterData,
        // If singleSelect, pass the current single value as a list so it's checked
        initialSelectedItems: singleSelect
            ? (currentSingleValue != null && currentSingleValue.isNotEmpty ? [currentSingleValue] : [])
            : currentMap.keys.toList(),
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
          SliverToBoxAdapter(
            child: Form(
              key: _formKey,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    // 1. DIET & ALLERGIES
                    _buildPremiumCard("Diet & Hydration", Icons.restaurant, Colors.orange, [
                      _buildPickerTile("Food Habit", _foodHabit ?? "Select", () => _openSelection(
                          title: "Food Habit", masterData: foodMaster, currentMap: {}, defaultValue: '',
                          singleSelect: true, currentSingleValue: _foodHabit, onSingleResult: (v) => _foodHabit = v
                      )),
                      _buildPickerTile("Water Intake", _waterIntake.keys.isEmpty ? "Select" : _waterIntake.keys.first, () => _openSelection(
                          title: "Water Intake", masterData: waterMaster, currentMap: _waterIntake, defaultValue: "Selected",
                          singleSelect: true, currentSingleValue: _waterIntake.keys.isEmpty ? null : _waterIntake.keys.first
                      )),
                      const SizedBox(height: 12),
                      const Text("Food Allergies", style: TextStyle(fontWeight: FontWeight.bold)),
                      Wrap(spacing: 8, children: _selectedAllergies.map((a) => Chip(label: Text(a), onDeleted: () => setState(() => _selectedAllergies.remove(a)))).toList()),
                      _buildAddAction("Select Allergies", () async {
                        final res = await showModalBottomSheet<List<String>>(context: context, isScrollControlled: true, builder: (ctx) => GenericMultiSelectDialog(title: "Allergies", items: allergyMaster.keys.toList(), itemNameIdMap: allergyMaster, initialSelectedItems: _selectedAllergies, onAddMaster: () {}));
                        if (res != null) setState(() => _selectedAllergies = res);
                      }),
                    ]),

                    // 2. CLINICAL
                    _buildPremiumCard("Clinical History", Icons.health_and_safety, Colors.blue, [
                      _buildAddAction("Select Medical Conditions", () => _openSelection(title: "Conditions", masterData: diseases, currentMap: _medicalHistory, defaultValue: "Not specified")),
                      ..._medicalHistory.keys.map((k) => MedicalDurationInput(key: ValueKey('med_$k'), condition: k, initialDetail: _medicalHistory[k]!, onChanged: (m) => _updateEntry('medical', k, m[k]!), onDelete: () => setState(() => _medicalHistory.remove(k)))),
                      const Divider(height: 32),
                      _buildAddAction("Select Medications", () => _openSelection(title: "Medications", masterData: medsMaster, currentMap: _medications, defaultValue: "Not specified, Once a Day")),
                      ..._medications.keys.map((k) => MedicationDosageInput(key: ValueKey('supp_$k'), medication: k, initialDetail: _medications[k]!, onChanged: (m) => _updateEntry('medication', k, m[k]!), onDelete: () => setState(() => _medications.remove(k)))),
                      const Divider(height: 32),
                      _buildAddAction("Select GI Details", () => _openSelection(title: "GI Symptoms", masterData: giMaster, currentMap: _giDetails, defaultValue: "Not specified")),
                      ..._giDetails.keys.map((k) => GIDetailInput(key: ValueKey('gi_$k'), detail: k, initialDetail: _giDetails[k]!, onChanged: (m) => _updateEntry('gi', k, m[k]!), onDelete: () => setState(() => _giDetails.remove(k)))),
                    ]),

                    // 3. LIFESTYLE & CAFFEINE
                    _buildPremiumCard("Lifestyle & Habits", Icons.psychology, Colors.purple, [
                      _buildPickerTile("Activity Level", _activityType ?? "Select", () => _openSelection(
                          title: "Activity Level", masterData: activityMaster, currentMap: {}, defaultValue: '',
                          singleSelect: true, currentSingleValue: _activityType, onSingleResult: (v) => _activityType = v
                      )),
                      _buildPickerTile("Sleep Quality", _sleepQuality ?? "Select", () => _openSelection(
                          title: "Sleep Quality", masterData: sleepMaster, currentMap: {}, defaultValue: '',
                          singleSelect: true, currentSingleValue: _sleepQuality, onSingleResult: (v) => _sleepQuality = v
                      )),
                      const SizedBox(height: 12),
                      Text("Stress Level: $_stressLevel/10", style: const TextStyle(fontWeight: FontWeight.bold)),
                      Slider(value: _stressLevel.toDouble(), min: 1, max: 10, divisions: 9, label: "$_stressLevel", onChanged: (v) => setState(() => _stressLevel = v.toInt())),
                      const Divider(height: 32),
                      _buildAddAction("Manage Habits", () => _openSelection(title: "Habits", masterData: habitsMaster, currentMap: _habits, defaultValue: "1|Day")),
                      ..._habits.keys.map((k) => HabitFrequencyInput(key: ValueKey('hab_$k'), habit: k, initialDetail: _habits[k]!, onChanged: (m) => _updateEntry('habit', k, m[k]!), onDelete: () => setState(() => _habits.remove(k)))),
                      const Divider(height: 32),
                      _buildAddAction("Caffeine Sources", () => _openSelection(title: "Caffeine", masterData: cafMaster, currentMap: _caffeineIntake, defaultValue: "1 per Day")),
                      ..._caffeineIntake.keys.map((k) => CaffeineInput(key: ValueKey('caf_$k'), source: k, initialDetail: _caffeineIntake[k]!, onChanged: (m) => _updateEntry('caffeine', k, m[k]!), onDelete: () => setState(() => _caffeineIntake.remove(k)))),
                    ]),

                    // 4. WOMEN'S HEALTH
                    if (widget.client.gender != 'Male')
                      _buildPremiumCard("Women's Health", Icons.female, Colors.pink, [
                        _buildPickerTile("Menstrual Status", _menstrualStatus ?? "Select", () => _openSelection(
                            title: "Menstrual Status", masterData: menstrualMaster, currentMap: {}, defaultValue: '',
                            singleSelect: true, currentSingleValue: _menstrualStatus, onSingleResult: (v) => _menstrualStatus = v
                        )),
                      ]),

                    const SizedBox(height: 40),
                    _buildSaveButton(),
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

  // --- UI COMPONENTS ---
  Widget _buildUltraHeader() => SliverAppBar(expandedHeight: 100, pinned: true, automaticallyImplyLeading: false, backgroundColor: Colors.white, flexibleSpace: FlexibleSpaceBar(titlePadding: const EdgeInsets.only(left: 20, bottom: 16), title: Row(children: [GestureDetector(onTap: () => Navigator.pop(context), child: const Icon(Icons.arrow_back_ios, size: 20, color: Colors.black)), const SizedBox(width: 12), const Text("Comprehensive History", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18))])));
  Widget _buildPremiumCard(String t, IconData i, Color c, List<Widget> ch) => Container(margin: const EdgeInsets.only(bottom: 24), padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: c.withOpacity(0.08), blurRadius: 20, offset: const Offset(0, 8))]), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [Icon(i, color: c, size: 22), const SizedBox(width: 12), Text(t, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold))]), const Divider(height: 32), ...ch]));
  Widget _buildPickerTile(String l, String v, VoidCallback t) => ListTile(contentPadding: EdgeInsets.zero, title: Text(l, style: const TextStyle(fontSize: 13, color: Colors.grey)), subtitle: Text(v, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)), trailing: const Icon(Icons.chevron_right), onTap: t);
  Widget _buildAddAction(String l, VoidCallback t) => TextButton.icon(onPressed: t, icon: const Icon(Icons.add_circle_outline, size: 18), label: Text(l));

  Widget _buildSaveButton() => ElevatedButton(
    onPressed: _isSaving ? null : _save,
    style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent, foregroundColor: Colors.white, minimumSize: const Size(double.infinity, 56), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
    child: _isSaving ? const CircularProgressIndicator(color: Colors.white) : const Text("SAVE ALL 12 ATTRIBUTES", style: TextStyle(fontWeight: FontWeight.bold)),
  );

  Future<void> _save() async {
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
        },
      );
      widget.onSaveComplete(true);
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}