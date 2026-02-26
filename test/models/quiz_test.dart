import 'package:flutter_test/flutter_test.dart';
import 'package:notes_app/models/quiz.dart';

void main() {
  group('QuizQuestion Validation', () {
    test('isValid returns true for valid question', () {
      final question = QuizQuestion(
        question: 'What is 2+2?',
        options: ['3', '4', '5'],
        correctAnswerIndex: 1,
        explanation: 'Math',
      );
      expect(question.isValid, isTrue);
    });

    test('isValid returns false when question is empty', () {
      final question = QuizQuestion(
        question: '',
        options: ['A', 'B'],
        correctAnswerIndex: 0,
        explanation: '',
      );
      expect(question.isValid, isFalse);
    });

    test('isValid returns false when question is whitespace', () {
      final question = QuizQuestion(
        question: '   ',
        options: ['A', 'B'],
        correctAnswerIndex: 0,
        explanation: '',
      );
      expect(question.isValid, isFalse);
    });

    test('isValid returns false when options length < 2', () {
      final question = QuizQuestion(
        question: 'Valid?',
        options: ['One'],
        correctAnswerIndex: 0,
        explanation: '',
      );
      expect(question.isValid, isFalse);
    });

    test('isValid returns false when correctAnswerIndex is negative', () {
      final question = QuizQuestion(
        question: 'Valid?',
        options: ['A', 'B'],
        correctAnswerIndex: -1,
        explanation: '',
      );
      expect(question.isValid, isFalse);
    });

    test('isValid returns false when correctAnswerIndex is out of bounds (equal length)', () {
      final question = QuizQuestion(
        question: 'Valid?',
        options: ['A', 'B'],
        correctAnswerIndex: 2,
        explanation: '',
      );
      expect(question.isValid, isFalse);
    });

    test('isValid returns false when correctAnswerIndex is out of bounds (greater than length)', () {
      final question = QuizQuestion(
        question: 'Valid?',
        options: ['A', 'B'],
        correctAnswerIndex: 3,
        explanation: '',
      );
      expect(question.isValid, isFalse);
    });
  });
}
