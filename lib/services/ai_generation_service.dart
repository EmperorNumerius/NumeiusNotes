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
}

List<Flashcard> parseAndValidateFlashcards(String body) {
  final decoded = jsonDecode(body);
  if (decoded is! Map<String, dynamic>) {
    throw AiGenerationException(
      'Flashcard payload was not a JSON object',
      userMessage: 'AI response format was invalid. Please try again.',
    );
  }

  final items = decoded['flashcards'];
  if (items is! List) {
    throw AiGenerationException(
      'Missing flashcards array',
      userMessage: 'AI response format was invalid. Please try again.',
    );
  }

  final cards = items
      .map((item) => Flashcard.fromJson(item as Map<String, dynamic>))
      .where((card) => card.isValid)
      .toList();

  if (cards.isEmpty) {
    throw AiGenerationException(
      'No valid flashcards found',
      userMessage: 'Could not generate flashcards from this note.',
    );
  }

  return cards;
}
