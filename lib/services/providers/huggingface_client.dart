import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:notes_app/models/flashcard.dart';
import 'package:notes_app/models/quiz.dart';
import 'package:notes_app/services/ai_generation_service.dart';

class HuggingFaceClient implements AiGenerationService {
  HuggingFaceClient({required this.apiKey, this.model = 'HuggingFaceH4/zephyr-7b-beta'});

  final String apiKey;
  final String model;

  @override
  Future<List<QuizQuestion>> generateQuiz(AiGenerationContext context) {
    return _withRetry(() async {
      final payload = await _invokeModel(_quizPrompt(context));
      return parseAndValidateQuiz(payload);
    });
  }

  @override
  Future<List<Flashcard>> generateFlashcards(AiGenerationContext context) {
    return _withRetry(() async {
      final payload = await _invokeModel(_flashcardPrompt(context));
      return parseAndValidateFlashcards(payload);
    });
  }

  Future<T> _withRetry<T>(Future<T> Function() operation) async {
    const delays = [Duration(milliseconds: 400), Duration(seconds: 1), Duration(seconds: 2)];

    Object? lastError;
    for (var i = 0; i < delays.length; i++) {
      try {
        return await operation();
      } catch (error) {
        lastError = error;
        if (i < delays.length - 1) {
          await Future.delayed(delays[i]);
        }
      }
    }

    if (lastError is AiGenerationException) {
      throw lastError;
    }

    throw AiGenerationException(
      'Hugging Face request failed: $lastError',
      userMessage: 'Generation failed. Please check your API key or try later.',
    );
  }

  Future<String> _invokeModel(String prompt) async {
    final response = await http
        .post(
          Uri.parse('https://api-inference.huggingface.co/models/$model'),
          headers: {
            'Authorization': 'Bearer $apiKey',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'inputs': prompt,
            'parameters': {
              'max_new_tokens': 900,
              'return_full_text': false,
              'temperature': 0.2,
            },
          }),
        )
        .timeout(const Duration(seconds: 60));

    if (response.statusCode == 429) {
      throw AiGenerationException(
        'Hugging Face quota exhausted',
        userMessage: 'You hit provider quota limits. Please try again later.',
      );
    }

    if (response.statusCode >= 400) {
      throw AiGenerationException(
        'Hugging Face request failed: ${response.statusCode} ${response.body}',
        userMessage: 'Generation failed. Verify your Hugging Face key and model.',
      );
    }

    final decoded = jsonDecode(response.body);
    if (decoded is List && decoded.isNotEmpty) {
      final item = decoded.first;
      if (item is Map<String, dynamic> && item['generated_text'] is String) {
        return item['generated_text'] as String;
      }
    }

    throw AiGenerationException(
      'Unexpected Hugging Face response: ${response.body}',
      userMessage: 'Unexpected provider response. Please try again.',
    );
  }
}

String _quizPrompt(AiGenerationContext context) => '''
Generate exactly 5 multiple-choice quiz questions from the context.
Return STRICT JSON ONLY (no markdown, no prose) with this schema:
{
  "questions": [
    {
      "question": "...",
      "options": ["A", "B", "C", "D"],
      "correctAnswerIndex": 0,
      "explanation": "..."
    }
  ]
}

Context:
${context.toPrompt()}
''';

String _flashcardPrompt(AiGenerationContext context) => '''
Generate 12 study flashcards from the context.
Return STRICT JSON ONLY (no markdown, no prose) with this schema:
{
  "flashcards": [
    {
      "front": "...",
      "back": "...",
      "easeFactor": 250,
      "intervalDays": 1,
      "repetitions": 0,
      "nextReviewAt": null
    }
  ]
}

Context:
${context.toPrompt()}
''';
