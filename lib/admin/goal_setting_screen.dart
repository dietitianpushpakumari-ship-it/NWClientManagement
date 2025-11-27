import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:nutricare_client_management/admin/habit_master_model.dart';
import 'package:nutricare_client_management/admin/habit_master_service.dart'; // 🎯 Your Service

class AdminGoalSettingScreen extends StatefulWidget {
  final String clientId;
  final String clientName;
  final String planId; // The ID of the active diet plan to update

  const AdminGoalSettingScreen({
    super.key,
    required this.clientId,
    required this.clientName,
    required this.planId,
  });

  @override
  State<AdminGoalSettingScreen> createState() => _AdminGoalSettingScreenState();
}

class _AdminGoalSettingScreenState extends State<AdminGoalSettingScreen> {
  bool _isLoading = false;
  final HabitMasterService _habitService = HabitMasterService();

  // 🎯 GOAL CONTROLLERS (Defaults)
  double _waterGoal = 3.0;
  double _sleepGoal = 7.5;
  double _stepGoal = 8000;
  double _mindfulnessGoal = 15;

  // 🎯 HABIT SELECTION
  final List<String> _assignedHabits = []; // List of titles strings e.g. "Morning Sun"

  @override
  void initState() {
    super.initState();
    _loadExistingData();
  }

  Future<void> _loadExistingData() async {
    setState(() => _isLoading = true);
    try {
      // Load current plan settings
      final doc = await FirebaseFirestore.instance.collection('clientDietPlans').doc(widget.planId).get();

      if (doc.exists) {
        final data = doc.data()!;
        setState(() {
          _waterGoal = (data['dailyWaterGoal'] as num?)?.toDouble() ?? 3.0;
          _sleepGoal = (data['dailySleepGoal'] as num?)?.toDouble() ?? 7.5;
          _stepGoal = (data['dailyStepGoal'] as num?)?.toDouble() ?? 8000;
          _mindfulnessGoal = (data['dailyMindfulnessMinutes'] as num?)?.toDouble() ?? 15;

          if (data['mandatoryDailyTasks'] != null) {
            _assignedHabits.clear();
            _assignedHabits.addAll(List<String>.from(data['mandatoryDailyTasks']));
          }
        });
      }
    } catch (e) {
      debugPrint("Error loading plan: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveGoals() async {
    setState(() => _isLoading = true);
    try {
      await FirebaseFirestore.instance.collection('clientDietPlans').doc(widget.planId).update({
        'dailyWaterGoal': _waterGoal,
        'dailySleepGoal': _sleepGoal,
        'dailyStepGoal': _stepGoal.toInt(),
        'dailyMindfulnessMinutes': _mindfulnessGoal.toInt(),
        'mandatoryDailyTasks': _assignedHabits, // Saves list of strings
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Goals Updated Successfully!"), backgroundColor: Colors.green));
        Navigator.pop(context, true); // Return success
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Goal Configuration", style: TextStyle(fontSize: 18)),
            Text("For ${widget.clientName}", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal)),
          ],
        ),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        actions: [
          TextButton.icon(
            onPressed: _isLoading ? null : _saveGoals,
            icon: const Icon(Icons.save, color: Colors.white),
            label: const Text("SAVE", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. NUMERIC TARGETS
            _buildSectionHeader("Daily Targets", Icons.track_changes, Colors.blue),
            _buildSlider("Hydration", _waterGoal, 1.0, 5.0, 8, "${_waterGoal.toStringAsFixed(1)} L", Colors.blue, (v) => setState(() => _waterGoal = v)),
            _buildSlider("Movement", _stepGoal, 1000, 20000, 19, "${_stepGoal.toInt()} Steps", Colors.orange, (v) => setState(() => _stepGoal = v)),
            _buildSlider("Sleep", _sleepGoal, 4.0, 10.0, 12, "${_sleepGoal.toStringAsFixed(1)} Hrs", Colors.indigo, (v) => setState(() => _sleepGoal = v)),
            _buildSlider("Mindfulness", _mindfulnessGoal, 5, 60, 11, "${_mindfulnessGoal.toInt()} Mins", Colors.teal, (v) => setState(() => _mindfulnessGoal = v)),

            const Divider(height: 40),

            // 2. HABIT SELECTOR (From Master)
            _buildSectionHeader("Assign Habits", Icons.check_circle_outline, Colors.green),
            const Text("Select daily rituals from your Habit Master library.", style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 10),

            StreamBuilder<List<HabitMasterModel>>(
              stream: _habitService.streamAllHabits(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                final masterHabits = snapshot.data!;

                if (masterHabits.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(8)),
                    child: const Row(children: [Icon(Icons.warning, color: Colors.orange), SizedBox(width: 10), Expanded(child: Text("No habits found in Master Library. Please add some first."))]),
                  );
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: masterHabits.length,
                  itemBuilder: (context, index) {
                    final habit = masterHabits[index];
                    final isSelected = _assignedHabits.contains(habit.title);

                    return CheckboxListTile(
                      title: Text(habit.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(habit.description, maxLines: 1, overflow: TextOverflow.ellipsis),
                      secondary: CircleAvatar(
                        backgroundColor: isSelected ? Colors.green.shade100 : Colors.grey.shade100,
                        child: Icon(habit.iconData, color: isSelected ? Colors.green : Colors.grey),
                      ),
                      value: isSelected,
                      activeColor: Colors.green,
                      onChanged: (val) {
                        setState(() {
                          if (val == true) {
                            _assignedHabits.add(habit.title);
                          } else {
                            _assignedHabits.remove(habit.title);
                          }
                        });
                      },
                    );
                  },
                );
              },
            ),

            const SizedBox(height: 50),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(width: 10),
          Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildSlider(String label, double val, double min, double max, int divs, String displayVal, Color color, ValueChanged<double> onChanged) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
            Text(displayVal, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
        Slider(
          value: val, min: min, max: max, divisions: divs,
          activeColor: color,
          label: displayVal,
          onChanged: onChanged,
        ),
        const SizedBox(height: 10),
      ],
    );
  }
}