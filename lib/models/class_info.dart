class ClassInfo {
  const ClassInfo({
    required this.id,
    required this.name,
    required this.code,
    this.description = '',
    this.section = '',
    this.instructorId,
    this.instructorName = '',
    this.presentTime = '',
    this.lateTime = '',
    this.endTime = '',
    this.studentCount = 0,
  });

  final String id;
  final String name;
  final String code;
  final String description;
  final String section;
  final int? instructorId;
  final String instructorName;
  final String presentTime;
  final String lateTime;
  final String endTime;
  final int studentCount;

  factory ClassInfo.fromJson(Map<String, dynamic> json) {
    return ClassInfo(
      id: json['id'] as String,
      name: (json['name'] ?? '') as String,
      code: (json['code'] ?? '') as String,
      description: (json['description'] ?? '') as String,
      section: (json['section'] ?? '') as String,
      instructorId: json['instructor_id'] == null
          ? null
          : (json['instructor_id'] as num).toInt(),
      instructorName: (json['instructor_name'] ?? '') as String,
      presentTime: (json['present_time'] ?? '') as String,
      lateTime: (json['late_time'] ?? '') as String,
      endTime: (json['end_time'] ?? '') as String,
      studentCount: (json['student_count'] as num?)?.toInt() ?? 0,
    );
  }
}
