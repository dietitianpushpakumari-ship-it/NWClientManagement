import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:nutricare_client_management/core/localization/language_config.dart';

class AiTranslationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Dynamically fetches config and translates [text].
  Future<Map<String, String>> translateContent(String text) async {
    if (text.trim().isEmpty) return {};

    // 1. Fetch Configuration from Firestore
    final doc = await _firestore.collection('configurations').doc('system_settings').get();
    final data = doc.data();

    if (data == null || data['translationApiKey'] == null || data['translationApiKey'].toString().isEmpty) {
      print("❌ AI Service Error: No API Key configured in System Settings.");
      return {};
    }

    final String apiKey = data['translationApiKey'];
    final String modelName = data['translationModel'] ?? 'gemini-1.5-flash';

    // 2. Initialize Model dynamically
    final model = GenerativeModel(
      model: modelName,
      apiKey: apiKey,
      generationConfig: GenerationConfig(responseMimeType: 'application/json', temperature: 0.2),
    );

    // 3. Prepare Prompt
    final targets = supportedLanguageCodes.where((c) => c != 'en').toList();
    if (targets.isEmpty) return {};

    print("🤖 AI Translation ($modelName) Started for: '$text'");

    final prompt = """
      You are a professional medical & nutrition translator.
      Translate the following text: "$text"
      Target Languages: ${targets.join(', ')}
      Return ONLY a JSON object where keys are language codes and values are translations.
      Example Output: {"hi": "...", "od": "..."}
      Do not include Markdown.
    """;

    try {
      final content = [Content.text(prompt)];
      final response = await model.generateContent(content);
      var jsonString = response.text ?? "";

      // Sanitize
      jsonString = jsonString.replaceAll(RegExp(r'^```json\s*'), '').replaceAll(RegExp(r'\s*```$'), '');
      jsonString = jsonString.trim();

      final Map<String, dynamic> parsed = jsonDecode(jsonString);
      return parsed.map((key, value) => MapEntry(key, value.toString()));

    } catch (e) {
      print("❌ Translation Error: $e");
      return {};
    }
  }
}