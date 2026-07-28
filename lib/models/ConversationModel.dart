
class ConversationModel {
  final String conversationId;
  final String title;
  final String emotion;
  final DateTime updatedAt;
  final int messageCount;
  final int moodScore;

  ConversationModel({
    required this.conversationId,
    required this.title,
    required this.emotion,
    required this.updatedAt,
    required this.messageCount,
    required this.moodScore,
  });

  factory ConversationModel.fromJson(
    Map<String, dynamic> json, {
    required int messageCount,
  }) {
    return ConversationModel(
      conversationId: json['conversation_id'],
      title: json['title']?.toString().isNotEmpty == true
          ? json['title']
          : 'Untitled Conversation',
      emotion: json['emotion'] ?? 'Neutral',
      updatedAt: DateTime.parse(json['updated_at']),
      messageCount: messageCount,
      moodScore: json['mood_score'] ?? 0,
    );
  }
}