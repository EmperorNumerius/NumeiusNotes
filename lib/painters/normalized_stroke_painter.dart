import 'package:flutter/material.dart';
import 'package:notes_app/models/stroke.dart';

/// CustomPainter that renders strokes stored as normalised [0,1] coordinates
/// mapped onto a [pageRect] inside the PDF viewer overlay.
///
/// Using a Flutter widget-level painter (vs pdfrx's [pagePaintCallbacks])
/// guarantees repaints happen on every Flutter rebuild, so newly drawn
/// annotations appear immediately without waiting for tile-cache invalidation.
class NormalizedStrokePainter extends CustomPainter {
  final List<Stroke> strokes;
  final Rect pageRect;

  const NormalizedStrokePainter({
    required this.strokes,
    required this.pageRect,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final stroke in strokes) {
      final pts = stroke.normalizedPoints;
      if (pts == null || pts.length < 2) continue;

      final paint = Paint()
        ..color = stroke.color
        ..strokeWidth = stroke.width
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke
        ..isAntiAlias = true;

      final path = Path();
      final mapped = pts.map((p) {
        return Offset(
          pageRect.left + p.dx * pageRect.width,
          pageRect.top + p.dy * pageRect.height,
        );
      }).toList();

      path.moveTo(mapped.first.dx, mapped.first.dy);
      if (mapped.length == 2) {
        path.lineTo(mapped[1].dx, mapped[1].dy);
      } else {
        for (var i = 1; i < mapped.length - 1; i++) {
          final p0 = mapped[i];
          final p1 = mapped[i + 1];
          final midX = (p0.dx + p1.dx) / 2;
          final midY = (p0.dy + p1.dy) / 2;
          path.quadraticBezierTo(p0.dx, p0.dy, midX, midY);
        }
        path.lineTo(mapped.last.dx, mapped.last.dy);
      }

      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant NormalizedStrokePainter oldDelegate) =>
      strokes != oldDelegate.strokes || pageRect != oldDelegate.pageRect;
}
