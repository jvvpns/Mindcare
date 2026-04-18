class ChatMessage {
  final String id;
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final String? detectedEmotion;
  final String? suggestedAction;

  ChatMessage({
    required this.id,
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.detectedEmotion,
    this.suggestedAction,
  });
}

