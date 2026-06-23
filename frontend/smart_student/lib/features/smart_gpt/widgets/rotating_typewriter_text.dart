import 'dart:async';

import 'package:flutter/material.dart';

/// Cycles through [phrases] with a typing-then-deleting "typewriter" effect.
/// Used inside the SmartGPT home promo card.
class RotatingTypewriterText extends StatefulWidget {
  final List<String> phrases;
  final TextStyle style;

  const RotatingTypewriterText({
    super.key,
    required this.phrases,
    required this.style,
  });

  @override
  State<RotatingTypewriterText> createState() => _RotatingTypewriterTextState();
}

class _RotatingTypewriterTextState extends State<RotatingTypewriterText> {
  Timer? _timer;
  int _phraseIndex = 0;
  int _charCount = 0;
  bool _deleting = false;

  static const _typingSpeed = Duration(milliseconds: 70);
  static const _deletingSpeed = Duration(milliseconds: 35);
  static const _holdDuration = Duration(milliseconds: 1100);

  @override
  void initState() {
    super.initState();
    _scheduleTick(_typingSpeed);
  }

  void _scheduleTick(Duration delay) {
    _timer?.cancel();
    _timer = Timer(delay, _tick);
  }

  void _tick() {
    if (!mounted || widget.phrases.isEmpty) return;
    final current = widget.phrases[_phraseIndex];

    if (!_deleting) {
      if (_charCount < current.length) {
        setState(() => _charCount++);
        _scheduleTick(_typingSpeed);
      } else {
        _deleting = true;
        _scheduleTick(_holdDuration);
      }
    } else {
      if (_charCount > 0) {
        setState(() => _charCount--);
        _scheduleTick(_deletingSpeed);
      } else {
        _deleting = false;
        _phraseIndex = (_phraseIndex + 1) % widget.phrases.length;
        _scheduleTick(_typingSpeed);
      }
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final current =
        widget.phrases.isEmpty ? '' : widget.phrases[_phraseIndex];
    final visible = current.substring(0, _charCount.clamp(0, current.length));

    return Row(
      children: [
        Flexible(
          child: Text(
            visible,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: widget.style,
          ),
        ),
        _BlinkingCursor(color: widget.style.color ?? Colors.white),
      ],
    );
  }
}

class _BlinkingCursor extends StatefulWidget {
  final Color color;

  const _BlinkingCursor({required this.color});

  @override
  State<_BlinkingCursor> createState() => _BlinkingCursorState();
}

class _BlinkingCursorState extends State<_BlinkingCursor>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 650),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _controller,
      child: Container(
        margin: const EdgeInsets.only(left: 2),
        width: 2,
        height: 16,
        color: widget.color,
      ),
    );
  }
}
