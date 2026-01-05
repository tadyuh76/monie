import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:monie/core/localization/app_localizations.dart';
import 'package:monie/core/themes/app_colors.dart';
import 'package:monie/features/ai_chat/domain/entities/chat_message.dart';
import 'package:monie/features/ai_chat/presentation/bloc/ai_chat_bloc.dart';
import 'package:monie/features/ai_chat/presentation/bloc/ai_chat_event.dart';
import 'package:monie/features/ai_chat/presentation/bloc/ai_chat_state.dart';
import 'package:monie/features/authentication/presentation/bloc/auth_bloc.dart';
import 'package:monie/features/authentication/presentation/bloc/auth_state.dart';

/// Full screen AI chat page
class AIChatPage extends StatefulWidget {
  const AIChatPage({super.key});

  @override
  State<AIChatPage> createState() => _AIChatPageState();
}

class _AIChatPageState extends State<AIChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _initializeChat();
  }

  void _initializeChat() {
    final authState = context.read<AuthBloc>().state;
    if (authState is Authenticated) {
      context.read<AIChatBloc>().add(InitializeChatEvent(authState.user.id));
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;

    final authState = context.read<AuthBloc>().state;
    if (authState is Authenticated) {
      context.read<AIChatBloc>().add(SendMessageEvent(
            userId: authState.user.id,
            message: message,
          ));
      _messageController.clear();
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: isDarkMode ? AppColors.background : Colors.grey[100],
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.auto_awesome,
                color: AppColors.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Text(context.tr('ai assistant')),
          ],
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<AIChatBloc>().add(const ClearChatEvent());
              _initializeChat();
            },
            tooltip: 'New conversation',
          ),
        ],
      ),
      body: Column(
        children: [
          // Messages list
          Expanded(
            child: BlocConsumer<AIChatBloc, AIChatState>(
              listener: (context, state) {
                _scrollToBottom();
              },
              builder: (context, state) {
                if (state.messages.isEmpty && !state.isTyping) {
                  return _buildEmptyState(isDarkMode, textTheme);
                }

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: state.messages.length + (state.isTyping ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == state.messages.length && state.isTyping) {
                      return _buildTypingIndicator(isDarkMode);
                    }
                    return _buildMessageBubble(
                      context,
                      state.messages[index],
                      isDarkMode,
                      textTheme,
                    );
                  },
                );
              },
            ),
          ),

          // Suggested questions
          BlocBuilder<AIChatBloc, AIChatState>(
            builder: (context, state) {
              if (state.messages.length <= 1 && !state.isTyping) {
                return _buildSuggestedQuestions(isDarkMode, textTheme);
              }
              return const SizedBox.shrink();
            },
          ),

          // Input area
          _buildInputArea(isDarkMode, textTheme),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isDarkMode, TextTheme textTheme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.chat_bubble_outline,
              size: 48,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Start a conversation',
            style: textTheme.titleLarge?.copyWith(
              color: isDarkMode ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Ask me anything about your finances',
            style: textTheme.bodyMedium?.copyWith(
              color: isDarkMode ? Colors.white54 : Colors.black45,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(
    BuildContext context,
    ChatMessage message,
    bool isDarkMode,
    TextTheme textTheme,
  ) {
    final isUser = message.isUser;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.auto_awesome,
                color: AppColors.primary,
                size: 18,
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              decoration: BoxDecoration(
                color: isUser
                    ? AppColors.primary
                    : (isDarkMode ? AppColors.cardDark : Colors.white),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isUser ? 16 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 16),
                ),
                boxShadow: isDarkMode
                    ? []
                    : [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 5,
                          offset: const Offset(0, 2),
                        ),
                      ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.content,
                    style: textTheme.bodyMedium?.copyWith(
                      color: isUser
                          ? Colors.white
                          : (isDarkMode ? Colors.white : Colors.black87),
                    ),
                  ),
                  if (message.status == MessageStatus.error)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 14,
                            color: Colors.red[400],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Failed to send',
                            style: textTheme.bodySmall?.copyWith(
                              color: Colors.red[400],
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.primary.withValues(alpha: 0.15),
              child: Icon(
                Icons.person,
                color: AppColors.primary,
                size: 18,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTypingIndicator(bool isDarkMode) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.auto_awesome,
              color: AppColors.primary,
              size: 18,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isDarkMode ? AppColors.cardDark : Colors.white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
                bottomLeft: Radius.circular(4),
                bottomRight: Radius.circular(16),
              ),
            ),
            child: _TypingDots(),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestedQuestions(bool isDarkMode, TextTheme textTheme) {
    final suggestions = [
      'How am I doing financially this month?',
      'What are my top spending categories?',
      'How can I save more money?',
      'Analyze my budget progress',
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: suggestions.map((suggestion) {
          return InkWell(
            onTap: () {
              _messageController.text = suggestion;
              _sendMessage();
            },
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isDarkMode
                    ? AppColors.cardDark
                    : AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.3),
                ),
              ),
              child: Text(
                suggestion,
                style: textTheme.bodySmall?.copyWith(
                  color: AppColors.primary,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildInputArea(bool isDarkMode, TextTheme textTheme) {
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 12,
        bottom: MediaQuery.of(context).padding.bottom + 12,
      ),
      decoration: BoxDecoration(
        color: isDarkMode ? AppColors.cardDark : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              focusNode: _focusNode,
              decoration: InputDecoration(
                hintText: context.tr('type message'),
                hintStyle: TextStyle(
                  color: isDarkMode ? Colors.white38 : Colors.black38,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: isDarkMode
                    ? Colors.white.withValues(alpha: 0.1)
                    : Colors.grey[100],
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
              ),
              style: textTheme.bodyMedium?.copyWith(
                color: isDarkMode ? Colors.white : Colors.black87,
              ),
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _sendMessage(),
              maxLines: null,
            ),
          ),
          const SizedBox(width: 12),
          BlocBuilder<AIChatBloc, AIChatState>(
            builder: (context, state) {
              return Container(
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  onPressed: state.isTyping ? null : _sendMessage,
                  icon: state.isTyping
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.send, color: Colors.white),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

/// Animated typing indicator dots
class _TypingDots extends StatefulWidget {
  @override
  State<_TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<_TypingDots>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _animations;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(
      3,
      (index) => AnimationController(
        duration: const Duration(milliseconds: 400),
        vsync: this,
      ),
    );

    _animations = _controllers.map((controller) {
      return Tween<double>(begin: 0, end: 6).animate(
        CurvedAnimation(parent: controller, curve: Curves.easeInOut),
      );
    }).toList();

    _startAnimation();
  }

  void _startAnimation() async {
    while (mounted) {
      for (int i = 0; i < 3; i++) {
        if (!mounted) return;
        _controllers[i].forward().then((_) {
          if (mounted) _controllers[i].reverse();
        });
        await Future.delayed(const Duration(milliseconds: 150));
      }
      await Future.delayed(const Duration(milliseconds: 400));
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (index) {
        return AnimatedBuilder(
          animation: _animations[index],
          builder: (context, child) {
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 2),
              child: Transform.translate(
                offset: Offset(0, -_animations[index].value),
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.6),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            );
          },
        );
      }),
    );
  }
}
