import 'package:flutter_test/flutter_test.dart';
import 'package:notes_app/models/document.dart';
import 'package:notes_app/models/stroke.dart';
import 'package:notes_app/models/content_block.dart';

void main() {
  group('NoteDocument', () {
    test('Default constructor values', () {
      final doc = NoteDocument(id: '123');

      expect(doc.id, '123');
      expect(doc.title, 'Untitled');
      expect(doc.folderId, isNull);
      expect(doc.subject, '');
      expect(doc.strokes, isEmpty);
      expect(doc.blocks, isEmpty);
      expect(doc.pdfWritebackEnabled, isTrue);
      expect(doc.pdfWritebackRevision, 0);
      expect(doc.pdfPageLayoutVersion, 1);
      expect(doc.createdAt, isNotNull);
      expect(doc.updatedAt, isNotNull);
    });

    test('toJson serialization', () {
      final now = DateTime.now();
      final stroke = Stroke(points: [Offset(10, 10)]);
      final block = ContentBlock(id: 'b1', content: 'test');

      final doc = NoteDocument(
        id: '123',
        title: 'My Note',
        folderId: 'f1',
        subject: 'Math',
        strokes: [stroke],
        blocks: [block],
        audioPath: 'audio.m4a',
        pdfPath: 'original.pdf',
        pdfWorkingPath: 'working.pdf',
        annotatedPdfPath: 'annotated.pdf',
        transcription: 'Hello world',
        createdAt: now,
        updatedAt: now,
      );

      final json = doc.toJson();

      expect(json['id'], '123');
      expect(json['title'], 'My Note');
      expect(json['folderId'], 'f1');
      expect(json['subject'], 'Math');
      expect(json['strokes'], hasLength(1));
      expect(json['blocks'], hasLength(1));
      expect(json['audioPath'], 'audio.m4a');
      // pdfPath is synchronized with pdfWorkingPath in the constructor
      expect(json['pdfPath'], 'working.pdf');
      expect(json['pdfWorkingPath'], 'working.pdf');
      expect(json['annotatedPdfPath'], 'annotated.pdf');
      expect(json['transcription'], 'Hello world');
      expect(json['createdAt'], now.toIso8601String());
      expect(json['updatedAt'], now.toIso8601String());
    });

    test('fromJson deserialization', () {
      final now = DateTime.now();
      final json = {
        'id': '123',
        'title': 'My Note',
        'folderId': 'f1',
        'subject': 'Math',
        'strokes': [
          {
            'points': [{'dx': 10, 'dy': 10}],
            'color': 0xFF000000,
            'width': 2.0,
            'pageIndex': 0,
          }
        ],
        'blocks': [
          {
            'id': 'b1',
            'type': 'text',
            'content': 'test',
          }
        ],
        'audioPath': 'audio.m4a',
        'pdfPath': 'original.pdf',
        'pdfWorkingPath': 'working.pdf',
        'annotatedPdfPath': 'annotated.pdf',
        'transcription': 'Hello world',
        'createdAt': now.toIso8601String(),
        'updatedAt': now.toIso8601String(),
      };

      final doc = NoteDocument.fromJson(json);

      expect(doc.id, '123');
      expect(doc.title, 'My Note');
      expect(doc.folderId, 'f1');
      expect(doc.subject, 'Math');
      expect(doc.strokes, hasLength(1));
      expect(doc.strokes.first.points.first, Offset(10, 10));
      expect(doc.blocks, hasLength(1));
      expect(doc.blocks.first.content, 'test');
      expect(doc.audioPath, 'audio.m4a');
      expect(doc.pdfPath, 'working.pdf'); // Note: pdfPath takes workingPath logic in constructor/fromJson
      expect(doc.pdfWorkingPath, 'working.pdf');
      expect(doc.annotatedPdfPath, 'annotated.pdf');
      expect(doc.transcription, 'Hello world');
      // Using closeTo for DateTime comparison due to potential precision loss in string conversion
      expect(doc.createdAt.difference(now).inMilliseconds.abs(), lessThan(100));
      expect(doc.updatedAt.difference(now).inMilliseconds.abs(), lessThan(100));
    });

    test('fromJson handles legacy PDF paths', () {
      final json = {
        'id': '123',
        'pdfPath': 'legacy.pdf',
        // pdfWorkingPath is missing
      };

      final doc = NoteDocument.fromJson(json);

      expect(doc.pdfPath, 'legacy.pdf');
      expect(doc.pdfWorkingPath, 'legacy.pdf');
    });

    test('fromJson null handling and defaults', () {
      final json = {'id': '123'};
      final doc = NoteDocument.fromJson(json);

      expect(doc.title, 'Untitled');
      expect(doc.folderId, isNull);
      expect(doc.subject, '');
      expect(doc.strokes, isEmpty);
      expect(doc.blocks, isEmpty);
      expect(doc.pdfWritebackEnabled, isTrue);
      expect(doc.pdfWritebackRevision, 0);
      expect(doc.createdAt, isNotNull);
      expect(doc.updatedAt, isNotNull);
    });

    test('Computed properties: activePdfPath and hasPdf', () {
      final doc1 = NoteDocument(id: '1', pdfPath: 'test.pdf');
      expect(doc1.activePdfPath, 'test.pdf');
      expect(doc1.hasPdf, isTrue);

      final doc2 = NoteDocument(id: '2', pdfWorkingPath: 'work.pdf');
      expect(doc2.activePdfPath, 'work.pdf');
      expect(doc2.hasPdf, isTrue);

      final doc3 = NoteDocument(id: '3');
      expect(doc3.activePdfPath, isNull);
      expect(doc3.hasPdf, isFalse);

      final doc4 = NoteDocument(id: '4', pdfPath: '');
      // If pdfPath is empty string, hasPdf checks if not empty
      expect(doc4.hasPdf, isFalse);
    });

    test('touch() updates updatedAt', () async {
      final doc = NoteDocument(id: '123');
      final initialUpdate = doc.updatedAt;

      await Future.delayed(const Duration(milliseconds: 10));
      doc.touch();

      expect(doc.updatedAt.isAfter(initialUpdate), isTrue);
    });
  });
}
