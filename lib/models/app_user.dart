class AppUser {
  const AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.username = '',
    this.schoolId,
    this.section = '',
    this.studentId,
    this.hasFace = false,
  });

  final int id;
  final String name;
  final String email;
  final String username;
  final String role; // 'admin' | 'instructor' | 'student'
  final String? schoolId;
  final String section;
  final String? studentId;
  final bool hasFace;

  bool get isAdmin => role == 'admin';
  bool get isInstructor => role == 'instructor';
  bool get isStudent => role == 'student';

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: (json['id'] as num).toInt(),
      name: (json['name'] ?? json['full_name'] ?? '') as String,
      email: (json['email'] ?? '') as String,
      username: (json['username'] ?? '') as String,
      role: (json['role'] ?? 'student') as String,
      schoolId: json['school_id'] as String?,
      section: (json['section'] ?? '') as String,
      studentId: json['student_id'] as String?,
      hasFace: json['has_face'] as bool? ?? json['student_id'] != null,
    );
  }
}
