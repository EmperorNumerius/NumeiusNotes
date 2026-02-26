import 'package:flutter_test/flutter_test.dart';
import 'package:notes_app/models/content_block.dart';
import 'package:notes_app/models/anchor_type.dart';

void main() {
  group('ContentBlock.fromJson', () {
    test('parses valid ContentBlockType', () {
      final json = {
        'id': '1',
        'type': 'flashcard',
        'content': 'test',
        'anchorType': 'canvas',
      };
      final block = ContentBlock.fromJson(json);
      expect(block.type, ContentBlockType.flashcard);
    });

    test('parses invalid ContentBlockType as text', () {
      final json = {
        'id': '2',
        'type': 'unknownType',
        'content': 'test',
        'anchorType': 'canvas',
      };
      final block = ContentBlock.fromJson(json);
      expect(block.type, ContentBlockType.text);
    });

    test('parses missing ContentBlockType as text', () {
      final json = {
        'id': '3',
        'content': 'test',
        'anchorType': 'canvas',
      };
      final block = ContentBlock.fromJson(json);
      expect(block.type, ContentBlockType.text);
    });

    test('parses valid AnchorType', () {
      final json = {
        'id': '4',
        'type': 'text',
        'content': 'test',
        'anchorType': 'pdfPage',
      };
      final block = ContentBlock.fromJson(json);
      expect(block.anchorType, AnchorType.pdfPage);
    });

    test('infers AnchorType.pdfPage when anchorType is missing but normalized coords present', () {
      final json = {
        'id': '5',
        'type': 'text',
        'content': 'test',
        'normalizedX': 0.5,
        'normalizedY': 0.5,
      };
      final block = ContentBlock.fromJson(json);
      expect(block.anchorType, AnchorType.pdfPage);
    });

    test('infers AnchorType.canvas when anchorType is missing and normalized coords missing', () {
      final json = {
        'id': '6',
        'type': 'text',
        'content': 'test',
      };
      final block = ContentBlock.fromJson(json);
      expect(block.anchorType, AnchorType.canvas);
    });

    test('infers AnchorType.pdfPage when anchorType is invalid but normalized coords present', () {
      final json = {
        'id': '7',
        'type': 'text',
        'content': 'test',
        'anchorType': 'invalidAnchor',
        'normalizedX': 0.5,
        'normalizedY': 0.5,
      };
      final block = ContentBlock.fromJson(json);
      expect(block.anchorType, AnchorType.pdfPage);
    });

     test('infers AnchorType.canvas when anchorType is invalid and normalized coords missing', () {
      final json = {
        'id': '8',
        'type': 'text',
        'content': 'test',
        'anchorType': 'invalidAnchor',
      };
      final block = ContentBlock.fromJson(json);
      expect(block.anchorType, AnchorType.canvas);
    });
  });
}
