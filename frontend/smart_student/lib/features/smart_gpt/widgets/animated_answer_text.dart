import 'dart:async';

import 'package:flutter/material.dart';

/// Reveals [text] gradually, character-by-character, the first time it is
/// shown (ChatGPT-style typing effect). Once fully revealed it stays revealed
/// across rebuilds. Pass [animate] = false to show the full text instantly.
///
/// The visible substring is rendered through [builder] so callers can format
/// it however they like (e.g. as Markdown).
class AnimatedAnswerText extends StatefulWidget {
  final String text;
  final bool animate;

  /// Builds the widget for the currently visible portion of [text].
  final Widget Function(BuildContext context, String visibleText) builder;

  /// Called on every reveal tick so the parent can keep the list scrolled to
  /// the bottom while typing.
  final VoidCallback? onProgress;

  const AnimatedAnswerText({
    super.key,
    required this.text,
    required this.builder,
    this.animate = true,
    this.onProgress,
  });

  @override
  State<AnimatedAnswerText> createState() => _AnimatedAnswerTextState();
}

class _AnimatedAnswerTextState extends State<AnimatedAnswerText> {
  Timer? _timer;
  int _visibleChars = 0;
  late final int _step;

  static const _charInterval = Duration(milliseconds: 24);

  @override
  void initState() {
    super.initState();
    if (widget.animate) {
      // Reveal more characters per tick for longer answers so the markdown is
      // not re-parsed thousands of times (keeps long responses smooth) while
      // short answers still feel like they are being typed out.
      _step = (widget.text.length / 90).ceil().clamp(2, 12);
      _startTyping();
    } else {
      _visibleChars = widget.text.length;
    }
  }

  void _startTyping() {
    _timer = Timer.periodic(_charInterval, (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_visibleChars >= widget.text.length) {
        timer.cancel();
        return;
      }
      setState(() {
        _visibleChars = (_visibleChars + _step).clamp(0, widget.text.length);
      });
      widget.onProgress?.call();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final visible = widget.text.substring(
      0,
      _visibleChars.clamp(0, widget.text.length),
    );
    return widget.builder(context, visible);
  }
}
