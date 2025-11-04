class ChatThread {
  final String id;
  final String user; // display name / username
  final List<ChatMessage> messages;

  ChatThread({required this.id, required this.user, required this.messages});

  factory ChatThread.fromJson(Map<String, dynamic> json) {
    final msgs = (json['messages'] as List<dynamic>? ?? [])
        .map((e) => ChatMessage.fromJson(e as Map<String, dynamic>))
        .toList();
    return ChatThread(
      id: json['id'] as String,
      user: json['user'] as String,
      messages: msgs,
    );
  }
}

class ChatMessage {
  final String text;
  final bool fromMe;
  final DateTime? timestamp;
  final String? sender;

  ChatMessage({required this.text, required this.fromMe, this.timestamp, this.sender});

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      text: json['text'] as String,
      fromMe: json['fromMe'] as bool? ?? false,
      timestamp: json['ts'] != null ? DateTime.tryParse(json['ts']) : null,
      sender: json['sender'] as String?,
    );
  }
}