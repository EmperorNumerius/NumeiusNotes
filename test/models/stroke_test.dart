import 'package:flutter_test/flutter_test.dart';
import 'package:notes_app/models/stroke.dart';
import 'package:notes_app/models/anchor_type.dart';
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

  group('Stroke.fromJson', () {
    test('handles valid JSON correctly', () {
      final json = {
        'points': [
          {'dx': 10.0, 'dy': 20.0},
          {'dx': 30.0, 'dy': 40.0}
        ],
        'color': 0xFF00FF00,
        'width': 5.0,
        'anchorType': 'pdfPage',
        'pageIndex': 2,
        'normalizedPoints': [
          {'dx': 0.1, 'dy': 0.2},
          {'dx': 0.3, 'dy': 0.4}
        ],
        'relativeTimestamp': 12345,
      };

      final stroke = Stroke.fromJson(json);

      expect(stroke.points.length, 2);
      expect(stroke.points[0], const Offset(10, 20));
      expect(stroke.color.toARGB32(), 0xFF00FF00);
      expect(stroke.width, 5.0);
      expect(stroke.anchorType, AnchorType.pdfPage);
      expect(stroke.pageIndex, 2);
      expect(stroke.normalizedPoints?.length, 2);
      expect(stroke.normalizedPoints?[0], const Offset(0.1, 0.2));
      expect(stroke.relativeTimestamp, 12345);
    });

    test('handles missing optional fields by using defaults', () {
      final json = {
        'points': [
          {'dx': 10.0, 'dy': 20.0}
        ],
        'color': 0xFF000000,
        'width': 2.0,
      };

      final stroke = Stroke.fromJson(json);

      expect(stroke.points.length, 1);
      // anchorType inference logic: normalizedRaw == null ? AnchorType.canvas : AnchorType.pdfPage (if anchorRaw null)
      expect(stroke.anchorType, AnchorType.canvas);
      expect(stroke.pageIndex, 0);
      expect(stroke.normalizedPoints, isNull);
      expect(stroke.relativeTimestamp, isNull);
    });

    test('handles null fields gracefully', () {
      final json = {
        'points': null,
        'color': null,
        'width': null,
        'anchorType': null,
        'pageIndex': null,
        'normalizedPoints': null,
        'relativeTimestamp': null,
      };

      final stroke = Stroke.fromJson(json);

      expect(stroke.points, isEmpty);
      expect(stroke.color, const Color(0xFFFFFFFF)); // Default color
      expect(stroke.width, 2.0); // Default width
      expect(stroke.anchorType, AnchorType.canvas); // Default anchor
      expect(stroke.pageIndex, 0); // Default pageIndex
      expect(stroke.normalizedPoints, isNull);
      expect(stroke.relativeTimestamp, isNull);
    });

    test('handles missing points key gracefully', () {
      final json = <String, dynamic>{};
      final stroke = Stroke.fromJson(json);
      expect(stroke.points, isEmpty);
      expect(stroke.color, const Color(0xFFFFFFFF));
      expect(stroke.width, 2.0);
    });

    test('handles malformed point objects gracefully', () {
      final json = {
        'points': [
          {'dx': 10.0}, // missing dy
          {'dy': 20.0}, // missing dx
          {}, // empty
        ],
        'color': 0xFF000000,
        'width': 2.0,
      };

      final stroke = Stroke.fromJson(json);
      // Expectation: robust implementation should probably default missing coords to 0.0
      expect(stroke.points.length, 3);
      expect(stroke.points[0], const Offset(10.0, 0.0));
      expect(stroke.points[1], const Offset(0.0, 20.0));
      expect(stroke.points[2], const Offset(0.0, 0.0));
    });
  });
}
