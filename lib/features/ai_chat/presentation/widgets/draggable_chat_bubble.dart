import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:monie/features/ai_chat/presentation/pages/ai_chat_page.dart';

/// Draggable floating chat bubble with beautiful animations
class DraggableChatBubble extends StatefulWidget {
  const DraggableChatBubble({super.key});

  @override
  State<DraggableChatBubble> createState() => _DraggableChatBubbleState();
}

class _DraggableChatBubbleState extends State<DraggableChatBubble>
    with TickerProviderStateMixin {
  Offset _position = const Offset(20, 100);
  bool _isDragging = false;
  
  late AnimationController _pulseController;
  late AnimationController _rotateController;
  late AnimationController _glowController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _rotateAnimation;
  late Animation<double> _glowAnimation;

  // Beautiful gradient colors
  static const _gradientColors = [
    Color(0xFF667EEA), // Purple blue
    Color(0xFF764BA2), // Deep purple
    Color(0xFFf093fb), // Pink
    Color(0xFFf5576c), // Coral
  ];

  @override
  void initState() {
    super.initState();
    
    // Pulse animation - subtle breathing effect
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Rotate animation for gradient
    _rotateController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    )..repeat();
    _rotateAnimation = Tween<double>(begin: 0, end: 2 * math.pi).animate(
      CurvedAnimation(parent: _rotateController, curve: Curves.linear),
    );

    // Glow animation
    _glowController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
    _glowAnimation = Tween<double>(begin: 0.3, end: 0.7).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _rotateController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  void _openChat() {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => const AIChatPage(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.1),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutCubic,
              )),
              child: child,
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    return Positioned(
      left: _position.dx,
      top: _position.dy,
      child: GestureDetector(
        onPanStart: (_) => setState(() => _isDragging = true),
        onPanUpdate: (details) {
          setState(() {
            _position = Offset(
              (_position.dx + details.delta.dx).clamp(0, screenSize.width - 64),
              (_position.dy + details.delta.dy).clamp(0, screenSize.height - 64),
            );
          });
        },
        onPanEnd: (_) {
          setState(() => _isDragging = false);
          // Snap to edge
          final centerX = _position.dx + 32;
          final shouldSnapRight = centerX > screenSize.width / 2;
          setState(() {
            _position = Offset(
              shouldSnapRight ? screenSize.width - 72 : 8,
              _position.dy,
            );
          });
        },
        onTap: _openChat,
        child: AnimatedBuilder(
          animation: Listenable.merge([_pulseAnimation, _rotateAnimation, _glowAnimation]),
          builder: (context, child) {
            return Transform.scale(
              scale: _isDragging ? 1.15 : _pulseAnimation.value,
              child: Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    // Outer glow
                    BoxShadow(
                      color: _gradientColors[0].withValues(alpha: _glowAnimation.value),
                      blurRadius: 20,
                      spreadRadius: 4,
                    ),
                    // Inner shadow
                    BoxShadow(
                      color: _gradientColors[1].withValues(alpha: 0.5),
                      blurRadius: 8,
                      spreadRadius: 0,
                    ),
                  ],
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Rotating gradient border
                    Transform.rotate(
                      angle: _rotateAnimation.value,
                      child: Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: SweepGradient(
                            colors: [
                              ..._gradientColors,
                              _gradientColors[0],
                            ],
                          ),
                        ),
                      ),
                    ),
                    // Inner circle with icon
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(0xFF1a1a2e),
                            Color(0xFF16213e),
                          ],
                        ),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.1),
                          width: 1,
                        ),
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Sparkle icon with shimmer
                          ShaderMask(
                            shaderCallback: (bounds) {
                              return LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Colors.white,
                                  _gradientColors[0],
                                  _gradientColors[2],
                                  Colors.white,
                                ],
                                stops: const [0.0, 0.3, 0.7, 1.0],
                                transform: GradientRotation(_rotateAnimation.value),
                              ).createShader(bounds);
                            },
                            child: const Icon(
                              Icons.auto_awesome,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Small notification dot
                    Positioned(
                      top: 4,
                      right: 4,
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFF00D9A5),
                          border: Border.all(
                            color: const Color(0xFF1a1a2e),
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF00D9A5).withValues(alpha: 0.5),
                              blurRadius: 4,
                              spreadRadius: 0,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
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
