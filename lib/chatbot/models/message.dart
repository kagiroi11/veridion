/// MessageModel: Data structure for chat messages.
class MessageModel {
  final String id;
  final String senderId; // 'me' for user, 'bot' for AI
  final String text;
  final DateTime timestamp;

  MessageModel({
    required this.id,
    required this.senderId,
    required this.text,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  /// Convert to JSON for Supabase storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sender_id': senderId,
      'text': text,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  /// Create from JSON from Supabase
  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      id: json['id']?.toString() ?? '',
      senderId: json['sender_id'] ?? '',
      text: json['text'] ?? '',
      timestamp: json['timestamp'] != null 
          ? DateTime.parse(json['timestamp']) 
          : DateTime.now(),
    );
  }
}
