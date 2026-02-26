import 'dart:convert';

import 'package:notes_app/models/flashcard.dart';
import 'package:notes_app/models/quiz.dart';

class AiGenerationContext {
  final String noteTitle;
  final String noteText;
  final String transcription;
  final String blockText;

  const AiGenerationContext({
    required this.noteTitle,
    required this.noteText,
    required this.transcription,
    required this.blockText,
  });

  String toPrompt() {
    return '''
Note title: $noteTitle

Note text:
$noteText

Transcription:
$transcription

Block content:
$blockText
''';
  }
}

abstract class AiGenerationService {
  Future<List<QuizQuestion>> generateQuiz(AiGenerationContext context);

  Future<List<Flashcard>> generateFlashcards(AiGenerationContext context);
}

class AiGenerationException implements Exception {
  final String message;
  final String userMessage;

  AiGenerationException(this.message, {required this.userMessage});

  @override
  String toString() => message;
}

List<QuizQuestion> parseAndValidateQuiz(String body) {
  dynamic decoded;
  try {
    decoded = jsonDecode(body);
  } on FormatException catch (_) {
    throw AiGenerationException(
      'Quiz payload was not valid JSON',
      userMessage: 'AI response format was invalid. Please try again.',
    );
  }

  if (decoded is! Map<String, dynamic>) {
    throw AiGenerationException(
      'Quiz payload was not a JSON object',
      userMessage: 'AI response format was invalid. Please try again.',
    );
  }

  final items = decoded['questions'];
  if (items is! List) {
    throw AiGenerationException(
      'Missing questions array',
      userMessage: 'AI response format was invalid. Please try again.',
    );
  }

  final questions = items
      .map((item) => QuizQuestion.fromJson(item as Map<String, dynamic>))
      .where((question) => question.isValid)
      .toList();

  if (questions.isEmpty) {
    throw AiGenerationException(
      'No valid quiz questions found',
      userMessage: 'Could not generate quiz questions from this note.',
    );
  }

  return questions;
  return _parseAndValidateResponse(
    body: body,
    jsonKey: 'questions',
    fromJson: (json) => QuizQuestion.fromJson(json),
    isValid: (question) => question.isValid,
    payloadType: 'Quiz',
    emptyErrorMessage: 'No valid quiz questions found',
    emptyUserMessage: 'Could not generate quiz questions from this note.',
  );
}

List<Flashcard> parseAndValidateFlashcards(String body) {
  return _parseAndValidateResponse(
    body: body,
    jsonKey: 'flashcards',
    fromJson: (json) => Flashcard.fromJson(json),
    isValid: (card) => card.isValid,
    payloadType: 'Flashcard',
    emptyErrorMessage: 'No valid flashcards found',
    emptyUserMessage: 'Could not generate flashcards from this note.',
  );
}

List<T> _parseAndValidateResponse<T>({
  required String body,
  required String jsonKey,
  required T Function(Map<String, dynamic>) fromJson,
  required bool Function(T) isValid,
  required String payloadType,
  required String emptyErrorMessage,
  required String emptyUserMessage,
}) {
  final decoded = jsonDecode(body);
  if (decoded is! Map<String, dynamic>) {
    throw AiGenerationException(
      '$payloadType payload was not a JSON object',
      userMessage: 'AI response format was invalid. Please try again.',
    );
  }

  final items = decoded[jsonKey];
  if (items is! List) {
    throw AiGenerationException(
      'Missing $jsonKey array',
      userMessage: 'AI response format was invalid. Please try again.',
    );
  }

  final results = items
      .map((item) => fromJson(item as Map<String, dynamic>))
      .where(isValid)
      .toList();

  if (results.isEmpty) {
    throw AiGenerationException(
      emptyErrorMessage,
      userMessage: emptyUserMessage,
    );
  }

  return results;
}
