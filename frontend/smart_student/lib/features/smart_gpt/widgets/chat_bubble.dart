import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../models/smart_gpt_message.dart';
import 'animated_answer_text.dart';

/// A single chat bubble. User messages align right with a gradient fill; AI
/// messages align left on a light surface with an AI avatar.
class ChatBubble extends StatelessWidget {
  final SmartGptMessage message;

  /// Whether this AI bubble should animate its reveal (only the freshly added
  /// AI answer animates).
  final bool animate;
  final VoidCallback? onProgress;

  const ChatBubble({
    super.key,
    required this.message,
    this.animate = false,
    this.onProgress,
  });

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;
    final screenWidth = MediaQuery.of(context).size.width;
    // User bubbles stay compact; AI answers use most of the width so long
    // explanations don't get squeezed into a narrow column.
    final maxWidth = isUser ? screenWidth * 0.78 : screenWidth * 0.95;

    final bubble = Container(
      constraints: BoxConstraints(maxWidth: maxWidth),
      padding: EdgeInsets.symmetric(
        horizontal: isUser ? 16 : 14,
        vertical: isUser ? 12 : 12,
      ),
      decoration: BoxDecoration(
        gradient: isUser ? AppColors.smartGptGradient : null,
        color: isUser
            ? null
            : (message.isError
                ? AppColors.redTint
                : AppColors.surfaceLight),
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(20),
          topRight: const Radius.circular(20),
          bottomLeft: Radius.circular(isUser ? 20 : 6),
          bottomRight: Radius.circular(isUser ? 6 : 20),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: _buildText(context, isUser),
    );

    final row = Row(
      mainAxisAlignment:
          isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!isUser) ...[
          _AiAvatar(isError: message.isError),
          const SizedBox(width: 8),
        ],
        Flexible(child: bubble),
      ],
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: _FadeIn(child: row),
    );
  }

  Widget _buildText(BuildContext context, bool isUser) {
    if (isUser) {
      return Text(
        message.text,
        style: AppTextStyles.bodyLarge.copyWith(
          color: Colors.white,
          height: 1.4,
        ),
      );
    }

    // Errors are plain, friendly sentences — render them as simple text.
    if (message.isError) {
      return Text(
        message.text,
        style: AppTextStyles.bodyLarge.copyWith(
          color: AppColors.accentRed,
          height: 1.5,
        ),
      );
    }

    final style = AppTextStyles.bodyLarge.copyWith(
      color: AppColors.textPrimary,
      height: 1.5,
    );

    if (message.animate && animate) {
      return AnimatedAnswerText(
        text: message.text,
        animate: true,
        onProgress: onProgress,
        builder: (context, visible) => _markdown(context, visible, style),
      );
    }

    return _markdown(context, message.text, style);
  }

  Widget _markdown(BuildContext context, String data, TextStyle style) {
    return MarkdownBody(
      data: data,
      shrinkWrap: true,
      styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
        p: style,
        listBullet: style,
        strong: style.copyWith(fontWeight: FontWeight.w700),
        em: style.copyWith(fontStyle: FontStyle.italic),
        a: style.copyWith(
          color: AppColors.primaryBlue,
          decoration: TextDecoration.underline,
        ),
        h1: style.copyWith(fontSize: 22, fontWeight: FontWeight.w800),
        h2: style.copyWith(fontSize: 20, fontWeight: FontWeight.w700),
        h3: style.copyWith(fontSize: 18, fontWeight: FontWeight.w700),
        code: style.copyWith(
          fontFamily: 'monospace',
          backgroundColor: AppColors.backgroundLight,
          color: AppColors.primaryBlueDark,
        ),
        codeblockDecoration: BoxDecoration(
          color: AppColors.backgroundLight,
          borderRadius: BorderRadius.circular(10),
        ),
        blockquoteDecoration: BoxDecoration(
          color: AppColors.purpleTint,
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}

class _AiAvatar extends StatelessWidget {
  final bool isError;

  const _AiAvatar({this.isError = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        gradient: isError ? null : AppColors.smartGptGradient,
        color: isError ? AppColors.accentRed : null,
        shape: BoxShape.circle,
      ),
      child: Icon(
        isError ? Icons.error_outline_rounded : Icons.auto_awesome_rounded,
        color: Colors.white,
        size: 18,
      ),
    );
  }
}

class _FadeIn extends StatefulWidget {
  final Widget child;

  const _FadeIn({required this.child});

  @override
  State<_FadeIn> createState() => _FadeInState();
}

class _FadeInState extends State<_FadeIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 320),
  )..forward();

  late final Animation<double> _fade = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeOut,
  );

  late final Animation<Offset> _slide = Tween<Offset>(
    begin: const Offset(0, 0.08),
    end: Offset.zero,
  ).animate(_fade);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(position: _slide, child: widget.child),
    );
  }
}
