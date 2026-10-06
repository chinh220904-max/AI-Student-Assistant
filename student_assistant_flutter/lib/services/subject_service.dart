import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/subject.dart';

/// Service để gọi REST API cho Subject
/// Backend chạy trên localhost:5177
/// Android Emulator dùng 10.0.2.2 để truy cập host machine
class SubjectService {
  // Base URL cho Android Emulator kết nối đến backend trên host
  static const String baseUrl = 'http://10.0.2.2:5177/api/Subjects';

  /// Lấy danh sách tất cả Subjects
  Future<List<Subject>> getSubjects() async {
    final response = await http.get(
      Uri.parse(baseUrl),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      // Parse JSON array thành List<Subject>
      List<dynamic> jsonList = jsonDecode(response.body);
      return jsonList.map((json) => Subject.fromJson(json)).toList();
    } else {
      throw Exception(
        'Không thể tải danh sách môn học: ${response.statusCode}',
      );
    }
  }

  /// Tạo mới một Subject
  Future<Subject> createSubject(Subject subject) async {
    final response = await http.post(
      Uri.parse(baseUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(subject.toJson()),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return Subject.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Không thể tạo môn học: ${response.statusCode}');
    }
  }

  /// Cập nhật một Subject hiện có
  Future<void> updateSubject(Subject subject) async {
    final response = await http.put(
      Uri.parse('$baseUrl/${subject.id}'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(subject.toJson()),
    );

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Không thể cập nhật môn học: ${response.statusCode}');
    }
  }

  /// Xóa một Subject
  Future<void> deleteSubject(int id) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/$id'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Không thể xóa môn học: ${response.statusCode}');
    }
  }
}
