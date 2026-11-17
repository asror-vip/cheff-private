import 'package:flutter/material.dart';
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
      _todayShifts = shifts;
    } catch (e) {
      _error = e.toString();
    } finally {
      if (_isLoading) {
        _isLoading = false;
      }
      notifyListeners();
    }
  }

  Future<bool> startShift({required String userId, String? userName, String? role}) async {
    final success = await _repository.startShift(userId: userId, userName: userName, role: role);
    if (success) {
      await fetchStaffData(background: true);
    }
    return success;
  }

  Future<bool> endShift(String shiftId) async {
    final success = await _repository.endShift(shiftId);
    if (success) {
      await fetchStaffData(background: true);
    }
    return success;
  }
}
