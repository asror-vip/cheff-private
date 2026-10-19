import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/network/supabase_service.dart';
import '../models/sales_model.dart';
import '../../domain/entities/sales_summary.dart';

class SalesRepository {
  final SupabaseClient _client = SupabaseService.client;
  
  Future<SalesSummary> getTodaySalesSummary() async {
    try {
      final now = DateTime.now();
      final todayStart = DateTime(now.year, now.month, now.day).toIso8601String();
      final todayEnd = DateTime(now.year, now.month, now.day, 23, 59, 59).toIso8601String();
      
      final response = await _client
          .from('sales')
          .select('*')
          .eq('restaurant_id', SupabaseService.currentRestaurantId)
          .eq('status', 'completed')
          .gte('date', todayStart)
          .lte('date', todayEnd);
          
      final List<SalesModel> todaySales = (response as List)
          .map((json) => SalesModel.fromJson(json))
          .toList();
          
      double totalRev = 0;
      for (var s in todaySales) {
        totalRev += s.amount;
      }

      int receipts = todaySales.length;
      double avg = receipts > 0 ? totalRev / receipts : 0;

      // Query top dishes
      final saleItemsResponse = await _client
          .from('sale_items')
          .select('quantity, total_price, recipes(name), sales!inner(restaurant_id, date, status)')
          .eq('sales.restaurant_id', SupabaseService.currentRestaurantId)
          .gte('sales.date', todayStart)
          .lte('sales.date', todayEnd)
          .eq('sales.status', 'completed');

      Map<String, TopDish> dishMap = {};
      for (var row in (saleItemsResponse as List)) {
        final recipe = row['recipes'];
        if (recipe != null) {
          final name = recipe['name'] as String;
          final num rawQty = row['quantity'] ?? 0;
          final int qty = rawQty.toInt();
          final num rawSum = row['total_price'] ?? 0;
          final double sum = rawSum.toDouble();
          
          if (dishMap.containsKey(name)) {
            dishMap[name] = TopDish(
              name: name,
              portions: dishMap[name]!.portions + qty,
              sum: dishMap[name]!.sum + sum,
            );
          } else {
            dishMap[name] = TopDish(name: name, portions: qty, sum: sum);
          }
        }
      }

      final topDishesList = dishMap.values.toList()
        ..sort((a, b) => b.sum.compareTo(a.sum));
      
      final topDishes = topDishesList.take(5).toList();

      final prevStart = DateTime(now.year, now.month, now.day - 1).toIso8601String();
      final prevEnd = DateTime(now.year, now.month, now.day - 1, 23, 59, 59).toIso8601String();
      final prevResponse = await _client
          .from('sales')
          .select('amount')
          .eq('restaurant_id', SupabaseService.currentRestaurantId)
          .eq('status', 'completed')
          .gte('date', prevStart)
          .lte('date', prevEnd);
      
      double prevRev = 0;
      for (var row in (prevResponse as List)) {
        prevRev += (row['amount'] ?? 0).toDouble();
      }

      return SalesSummary(
        totalRevenue: totalRev,
        previousRevenue: prevRev,
        totalReceipts: receipts,
        averageReceipt: avg,
        topDishes: topDishes,
        dailyRevenues: [totalRev],
      );
    } catch (e) {
      debugPrint('Error fetching sales: $e');
      return SalesSummary(
        totalRevenue: 0,
        previousRevenue: 0,
        totalReceipts: 0,
        averageReceipt: 0,
      );
    }
  }

  Future<SalesSummary> getSalesSummaryByRange(DateTime start, DateTime end) async {
    try {
      final rangeStart = DateTime(start.year, start.month, start.day).toIso8601String();
      final rangeEnd = DateTime(end.year, end.month, end.day, 23, 59, 59).toIso8601String();
      
      final response = await _client
          .from('sales')
          .select('*')
          .eq('restaurant_id', SupabaseService.currentRestaurantId)
          .eq('status', 'completed')
          .gte('date', rangeStart)
          .lte('date', rangeEnd);
          
      final List<SalesModel> sales = (response as List)
          .map((json) => SalesModel.fromJson(json))
          .toList();
          
      double totalRev = 0;
      for (var s in sales) {
        totalRev += s.amount;
      }

      int receipts = sales.length;
      double avg = receipts > 0 ? totalRev / receipts : 0;

      final List<double> dailyRevs = List.filled(7, 0.0);
      for (var s in sales) {
        final diffDays = s.date.difference(DateTime(start.year, start.month, start.day)).inDays;
        if (diffDays >= 0 && diffDays < 7) {
          dailyRevs[diffDays] += s.amount;
        } else {
          dailyRevs[s.date.weekday % 7] += s.amount;
        }
      }

      final saleItemsResponse = await _client
          .from('sale_items')
          .select('quantity, total_price, recipes(name), sales!inner(restaurant_id, date, status)')
          .eq('sales.restaurant_id', SupabaseService.currentRestaurantId)
          .gte('sales.date', rangeStart)
          .lte('sales.date', rangeEnd)
          .eq('sales.status', 'completed');

      Map<String, TopDish> dishMap = {};
      for (var row in (saleItemsResponse as List)) {
        final recipe = row['recipes'];
        if (recipe != null) {
          final name = recipe['name'] as String;
          final num rawQty = row['quantity'] ?? 0;
          final int qty = rawQty.toInt();
          final num rawSum = row['total_price'] ?? 0;
          final double sum = rawSum.toDouble();
          
          if (dishMap.containsKey(name)) {
            dishMap[name] = TopDish(
              name: name,
              portions: dishMap[name]!.portions + qty,
              sum: dishMap[name]!.sum + sum,
            );
          } else {
            dishMap[name] = TopDish(name: name, portions: qty, sum: sum);
          }
        }
      }

      final topDishesList = dishMap.values.toList()
        ..sort((a, b) => b.sum.compareTo(a.sum));
      
      final topDishes = topDishesList.take(5).toList();
      
      final rangeDuration = end.difference(start);
      // If start and end are same day, difference is 0 days, so we subtract 1 day manually to get previous period
      final durationToSubtract = rangeDuration.inDays == 0 ? const Duration(days: 1) : rangeDuration;
      final prevStart = start.subtract(durationToSubtract);
      final prevEnd = end.subtract(durationToSubtract);
      
      final prevStartIso = DateTime(prevStart.year, prevStart.month, prevStart.day).toIso8601String();
      final prevEndIso = DateTime(prevEnd.year, prevEnd.month, prevEnd.day, 23, 59, 59).toIso8601String();
      
      final prevResponse = await _client
          .from('sales')
          .select('amount')
          .eq('restaurant_id', SupabaseService.currentRestaurantId)
          .eq('status', 'completed')
          .gte('date', prevStartIso)
          .lte('date', prevEndIso);
          
      double prevRev = 0;
      for (var row in (prevResponse as List)) {
        prevRev += (row['amount'] ?? 0).toDouble();
      }

      return SalesSummary(
        totalRevenue: totalRev,
        previousRevenue: prevRev,
        totalReceipts: receipts,
        averageReceipt: avg,
        topDishes: topDishes,
        dailyRevenues: dailyRevs,
      );
    } catch (e) {
      debugPrint('Error fetching sales by range: $e');
      return SalesSummary(
        totalRevenue: 0,
        previousRevenue: 0,
        totalReceipts: 0,
        averageReceipt: 0,
      );
    }
  }

  Future<bool> refundSale(String saleId, {String reason = 'Bekor qilindi'}) async {
    try {
      final response = await _client.rpc('process_pos_refund', params: {
        'p_sale_id': saleId,
        'p_reason': reason,
      });
      return response == true;
    } catch (e) {
      debugPrint('Error refunding sale: $e');
      throw Exception('Chekni bekor qilishda xatolik: $e');
    }
  }
}
