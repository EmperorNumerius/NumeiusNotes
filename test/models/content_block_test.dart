import 'package:flutter_test/flutter_test.dart';
import 'package:notes_app/models/content_block.dart';
import 'package:notes_app/models/anchor_type.dart';

void main() {
  group('ContentBlock Anchor Logic Tests', () {
    test('updateNormalizedAnchor calculates correct normalized coordinates', () {
      final block = ContentBlock(id: '1', x: 100, y: 200);
      block.updateNormalizedAnchor(viewportWidth: 1000, viewportHeight: 2000);

      expect(block.normalizedX, closeTo(0.1, 0.0001));
      expect(block.normalizedY, closeTo(0.1, 0.0001));
      expect(block.anchorType, AnchorType.pdfPage);
    });

    test('updateNormalizedAnchor clamps coordinates to [0, 1]', () {
      final block = ContentBlock(id: '1', x: -50, y: 2500);
      block.updateNormalizedAnchor(viewportWidth: 1000, viewportHeight: 2000);

      expect(block.normalizedX, 0.0);
      expect(block.normalizedY, 1.0);
      expect(block.anchorType, AnchorType.pdfPage);
    });

    test('updateNormalizedAnchor handles zero or negative viewport dimensions', () {
      final block = ContentBlock(id: '1', x: 50, y: 50);

      // Test with zero viewport
      block.updateNormalizedAnchor(viewportWidth: 0, viewportHeight: 0);
      // Expected behavior: viewport defaults to 1.0.
      // 50 / 1.0 = 50, clamped to 1.0
      expect(block.normalizedX, 1.0);
      expect(block.normalizedY, 1.0);

      // Test with negative viewport
      block.updateNormalizedAnchor(viewportWidth: -100, viewportHeight: -100);
      // Expected behavior: viewport defaults to 1.0.
      expect(block.normalizedX, 1.0);
      expect(block.normalizedY, 1.0);
    });

    test('updateNormalizedAnchor updates page index if provided', () {
      final block = ContentBlock(id: '1', pageIndex: 0);
      block.updateNormalizedAnchor(viewportWidth: 100, viewportHeight: 100, page: 5);

      expect(block.pageIndex, 5);
    });

    test('updateCanvasAnchor updates coordinates and resets normalized anchor', () {
      final block = ContentBlock(
        id: '1',
        normalizedX: 0.5,
        normalizedY: 0.5,
        anchorType: AnchorType.pdfPage
      );

      block.updateCanvasAnchor(worldX: 300, worldY: 400);

      expect(block.x, 300);
      expect(block.y, 400);
      expect(block.anchorType, AnchorType.canvas);
      expect(block.normalizedX, isNull);
      expect(block.normalizedY, isNull);
    });

    test('fromJson respects explicit anchorType', () {
      final json = {
        'id': '1',
        'anchorType': 'pdfPage',
        'normalizedX': 0.5,
        'normalizedY': 0.5,
      };
      final block = ContentBlock.fromJson(json);
      expect(block.anchorType, AnchorType.pdfPage);

      final jsonCanvas = {
        'id': '2',
        'anchorType': 'canvas',
        'normalizedX': 0.5, // Explicit anchorType takes precedence over inferred type
      };
      final blockCanvas = ContentBlock.fromJson(jsonCanvas);
      expect(blockCanvas.anchorType, AnchorType.canvas);
    });

    test('fromJson infers pdfPage anchor from normalized coordinates', () {
      final json = {
        'id': '1',
        // No anchorType
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
    test('fromJson defaults to canvas anchor if no info provided', () {
      final json = {
        'id': '1',
        // No anchorType, no normalized coordinates
      };
      final block = ContentBlock.fromJson(json);
      expect(block.anchorType, AnchorType.canvas);
    });
  });
}
