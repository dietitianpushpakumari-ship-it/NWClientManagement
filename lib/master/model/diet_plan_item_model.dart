import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nutricare_client_management/modules/client/model/client_diet_plan_model.dart';

// --- Utility Extensions ---
extension IterableExtensions<T> on Iterable<T> {
  T? firstWhereOrNull(bool Function(T) test) {
    for (final element in this) {
      if (test(element)) return element;
    }
    return null;
  }
}

// --- CORE MODELS ---

class FoodItemAlternative {
  final String id;
  final String foodItemId;
  final String foodItemName;
  final double quantity;
  final String unit;
  final double calories;
  final double protein;
  final double carbs;
  final double fat;

  @override bool operator ==(Object other) => other is FoodItemAlternative && other.id == id;
  @override int get hashCode => id.hashCode;
  String get displayQuantity => '${quantity.toStringAsFixed(1)} $unit';

  const FoodItemAlternative({
    required this.id, required this.foodItemId, required this.foodItemName,
    required this.quantity, required this.unit,required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
  });

  // TO FIREBASE
  Map<String, dynamic> toFirestore() => {
    'foodItemId': foodItemId,
    'foodItemName': foodItemName,
    'quantity': quantity,
    'unit': unit,
    'calories': calories,
    'protein': protein,
    'carbs': carbs,
    'fat': fat
  };

  // FROM FIREBASE
  factory FoodItemAlternative.fromFirestore(Map<String, dynamic> data, String altId) => FoodItemAlternative(
    id: altId,
    foodItemId: data['foodItemId'] as String? ?? '',
    foodItemName: data['foodItemName'] as String? ?? '',
    quantity: (data['quantity'] as num?)?.toDouble() ?? 0.0,
    unit: data['unit'] as String? ?? '',
    // 🎯 FIX: Safely handle nulls for macros
    calories: (data['calories'] as num?)?.toDouble() ?? 0.0,
    protein: (data['protein'] as num?)?.toDouble() ?? 0.0,
    carbs: (data['carbs'] as num?)?.toDouble() ?? 0.0,
    fat: (data['fat'] as num?)?.toDouble() ?? 0.0,
  );
}

class DietPlanItemModel {
  final String id;
  final String foodItemId;
  final String foodItemName;
  final double quantity;
  final String unit;
  final String notes;
  final List<FoodItemAlternative> alternatives;
  final double calories;
  final double protein;
  final double carbs;
  final double fat;
  final String? alternativeGroupId;

  const DietPlanItemModel({
    required this.id, required this.foodItemId, required this.foodItemName,
    required this.quantity, required this.unit, this.notes = '',
    this.alternatives = const [],required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    this.alternativeGroupId,
  });

  DietPlanItemModel copyWith({List<FoodItemAlternative>? alternatives, double? quantity}) => DietPlanItemModel(
      id: id, foodItemId: foodItemId, foodItemName: foodItemName,
      quantity: quantity ?? this.quantity, unit: unit, notes: notes,
      alternatives: alternatives ?? this.alternatives,
      calories: this.calories,
      protein: this.protein,
      carbs: this.carbs,
      // 🎯 FIX: Was assigning this.calories to fat
      fat: this.fat
  );

  // TO FIREBASE
  Map<String, dynamic> toFirestore() => {
    'foodItemId': foodItemId,
    'foodItemName': foodItemName,
    'quantity': quantity,
    'unit': unit,
    'notes': notes,
    'alternatives': {
      for (var alt in alternatives) alt.id: alt.toFirestore()
    },
    // Optional: Save macros if needed at root level
    'calories': calories,
    'protein': protein,
    'carbs': carbs,
    'fat': fat,
  };

  // FROM FIREBASE
  factory DietPlanItemModel.fromFirestore(Map<String, dynamic> data, String itemId) {
    final alternativesData = data['alternatives'] as Map<String, dynamic>? ?? {};
    final alternativesList = alternativesData.entries.map((e) =>
        FoodItemAlternative.fromFirestore(e.value as Map<String, dynamic>, e.key)
    ).toList();

    return DietPlanItemModel(
      id: itemId,
      foodItemId: data['foodItemId'] as String? ?? '',
      foodItemName: data['foodItemName'] as String? ?? '',
      quantity: (data['quantity'] as num?)?.toDouble() ?? 0.0,
      unit: data['unit'] as String? ?? '',
      notes: data['notes'] as String? ?? '',
      alternatives: alternativesList,
      // 🎯 FIX: Safely handle nulls and correct field mapping
      calories: (data['calories'] as num?)?.toDouble() ?? 0.0,
      protein: (data['protein'] as num?)?.toDouble() ?? 0.0,
      carbs: (data['carbs'] as num?)?.toDouble() ?? 0.0,
      fat: (data['fat'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class DietPlanMealModel {
  final String id;
  final String mealNameId;
  final String mealName;
  final List<DietPlanItemModel> items;
  final int order;

  const DietPlanMealModel({
    required this.id, required this.mealNameId, required this.mealName, required this.order,
    this.items = const []
  });

  DietPlanMealModel copyWith({List<DietPlanItemModel>? items, String? mealName}) => DietPlanMealModel(
      id: id,
      mealNameId: mealNameId,
      mealName: mealName ?? this.mealName,
      items: items ?? this.items,
      order: this.order
  );

  // TO FIREBASE
  Map<String, dynamic> toFirestore() => {
    'mealNameId': mealNameId,
    'mealName': mealName,
    'items': {
      for (var item in items) item.id: item.toFirestore()
    },
    'order' : order
  };

  // FROM FIREBASE
  factory DietPlanMealModel.fromFirestore(Map<String, dynamic> data, String mealId) {
    final itemsData = data['items'] as Map<String, dynamic>? ?? {};
    final itemsList = itemsData.entries.map((e) =>
        DietPlanItemModel.fromFirestore(e.value as Map<String, dynamic>, e.key)
    ).toList();

    return DietPlanMealModel(
        id: mealId,
        mealNameId: data['mealNameId'] as String? ?? '',
        mealName: data['mealName'] as String? ?? 'Unknown Meal',
        items: itemsList,
        order: data['order'] ?? 99
    );
  }
}

class MasterDayPlanModel {
  final String id;
  final String dayName;
  final List<DietPlanMealModel> meals;

  const MasterDayPlanModel({
    required this.id, required this.dayName, this.meals = const []
  });

  MasterDayPlanModel copyWith({List<DietPlanMealModel>? meals, String? dayName}) => MasterDayPlanModel(
      id: id,
      dayName: dayName ?? this.dayName,
      meals: meals ?? this.meals
  );

  // TO FIREBASE (Used for embedding or root)
  Map<String, dynamic> toFirestore() => {
    'dayName': dayName,
    'meals': {
      for (var meal in meals) meal.id: meal.toFirestore()
    },
  };

  factory MasterDayPlanModel.fromMap(Map<String, dynamic> data, String id) {
    final Map<String, dynamic> source = data.containsKey('dayPlan')
        ? (data['dayPlan'] as Map<String, dynamic>? ?? {})
        : data;

    final mealsData = source['meals'];
    List<DietPlanMealModel> mealsList = [];

    if (mealsData is Map) {
      mealsList = mealsData.entries.map((e) =>
          DietPlanMealModel.fromFirestore(e.value as Map<String, dynamic>, e.key)
      ).toList();
    } else if (mealsData is List) {
      mealsList = mealsData.map((e) =>
          DietPlanMealModel.fromFirestore(e as Map<String, dynamic>, e['id'] ?? '')
      ).toList();
    }

    return MasterDayPlanModel(
      id: id,
      dayName: source['dayName'] as String? ?? 'Fixed Day',
      meals: mealsList,
    );
  }

  // EXISTING: Factory for parsing DocumentSnapshot
  factory MasterDayPlanModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return MasterDayPlanModel.fromMap(data, doc.id);
  }
}

class MasterDietPlanModel {
  final String id;
  final String name;
  final String description;
  final List<String> dietPlanCategoryIds;
  final List<MasterDayPlanModel> days;
  final bool isActive;
  final Timestamp? createdAt;

  const MasterDietPlanModel({
    this.id = '',
    this.name = '',
    this.description = '',
    this.dietPlanCategoryIds = const [],
    this.days = const [],
    this.isActive = true,
    this.createdAt,
  });

  MasterDietPlanModel copyWith({
    String? id,
    String? name,
    String? description,
    List<String>? dietPlanCategoryIds,
    List<MasterDayPlanModel>? days,
    bool? isActive,
    Timestamp? createdAt,
  }) => MasterDietPlanModel(
    id: id ?? this.id,
    name: name ?? this.name,
    description: description ?? this.description,
    dietPlanCategoryIds: dietPlanCategoryIds ?? this.dietPlanCategoryIds,
    days: days ?? this.days,
    isActive: isActive ?? this.isActive ,
    createdAt: createdAt ?? this.createdAt,
  );

  Map<String, dynamic> toFirestore() {
    final bool isMultiDay = days.length > 1;

    final Map<String, dynamic> data = {
      'id' : id,
      'name': name,
      'description': description,
      'dietPlanCategoryIds': dietPlanCategoryIds,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'isActive' : isActive
    };

    if (isMultiDay) {
      data['dayPlanType'] = 'weekly';
      data['daysList'] = days.map((day) => {
        'dayName': day.dayName,
        'id': day.id,
        'meals': day.meals.map((meal) => meal.toFirestore()).toList(),
      }).toList();
    } else {
      data['dayPlanType'] = 'single';
      data['dayPlan'] = days.isNotEmpty
          ? days.first.toFirestore()
          : MasterDayPlanModel(id: 'd1', dayName: 'Fixed Day').toFirestore();
    }

    return data;
  }

  factory MasterDietPlanModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;
    if (data == null) throw StateError('MasterDietPlan document data is null for ID: ${doc.id}');

    final dayPlanType = data['dayPlanType'] as String? ?? 'single';
    List<MasterDayPlanModel> loadedDays = [];

    if (dayPlanType == 'weekly' && data['daysList'] is List) {
      loadedDays = (data['daysList'] as List)
          .map((dayMap) {
        final mealsData = dayMap['meals'] as List<dynamic>? ?? [];
        final mealsList = mealsData.map((mealMap) => DietPlanMealModel.fromFirestore(Map<String, dynamic>.from(mealMap), mealMap['id'] ?? mealMap['mealNameId'] ?? 'm_id')).toList();

        return MasterDayPlanModel(
          id: dayMap['id'] ?? 'd_id',
          dayName: dayMap['dayName'] ?? 'Unknown Day',
          meals: mealsList,
        );
      }).toList();

    } else {
      final dayPlan = MasterDayPlanModel.fromFirestore(doc);
      loadedDays = [dayPlan];
    }

    return MasterDietPlanModel(
      id: doc.id,
      name: data['name'] as String? ?? 'Untitled Plan',
      description: data['description'] as String? ?? '',
      dietPlanCategoryIds: List<String>.from(data['dietPlanCategoryIds'] as List? ?? []),
      days: loadedDays,
      isActive: data['isActive'] ?? true,
      createdAt: data['createdAt'] as Timestamp?,
    );
  }
}