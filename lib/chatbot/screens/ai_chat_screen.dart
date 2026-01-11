// Main chat screen where users interact with the AI assistant
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/finance_llm.dart';
import '../services/supabase_service.dart';
import '../models/message.dart';
import 'home_screen.dart';
import 'insights_screen.dart';
import 'leaderboard_screen.dart';
import '../services/chat_service.dart';
import '../services/insights_service.dart';
import '../services/streak_service.dart';
import '../services/prediction_service.dart';
import '../utils/notification_helper.dart';

class AIChatScreen extends StatefulWidget {
  const AIChatScreen({
    super.key,
    this.llm,
    this.supabaseService,
    this.streakService,
    this.chatService,
  });

  // Optional injected services for testing or external control.
  final FinanceLLM? llm;
  final SupabaseService? supabaseService;
  final StreakService? streakService;
  final ChatService? chatService;

  @override
  State<AIChatScreen> createState() => _AIChatScreenState();
}

class _AIChatScreenState extends State<AIChatScreen> {
  // Controller for the text input field
  final TextEditingController _messageController = TextEditingController();

  // ScrollController to auto-scroll to the latest message
  final ScrollController _scrollController = ScrollController();

  // List to store all chat messages
  final List<MessageModel> _messages = [];

  // Instance of FinanceLLM service to call AI.
  late final FinanceLLM _llm;

  // Instance of SupabaseService to fetch financial data
  late final SupabaseService _supabaseService;

  // Loading state - true when waiting for AI response
  bool _isLoading = false;

  // User ID - in a real app, this would come from authentication
  // TODO: Replace with actual user ID from your auth system
  late final String _userId;

  // Financial context string - stores user's financial summary
  String _financialContext = '';

  // Instance of StreakService
  late final StreakService _streakService;
  
  // Instance of ChatService
  late final ChatService _chatService;
  
  int _currentStreak = 0;

  @override
  void initState() {
    super.initState();
    _llm = widget.llm ?? FinanceLLM();
    _supabaseService = widget.supabaseService ?? SupabaseService();
    _streakService = widget.streakService ?? StreakService();
    _chatService = widget.chatService ?? ChatService();

    _userId = Supabase.instance.client.auth.currentUser?.id ?? 'user_123';
    
    _loadChatHistory();
    _loadFinancialContext();
    _loadStreakAndNotify(); // Load streak + motivation
  }

  /// Load chat history from Supabase
  Future<void> _loadChatHistory() async {
    final history = await _chatService.getAllMessages();
    if (mounted && history.isNotEmpty) {
      setState(() {
        _messages.addAll(history);
      });
      _scrollToBottom();
    } else if (mounted) {
      _addWelcomeMessage();
    }
  }

  /// Load streak count and show AI-generated motivational notification.
  /// 
  /// Uses Gemini AI to generate personalized, positive financial encouragement
  /// messages based on the user's streak achievement.
  Future<void> _loadStreakAndNotify() async {
    // Also evaluate daily streak based on budget discipline before showing
    await _streakService.evaluateDailyStreak(_userId);
    
    final streak = await _streakService.getStreak(_userId);
    if (mounted) {
      setState(() {
        _currentStreak = streak;
      });

      // Generate AI-based motivational notification (if streak exists)
      if (streak > 0) {
        Future.delayed(const Duration(seconds: 2), () async {
          if (mounted) {
            try {
              // Generate AI motivational message using Gemini
              final aiMessage = await NotificationHelper.generateAIMotivationalMessage(
                llm: _llm,
                streak: streak,
                savingsContext: _financialContext.isNotEmpty ? _financialContext : null,
              );
              
              // Display the AI-generated message
              if (mounted) {
                NotificationHelper.notify(
                  context: context,
                  message: aiMessage,
                );
              }
            } catch (e) {
              // Fallback to simple notification if AI generation fails
              debugPrint('Error generating AI motivational message: $e');
              if (mounted) {
                NotificationHelper.notify(
                  context: context,
                  message: 'Great job! You are on a $streak-day savings streak! Keep it up!',
                );
              }
            }
          }
        });
      }
    }
  }

  // Load user's financial data from Supabase
  Future<void> _loadFinancialContext() async {
    try {
      // Fetch financial summary from Supabase
      final context = await _supabaseService.getFinancialSummary(_userId);
      setState(() {
        _financialContext = context;
      });
    } catch (e) {
      debugPrint('Error loading financial context: $e');
      // Set empty context if loading fails
      _financialContext = 'No financial data available.';
    }
  }

  // Add welcome message when app starts
  void _addWelcomeMessage() {
    final welcomeMessage = MessageModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      senderId: 'bot',
      text:
          'Hello! I\'m your AI financial assistant. I can help you with budgeting, saving tips, and analyzing your expenses. What would you like to know.',
    );

    setState(() {
      _messages.add(welcomeMessage);
    });
    // Save welcome message if conversation is new
    _chatService.saveMessage(welcomeMessage);
  }

  // Send message function - called when user presses send button
  Future<void> _sendMessage() async {
    // Get the text from input field and remove extra spaces
    final messageText = _messageController.text.trim();

    // Don't send if message is empty
    if (messageText.isEmpty) return;

    // Check if API key is configured
    if (!_llm.isApiKeyConfigured()) {
      _showApiKeyError();
      return;
    }

    // Create a new message object for user's message
    final userMessage = MessageModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      senderId: 'me',
      text: messageText,
    );

    // Add user's message to the list and clear input field
    setState(() {
      _messages.add(userMessage);
      _messageController.clear(); // Clear the input field
      _isLoading = true; // Show loading indicator
    });
    
    // Save to Supabase
    await _chatService.saveMessage(userMessage);

    // Scroll to bottom to show the new message
    _scrollToBottom();

    try {
      // Call the AI to get a response
      // Pass user's message and financial context
      final aiResponse = await _llm.reasoningEngine(
        messageText,
        _financialContext,
      );

      // Create AI's response message
      final assistantMessage = MessageModel(
        id: (DateTime.now().millisecondsSinceEpoch + 1).toString(),
        senderId: 'bot',
        text: aiResponse,
      );

      // Add AI's response to the message list
      setState(() {
        _messages.add(assistantMessage);
        _isLoading = false; // Hide loading indicator
      });
      
      // Save AI response to Supabase
      await _chatService.saveMessage(assistantMessage);

      // Scroll to bottom to show AI's response
      _scrollToBottom();

      // Increment streak (demo: assume good interaction means no emergency withdrawal)
      try {
        await _streakServiceIncrementAndNotify();
      } catch (_) {}
    } catch (e) {
      // If error occurs, show error message
      final errorMessage = MessageModel(
        id: (DateTime.now().millisecondsSinceEpoch + 2).toString(),
        senderId: 'bot',
        text: 'Sorry, I encountered an error. Please try again.',
      );

      setState(() {
        _messages.add(errorMessage);
        _isLoading = false;
      });
    }
  }

  // Show error dialog if API key is not configured
  void _showApiKeyError() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('API Key Required'),
        content: const Text(
          'Please configure GEMINI_API_KEY (e.g., add a .env file with GEMINI_API_KEY=your_key or set the environment variable).\n\nGet your free API key from: https://makersuite.google.com/app/apikey',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  // Show confirmation dialog for clearing history
  void _showClearHistoryDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Chat History?'),
        content: const Text('This will delete all messages permanently.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _clearHistory();
            },
            child: const Text('Clear', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  /// Clear history from local state and Supabase
  Future<void> _clearHistory() async {
    setState(() {
      _isLoading = true;
    });
    
    await _chatService.clearChatHistory();
    
    if (mounted) {
      setState(() {
        _messages.clear();
        _isLoading = false;
        _addWelcomeMessage(); // Re-add welcome message
      });
    }
  }

  // Scroll to the bottom of the chat
  void _scrollToBottom() {
    // Use a small delay to ensure the new message is rendered first
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent, // Scroll to max position
          duration: const Duration(milliseconds: 300), // Animation duration
          curve: Curves.easeOut, // Animation curve
        );
      }
    });
  }

  @override
  void dispose() {
    // Clean up controllers when screen is closed to prevent memory leaks
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  /// Helper to increment streak and notify the user with AI-generated message.
  /// 
  /// This method:
  /// 1. Increments the user's streak count
  /// 2. Generates an AI-based motivational message using Gemini
  /// 3. Displays the message to encourage continued savings behavior
  Future<void> _streakServiceIncrementAndNotify() async {
    final before = await _streakService.getStreak(_userId);
    await _streakService.incrementStreak(_userId);
    final updated = await _streakService.getStreak(_userId);
    
    if (mounted && updated > before) {
      setState(() {
        _currentStreak = updated;
      });
      
      try {
        // Generate AI motivational message for streak increase
        final aiMessage = await NotificationHelper.generateAIMotivationalMessage(
          llm: _llm,
          streak: updated,
          savingsContext: _financialContext.isNotEmpty ? _financialContext : null,
        );
        
        // Display the AI-generated message
        if (mounted) {
          NotificationHelper.notify(
            context: context,
            message: aiMessage,
          );
        }
      } catch (e) {
        // Fallback to simple notification if AI generation fails
        debugPrint('Error generating AI motivational message: $e');
        if (mounted) {
          NotificationHelper.notify(
            context: context,
            message: '🔥 Streak increased! Now $updated days.',
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // App bar at the top
      appBar: AppBar(
        title: const Text('Finance Assistant'),
        actions: [
          // Gamified Streak Display
          if (_currentStreak > 0)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Chip(
                avatar: const Icon(
                  Icons.local_fire_department,
                  color: Colors.orange,
                  size: 20,
                ),
                label: Text(
                  '$_currentStreak',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                backgroundColor: Colors.white,
              ),
            ),
          // Delete button to clear chat history
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: _showClearHistoryDialog,
            tooltip: 'Clear History',
          ),
          // Refresh button to reload financial data
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadFinancialContext,
            tooltip: 'Refresh',
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Color(0xFF00897B)),
              child: Text(
                'Financial Resilience',
                style: TextStyle(color: Colors.white, fontSize: 24),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.home),
              title: const Text('Home'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => HomeScreen(
                      chatService: ChatService(),
                      streakService: StreakService(),
                      predictionService: PredictionService(),
                    ),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.insights),
              title: const Text('Insights'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => InsightsScreen(
                      insightsService: InsightsService(),
                      streakService: StreakService(),
                    ),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.leaderboard),
              title: const Text('Leaderboard'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const LeaderboardScreen(),
                  ),
                );
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.notifications_active),
              title: const Text('Get Motivation'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      '🔔 "Financial freedom is available to those who learn about it and work for it."',
                    ),
                    duration: Duration(seconds: 4),
                  ),
                );
              },
            ),
          ],
        ),
      ),

      // Main body of the screen
      body: Column(
        children: [
          // Message list area (takes up most of the screen)
          Expanded(
            child: _messages.isEmpty
                ? _buildEmptyState() // Show when no messages
                : _buildMessageList(), // Show message list
          ),

          // Show loading indicator when AI is thinking
          if (_isLoading) _buildLoadingIndicator(),

          // Input area at the bottom
          _buildInputArea(),
        ],
      ),
    );
  }

  // Build empty state (shown when no messages)
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_bubble_outline, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'Start a conversation!',
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  // Build the scrollable list of messages
  Widget _buildMessageList() {
    return ListView.builder(
      controller: _scrollController, // Attach scroll controller
      padding: const EdgeInsets.all(16),
      itemCount: _messages.length, // Number of messages
      itemBuilder: (context, index) {
        final message = _messages[index];
        return _buildMessageBubble(message); // Build each message bubble
      },
    );
  }

  // Build a single message bubble
  Widget _buildMessageBubble(MessageModel message) {
    return Align(
      // Align to right if user message, left if AI message
      alignment: message.senderId == 'me'
          ? Alignment.centerRight
          : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75, // Max 75% width
        ),
        decoration: BoxDecoration(
          // Different colors for user vs AI messages
          color: message.senderId == 'me'
              ? const Color(0xFF00897B) // Teal for user
              : Colors.white, // White for AI
          borderRadius: BorderRadius.circular(20),
          // Add shadow for depth
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha((0.1 * 255).round()),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Message text
            Text(
              message.text,
              style: TextStyle(
                color: message.senderId == 'me' ? Colors.white : Colors.black87,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 4),
            // Timestamp
            Text(
              _formatTimestamp(message.timestamp),
              style: TextStyle(
                color: message.senderId == 'me'
                    ? Colors.white.withAlpha((0.7 * 255).round())
                    : Colors.grey[600],
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Build loading indicator (three dots animation)
  Widget _buildLoadingIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha((0.1 * 255).round()),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Three dots loading animation
            _buildDot(0),
            const SizedBox(width: 4),
            _buildDot(1),
            const SizedBox(width: 4),
            _buildDot(2),
          ],
        ),
      ),
    );
  }

  // Build a single animated dot for loading indicator
  Widget _buildDot(int index) {
    return TweenAnimationBuilder<double>(
      // Animated opacity that cycles between 0.3 and 1.0
      tween: Tween(begin: 0.3, end: 1.0),
      duration: const Duration(milliseconds: 600),
      // Repeat animation infinitely
      onEnd: () {
        if (mounted) {
          setState(() {}); // Trigger rebuild to restart animation
        }
      },
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: Color(0xFF00897B),
              shape: BoxShape.circle,
            ),
          ),
        );
      },
    );
  }

  // Build the input area at the bottom
  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        // Add shadow at top for depth
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha((0.05 * 255).round()),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Text input field
            Expanded(
              child: TextField(
                controller: _messageController,
                decoration: const InputDecoration(
                  hintText: 'Ask about your finances...',
                  border: InputBorder.none,
                ),
                // Allow multiple lines
                maxLines: null,
                // Enable keyboard action
                textInputAction: TextInputAction.send,
                // Send message when user presses enter
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
            const SizedBox(width: 8),
            // Send button
            Material(
              color: const Color(0xFF00897B),
              borderRadius: BorderRadius.circular(25),
              child: InkWell(
                onTap: _isLoading ? null : _sendMessage, // Disable when loading
                borderRadius: BorderRadius.circular(25),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  child: Icon(
                    Icons.send,
                    color: _isLoading
                        ? Colors.white.withAlpha((0.5 * 255).round())
                        : Colors.white,
                    size: 24,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Format timestamp to readable format (e.g., "2:30 PM")
  String _formatTimestamp(DateTime timestamp) {
    final hour = timestamp.hour > 12 ? timestamp.hour - 12 : timestamp.hour;
    final minute = timestamp.minute.toString().padLeft(2, '0');
    final period = timestamp.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }
}
