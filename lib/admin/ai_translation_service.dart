import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:http/http.dart' as http;
import 'package:nutricare_client_management/core/localization/language_config.dart';

class AiTranslationService {
  // ⚠️ REPLACE WITH YOUR ACTUAL GEMINI API KEY
  // Get it for free at https://aistudio.google.com/
  static const String _apiKey = "AIzaSyDY9gqF_6y7bVeZe0MqmEAtHdWUPzAwgQg";

  late final GenerativeModel _model;

  AiTranslationService() {
    _model = GenerativeModel(
      model: 'gemini-2.5-flash',
      apiKey: _apiKey,
      generationConfig: GenerationConfig(responseMimeType: 'application/json'),
    );
  }

  /// Translates [text] into all languages defined in [supportedLanguageCodes] (except English).
  /// Returns a Map<String, String> where Key = Language Code (e.g., 'hi') and Value = Translated Text.
  Future<Map<String, String>> translateContent(String text) async {
    if (text.trim().isEmpty) return {};

    // 1. Identify target languages (exclude 'en')
    final targets = supportedLanguageCodes.where((c) => c != 'en').toList();
    if (targets.isEmpty) return {};

    // 2. Construct the Prompt
    final prompt = """
      You are a professional medical & nutrition translator.
      Translate the following text: "$text"
      
      Target Languages: ${targets.join(', ')}
      
      Return ONLY a JSON object where keys are language codes and values are translations.
      Example Output format: {"hi": "...", "od": "..."}
      Use simple, common terms used in daily Indian conversation.
    """;

    try {
      // 3. Call AI
      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);

      final jsonString = response.text;
      if (jsonString == null) throw Exception("Empty response from AI");

      // 4. Parse JSON
      final Map<String, dynamic> parsed = jsonDecode(jsonString);

      // Convert to Map<String, String>
      return parsed.map((key, value) => MapEntry(key, value.toString()));

    } catch (e) {
      print("Translation Error: $e");
      // Return empty map on failure so app doesn't crash
      return {};
    }
  }


  Future<void> debugPrintAvailableModels() async {
    final url = Uri.parse('https://generativelanguage.googleapis.com/v1beta/models?key=$_apiKey');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List models = data['models'];

        print("---------------- AVAILABLE MODELS ----------------");
        for (var m in models) {
          // Filter for models that support 'generateContent'
          if (m['supportedGenerationMethods'].contains('generateContent')) {
            print("✅ ${m['name'].toString().replaceAll('models/', '')}");
          }
        }
        print("--------------------------------------------------");
      } else {
        print("❌ Error fetching models: ${response.body}");
      }
    } catch (e) {
      print("❌ Connection Error: $e");
    }
  }
}