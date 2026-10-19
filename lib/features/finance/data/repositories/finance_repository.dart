import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/network/supabase_service.dart';
import '../../domain/entities/finance_summary.dart';

class FinanceRepository {
  final SupabaseClient _client = SupabaseService.client;
  
  Future<FinanceSummary> getMonthlyFinance(int year, int month) async {
    try {
      final restaurantId = SupabaseService.currentRestaurantId;
      final startOfMonth = DateTime(year, month, 1).toIso8601String();
      final endOfMonth = DateTime(year, month + 1, 0, 23, 59, 59).toIso8601String();

      // 1. Fetch Income (Sales) for current month
      final salesResponse = await _client
          .from('sales')
          .select('total_amount')
          .eq('restaurant_id', restaurantId)
          .gte('date', startOfMonth)
          .lte('date', endOfMonth)
          .eq('status', 'completed');

      double income = 0;
      for (var row in salesResponse) {
        income += (row['total_amount'] ?? 0).toDouble();
      }

      // 2. Fetch Real Food Cost (COGS) from sale stock movements
      final movementsResponse = await _client
          .from('stock_movements')
          .select('quantity, products (average_cost)')
          .eq('restaurant_id', restaurantId)
          .eq('type', 'sale')
          .gte('created_at', startOfMonth)
          .lte('created_at', endOfMonth);

      double foodCost = 0;
      for (var row in movementsResponse) {
        final double qty = (row['quantity'] ?? 0).toDouble().abs();
        final product = row['products'] as Map<String, dynamic>?;
        final double avgCost = (product?['average_cost'] ?? 0).toDouble();
        foodCost += qty * avgCost;
      }

      // 3. Fetch Operating Expenses
      final expensesResponse = await _client
          .from('expenses')
          .select('amount, category')
          .eq('restaurant_id', restaurantId)
          .gte('expense_date', startOfMonth)
          .lte('expense_date', endOfMonth);

      double operatingExpense = 0;
      Map<String, double> expensesByCategory = {};
      for (var row in expensesResponse) {
        final amt = (row['amount'] ?? 0).toDouble();
        final cat = row['category'] ?? 'Boshqa';
        operatingExpense += amt;
        expensesByCategory[cat] = (expensesByCategory[cat] ?? 0) + amt;
      }

      // 4. Fetch Cash Purchases (Recorded separately as cash flow)
      final purchasesResponse = await _client
          .from('purchases')
          .select('total_amount')
          .eq('restaurant_id', restaurantId)
          .gte('date', startOfMonth)
          .lte('date', endOfMonth)
          .eq('status', 'completed');
          
      double purchasesTotal = 0;
      for (var row in purchasesResponse) {
        purchasesTotal += (row['total_amount'] ?? 0).toDouble();
      }

      // Add Food Cost as an expense category if present
      if (foodCost > 0) {
        expensesByCategory['ФудКост (Таннарх)'] = foodCost;
      }

      final totalExpenses = foodCost + operatingExpense;
      final profit = income - totalExpenses;
      final margin = income > 0 ? (profit / income) * 100 : 0.0;

      // 5. Calculate Previous Month Metrics for Changes
      final prevYear = month == 1 ? year - 1 : year;
      final prevMonth = month == 1 ? 12 : month - 1;
      final prevStart = DateTime(prevYear, prevMonth, 1).toIso8601String();
      final prevEnd = DateTime(prevYear, prevMonth + 1, 0, 23, 59, 59).toIso8601String();

      double prevIncome = 0;
      final prevSales = await _client
          .from('sales')
          .select('total_amount')
          .eq('restaurant_id', restaurantId)
          .gte('date', prevStart)
          .lte('date', prevEnd)
          .eq('status', 'completed');
      for (var row in prevSales) {
        prevIncome += (row['total_amount'] ?? 0).toDouble();
      }

      double prevExpenses = 0;
      final prevExp = await _client
          .from('expenses')
          .select('amount')
          .eq('restaurant_id', restaurantId)
          .gte('expense_date', prevStart)
          .lte('expense_date', prevEnd);
      for (var row in prevExp) {
        prevExpenses += (row['amount'] ?? 0).toDouble();
      }

      final prevMovements = await _client
          .from('stock_movements')
          .select('quantity, products (average_cost)')
          .eq('restaurant_id', restaurantId)
          .eq('type', 'sale')
          .gte('created_at', prevStart)
          .lte('created_at', prevEnd);
      for (var row in prevMovements) {
        final double qty = (row['quantity'] ?? 0).toDouble().abs();
        final product = row['products'] as Map<String, dynamic>?;
        final double avgCost = (product?['average_cost'] ?? 0).toDouble();
        prevExpenses += qty * avgCost;
      }

      final prevProfit = prevIncome - prevExpenses;
      final prevMargin = prevIncome > 0 ? (prevProfit / prevIncome) * 100 : 0.0;

      final double revenueChange = prevIncome > 0
          ? double.parse((((income - prevIncome) / prevIncome) * 100).toStringAsFixed(1))
          : 0.0;
      final double expensesChange = prevExpenses > 0
          ? double.parse((((totalExpenses - prevExpenses) / prevExpenses) * 100).toStringAsFixed(1))
          : 0.0;
      final double profitChange = prevProfit.abs() > 0
          ? double.parse((((profit - prevProfit) / prevProfit.abs()) * 100).toStringAsFixed(1))
          : 0.0;
      final double marginChange = double.parse((margin - prevMargin).toStringAsFixed(1));
      
      final expenseCats = expensesByCategory.entries
          .map((e) => ExpenseCategory(name: e.key, amount: e.value))
          .toList();

      return FinanceSummary(
        revenue: income,
        revenueChange: revenueChange,
        expenses: totalExpenses,
        expensesChange: expensesChange,
        profit: profit,
        profitChange: profitChange,
        margin: margin,
        marginChange: marginChange,
        foodCost: foodCost,
        purchasesTotal: purchasesTotal,
        expenseCategories: expenseCats,
      );
    } catch (e) {
      debugPrint('Error fetching finance: $e');
      return FinanceSummary(
        revenue: 0, revenueChange: 0,
        expenses: 0, expensesChange: 0,
        profit: 0, profitChange: 0,
        margin: 0, marginChange: 0,
        foodCost: 0, purchasesTotal: 0,
      );
    }
  }

  Future<void> addExpense(String category, double amount) async {
    await _client.from('expenses').insert({
      'restaurant_id': SupabaseService.currentRestaurantId,
      'category': category,
      'amount': amount,
      'expense_date': DateTime.now().toIso8601String(),
    });
  }
}
