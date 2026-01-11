import 'package:flutter/material.dart';
import '../services/leaderboard_service.dart';

class LeaderboardScreen extends StatelessWidget {
  const LeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final leaderboardService = LeaderboardService();

    return Scaffold(
      appBar: AppBar(title: const Text('Privacy-Safe Leaderboard')),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: leaderboardService.getPrivacySafeLeaderboard(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final list = snapshot.data ?? [];
          return ListView.builder(
            itemCount: list.length,
            itemBuilder: (context, index) {
              final user = list[index];
              return ListTile(
                leading: CircleAvatar(child: Text(user['rank'].toString())),
                title: Text(user['displayName']),
                subtitle: Text('Status: ${user['status']}'),
                trailing: Text('${user['streak']} Days 🔥'),
              );
            },
          );
        },
      ),
    );
  }
}
