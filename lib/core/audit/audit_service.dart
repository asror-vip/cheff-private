import 'package:flutter/foundation.dart';
import '../network/supabase_service.dart';
import '../session/session_manager.dart';

class AuditEntry {
  final String id;
  final String employeeId;
  final String employeeName;
  final String department;
  final String action;
  final String details;
  final DateTime timestamp;
  final Map<String, dynamic>? extraData;

  const AuditEntry({
    required this.id,
    required this.employeeId,
    required this.employeeName,
    required this.department,
    required this.action,
    required this.details,
    required this.timestamp,
    this.extraData,
  });

  factory AuditEntry.fromJson(Map<String, dynamic> json) {
    final payload = (json['payload'] as Map<String, dynamic>?) ?? {};
    return AuditEntry(
      id: json['id'] ?? '',
      employeeId: payload['employee_id'] ?? 'EMP-101',
      employeeName: payload['employee_name'] ?? 'Noma`lum xodim',
      department: payload['department'] ?? json['event_type'] ?? 'general',
      action: payload['action'] ?? json['event_type'] ?? '',
      details: payload['details'] ?? '',
      timestamp: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
      extraData: payload,
    );
  }
}

class AuditService extends ChangeNotifier {
  static final AuditService _instance = AuditService._internal();
  factory AuditService() => _instance;
  AuditService._internal() {
    _initSeedData();
  }

  final List<AuditEntry> _entries = [];
  List<AuditEntry> get entries => List.unmodifiable(_entries);

  final bool _isLoading = false;
  bool get isLoading => _isLoading;

  void _initSeedData() {
    final now = DateTime.now();
    _entries.addAll([
      AuditEntry(
        id: 'aud-1',
        employeeId: 'EMP-101',
        employeeName: 'Bobur Aliyev',
        department: 'warehouse',
        action: 'Ombor kirimi',
        details: 'Mol go`shti (lahm) - 25 kg kirim qilindi. Yetkazib beruvchi: Go`sht Savdo MCHJ.',
        timestamp: DateTime(now.year, now.month, now.day, 9, 15),
      ),
      AuditEntry(
        id: 'aud-2',
        employeeId: 'EMP-102',
        employeeName: 'Malika Karimova',
        department: 'pos',
        action: 'POS Savdo cheki',
        details: 'Chek #1001 yopildi. Jami: 185 000 so`m (Osh x2, Choy x1, Salat x2).',
        timestamp: DateTime(now.year, now.month, now.day, 10, 5),
      ),
      AuditEntry(
        id: 'aud-3',
        employeeId: 'EMP-101',
        employeeName: 'Bobur Aliyev',
        department: 'warehouse',
        action: 'Qoldiq tekshiruvi',
        details: 'O`simlik yog`i qoldig`i tekshirildi (Haqiqiy: 18 litr).',
        timestamp: DateTime(now.year, now.month, now.day, 10, 40),
      ),
      AuditEntry(
        id: 'aud-4',
        employeeId: 'EMP-102',
        employeeName: 'Malika Karimova',
        department: 'pos',
        action: 'POS Savdo cheki',
        details: 'Chek #1002 yopildi. Jami: 95 000 so`m (Shashlik x3, Non x2).',
        timestamp: DateTime(now.year, now.month, now.day, 11, 20),
      ),
      AuditEntry(
        id: 'aud-5',
        employeeId: 'EMP-101',
        employeeName: 'Bobur Aliyev',
        department: 'warehouse',
        action: 'Chiqim hujjati',
        details: 'Oshxona talabnomasi bo`yicha 10 kg Guruch chiqarildi.',
        timestamp: DateTime(now.year, now.month, now.day, 11, 55),
      ),
    ]);
  }

  Future<void> logAction({
    required String department,
    required String action,
    required String details,
    String? employeeId,
    String? employeeName,
    Map<String, dynamic>? extraData,
  }) async {
    final session = SessionManager();
    final effectiveEmpId = employeeId ?? session.currentEmployee?.id ?? 'EMP-101';
    final effectiveEmpName = employeeName ?? session.currentEmployee?.name ?? (session.currentRole == AppRole.owner ? 'Boshliq' : 'Xodim');

    final entry = AuditEntry(
      id: 'aud-${DateTime.now().millisecondsSinceEpoch}',
      employeeId: effectiveEmpId,
      employeeName: effectiveEmpName,
      department: department,
      action: action,
      details: details,
      timestamp: DateTime.now(),
      extraData: extraData,
    );

    _entries.insert(0, entry);
    notifyListeners();

    try {
      final client = SupabaseService.client;
      await client.from('business_events').insert({
        'restaurant_id': SupabaseService.currentRestaurantId,
        'event_type': action,
        'payload': {
          'employee_id': effectiveEmpId,
          'employee_name': effectiveEmpName,
          'department': department,
          'action': action,
          'details': details,
          ...?extraData,
        },
      });
    } catch (e) {
      debugPrint('Audit remote logging bypassed or failed: $e');
    }
  }

  List<AuditEntry> getTodayEvents({String? query}) {
    final now = DateTime.now();
    return _entries.where((entry) {
      final isToday = entry.timestamp.year == now.year &&
          entry.timestamp.month == now.month &&
          entry.timestamp.day == now.day;
      if (!isToday) return false;

      if (query == null || query.trim().isEmpty) return true;

      final q = query.trim().toLowerCase();
      final idMatch = entry.employeeId.toLowerCase().contains(q);
      final nameMatch = entry.employeeName.toLowerCase().contains(q);
      final deptMatch = entry.department.toLowerCase().contains(q);
      final actionMatch = entry.action.toLowerCase().contains(q);
      final detailsMatch = entry.details.toLowerCase().contains(q);

      return idMatch || nameMatch || deptMatch || actionMatch || detailsMatch;
    }).toList();
  }
}
