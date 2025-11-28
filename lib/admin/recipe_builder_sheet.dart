import 'package:flutter/material.dart';

class RecipeBuilderSheet extends StatefulWidget {
  final Map<String, dynamic>? initialData;
  const RecipeBuilderSheet({super.key, this.initialData});

  @override
  State<RecipeBuilderSheet> createState() => _RecipeBuilderSheetState();
}

class _RecipeBuilderSheetState extends State<RecipeBuilderSheet> {
  final _ingredientsCtrl = TextEditingController(); // Line separated
  final _stepsCtrl = TextEditingController(); // Line separated
  final _caloriesCtrl = TextEditingController();
  final _timeCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.initialData != null) {
      _ingredientsCtrl.text = (widget.initialData!['ingredients'] as List).join('\n');
      _stepsCtrl.text = (widget.initialData!['steps'] as List).join('\n');
      _caloriesCtrl.text = widget.initialData!['calories'].toString();
      _timeCtrl.text = widget.initialData!['time'].toString();
    }
  }

  void _save() {
    final data = {
      'ingredients': _ingredientsCtrl.text.split('\n').where((s) => s.trim().isNotEmpty).toList(),
      'steps': _stepsCtrl.text.split('\n').where((s) => s.trim().isNotEmpty).toList(),
      'calories': int.tryParse(_caloriesCtrl.text) ?? 0,
      'time': int.tryParse(_timeCtrl.text) ?? 0,
    };
    Navigator.pop(context, data);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const Text("Recipe Details", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(child: TextField(controller: _caloriesCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Calories (Kcal)", border: OutlineInputBorder()))),
                      const SizedBox(width: 12),
                      Expanded(child: TextField(controller: _timeCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Cook Time (Mins)", border: OutlineInputBorder()))),
                    ],
                  ),
                  const SizedBox(height: 20),
                  TextField(controller: _ingredientsCtrl, maxLines: 6, decoration: const InputDecoration(labelText: "Ingredients (One per line)", border: OutlineInputBorder(), alignLabelWithHint: true)),
                  const SizedBox(height: 20),
                  TextField(controller: _stepsCtrl, maxLines: 6, decoration: const InputDecoration(labelText: "Steps (One per line)", border: OutlineInputBorder(), alignLabelWithHint: true)),
                ],
              ),
            ),
          ),
          SizedBox(width: double.infinity, child: ElevatedButton(onPressed: _save, style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, padding: const EdgeInsets.symmetric(vertical: 16)), child: const Text("SAVE RECIPE", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))))
        ],
      ),
    );
  }
}