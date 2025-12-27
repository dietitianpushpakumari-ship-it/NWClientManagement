import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // 🎯 FIX 1: Import Riverpod
import 'package:nutricare_client_management/admin/ai_translation_service.dart';
import 'package:nutricare_client_management/admin/habit_master_model.dart';
import 'package:nutricare_client_management/admin/labvital/global_service_provider.dart'; // 🎯 Import services provider
import 'package:nutricare_client_management/core/localization/language_config.dart';

class HabitMasterScreen extends ConsumerStatefulWidget {
  const HabitMasterScreen({super.key});

  @override
  ConsumerState<HabitMasterScreen> createState() => _HabitMasterScreenState();
}

// 🎯 FIX 3: Convert State to ConsumerState
class _HabitMasterScreenState extends ConsumerState<HabitMasterScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // Content Controllers
  final TextEditingController _enTitleController = TextEditingController();
  final TextEditingController _enDescController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();

  // Localization Controllers
  final Map<String, TextEditingController> _localizedTitleControllers = {};
  final Map<String, TextEditingController> _localizedDescControllers = {};

  // State
  final AiTranslationService _translationService = AiTranslationService();
  bool _isLoading = false;
  bool _isTranslatingTitle = false;
  bool _isTranslatingDesc = false;
  HabitMasterModel? _editingHabit;
  HabitCategory _selectedCategory = HabitCategory.morning;
  String _selectedIconCode = 'sunny';
  String _searchQuery = "";

  @override
  void initState() {
    super.initState();
    for (var code in supportedLanguageCodes.where((c) => c != 'en')) {
      _localizedTitleControllers[code] = TextEditingController();
      _localizedDescControllers[code] = TextEditingController();
    }
    _clearForm();

    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _enTitleController.dispose();
    _enDescController.dispose();
    _searchController.dispose();
    _localizedTitleControllers.values.forEach((c) => c.dispose());
    _localizedDescControllers.values.forEach((c) => c.dispose());
    super.dispose();
  }

  // --- ACTIONS ---

  void _clearForm() {
    _enTitleController.clear();
    _enDescController.clear();
    _localizedTitleControllers.values.forEach((c) => c.clear());
    _localizedDescControllers.values.forEach((c) => c.clear());
    setState(() {
      _editingHabit = null;
      _selectedCategory = HabitCategory.morning;
      _selectedIconCode = 'sunny';
    });
  }

  void _editItem(HabitMasterModel habit) {
    _clearForm();
    _enTitleController.text = habit.name;
    _enDescController.text = habit.description;

    habit.titleLocalized.forEach((code, name) {
      if (_localizedTitleControllers.containsKey(code)) {
        _localizedTitleControllers[code]!.text = name;
      }
    });
    habit.descriptionLocalized.forEach((code, desc) {
      if (_localizedDescControllers.containsKey(code)) {
        _localizedDescControllers[code]!.text = desc;
      }
    });

    setState(() {
      _editingHabit = habit;
      _selectedCategory = habit.category;
      _selectedIconCode = habit.iconCode;
    });
  }

  Future<void> _performAutoTranslation({required bool isTitle}) async {
    final sourceController = isTitle ? _enTitleController : _enDescController;
    final targetControllers = isTitle ? _localizedTitleControllers : _localizedDescControllers;

    final text = sourceController.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Enter English ${isTitle ? 'Title' : 'Description'} first")));
      return;
    }

    setState(() => isTitle ? _isTranslatingTitle = true : _isTranslatingDesc = true);

    try {
      final translations = await _translationService.translateContent(text);
      translations.forEach((code, translatedText) {
        if (targetControllers.containsKey(code)) {
          targetControllers[code]!.text = translatedText;
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("✨ ${isTitle ? 'Title' : 'Description'} Translated!")));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Translation Error: $e")));
    } finally {
      if (mounted) setState(() => isTitle ? _isTranslatingTitle = false : _isTranslatingDesc = false);
    }
  }

  Future<void> _saveHabit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    // 🎯 FIX 4: Access services via ref.read()
    final service = ref.read(habitMasterServiceProvider);

    // Gather localized maps
    final Map<String, String> localizedTitles = {};
    _localizedTitleControllers.forEach((code, controller) {
      if (controller.text.trim().isNotEmpty) localizedTitles[code] = controller.text.trim();
    });

    final Map<String, String> localizedDescriptions = {};
    _localizedDescControllers.forEach((code, controller) {
      if (controller.text.trim().isNotEmpty) localizedDescriptions[code] = controller.text.trim();
    });

    final itemToSave = HabitMasterModel(
      id: _editingHabit?.id ?? '',
      name: _enTitleController.text.trim(),
      description: _enDescController.text.trim(),
      category: _selectedCategory,
      iconCode: _selectedIconCode,
      titleLocalized: localizedTitles,
      descriptionLocalized: localizedDescriptions,
    );

    try {
      await service.save(itemToSave);
      _clearForm();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteHabit(HabitMasterModel habit) async {
    // 🎯 FIX 5: Access services via ref.read()
    final service = ref.read(habitMasterServiceProvider);
    await service.delete(habit.id);
  }

  // --- UI BUILD ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      body: Column(
        children: [
          _buildHeader(),

          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: MediaQuery.of(context).size.width * 0.40,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: _buildHabitForm(),
                  ),
                ),

                VerticalDivider(width: 1, color: Colors.grey.shade300),

                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: _buildHabitList(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 🎯 HABIT FORM UI (omitted for brevity, content is based on last exchange)
  Widget _buildHabitForm() {
    final isEditing = _editingHabit != null;
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(isEditing ? "Edit Habit" : "Add New Habit", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.indigo)),
          const SizedBox(height: 20),

          // --- 1. Basic Info ---
          _buildPremiumCard(
            "Basic Info", Icons.info_outline, Colors.indigo,
            Column(
              children: [
                DropdownButtonFormField<HabitCategory>(
                  value: _selectedCategory,
                  decoration: _inputDec("Category", Icons.category),
                  items: HabitCategory.values.map((c) => DropdownMenuItem(value: c, child: Text(c.name))).toList(),
                  onChanged: (v) => setState(() => _selectedCategory = v!),
                ),
                const SizedBox(height: 12),
                _buildIconSelector(),
                const SizedBox(height: 12),
              ],
            ),
          ),

          // --- 2. Title Input ---
          _buildPremiumCard(
            "Habit Title", Icons.title, Colors.teal,
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _buildField(_enTitleController, "Title (English)", Icons.title)),
                const SizedBox(width: 8),
                _buildTranslateButton(isTitle: true),
              ],
            ),
          ),

          // --- 3. Description Input ---
          _buildPremiumCard(
            "Habit Description", Icons.description, Colors.blue,
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _buildMultiLineField(_enDescController, "Description (English)")),
                const SizedBox(width: 8),
                _buildTranslateButton(isTitle: false),
              ],
            ),
          ),

          // --- 4. Localization ---
          _buildPremiumCard(
            "Translations", Icons.language, Colors.purple,
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Title Localization:", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                ...supportedLanguageCodes.where((c) => c != 'en').map((code) => Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: _buildField(_localizedTitleControllers[code]!, "Title in ${supportedLanguages[code]}", Icons.language),
                )).toList(),

                const SizedBox(height: 20),
                const Text("Description Localization:", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                ...supportedLanguageCodes.where((c) => c != 'en').map((code) => Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: _buildMultiLineField(_localizedDescControllers[code]!, "Description in ${supportedLanguages[code]}"),
                )).toList(),
              ],
            ),
          ),

          const SizedBox(height: 20),
          Row(
            children: [
              if (isEditing)
                Expanded(child: TextButton(onPressed: _clearForm, child: const Text("Cancel Edit"))),
              Expanded(
                flex: isEditing ? 2 : 1,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveHabit,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white),
                  child: _isLoading
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white))
                      : Text(isEditing ? "UPDATE HABIT" : "SAVE HABIT"),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }


  // 🎯 HABIT LIST UI (Refactored with Search)
  Widget _buildHabitList() {
    // 🎯 FIX 6: Use ref.watch(provider) to stream data
    final habitStream = ref.watch(habitMasterServiceProvider).streamActiveHabits();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Current Habits", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.teal)),
        const SizedBox(height: 16),

        // 🎯 Search Bar (Re-using the definition from the previous step)
        Container(
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))]),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: "Search habit by title...",
              hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
              prefixIcon: Icon(Icons.search, color: Colors.grey.shade400),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            ),
          ),
        ),
        const SizedBox(height: 16),

        StreamBuilder<List<HabitMasterModel>>(
          stream: habitStream, // Use the Riverpod stream
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
            if (snapshot.hasError) return Center(child: Text("Error: ${snapshot.error}"));

            final allHabits = snapshot.data ?? [];

            final filteredHabits = allHabits.where((habit) =>
            habit.name.toLowerCase().contains(_searchQuery) ||
                habit.description.toLowerCase().contains(_searchQuery)
            ).toList();


            if (filteredHabits.isEmpty) return Center(child: Text("No habits matching filter."));

            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: filteredHabits.length,
              itemBuilder: (context, index) {
                final habit = filteredHabits[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    leading: Icon(habit.iconData, color: Colors.teal),
                    title: Text(habit.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(habit.category.name),
                        if (habit.titleLocalized.isNotEmpty)
                          Text("Titles: ${habit.titleLocalized.values.join(", ")}", style: TextStyle(fontSize: 11, color: Colors.grey)),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(icon: const Icon(Icons.edit, color: Colors.blue), onPressed: () => _editItem(habit)),
                        IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _deleteHabit(habit)),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }

  // --- WIDGET HELPERS (Retained from previous step) ---

  Widget _buildIconSelector() {
    final iconMap = {
      'sunny': Icons.wb_sunny, 'water': Icons.water_drop, 'book': Icons.menu_book,
      'walk': Icons.directions_walk, 'sleep': Icons.bedtime, 'phone': Icons.phonelink_erase,
      'food': Icons.restaurant, 'yoga': Icons.self_improvement, 'check': Icons.check_circle_outline,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Select Icon:", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.blueGrey)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 10, runSpacing: 10,
          children: iconMap.entries.map((entry) {
            final isSelected = _selectedIconCode == entry.key;
            return GestureDetector(
              onTap: () => setState(() => _selectedIconCode = entry.key),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.indigo.shade100 : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: isSelected ? Colors.indigo : Colors.transparent),
                ),
                child: Icon(entry.value, color: isSelected ? Colors.indigo : Colors.grey.shade600, size: 24),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildTranslateButton({required bool isTitle}) {
    final bool isLoaderActive = isTitle ? _isTranslatingTitle : _isTranslatingDesc;

    return InkWell(
      onTap: isLoaderActive ? null : () => _performAutoTranslation(isTitle: isTitle),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 56,
        width: 56,
        decoration: BoxDecoration(
          color: Colors.indigo.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.indigo.withOpacity(0.2)),
        ),
        child: isLoaderActive
            ? const Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)))
            : const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.translate, color: Colors.indigo, size: 20),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 2.0),
              child: FittedBox(
                  child: Text("Auto", style: TextStyle(fontSize: 9, color: Colors.indigo, fontWeight: FontWeight.bold))
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 10, 20, 16),
          decoration: BoxDecoration(color: Colors.white.withOpacity(0.8), border: Border(bottom: BorderSide(color: Colors.grey.withOpacity(0.1)))),
          child: Row(children: [
            GestureDetector(onTap: () => Navigator.pop(context), child: const Icon(Icons.arrow_back)),
            const SizedBox(width: 16),
            const Expanded(child: Text("Habits Master", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold))),
            Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.teal.withOpacity(.1), shape: BoxShape.circle), child: const Icon(Icons.check_circle_outline, color: Colors.teal)),
          ]),
        ),
      ),
    );
  }

  Widget _buildPremiumCard(String title, IconData icon, Color color, Widget child) {
    return Container(margin: const EdgeInsets.only(bottom: 20), padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: color.withOpacity(0.1))), child: Column(children: [Row(children: [Icon(icon, color: color), const SizedBox(width: 10), Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: color))]), const SizedBox(height: 16), child]));
  }

  Widget _buildField(TextEditingController c, String l, IconData i) => TextFormField(controller: c, decoration: _inputDec(l, i), validator: (v) => v!.isEmpty ? "Required" : null);

  Widget _buildMultiLineField(TextEditingController c, String l) => TextFormField(
    controller: c,
    decoration: _inputDec(l, Icons.text_fields),
    maxLines: 3,
    validator: (v) => v!.isEmpty ? "Required" : null,
  );

  InputDecoration _inputDec(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, size: 18),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      filled: true,
      fillColor: Colors.grey.shade50,
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
    );
  }
}