enum AiMessageType {
  text,
  voice,
  action,
}

enum AiMessageSender {
  user,
  assistant,
}

class AiMessageEntity {
  final String id;
  final String text;
  final AiMessageSender sender;
  final AiMessageType type;
  final DateTime timestamp;
  final int? voiceDurationSeconds;
  final Map<String, dynamic>? actionData;

  const AiMessageEntity({
    required this.id,
    required this.text,
    required this.sender,
    this.type = AiMessageType.text,
    required this.timestamp,
    this.voiceDurationSeconds,
    this.actionData,
  });

  bool get isUser => sender == AiMessageSender.user;
}
