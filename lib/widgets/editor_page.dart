import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:notes_app/controllers/canvas_controller.dart';
import 'package:notes_app/controllers/document_manager.dart';
import 'package:notes_app/widgets/tab_manager.dart';
import 'package:notes_app/widgets/canvas_page.dart';
import 'package:notes_app/widgets/pdf_viewer_page.dart';
import 'package:notes_app/widgets/audio_toolbar.dart';
import 'package:notes_app/widgets/transcription_panel.dart';
import 'package:notes_app/widgets/flashcard_review_page.dart';

/// Full editor shell — composes tab bar + canvas/PDF + audio toolbar + transcription panel.
class EditorPage extends StatefulWidget {
  const EditorPage({super.key});

  @override
  State<EditorPage> createState() => _EditorPageState();
}

class _EditorPageState extends State<EditorPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncCanvasToDocument();
    });
  }

  void _syncCanvasToDocument() {
    final docMgr = context.read<DocumentManager>();
    final canvasCtrl = context.read<CanvasController>();
    final doc = docMgr.activeDocument;
    if (doc != null) {
      canvasCtrl.loadStrokes(doc.strokes);
    }

    docMgr.addListener(() {
      if (!mounted) return;
      final activeDoc = docMgr.activeDocument;
      if (activeDoc != null) {
        canvasCtrl.loadStrokes(activeDoc.strokes);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final docMgr = context.watch<DocumentManager>();
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth >= 768;
    final topBarHeight = isTablet ? 48.0 : 42.0;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A1A),
      body: CallbackShortcuts(
        bindings: {
          const SingleActivator(LogicalKeyboardKey.keyZ, control: true): () {
            context.read<CanvasController>().undo();
          },
          const SingleActivator(LogicalKeyboardKey.keyY, control: true): () {
            context.read<CanvasController>().redo();
          },
          const SingleActivator(LogicalKeyboardKey.keyS, control: true): () {
            docMgr.saveActiveDocument();
          },
        },
        child: Focus(
          autofocus: true,
          child: Column(
            children: [
              // Top: Tab bar + back button
              _buildTopBar(docMgr, topBarHeight),
              // Middle: Canvas/PDF + Transcription panel
              Expanded(
                child: Row(
                  children: [
                    // Main editor area (canvas or PDF)
                    Expanded(
                      child: (docMgr.activeDocument?.pdfPath != null)
                          ? PdfViewerPage(
                              pdfPath: docMgr.activeDocument!.pdfPath!)
                          : const CanvasPage(),
                    ),
                    // Right: Live transcription panel (auto-hide on small screens)
                    if (screenWidth >= 600) const TranscriptionPanel(),
                  ],
                ),
              ),
              // Bottom: Audio toolbar
              const AudioToolbar(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(DocumentManager docMgr, double barHeight) {
    return Container(
      height: barHeight,
      decoration: BoxDecoration(
        color: const Color(0xFF0F0F23),
        border: Border(
          bottom: BorderSide(color: Colors.white.withAlpha(10)),
        ),
      ),
      child: Row(
        children: [
          // Back to home
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                docMgr.saveActiveDocument();
                Navigator.of(context).pop();
              },
              child: Container(
                width: barHeight,
                height: barHeight,
                alignment: Alignment.center,
                child: Icon(Icons.arrow_back_rounded,
                    color: Colors.white.withAlpha(150), size: 18),
              ),
            ),
          ),
          // Tab manager takes the rest
          const Expanded(child: TabManager()),
          if ((docMgr.activeDocument?.blocks.where((b) => b.type.name == 'flashcard').length ?? 0) > 0)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: IconButton(
                tooltip: 'Review flashcards',
                onPressed: () {
                  final doc = docMgr.activeDocument;
                  if (doc == null) return;
                  final cards = FlashcardReviewPage.collectCardsFromDocuments([doc]);
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => FlashcardReviewPage(cards: cards),
                    ),
                  );
                },
                icon: const Icon(Icons.style_rounded, size: 18),
                color: const Color(0xFFFF6B9A),
              ),
            ),
        ],
      ),
    );
  }
}
