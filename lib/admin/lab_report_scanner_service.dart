import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:nutricare_client_management/admin/lab_test_config_model.dart';

class LabReportScannerService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Scans an image and extracts lab values matching the provided [availableTests].
  Future<Map<String, double>> extractLabData(File imageFile, List<LabTestConfigModel> availableTests) async {
    try {
      // 1. Fetch Configuration from Firestore (Same as AiTranslationService)
      final doc = await _firestore.collection('configurations').doc('system_settings').get();
      final data = doc.data();

      if (data == null || data['translationApiKey'] == null || data['translationApiKey'].toString().isEmpty) {
        print("❌ Lab Scanner Error: No API Key configured in System Settings.");
        return {};
      }

      final String apiKey = data['translationApiKey'];
      // Use configured model or default to flash (efficient for vision)
      final String modelName = data['translationModel'] ?? 'gemini-1.5-flash';

      // 2. Initialize Model dynamically
      final model = GenerativeModel(
        model: modelName,
        apiKey: apiKey,
        generationConfig: GenerationConfig(
          responseMimeType: 'application/json',
          temperature: 0.1, // Low temperature for factual data extraction
        ),
      );

      print("🤖 Lab Report Scan ($modelName) Started...");

      // 3. Prepare Mapping Prompt
      final testListString = availableTests.map((t) => "- ID: ${t.id}, Name: ${t.displayName}, Unit: ${t.unit}").join("\n");

      final prompt = """
        Analyze this medical lab report image. Extract the numeric results for the specific tests listed below.
        
        Target Tests Mapping:
        $testListString

        Instructions:
        1. Find the result value for each Target Test Name in the image.
        2. Map it to the corresponding 'ID'.
        3. Return a JSON object where keys are the 'ID' and values are the numeric results (as doubles).
        4. Ignore tests not in the list or values that are missing/unreadable.
        5. Do not include units in the value, only numbers.
        
        Example Output: {"hemoglobin": 13.5, "fasting_sugar": 95.0}
      """;

      // 4. Prepare Image Content
      final imageBytes = await imageFile.readAsBytes();
      final content = [
        Content.multi([
          TextPart(prompt),
          DataPart('image/jpeg', imageBytes),
        ])
      ];

      // 5. Generate & Parse
      final response = await model.generateContent(content);
      var jsonString = response.text ?? "{}";

      // Sanitize JSON
      jsonString = jsonString.replaceAll(RegExp(r'^```json\s*'), '').replaceAll(RegExp(r'\s*```$'), '');

      final Map<String, dynamic> parsed = jsonDecode(jsonString);
      final Map<String, double> results = {};

      parsed.forEach((key, value) {
        if (value is num) {
          results[key] = value.toDouble();
        } else if (value is String) {
          final v = double.tryParse(value);
          if(v != null) results[key] = v;
        }
      });

      return results;

    } catch (e) {
      print("❌ Lab Scan Error: $e");
      return {};
    }
  }
}