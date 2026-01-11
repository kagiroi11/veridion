import 'package:flutter/material.dart';

/// Compatibility screen to keep the AIChatScreen drawer behavior from the
/// original financial_resilience_app.
///
/// It simply routes back to this app's main dashboard HomeScreen.
import '../../screens/home_screen.dart' as dashboard;

class HomeScreen extends StatelessWidget {
  const HomeScreen({
    super.key,
    this.chatService,
    this.streakService,
    this.predictionService,
  });

  // Keep these optional parameters so AIChatScreen can pass them as-is.
  final Object? chatService;
  final Object? streakService;
  final Object? predictionService;

  @override
  Widget build(BuildContext context) {
    return const dashboard.HomeScreen();
  }
}
