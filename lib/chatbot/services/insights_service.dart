import 'finance_llm.dart';
import 'supabase_service.dart';

/// InsightsService: Generates predictive financial insights using AI.
class InsightsService {
  final FinanceLLM _llm;
  final SupabaseService _supabaseService;

  InsightsService({FinanceLLM? llm, SupabaseService? supabaseService})
      : _llm = llm ?? FinanceLLM(),
        _supabaseService = supabaseService ?? SupabaseService();

  /// Generate predictive insights for savings and overspending risk.
  Future<String> generatePredictiveInsights(String userId) async {
    // 1. Gather context data
    final financialSummary = await _supabaseService.getFinancialSummary(userId);
    final budgetData = await _supabaseService.getBudget(userId);
    final recentTransactions = await _supabaseService.getRecentTransactions(userId, limit: 10);

    // 2. Construct detailed context for AI
    String transactionsString = recentTransactions.map((t) => 
      '- ${t['description']}: ${t['amount']} (${t['category']})'
    ).join('\n');

    String budgetString = budgetData != null 
      ? 'Monthly Limit: ${budgetData['monthly_limit']}, Spent: ${budgetData['spent']}'
      : 'No budget set.';

    final context = '''
$financialSummary
BUDGET: $budgetString
RECENT TRANSACTIONS:
$transactionsString
''';

    // 3. Prompt for prediction
    const prompt = '''
Based on the provided financial data, please:
1. Predict the user's potential savings growth over the next 3 months if current behavior continues.
2. Identify any risks of overspending or debt based on the current budget and recent transactions.
3. Provide one actionable, encouraging tip for improvement.
Keep the response human-readable, practical, and under 200 words.
''';

    return await _llm.reasoningEngine(prompt, context);
  }
}
