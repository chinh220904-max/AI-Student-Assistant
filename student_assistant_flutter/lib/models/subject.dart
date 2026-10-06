/// Model class cho Subject
/// Parse và convert JSON từ backend API
class Subject {
  final int id;
  final String name;
  final String description;

  Subject({required this.id, required this.name, required this.description});

  /// Tạo Subject từ JSON
  factory Subject.fromJson(Map<String, dynamic> json) {
    return Subject(
      id: json['id'] as int,
      name: json['name'] as String,
      description: json['description'] as String,
    );
  }

  /// Convert Subject thành JSON
  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name, 'description': description};
  }

  /// Tạo copy với dữ liệu mới (dùng cho Edit)
  Subject copyWith({int? id, String? name, String? description}) {
    return Subject(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
    );
  }
}
