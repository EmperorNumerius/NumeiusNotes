import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:notes_app/models/content_block.dart';
import 'package:notes_app/models/stroke.dart';

void main() {
  test('Stroke serialization preserves page mapping + normalized points', () {
    final stroke = Stroke(
      points: const [Offset(10, 20), Offset(20, 40)],
      pageIndex: 2,
      normalizedPoints: const [Offset(0.1, 0.2), Offset(0.2, 0.4)],
      width: 3,
    );

    final decoded = Stroke.fromJson(stroke.toJson());

    expect(decoded.pageIndex, 2);
    expect(decoded.normalizedPoints, isNotNull);
    expect(decoded.normalizedPoints!.first.dx, closeTo(0.1, 1e-6));
  });

  test('Legacy stroke migrates gracefully with page 0 + viewport mapping', () {
    final legacyJson = {
      'points': [
        {'dx': 50.0, 'dy': 100.0},
        {'dx': 100.0, 'dy': 200.0},
      ],
      'color': const Color(0xFFFFFFFF).toARGB32(),
      'width': 2.0,
    };

    final stroke = Stroke.fromJson(legacyJson);
    final resolved = stroke.resolvePointsForPage(
      const Size(1000, 2000),
      fallbackViewportSize: const Size(500, 1000),
    );

    expect(stroke.pageIndex, 0);
    expect(resolved.first.dx, closeTo(100, 1e-6));
    expect(resolved.first.dy, closeTo(200, 1e-6));
  });

  test('ContentBlock serialization includes normalized anchor + page index', () {
    final block = ContentBlock(
      id: 'b1',
      pageIndex: 3,
      normalizedX: 0.25,
      normalizedY: 0.5,
      x: 10,
      y: 20,
    );

    final decoded = ContentBlock.fromJson(block.toJson());

    expect(decoded.pageIndex, 3);
    expect(decoded.normalizedX, closeTo(0.25, 1e-6));
    expect(decoded.normalizedY, closeTo(0.5, 1e-6));
  });
}
