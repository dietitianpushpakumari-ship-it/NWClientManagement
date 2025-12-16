// lib/helper/lab_vitals_data.dart

class LabTestConfig {
  final String displayName;
  final String unit;
  final String category;
  final double? minRange; // 🎯 NEW: Minimum healthy value (inclusive)
  final double? maxRange; // 🎯 NEW: Maximum healthy value (inclusive)
  final bool isReverseLogic; // e.g., HDL where higher is better

  const LabTestConfig({
    required this.displayName,
    required this.unit,
    required this.category,
    this.minRange,
    this.maxRange,
    this.isReverseLogic = false,
  });

  // Helper to get range string for display
  String get referenceRangeDisplay {
    if (minRange != null && maxRange != null) {
      return '$minRange - $maxRange';
    } else if (maxRange != null) {
      return '< $maxRange';
    } else if (minRange != null) {
      return '> $minRange';
    }
    return 'N/A';
  }
}

class LabVitalsData {
  // 1. Define the categories strictly to ensure order
  static const List<String> labCategories = [
    'Hematology',
    'Diabetic Profile',
    'Lipid Profile',
    'Thyroid Profile',
    'Liver Function',
    'Kidney Function',
    'Vitamins & Minerals'
  ];

  // 2. Define the Map of all tests needed by the UI with numeric ranges
  static const Map<String, LabTestConfig> allLabTests = {
    // --- Hematology ---
    'hemoglobin': LabTestConfig(displayName: 'Hemoglobin', unit: 'g/dL', category: 'Hematology', minRange: 12.0, maxRange: 15.5),
    'rbc_count': LabTestConfig(displayName: 'RBC Count', unit: 'mil/uL', category: 'Hematology', minRange: 4.5, maxRange: 5.5),
    'wbc_count': LabTestConfig(displayName: 'WBC Count', unit: '/cumm', category: 'Hematology', minRange: 4000.0, maxRange: 11000.0),
    'platelet_count': LabTestConfig(displayName: 'Platelet Count', unit: 'lakh/cumm', category: 'Hematology', minRange: 150000.0, maxRange: 450000.0),

    // --- Diabetic ---
    'fbs': LabTestConfig(displayName: 'Fasting Blood Sugar', unit: 'mg/dL', category: 'Diabetic Profile', maxRange: 99.0),
    'ppbs': LabTestConfig(displayName: 'Post Prandial (PPBS)', unit: 'mg/dL', category: 'Diabetic Profile', maxRange: 140.0),
    'hba1c': LabTestConfig(displayName: 'HbA1c', unit: '%', category: 'Diabetic Profile', maxRange: 5.7),
    'insulin_fasting': LabTestConfig(displayName: 'Insulin Fasting', unit: 'mIU/L', category: 'Diabetic Profile', maxRange: 25.0),

    // --- Lipid Profile ---
    'total_cholesterol': LabTestConfig(displayName: 'Total Cholesterol', unit: 'mg/dL', category: 'Lipid Profile', maxRange: 200.0),
    'hdl_cholesterol': LabTestConfig(displayName: 'HDL (Good) Cholesterol', unit: 'mg/dL', category: 'Lipid Profile', minRange: 40.0, isReverseLogic: true), // Higher is better
    'ldl_cholesterol': LabTestConfig(displayName: 'LDL (Bad) Cholesterol', unit: 'mg/dL', category: 'Lipid Profile', maxRange: 100.0),
    'triglycerides': LabTestConfig(displayName: 'Triglycerides', unit: 'mg/dL', category: 'Lipid Profile', maxRange: 150.0),

    // --- Thyroid ---
    'tsh': LabTestConfig(displayName: 'TSH', unit: 'uIU/mL', category: 'Thyroid Profile', minRange: 0.5, maxRange: 5.0),
    // ... T3/T4 ranges are often complex, leaving them without min/max for safety or assume general range:
    't3': LabTestConfig(displayName: 'T3 (Triiodothyronine)', unit: 'ng/dL', category: 'Thyroid Profile', minRange: 80.0, maxRange: 220.0),
    't4': LabTestConfig(displayName: 'T4 (Thyroxine)', unit: 'ug/dL', category: 'Thyroid Profile', minRange: 4.5, maxRange: 12.0),

    // --- Liver Function ---
    'sgot': LabTestConfig(displayName: 'SGOT (AST)', unit: 'U/L', category: 'Liver Function', maxRange: 35.0),
    'sgpt': LabTestConfig(displayName: 'SGPT (ALT)', unit: 'U/L', category: 'Liver Function', maxRange: 40.0),
    'bilirubin_total': LabTestConfig(displayName: 'Total Bilirubin', unit: 'mg/dL', category: 'Liver Function', maxRange: 1.0),

    // --- Kidney Function ---
    'creatinine': LabTestConfig(displayName: 'Serum Creatinine', unit: 'mg/dL', category: 'Kidney Function', maxRange: 1.2),
    'urea': LabTestConfig(displayName: 'Blood Urea', unit: 'mg/dL', category: 'Kidney Function', maxRange: 40.0),
    'uric_acid': LabTestConfig(displayName: 'Uric Acid', unit: 'mg/dL', category: 'Kidney Function', maxRange: 7.0),

    // --- Vitamins ---
    'vitamin_d': LabTestConfig(displayName: 'Vitamin D Total', unit: 'ng/mL', category: 'Vitamins & Minerals', minRange: 30.0), // Min 30 ng/mL is standard goal
    'vitamin_b12': LabTestConfig(displayName: 'Vitamin B12', unit: 'pg/mL', category: 'Vitamins & Minerals', minRange: 200.0, maxRange: 900.0),
    'calcium': LabTestConfig(displayName: 'Calcium', unit: 'mg/dL', category: 'Vitamins & Minerals', minRange: 8.5, maxRange: 10.2),
    'iron': LabTestConfig(displayName: 'Serum Iron', unit: 'mcg/dL', category: 'Vitamins & Minerals', minRange: 60.0, maxRange: 170.0),
  };
}