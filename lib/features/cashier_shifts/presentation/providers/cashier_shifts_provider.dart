import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../domain/entities/cashier_shift_entity.dart';
import '../../data/repositories/cashier_shifts_repository.dart';
import '../../../../core/session/session_manager.dart';
import '../../../../core/network/supabase_service.dart';

class CashierShiftsProvider extends ChangeNotifier {
  final CashierShiftsRepository _repository = CashierShiftsRepository();
  final _uuid = const Uuid();

  CashierShiftEntity? _activeShift;
  CashierShiftEntity? get activeShift => _activeShift;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  Future<void> checkActiveShift() async {
    _isLoading = true;
    notifyListeners();

    try {
      final session = SessionManager();
      final cashierId = session.currentEmployee?.id ?? session.bossProfile.id;
      _activeShift = await _repository.getActiveShift(cashierId);
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> openShift(double initialCash) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final session = SessionManager();
      final cashierId = session.currentEmployee?.id ?? session.bossProfile.id;
      final cashierName = session.currentEmployee?.name ?? session.bossProfile.name;

      final newShift = CashierShiftEntity(
        id: _uuid.v4(),
        restaurantId: SupabaseService.currentRestaurantId,
        cashierId: cashierId,
        cashierName: cashierName,
        openedAt: DateTime.now(),
        initialCash: initialCash,
        status: ShiftStatus.open,
      );

      await _repository.openShift(newShift);
      _activeShift = newShift;

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = "Smenani ochishda xatolik: $e";
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> closeShift({
    required double expectedCash,
    required double expectedCard,
    required double actualCash,
    String? note,
  }) async {
    if (_activeShift == null) return false;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final closedShift = _activeShift!.copyWith(
        status: ShiftStatus.closed,
        closedAt: DateTime.now(),
        expectedCash: expectedCash,
        expectedCard: expectedCard,
        actualCash: actualCash,
        difference: actualCash - expectedCash,
        note: note,
      );

      await _repository.closeShift(closedShift);
      _activeShift = null;

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = "Smenani yopishda xatolik: $e";
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}
