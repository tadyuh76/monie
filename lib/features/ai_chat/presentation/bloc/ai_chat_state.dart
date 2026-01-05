import 'package:equatable/equatable.dart';
import 'package:monie/features/ai_chat/domain/entities/chat_message.dart';

/// States for AIChatBloc
class AIChatState extends Equatable {
  final List<ChatMessage> messages;
  final bool isTyping;
  final bool isInitialized;
  final String? error;

  const AIChatState({
    this.messages = const [],
    this.isTyping = false,
    this.isInitialized = false,
    this.error,
  });

  AIChatState copyWith({
    List<ChatMessage>? messages,
    bool? isTyping,
    bool? isInitialized,
    String? error,
  }) {
    return AIChatState(
      messages: messages ?? this.messages,
      isTyping: isTyping ?? this.isTyping,
      isInitialized: isInitialized ?? this.isInitialized,
      error: error,
    );
  }

  @override
  List<Object?> get props => [messages, isTyping, isInitialized, error];
}
