class EmployeeShift {
  final String id;
  final String name;
  final String roleKey; // translation key for role
  final String startTime;
  final String endTime;

  EmployeeShift({
    required this.id,
    required this.name,
    required this.roleKey,
    required this.startTime,
    required this.endTime,
  });
}
