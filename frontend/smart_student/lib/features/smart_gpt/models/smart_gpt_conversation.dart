import 'package:equatable/equatable.dart';

import 'smart_gpt_message.dart';

/// A saved SmartGPT chat session, shown in the history screen.
class SmartGptConversation extends Equatable {
  final String id;
  final String title;
  final List<SmartGptMessage> messages;
  final DateTime updatedAt;

  const SmartGptConversation({
    required this.id,
    required this.title,
    required this.messages,
    required this.updatedAt,
  });

  /// Builds a conversation from a live message list, deriving the title from
  /// the first user message.
  factory SmartGptConversation.fromMessages({
    required String id,
    required List<SmartGptMessage> messages,
  }) {
    final firstUser = messages.firstWhere(
      (m) => m.isUser,
      orElse: () => messages.isNotEmpty
          ? messages.first
          : const SmartGptMessage(
              id: '',
              text: 'New chat',
              sender: SmartGptSender.user,
            ),
    );
    var title = firstUser.text.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (title.length > 48) title = '${title.substring(0, 48)}…';
    return SmartGptConversation(
      id: id,
      title: title.isEmpty ? 'New chat' : title,
      messages: messages,
      updatedAt: DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'updatedAt': updatedAt.toIso8601String(),
        'messages': messages
            .map((m) => {
                  'id': m.id,
                  'text': m.text,
                  'sender': m.sender.name,
                  'isError': m.isError,
                })
            .toList(),
      };

  factory SmartGptConversation.fromJson(Map<String, dynamic> json) {
    final messages = (json['messages'] as List? ?? [])
        .map((e) => e as Map<String, dynamic>)
        .map(
          (m) => SmartGptMessage(
            id: m['id']?.toString() ?? '',
            text: m['text']?.toString() ?? '',
            sender: m['sender'] == 'user'
                ? SmartGptSender.user
                : SmartGptSender.ai,
            isError: m['isError'] == true,
            animate: false,
          ),
        )
        .toList();
    return SmartGptConversation(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? 'New chat',
      messages: messages,
      updatedAt:
          DateTime.tryParse(json['updatedAt']?.toString() ?? '') ??
              DateTime.now(),
    );
  }

  @override
  List<Object?> get props => [id, title, messages, updatedAt];
}
