import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// FinanceLLM: Centralized AI logic for the Financial Resilience App.
/// Mandatory Design for Member 3: AI reasoning engine using Gemini 1.5 Flash.
class FinanceLLM {
  final String apiKey;

  FinanceLLM({String? apiKey})
    : apiKey =
          apiKey ??
          dotenv.env['GEMINI_API_KEY'] ??
          const String.fromEnvironment('GEMINI_API_KEY', defaultValue: '');

  bool isApiKeyConfigured() => apiKey.isNotEmpty;

  /// Mandatory: reasoningEngine(prompt, userContext)
  /// Coordinates the AI request and returns formatted response.
  Future<String> reasoningEngine(String prompt, [String? userContext]) async {
    if (!isApiKeyConfigured()) {
      return 'Configuration Error: GEMINI_API_KEY is missing.';
    }

    // 1. Construct reasoning-based persona
    const systemPersona =
        'You are a friendly, encouraging AI Financial Coach for a resilience competition app. '
        'Goal: help user build savings, maintain streaks, and avoid debt. '
        'Style: Reasoning-based, practical, motivational, no complex jargon.';

    final fullPrompt =
        '$systemPersona\n\n'
        '${userContext != null ? "USER FINANCIAL CONTEXT:\n$userContext\n\n" : ""}'
        'USER QUESTION: $prompt';

    try {
      // 2. Call API
      final rawResponse = await apiModelCall(fullPrompt);
      
      // 3. Format and return
      return responseFormatter(rawResponse);
    } catch (e) {
      return 'AI unreachable: $e';
    }
  }

  /// Mandatory: apiModelCall()
  /// Handles the physical HTTP request to Gemini API.
  Future<String> apiModelCall(String fullPrompt) async {
    final url = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=$apiKey',
    );

    final response = await http
        .post(
          url,
          headers: {'Content-Type': 'application/json; charset=utf-8'},
          body: jsonEncode({
            'contents': [
              {
                'parts': [
                  {'text': fullPrompt},
                ],
              },
            ],
            'generationConfig': {
              'temperature': 0.7,
              'maxOutputTokens': 500,
            },
          }),
        )
        .timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      return response.body;
    } else {
      throw Exception('API Error (${response.statusCode}): ${response.body}');
    }
  }

  /// Mandatory: localModelPlaceholder()
  /// Placeholder for future on-device privacy features.
  Future<String> localModelPlaceholder(String prompt) async {
    await Future.delayed(const Duration(seconds: 1));
    return 'Local LLM (TFLite) is not yet implemented. Using cloud API.';
  }

  /// Mandatory: responseFormatter()
  /// Parses Gemini's complex JSON into a clean string.
  String responseFormatter(String rawBody) {
    try {
      final Map<String, dynamic> jsonMap = jsonDecode(rawBody);

      if (jsonMap['candidates'] != null &&
          (jsonMap['candidates'] as List).isNotEmpty) {
        final first = (jsonMap['candidates'] as List).first;
        final candidateText =
            first['content']?['parts']?[0]?['text'] ??
            first['text'];
        if (candidateText != null) return candidateText.trim();
      }
      return 'I could not generate a clear response. Please try again.';
    } catch (e) {
      return 'Error parsing AI response.';
    }
  }
}
