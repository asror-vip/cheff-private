import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/network/supabase_service.dart';
import '../../domain/entities/cashier_shift_entity.dart';

class CashierShiftsRepository {
  final SupabaseClient _client = SupabaseService.client;

  Future<CashierShiftEntity?> getActiveShift(String cashierId) async {
    try {
      final response = await _client
          .from('cashier_shifts')
          .select()
          .eq('restaurant_id', SupabaseService.currentRestaurantId)
          .eq('cashier_id', cashierId)
          .eq('status', ShiftStatus.open.name)
          .maybeSingle();

      if (response != null) {
        return _fromMap(response);
      }
      return null;
    } catch (e) {
      throw Exception('Smenani olishda xatolik: $e');
    }
  }

  Future<void> openShift(CashierShiftEntity shift) async {
    try {
      await _client.from('cashier_shifts').insert({
        'id': shift.id,
        'restaurant_id': shift.restaurantId,
        'cashier_id': shift.cashierId,
        'cashier_name': shift.cashierName,
        'opened_at': shift.openedAt.toIso8601String(),
        'status': shift.status.name,
        'initial_cash': shift.initialCash,
      });
    } catch (e) {
      throw Exception('Smenani ochishda xatolik: $e');
    }
  }

  Future<void> closeShift(CashierShiftEntity shift) async {
    try {
      await _client.from('cashier_shifts').update({
        'closed_at': shift.closedAt?.toIso8601String(),
        'status': shift.status.name,
        'expected_cash': shift.expectedCash,
        'expected_card': shift.expectedCard,
        'actual_cash': shift.actualCash,
        'difference': shift.difference,
        'note': shift.note,
      }).eq('id', shift.id);
    } catch (e) {
      throw Exception('Smenani yopishda xatolik: $e');
    }
  }

  CashierShiftEntity _fromMap(Map<String, dynamic> map) {
    return CashierShiftEntity(
      id: map['id'],
      restaurantId: map['restaurant_id'],
      cashierId: map['cashier_id'],
      cashierName: map['cashier_name'],
      openedAt: DateTime.parse(map['opened_at']),
      closedAt: map['closed_at'] != null ? DateTime.parse(map['closed_at']) : null,
      status: map['status'] == 'open' ? ShiftStatus.open : ShiftStatus.closed,
      initialCash: (map['initial_cash'] ?? 0).toDouble(),
      expectedCash: (map['expected_cash'] ?? 0).toDouble(),
      expectedCard: (map['expected_card'] ?? 0).toDouble(),
      actualCash: (map['actual_cash'] ?? 0).toDouble(),
      difference: (map['difference'] ?? 0).toDouble(),
      note: map['note'],
    );
  }
}
