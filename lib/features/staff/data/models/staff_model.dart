class StaffModel {
  final String id;
  final String name;
  final String role;
  final bool isActive;

  StaffModel({
    required this.id,
    required this.name,
    required this.role,
    required this.isActive,
  });

  factory StaffModel.fromJson(Map<String, dynamic> json) {
    return StaffModel(
      id: json['id'],
      name: json['name'] ?? '',
      role: json['role'] ?? '',
      isActive: json['is_active'] ?? true,
    );
  }
}

class ShiftModel {
  final String id;
  final String userId;
  final DateTime startTime;
  final DateTime? endTime;
  final String status;
  final StaffModel? staff;

  ShiftModel({
    required this.id,
    required this.userId,
    required this.startTime,
    this.endTime,
    required this.status,
    this.staff,
  });

  factory ShiftModel.fromJson(Map<String, dynamic> json) {
    StaffModel? staff;
    if (json['users'] != null) {
      staff = StaffModel.fromJson(json['users']);
    }

    return ShiftModel(
      id: json['id'],
      userId: json['user_id'],
      startTime: DateTime.tryParse(json['start_time']?.toString() ?? '') ?? DateTime.now(),
      endTime: json['end_time'] != null ? DateTime.tryParse(json['end_time']?.toString() ?? '') : null,
      status: json['status'] ?? 'active',
      staff: staff,
    );
  }
}
