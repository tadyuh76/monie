import 'package:equatable/equatable.dart';
import 'package:monie/features/ai_chat/domain/entities/chat_message.dart';

/// Events for AIChatBloc
abstract class AIChatEvent extends Equatable {
  const AIChatEvent();

  @override
  List<Object?> get props => [];
}

/// Initialize chat session with user data
class InitializeChatEvent extends AIChatEvent {
  final String userId;

  const InitializeChatEvent(this.userId);

  @override
  List<Object?> get props => [userId];
}

/// Send a message to AI
class SendMessageEvent extends AIChatEvent {
  final String userId;
  final String message;

  const SendMessageEvent({
    required this.userId,
    required this.message,
  });

  @override
  List<Object?> get props => [userId, message];
}

/// Clear chat history
class ClearChatEvent extends AIChatEvent {
  const ClearChatEvent();
}

/// Message received from AI (internal event)
class MessageReceivedEvent extends AIChatEvent {
  final ChatMessage message;

  const MessageReceivedEvent(this.message);

  @override
  List<Object?> get props => [message];
}

/// Update message status (internal event)
class UpdateMessageStatusEvent extends AIChatEvent {
  final String messageId;
  final MessageStatus status;

  const UpdateMessageStatusEvent({
    required this.messageId,
    required this.status,
  });

  @override
  List<Object?> get props => [messageId, status];
}
