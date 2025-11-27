import 'package:flutter/material.dart';
import 'package:nutricare_client_management/helper/lab_vitals_data.dart';

class BodyVitalsSection extends StatelessWidget {
  // Controllers
  final TextEditingController weightController;
  final TextEditingController heightController;
  final TextEditingController waistController;
  final TextEditingController hipController;
  final TextEditingController fatController;
  final TextEditingController bpSysController;
  final TextEditingController bpDiaController;
  final TextEditingController hrController;
  final TextEditingController spo2Controller;

  // Lab Data Map
  final Map<String, TextEditingController> labControllers;

  // Lifestyle Data
  final String? foodHabit;
  final Function(String?) onFoodHabitChanged;
  final String? activityLevel;
  final Function(String?) onActivityLevelChanged;
  final bool smoking;
  final Function(bool) onSmokingChanged;
  final TextEditingController smokingFreqController;
  final bool alcohol;
  final Function(bool) onAlcoholChanged;
  final TextEditingController alcoholFreqController;

  const BodyVitalsSection({
    super.key,
    required this.weightController,
    required this.heightController,
    required this.waistController,
    required this.hipController,
    required this.fatController,
    required this.bpSysController,
    required this.bpDiaController,
    required this.hrController,
    required this.spo2Controller,
    required this.labControllers,
    required this.foodHabit,
    required this.onFoodHabitChanged,
    required this.activityLevel,
    required this.onActivityLevelChanged,
    required this.smoking,
    required this.onSmokingChanged,
    required this.smokingFreqController,
    required this.alcohol,
    required this.onAlcoholChanged,
    required this.alcoholFreqController,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Anthropometrics
          _buildSectionHeader("Body Metrics", Icons.accessibility_new, Colors.blue),
          _buildGlassContainer(
            child: Column(
              children: [
                Row(children: [
                  Expanded(child: _buildTextField("Weight (kg)", weightController)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildTextField("Height (cm)", heightController)),
                ]),
                const SizedBox(height: 16),
                Row(children: [
                  Expanded(child: _buildTextField("Waist (cm)", waistController)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildTextField("Hip (cm)", hipController)),
                ]),
                const SizedBox(height: 16),
                _buildTextField("Body Fat %", fatController),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // 2. Vital Signs
          _buildSectionHeader("Vital Signs", Icons.monitor_heart, Colors.red),
          _buildGlassContainer(
            child: Column(
              children: [
                Row(children: [
                  Expanded(child: _buildTextField("BP Sys (mmHg)", bpSysController)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildTextField("BP Dia (mmHg)", bpDiaController)),
                ]),
                const SizedBox(height: 16),
                Row(children: [
                  Expanded(child: _buildTextField("Heart Rate (bpm)", hrController)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildTextField("SpO2 (%)", spo2Controller)),
                ]),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // 3. DYNAMIC LABS (Grouped by Category)
          _buildSectionHeader("Lab Reports", Icons.science, Colors.teal),
          ...LabVitalsData.labCategories.map((category) {
            // Filter tests for this category
            final testsInCategory = LabVitalsData.allLabTests.entries
                .where((e) => e.value.category == category)
                .toList();

            if (testsInCategory.isEmpty) return const SizedBox.shrink();

            return Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: _buildGlassContainer(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(category, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.teal.shade800, fontSize: 14)),
                    const Divider(),
                    ...testsInCategory.map((entry) {
                      final testId = entry.key;
                      final config = entry.value;

                      // Ensure controller exists
                      if (!labControllers.containsKey(testId)) {
                        labControllers[testId] = TextEditingController();
                      }

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: _buildTextField(
                          "${config.displayName} (${config.unit})",
                          labControllers[testId]!,
                        ),
                      );
                    }).toList(),
                  ],
                ),
              ),
            );
          }).toList(),

          const SizedBox(height: 24),

          // 4. Lifestyle
          _buildSectionHeader("Lifestyle", Icons.self_improvement, Colors.green),
          _buildGlassContainer(
            child: Column(
              children: [
                DropdownButtonFormField<String>(
                  value: foodHabit,
                  decoration: _inputDecoration("Food Preference"),
                  items: ["Veg", "Non-Veg", "Eggetarian", "Vegan"].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                  onChanged: onFoodHabitChanged,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: activityLevel,
                  decoration: _inputDecoration("Activity Level"),
                  items: ["Sedentary", "Light", "Moderate", "Heavy", "Athlete"].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                  onChanged: onActivityLevelChanged,
                ),
                const SizedBox(height: 16),
                _buildHabitSwitch("Smoking", smoking, onSmokingChanged, smokingFreqController),
                const Divider(),
                _buildHabitSwitch("Alcohol", alcohol, onAlcoholChanged, alcoholFreqController),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlassContainer({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: child,
    );
  }

  Widget _buildTextField(String label, TextEditingController ctrl) {
    return TextFormField(
      controller: ctrl,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: _inputDecoration(label),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: Colors.grey.shade50,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.indigo, width: 1.5)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  Widget _buildHabitSwitch(String label, bool val, Function(bool) onChanged, TextEditingController freqCtrl) {
    return Column(
      children: [
        SwitchListTile(
          title: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          value: val,
          onChanged: onChanged,
          contentPadding: EdgeInsets.zero,
          activeColor: Colors.green,
        ),
        if (val)
          TextFormField(
            controller: freqCtrl,
            decoration: _inputDecoration("Frequency (e.g., Socially / 5 per day)"),
          )
      ],
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(children: [Icon(icon, color: color, size: 22), const SizedBox(width: 10), Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueGrey.shade800))]),
    );
  }
}