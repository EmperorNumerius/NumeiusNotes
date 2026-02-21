import 'dart:ui';

/// A single drawn stroke on the canvas.
class Stroke {
  final List<Offset> points;
  final Color color;
  final double width;

  /// Milliseconds relative to the start of the audio recording.
  /// Null if no recording was active when the stroke was made.
  final int? relativeTimestamp;

  Stroke({
    required this.points,
    this.color = const Color(0xFFFFFFFF),
    this.width = 2.0,
    this.relativeTimestamp,
  });

  Map<String, dynamic> toJson() => {
        'points': points.map((p) => {'dx': p.dx, 'dy': p.dy}).toList(),
        'color': color.toARGB32(),
        'width': width,
        'relativeTimestamp': relativeTimestamp,
      };

  factory Stroke.fromJson(Map<String, dynamic> json) {
    return Stroke(
      points: (json['points'] as List)
          .map((p) => Offset(
                (p['dx'] as num).toDouble(),
                (p['dy'] as num).toDouble(),
              ))
          .toList(),
      color: Color(json['color'] as int),
      width: (json['width'] as num).toDouble(),
      relativeTimestamp: json['relativeTimestamp'] as int?,
    );
  }

  Stroke copyWith({
    List<Offset>? points,
    Color? color,
    double? width,
    int? relativeTimestamp,
  }) {
    return Stroke(
      points: points ?? this.points,
      color: color ?? this.color,
      width: width ?? this.width,
      relativeTimestamp: relativeTimestamp ?? this.relativeTimestamp,
    );
  }
}
