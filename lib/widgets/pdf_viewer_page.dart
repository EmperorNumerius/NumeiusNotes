import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:provider/provider.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:notes_app/controllers/canvas_controller.dart';
import 'package:notes_app/controllers/audio_controller.dart';
import 'package:notes_app/controllers/document_manager.dart';
import 'package:notes_app/painters/ink_painter.dart';
import 'package:notes_app/models/content_block.dart';
import 'package:notes_app/models/stroke.dart';
import 'package:notes_app/widgets/code_block.dart';
import 'package:notes_app/widgets/latex_block.dart';
import 'package:notes_app/widgets/chemistry_block.dart';
import 'package:notes_app/widgets/calculator_block.dart';
import 'package:notes_app/widgets/draggable_block_shell.dart';
import 'package:uuid/uuid.dart';

/// PDF viewer with full annotation — ink drawing + draggable content blocks.
class PdfViewerPage extends StatefulWidget {
  final String pdfPath;

  const PdfViewerPage({super.key, required this.pdfPath});

  @override
  State<PdfViewerPage> createState() => _PdfViewerPageState();
}

class _PdfViewerPageState extends State<PdfViewerPage> {
  late PdfViewerController _pdfController;
  final _uuid = const Uuid();
  String? _draggingBlockId;
  final Map<String, TextEditingController> _textControllers = {};
  final Map<String, FocusNode> _textFocusNodes = {};
  final Map<String, Timer> _textSaveDebouncers = {};

  static const _textSaveDebounce = Duration(milliseconds: 700);

  @override
  void initState() {
    super.initState();
    _pdfController = PdfViewerController();
  }

  @override
  void dispose() {
    for (final timer in _textSaveDebouncers.values) {
      timer.cancel();
    }
    for (final controller in _textControllers.values) {
      controller.dispose();
    }
    for (final focusNode in _textFocusNodes.values) {
      focusNode.dispose();
    }
    super.dispose();
  }

  bool _shouldDraw(PointerEvent event, CanvasController ctrl) {
    if (event.kind == PointerDeviceKind.stylus ||
        event.kind == PointerDeviceKind.invertedStylus) {
      return true;
    }
    if (event.kind == PointerDeviceKind.touch) {
      return ctrl.isDrawingToolActive;
    }
    if (event.kind == PointerDeviceKind.mouse) {
      return ctrl.isDrawingToolActive;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<CanvasController>();
    final docMgr = context.watch<DocumentManager>();
    final audioCtrl = context.read<AudioController>();
    final doc = docMgr.activeDocument;

    if (doc == null || !File(widget.pdfPath).existsSync()) {
      return const Center(
        child: Text('PDF not found',
            style: TextStyle(color: Colors.white38)),
      );
    }

    _syncTextEditingResources(doc.blocks.cast<ContentBlock>());

    return Row(
      children: [
        // Left sidebar — block palette
        _buildBlockPalette(doc, docMgr),
        // PDF + annotations
        Expanded(
          child: Stack(
            children: [
              // PDF viewer base layer
              PdfViewer.file(
                widget.pdfPath,
                controller: _pdfController,
                params: PdfViewerParams(
                  backgroundColor: const Color(0xFF0A0A1A),
                  enableTextSelection: !ctrl.isDrawingToolActive,
                ),
              ),

              // Positioned content blocks (on top of PDF)
              ...doc.blocks.asMap().entries.map<Widget>((entry) {
                final block = entry.value;
                return _buildPositionedBlock(block, doc, docMgr);
              }),

              // Ink annotation layer
              Positioned.fill(
                child: IgnorePointer(
                  ignoring: ctrl.isSelectMode,
                  child: Listener(
                    behavior: HitTestBehavior.translucent,
                    onPointerDown: (e) {
                      if (_shouldDraw(e, ctrl)) {
                        final ts = audioCtrl.isRecording
                            ? audioCtrl.elapsedRecordingMs
                            : null;
                        ctrl.startStroke(e.localPosition,
                            relativeTimestamp: ts,
                            pressure: e.pressure);
                      }
                    },
                    onPointerMove: (e) {
                      if (_shouldDraw(e, ctrl) && ctrl.currentStroke != null) {
                        ctrl.addPoint(e.localPosition, pressure: e.pressure);
                      }
                    },
                    onPointerUp: (e) {
                      if (ctrl.currentStroke != null) {
                        ctrl.endStroke();
                        doc.strokes = List<Stroke>.from(ctrl.strokes);
                        docMgr.saveActiveDocument();
                      }
                    },
                    child: RepaintBoundary(
                      child: CustomPaint(
                        painter: InkPainter(
                          strokes: ctrl.visibleStrokes,
                          currentStroke: ctrl.currentStroke,
                        ),
                        size: Size.infinite,
                      ),
                    ),
                  ),
                ),
              ),

              // Floating toolbar
              Positioned(
                left: 16,
                top: 16,
                child: _buildToolbar(ctrl),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════
  // BLOCK PALETTE
  // ═══════════════════════════════════════════════════════

  Widget _buildBlockPalette(dynamic doc, DocumentManager docMgr) {
    return Container(
      width: 56,
      decoration: BoxDecoration(
        color: const Color(0xFF0D0D20),
        border: Border(
          right: BorderSide(color: Colors.white.withAlpha(10)),
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          _paletteLabel('BLOCKS'),
          const SizedBox(height: 8),
          _paletteItem(
            icon: Icons.text_fields_rounded,
            label: 'Text',
            color: const Color(0xFF00D2FF),
            onTap: () => _addBlock(doc, docMgr, ContentBlockType.text),
          ),
          _paletteItem(
            icon: Icons.code_rounded,
            label: 'Code',
            color: const Color(0xFF51CF66),
            onTap: () => _addBlock(doc, docMgr, ContentBlockType.code),
          ),
          _paletteItem(
            icon: Icons.functions_rounded,
            label: 'LaTeX',
            color: const Color(0xFF7C3AED),
            onTap: () => _addBlock(doc, docMgr, ContentBlockType.latex),
          ),
          _paletteItem(
            icon: Icons.science_rounded,
            label: 'Chemistry',
            color: const Color(0xFF38D9A9),
            onTap: () => _addBlock(doc, docMgr, ContentBlockType.chemistry, width: 680),
          ),
          _paletteItem(
            icon: Icons.calculate_rounded,
            label: 'Calculator',
            color: const Color(0xFFFFAA5C),
            onTap: () => _addBlock(doc, docMgr, ContentBlockType.calculator, width: 320),
          ),
          const Spacer(),
        ],
      ),
    );
  }

  Widget _paletteLabel(String text) {
    return Text(
      text,
      style: TextStyle(
        color: Colors.white.withAlpha(40),
        fontSize: 9,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.5,
      ),
    );
  }

  Widget _paletteItem({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: label,
      preferBelow: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withAlpha(15),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: color.withAlpha(30)),
            ),
            child: Icon(icon, size: 18, color: color.withAlpha(200)),
          ),
        ),
      ),
    );
  }

  void _addBlock(dynamic doc, DocumentManager docMgr, ContentBlockType type, {double? width}) {
    final count = doc.blocks.length as int;
    final defaultWidth = width ?? (type == ContentBlockType.code ? 500 : 360);
    final block = ContentBlock(
      id: _uuid.v4(),
      type: type,
      x: 80.0 + (count % 3) * 30.0,
      y: 80.0 + count * 60.0,
      blockWidth: defaultWidth,
    );
    doc.blocks.add(block);
    docMgr.saveActiveDocument();
    setState(() {});
  }

  // ═══════════════════════════════════════════════════════
  // POSITIONED BLOCKS
  // ═══════════════════════════════════════════════════════

  Widget _buildPositionedBlock(
      ContentBlock block, dynamic doc, DocumentManager docMgr) {
    final isDragging = _draggingBlockId == block.id;

    return Positioned(
      left: block.x,
      top: block.y,
      child: DraggableBlockShell(
        block: block,
        isDragging: isDragging,
        backgroundColor: const Color(0xFF141428).withAlpha(230),
        onDragStart: (_) => setState(() => _draggingBlockId = block.id),
        onDragUpdate: (details) {
          setState(() {
            block.x += details.delta.dx;
            block.y += details.delta.dy;
          });
        },
        onDragEnd: (_) {
          _draggingBlockId = null;
          docMgr.saveActiveDocument();
          setState(() {});
        },
        onDelete: () {
          _disposeTextEditingResources(block.id);
          doc.blocks.remove(block);
          docMgr.saveActiveDocument();
          setState(() {});
        },
        content: _buildBlockContent(block, doc, docMgr),
      ),
    );
  }

  Widget _buildBlockContent(ContentBlock block, dynamic doc, DocumentManager docMgr) {
    switch (block.type) {
      case ContentBlockType.text:
        return Padding(
          padding: const EdgeInsets.all(10),
          child: TextField(
            controller: _controllerForBlock(block),
            focusNode: _focusNodeForBlock(block.id, docMgr),
            onChanged: (val) {
              block.content = val;
              doc.touch();
              _scheduleTextBlockSave(block.id, docMgr);
            },
            maxLines: null,
            style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.6),
            decoration: InputDecoration(
              hintText: 'Start typing...',
              hintStyle: TextStyle(color: Colors.white.withAlpha(30)),
              border: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.zero,
            ),
          ),
        );
      case ContentBlockType.code:
        return CodeBlockWidget(block: block);
      case ContentBlockType.latex:
        return LatexBlockWidget(block: block);
      case ContentBlockType.chemistry:
        return ChemistryBlockWidget(
          block: block,
          onChanged: () {
            doc.touch();
            docMgr.saveActiveDocument();
          },
        );
      case ContentBlockType.calculator:
        return CalculatorBlockWidget(
          block: block,
          onChanged: () {
            doc.touch();
            docMgr.saveActiveDocument();
          },
        );
    }
  }

  TextEditingController _controllerForBlock(ContentBlock block) {
    final controller = _textControllers.putIfAbsent(
      block.id,
      () => TextEditingController(text: block.content),
    );
    final focusNode = _textFocusNodes[block.id];
    if (controller.text != block.content && (focusNode == null || !focusNode.hasFocus)) {
      controller.value = controller.value.copyWith(
        text: block.content,
        selection: TextSelection.collapsed(offset: block.content.length),
        composing: TextRange.empty,
      );
    }
    return controller;
  }

  FocusNode _focusNodeForBlock(String blockId, DocumentManager docMgr) {
    return _textFocusNodes.putIfAbsent(blockId, () {
      final focusNode = FocusNode();
      focusNode.addListener(() {
        if (!focusNode.hasFocus) {
          _flushTextBlockSave(blockId, docMgr);
        }
      });
      return focusNode;
    });
  }

  void _scheduleTextBlockSave(String blockId, DocumentManager docMgr) {
    _textSaveDebouncers[blockId]?.cancel();
    _textSaveDebouncers[blockId] = Timer(_textSaveDebounce, () {
      if (!mounted) {
        return;
      }
      docMgr.saveActiveDocument();
    });
  }

  void _flushTextBlockSave(String blockId, DocumentManager docMgr) {
    _textSaveDebouncers.remove(blockId)?.cancel();
    docMgr.saveActiveDocument();
  }

  void _disposeTextEditingResources(String blockId) {
    _textSaveDebouncers.remove(blockId)?.cancel();
    _textControllers.remove(blockId)?.dispose();
    _textFocusNodes.remove(blockId)?.dispose();
  }

  void _syncTextEditingResources(List<ContentBlock> blocks) {
    final textBlockIds = blocks
        .where((block) => block.type == ContentBlockType.text)
        .map((block) => block.id)
        .toSet();

    final staleIds = <String>{
      ..._textControllers.keys,
      ..._textFocusNodes.keys,
      ..._textSaveDebouncers.keys,
    }.difference(textBlockIds);

    for (final blockId in staleIds) {
      _disposeTextEditingResources(blockId);
    }
  }

  // ═══════════════════════════════════════════════════════
  // TOOLBAR — with color dots + color picker
  // ═══════════════════════════════════════════════════════

  Widget _buildToolbar(CanvasController ctrl) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF141428).withAlpha(240),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withAlpha(12)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(80),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _toolBtn(Icons.open_with_rounded, 'Select',
              ctrl.currentTool == DrawingTool.select,
              () => ctrl.setTool(DrawingTool.select),
              activeColor: const Color(0xFFFFD43B)),
          const SizedBox(width: 2),
          _divider(),
          _toolBtn(Icons.edit_rounded, 'Pen',
              ctrl.currentTool == DrawingTool.pen,
              () => ctrl.setTool(DrawingTool.pen)),
          const SizedBox(width: 2),
          _toolBtn(Icons.edit_outlined, 'Fine Pen',
              ctrl.currentTool == DrawingTool.finePen,
              () => ctrl.setTool(DrawingTool.finePen)),
          const SizedBox(width: 2),
          _toolBtn(Icons.gesture_rounded, 'Calligraphy',
              ctrl.currentTool == DrawingTool.calligraphy,
              () => ctrl.setTool(DrawingTool.calligraphy)),
          _divider(),
          _toolBtn(Icons.brush_rounded, 'Highlighter',
              ctrl.currentTool == DrawingTool.highlighter,
              () => ctrl.setTool(DrawingTool.highlighter)),
          const SizedBox(width: 2),
          _toolBtn(Icons.format_paint_rounded, 'Wide Highlight',
              ctrl.currentTool == DrawingTool.highlighterThick,
              () => ctrl.setTool(DrawingTool.highlighterThick)),
          _divider(),
          _toolBtn(Icons.auto_fix_high_rounded, 'Eraser',
              ctrl.currentTool == DrawingTool.eraser,
              () => ctrl.setTool(DrawingTool.eraser)),
          const SizedBox(width: 2),
          _toolBtn(Icons.auto_fix_off_rounded, 'Partial Eraser',
              ctrl.currentTool == DrawingTool.partialEraser,
              () => ctrl.setTool(DrawingTool.partialEraser)),
          _divider(),
          // Colors
          _colorDot(ctrl, Colors.white),
          _colorDot(ctrl, const Color(0xFF00D2FF)),
          _colorDot(ctrl, const Color(0xFFFF6B6B)),
          _colorDot(ctrl, const Color(0xFF51CF66)),
          _colorDot(ctrl, const Color(0xFFFFD43B)),
          _colorDot(ctrl, const Color(0xFF7C3AED)),
          const SizedBox(width: 2),
          _colorPickerButton(ctrl),
          _divider(),
          // Width slider
          SizedBox(
            width: 80,
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 2,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
                activeTrackColor: const Color(0xFF00D2FF),
                thumbColor: Colors.white,
                inactiveTrackColor: Colors.white12,
              ),
              child: Slider(
                value: ctrl.currentWidth,
                min: 1,
                max: 8,
                onChanged: (v) => ctrl.setWidth(v),
              ),
            ),
          ),
          _divider(),
          // Undo/Redo
          GestureDetector(
            onTap: ctrl.undo,
            child: Container(
              width: 30, height: 30, alignment: Alignment.center,
              child: Icon(Icons.undo_rounded, size: 16, color: Colors.white.withAlpha(120)),
            ),
          ),
          GestureDetector(
            onTap: ctrl.redo,
            child: Container(
              width: 30, height: 30, alignment: Alignment.center,
              child: Icon(Icons.redo_rounded, size: 16, color: Colors.white.withAlpha(120)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider() => Container(
        width: 1, height: 20,
        margin: const EdgeInsets.symmetric(horizontal: 6),
        color: Colors.white.withAlpha(15),
      );

  Widget _toolBtn(IconData icon, String label, bool active, VoidCallback onTap,
      {Color? activeColor}) {
    final color = activeColor ?? const Color(0xFF00D2FF);
    return Tooltip(
      message: label,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: active ? color.withAlpha(25) : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: active ? color.withAlpha(80) : Colors.transparent,
            ),
          ),
          child: Icon(icon,
              size: 15,
              color: active ? color : Colors.white.withAlpha(100)),
        ),
      ),
    );
  }

  Widget _colorDot(CanvasController ctrl, Color color) {
    final isSelected =
        ctrl.currentColor == color && ctrl.currentTool != DrawingTool.eraser;
    return GestureDetector(
      onTap: () => ctrl.setColor(color),
      child: Container(
        width: 16,
        height: 16,
        margin: const EdgeInsets.symmetric(horizontal: 2),
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected ? Colors.white : Colors.transparent,
            width: 2,
          ),
          boxShadow: isSelected
              ? [BoxShadow(color: color.withAlpha(80), blurRadius: 6)]
              : null,
        ),
      ),
    );
  }

  Widget _colorPickerButton(CanvasController ctrl) {
    return GestureDetector(
      onTap: () => _showColorPickerDialog(ctrl),
      child: Container(
        width: 16,
        height: 16,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const SweepGradient(
            colors: [Colors.red, Colors.yellow, Colors.green, Colors.cyan, Colors.blue, Colors.purple, Colors.red],
          ),
          border: Border.all(color: Colors.white.withAlpha(40), width: 1.5),
        ),
        child: Icon(Icons.add, size: 8, color: Colors.white.withAlpha(200)),
      ),
    );
  }

  void _showColorPickerDialog(CanvasController ctrl) {
    HSVColor hsv = HSVColor.fromColor(ctrl.currentColor);
    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (_, setD) {
            return AlertDialog(
              backgroundColor: const Color(0xFF141428),
              title: const Text('Pick a color', style: TextStyle(color: Colors.white, fontSize: 14)),
              content: SizedBox(
                width: 260,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Hue bar
                    SizedBox(
                      height: 20,
                      child: GestureDetector(
                        onPanDown: (d) {
                          final h = (d.localPosition.dx / 260 * 360).clamp(0, 359).toDouble();
                          setD(() => hsv = hsv.withHue(h));
                        },
                        onPanUpdate: (d) {
                          final h = (d.localPosition.dx / 260 * 360).clamp(0, 359).toDouble();
                          setD(() => hsv = hsv.withHue(h));
                        },
                        child: CustomPaint(
                          painter: _HueBarPainter(selectedHue: hsv.hue),
                          size: const Size(260, 20),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // SV picker
                    SizedBox(
                      width: 260,
                      height: 150,
                      child: GestureDetector(
                        onPanDown: (d) => setD(() => hsv = hsv
                            .withSaturation((d.localPosition.dx / 260).clamp(0, 1).toDouble())
                            .withValue((1 - d.localPosition.dy / 150).clamp(0, 1).toDouble())),
                        onPanUpdate: (d) => setD(() => hsv = hsv
                            .withSaturation((d.localPosition.dx / 260).clamp(0, 1).toDouble())
                            .withValue((1 - d.localPosition.dy / 150).clamp(0, 1).toDouble())),
                        child: CustomPaint(
                          painter: _SVPickerPainter(hue: hsv.hue, sat: hsv.saturation, val: hsv.value),
                          size: const Size(260, 150),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Preview
                    Row(
                      children: [
                        Container(
                          width: 36, height: 36,
                          decoration: BoxDecoration(
                            color: hsv.toColor(),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.white24),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            '#${hsv.toColor().value.toRadixString(16).substring(2).toUpperCase()}',
                            style: TextStyle(color: Colors.white.withAlpha(120), fontFamily: 'Courier New', fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel', style: TextStyle(color: Colors.white38)),
                ),
                TextButton(
                  onPressed: () {
                    ctrl.setColor(hsv.toColor());
                    Navigator.pop(ctx);
                  },
                  child: const Text('Apply', style: TextStyle(color: Color(0xFF00D2FF))),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════
// Color picker painters
// ═══════════════════════════════════════════════════════

class _HueBarPainter extends CustomPainter {
  final double selectedHue;
  _HueBarPainter({required this.selectedHue});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final List<Color> colors = [];
    for (int i = 0; i <= 360; i += 10) {
      colors.add(HSVColor.fromAHSV(1, i.toDouble(), 1, 1).toColor());
    }
    final gradient = LinearGradient(colors: colors);
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(10)),
      Paint()..shader = gradient.createShader(rect),
    );
    final x = selectedHue / 360 * size.width;
    canvas.drawCircle(
      Offset(x.clamp(6, size.width - 6), size.height / 2),
      7,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(covariant _HueBarPainter old) => old.selectedHue != selectedHue;
}

class _SVPickerPainter extends CustomPainter {
  final double hue;
  final double sat;
  final double val;
  _SVPickerPainter({required this.hue, required this.sat, required this.val});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rr = RRect.fromRectAndRadius(rect, const Radius.circular(8));
    canvas.drawRRect(rr, Paint()..color = HSVColor.fromAHSV(1, hue, 1, 1).toColor());
    canvas.drawRRect(
      rr,
      Paint()
        ..shader = const LinearGradient(
          colors: [Colors.white, Colors.transparent],
        ).createShader(rect),
    );
    canvas.drawRRect(
      rr,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.transparent, Colors.black],
        ).createShader(rect),
    );
    final x = sat * size.width;
    final y = (1 - val) * size.height;
    canvas.drawCircle(
      Offset(x.clamp(6, size.width - 6), y.clamp(6, size.height - 6)),
      8,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(covariant _SVPickerPainter old) =>
      old.hue != hue || old.sat != sat || old.val != val;
}
