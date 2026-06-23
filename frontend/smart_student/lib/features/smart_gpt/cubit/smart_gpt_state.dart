import 'package:equatable/equatable.dart';

import '../models/smart_gpt_message.dart';

class SmartGptState extends Equatable {
  final List<SmartGptMessage> messages;

  /// True while waiting for the AI response (drives the typing indicator).
  final bool isAwaitingResponse;

  const SmartGptState({
    this.messages = const [],
    this.isAwaitingResponse = false,
  });

  bool get hasMessages => messages.isNotEmpty;

  SmartGptState copyWith({
    List<SmartGptMessage>? messages,
    bool? isAwaitingResponse,
  }) {
    return SmartGptState(
      messages: messages ?? this.messages,
      isAwaitingResponse: isAwaitingResponse ?? this.isAwaitingResponse,
    );
  }

  @override
  List<Object?> get props => [messages, isAwaitingResponse];
}
