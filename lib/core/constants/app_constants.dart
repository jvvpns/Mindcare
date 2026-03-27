import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConstants {
  AppConstants._();

  static const String appName    = 'HILWAY';
  static const String appTagline = 'Your holistic mental health companion.';

  // ── Supabase ──────────────────────────────────────────────────────────────
  static String get supabaseUrl     => dotenv.get('SUPABASE_URL');
  static String get supabaseAnonKey => dotenv.get('SUPABASE_ANON_KEY');

  // ── Gemini ────────────────────────────────────────────────────────────────
  static String get geminiApiKey    => dotenv.get('GEMINI_API_KEY');
  static const String geminiModel   = 'gemini-1.5-flash';

  // ── Hive Box Names ────────────────────────────────────────────────────────
  static const String boxMoodLogs       = 'mood_logs';
  static const String boxStressRatings  = 'stress_ratings';
  static const String boxChatMessages   = 'chat_messages';
  static const String boxPlannerEntries = 'planner_entries';
  static const String boxAssessments    = 'assessments';
  static const String boxSettings       = 'settings';
  static const String boxUserCache      = 'user_cache';

  // ── Supabase Table Names ──────────────────────────────────────────────────
  static const String tableMoodLogs       = 'mood_logs';
  static const String tableStressRatings  = 'stress_ratings';
  static const String tablePlannerEntries = 'planner_entries';
  static const String tableAssessments    = 'assessments';
  static const String tableSettings       = 'settings';

  // ── Hive Type IDs ─────────────────────────────────────────────────────────
  static const int hiveTypeMoodLog          = 0;
  static const int hiveTypeStressRating     = 1;
  static const int hiveTypeChatMessage      = 2;
  static const int hiveTypePlannerEntry     = 3;
  static const int hiveTypeAssessmentResult = 4;

  // ── App Config ────────────────────────────────────────────────────────────
  static const int  maxChatHistory  = 50;
  static const int  stressScaleMin  = 1;
  static const int  stressScaleMax  = 5;

  // ── Chatbot Disclaimer (shown once to new users) ──────────────────────────
  static const String chatDisclaimerTitle = 'Before you chat with Kelly';
  static const String chatDisclaimer =
      'Your conversations with Kelly are stored only on your device and are '
      'encrypted for your privacy. This data is used solely to personalize '
      'your experience and improve your mental wellness journey. '
      'The developers have no access to your messages at any time.\n\n'
      'Kelly is an AI-powered wellness companion — not a licensed therapist. '
      'If you are in crisis, please reach out to a mental health professional '
      'or use the emergency hotlines provided in the app.';

  // ── Crisis Keywords ───────────────────────────────────────────────────────
  static const List<String> crisisKeywords = [
    'suicidal', 'suicide', 'kill myself', 'end my life', 'want to die',
    'self-harm', 'self harm', 'hurt myself', 'cut myself', 'no reason to live',
    'hopeless', "can't go on", 'cannot go on', 'give up on life',
  ];

  // ── Emergency Hotlines (Philippines) ─────────────────────────────────────
  static const String hotlineNationalMH   = '1553';         // DOH National Mental Health
  static const String hotlineCrisisLine   = '(02) 989-8727'; // In Touch Crisis Line
  static const String hotlineSafeSpace    = '(02) 893-7603'; // Hopeline PH

  // ── Notification Channel ──────────────────────────────────────────────────
  static const String notifChannelId   = 'hilway_reminders';
  static const String notifChannelName = 'Daily Reminders';
  static const String notifChannelDesc = 'Gentle daily reminders for mood check-in and self-care';

  // ── Mood Options ──────────────────────────────────────────────────────────
  static const List<String> moodLabels = [
    'Sad', 'Stressed', 'Neutral', 'Calm', 'Motivated'
  ];
  static const List<String> moodEmojis = [
    '😔', '😰', '😐', '😊', '😄'
  ];

  // ── Kelly Emotion Constants ────────────────────────────────────────────────
  static const String kellyDefault   = 'default';
  static const String kellyHappy     = 'happy';
  static const String kellySad       = 'sad';
  static const String kellyExcited   = 'excited';
  static const String kellyConcerned = 'concerned';
  static const String kellyCalm      = 'calm';
  static const String kellySurprised = 'surprised';

  // ── Tutorial Steps (onboarding walkthrough) ───────────────────────────────
  static const List<Map<String, String>> tutorialSteps = [
    {
      'title': 'Welcome to HILWAY',
      'subtitle': 'Your holistic mental health companion',
      'body': 'HILWAY helps you manage stress, track your mood, and find balance '
          'through your nursing journey.',
      'asset': 'assets/images/tutorial_welcome.png',
    },
    {
      'title': 'Meet Kelly',
      'subtitle': 'Your wellness companion',
      'body': 'Kelly the capybara is here to listen, support, and guide you '
          'through your day. Chat with Kelly anytime you need a friendly ear.',
      'asset': 'assets/images/tutorial_kelly.png',
    },
    {
      'title': 'Track your mood',
      'subtitle': 'Check in daily',
      'body': 'Log how you feel each day and track your stress levels. '
          'HILWAY helps you spot patterns and understand your emotional health.',
      'asset': 'assets/images/tutorial_mood.png',
    },
    {
      'title': 'Stay on top of academics',
      'subtitle': 'Plan smarter',
      'body': 'Manage your clinical duties, exams, and to-dos all in one place. '
          'HILWAY keeps your academic life organized so you can focus on what matters.',
      'asset': 'assets/images/tutorial_planner.png',
    },
    {
      'title': 'You are not alone',
      'subtitle': 'Help is always here',
      'body': 'When things get tough, HILWAY connects you to coping tools, '
          'mental health resources, and professional support in Roxas City.',
      'asset': 'assets/images/tutorial_support.png',
    },
  ];
}