class LabTestConfig {
  final String displayName;
  final String unit;
  final String category;

  const LabTestConfig({
    required this.displayName,
    required this.unit,
    required this.category,
  });
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

  // 2. Define the Map of all tests needed by the UI
  // Key = ID used in database/API
  // Value = Configuration (Name, Unit, Category)
  static const Map<String, LabTestConfig> allLabTests = {
    // --- Hematology ---
    'hemoglobin': LabTestConfig(displayName: 'Hemoglobin', unit: 'g/dL', category: 'Hematology'),
    'rbc_count': LabTestConfig(displayName: 'RBC Count', unit: 'mil/uL', category: 'Hematology'),
    'wbc_count': LabTestConfig(displayName: 'WBC Count', unit: '/cumm', category: 'Hematology'),
    'platelet_count': LabTestConfig(displayName: 'Platelet Count', unit: 'lakh/cumm', category: 'Hematology'),

    // --- Diabetic ---
    'fbs': LabTestConfig(displayName: 'Fasting Blood Sugar', unit: 'mg/dL', category: 'Diabetic Profile'),
    'ppbs': LabTestConfig(displayName: 'Post Prandial (PPBS)', unit: 'mg/dL', category: 'Diabetic Profile'),
    'hba1c': LabTestConfig(displayName: 'HbA1c', unit: '%', category: 'Diabetic Profile'),
    'insulin_fasting': LabTestConfig(displayName: 'Insulin Fasting', unit: 'mIU/L', category: 'Diabetic Profile'),

    // --- Lipid Profile ---
    'total_cholesterol': LabTestConfig(displayName: 'Total Cholesterol', unit: 'mg/dL', category: 'Lipid Profile'),
    'hdl_cholesterol': LabTestConfig(displayName: 'HDL (Good) Cholesterol', unit: 'mg/dL', category: 'Lipid Profile'),
    'ldl_cholesterol': LabTestConfig(displayName: 'LDL (Bad) Cholesterol', unit: 'mg/dL', category: 'Lipid Profile'),
    'triglycerides': LabTestConfig(displayName: 'Triglycerides', unit: 'mg/dL', category: 'Lipid Profile'),

    // --- Thyroid ---
    't3': LabTestConfig(displayName: 'T3 (Triiodothyronine)', unit: 'ng/dL', category: 'Thyroid Profile'),
    't4': LabTestConfig(displayName: 'T4 (Thyroxine)', unit: 'ug/dL', category: 'Thyroid Profile'),
    'tsh': LabTestConfig(displayName: 'TSH', unit: 'uIU/mL', category: 'Thyroid Profile'),

    // --- Liver Function ---
    'sgot': LabTestConfig(displayName: 'SGOT (AST)', unit: 'U/L', category: 'Liver Function'),
    'sgpt': LabTestConfig(displayName: 'SGPT (ALT)', unit: 'U/L', category: 'Liver Function'),
    'bilirubin_total': LabTestConfig(displayName: 'Total Bilirubin', unit: 'mg/dL', category: 'Liver Function'),

    // --- Kidney Function ---
    'creatinine': LabTestConfig(displayName: 'Serum Creatinine', unit: 'mg/dL', category: 'Kidney Function'),
    'urea': LabTestConfig(displayName: 'Blood Urea', unit: 'mg/dL', category: 'Kidney Function'),
    'uric_acid': LabTestConfig(displayName: 'Uric Acid', unit: 'mg/dL', category: 'Kidney Function'),

    // --- Vitamins ---
    'vitamin_d': LabTestConfig(displayName: 'Vitamin D Total', unit: 'ng/mL', category: 'Vitamins & Minerals'),
    'vitamin_b12': LabTestConfig(displayName: 'Vitamin B12', unit: 'pg/mL', category: 'Vitamins & Minerals'),
    'calcium': LabTestConfig(displayName: 'Calcium', unit: 'mg/dL', category: 'Vitamins & Minerals'),
    'iron': LabTestConfig(displayName: 'Serum Iron', unit: 'mcg/dL', category: 'Vitamins & Minerals'),
  };
}