import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../../../core/services/storage_service.dart';
import '../models/smart_gpt_conversation.dart';

/// Thrown by [SmartGptRepository] with a user-friendly message that can be
/// shown directly inside an AI error bubble.
class SmartGptException implements Exception {
  final String message;

  const SmartGptException(this.message);

  @override
  String toString() => message;
}

class SmartGptRepository {
  final ApiClient _apiClient;
  final StorageService _storageService;

  SmartGptRepository({
    required ApiClient apiClient,
    required StorageService storageService,
  })  : _apiClient = apiClient,
        _storageService = storageService;

  /// Sends [question] to the backend AI tutor and returns the answer text.
  ///
  /// Throws a [SmartGptException] with a friendly message for any failure
  /// (no internet, timeout, server error, empty response).
  Future<String> ask(String question) async {
    try {
      final response = await _apiClient.post(
        '/api/ai/ask',
        data: {'question': question},
      );

      final data = response.data;
      if (data is Map && data['success'] == true) {
        final answer = data['answer']?.toString().trim() ?? '';
        if (answer.isEmpty) {
          throw const SmartGptException(
            "I couldn't find an answer for that. Try rephrasing your "
            'question.',
          );
        }
        return answer;
      }

      final message = (data is Map && data['message'] != null)
          ? data['message'].toString()
          : 'Something went wrong while answering. Please try again.';
      throw SmartGptException(message);
    } on SmartGptException {
      rethrow;
    } on DioException catch (e) {
      throw SmartGptException(_mapDioError(e));
    } catch (_) {
      throw const SmartGptException(
        'Something unexpected happened. Please try again.',
      );
    }
  }

  String _mapDioError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'This is taking longer than usual. Please check your '
            'connection and try again.';
      case DioExceptionType.connectionError:
        return 'No internet connection. Please check your network and try '
            'again.';
      case DioExceptionType.badResponse:
        final code = e.response?.statusCode;
        return 'The server ran into a problem'
            '${code != null ? ' ($code)' : ''}. Please try again shortly.';
      case DioExceptionType.cancel:
        return 'The request was cancelled. Please try again.';
      default:
        return 'Unable to reach SmartGPT right now. Please try again.';
    }
  }

  // ---- Chat history -----------------------------------------------------

  Future<List<SmartGptConversation>> getConversations() async {
    final raw = await _storageService.getSmartGptConversations();
    return raw.map(SmartGptConversation.fromJson).toList();
  }

  Future<void> saveConversation(SmartGptConversation conversation) async {
    await _storageService.saveSmartGptConversation(conversation.toJson());
  }

  Future<void> deleteConversation(String id) async {
    await _storageService.deleteSmartGptConversation(id);
  }

  Future<void> clearHistory() async {
    await _storageService.clearSmartGptHistory();
  }
}
