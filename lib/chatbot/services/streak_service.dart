import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

/// StreakService: Manage user's "resilience streak".
/// 
/// Tracks consecutive days without emergency fund withdrawals.
/// 
/// Streak Rules:
/// - Increment streak if no emergency withdrawal detected for the day
/// - Reset streak if emergency fund is used
/// - Streak is stored in Supabase 'streaks' table
/// 
/// NOTE: This service handles missing tables gracefully and returns default 
/// values (0) if the 'streaks' table doesn't exist in Supabase.
class StreakService {
  final SupabaseClient _supabase;

  /// Allow injecting a SupabaseClient for testing; defaults to the global instance.
  StreakService({SupabaseClient? client})
    : _supabase = client ?? Supabase.instance.client;

  /// Fetch the current streak for a user.
  /// 
  /// Returns the current streak count (number of consecutive days without 
  /// emergency fund withdrawal).
  /// 
  /// Returns 0 if:
  /// - No streak record exists for the user
  /// - The 'streaks' table doesn't exist in Supabase
  /// - Any error occurs while fetching
  Future<int> getStreak(String userId) async {
    try {
      // Attempt to fetch streak from 'streaks' table
      // If table doesn't exist, Supabase will throw an error, which we catch below
      final response = await _supabase
          .from('streaks')
          .select('current_streak')
          .eq('user_id', userId)
          .maybeSingle(); // returns null if no row found (table exists but no data)

      // If no record exists, return 0
      if (response == null) return 0;
      
      // Extract streak count, defaulting to 0 if missing or invalid
      return response['current_streak'] as int? ?? 0;
    } catch (e) {
      // Handle errors gracefully: table doesn't exist, network error, etc.
      // Return 0 instead of crashing - allows app to work even without database setup
      debugPrint('StreakService: Error fetching streak (table may not exist): $e');
      return 0; // Default to 0 on error (graceful degradation)
    }
  }

  /// Increment the streak for a user.
  /// 
  /// This method increments the streak count by 1, indicating that the user
  /// has successfully maintained their emergency fund for another day.
  /// 
  /// In a production app, this would check transaction dates to verify that
  /// no emergency fund withdrawal occurred. For this prototype, it's a simple increment.
  /// 
  /// NOTE: If the 'streaks' table doesn't exist, this method silently fails
  /// (graceful degradation - app continues to work).
  Future<void> incrementStreak(String userId) async {
    try {
      // Check if a streak record already exists for this user
      final existing = await _supabase
          .from('streaks')
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      if (existing == null) {
        // Create new streak record (first time for this user)
        await _supabase.from('streaks').insert({
          'user_id': userId,
          'current_streak': 1,
          'last_updated': DateTime.now().toIso8601String(),
        });
      } else {
        // Increment existing streak
        final current = existing['current_streak'] as int? ?? 0;
        await _supabase
            .from('streaks')
            .update({
              'current_streak': current + 1,
              'last_updated': DateTime.now().toIso8601String(),
            })
            .eq('user_id', userId);
      }
    } catch (e) {
      // Handle errors gracefully: table doesn't exist, network error, etc.
      // Silently fail to allow app to continue working
      debugPrint('StreakService: Error incrementing streak (table may not exist): $e');
    }
  }

  /// Reset streak to 0 (e.g. if emergency fund was used).
  /// 
  /// This is called when the user makes a withdrawal from their emergency fund,
  /// breaking their streak of consecutive days without withdrawal.
  /// 
  /// NOTE: If the 'streaks' table doesn't exist, this method silently fails
  /// (graceful degradation - app continues to work).
  Future<void> resetStreak(String userId) async {
    try {
      // Reset streak to 0 (upsert creates record if it doesn't exist)
      await _supabase.from('streaks').upsert({
        'user_id': userId,
        'current_streak': 0,
        'last_updated': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      // Handle errors gracefully: table doesn't exist, network error, etc.
      // Silently fail to allow app to continue working
      debugPrint('StreakService: Error resetting streak (table may not exist): $e');
    }
  }

  /// Evaluate budget discipline and update streak.
  /// Increment if spent <= monthly_limit, reset if spent > monthly_limit.
  Future<void> evaluateDailyStreak(String userId) async {
    try {
      // 1. Get budget info
      final budgetArr = await _supabase
          .from('budgets')
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      if (budgetArr == null) return;

      final double limit = (budgetArr['monthly_limit'] ?? 0).toDouble();
      final double spent = (budgetArr['spent'] ?? 0).toDouble();

      // 2. Decide based on discipline
      if (spent <= limit) {
        // Budget maintained - increment streak
        await incrementStreak(userId);
      } else {
        // Overspent - reset streak
        await resetStreak(userId);
      }
    } catch (e) {
      debugPrint('StreakService: Error evaluating daily streak: $e');
    }
  }
}
