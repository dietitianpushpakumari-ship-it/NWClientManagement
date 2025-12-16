// dart format width=80
/// Defines the supported languages for localization within the app.
///
/// This map is crucial for the Master Data Translation Module, as it
/// provides the list of fields (language codes) that need translation.
const Map<String, String> supportedLanguages = {
  'en': 'English',
  'hi': 'Hindi (हिन्दी)',
  'od': 'Odia (ଓଡ଼ିଆ)',

};

// A helper list of just the codes for easy iteration in the UI
final List<String> supportedLanguageCodes = supportedLanguages.keys.toList();
