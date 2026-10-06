import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/chat_message.dart';

/// Service để gọi REST API cho ChatMessage
/// Backend chạy trên localhost:5177
/// Android Emulator dùng 10.0.2.2 để truy cập host machine
class ChatService {
  // Base URL cho Android Emulator kết nối đến backend trên host
  static const String baseUrl = 'http://10.0.2.2:5177/api/ChatMessages';

  /// Lấy toàn bộ lịch sử chat
  Future<List<ChatMessage>> getMessages() async {
    try {
      final response = await http.get(
        Uri.parse(baseUrl),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        List<dynamic> jsonList = jsonDecode(response.body);
        return jsonList.map((json) => ChatMessage.fromJson(json)).toList();
      } else {
        // Trả về list rỗng nếu API lỗi (để app vẫn chạy được)
        return [];
      }
    } catch (e) {
      // Bắt exception để app không crash khi backend không chạy
      return [];
    }
  }

  /// Gửi câu hỏi tới AI và nhận phản hồi
  /// POST /api/ChatMessages/ask
  Future<ChatMessage> askAI(String message) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/ask'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'message': message}),
      );

      if (response.statusCode == 200) {
        // Parse response và tạo ChatMessage
        final jsonData = jsonDecode(response.body);
        return ChatMessage.fromJson(jsonData);
      } else {
        // Parse error message từ response
        String errorMsg = 'Lỗi không xác định';
        try {
          final errorJson = jsonDecode(response.body);
          errorMsg = errorJson['message'] ?? errorMsg;
        } catch (_) {
          errorMsg = 'Server trả về lỗi: ${response.statusCode}';
        }
        throw Exception(errorMsg);
      }
    } catch (e) {
      // Re-throw exception đã format
      if (e is Exception) rethrow;
      // Nếu không phải Exception, wrap lại
      throw Exception('Đã xảy ra lỗi không mong muốn');
    }
  }

  /// Xóa toàn bộ lịch sử chat
  Future<bool> clearMessages() async {
    try {
      final response = await http.delete(
        Uri.parse(baseUrl),
        headers: {'Content-Type': 'application/json'},
      );

      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      // Trả về false nếu không kết nối được
      return false;
    }
  }
}
