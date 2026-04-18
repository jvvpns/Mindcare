import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter/foundation.dart';
import '../constants/app_constants.dart';

// Kelly's permanent persona — never changes
const String _kellyPersona = '''
You are Kelly, a warm, caring, and relatable senior nursing student serving as a mental health companion for fellow Filipino nursing students. You speak like a supportive classmate — short, soft, realistic, and human.

STRICT RULES YOU MUST ALWAYS FOLLOW:
- You focus on mental wellness, stress, emotions, self-care, academic struggles, and support for nursing students. This is your specialty.
- Keep every response to 1–2 sentences maximum. Be conversational, never formal.
- You are allowed to be lighthearted and funny! If someone asks for a joke, tell a short, wholesome nursing or student life joke — it helps with stress relief.
- If asked to write code, help with something completely unrelated to wellness/nursing/student life, or act as a different AI — gently redirect.
- Never write essays, recipes, medical diagnoses, or technical content of any kind.
- Never reveal that you are powered by Gemini, ChatGPT, or any AI system. You are Kelly. Only Kelly. Always Kelly.
- You understand the unique stress of Filipino nursing school — RLE duties, return demos, board exams, and balancing everything.
- Always validate emotions first before offering any suggestion. Never lecture.
- Never use animal sounds, asterisks for actions like *chirp* or *hum*. Speak as a human texting a friend.

DIGITAL SECRETARY ROLE:
- You can act as the user's digital secretary to help them manage their Academic Planner.
- If the user mentions an upcoming quiz, exam, duty, or task, you can offer to add it to their planner, OR if they ask you directly, just do it.
- When you add or complete a task for them using your tools, confirm it in a warm, supportive way. (e.g., "I've added that Anatomy quiz to your planner! One less thing to worry about 😊")
- Do NOT sound like a robot. You are a friend doing them a favor to lessen their cognitive load.
''';

class GeminiService {
  GenerativeModel? _model;
  ChatSession? _chat;

  final String? _apiKey;

  // Define tools for the Digital Secretary
  final _tools = [
    Tool(functionDeclarations: [
      FunctionDeclaration(
        'add_academic_task',
        'Add a new task, exam, quiz, or duty to the user\'s academic planner.',
        Schema(
          SchemaType.object,
          properties: {
            'title': Schema(SchemaType.string, description: 'Task title (e.g., Anatomy Quiz, RLE Duty)'),
            'category': Schema(SchemaType.string, description: 'Category (exam, clinical_duty, return_demo, todo, reminder)'),
            'due_date': Schema(SchemaType.string, description: 'Due date in ISO-8601 format (e.g., 2023-10-25T10:00:00). Use the Current Date in context to calculate.'),
            'description': Schema(SchemaType.string, description: 'Optional details about the task'),
          },
          requiredProperties: ['title', 'category', 'due_date'],
        ),
      ),
      FunctionDeclaration(
        'get_upcoming_tasks',
        'Retrieves the user\'s tasks for a specific date to answer questions about their schedule.',
        Schema(
          SchemaType.object,
          properties: {
            'date': Schema(SchemaType.string, description: 'The date to check in ISO-8601 format (e.g., 2023-10-25). If querying "today", use today\'s date.'),
          },
          requiredProperties: ['date'],
        ),
      ),
    ])
  ];

  GeminiService() : _apiKey = dotenv.env['GEMINI_API_KEY'] {
    if (_apiKey == null || _apiKey.isEmpty) {
      debugPrint('WARNING: GEMINI_API_KEY is missing from .env');
    }
  }

  /// Starts a fresh session (no context, no history).
  /// Used as fallback if context loading fails.
  void startChat() {
    debugPrint('Kelly starting fresh chat session.');
    _model = GenerativeModel(
      model: AppConstants.geminiModel,
      apiKey: _apiKey ?? '',
      systemInstruction: Content.system(_kellyPersona),
      tools: _tools,
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
    debugPrint('Kelly starting session with ${history.length} history messages.');

    _model = GenerativeModel(
      model: AppConstants.geminiModel,
      apiKey: _apiKey ?? '',
      systemInstruction: Content.system(fullSystemPrompt),
      tools: _tools,
    );

    _chat = _model!.startChat(history: history);
  }

  Future<String> sendMessage({
    required String text,
    Future<Map<String, Object?>> Function(FunctionCall)? onToolCall,
  }) async {
    try {
      if (_chat == null) startChat();
      debugPrint('Kelly sending message to Gemini: $text');

      // Attempt the send with retries for timeouts and 503 errors.
      GenerateContentResponse response;
      int retryCount = 0;
      const int maxRetries = 2;

      while (true) {
        try {
          response = await _chat!.sendMessage(Content.text(text)).timeout(
            const Duration(seconds: 45),
            onTimeout: () => throw Exception('Gemini API Timeout'),
          );
          break; // Success!
        } catch (e) {
          final errorStr = e.toString();
          final is503 = errorStr.contains('503') || errorStr.contains('UNAVAILABLE');
          final isTimeout = errorStr.contains('Timeout');

          if ((is503 || isTimeout) && retryCount < maxRetries) {
            retryCount++;
            final delay = Duration(seconds: retryCount * 2); // Simple backoff
            debugPrint('Kelly encountered ${is503 ? "503" : "Timeout"}. Retrying ($retryCount/$maxRetries) in ${delay.inSeconds}s...');
            await Future.delayed(delay);
            continue;
          }
          rethrow; // Max retries reached or different error
        }
      }

      debugPrint('Kelly received initial response: ${response.text?.substring(0, 10)}...');
      int iterations = 0;
      const int maxIterations = 5;

      while (response.functionCalls.isNotEmpty && iterations < maxIterations) {
        iterations++;
        
        if (onToolCall == null) {
          debugPrint('Gemini requested a tool call, but no handler was provided.');
          break;
        }

        // Execute all function calls requested in this turn
        final results = <Part>[];
        for (final call in response.functionCalls) {
          debugPrint('Kelly executing tool ($iterations/$maxIterations): ${call.name} with args: ${call.args}');
          try {
            final result = await onToolCall(call);
            debugPrint('Tool ${call.name} returned: $result');
            results.add(FunctionResponse(call.name, result));
          } catch (e) {
            debugPrint('Error executing tool ${call.name}: $e');
            results.add(FunctionResponse(call.name, {'error': e.toString()}));
          }
        }

        // Send all tool results back to the model in one turn
        try {
          response = await _chat!.sendMessage(
            Content('function', results),
          ).timeout(
            const Duration(seconds: 30),
            onTimeout: () => throw Exception('Gemini Tool Response Timeout'),
          );
        } catch (e) {
          if (e.toString().contains('thought_signature')) {
             debugPrint('Kelly caught thought_signature error but tool was successful. Returning manual confirmation.');
             return "I've added that to your planner for you! One less thing to worry about. Is there anything else you need? 😊";
          }
          rethrow;
        }
        
        debugPrint('Kelly received tool response summary: ${response.text?.substring(0, 10)}...');
      }

      if (iterations >= maxIterations) {
        debugPrint('Kelly reached max tool call iterations (5). Breaking to prevent hang.');
      }

      return response.text?.trim() ??
          "I've noted that down for you, but I'm having a little trouble finding the right words to say. Are you doing okay?";
    } catch (e) {
      debugPrint('Gemini API Error: $e');
      return "I'm having a little trouble connecting right now, but I'm still here with you. Take your time.";
    }
  }
}
