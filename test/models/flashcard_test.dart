import 'package:flutter_test/flutter_test.dart';
import 'package:notes_app/models/flashcard.dart';

void main() {
  group('Flashcard validation', () {
    test('isValid returns true when front and back are not empty', () {
      final flashcard = Flashcard(front: 'Question', back: 'Answer');
      expect(flashcard.isValid, isTrue);
    });

    test('isValid returns false when front is empty', () {
      final flashcard = Flashcard(front: '', back: 'Answer');
      expect(flashcard.isValid, isFalse);
    });

    test('isValid returns false when back is empty', () {
      final flashcard = Flashcard(front: 'Question', back: '');
      expect(flashcard.isValid, isFalse);
    });

    test('isValid returns false when both are empty', () {
      final flashcard = Flashcard(front: '', back: '');
      expect(flashcard.isValid, isFalse);
    });

    test('isValid returns false when front is whitespace only', () {
      final flashcard = Flashcard(front: '   ', back: 'Answer');
      expect(flashcard.isValid, isFalse);
    });

    test('isValid returns false when back is whitespace only', () {
      final flashcard = Flashcard(front: 'Question', back: '  \t\n ');
      expect(flashcard.isValid, isFalse);
    });
  });

  group('Flashcard serialization', () {
    test('Flashcard to JSON and back should preserve data', () {
      final now = DateTime.now();
      final flashcard = Flashcard(
        front: 'Question',
        back: 'Answer',
        easeFactor: 260,
        intervalDays: 2,
        repetitions: 1,
        nextReviewAt: now,
      );

      final json = flashcard.toJson();
      final fromJson = Flashcard.fromJson(json);

      expect(fromJson.front, flashcard.front);
      expect(fromJson.back, flashcard.back);
      expect(fromJson.easeFactor, flashcard.easeFactor);
      expect(fromJson.intervalDays, flashcard.intervalDays);
      expect(fromJson.repetitions, flashcard.repetitions);
      // DateTime might lose some precision in ISO8601 string, but should be same minute
      expect(
        fromJson.nextReviewAt!.toIso8601String(),
        flashcard.nextReviewAt!.toIso8601String(),
      );
    });

    test('Flashcard fromJson handles empty JSON', () {
      final flashcard = Flashcard.fromJson({});
      expect(flashcard.front, '');
      expect(flashcard.back, '');
      expect(flashcard.easeFactor, 250);
      expect(flashcard.intervalDays, 1);
      expect(flashcard.repetitions, 0);
      expect(flashcard.nextReviewAt, isNull);
    });
  });

  group('FlashcardSet serialization', () {
    test('FlashcardSet to JSON and back should preserve data', () {
      final cards = [
        Flashcard(front: 'q1', back: 'a1'),
        Flashcard(front: 'q2', back: 'a2'),
      ];
      final set = FlashcardSet(
        id: 'set-1',
        sourceDocId: 'doc-1',
        cards: cards,
      );

      final json = set.toJson();
      final fromJson = FlashcardSet.fromJson(json);

      expect(fromJson.id, set.id);
      expect(fromJson.sourceDocId, set.sourceDocId);
      expect(fromJson.cards.length, set.cards.length);
      expect(fromJson.cards[0].front, 'q1');
      expect(fromJson.cards[1].back, 'a2');
    });

    test('FlashcardSet fromJson handles empty JSON', () {
      final set = FlashcardSet.fromJson({});
      expect(set.id, '');
      expect(set.sourceDocId, '');
      expect(set.cards, isEmpty);
      expect(set.createdAt, isNotNull);
    });
  });
}
