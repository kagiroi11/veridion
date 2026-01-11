import 'supabase_service.dart';

/// PredictionService: Handles core logic for financial projections.
class PredictionService {
  final SupabaseService _supabaseService;

  PredictionService({SupabaseService? supabaseService})
      : _supabaseService = supabaseService ?? SupabaseService();

  /// Predict potential savings over N months based on budget discipline.
  Future<double> predictPotentialSavings(String userId, {int months = 3}) async {
    final budget = await _supabaseService.getBudget(userId);
    if (budget == null) return 0.0;

    final double limit = (budget['monthly_limit'] ?? 0).toDouble();
    final double spent = (budget['spent'] ?? 0).toDouble();
    
    // Simple projection: if they stay within budget, how much can they save?
    // Assuming 'limit' represents their planned spending and 'income' is handled in AI context.
    // For this helper, we'll return the projected savings amount if they keep the gap constant.
    
    // In a real app, we'd parse income here. For simplicity:
    final double monthlyPotential = limit - spent;
    
    return monthlyPotential > 0 ? monthlyPotential * months : 0.0;
  }
}
