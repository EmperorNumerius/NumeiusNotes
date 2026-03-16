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
import 'package:notes_app/widgets/document_surface_page.dart';
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
  bool _isGeneratingQuiz = false;
  bool _isGeneratingFlashcards = false;
  late final DocumentManager _docMgr;
  late final CanvasController _canvasCtrl;
  late final VoidCallback _docListener;
  bool _isDocListenerRegistered = false;

  @override
  void initState() {
    super.initState();
    _docListener = _handleDocumentChanged;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isDocListenerRegistered) return;

    _docMgr = context.read<DocumentManager>();
    _canvasCtrl = context.read<CanvasController>();
    _docMgr.addListener(_docListener);
    _isDocListenerRegistered = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _handleDocumentChanged();
    });
  }

  void _handleDocumentChanged() {
    final doc = _docMgr.activeDocument;
    if (doc != null) {
      _canvasCtrl.loadStrokes(doc.strokes);
    }
  }

  @override
  void dispose() {
    if (_isDocListenerRegistered) {
      _docMgr.removeListener(_docListener);
    }
    super.dispose();
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
                      child: const DocumentSurfacePage(),
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
    final topH = (barHeight + 8).clamp(52.0, 64.0);
    return Container(
      height: topH,
      decoration: BoxDecoration(
        color: const Color(0xFF0D0D20),
        border: Border(
          bottom: BorderSide(color: Colors.white.withAlpha(10)),
        ),
      ),
      child: Row(
        children: [
          // Back to home
          Tooltip(
            message: 'Back to notes',
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  docMgr.saveActiveDocument();
                  Navigator.of(context).pop();
                },
                borderRadius: BorderRadius.circular(8),
                hoverColor: Colors.white.withAlpha(10),
                child: SizedBox(
                  width: topH,
                  height: topH,
                  child: Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: Colors.white.withAlpha(160),
                    size: 17,
                  ),
                ),
              ),
            ),
          ),
          Container(width: 1, height: 24, color: Colors.white.withAlpha(10)),
          const Expanded(child: TabManager()),
          // AI actions — icon only on compact, icon+label on wider screens
          LayoutBuilder(
            builder: (ctx, bc) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _topBarAction(
                    icon: Icons.quiz_outlined,
                    label: 'Generate Quiz',
                    color: const Color(0xFF51CF66),
                    loading: _isGeneratingQuiz,
                    onTap: _isGeneratingQuiz ? null : _generateQuiz,
                  ),
                  const SizedBox(width: 4),
                  _topBarAction(
                    icon: Icons.style_outlined,
                    label: 'Flashcards',
                    color: const Color(0xFFFF6B9A),
                    loading: _isGeneratingFlashcards,
                    onTap:
                        _isGeneratingFlashcards ? null : _generateFlashcards,
                  ),
                  if ((docMgr.activeDocument?.blocks
                              .where((b) => b.type.name == 'flashcard')
                              .length ??
                          0) >
                      0) ...[
                    const SizedBox(width: 4),
                    Tooltip(
                      message: 'Review flashcards',
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(9),
                          onTap: () {
                            final doc = docMgr.activeDocument;
                            if (doc == null) return;
                            final cards = FlashcardReviewPage
                                .collectCardsFromDocuments([doc]);
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) =>
                                    FlashcardReviewPage(cards: cards),
                              ),
                            );
                          },
                          child: Container(
                            width: 38,
                            height: 38,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: const Color(0xFFFF6B9A).withAlpha(18),
                              borderRadius: BorderRadius.circular(9),
                            ),
                            child: const Icon(
                              Icons.style_rounded,
                              size: 18,
                              color: Color(0xFFFF6B9A),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(width: 10),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _topBarAction({
    required IconData icon,
    required String label,
    required Color color,
    bool loading = false,
    VoidCallback? onTap,
  }) {
    return Tooltip(
      message: label,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(9),
          onTap: onTap,
          hoverColor: color.withAlpha(15),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: onTap == null ? color.withAlpha(10) : color.withAlpha(15),
              borderRadius: BorderRadius.circular(9),
              border: Border.all(color: color.withAlpha(25)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (loading)
                  SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: color,
                    ),
                  )
                else
                  Icon(icon, size: 16, color: color),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    color: color,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
