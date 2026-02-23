import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:notes_app/controllers/ai_settings_controller.dart';
import 'package:notes_app/controllers/canvas_controller.dart';
import 'package:notes_app/controllers/document_manager.dart';
import 'package:notes_app/models/content_block.dart';
import 'package:notes_app/models/flashcard.dart';
import 'package:notes_app/models/quiz.dart';
import 'package:notes_app/services/ai_generation_service.dart';
import 'package:notes_app/widgets/flashcard_study_page.dart';
import 'package:notes_app/widgets/quiz_study_page.dart';
import 'package:notes_app/widgets/tab_manager.dart';
import 'package:notes_app/widgets/canvas_page.dart';
import 'package:notes_app/widgets/pdf_viewer_page.dart';
import 'package:notes_app/widgets/audio_toolbar.dart';
import 'package:notes_app/widgets/transcription_panel.dart';

/// Full editor shell — composes tab bar + canvas/PDF + audio toolbar + transcription panel.
class EditorPage extends StatefulWidget {
  const EditorPage({super.key});

  @override
  State<EditorPage> createState() => _EditorPageState();
}

class _EditorPageState extends State<EditorPage> {
  bool _isGeneratingQuiz = false;
  bool _isGeneratingFlashcards = false;

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

  AiGenerationContext? _buildGenerationContext() {
    final doc = context.read<DocumentManager>().activeDocument;
    if (doc == null) return null;

    final textBlocks = doc.blocks
        .where((b) => b.type == ContentBlockType.text)
        .map((b) => b.content)
        .join('\n');

    final allBlocks = doc.blocks
        .map((b) => '[${b.type.name}] ${b.content} ${_metadataText(b)}')
        .join('\n');

    return AiGenerationContext(
      noteTitle: doc.title,
      noteText: textBlocks,
      transcription: doc.transcription,
      blockText: allBlocks,
    );
  }

  String _metadataText(ContentBlock block) {
    if (block.metadata.isEmpty) return '';
    return block.metadata.entries.map((e) => '${e.key}:${e.value}').join(', ');
  }

  Future<void> _generateQuiz() async {
    setState(() => _isGeneratingQuiz = true);
    try {
      final contextData = _buildGenerationContext();
      final settings = context.read<AiSettingsController>();
      final service = settings.buildService();
      final docMgr = context.read<DocumentManager>();
      final doc = docMgr.activeDocument;

      if (contextData == null || doc == null) {
        throw AiGenerationException(
          'No active document',
          userMessage: 'No active note found.',
        );
      }

      if (service == null) {
        throw AiGenerationException(
          'No provider configured',
          userMessage: 'Configure AI provider credentials in AI Settings first.',
        );
      }

      final questions = await service.generateQuiz(contextData);
      final set = QuizSet(
        id: const Uuid().v4(),
        sourceDocId: doc.id,
        questions: questions,
      );
      await docMgr.saveQuizSet(set);

      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => QuizStudyPage(quizSet: set)),
      );
    } catch (error) {
      if (!mounted) return;
      final message = error is AiGenerationException
          ? error.userMessage
          : 'Something went wrong while generating the quiz.';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    } finally {
      if (mounted) {
        setState(() => _isGeneratingQuiz = false);
      }
    }
  }

  Future<void> _generateFlashcards() async {
    setState(() => _isGeneratingFlashcards = true);
    try {
      final contextData = _buildGenerationContext();
      final settings = context.read<AiSettingsController>();
      final service = settings.buildService();
      final docMgr = context.read<DocumentManager>();
      final doc = docMgr.activeDocument;

      if (contextData == null || doc == null) {
        throw AiGenerationException(
          'No active document',
          userMessage: 'No active note found.',
        );
      }

      if (service == null) {
        throw AiGenerationException(
          'No provider configured',
          userMessage: 'Configure AI provider credentials in AI Settings first.',
        );
      }

      final cards = await service.generateFlashcards(contextData);
      final set = FlashcardSet(
        id: const Uuid().v4(),
        sourceDocId: doc.id,
        cards: cards,
      );
      await docMgr.saveFlashcardSet(set);

      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => FlashcardStudyPage(flashcardSet: set)),
      );
    } catch (error) {
      if (!mounted) return;
      final message = error is AiGenerationException
          ? error.userMessage
          : 'Something went wrong while generating flashcards.';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    } finally {
      if (mounted) {
        setState(() => _isGeneratingFlashcards = false);
      }
    }
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
          const Expanded(child: TabManager()),
          TextButton.icon(
            onPressed: _isGeneratingQuiz ? null : _generateQuiz,
            icon: _isGeneratingQuiz
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.quiz_outlined),
            label: const Text('Generate Quiz'),
          ),
          const SizedBox(width: 8),
          TextButton.icon(
            onPressed: _isGeneratingFlashcards ? null : _generateFlashcards,
            icon: _isGeneratingFlashcards
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.style_outlined),
            label: const Text('Generate Flashcards'),
          ),
          const SizedBox(width: 10),
        ],
      ),
    );
  }
}
