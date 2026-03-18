import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:provider/provider.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:notes_app/models/anchor_type.dart';
import 'package:notes_app/controllers/canvas_controller.dart';
import 'package:notes_app/controllers/audio_controller.dart';
import 'package:notes_app/controllers/document_manager.dart';
import 'package:notes_app/models/document.dart';
import 'package:notes_app/painters/ink_painter.dart';
import 'package:notes_app/models/content_block.dart';
import 'package:notes_app/models/stroke.dart';
import 'package:notes_app/widgets/code_block.dart';
import 'package:notes_app/widgets/latex_block.dart';
import 'package:notes_app/widgets/chemistry_block.dart';
import 'package:notes_app/widgets/calculator_block.dart';
import 'package:notes_app/widgets/draggable_block_shell.dart';
import 'package:notes_app/widgets/markdown_block.dart';
import 'package:notes_app/widgets/image_block.dart';
import 'package:notes_app/widgets/feynman_block.dart';
import 'package:notes_app/services/image_service.dart';
import 'package:notes_app/services/pdf_writeback_service.dart';
import 'package:notes_app/widgets/flashcard_block.dart';
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
  static const double _worldWidth = 5200;
  static const double _worldHeight = 5200;
  static const Duration _pdfWritebackDebounce = Duration(milliseconds: 600);

  final _uuid = const Uuid();
  late final PdfViewerController _pdfController;
  final _pdfWritebackService = PdfWritebackService();
  String? _draggingBlockId;
  final Map<String, TextEditingController> _textControllers = {};
  final Map<String, FocusNode> _textFocusNodes = {};
  final Map<String, Timer> _textSaveDebouncers = {};
  Timer? _pdfWritebackTimer;
  bool _isWritingBackPdf = false;
  String? _writebackMessage;

  int? _activePdfStrokePageIndex;
  Size? _activePdfStrokePageSize;
  final List<Offset> _activePdfStrokePoints = [];

  static const _textSaveDebounce = Duration(milliseconds: 700);

  @override
  void initState() {
    super.initState();
    _pdfController = PdfViewerController();
  }

  @override
  void dispose() {
    _pdfWritebackTimer?.cancel();
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
    // ignore: unnecessary_non_null_assertion
    if (event.kind == PointerDeviceKind.mouse) {
      return ctrl.isDrawingToolActive;
    }
    return false;
  }

  Rect _pdfPanelRect() {
    const width = 980.0;
    const height = 4300.0;
    return Rect.fromCenter(
      center: const Offset(_worldWidth / 2, _worldHeight / 2),
      width: width,
      height: height,
    );
  }

  PdfPageHitTestResult? _pdfHitTest(NoteDocument doc, Offset worldPosition) {
    if (!doc.hasPdf || !_pdfController.isReady) return null;
    final panel = _pdfPanelRect();
    if (!panel.contains(worldPosition)) return null;
    final local = worldPosition - panel.topLeft;
    return _pdfController.getPdfPageHitTestResult(
      local,
      useDocumentLayoutCoordinates: false,
    );
  }

  Future<void> _queuePdfWriteback(DocumentManager docMgr,
      {bool immediate = false}) async {
    final doc = docMgr.activeDocument;
    if (doc == null || !doc.hasPdf || !doc.pdfWritebackEnabled) return;

    _pdfWritebackTimer?.cancel();
    void run() async {
      if (!mounted) return;
      setState(() {
        _isWritingBackPdf = true;
        _writebackMessage = 'Writing to PDF...';
      });
      final result = await _pdfWritebackService.writeback(doc);
      doc.lastPdfExportAt = result.writtenAt;
      doc.lastPdfExportStatus = result.success ? 'success' : 'failed';
      doc.lastPdfExportMessage = result.message;
      await docMgr.saveActiveDocument();
      if (!mounted) return;
      setState(() {
        _isWritingBackPdf = false;
        _writebackMessage = result.message;
      });
    }

    if (immediate) {
      run();
    } else {
      _pdfWritebackTimer = Timer(_pdfWritebackDebounce, run);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<CanvasController>();
    final docMgr = context.watch<DocumentManager>();
    final audioCtrl = context.read<AudioController>();
    final doc = docMgr.activeDocument;

    if (doc == null) {
      return const Center(
        child: Text(
          'No document open',
          style: TextStyle(color: Colors.white38),
        ),
      );
    }

    _syncTextEditingResources(doc.blocks.cast<ContentBlock>());

    // Disable viewport panning if drawing or dragging a block
    final panEnabled = !ctrl.isDrawingToolActive && _draggingBlockId == null;

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
                child: InteractiveViewer(
                  minScale: 0.5,
                  maxScale: 3.0,
                  constrained: false,
                  panEnabled: panEnabled,
                  child: SizedBox(
                    width: _worldWidth,
                    height: _worldHeight,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        // Grid background
                        Positioned.fill(child: _buildGrid()),
                        if (doc.activePdfPath != null &&
                            File(doc.activePdfPath!).existsSync())
                          Positioned(
                            left: _pdfPanelRect().left,
                            top: _pdfPanelRect().top,
                            width: _pdfPanelRect().width,
                            height: _pdfPanelRect().height,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0B0B1A),
                                  border: Border.all(
                                      color: Colors.white.withAlpha(18)),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: PdfViewer.file(
                                  doc.activePdfPath!,
                                  controller: _pdfController,
                                  params: PdfViewerParams(
                                    backgroundColor: const Color(0xFF0A0A1A),
                                    enableTextSelection:
                                        !ctrl.isDrawingToolActive,
                                    pagePaintCallbacks: [
                                      (canvas, pageRect, page) {
                                        final pageStrokes = doc.strokes.where(
                                          (s) =>
                                              s.anchorType ==
                                                  AnchorType.pdfPage &&
                                              s.pageIndex ==
                                                  page.pageNumber - 1 &&
                                              s.normalizedPoints != null &&
                                              s.normalizedPoints!.length >= 2,
                                        );
                                        for (final stroke in pageStrokes) {
                                          final paint = Paint()
                                            ..color = stroke.color
                                            ..strokeWidth = stroke.width
                                            ..style = PaintingStyle.stroke
                                            ..strokeCap = StrokeCap.round
                                            ..strokeJoin = StrokeJoin.round;
                                          final path = Path();
                                          final pts = stroke.normalizedPoints!
                                              .map(
                                                (p) => Offset(
                                                  pageRect.left +
                                                      p.dx * pageRect.width,
                                                  pageRect.top +
                                                      p.dy * pageRect.height,
                                                ),
                                              )
                                              .toList();
                                          path.moveTo(
                                              pts.first.dx, pts.first.dy);
                                          for (var i = 1; i < pts.length; i++) {
                                            path.lineTo(pts[i].dx, pts[i].dy);
                                          }
                                          canvas.drawPath(path, paint);
                                        }
                                      },
                                    ],
                                    pageOverlaysBuilder:
                                        (context, pageRect, page) {
                                      return _buildPdfPageOverlayBlocks(
                                        pageRect: pageRect,
                                        page: page,
                                        doc: doc,
                                        docMgr: docMgr,
                                        panelRect: _pdfPanelRect(),
                                      );
                                    },
                                  ),
                                ),
                              ),
                            ),
                          ),

                        // Positioned content blocks
                        ...doc.blocks
                            .where((b) =>
                                !doc.hasPdf ||
                                b.anchorType == AnchorType.canvas)
                            .toList()
                            .asMap()
                            .entries
                            .map<Widget>((entry) {
                          final block = entry.value;
                          return _buildPositionedBlock(block, doc, docMgr);
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
                                  // ignore: unnecessary_non_null_assertion
                                  final hit = _pdfHitTest(doc, e.localPosition);
                                  if (hit != null) {
                                    _activePdfStrokePageIndex =
                                        hit.page.pageNumber - 1;
                                    _activePdfStrokePageSize =
                                        Size(hit.page.width, hit.page.height);
                                    _activePdfStrokePoints
                                      ..clear()
                                      ..add(
                                        Offset(hit.offset.x,
                                            hit.page.height - hit.offset.y),
                                      );
                                  } else {
                                    _activePdfStrokePageIndex = null;
                                    _activePdfStrokePageSize = null;
                                    _activePdfStrokePoints.clear();
                                  }
                                  ctrl.startStroke(
                                    e.localPosition,
                                    relativeTimestamp: ts,
                                    pressure: e.pressure,
                                  );
                                }
                              },
                              onPointerMove: (e) {
                                if (_shouldDraw(e, ctrl) &&
                                    ctrl.currentStroke != null) {
                                  ctrl.addPoint(e.localPosition,
                                      pressure: e.pressure);
                                  if (_activePdfStrokePageIndex != null) {
                                    // ignore: unnecessary_non_null_assertion
                                    final hit =
                                        _pdfHitTest(doc, e.localPosition);
                                    if (hit != null &&
                                        hit.page.pageNumber - 1 ==
                                            _activePdfStrokePageIndex) {
                                      _activePdfStrokePoints.add(
                                        Offset(hit.offset.x,
                                            hit.page.height - hit.offset.y),
                                      );
                                    }
                                  }
                                }
                              },
                              onPointerUp: (e) {
                                if (ctrl.currentStroke != null) {
                                  ctrl.endStroke();
                                  final strokes =
                                      List<Stroke>.from(ctrl.strokes);
                                  final idx = strokes.length - 1;
                                  if (idx >= 0) {
                                    final pageSize = _activePdfStrokePageSize;
                                    if (_activePdfStrokePageIndex != null &&
                                        pageSize != null &&
                                        _activePdfStrokePoints.length >= 2) {
                                      final size = pageSize;
                                      final normalized = _activePdfStrokePoints
                                          .map(
                                            (p) => Offset(
                                              (p.dx / size.width)
                                                  .clamp(0.0, 1.0),
                                              (p.dy / size.height)
                                                  .clamp(0.0, 1.0),
                                            ),
                                          )
                                          .toList();
                                      strokes[idx] = strokes[idx].copyWith(
                                        anchorType: AnchorType.pdfPage,
                                        pageIndex: _activePdfStrokePageIndex,
                                        normalizedPoints: normalized,
                                      );
                                      _queuePdfWriteback(docMgr,
                                          immediate: true);
                                    } else {
                                      strokes[idx] = strokes[idx].copyWith(
                                        anchorType: AnchorType.canvas,
                                        clearNormalizedPoints: true,
                                        pageIndex: 0,
                                      );
                                    }
                                  }
                                  ctrl.loadStrokes(strokes);
                                  doc.strokes = strokes;
                                  docMgr.saveActiveDocument();
                                  _activePdfStrokePageIndex = null;
                                  _activePdfStrokePageSize = null;
                                  _activePdfStrokePoints.clear();
                                }
                              },
                              child: RepaintBoundary(
                                child: CustomPaint(
                                  painter: InkPainter(
                                    strokes: ctrl.visibleStrokes
                                        .where((s) =>
                                            s.anchorType == AnchorType.canvas)
                                        .toList(),
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
                ),
              ),
              // ─── Top Toolbar ─────────────────────────────
              Positioned(
                left: 16,
                top: 16,
                child: _buildFloatingToolbar(ctrl, docMgr, doc),
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

  Widget _buildBlockPalette(NoteDocument doc, DocumentManager docMgr) {
    return Container(
      width: 56,
      decoration: BoxDecoration(
        color: const Color(0xFF0D0D20),
        border: Border(right: BorderSide(color: Colors.white.withAlpha(10))),
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
          _paletteItem(
            icon: Icons.article_rounded,
            label: 'Markdown',
            color: const Color(0xFFFF6B6B),
            onTap: () => _addBlockAtCenter(
              doc,
              docMgr,
              ContentBlockType.markdown,
              width: 460,
            ),
          ),
          _paletteItem(
            icon: Icons.science_rounded,
            label: 'Chemistry',
            color: const Color(0xFF38D9A9),
            onTap: () => _addBlockAtCenter(
              doc,
              docMgr,
              ContentBlockType.chemistry,
              width: 680,
            ),
          ),
          _paletteItem(
            icon: Icons.lightbulb_outline_rounded,
            label: 'Feynman',
            color: const Color(0xFFFFAA5C), // Orange-ish
            onTap: () => _addBlockAtCenter(
              doc,
              docMgr,
              ContentBlockType.feynman,
              width: 500,
            ),
          ),
          _paletteItem(
            icon: Icons.calculate_rounded,
            label: 'Calculator',
            color: const Color(0xFFFFAA5C),
            onTap: () => _addBlockAtCenter(
              doc,
              docMgr,
              ContentBlockType.calculator,
              width: 320,
            ),
          ),
          _paletteItem(
            icon: Icons.image_rounded,
            label: 'Image',
            color: const Color(0xFF4DABF7),
            onTap: () => _addImageBlock(doc, docMgr),
          ),
          _paletteItem(
            icon: Icons.style_rounded,
            label: 'Flashcard',
            color: const Color(0xFFFF6B9A),
            onTap: () => _addBlockAtCenter(
              doc,
              docMgr,
              ContentBlockType.flashcard,
              width: 460,
            ),
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

  void _addBlockAtCenter(
    NoteDocument doc,
    DocumentManager docMgr,
    ContentBlockType type, {
    double? width,
  }) {
    // Stack blocks vertically, offset from each other
    final existingCount = doc.blocks.length;
    final defaultWidth = width ??
        (type == ContentBlockType.code
            ? 500
            : type == ContentBlockType.markdown ||
                    type == ContentBlockType.image
                ? 460
                : 360);
    final block = ContentBlock(
      id: _uuid.v4(),
      type: type,
      x: (_worldWidth / 2) - 360 + (existingCount % 3) * 30.0,
      y: 220.0 + existingCount * 60.0,
      blockWidth: defaultWidth,
    );
    if (doc.hasPdf) {
      // ignore: unnecessary_non_null_assertion
      final maybeHit = _pdfHitTest(doc, Offset(block.x, block.y));
      if (maybeHit != null) {
        final page = maybeHit.page;
        final localTopY = page.height - maybeHit.offset.y;
        block.anchorType = AnchorType.pdfPage;
        block.pageIndex = page.pageNumber - 1;
        block.normalizedX = (maybeHit.offset.x / page.width).clamp(0.0, 1.0);
        block.normalizedY = (localTopY / page.height).clamp(0.0, 1.0);
      }
    }
    doc.blocks.add(block);
    docMgr.saveActiveDocument();
    _queuePdfWriteback(docMgr);
    setState(() {});
  }

  Future<void> _addImageBlock(NoteDocument doc, DocumentManager docMgr) async {
    final imagePath = await ImageService.importImage();
    if (imagePath == null) return;

    final existingCount = doc.blocks.length;
    final block = ContentBlock(
      id: _uuid.v4(),
      type: ContentBlockType.image,
      content: '',
      x: (_worldWidth / 2) - 360 + (existingCount % 3) * 30.0,
      y: 220.0 + existingCount * 60.0,
      blockWidth: 420,
      metadata: {'imagePath': imagePath, 'imageHeight': 240.0},
    );

    doc.blocks.add(block);
    doc.touch();
    docMgr.saveActiveDocument();
    _queuePdfWriteback(docMgr);
    setState(() {});
  }

  // ═══════════════════════════════════════════════════════════
  // POSITIONED BLOCK — draggable container with header
  // ═══════════════════════════════════════════════════════════

  List<Widget> _buildPdfPageOverlayBlocks({
    required Rect pageRect,
    required PdfPage page,
    required NoteDocument doc,
    required DocumentManager docMgr,
    required Rect panelRect,
  }) {
    final pageIndex = page.pageNumber - 1;
    final blocks = doc.blocks.where(
      (b) => b.anchorType == AnchorType.pdfPage && b.pageIndex == pageIndex,
    );

    return blocks.map((block) {
      final left = (block.normalizedX ?? 0) * pageRect.width;
      final top = (block.normalizedY ?? 0) * pageRect.height;
      final isDragging = _draggingBlockId == block.id;

      // Wrap in positioned, but use helper for content
      return Positioned(
        left: left,
        top: top,
        child: _buildBlockWidget(
          block,
          isDragging,
          // onDragStart
          (_) => setState(() => _draggingBlockId = block.id),
          // onDragUpdate
          (details) {
            // details.delta is relative to the screen. To scale to the PDF page size we must
            // divide by the current zoom level of the interactive viewer, if applicable,
            // or just the pageRect dimensions if it represents the rendered size.
            // pdfrx pageOverlaysBuilder guarantees `pageRect` is the rendered physical size.
            final rawX =
                (block.normalizedX ?? 0) + (details.delta.dx / pageRect.width);
            final rawY =
                (block.normalizedY ?? 0) + (details.delta.dy / pageRect.height);
            setState(() {
              if (rawX < -0.12 || rawX > 1.12 || rawY < -0.12 || rawY > 1.12) {
                final worldX =
                    panelRect.left + pageRect.left + rawX * pageRect.width;
                final worldY =
                    panelRect.top + pageRect.top + rawY * pageRect.height;
                block.updateCanvasAnchor(worldX: worldX, worldY: worldY);
              } else {
                block.anchorType = AnchorType.pdfPage;
                block.normalizedX = rawX.clamp(0.0, 1.0);
                block.normalizedY = rawY.clamp(0.0, 1.0);
                block.pageIndex = pageIndex;
              }
            });
          },
          // onDragEnd
          (_) {
            _draggingBlockId = null;
            doc.touch();
            docMgr.saveActiveDocument();
            _queuePdfWriteback(docMgr);
            setState(() {});
          },
          doc,
          docMgr,
        ),
      );
    }).toList();
  }

  Widget _buildPositionedBlock(
    ContentBlock block,
    NoteDocument doc,
    DocumentManager docMgr,
  ) {
    final isDragging = _draggingBlockId == block.id;

    return Positioned(
      left: block.x,
      top: block.y,
      child: _buildBlockWidget(
        block,
        isDragging,
        // onDragStart
        (_) => setState(() => _draggingBlockId = block.id),
        // onDragUpdate
        (details) {
          setState(() {
            block.x += details.delta.dx;
            block.y += details.delta.dy;
          });
        },
        // onDragEnd
        (_) {
          if (doc.hasPdf) {
            // ignore: unnecessary_non_null_assertion
            final hit = _pdfHitTest(
              doc,
              Offset(block.x + block.blockWidth / 2, block.y + 28),
            );
            if (hit != null) {
              final topY = hit.page.height - hit.offset.y;
              block.anchorType = AnchorType.pdfPage;
              block.pageIndex = hit.page.pageNumber - 1;
              block.normalizedX =
                  (hit.offset.x / hit.page.width).clamp(0.0, 1.0);
              block.normalizedY = (topY / hit.page.height).clamp(0.0, 1.0);
            }
          }
          _draggingBlockId = null;
          doc.touch();
          docMgr.saveActiveDocument();
          _queuePdfWriteback(docMgr);
          setState(() {});
        },
        doc,
        docMgr,
      ),
    );
  }

  Widget _buildBlockWidget(
    ContentBlock block,
    bool isDragging,
    GestureDragStartCallback onDragStart,
    GestureDragUpdateCallback onDragUpdate,
    GestureDragEndCallback onDragEnd,
    NoteDocument doc,
    DocumentManager docMgr,
  ) {
    // 1. Refactored blocks (handle their own shell)
    switch (block.type) {
      case ContentBlockType.code:
        return KeyedSubtree(
          key: ValueKey('code_${block.id}'),
          child: CodeBlockWidget(
            block: block,
            isDragging: isDragging,
            onDragStart: onDragStart,
            onDragUpdate: onDragUpdate,
            onDragEnd: onDragEnd,
            onChanged: () {
              doc.touch();
              docMgr.saveActiveDocument();
              _queuePdfWriteback(docMgr);
            },
            onDelete: () {
              doc.blocks.remove(block);
              docMgr.saveActiveDocument();
              _queuePdfWriteback(docMgr);
              setState(() {});
            },
          ),
        );
      case ContentBlockType.markdown:
        return MarkdownBlockWidget(
          block: block,
          isDragging: isDragging,
          onDragStart: onDragStart,
          onDragUpdate: onDragUpdate,
          onDragEnd: onDragEnd,
          onChanged: () {
            doc.touch();
            docMgr.saveActiveDocument();
            _queuePdfWriteback(docMgr);
          },
          onDelete: () {
            doc.blocks.remove(block);
            docMgr.saveActiveDocument();
            _queuePdfWriteback(docMgr);
            setState(() {});
          },
        );
      case ContentBlockType.feynman:
        return FeynmanBlockWidget(
          block: block,
          isDragging: isDragging,
          onDragStart: onDragStart,
          onDragUpdate: onDragUpdate,
          onDragEnd: onDragEnd,
          onChanged: () {
            doc.touch();
            docMgr.saveActiveDocument();
            _queuePdfWriteback(docMgr);
          },
          onDelete: () {
            doc.blocks.remove(block);
            docMgr.saveActiveDocument();
            _queuePdfWriteback(docMgr);
            setState(() {});
          },
        );
      case ContentBlockType.flashcard:
        return FlashcardBlockWidget(
          block: block,
          isDragging: isDragging,
          onDragStart: onDragStart,
          onDragUpdate: onDragUpdate,
          onDragEnd: onDragEnd,
          onChanged: () {
            doc.touch();
            docMgr.saveActiveDocument();
            _queuePdfWriteback(docMgr);
          },
          onDelete: () {
            doc.blocks.remove(block);
            docMgr.saveActiveDocument();
            _queuePdfWriteback(docMgr);
            setState(() {});
          },
        );
      default:
        // 2. Legacy blocks (need external shell)
        return DraggableBlockShell(
          key: block.anchorType == AnchorType.pdfPage
              ? ValueKey('pdf_${block.id}')
              : null,
          block: block,
          isDragging: isDragging,
          backgroundColor: block.anchorType == AnchorType.pdfPage
              ? const Color(0xFF141428).withAlpha(235)
              : const Color(0xFF141428),
          onDragStart: onDragStart,
          onDragUpdate: onDragUpdate,
          onDragEnd: onDragEnd,
          onDelete: () {
            _disposeTextEditingResources(block.id);
            doc.blocks.remove(block);
            doc.touch();
            docMgr.saveActiveDocument();
            _queuePdfWriteback(docMgr);
            setState(() {});
          },
          content: _buildLegacyBlockContent(block, doc, docMgr),
        );
    }
  }

  Widget _buildLegacyBlockContent(
    ContentBlock block,
    NoteDocument doc,
    DocumentManager docMgr,
  ) {
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
            ),
          ),
        );
      case ContentBlockType.latex:
        return LatexBlockWidget(
          block: block,
          onChanged: () {
            doc.touch();
            docMgr.saveActiveDocument();
            _queuePdfWriteback(docMgr);
          },
        );
      case ContentBlockType.chemistry:
        return ChemistryBlockWidget(
          block: block,
          onChanged: () {
            doc.touch();
            docMgr.saveActiveDocument();
            _queuePdfWriteback(docMgr);
          },
        );
      case ContentBlockType.calculator:
        return CalculatorBlockWidget(
          block: block,
          onChanged: () {
            doc.touch();
            docMgr.saveActiveDocument();
            _queuePdfWriteback(docMgr);
          },
        );
      case ContentBlockType.image:
        return ImageBlockWidget(
          block: block,
          onChanged: () {
            doc.touch();
            docMgr.saveActiveDocument();
            _queuePdfWriteback(docMgr);
          },
        );
      case ContentBlockType.flashcard:
        return FlashcardBlockWidget(
          block: block,
          onChanged: () {
            doc.touch();
            docMgr.saveActiveDocument();
            _queuePdfWriteback(docMgr);
          },
        );
      case ContentBlockType.code:
      case ContentBlockType.markdown:
      case ContentBlockType.feynman:
        return const SizedBox.shrink(); // Should not happen via this method
    }
  }

  TextEditingController _controllerForBlock(ContentBlock block) {
    final controller = _textControllers.putIfAbsent(
      block.id,
      () => TextEditingController(text: block.content),
    );
    final focusNode = _textFocusNodes[block.id];
    if (controller.text != block.content &&
        (focusNode == null || !focusNode.hasFocus)) {
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
      _queuePdfWriteback(docMgr);
    });
  }

  void _flushTextBlockSave(String blockId, DocumentManager docMgr) {
    _textSaveDebouncers.remove(blockId)?.cancel();
    docMgr.saveActiveDocument();
    _queuePdfWriteback(docMgr);
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

  // ═══════════════════════════════════════════════════════════
  // FLOATING TOOLBAR
  // ═══════════════════════════════════════════════════════════

  Widget _buildFloatingToolbar(
    CanvasController ctrl,
    DocumentManager docMgr,
    NoteDocument doc,
  ) {
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
          // Colors — current + picker
          _colorDot(ctrl, Colors.white),
          _colorDot(ctrl, const Color(0xFF00D2FF)),
          _colorDot(ctrl, const Color(0xFFFF6B6B)),
          _colorDot(ctrl, const Color(0xFF51CF66)),
          _colorDot(ctrl, const Color(0xFFFFD43B)),
          _colorDot(ctrl, const Color(0xFF7C3AED)),
          const SizedBox(width: 2),
          _colorPickerButton(ctrl),
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
          _iconBtn(Icons.undo_rounded, () {
            ctrl.undo();
            doc.strokes = List<Stroke>.from(ctrl.strokes);
            docMgr.saveActiveDocument();
            _queuePdfWriteback(docMgr, immediate: true);
          }),
          _iconBtn(Icons.redo_rounded, () {
            ctrl.redo();
            doc.strokes = List<Stroke>.from(ctrl.strokes);
            docMgr.saveActiveDocument();
            _queuePdfWriteback(docMgr, immediate: true);
          }),
          if (doc.hasPdf) ...[
            _separator(),
            _toolButton(
              icon: _isWritingBackPdf
                  ? Icons.hourglass_top_rounded
                  : Icons.picture_as_pdf_rounded,
              label: _writebackMessage ?? 'Force PDF Rebuild',
              isActive: false,
              onTap: _isWritingBackPdf
                  ? null
                  : () => _queuePdfWriteback(docMgr, immediate: true),
              activeColor: const Color(0xFF38D9A9),
            ),
          ],
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
    required VoidCallback? onTap,
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
            color: isActive ? color.withAlpha(25) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isActive ? color.withAlpha(80) : Colors.transparent,
            ),
          ),
          child: Icon(
            icon,
            size: 16,
            color: onTap == null
                ? Colors.white.withAlpha(70)
                : (isActive ? color : Colors.white.withAlpha(120)),
          ),
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

  Widget _colorPickerButton(CanvasController ctrl) {
    return GestureDetector(
      onTap: () => _showColorPickerDialog(ctrl),
      child: Container(
        width: 18,
        height: 18,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const SweepGradient(
            colors: [
              Colors.red,
              Colors.yellow,
              Colors.green,
              Colors.cyan,
              Colors.blue,
              Colors.purple,
              Colors.red,
            ],
          ),
          border: Border.all(color: Colors.white.withAlpha(40), width: 1.5),
        ),
        child: Icon(Icons.add, size: 10, color: Colors.white.withAlpha(200)),
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
              title: const Text(
                'Pick a color',
                style: TextStyle(color: Colors.white, fontSize: 14),
              ),
              content: SizedBox(
                width: 260,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Hue bar
                    _hueBar(hsv, (h) => setD(() => hsv = hsv.withHue(h))),
                    const SizedBox(height: 12),
                    // Saturation / Value grid
                    _svPicker(
                      hsv,
                      (s, v) =>
                          setD(() => hsv = hsv.withSaturation(s).withValue(v)),
                    ),
                    const SizedBox(height: 12),
                    // Preview
                    Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: hsv.toColor(),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.white24),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            '#${hsv.toColor().toARGB32().toRadixString(16).substring(2).toUpperCase()}',
                            style: TextStyle(
                              color: Colors.white.withAlpha(120),
                              fontFamily: 'Courier New',
                              fontSize: 13,
                            ),
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
                  child: const Text(
                    'Cancel',
                    style: TextStyle(color: Colors.white38),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    ctrl.setColor(hsv.toColor());
                    Navigator.pop(ctx);
                  },
                  child: const Text(
                    'Apply',
                    style: TextStyle(color: Color(0xFF00D2FF)),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _hueBar(HSVColor hsv, ValueChanged<double> onChanged) {
    return SizedBox(
      height: 20,
      child: GestureDetector(
        onPanDown: (d) => onChanged(_hueFromPosition(d.localPosition.dx, 260)),
        onPanUpdate: (d) =>
            onChanged(_hueFromPosition(d.localPosition.dx, 260)),
        child: CustomPaint(
          painter: _HueBarPainter(selectedHue: hsv.hue),
          size: const Size(260, 20),
        ),
      ),
    );
  }

  double _hueFromPosition(double x, double width) {
    return (x / width * 360).clamp(0, 359).toDouble();
  }

  Widget _svPicker(HSVColor hsv, void Function(double s, double v) onChanged) {
    return SizedBox(
      width: 260,
      height: 150,
      child: GestureDetector(
        onPanDown: (d) => onChanged(
          (d.localPosition.dx / 260).clamp(0, 1).toDouble(),
          (1 - d.localPosition.dy / 150).clamp(0, 1).toDouble(),
        ),
        onPanUpdate: (d) => onChanged(
          (d.localPosition.dx / 260).clamp(0, 1).toDouble(),
          (1 - d.localPosition.dy / 150).clamp(0, 1).toDouble(),
        ),
        child: CustomPaint(
          painter: _SVPickerPainter(
            hue: hsv.hue,
            sat: hsv.saturation,
            val: hsv.value,
          ),
          size: const Size(260, 150),
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
    return CustomPaint(painter: _GridPainter(), size: Size.infinite);
  }
}

class TextBlockWidget extends StatefulWidget {
  const TextBlockWidget({
    super.key,
    required this.block,
    required this.onChanged,
  });

  final ContentBlock block;
  final ValueChanged<String> onChanged;

  @override
  State<TextBlockWidget> createState() => _TextBlockWidgetState();
}

class _TextBlockWidgetState extends State<TextBlockWidget> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.block.content);
  }

  @override
  void didUpdateWidget(covariant TextBlockWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.block.id != widget.block.id) {
      _controller.value = TextEditingValue(
        text: widget.block.content,
        selection: TextSelection.collapsed(offset: widget.block.content.length),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: TextField(
        controller: _controller,
        onChanged: widget.onChanged,
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
    // Selection indicator
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
  bool shouldRepaint(covariant _HueBarPainter old) =>
      old.selectedHue != selectedHue;
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
    // Base hue fill
    canvas.drawRRect(
      rr,
      Paint()..color = HSVColor.fromAHSV(1, hue, 1, 1).toColor(),
    );
    // White → transparent horizontal gradient (saturation)
    canvas.drawRRect(
      rr,
      Paint()
        ..shader = const LinearGradient(
          colors: [Colors.white, Colors.transparent],
        ).createShader(rect),
    );
    // Transparent → black vertical gradient (value)
    canvas.drawRRect(
      rr,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.transparent, Colors.black],
        ).createShader(rect),
    );
    // Selection circle
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
