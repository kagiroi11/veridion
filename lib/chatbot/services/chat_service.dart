import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import '../models/message.dart';

/// ChatService: Manages chat history in the 'messages' table.
class ChatService {
  final SupabaseClient _supabase;

  ChatService({SupabaseClient? client})
      : _supabase = client ?? Supabase.instance.client;

  /// Save a message to Supabase.
  Future<void> saveMessage(MessageModel message) async {
    try {
      await _supabase.from('messages').insert(message.toJson());
    } catch (e) {
      debugPrint('ChatService Save Error: $e');
    }
  }

  /// Get chat history for a user.
  Future<List<MessageModel>> getChatHistory(String userId) async {
    try {
      final response = await _supabase
          .from('messages')
          .select()
          .eq('sender_id', userId) // This might need adjustment if sender_id is not user_id
          .order('timestamp', ascending: true);
      
      return (response as List)
          .map((m) => MessageModel.fromJson(m))
          .toList();
    } catch (e) {
      debugPrint('ChatService History Error: $e');
      return [];
    }
  }

  /// Special fetch for AI messages (where sender_id is 'bot')
  /// In a real app, you'd likely have a 'conversation_id' or check both user and bot messages.
  Future<List<MessageModel>> getAllMessages() async {
     try {
      final response = await _supabase
          .from('messages')
          .select()
          .order('timestamp', ascending: true);
      
      return (response as List)
          .map((m) => MessageModel.fromJson(m))
          .toList();
    } catch (e) {
      debugPrint('ChatService History Error: $e');
      return [];
    }
  }

  /// Clear all chat history.
  Future<void> clearChatHistory() async {
    try {
      // Deleting without a filter is restricted in some Supabase setups, 
      // so we use a filter that matches all.
      await _supabase.from('messages').delete().neq('id', 'placeholder_that_never_matches');
    } catch (e) {
      debugPrint('ChatService Clear Error: $e');
    }
  }
}
