import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/network/supabase_service.dart';
import '../models/staff_model.dart';

class StaffRepository {
  final SupabaseClient _client = SupabaseService.client;
  
  Future<List<ShiftModel>> getTodayShifts() async {
    try {
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day).toIso8601String();
      final endOfDay = DateTime(today.year, today.month, today.day, 23, 59, 59).toIso8601String();
      
      final response = await _client
          .from('shifts')
          .select('''
            *,
            users (id, name, role, is_active)
          ''')
          .eq('restaurant_id', SupabaseService.currentRestaurantId)
          .gte('start_time', startOfDay)
          .lte('start_time', endOfDay);
          
      return (response as List)
          .map((json) => ShiftModel.fromJson(json))
          .toList();
    } catch (e) {
      // Error fetching shifts: $e
      return [];
    }
  }

  Future<List<StaffModel>> getStaffList() async {
    try {
      final response = await _client
          .from('users')
          .select()
          .eq('restaurant_id', SupabaseService.currentRestaurantId);
          
      return (response as List)
          .map((json) => StaffModel.fromJson(json))
          .toList();
    } catch (e) {
      // Error fetching staff: $e
      return [];
    }
  }

  Future<bool> startShift({required String userId, String? userName, String? role}) async {
    try {
      await _client.from('shifts').insert({
        'restaurant_id': SupabaseService.currentRestaurantId,
        'user_id': userId,
        'start_time': DateTime.now().toIso8601String(),
        'status': 'active',
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> endShift(String shiftId) async {
    try {
      await _client.from('shifts').update({
        'end_time': DateTime.now().toIso8601String(),
        'status': 'completed',
      }).eq('id', shiftId);
      return true;
    } catch (e) {
      return false;
    }
  }
}
