import 'package:flutter/material.dart';
import 'package:monie/core/themes/app_colors.dart';
import 'package:monie/features/ai_chat/presentation/pages/ai_chat_page.dart';

/// Draggable floating chat bubble
class DraggableChatBubble extends StatefulWidget {
  const DraggableChatBubble({super.key});

  @override
  State<DraggableChatBubble> createState() => _DraggableChatBubbleState();
}

class _DraggableChatBubbleState extends State<DraggableChatBubble>
    with SingleTickerProviderStateMixin {
  Offset _position = const Offset(20, 100);
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    return Positioned(
      left: _position.dx,
      top: _position.dy,
      child: GestureDetector(
        onPanUpdate: (details) {
          setState(() {
            _position = Offset(
              (_position.dx + details.delta.dx).clamp(0, screenSize.width - 60),
              (_position.dy + details.delta.dy).clamp(0, screenSize.height - 60),
            );
          });
        },
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AIChatPage()),
          );
        },
        child: AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _pulseAnimation.value,
              child: child,
            );
          },
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF667EEA), // Purple
                  Color(0xFF764BA2), // Deep purple
                ],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF667EEA).withValues(alpha: 0.5),
                  blurRadius: 12,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: const Icon(
              Icons.auto_awesome,
              color: Colors.white,
              size: 28,
            ),
          ),
        ),
      ),
    );
  }
}

/// Manager to show/hide the chat bubble overlay
class ChatBubbleManager {
  static OverlayEntry? _overlayEntry;

  /// Show the chat bubble
  static void show(BuildContext context) {
    if (_overlayEntry != null) return;

    _overlayEntry = OverlayEntry(
      builder: (context) => const DraggableChatBubble(),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  /// Hide the chat bubble
  static void hide() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  /// Toggle the chat bubble
  static void toggle(BuildContext context) {
    if (_overlayEntry != null) {
      hide();
    } else {
      show(context);
    }
  }

  /// Check if bubble is showing
  static bool get isShowing => _overlayEntry != null;
}
