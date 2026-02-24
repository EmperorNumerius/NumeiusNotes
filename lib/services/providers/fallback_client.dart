import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:notes_app/models/flashcard.dart';
import 'package:notes_app/models/quiz.dart';
import 'package:notes_app/services/ai_generation_service.dart';

class FallbackProviderClient implements AiGenerationService {
  final String apiKey;
  final String endpoint;
  final String model;

  FallbackProviderClient({
    required this.apiKey,
    required this.endpoint,
    required this.model,
  });

  @override
  Future<List<QuizQuestion>> generateQuiz(AiGenerationContext context) async {
    final jsonText = await _chatCompletion(_quizPrompt(context));
    return parseAndValidateQuiz(jsonText);
  }

  @override
  Future<List<Flashcard>> generateFlashcards(
    AiGenerationContext context,
  ) async {
    final jsonText = await _chatCompletion(_flashcardPrompt(context));
    return parseAndValidateFlashcards(jsonText);
  }

  Future<String> _chatCompletion(String prompt) async {
    final response = await http
        .post(
          Uri.parse(endpoint),
          headers: {
            'Authorization': 'Bearer $apiKey',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'model': model,
            'messages': [
              {'role': 'user', 'content': prompt},
            ],
            'temperature': 0.2,
          }),
        )
        .timeout(const Duration(seconds: 60));

    if (response.statusCode == 429) {
      throw AiGenerationException(
        'Fallback provider quota exhausted',
        userMessage: 'Free-tier quota is exhausted. Please try again later.',
      );
    }

    if (response.statusCode >= 400) {
      throw AiGenerationException(
        'Fallback provider request failed: ${response.statusCode} ${response.body}',
        userMessage:
            'Fallback provider request failed. Check endpoint, model, and key.',
      );
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final choices = decoded['choices'] as List?;
    String? content;
    if (choices != null && choices.isNotEmpty) {
      final firstChoice = choices.first;
      if (firstChoice is Map) {
        final message = firstChoice['message'];
        if (message is Map) {
          content = message['content'] as String?;
        }
      }
    }
    if (content is String && content.trim().isNotEmpty) {
      return content;
    }

    throw AiGenerationException(
      'Invalid fallback provider response: ${response.body}',
      userMessage: 'Unexpected fallback provider response.',
    );
  }
}

String _quizPrompt(AiGenerationContext context) =>
    '''
Return STRICT JSON ONLY.
{"questions":[{"question":"...","options":["...","...","...","..."],"correctAnswerIndex":0,"explanation":"..."}]}

Use this context:
${context.toPrompt()}
''';

String _flashcardPrompt(AiGenerationContext context) =>
    '''
Return STRICT JSON ONLY.
{"flashcards":[{"front":"...","back":"...","easeFactor":250,"intervalDays":1,"repetitions":0,"nextReviewAt":null}]}

Use this context:
${context.toPrompt()}
''';
