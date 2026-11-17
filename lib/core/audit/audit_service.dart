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
      id: json['id']?.toString() ?? '',
      employeeId: payload['employee_id']?.toString() ?? '',
      employeeName: payload['employee_name']?.toString() ?? 'Noma`lum xodim',
      department: payload['department']?.toString() ?? json['event_type']?.toString() ?? 'general',
      action: payload['action']?.toString() ?? json['event_type']?.toString() ?? '',
      details: payload['details']?.toString() ?? '',
      timestamp: DateTime.tryParse(json['created_at']?.toString() ?? '') ?? DateTime.now(),
      extraData: payload,
    );
  }
}

class AuditService extends ChangeNotifier {
  static final AuditService _instance = AuditService._internal();
  factory AuditService() => _instance;
  AuditService._internal() {
    fetchEvents();
  }

  final List<AuditEntry> _entries = [];
  List<AuditEntry> get entries => List.unmodifiable(_entries);

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Future<void> fetchEvents() async {
    _isLoading = true;
    notifyListeners();

    try {
      final client = SupabaseService.client;
      final restId = SupabaseService.currentRestaurantId;
      final res = await client
          .from('business_events')
          .select()
          .eq('restaurant_id', restId)
          .order('created_at', ascending: false)
          .limit(100);

      final loaded = res.map((json) => AuditEntry.fromJson(json)).toList();
      _entries.clear();
      _entries.addAll(loaded);
    } catch (e) {
      debugPrint('Error fetching audit events: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
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
    final effectiveEmpId = employeeId ?? session.currentEmployee?.id ?? '';
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
