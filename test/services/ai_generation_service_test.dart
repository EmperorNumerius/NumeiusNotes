import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:notes_app/models/flashcard.dart';
import 'package:notes_app/models/quiz.dart';
import 'package:notes_app/services/ai_generation_service.dart';

void main() {
  group('AiGenerationService', () {
    group('parseAndValidateQuiz', () {
      test('parses valid quiz JSON', () {
        final json = {
          'questions': [
            {
              'question': 'What is 2+2?',
              'options': ['3', '4', '5'],
              'correctAnswerIndex': 1,
              'explanation': 'Math',
            },
          ],
        };
        final body = jsonEncode(json);
        final result = parseAndValidateQuiz(body);
        expect(result, isA<List<QuizQuestion>>());
        expect(result.length, 1);
        expect(result.first.question, 'What is 2+2?');
      });

      test('throws if body is not a JSON object', () {
        final body = '"string"';
        expect(
          () => parseAndValidateQuiz(body),
          throwsA(
            isA<AiGenerationException>().having(
              (e) => e.message,
              'message',
              'Quiz payload was not a JSON object',
            ),
          ),
        );
      });

      test('throws if questions key is missing', () {
        final json = {'wrongKey': []};
        final body = jsonEncode(json);
        expect(
          () => parseAndValidateQuiz(body),
          throwsA(
            isA<AiGenerationException>().having(
              (e) => e.message,
              'message',
              'Missing questions array',
            ),
          ),
        );
      });

      test('filters invalid questions and throws if empty', () {
        final json = {
          'questions': [
            {
              'question': '', // Invalid
              'options': ['3', '4'],
              'correctAnswerIndex': 1,
              'explanation': 'Math',
            },
          ],
        };
        final body = jsonEncode(json);
        expect(
          () => parseAndValidateQuiz(body),
          throwsA(
            isA<AiGenerationException>().having(
              (e) => e.message,
              'message',
              'No valid quiz questions found',
            ),
          ),
        );
      });
    });

    group('parseAndValidateFlashcards', () {
      test('parses valid flashcard JSON', () {
        final json = {
          'flashcards': [
            {'front': 'Front', 'back': 'Back'},
          ],
        };
        final body = jsonEncode(json);
        final result = parseAndValidateFlashcards(body);
        expect(result, isA<List<Flashcard>>());
        expect(result.length, 1);
        expect(result.first.front, 'Front');
      });

      test('throws if body is not a JSON object', () {
        final body = '"string"';
        expect(
          () => parseAndValidateFlashcards(body),
          throwsA(
            isA<AiGenerationException>().having(
              (e) => e.message,
              'message',
              'Flashcard payload was not a JSON object',
            ),
          ),
        );
      });

      test('throws if flashcards key is missing', () {
        final json = {'wrongKey': []};
        final body = jsonEncode(json);
        expect(
          () => parseAndValidateFlashcards(body),
          throwsA(
            isA<AiGenerationException>().having(
              (e) => e.message,
              'message',
              'Missing flashcards array',
            ),
          ),
        );
      });

      test('filters invalid flashcards and throws if empty', () {
        final json = {
          'flashcards': [
            {'front': '', 'back': 'Back'}, // Invalid
          ],
        };
        final body = jsonEncode(json);
        expect(
          () => parseAndValidateFlashcards(body),
          throwsA(
            isA<AiGenerationException>().having(
              (e) => e.message,
              'message',
              'No valid flashcards found',
            ),
          ),
        );
      });
    });
  });
}
