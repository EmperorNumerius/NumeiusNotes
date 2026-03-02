import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:notes_app/models/flashcard.dart';
import 'package:notes_app/models/quiz.dart';
import 'package:notes_app/services/ai_generation_service.dart';

/// AI generation client backed by the GitHub Copilot chat completions API.
///
/// Requires a GitHub personal access token (classic or fine-grained) with the
/// `copilot` scope, or a Copilot Business / Enterprise token.
class CopilotClient implements AiGenerationService {
  static const _endpoint = 'https://api.githubcopilot.com/chat/completions';
  static const _model = 'gpt-4o';
  static const _editorVersion = 'notes-app/1.0';

  final String apiKey;

  CopilotClient({required this.apiKey});

  @override
  Future<List<QuizQuestion>> generateQuiz(AiGenerationContext context) async {
    final text = await _chatCompletion(_quizPrompt(context));
    return parseAndValidateQuiz(text);
  }

  @override
  Future<List<Flashcard>> generateFlashcards(AiGenerationContext context) async {
    final text = await _chatCompletion(_flashcardPrompt(context));
    return parseAndValidateFlashcards(text);
  }

  Future<String> _chatCompletion(String prompt) async {
    final response = await http
        .post(
          Uri.parse(_endpoint),
          headers: {
            'Authorization': 'Bearer $apiKey',
            'Content-Type': 'application/json',
            'Editor-Version': _editorVersion,
            'Copilot-Integration-Id': 'copilot-chat',
          },
          body: jsonEncode({
            'model': _model,
            'messages': [
              {'role': 'user', 'content': prompt},
            ],
            'temperature': 0.2,
          }),
        )
        .timeout(const Duration(seconds: 60));

    if (response.statusCode == 401 || response.statusCode == 403) {
      throw AiGenerationException(
        'GitHub Copilot auth failed: ${response.statusCode} ${response.body}',
        userMessage:
            'Invalid Copilot token. Please check your GitHub token and ensure '
            'it has the copilot scope.',
      );
    }

    if (response.statusCode >= 400) {
      throw AiGenerationException(
        'GitHub Copilot request failed: ${response.statusCode} ${response.body}',
        userMessage: 'Copilot request failed. Check your token and try again.',
      );
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final choices = decoded['choices'] as List?;
    String? content;
    if (choices != null && choices.isNotEmpty) {
      final first = choices.first;
      if (first is Map) {
        final message = first['message'];
        if (message is Map) {
          content = message['content'] as String?;
        }
      }
    }

    if (content is String && content.trim().isNotEmpty) {
      return content;
    }

    throw AiGenerationException(
      'Unexpected Copilot response: ${response.body}',
      userMessage: 'Unexpected Copilot response. Please try again.',
    );
  }
}

String _quizPrompt(AiGenerationContext context) =>
    '''Return STRICT JSON ONLY.
{"questions":[{"question":"...","options":["...","...","...","..."],"correctAnswerIndex":0,"explanation":"..."}]}

Use this context:
${context.toPrompt()}
''';

String _flashcardPrompt(AiGenerationContext context) =>
    '''Return STRICT JSON ONLY.
{"flashcards":[{"front":"...","back":"...","easeFactor":250,"intervalDays":1,"repetitions":0,"nextReviewAt":null}]}

Use this context:
${context.toPrompt()}
''';
