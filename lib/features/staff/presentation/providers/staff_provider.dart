import 'package:flutter/material.dart';
import '../../../../core/session/session_manager.dart';
import '../../data/models/staff_model.dart';
import '../../data/repositories/staff_repository.dart';

class StaffProvider extends ChangeNotifier {
  final StaffRepository _repository = StaffRepository();
  
  List<ShiftModel> _todayShifts = [];
  List<ShiftModel> get todayShifts => _todayShifts;
  
  bool _isLoading = false;
  bool get isLoading => _isLoading;
  
  String? _error;
  String? get error => _error;

  

  Future<void> fetchStaffData({bool background = false}) async {
    if (!background && _todayShifts.isEmpty) {
      _isLoading = true;
      _error = null;
      notifyListeners();
    }
    
    try {
      final shifts = await _repository.getTodayShifts();
      if (shifts.isEmpty) {
        final session = SessionManager();
        final now = DateTime.now();
        _todayShifts = session.employees
            .where((e) => e.status == 'active')
            .map((e) => ShiftModel(
                  id: 'shift_${e.id}',
                  userId: e.id,
                  startTime: DateTime(now.year, now.month, now.day, 9, 0),
                  status: 'active',
                  staff: StaffModel(id: e.id, name: e.name, role: e.roleName, isActive: true),
                ))
            .toList();
      } else {
        _todayShifts = shifts;
      }
    } catch (e) {
      _error = e.toString();
    }
    if (_isLoading) {
      _isLoading = false;
    }
    notifyListeners();
  }

}
