import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nutricare_client_management/helper/language_config.dart';
import 'package:nutricare_client_management/modules/master/model/meal_master_name.dart';
import 'package:nutricare_client_management/modules/master/service/master_meal_name_service.dart';
import 'package:provider/provider.dart';
import 'package:nutricare_client_management/admin/custom_gradient_app_bar.dart';

// NOTE: Ensure this file exists in your project structure
// import '../../helper/language_config.dart';

final List<String> supportedLanguageCodes = supportedLanguages.keys.toList();

class MasterMealNameEntryPage extends StatefulWidget {
  final MasterMealName? itemToEdit;

  const MasterMealNameEntryPage({super.key, this.itemToEdit});

  @override
  State<MasterMealNameEntryPage> createState() => _MasterMealNameEntryPageState();
}

class _MasterMealNameEntryPageState extends State<MasterMealNameEntryPage> {
  final _formKey = GlobalKey<FormState>();
  final _enNameController = TextEditingController();
  final _orderController = TextEditingController();
  final Map<String, TextEditingController> _localizedControllers = {};

  // 🎯 New State Variables for Time
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeLocalizedControllers();
    if (widget.itemToEdit != null) {
      _initializeForEdit(widget.itemToEdit!);
    } else {
      _orderController.text = '1';
    }
  }

  void _initializeLocalizedControllers() {
    for (var code in supportedLanguageCodes) {
      if (code != 'en') {
        _localizedControllers[code] = TextEditingController();
      }
    }
  }

  void _initializeForEdit(MasterMealName item) {
    _enNameController.text = item.enName;
    _orderController.text = item.order.toString();

    // Initialize Times
    if (item.startTime != null) _startTime = _stringToTimeOfDay(item.startTime!);
    if (item.endTime != null) _endTime = _stringToTimeOfDay(item.endTime!);

    item.nameLocalized.forEach((code, name) {
      if (_localizedControllers.containsKey(code)) {
        _localizedControllers[code]!.text = name;
      }
    });
  }

  // Helper to convert "HH:mm" string to TimeOfDay
  TimeOfDay? _stringToTimeOfDay(String timeString) {
    try {
      final parts = timeString.split(':');
      return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
    } catch (e) {
      return null;
    }
  }

  // Helper to convert TimeOfDay to "HH:mm" string
  String _timeOfDayToString(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  Future<void> _selectTime(BuildContext context, bool isStart) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: (isStart ? _startTime : _endTime) ?? TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startTime = picked;
        } else {
          _endTime = picked;
        }
      });
    }
  }

  @override
  void dispose() {
    _enNameController.dispose();
    _orderController.dispose();
    _localizedControllers.values.forEach((c) => c.dispose());
    super.dispose();
  }

  Future<void> _saveItem() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    final service = Provider.of<MasterMealNameService>(context, listen: false);

    final Map<String, String> localizedNames = {};
    _localizedControllers.forEach((code, controller) {
      final text = controller.text.trim();
      if (text.isNotEmpty) localizedNames[code] = text;
    });

    final int orderValue = int.tryParse(_orderController.text.trim()) ?? 99;

    final itemToSave = MasterMealName(
      id: widget.itemToEdit?.id ?? '',
      enName: _enNameController.text.trim(),
      nameLocalized: localizedNames,
      isDeleted: widget.itemToEdit?.isDeleted ?? false,
      createdDate: widget.itemToEdit?.createdDate,
      order: orderValue,
      // 🎯 Save Times
      startTime: _startTime != null ? _timeOfDayToString(_startTime!) : null,
      endTime: _endTime != null ? _timeOfDayToString(_endTime!) : null,
    );

    try {
      await service.save(itemToSave);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${itemToSave.enName} saved!')));
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  InputDecoration _inputDecoration(String label, {String? hint, IconData? icon}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: icon != null ? Icon(icon, color: Colors.indigo) : null,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      filled: true,
      fillColor: Colors.grey.shade50,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isEdit = widget.itemToEdit != null;
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: CustomGradientAppBar(
        title: Text(isEdit ? 'Edit Meal Name' : 'Add New Meal Name'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // --- CARD 1: Basic Info ---
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Basic Details', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blueGrey.shade800)),
                        const SizedBox(height: 20),
                        TextFormField(
                          controller: _enNameController,
                          decoration: _inputDecoration('Meal Name (English) *', hint: 'e.g., Breakfast'),
                          validator: (value) => value!.isEmpty ? 'Required' : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _orderController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          decoration: _inputDecoration('Display Order *', hint: '1, 2, 3...'),
                          validator: (value) => (value == null || int.tryParse(value) == null) ? 'Invalid order' : null,
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // --- CARD 2: Schedule / Timing ---
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Standard Timing', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blueGrey.shade800)),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Expanded(
                              child: InkWell(
                                onTap: () => _selectTime(context, true),
                                child: InputDecorator(
                                  decoration: _inputDecoration('Start Time', icon: Icons.access_time),
                                  child: Text(
                                    _startTime != null ? _startTime!.format(context) : 'Select',
                                    style: TextStyle(color: _startTime != null ? Colors.black87 : Colors.grey),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: InkWell(
                                onTap: () => _selectTime(context, false),
                                child: InputDecorator(
                                  decoration: _inputDecoration('End Time', icon: Icons.access_time_filled),
                                  child: Text(
                                    _endTime != null ? _endTime!.format(context) : 'Select',
                                    style: TextStyle(color: _endTime != null ? Colors.black87 : Colors.grey),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // --- CARD 3: Localization ---
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: ExpansionTile(
                    title: const Text('Translations', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.teal)),
                    leading: const Icon(Icons.translate, color: Colors.teal),
                    childrenPadding: const EdgeInsets.all(20),
                    children: [
                      ...supportedLanguageCodes.map((code) {
                        if (code == 'en') return const SizedBox.shrink();
                        final languageName = supportedLanguages[code]!;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16.0),
                          child: TextFormField(
                            controller: _localizedControllers[code],
                            decoration: _inputDecoration('Name in $languageName'),
                          ),
                        );
                      }).toList(),
                    ],
                  ),
                ),

                const SizedBox(height: 40),

                // --- Save Button ---
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _saveItem,
                  icon: _isLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.check_circle),
                  label: Text(isEdit ? 'Update Meal Name' : 'Save Meal Name'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 56),
                    backgroundColor: colorScheme.primary,
                    foregroundColor: Colors.white,
                    elevation: 4,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}