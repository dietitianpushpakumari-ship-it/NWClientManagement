import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:nutricare_client_management/modules/master/model/diet_plan_item_model.dart';
import 'package:nutricare_client_management/modules/master/model/food_item.dart';

import '../../modules/master/screen/master_diet_plan_entry_page.dart';

class AlternativeManagerModal extends StatefulWidget {
  final DietPlanItemModel item;
  final List<FoodItem> allFoodItems;
  final void Function(FoodItemAlternative) onAddAlternative;
  final void Function(FoodItemAlternative) onRemoveAlternative;

  const AlternativeManagerModal({
    super.key,
    required this.item,
    required this.allFoodItems,
    required this.onAddAlternative,
    required this.onRemoveAlternative,
  });

  @override
  State<AlternativeManagerModal> createState() =>
      _AlternativeManagerModalState();
}
class _AlternativeManagerModalState extends State<AlternativeManagerModal> {
  // Local flag to control the visibility of the Add Alternative form
  bool _isAddingNew = false;

  void _startAddingNew() {
    setState(() {
      _isAddingNew = true;
    });
  }

  void _finishAddingNew() {
    // 🎯 FIX: Only call setState to hide the form if the widget is still mounted
    if (mounted) {
      setState(() {
        _isAddingNew = false;
      });
    }
  }

  // 🎯 FIX APPLIED HERE: Delay the hiding of the form until the next frame
  void _onAlternativeAdded(FoodItemAlternative alternative) {
    // 1. Trigger parent state update immediately
    widget.onAddAlternative(alternative);

    // 2. Wait until the end of the current frame (where the parent rebuild happens)
    //    before calling setState to hide the form. This guarantees the list reads
    //    the new, updated 'item' property passed by the parent rebuild.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _finishAddingNew();
    });
  }

  @override
  Widget build(BuildContext context) {
    // The main item's information
    final mainItem = widget.item;
    final alternatives = mainItem.alternatives;

    return Padding(
      // Only pad for the keyboard when the 'add' form is visible
      padding: EdgeInsets.only(
        bottom: _isAddingNew ? MediaQuery
            .of(context)
            .viewInsets
            .bottom : 0,
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
        constraints: BoxConstraints(
          maxHeight: MediaQuery
              .of(context)
              .size
              .height * 0.9,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(25.0)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Header Section ---
            Text(
              'Manage Alternatives for',
              style: Theme
                  .of(context)
                  .textTheme
                  .titleLarge,
            ),
            Text(
              '${mainItem.foodItemName} (${mainItem.quantity.toStringAsFixed(
                  1)} ${mainItem.unit})',
              style: Theme
                  .of(
                context,
              )
                  .textTheme
                  .titleMedium
                  ?.copyWith(color: Colors.blueGrey),
            ),
            const Divider(),

            // --- Alternatives List Section ---
            if (alternatives.isEmpty && !_isAddingNew)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20.0),
                child: Center(
                  child: Text(
                    'No alternatives added yet.',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              ),

            if (!_isAddingNew && alternatives.isNotEmpty)
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: alternatives.length,
                  itemBuilder: (context, index) {
                    final alternative = alternatives[index];
                    return Card(
                      color: Colors.orange.shade50,
                      margin: const EdgeInsets.only(bottom: 8.0),
                      child: ListTile(
                        title: Text(alternative.foodItemName),
                        subtitle: Text(alternative.displayQuantity),
                        trailing: IconButton(
                          icon: const Icon(
                            Icons.delete_forever,
                            color: Colors.red,
                          ),
                          onPressed: () {
                            // Call the removal callback
                            widget.onRemoveAlternative(alternative);
                            // Parent state updates, which forces a rebuild of this modal
                            // with the new, shorter alternatives list.
                          },
                        ),
                      ),
                    );
                  },
                ),
              ),

            // --- Action and Add Form Section ---
            const SizedBox(height: 10),
            if (!_isAddingNew)
              ElevatedButton.icon(
                onPressed: _startAddingNew,
                icon: const Icon(Icons.add),
                label: const Text('Add New Alternative'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 45),
                  backgroundColor: Colors.orange.shade600,
                  foregroundColor: Colors.white,
                ),
              )
            else
            // The Add Alternative Form is displayed here when _isAddingNew is true
              AlternativeEntryForm(
                foodItems: widget.allFoodItems,
                onSave: _onAlternativeAdded,
                onCancel: _finishAddingNew,
              ),
            const SizedBox(height: 5),
          ],
        ),
      ),
    );
  }
}
