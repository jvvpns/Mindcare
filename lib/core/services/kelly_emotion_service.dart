import '../constants/app_constants.dart';

/// Analyzes user message text and Gemini response sentiment
/// to determine which Kelly animation to display.
class KellyEmotionService {
  KellyEmotionService._();

  // ── Keyword maps ──────────────────────────────────────────────────────────
  static const _sadKeywords = [
    'sad', 'cry', 'crying', 'depressed', 'hopeless', 'lonely', 'alone',
    'heartbroken', 'upset', 'devastated', 'miserable', 'down', 'low',
    'tired', 'exhausted', 'drained', 'burned out', 'burnout',
  ];

  static const _excitedKeywords = [
    'excited', 'amazing', 'awesome', 'great', 'fantastic', 'wonderful',
    'happy', 'joy', 'yay', 'passed', 'aced', 'graduated', 'done',
    'finished', 'thank you', 'thanks', 'love', 'best day',
  ];

  static const _concernedKeywords = [
    'scared', 'afraid', 'anxious', 'anxiety', 'panic', 'worried',
    'fear', 'nervous', 'stress', 'stressed', 'overwhelmed', 'cant cope',
    "can't cope", 'too much', 'breaking down', 'help',
  ];

  static const _surprisedKeywords = [
    'what', 'really', 'seriously', 'omg', 'no way', 'unbelievable',
    'surprised', 'shocked', 'unexpected', 'wait', 'huh',
  ];

  static const _happyKeywords = [
    'good', 'okay', 'fine', 'better', 'improving', 'well', 'nice',
    'calm', 'relaxed', 'peaceful', 'relieved', 'grateful',
  ];

  // ── Crisis check ──────────────────────────────────────────────────────────
  static bool isCrisis(String message) {
    final lower = message.toLowerCase();
    return AppConstants.crisisKeywords.any((k) => lower.contains(k));
  }

  // ── Primary emotion detector ──────────────────────────────────────────────
  /// Pass the user's message to get the appropriate Kelly emotion string.
  /// Returns one of the AppConstants.kelly* constants.
  static String detectEmotion(String userMessage) {
    final lower = userMessage.toLowerCase();

    if (isCrisis(lower)) return AppConstants.kellyConcerned;

    if (_sadKeywords.any((k) => lower.contains(k))) {
      return AppConstants.kellySad;
    }
    if (_excitedKeywords.any((k) => lower.contains(k))) {
      return AppConstants.kellyExcited;
    }
    if (_concernedKeywords.any((k) => lower.contains(k))) {
      return AppConstants.kellyConcerned;
    }
    if (_surprisedKeywords.any((k) => lower.contains(k))) {
      return AppConstants.kellySurprised;
    }
    if (_happyKeywords.any((k) => lower.contains(k))) {
      return AppConstants.kellyHappy;
    }

    return AppConstants.kellyDefault;
  }

  // ── Emotion to asset path ─────────────────────────────────────────────────
  /// Returns the asset path for Kelly's animation frame based on emotion.
  /// In Phase 4, swap these paths for Rive/Lottie animation file paths.
  static String emotionToAsset(String emotion) {
    switch (emotion) {
      case 'happy':     return 'assets/images/kelly/kelly_happy.png';
      case 'sad':       return 'assets/images/kelly/kelly_sad.png';
      case 'excited':   return 'assets/images/kelly/kelly_excited.png';
      case 'concerned': return 'assets/images/kelly/kelly_concerned.png';
      case 'calm':      return 'assets/images/kelly/kelly_calm.png';
      case 'surprised': return 'assets/images/kelly/kelly_surprised.png';
      default:          return 'assets/images/kelly/kelly_default.png';
    }
  }

  // ── Emotion to Rive animation trigger ─────────────────────────────────────
  /// Returns the Rive state machine trigger name for Kelly's emotion.
  /// Use this in Phase 4 when Rive animation is integrated.
  static String emotionToRiveTrigger(String emotion) {
    switch (emotion) {
      case 'happy':     return 'triggerHappy';
      case 'sad':       return 'triggerSad';
      case 'excited':   return 'triggerExcited';
      case 'concerned': return 'triggerConcerned';
      case 'calm':      return 'triggerCalm';
      case 'surprised': return 'triggerSurprised';
      default:          return 'triggerIdle';
    }
  }

  // ── Mood Index → Kelly emotion ─────────────────────────────────────────────
  /// Maps today's Dashboard mood index (0–3) to a Kelly emotion string.
  /// 0 = Happy 😄  → kellyHappy
  /// 1 = Angry 😡  → kellyConcerned
  /// 2 = Sleepy 😴 → kellySad
  /// 3 = Bored 😒  → kellyDefault
  static String fromMoodIndex(int index) {
    switch (index) {
      case 0:  return AppConstants.kellyHappy;
      case 1:  return AppConstants.kellyConcerned;
      case 2:  return AppConstants.kellySad;
      default: return AppConstants.kellyDefault;
    }
  }
}