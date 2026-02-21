import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:provider/provider.dart';
import 'package:notes_app/controllers/canvas_controller.dart';
import 'package:notes_app/controllers/audio_controller.dart';
import 'package:notes_app/controllers/document_manager.dart';
import 'package:notes_app/painters/ink_painter.dart';
import 'package:notes_app/models/content_block.dart';
import 'package:notes_app/models/stroke.dart';
import 'package:notes_app/widgets/code_block.dart';
import 'package:notes_app/widgets/latex_block.dart';
import 'package:uuid/uuid.dart';

/// The main canvas — free-form drawing + draggable content blocks.
/// Left sidebar palette lets you drag Text/Code/LaTeX blocks onto the canvas.
/// Mouse draws ink when a drawing tool is active; use Select mode to drag blocks.
class CanvasPage extends StatefulWidget {
  const CanvasPage({super.key});

  @override
  State<CanvasPage> createState() => _CanvasPageState();
}

class _CanvasPageState extends State<CanvasPage> {
  final _uuid = const Uuid();
  String? _draggingBlockId;

  // Mouse draws when a drawing tool (pen/highlighter/eraser) is active
  bool _shouldDraw(PointerEvent event, CanvasController ctrl) {
    // Stylus always draws
    if (event.kind == PointerDeviceKind.stylus ||
        event.kind == PointerDeviceKind.invertedStylus) {
      return true;
    }
    // Touch draws
    if (event.kind == PointerDeviceKind.touch) {
      return ctrl.isDrawingToolActive;
    }
    // Mouse draws when a drawing tool is active (not select mode)
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

    if (doc == null) {
      return const Center(
        child: Text('No document open',
            style: TextStyle(color: Colors.white38)),
      );
    }

    return Row(
      children: [
        // ─── Left Sidebar — Block Palette ─────────────────
        _buildBlockPalette(doc, docMgr),
        // ─── Canvas Area ──────────────────────────────────
        Expanded(
          child: Stack(
            children: [
              // Canvas with ink + blocks
              Positioned.fill(
                child: _buildCanvas(ctrl, docMgr, audioCtrl, doc),
              ),
              // ─── Top Toolbar ─────────────────────────────
              Positioned(
                left: 16,
                top: 16,
                child: _buildFloatingToolbar(ctrl),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════
  // LEFT SIDEBAR — Block Palette
  // ═══════════════════════════════════════════════════════════

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
            onTap: () => _addBlockAtCenter(doc, docMgr, ContentBlockType.text),
          ),
          _paletteItem(
            icon: Icons.code_rounded,
            label: 'Code',
            color: const Color(0xFF51CF66),
            onTap: () => _addBlockAtCenter(doc, docMgr, ContentBlockType.code),
          ),
          _paletteItem(
            icon: Icons.functions_rounded,
            label: 'LaTeX',
            color: const Color(0xFF7C3AED),
            onTap: () => _addBlockAtCenter(doc, docMgr, ContentBlockType.latex),
          ),
          const Spacer(),
        ],
      ),
    );
  }

  Widget _paletteLabel(String text) {
    return RotatedBox(
      quarterTurns: 0,
      child: Text(
        text,
        style: TextStyle(
          color: Colors.white.withAlpha(40),
          fontSize: 9,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.5,
        ),
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

  void _addBlockAtCenter(dynamic doc, DocumentManager docMgr, ContentBlockType type) {
    // Stack blocks vertically, offset from each other
    final existingCount = doc.blocks.length as int;
    final block = ContentBlock(
      id: _uuid.v4(),
      type: type,
      x: 80.0 + (existingCount % 3) * 30.0,
      y: 80.0 + existingCount * 60.0,
      blockWidth: type == ContentBlockType.code ? 500 : 360,
    );
    doc.blocks.add(block);
    docMgr.saveActiveDocument();
    setState(() {});
  }

  // ═══════════════════════════════════════════════════════════
  // CANVAS — Ink + Positioned Blocks
  // ═══════════════════════════════════════════════════════════

  Widget _buildCanvas(CanvasController ctrl, DocumentManager docMgr,
      AudioController audioCtrl, dynamic doc) {
    return InteractiveViewer(
      minScale: 0.5,
      maxScale: 3.0,
      constrained: false,
      child: SizedBox(
        width: MediaQuery.of(context).size.width,
        height: 3000,
        child: Stack(
          children: [
            // Grid background
            Positioned.fill(child: _buildGrid()),

            // Positioned content blocks
            ...doc.blocks.asMap().entries.map<Widget>((entry) {
              final block = entry.value as ContentBlock;
              return _buildPositionedBlock(block, doc, docMgr, ctrl);
            }),

            // Ink layer — draws on top, but translucent to allow block interaction
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
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // POSITIONED BLOCK — draggable container with header
  // ═══════════════════════════════════════════════════════════

  Widget _buildPositionedBlock(
      ContentBlock block, dynamic doc, DocumentManager docMgr, CanvasController ctrl) {
    final isDragging = _draggingBlockId == block.id;

    return Positioned(
      left: block.x,
      top: block.y,
      child: GestureDetector(
        // Only allow drag when in select mode or when using the drag header
        onPanStart: (_) => setState(() => _draggingBlockId = block.id),
        onPanUpdate: (details) {
          setState(() {
            block.x += details.delta.dx;
            block.y += details.delta.dy;
          });
        },
        onPanEnd: (_) {
          _draggingBlockId = null;
          docMgr.saveActiveDocument();
          setState(() {});
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          width: block.blockWidth,
          decoration: BoxDecoration(
            color: const Color(0xFF141428),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDragging
                  ? const Color(0xFF00D2FF).withAlpha(120)
                  : Colors.white.withAlpha(12),
              width: isDragging ? 1.5 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: isDragging
                    ? const Color(0xFF00D2FF).withAlpha(15)
                    : Colors.black.withAlpha(40),
                blurRadius: isDragging ? 16 : 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag handle header
              _buildBlockHeader(block, doc, docMgr),
              // Block content
              _buildBlockContent(block, doc, docMgr),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBlockHeader(ContentBlock block, dynamic doc, DocumentManager docMgr) {
    Color typeColor;
    IconData typeIcon;
    String typeLabel;

    switch (block.type) {
      case ContentBlockType.text:
        typeColor = const Color(0xFF00D2FF);
        typeIcon = Icons.text_fields_rounded;
        typeLabel = 'Text';
      case ContentBlockType.code:
        typeColor = const Color(0xFF51CF66);
        typeIcon = Icons.code_rounded;
        typeLabel = 'Code';
      case ContentBlockType.latex:
        typeColor = const Color(0xFF7C3AED);
        typeIcon = Icons.functions_rounded;
        typeLabel = 'LaTeX';
    }

    return Container(
      height: 28,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: typeColor.withAlpha(10),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
        border: Border(
          bottom: BorderSide(color: Colors.white.withAlpha(6)),
        ),
      ),
      child: Row(
        children: [
          // Drag grip icon
          Icon(Icons.drag_indicator_rounded,
              size: 14, color: Colors.white.withAlpha(40)),
          const SizedBox(width: 4),
          // Type indicator
          Icon(typeIcon, size: 12, color: typeColor.withAlpha(150)),
          const SizedBox(width: 4),
          Text(typeLabel,
              style: TextStyle(
                  color: typeColor.withAlpha(150),
                  fontSize: 10,
                  fontWeight: FontWeight.w600)),
          const Spacer(),
          // Delete
          GestureDetector(
            onTap: () {
              doc.blocks.remove(block);
              docMgr.saveActiveDocument();
              setState(() {});
            },
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: Icon(Icons.close_rounded,
                  size: 13, color: Colors.white.withAlpha(50)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBlockContent(ContentBlock block, dynamic doc, DocumentManager docMgr) {
    switch (block.type) {
      case ContentBlockType.text:
        return Padding(
          padding: const EdgeInsets.all(10),
          child: TextField(
            controller: TextEditingController(text: block.content)
              ..selection = TextSelection.collapsed(
                  offset: block.content.length),
            onChanged: (val) {
              block.content = val;
              doc.touch();
            },
            maxLines: null,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              height: 1.6,
            ),
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
        return CodeBlockWidget(
          block: block,
          onChanged: (val) {
            block.content = val;
            doc.touch();
          },
          onDelete: () {
            doc.blocks.remove(block);
            docMgr.saveActiveDocument();
            setState(() {});
          },
        );
      case ContentBlockType.latex:
        return LatexBlockWidget(block: block);
    }
  }

  // ═══════════════════════════════════════════════════════════
  // FLOATING TOOLBAR
  // ═══════════════════════════════════════════════════════════

  Widget _buildFloatingToolbar(CanvasController ctrl) {
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
          // Select (move blocks)
          _toolButton(
            icon: Icons.open_with_rounded,
            label: 'Select / Move',
            isActive: ctrl.currentTool == DrawingTool.select,
            onTap: () => ctrl.setTool(DrawingTool.select),
            activeColor: const Color(0xFFFFD43B),
          ),
          _separator(),
          // Pens
          _toolButton(
            icon: Icons.edit_rounded,
            label: 'Pen',
            isActive: ctrl.currentTool == DrawingTool.pen,
            onTap: () => ctrl.setTool(DrawingTool.pen),
          ),
          const SizedBox(width: 2),
          _toolButton(
            icon: Icons.edit_outlined,
            label: 'Fine Pen',
            isActive: ctrl.currentTool == DrawingTool.finePen,
            onTap: () => ctrl.setTool(DrawingTool.finePen),
          ),
          const SizedBox(width: 2),
          _toolButton(
            icon: Icons.gesture_rounded,
            label: 'Calligraphy',
            isActive: ctrl.currentTool == DrawingTool.calligraphy,
            onTap: () => ctrl.setTool(DrawingTool.calligraphy),
          ),
          _separator(),
          // Highlighters
          _toolButton(
            icon: Icons.brush_rounded,
            label: 'Highlighter',
            isActive: ctrl.currentTool == DrawingTool.highlighter,
            onTap: () => ctrl.setTool(DrawingTool.highlighter),
          ),
          const SizedBox(width: 2),
          _toolButton(
            icon: Icons.format_paint_rounded,
            label: 'Wide Highlight',
            isActive: ctrl.currentTool == DrawingTool.highlighterThick,
            onTap: () => ctrl.setTool(DrawingTool.highlighterThick),
          ),
          _separator(),
          // Erasers
          _toolButton(
            icon: Icons.auto_fix_high_rounded,
            label: 'Eraser',
            isActive: ctrl.currentTool == DrawingTool.eraser,
            onTap: () => ctrl.setTool(DrawingTool.eraser),
          ),
          const SizedBox(width: 2),
          _toolButton(
            icon: Icons.auto_fix_off_rounded,
            label: 'Partial Eraser',
            isActive: ctrl.currentTool == DrawingTool.partialEraser,
            onTap: () => ctrl.setTool(DrawingTool.partialEraser),
          ),
          _separator(),
          // Colors
          _colorDot(ctrl, Colors.white),
          _colorDot(ctrl, const Color(0xFF00D2FF)),
          _colorDot(ctrl, const Color(0xFFFF6B6B)),
          _colorDot(ctrl, const Color(0xFF51CF66)),
          _colorDot(ctrl, const Color(0xFFFFD43B)),
          _colorDot(ctrl, const Color(0xFF7C3AED)),
          _separator(),
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
          _separator(),
          // Undo / Redo
          _iconBtn(Icons.undo_rounded, () => ctrl.undo()),
          _iconBtn(Icons.redo_rounded, () => ctrl.redo()),
        ],
      ),
    );
  }

  Widget _separator() => Container(
        width: 1,
        height: 20,
        margin: const EdgeInsets.symmetric(horizontal: 6),
        color: Colors.white.withAlpha(15),
      );

  Widget _toolButton({
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
    Color? activeColor,
  }) {
    final color = activeColor ?? const Color(0xFF00D2FF);
    return Tooltip(
      message: label,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: isActive
                ? color.withAlpha(25)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isActive
                  ? color.withAlpha(80)
                  : Colors.transparent,
            ),
          ),
          child: Icon(icon,
              size: 16,
              color: isActive
                  ? color
                  : Colors.white.withAlpha(120)),
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
        width: 18,
        height: 18,
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

  Widget _iconBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 30,
        height: 30,
        alignment: Alignment.center,
        child: Icon(icon, size: 16, color: Colors.white.withAlpha(120)),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // GRID BACKGROUND
  // ═══════════════════════════════════════════════════════════

  Widget _buildGrid() {
    return CustomPaint(
      painter: _GridPainter(),
      size: Size.infinite,
    );
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withAlpha(6)
      ..strokeWidth = 0.5;

    const spacing = 30.0;
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
