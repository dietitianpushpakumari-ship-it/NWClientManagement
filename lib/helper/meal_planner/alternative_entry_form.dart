import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nutricare_client_management/modules/master/model/diet_plan_item_model.dart';
import 'package:nutricare_client_management/modules/master/model/food_item.dart';

class AlternativeEntryForm extends StatefulWidget {
  final List<FoodItem> foodItems;
  final void Function(FoodItemAlternative) onSave;
  final VoidCallback onCancel;

  const AlternativeEntryForm({
    super.key,
    required this.foodItems,
    required this.onSave,
    required this.onCancel,
  });

  @override
  State<AlternativeEntryForm> createState() => _AlternativeEntryFormState();
}

class _AlternativeEntryFormState extends State<AlternativeEntryForm> {
  FoodItem? _selectedFoodItem;
  final _quantityController = TextEditingController(text: '1.0');
  double _calculatedCalories = 0.0;
  double _calculatedProteinG = 0.0;
  double _calculatedCarbsG = 0.0;
  double _calculatedFatG = 0.0;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _selectedFoodItem = widget.foodItems.isNotEmpty
        ? widget.foodItems.first
        : null;
    _quantityController.addListener(_onQuantityChanged);
    _calculateMacros();
  }

  @override
  void dispose() {
    _quantityController.removeListener(_onQuantityChanged);
    _quantityController.dispose();
    super.dispose();
  }

  void _onQuantityChanged() {
    _calculateMacros(quantityValue: double.tryParse(_quantityController.text));
  }

  void _calculateMacros({FoodItem? item, double? quantityValue}) {
    final itemToUse = item ?? _selectedFoodItem;
    final quantity =
        quantityValue ?? (double.tryParse(_quantityController.text) ?? 0.0);

    if (itemToUse == null || quantity <= 0) {
      if (_calculatedCalories != 0.0) {
        setState(() {
          _calculatedCalories = _calculatedProteinG = _calculatedCarbsG =
              _calculatedFatG = 0.0;
        });
      }
      return;
    }

    final macros = _selectedFoodItem!.calculateMacros(quantity);

    setState(() {
      _calculatedCalories = macros['calories']!;
      _calculatedProteinG = macros['protein']!;
      _calculatedCarbsG = macros['carbs']!;
      _calculatedFatG = macros['fat']!;
    });
  }

  void _save() {
    if (_formKey.currentState!.validate() && _selectedFoodItem != null) {
      final quantity = double.tryParse(_quantityController.text) ?? 0.0;

      final newAlternative = FoodItemAlternative(
        // IMPORTANT: Generate a unique ID for reliable removal
        id: 'alt_${DateTime
            .now()
            .millisecondsSinceEpoch}_${Random().nextInt(999)}',
        foodItemId: _selectedFoodItem!.id,
        foodItemName: _selectedFoodItem!.enName,
        quantity: quantity,
        unit: _selectedFoodItem!.servingUnitId,
      );
      widget.onSave(newAlternative);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please select a food item and enter a valid quantity.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 10),
        Text(
          'Add New Alternative',
          style: Theme
              .of(context)
              .textTheme
              .titleMedium,
        ),
        const SizedBox(height: 10),
        Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DropdownButtonFormField<FoodItem>(
                value: _selectedFoodItem,
                decoration: InputDecoration(
                  labelText: 'Food Item (Alternative)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
                isExpanded: true,
                items: widget.foodItems.map<DropdownMenuItem<FoodItem>>((item) {
                  return DropdownMenuItem<FoodItem>(
                    value: item,
                    child: Text(item.enName, overflow: TextOverflow.ellipsis),
                  );
                }).toList(),
                onChanged: (item) {
                  setState(() {
                    _selectedFoodItem = item;
                    _calculateMacros(item: item);
                  });
                },
                validator: (value) => value == null ? 'Select an item' : null,
              ),
              const SizedBox(height: 15),
              TextFormField(
                controller: _quantityController,
                decoration: InputDecoration(
                  labelText: 'Quantity',
                  suffixText: _selectedFoodItem?.servingUnitId ?? 'Unit',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                ],
                validator: (value) =>
                (double.tryParse(value ?? '') ?? 0) <= 0
                    ? 'Enter valid quantity'
                    : null,
              ),
              const SizedBox(height: 10),
              Container(
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildMacroStat('KCal', _calculatedCalories, Colors.red),
                      _buildMacroStat(
                        'Protein',
                        _calculatedProteinG,
                        Colors.blue,
                      ),
                      _buildMacroStat('Carbs', _calculatedCarbsG, Colors.green),
                      _buildMacroStat('Fat', _calculatedFatG, Colors.orange),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 15),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: widget.onCancel,
                      icon: const Icon(Icons.cancel),
                      label: const Text('Cancel'),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 40),
                        foregroundColor: Colors.grey,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _save,
                      icon: const Icon(Icons.add),
                      label: const Text('Add'),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 40),
                        backgroundColor: Colors.orange.shade600,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ],
    );
  }
  Widget _buildMacroStat(String label, double value, Color color) {
    return Column(
      children: [
        Text(
          value.toStringAsFixed(1),
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
      ],
    );
  }
}
