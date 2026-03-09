class AppConstants {
  AppConstants._();

  // App Info
  static const String appName = 'MindCare';
  static const String appVersion = '1.0.0';

  // Supabase
  static const String supabaseUrl = 'YOUR_SUPABASE_URL';
  static const String supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY';

  // Gemini
  static const String geminiApiKey = 'YOUR_GEMINI_API_KEY';

  // Hive Box Names
  static const String moodBoxName = 'mood_logs';
  static const String journalBoxName = 'journal_entries';
  static const String chatBoxName = 'chat_logs';
  static const String settingsBoxName = 'settings';
  static const String assessmentBoxName = 'assessments';

  // Stress Rating
  static const int minStressRating = 1;
  static const int maxStressRating = 5;

  // Burnout Risk Thresholds
  static const double burnoutLow = 0.3;
  static const double burnoutMonitor = 0.6;

  // Crisis Keywords
  static const List<String> crisisKeywords = [
    'suicidal', 'suicide', 'kill myself', 'end my life',
    'self harm', 'self-harm', 'hurt myself', 'want to die',
    'can\'t go on', 'no reason to live',
  ];

  // Data Retention (days)
  static const int moodRetentionDays = 30;
  static const int crisisRetentionDays = 30;

  // TFLite
  static const String tfliteModelPath = 'assets/models/burnout_model.tflite';

  // Pagination
  static const int pageSize = 20;
}