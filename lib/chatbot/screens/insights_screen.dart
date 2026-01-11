import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/insights_service.dart';
import '../services/streak_service.dart';

class InsightsScreen extends StatelessWidget {
  final InsightsService insightsService;
  final StreakService streakService;

  const InsightsScreen({
    super.key,
    required this.insightsService,
    required this.streakService,
  });

  @override
  Widget build(BuildContext context) {
    final userId = Supabase.instance.client.auth.currentUser?.id ?? 'user_123';
    return Scaffold(
      appBar: AppBar(title: const Text('Predictive Insights')),
      body: FutureBuilder<String>(
        future: insightsService.generatePredictiveInsights(userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const Text('AI Predictive Analysis', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(snapshot.data ?? 'No insights available.'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
