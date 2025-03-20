// models/message.dart
class Message {
  final String id;
  final String content;
  final DateTime timestamp;
  final bool isUser;
  final List<String>? suggestions;

  Message({
    required this.id,
    required this.content,
    required this.timestamp,
    this.isUser = false,
    this.suggestions,
  });
}
