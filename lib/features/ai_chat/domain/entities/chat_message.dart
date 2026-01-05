import 'package:equatable/equatable.dart';

/// Entity representing a chat message
class ChatMessage extends Equatable {
  final String id;
  final String content;
  final bool isUser;
  final DateTime timestamp;
  final MessageStatus status;

  const ChatMessage({
    required this.id,
    required this.content,
    required this.isUser,
    required this.timestamp,
    this.status = MessageStatus.sent,
  });

  ChatMessage copyWith({
    String? id,
    String? content,
    bool? isUser,
    DateTime? timestamp,
    MessageStatus? status,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      content: content ?? this.content,
      isUser: isUser ?? this.isUser,
      timestamp: timestamp ?? this.timestamp,
      status: status ?? this.status,
    );
  }

  @override
  List<Object?> get props => [id, content, isUser, timestamp, status];
}

enum MessageStatus {
  sending,
  sent,
  error,
}
