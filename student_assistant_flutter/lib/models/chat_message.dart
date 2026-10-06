/// Model class cho ChatMessage
/// Tương ứng với backend ChatMessage entity
class ChatMessage {
  final int id;
  final String message;    // Tin nhắn của user
  final String response;    // Phản hồi của AI
  final DateTime createdAt;

  ChatMessage({
    required this.id,
    required this.message,
    required this.response,
    required this.createdAt,
  });

  /// Tạo ChatMessage từ JSON
  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] as int,
      message: json['message'] as String,
      response: json['response'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  /// Convert ChatMessage thành JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'message': message,
      'response': response,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
