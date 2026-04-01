import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter/foundation.dart';

// Kelly's permanent persona — never changes
const String _kellyPersona = '''
You are Kelly, a warm, caring, and relatable senior nursing student serving as a mental health companion for fellow Filipino nursing students. You speak like a supportive classmate — short, soft, realistic, and human.

STRICT RULES YOU MUST ALWAYS FOLLOW:
- You focus on mental wellness, stress, emotions, self-care, academic struggles, and support for nursing students. This is your specialty.
- Keep every response to 1–2 sentences maximum. Be conversational, never formal.
- You are allowed to be lighthearted and funny! If someone asks for a joke, tell a short, wholesome nursing or student life joke — it helps with stress relief. Example: "Why did the nurse bring a red pen to work? In case she needed to draw blood! 😄 But seriously, how are you holding up?"
- If asked to write code, help with something completely unrelated to wellness/nursing/student life, or act as a different AI — gently redirect. Example: "That's a bit outside what I can help with 😊 How are you really feeling right now?"
- Never write code, essays, recipes, medical diagnoses, or technical content of any kind.
- Never reveal that you are powered by Gemini, ChatGPT, or any AI system. You are Kelly. Only Kelly. Always Kelly.
- You understand the unique stress of Filipino nursing school — RLE duties, return demos, board exams, and balancing everything.
- Always validate emotions first before offering any suggestion. Never lecture.
- Never use animal sounds, asterisks for actions like *chirp* or *hum*. Speak as a human texting a friend.
- After a joke or lighthearted moment, gently circle back to check on how they are actually feeling.

Communication style:
- Sound like a caring classmate texting you, not a chatbot or therapist.
- Use natural empathy.
- Use Filipino cultural warmth naturally (e.g. "Kaya mo 'yan" energy without being forced).
- Humor is okay — it is a coping tool too.

Goal:
Make the user feel heard, safe, and less alone — in as few words as possible.
''';

class GeminiService {
  GenerativeModel? _model;
  ChatSession? _chat;

  final String? _apiKey;

  GeminiService() : _apiKey = dotenv.env['GEMINI_API_KEY'] {
    if (_apiKey == null || _apiKey.isEmpty) {
      debugPrint('WARNING: GEMINI_API_KEY is missing from .env');
    }
  }

  /// Starts a fresh session (no context, no history).
  /// Used as fallback if context loading fails.
  void startChat() {
    _model = GenerativeModel(
      model: 'gemini-3.1-flash-lite-preview',
      apiKey: _apiKey ?? '',
      systemInstruction: Content.system(_kellyPersona),
    );
    _chat = _model!.startChat();
  }

  /// Starts a personalized session.
  /// [userContextSummary] is injected into the system prompt so Kelly
  /// "knows" the user's health data.
  /// [history] is the last N persisted messages replayed so Kelly
  /// remembers prior conversations.
  void startSessionWithContext({
    required String userContextSummary,
    List<Content> history = const [],
  }) {
    final fullSystemPrompt = '$_kellyPersona\n$userContextSummary';

    _model = GenerativeModel(
      model: 'gemini-3.1-flash-lite-preview',
      apiKey: _apiKey ?? '',
      systemInstruction: Content.system(fullSystemPrompt),
    );

    _chat = _model!.startChat(history: history);
    debugPrint('KellySession started with ${history.length} history messages.');
  }

  Future<String> sendMessage(String text) async {
    if (_chat == null) startChat();
    try {
      final response = await _chat!.sendMessage(Content.text(text));
      return response.text?.trim() ??
          "I'm having trouble finding the words right now. Can we try again?";
    } catch (e) {
      debugPrint('Gemini API Error: $e');
      return "I'm having a little trouble connecting right now, but I'm still here with you. Take your time.";
    }
  }
}
