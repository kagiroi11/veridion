import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

/// LeaderboardService: Provides privacy-safe user rankings based on streaks.
class LeaderboardService {
  final SupabaseClient _supabase;

  LeaderboardService({SupabaseClient? client})
      : _supabase = client ?? Supabase.instance.client;

  /// Fetch ranked users by streak count.
  /// Privacy Rule: Do NOT display money values or personal identifiers.
  Future<List<Map<String, dynamic>>> getPrivacySafeLeaderboard() async {
    try {
      // Fetch top users by streak
      // Note: In a real app, you'd map user_id to an anonymous nickname like "Super Saver 123"
      final response = await _supabase
          .from('streaks')
          .select('user_id, current_streak')
          .order('current_streak', ascending: false)
          .limit(10);
      
      final List<Map<String, dynamic>> data = List<Map<String, dynamic>>.from(response);

      // Map to privacy-safe format
      return data.asMap().entries.map((entry) {
        final index = entry.key + 1;
        final streak = entry.value['current_streak'] ?? 0;
        
        return {
          'rank': index,
          'displayName': 'Financial Warrior #$index', // Privacy-safe anonymous name
          'streak': streak,
          'status': _getStreakStatus(streak),
        };
      }).toList();
    } catch (e) {
      debugPrint('LeaderboardService Error: $e');
      return [];
    }
  }

  String _getStreakStatus(int streak) {
    if (streak >= 30) return 'Legendary';
    if (streak >= 14) return 'Master';
    if (streak >= 7) return 'Pro';
    return 'Rising Star';
  }
}
