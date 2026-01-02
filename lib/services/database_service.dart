import '../models/category.dart';
import '../models/user_settings.dart';
import '../models/monthly_debt_history.dart';
import '../data/transactions_data.dart';
import 'supabase_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';
import 'dart:async';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  final SupabaseClient _client = SupabaseService.client;
  String? _currentUserId;

  // Set the current user ID (from Supabase Auth)
  void setUserId(String userId) {
    _currentUserId = userId;
  }

  // Get current user ID
  String get userId {
    if (_currentUserId == null) {
      final user = SupabaseService.client.auth.currentUser;
      if (user != null) {
        _currentUserId = user.id;
      } else {
        throw Exception('No authenticated user found.');
      }
    }
    return _currentUserId!;
  }

  // Initialize user settings if they don't exist
  Future<UserSettings?> getOrCreateUserSettings() async {
    try {
      // Try to get existing user settings
      final response = await _client
          .from('user_settings')
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      if (response != null) {
        return UserSettings.fromMap(response);
      }

      // Create default user settings if they don't exist
      final defaultSettings = UserSettings(
        id: '', // Will be set by database
        userId: userId,
        startingBalance: 789050, // ₹7,890.50
        monthlyBudget: 300000,   // ₹3,000.00
        currentDebt: 0,         // ₹0.00
      );

      final insertResponse = await _client
          .from('user_settings')
          .insert(defaultSettings.toMap())
          .select()
          .single();

      return UserSettings.fromMap(insertResponse);
    } catch (e) {
      print('Error getting/creating user settings: $e');
      return null;
    }
  }

  // CATEGORIES
  Future<List<Category>> getCategories() async {
    try {
      final response = await _client
          .from('categories')
          .select()
          .order('name');

      return List<Category>.from(
        response.map((category) => Category.fromMap(category)),
      );
    } catch (e) {
      print('Error fetching categories: $e');
      return [];
    }
  }

  // Helper method to get color for category
  Color _getColorForCategory(String category) {
    switch (category.toLowerCase()) {
      case 'shopping':
        return Colors.purple;
      case 'food':
        return Colors.red;
      case 'rent':
        return Colors.orange;
      case 'miscellaneous':
        return Colors.blue;
      case 'debt payment':
        return Colors.teal;
      case 'income':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  // TRANSACTIONS
  Future<List<Transaction>> getTransactions() async {
    try {
      final response = await _client
          .from('transactions')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      return List<Transaction>.from(
        response.map((transaction) {
          // Map existing schema to Transaction model
          return Transaction(
            id: transaction['id'].toString(),
            title: transaction['title'] ?? transaction['description'] ?? 'Unknown',
            subtitle: transaction['subtitle'] ?? transaction['category'] ?? '',
            amount: (transaction['amount'] is int 
                ? transaction['amount'] as int
                : (transaction['amount'] as num).toInt()),
            date: transaction['date'] != null 
                ? DateTime.parse(transaction['date'])
                : DateTime.parse(transaction['created_at']),
            isExpense: transaction['is_expense'] ?? true,
            category: transaction['category'] ?? 'Shopping',
            color: _getColorForCategory(transaction['category'] ?? 'Shopping'),
            categoryId: transaction['category_id'],
          );
        }),
      );
    } catch (e) {
      print('Error fetching transactions: $e');
      return [];
    }
  }

  Future<Transaction> addTransaction(Transaction transaction) async {
    try {
      // Map to existing schema
      final transactionData = {
        'user_id': userId,
        'title': transaction.title,
        'description': transaction.subtitle,
        'amount': transaction.amount,
        'category': transaction.category,
        'is_expense': transaction.isExpense,
        'date': transaction.date.toIso8601String().split('T')[0], // YYYY-MM-DD format
        'category_id': transaction.categoryId,
      };

      final response = await _client
          .from('transactions')
          .insert(transactionData)
          .select()
          .single();

      return Transaction(
        id: response['id'].toString(),
        title: response['title'] ?? response['description'] ?? 'Unknown',
        subtitle: response['subtitle'] ?? response['category'] ?? '',
        amount: (response['amount'] is int 
            ? response['amount'] as int
            : (response['amount'] as num).toInt()),
        date: response['date'] != null 
            ? DateTime.parse(response['date'])
            : DateTime.parse(response['created_at']),
        isExpense: response['is_expense'] ?? true,
        category: response['category'] ?? 'Shopping',
        color: _getColorForCategory(response['category'] ?? 'Shopping'),
        categoryId: response['category_id'],
      );
    } catch (e) {
      print('Error adding transaction: $e');
      rethrow;
    }
  }

  Future<void> deleteTransaction(String transactionId) async {
    try {
      await _client
          .from('transactions')
          .delete()
          .eq('id', transactionId)
          .eq('user_id', userId);
    } catch (e) {
      print('Error deleting transaction: $e');
      rethrow;
    }
  }

  // USER SETTINGS
  Future<UserSettings> getUserSettings() async {
    try {
      final response = await _client
          .from('user_settings')
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      if (response == null) {
        // Create default settings if none exist
        return await _createDefaultUserSettings();
      }

      return UserSettings.fromMap(response);
    } catch (e) {
      print('Error fetching user settings: $e');
      // Return default settings on error
      return UserSettings(
        id: '',
        userId: userId,
        startingBalance: 789050,
        monthlyBudget: 300000,
        currentDebt: 0,
      );
    }
  }

  Future<UserSettings> updateUserSettings(UserSettings settings) async {
    try {
      final settingsData = settings.toMap();
      settingsData['user_id'] = userId;

      final response = await _client
          .from('user_settings')
          .upsert(settingsData)
          .select()
          .single();

      return UserSettings.fromMap(response);
    } catch (e) {
      print('Error updating user settings: $e');
      rethrow;
    }
  }

  Future<UserSettings> _createDefaultUserSettings() async {
    try {
      final defaultSettings = {
        'user_id': userId,
        'starting_balance': 789050,
        'monthly_budget': 300000,
        'current_debt': 0,
      };

      final response = await _client
          .from('user_settings')
          .insert(defaultSettings)
          .select()
          .single();

      return UserSettings.fromMap(response);
    } catch (e) {
      print('Error creating default user settings: $e');
      rethrow;
    }
  }

  // MONTHLY DEBT HISTORY
  Future<List<MonthlyDebtHistory>> getMonthlyDebtHistory() async {
    try {
      final response = await _client
          .from('monthly_debt_history')
          .select()
          .eq('user_id', userId)
          .order('month', ascending: false)
          .limit(6); // Last 6 months

      return List<MonthlyDebtHistory>.from(
        response.map((history) => MonthlyDebtHistory.fromMap(history)),
      );
    } catch (e) {
      print('Error fetching monthly debt history: $e');
      return [];
    }
  }

  Future<MonthlyDebtHistory> updateMonthlyDebt(DateTime month, int debtAmount) async {
    try {
      final monthStart = DateTime(month.year, month.month, 1);
      final historyData = {
        'month': monthStart.toIso8601String().split('T')[0],
        'debt_amount': debtAmount,
        'user_id': userId,
      };

      final response = await _client
          .from('monthly_debt_history')
          .upsert(historyData)
          .select()
          .single();

      return MonthlyDebtHistory.fromMap(response);
    } catch (e) {
      print('Error updating monthly debt: $e');
      rethrow;
    }
  }

  // UTILITY METHODS
  Future<int> getCurrentMonthSpent() async {
    try {
      final now = DateTime.now();
      final monthStart = DateTime(now.year, now.month, 1);
      final monthEnd = DateTime(now.year, now.month + 1, 0);

      final response = await _client
          .from('transactions')
          .select('amount')
          .eq('user_id', userId)
          .eq('is_expense', true)
          .gte('date', monthStart.toIso8601String().split('T')[0])
          .lte('date', monthEnd.toIso8601String().split('T')[0]);

      int total = 0;
      for (var transaction in response) {
        total += transaction['amount'] as int;
      }
      return total;
    } catch (e) {
      print('Error calculating current month spent: $e');
      return 0;
    }
  }

  Future<int> getTotalBalance() async {
    try {
      final settings = await getUserSettings();
      final transactions = await getTransactions();

      int balance = settings.startingBalance;
      
      for (var transaction in transactions) {
        if (transaction.isExpense) {
          balance -= transaction.amount;
        } else {
          balance += transaction.amount;
        }
      }

      return balance;
    } catch (e) {
      print('Error calculating total balance: $e');
      return 0;
    }
  }
}
