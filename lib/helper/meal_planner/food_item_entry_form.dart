import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nutricare_client_management/modules/master/model/diet_plan_item_model.dart';
import 'package:nutricare_client_management/modules/master/model/food_item.dart';

class FoodItemEntryForm extends StatefulWidget {
  final List<FoodItem> foodItems;

  const FoodItemEntryForm({super.key, required this.foodItems});

  @override
  State<FoodItemEntryForm> createState() => _FoodItemEntryFormState();
}

class _FoodItemEntryFormState extends State<FoodItemEntryForm> {
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

    final Map<String, double> macros = _selectedFoodItem!.calculateMacros(
      quantity,
    );

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

      final newItem = DietPlanItemModel(
        id: 'item_${DateTime
            .now()
            .millisecondsSinceEpoch}',
        foodItemId: _selectedFoodItem!.id,
        foodItemName: _selectedFoodItem!.enName,
        quantity: quantity,
        unit: _selectedFoodItem!.servingUnitId,
      );
      Navigator.of(context).pop(newItem);
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
    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          16,
          16,
          16,
          MediaQuery
              .of(context)
              .viewInsets
              .bottom,
        ),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Add Food Item',
                style: Theme
                    .of(context)
                    .textTheme
                    .titleLarge,
              ),
              const SizedBox(height: 20),
              DropdownButtonFormField<FoodItem>(
                value: _selectedFoodItem,
                decoration: InputDecoration(
                  labelText: 'Select Food Item',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
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
              const SizedBox(height: 20),
              Container(
                decoration: BoxDecoration(
                  color: Colors.teal.shade50,
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
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _save,
                icon: const Icon(Icons.check_circle_outline),
                label: const Text('Confirm Item and Quantity'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  backgroundColor: Colors.teal.shade600,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
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
