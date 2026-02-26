import 'package:flutter_test/flutter_test.dart';
import 'package:notes_app/models/quiz.dart';
import 'package:notes_app/services/ai_generation_service.dart';

void main() {
  group('parseAndValidateQuiz', () {
    test('returns valid quiz questions from a correct JSON payload', () {
      const json = '''
      {
        "questions": [
          {
            "question": "What is Flutter?",
            "options": ["SDK", "Language", "IDE", "OS"],
            "correctAnswerIndex": 0,
            "explanation": "Flutter is a UI toolkit."
          },
          {
            "question": "Which language is used?",
            "options": ["Java", "Dart", "Swift", "Kotlin"],
            "correctAnswerIndex": 1,
            "explanation": "Dart is used."
          }
        ]
      }
      ''';

      final result = parseAndValidateQuiz(json);

      expect(result.length, 2);
      expect(result[0].question, 'What is Flutter?');
      expect(result[0].options, ['SDK', 'Language', 'IDE', 'OS']);
      expect(result[0].correctAnswerIndex, 0);
      expect(result[0].explanation, 'Flutter is a UI toolkit.');

      expect(result[1].question, 'Which language is used?');
      expect(result[1].options, ['Java', 'Dart', 'Swift', 'Kotlin']);
      expect(result[1].correctAnswerIndex, 1);
      expect(result[1].explanation, 'Dart is used.');
    });

    test('throws AiGenerationException on malformed JSON', () {
      const json = '{ "questions": [ ... '; // Invalid JSON
      expect(
        () => parseAndValidateQuiz(json),
        throwsA(isA<AiGenerationException>()),
      );
    });

    test('throws AiGenerationException if root is not a Map', () {
      const json = '["Just an array"]';
      expect(
        () => parseAndValidateQuiz(json),
        throwsA(isA<AiGenerationException>()),
      );
    });

    test('throws AiGenerationException if "questions" key is missing', () {
      const json = '{"foo": "bar"}';
      expect(
        () => parseAndValidateQuiz(json),
        throwsA(isA<AiGenerationException>()),
      );
    });

    test('throws AiGenerationException if "questions" is not a List', () {
      const json = '{"questions": "not a list"}';
      expect(
        () => parseAndValidateQuiz(json),
        throwsA(isA<AiGenerationException>()),
      );
    });

    test('filters out invalid questions and returns valid ones', () {
      const json = '''
      {
        "questions": [
          {
            "question": "Valid Question",
            "options": ["A", "B"],
            "correctAnswerIndex": 0,
            "explanation": "Valid."
          },
          {
            "question": "",
            "options": ["A", "B"],
            "correctAnswerIndex": 0,
            "explanation": "Invalid: Empty question"
          },
          {
            "question": "Invalid: Too few options",
            "options": ["A"],
            "correctAnswerIndex": 0,
            "explanation": "Invalid"
          },
          {
            "question": "Invalid: Bad index",
            "options": ["A", "B"],
            "correctAnswerIndex": 5,
            "explanation": "Invalid"
          }
        ]
      }
      ''';

      final result = parseAndValidateQuiz(json);
      expect(result.length, 1);
      expect(result[0].question, 'Valid Question');
    });

    test('throws AiGenerationException if no valid questions remain', () {
      const json = '''
      {
        "questions": [
          {
            "question": "",
            "options": ["A", "B"],
            "correctAnswerIndex": 0,
            "explanation": "Invalid"
          }
        ]
      }
      ''';
      expect(
        () => parseAndValidateQuiz(json),
        throwsA(isA<AiGenerationException>()),
      );
    });

    test('throws AiGenerationException if "questions" array is empty', () {
      const json = '{"questions": []}';
      expect(
        () => parseAndValidateQuiz(json),
        throwsA(isA<AiGenerationException>()),
      );
    });
  });
}
