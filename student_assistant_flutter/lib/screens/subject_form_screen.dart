import 'package:flutter/material.dart';

import '../models/subject.dart';
import '../services/subject_service.dart';

/// Màn hình form thêm/sửa Subject
/// Dùng chung cho cả Add và Edit mode
class SubjectFormScreen extends StatefulWidget {
  // Nếu có subject -> Edit mode, không có -> Add mode
  final Subject? subject;

  const SubjectFormScreen({super.key, this.subject});

  @override
  State<SubjectFormScreen> createState() => _SubjectFormScreenState();
}

class _SubjectFormScreenState extends State<SubjectFormScreen> {
  // Form key để validate
  final _formKey = GlobalKey<FormState>();

  // Controllers cho text fields
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;

  // Service để gọi API
  final SubjectService _subjectService = SubjectService();

  // Trạng thái loading
  bool _isLoading = false;

  // Kiểm tra mode: true = Edit, false = Add
  bool get isEditMode => widget.subject != null;

  @override
  void initState() {
    super.initState();
    // Khởi tạo controllers với dữ liệu hiện có (nếu Edit)
    _nameController = TextEditingController(text: widget.subject?.name ?? '');
    _descriptionController = TextEditingController(
      text: widget.subject?.description ?? '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  /// Submit form
  Future<void> submitForm() async {
    // Validate form
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      if (isEditMode) {
        // Update existing subject
        final updatedSubject = widget.subject!.copyWith(
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim(),
        );
        await _subjectService.updateSubject(updatedSubject);
      } else {
        // Create new subject
        final newSubject = Subject(
          id: 0, // Backend sẽ tự gán ID
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim(),
        );
        await _subjectService.createSubject(newSubject);
      }

      // Thành công -> Quay lại với kết quả true
      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      // Lỗi -> Hiển thị snackbar
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditMode ? 'Sửa môn học' : 'Thêm môn học'),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Tên môn học
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Tên môn học',
                  hintText: 'Ví dụ: PRM393',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.book),
                ),
                // Không cho edit ID khi Edit mode
                enabled: !_isLoading,
                textInputAction: TextInputAction.next,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Vui lòng nhập tên môn học';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Mô tả
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Mô tả',
                  hintText: 'Ví dụ: Mobile Programming',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.description),
                ),
                maxLines: 3,
                // Không cho edit khi đang loading
                enabled: !_isLoading,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Vui lòng nhập mô tả';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Nút Submit
              SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : submitForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          isEditMode ? 'Cập nhật' : 'Lưu',
                          style: const TextStyle(fontSize: 16),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
