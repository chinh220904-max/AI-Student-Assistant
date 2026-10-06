import 'package:flutter/material.dart';

import '../models/subject.dart';
import '../services/subject_service.dart';
import 'subject_form_screen.dart';

/// Màn hình hiển thị danh sách Subjects
/// Thực hiện CRUD: Create, Read, Update, Delete
class SubjectsScreen extends StatefulWidget {
  const SubjectsScreen({super.key});

  @override
  State<SubjectsScreen> createState() => _SubjectsScreenState();
}

class _SubjectsScreenState extends State<SubjectsScreen> {
  // Service để gọi API
  final SubjectService _subjectService = SubjectService();

  // Danh sách subjects
  List<Subject> _subjects = [];

  // Trạng thái loading
  bool _isLoading = true;

  // Lỗi nếu có
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    loadSubjects();
  }

  /// Tải danh sách subjects từ API
  Future<void> loadSubjects() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final subjects = await _subjectService.getSubjects();
      setState(() {
        _subjects = subjects;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  /// Xóa một subject
  Future<void> deleteSubject(Subject subject) async {
    try {
      await _subjectService.deleteSubject(subject.id);
      // Tải lại danh sách sau khi xóa
      if (mounted) {
        loadSubjects();
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Đã xóa "${subject.name}"')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Lỗi xóa: ${e.toString()}')));
      }
    }
  }

  /// Mở form thêm/sửa subject
  Future<void> openSubjectForm([Subject? subject]) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => SubjectFormScreen(subject: subject),
      ),
    );

    // Nếu thêm/sửa thành công, tải lại danh sách
    if (result == true) {
      loadSubjects();
    }
  }

  /// Hiển thị dialog xác nhận xóa
  void showDeleteConfirmation(Subject subject) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text('Bạn có chắc muốn xóa môn học "${subject.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              deleteSubject(subject);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Subjects'),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      ),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton(
        onPressed: () => openSubjectForm(),
        tooltip: 'Thêm môn học',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildBody() {
    // Đang loading
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // Có lỗi
    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
              const SizedBox(height: 16),
              Text(
                'Không thể tải dữ liệu',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600]),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: loadSubjects,
                icon: const Icon(Icons.refresh),
                label: const Text('Thử lại'),
              ),
            ],
          ),
        ),
      );
    }

    // Danh sách rỗng
    if (_subjects.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.school_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Chưa có môn học nào',
              style: Theme.of(context).textTheme.titleLarge
                  ?.copyWith(color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              'Bấm + để thêm môn học mới',
              style: TextStyle(color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    // Hiển thị danh sách với Pull to Refresh
    return RefreshIndicator(
      onRefresh: loadSubjects,
      child: ListView.builder(
        padding: const EdgeInsets.all(8),
        itemCount: _subjects.length,
        itemBuilder: (context, index) {
          final subject = _subjects[index];
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 4),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                child: Text(
                  subject.name.isNotEmpty ? subject.name[0].toUpperCase() : '?',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              title: Text(
                subject.name,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(subject.description),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Nút Edit
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.blue),
                    tooltip: 'Sửa',
                    onPressed: () => openSubjectForm(subject),
                  ),
                  // Nút Delete
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    tooltip: 'Xóa',
                    onPressed: () => showDeleteConfirmation(subject),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
