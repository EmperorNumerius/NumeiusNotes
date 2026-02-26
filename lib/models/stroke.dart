import 'dart:ui';
import 'package:notes_app/models/anchor_type.dart';

/// A single drawn stroke on the canvas.
class Stroke {
  final List<Offset> points;
  final Color color;
  final double width;
  final AnchorType anchorType;

  /// Target page index in the PDF.
  final int pageIndex;

  /// Points normalized to [0, 1] within the PDF page bounds.
  ///
  /// When null, `points` are treated as legacy viewport coordinates.
  final List<Offset>? normalizedPoints;

  /// Milliseconds relative to the start of the audio recording.
  /// Null if no recording was active when the stroke was made.
  final int? relativeTimestamp;

  late final Rect boundingBox;

  Stroke({
    required this.points,
    this.color = const Color(0xFFFFFFFF),
    this.width = 2.0,
    this.anchorType = AnchorType.canvas,
    this.pageIndex = 0,
    this.normalizedPoints,
    this.relativeTimestamp,
  }) {
    boundingBox = _computeBoundingBox();
  }

  Rect _computeBoundingBox() {
    if (points.isEmpty) return Rect.zero;
    double minX = points[0].dx;
    double maxX = points[0].dx;
    double minY = points[0].dy;
    double maxY = points[0].dy;

    for (int i = 1; i < points.length; i++) {
      final p = points[i];
      if (p.dx < minX) {
        minX = p.dx;
      } else if (p.dx > maxX) {
        maxX = p.dx;
      }

      if (p.dy < minY) {
        minY = p.dy;
      } else if (p.dy > maxY) {
        maxY = p.dy;
      }
    }
    return Rect.fromLTRB(minX, minY, maxX, maxY);
  }

  Map<String, dynamic> toJson() => {
        'points': points.map((p) => {'dx': p.dx, 'dy': p.dy}).toList(),
        'color': color.toARGB32(),
        'width': width,
        'anchorType': anchorType.name,
        'pageIndex': pageIndex,
        'normalizedPoints': normalizedPoints
            ?.map((p) => {'dx': p.dx, 'dy': p.dy})
            .toList(),
        'relativeTimestamp': relativeTimestamp,
      };

  factory Stroke.fromJson(Map<String, dynamic> json) {
    final normalizedRaw = json['normalizedPoints'] as List?;
    final anchorRaw = json['anchorType'] as String?;
    final inferredAnchor = (anchorRaw != null &&
            AnchorType.values.any((v) => v.name == anchorRaw))
        ? AnchorType.values.firstWhere((v) => v.name == anchorRaw)
        : (normalizedRaw != null ? AnchorType.pdfPage : AnchorType.canvas);

    return Stroke(
      points: (json['points'] as List)
          .map((p) => Offset(
                (p['dx'] as num).toDouble(),
                (p['dy'] as num).toDouble(),
              ))
          .toList(),
      color: Color(json['color'] as int),
      width: (json['width'] as num).toDouble(),
      anchorType: inferredAnchor,
      pageIndex: (json['pageIndex'] as num?)?.toInt() ?? 0,
      normalizedPoints: normalizedRaw
          ?.map((p) => Offset(
                (p['dx'] as num).toDouble(),
                (p['dy'] as num).toDouble(),
              ))
          .toList(),
      relativeTimestamp: json['relativeTimestamp'] as int?,
    );
  }

  Stroke copyWith({
    List<Offset>? points,
    Color? color,
    double? width,
    AnchorType? anchorType,
    int? pageIndex,
    List<Offset>? normalizedPoints,
    bool clearNormalizedPoints = false,
    int? relativeTimestamp,
  }) {
    return Stroke(
      points: points ?? this.points,
      color: color ?? this.color,
      width: width ?? this.width,
      anchorType: anchorType ?? this.anchorType,
      pageIndex: pageIndex ?? this.pageIndex,
      normalizedPoints: clearNormalizedPoints
          ? null
          : (normalizedPoints ?? this.normalizedPoints),
      relativeTimestamp: relativeTimestamp ?? this.relativeTimestamp,
    );
  }

  /// Converts legacy viewport points into normalized page coordinates.
  Stroke withNormalizedPoints(Size viewportSize, {int? pageIndex}) {
    if (normalizedPoints != null || points.isEmpty) {
      return copyWith(pageIndex: pageIndex);
    }

    final vw = viewportSize.width <= 0 ? 1.0 : viewportSize.width;
    final vh = viewportSize.height <= 0 ? 1.0 : viewportSize.height;

    final normalized = points
        .map(
          (p) => Offset(
            (p.dx / vw).clamp(0.0, 1.0),
            (p.dy / vh).clamp(0.0, 1.0),
          ),
        )
        .toList();

    return copyWith(
      anchorType: AnchorType.pdfPage,
      normalizedPoints: normalized,
      pageIndex: pageIndex,
    );
  }

  /// Resolves stroke points in absolute PDF page coordinates.
  List<Offset> resolvePointsForPage(
    Size pageSize, {
    Size? fallbackViewportSize,
  }) {
    if (normalizedPoints != null && normalizedPoints!.isNotEmpty) {
      return normalizedPoints!
          .map((p) => Offset(p.dx * pageSize.width, p.dy * pageSize.height))
          .toList();
    }

    final viewport = fallbackViewportSize;
    if (viewport != null && viewport.width > 0 && viewport.height > 0) {
      return points
          .map(
            (p) => Offset(
              (p.dx / viewport.width) * pageSize.width,
              (p.dy / viewport.height) * pageSize.height,
            ),
          )
          .toList();
    }

    return points;
  }
}
