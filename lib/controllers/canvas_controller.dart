import 'package:flutter/material.dart';
import 'package:notes_app/models/stroke.dart';

/// Drawing tools the user can select.
enum DrawingTool {
  pen,
  finePen,
  calligraphy,
  highlighter,
  highlighterThick,
  eraser,
  partialEraser,
  select,
}

/// Controls the drawing canvas — manages strokes, undo/redo, current tool settings.
class CanvasController extends ChangeNotifier {
  List<Stroke> _strokes = [];
  final List<List<Stroke>> _undoStack = [];
  final List<List<Stroke>> _redoStack = [];
  Stroke? _currentStroke;

  Color _currentColor = Colors.white;
  double _currentWidth = 2.5;
  DrawingTool _currentTool = DrawingTool.pen;

  /// Whether to show only strokes up to a certain playback time.
  bool playbackMode = false;
  int playbackTimeMs = 0;

  List<Stroke> get strokes => _strokes;
  Stroke? get currentStroke => _currentStroke;
  Color get currentColor => _currentColor;
  double get currentWidth => _currentWidth;
  DrawingTool get currentTool => _currentTool;

  bool get isEraser =>
      _currentTool == DrawingTool.eraser ||
      _currentTool == DrawingTool.partialEraser;

  bool get isSelectMode => _currentTool == DrawingTool.select;

  /// True when a drawing tool (any pen/highlighter/eraser) is active.
  bool get isDrawingToolActive => _currentTool != DrawingTool.select;

  /// Strokes visible in current state (all, or filtered by playback time).
  List<Stroke> get visibleStrokes {
    if (!playbackMode) return _strokes;
    return _strokes
        .where((s) =>
            s.relativeTimestamp == null ||
            s.relativeTimestamp! <= playbackTimeMs)
        .toList();
  }

  void setColor(Color c) {
    _currentColor = c;
    if (_currentTool == DrawingTool.eraser ||
        _currentTool == DrawingTool.partialEraser ||
        _currentTool == DrawingTool.select) {
      _currentTool = DrawingTool.pen;
    }
    notifyListeners();
  }

  void setWidth(double w) {
    _currentWidth = w;
    notifyListeners();
  }

  void setTool(DrawingTool tool) {
    _currentTool = tool;
    notifyListeners();
  }

  void setPlaybackTime(int ms) {
    playbackTimeMs = ms;
    notifyListeners();
  }

  void setPlaybackMode(bool v) {
    playbackMode = v;
    notifyListeners();
  }

  void loadStrokes(List<Stroke> strokes) {
    _strokes = List<Stroke>.from(strokes);
    _undoStack.clear();
    _redoStack.clear();
    notifyListeners();
  }

  /// Compute stroke width based on tool type and pressure.
  double _computeWidth({double? pressure}) {
    switch (_currentTool) {
      case DrawingTool.finePen:
        return pressure != null ? 1.0 * (0.5 + pressure * 0.5) : 1.0;
      case DrawingTool.calligraphy:
        return pressure != null ? _currentWidth * (0.3 + pressure * 1.4) : _currentWidth * 1.2;
      case DrawingTool.highlighter:
        return 12.0;
      case DrawingTool.highlighterThick:
        return 20.0;
      case DrawingTool.pen:
      default:
        return pressure != null ? _currentWidth * (0.5 + pressure) : _currentWidth;
    }
  }

  /// Compute stroke color based on tool type.
  Color _computeColor() {
    switch (_currentTool) {
      case DrawingTool.highlighter:
        return _currentColor.withAlpha(80);
      case DrawingTool.highlighterThick:
        return _currentColor.withAlpha(65);
      default:
        return _currentColor;
    }
  }

  void startStroke(Offset point, {int? relativeTimestamp, double? pressure}) {
    if (_currentTool == DrawingTool.eraser) {
      _eraseAt(point);
      return;
    }
    if (_currentTool == DrawingTool.partialEraser) {
      _partialEraseAt(point);
      return;
    }
    if (_currentTool == DrawingTool.select) return;

    _currentStroke = Stroke(
      points: [point],
      color: _computeColor(),
      width: _computeWidth(pressure: pressure),
      relativeTimestamp: relativeTimestamp,
    );
    notifyListeners();
  }

  void addPoint(Offset point, {double? pressure}) {
    if (_currentTool == DrawingTool.eraser) {
      _eraseAt(point);
      return;
    }
    if (_currentTool == DrawingTool.partialEraser) {
      _partialEraseAt(point);
      return;
    }
    if (_currentStroke != null) {
      _currentStroke = _currentStroke!.copyWith(
        points: [..._currentStroke!.points, point],
      );
      notifyListeners();
    }
  }

  void endStroke() {
    if (_currentStroke != null && _currentStroke!.points.length >= 2) {
      _undoStack.add(List<Stroke>.from(_strokes));
      _redoStack.clear();
      _strokes.add(_currentStroke!);
    }
    _currentStroke = null;
    notifyListeners();
  }

  void undo() {
    if (_undoStack.isNotEmpty) {
      _redoStack.add(List<Stroke>.from(_strokes));
      _strokes = _undoStack.removeLast();
      notifyListeners();
    }
  }

  void redo() {
    if (_redoStack.isNotEmpty) {
      _undoStack.add(List<Stroke>.from(_strokes));
      _strokes = _redoStack.removeLast();
      notifyListeners();
    }
  }

  /// Full-stroke eraser — removes entire stroke if any point is within range.
  void _eraseAt(Offset point) {
    final before = _strokes.length;
    final eraserRect = Rect.fromCircle(center: point, radius: 20);
    _strokes.removeWhere((s) {
      if (!s.boundingBox.overlaps(eraserRect)) return false;
      for (final p in s.points) {
        if ((p - point).distance < 20) return true;
      }
      return false;
    });
    if (_strokes.length != before) notifyListeners();
  }

  /// Partial eraser — removes only the points near the eraser, splitting strokes.
  void _partialEraseAt(Offset point) {
    const radius = 12.0;
    final eraserRect = Rect.fromCircle(center: point, radius: radius);
    bool changed = false;
    final newStrokes = <Stroke>[];

    for (final stroke in _strokes) {
      // Check if any point is within range
      bool hasErasedPoint = false;
      if (stroke.boundingBox.overlaps(eraserRect)) {
        for (final p in stroke.points) {
          if ((p - point).distance < radius) {
            hasErasedPoint = true;
            break;
          }
        }
      }

      if (!hasErasedPoint) {
        newStrokes.add(stroke);
        continue;
      }

      changed = true;
      // Split the stroke into segments, omitting erased points
      List<Offset> segment = [];
      for (final p in stroke.points) {
        if ((p - point).distance < radius) {
          // End current segment
          if (segment.length >= 2) {
            newStrokes.add(stroke.copyWith(points: List<Offset>.from(segment)));
          }
          segment = [];
        } else {
          segment.add(p);
        }
      }
      // Add remaining segment
      if (segment.length >= 2) {
        newStrokes.add(stroke.copyWith(points: List<Offset>.from(segment)));
      }
    }

    if (changed) {
      _strokes = newStrokes;
      notifyListeners();
    }
  }

  void clear() {
    _undoStack.add(List<Stroke>.from(_strokes));
    _redoStack.clear();
    _strokes.clear();
    notifyListeners();
  }
}
