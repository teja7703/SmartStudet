import 'package:equatable/equatable.dart';

/// Who authored a chat message in the SmartGPT conversation.
enum SmartGptSender { user, ai }

/// A single message inside the SmartGPT chat conversation.
class SmartGptMessage extends Equatable {
  final String id;
  final String text;
  final SmartGptSender sender;

  /// True when the message represents a friendly error (rendered with a
  /// distinct style and never animated).
  final bool isError;

  /// True when the AI bubble should reveal its text gradually
  /// (character-by-character) the first time it is shown.
  final bool animate;

  const SmartGptMessage({
    required this.id,
    required this.text,
    required this.sender,
    this.isError = false,
    this.animate = false,
  });

  bool get isUser => sender == SmartGptSender.user;
  bool get isAi => sender == SmartGptSender.ai;

  factory SmartGptMessage.user(String id, String text) => SmartGptMessage(
        id: id,
        text: text,
        sender: SmartGptSender.user,
      );

  factory SmartGptMessage.ai(String id, String text, {bool animate = true}) =>
      SmartGptMessage(
        id: id,
        text: text,
        sender: SmartGptSender.ai,
        animate: animate,
      );

  factory SmartGptMessage.error(String id, String text) => SmartGptMessage(
        id: id,
        text: text,
        sender: SmartGptSender.ai,
        isError: true,
      );

  @override
  List<Object?> get props => [id, text, sender, isError, animate];
}
