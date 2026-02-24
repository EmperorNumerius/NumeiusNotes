import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:notes_app/controllers/canvas_controller.dart';
import 'package:notes_app/controllers/document_manager.dart';
import 'package:notes_app/controllers/audio_controller.dart';
import 'package:notes_app/controllers/ai_settings_controller.dart';
import 'package:notes_app/widgets/home_page.dart';
import 'package:notes_app/widgets/editor_page.dart';
import 'package:notes_app/config/app_config.dart';
import 'package:notes_app/widgets/flashcard_review_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final docManager = DocumentManager();
  await docManager.init();

  final aiSettings = AiSettingsController();
  await aiSettings.init();

  runApp(NotesApp(docManager: docManager, aiSettings: aiSettings));
  final codeUrl = AppConfig.endpoints.codeRunnerBaseUrl.isEmpty
      ? 'disabled'
      : AppConfig.endpoints.codeRunnerBaseUrl;
  final latexUrl =
      AppConfig.endpoints.latexApiUrl.isEmpty ? 'disabled' : AppConfig.endpoints.latexApiUrl;
  debugPrint(
    '[AppConfig] env=${AppConfig.environmentLabel} '
    'codeMock=${AppConfig.isExecutionMocked} '
    'latexMock=${AppConfig.isLatexMocked} '
    'codeUrl=$codeUrl '
    'latexUrl=$latexUrl',
  );

  runApp(NotesApp(docManager: docManager));
}

class NotesApp extends StatelessWidget {
  final DocumentManager docManager;
  final AiSettingsController aiSettings;

  const NotesApp({
    super.key,
    required this.docManager,
    required this.aiSettings,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: docManager),
        ChangeNotifierProvider(create: (_) => CanvasController()),
        ChangeNotifierProvider(create: (_) => AudioController()),
        ChangeNotifierProvider.value(value: aiSettings),
      ],
      child: MaterialApp(
        title: 'Notes',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          brightness: Brightness.dark,
          scaffoldBackgroundColor: const Color(0xFF0A0A1A),
          colorScheme: const ColorScheme.dark(
            primary: Color(0xFF00D2FF),
            secondary: Color(0xFF7C3AED),
            surface: Color(0xFF1A1A2E),
          ),
          fontFamily: 'Segoe UI',
          textTheme: const TextTheme(
            bodyLarge: TextStyle(color: Colors.white),
            bodyMedium: TextStyle(color: Colors.white70),
          ),
        ),
        initialRoute: '/',
        routes: {
          '/': (_) => const HomePage(),
          '/editor': (_) => const EditorPage(),
          '/flashcards': (_) => const FlashcardReviewPage(cards: []),
        },
      ),
    );
  }
}
