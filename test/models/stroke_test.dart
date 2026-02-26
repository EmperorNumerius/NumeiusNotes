import 'package:flutter_test/flutter_test.dart';
import 'package:notes_app/models/stroke.dart';
import 'package:flutter/material.dart';

void main() {
  group('Stroke', () {
    test('boundingBox calculation is correct', () {
      final stroke = Stroke(points: [
        Offset(10, 10),
        Offset(20, 20),
        Offset(5, 5),
        Offset(15, 25),
      ]);

      // minX = 5, maxX = 20
      // minY = 5, maxY = 25
      final box = stroke.boundingBox;

      expect(box.left, 5);
      expect(box.right, 20);
      expect(box.top, 5);
      expect(box.bottom, 25);
    });

    test('boundingBox handles single point', () {
      final stroke = Stroke(points: [Offset(10, 10)]);
      final box = stroke.boundingBox;
      expect(box, Rect.fromLTRB(10, 10, 10, 10));
    });

    test('boundingBox handles empty points', () {
      final stroke = Stroke(points: []);
      final box = stroke.boundingBox;
      expect(box, Rect.zero);
    });

    test('copyWith recomputes boundingBox', () {
      final stroke = Stroke(points: [Offset(10, 10)]);
      final copy = stroke.copyWith(points: [Offset(20, 20)]);

      expect(stroke.boundingBox, Rect.fromLTRB(10, 10, 10, 10));
      expect(copy.boundingBox, Rect.fromLTRB(20, 20, 20, 20));
    });

    test('fromJson calculates boundingBox', () {
      final json = {
        'points': [
          {'dx': 0.0, 'dy': 0.0},
          {'dx': 100.0, 'dy': 100.0}
        ],
        'color': 0xFF000000,
        'width': 1.0,
        'anchorType': 'canvas'
      };
      final stroke = Stroke.fromJson(json);
      expect(stroke.boundingBox, Rect.fromLTRB(0, 0, 100, 100));
    });
  });
}
