import 'package:flutter/material.dart';
import '../services/finance_llm.dart';

/// NotificationHelper: Handles AI-generated motivational nudges and in-app alerts.
class NotificationHelper {
  /// Generate a personalized motivational message using Gemini AI.
  static Future<String> generateAIMotivationalMessage({
    required FinanceLLM llm,
    required int streak,
    String? savingsContext,
  }) async {
    final prompt = '''
The user just reached a $streak-day resilience streak! 
${savingsContext != null ? "Current financial status: $savingsContext" : ""}
Please generate a short, high-energy motivational nudge (max 20 words).
Celebrate their discipline and encourage them to keep going!
''';

    return await llm.reasoningEngine(prompt);
  }

  /// Display a simple in-app snackbar notification.
  static void notify({
    required BuildContext context,
    required String message,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.auto_awesome, color: Colors.amber),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        backgroundColor: const Color(0xFF00796B),
        duration: const Duration(seconds: 4),
      ),
    );
  }
}
