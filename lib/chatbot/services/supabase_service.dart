import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

/// SupabaseService: Handles database interactions with existing tables.
/// Specifically focuses on user finances, transactions, and budgets for Member 3 features.
class SupabaseService {
  final SupabaseClient _supabase;

  SupabaseService({SupabaseClient? client})
      : _supabase = client ?? Supabase.instance.client;

  /// Fetch user financial summary as a context string for the AI.
  Future<String> getFinancialSummary(String userId) async {
    try {
      final finances = await _supabase
          .from('user_finances')
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      if (finances == null) return 'No financial profile found.';

      final balance = finances['balance'] ?? 0;
      final income = finances['monthly_income'] ?? 0;
      final expenses = finances['total_expenses'] ?? 0;

      return 'Monthly Income: $income, Current Balance: $balance, Total Expenses: $expenses.';
    } catch (e) {
      debugPrint('SupabaseService Error: $e');
      return 'Error fetching financial summary.';
    }
  }

  /// Get budget information for the user.
  Future<Map<String, dynamic>?> getBudget(String userId) async {
    try {
      return await _supabase
          .from('budgets')
          .select()
          .eq('user_id', userId)
          .maybeSingle();
    } catch (e) {
      debugPrint('SupabaseService Budget Error: $e');
      return null;
    }
  }

  /// Fetch recent transactions.
  Future<List<Map<String, dynamic>>> getRecentTransactions(String userId, {int limit = 5}) async {
    try {
      final response = await _supabase
          .from('transactions')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(limit);
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('SupabaseService Transactions Error: $e');
      return [];
    }
  }
}
