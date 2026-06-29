import 'package:flutter_bloc/flutter_bloc.dart';

import '../models/smart_gpt_conversation.dart';
import '../models/smart_gpt_message.dart';
import '../repositories/smart_gpt_repository.dart';
import 'smart_gpt_state.dart';

class SmartGptCubit extends Cubit<SmartGptState> {
  final SmartGptRepository _repository;

  SmartGptCubit(this._repository) : super(const SmartGptState());

  int _counter = 0;
  String _conversationId = _freshConversationId();

  static String _freshConversationId() =>
      'conv-${DateTime.now().microsecondsSinceEpoch}';

  String _nextId() {
    _counter++;
    return '${DateTime.now().microsecondsSinceEpoch}-$_counter';
  }

  Future<void> sendMessage(String text) async {
    final question = text.trim();
    if (question.isEmpty || state.isAwaitingResponse) return;

    final userMessage = SmartGptMessage.user(_nextId(), question);
    emit(
      state.copyWith(
        messages: [...state.messages, userMessage],
        isAwaitingResponse: true,
      ),
    );

    try {
      final answer = await _repository.ask(question);
      // The screen (and this per-route cubit) may have been closed while the
      // request was in flight — never emit after that.
      if (isClosed) return;
      emit(
        state.copyWith(
          messages: [...state.messages, SmartGptMessage.ai(_nextId(), answer)],
          isAwaitingResponse: false,
        ),
      );
    } on SmartGptException catch (e) {
      if (isClosed) return;
      emit(
        state.copyWith(
          messages: [
            ...state.messages,
            SmartGptMessage.error(_nextId(), e.message),
          ],
          isAwaitingResponse: false,
        ),
      );
    } catch (_) {
      if (isClosed) return;
      emit(
        state.copyWith(
          messages: [
            ...state.messages,
            SmartGptMessage.error(
              _nextId(),
              'Something unexpected happened. Please try again.',
            ),
          ],
          isAwaitingResponse: false,
        ),
      );
    }

    await _persist();
  }

  Future<void> _persist() async {
    if (state.messages.isEmpty) return;
    final conversation = SmartGptConversation.fromMessages(
      id: _conversationId,
      messages: state.messages,
    );
    await _repository.saveConversation(conversation);
  }

  /// Saves the current chat (if any) and starts a fresh conversation.
  Future<void> startNewChat() async {
    await _persist();
    if (isClosed) return;
    _conversationId = _freshConversationId();
    emit(const SmartGptState());
  }

  /// Returns the saved chat history (newest first).
  Future<List<SmartGptConversation>> loadHistory() =>
      _repository.getConversations();

  /// Deletes a saved conversation. If it is the one currently open, the chat
  /// view is reset to a fresh conversation.
  Future<void> deleteConversation(String id) async {
    await _repository.deleteConversation(id);
    if (isClosed) return;
    if (id == _conversationId) {
      _conversationId = _freshConversationId();
      emit(const SmartGptState());
    }
  }

  /// Loads a previously saved conversation into the chat view.
  void loadConversation(SmartGptConversation conversation) {
    _conversationId = conversation.id;
    emit(
      SmartGptState(
        messages: conversation.messages
            .map(
              (m) => SmartGptMessage(
                id: m.id,
                text: m.text,
                sender: m.sender,
                isError: m.isError,
              ),
            )
            .toList(),
      ),
    );
  }

  void clearConversation() => startNewChat();
}
