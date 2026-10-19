import 'package:supabase_flutter/supabase_flutter.dart';
import '../session/session_manager.dart';

class SupabaseService {
  static final SupabaseClient client = Supabase.instance.client;
  
  static String get currentRestaurantId => SessionManager().bossProfile.restaurantId;
}
