import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notes_app/widgets/audio_toolbar.dart';
import 'package:notes_app/controllers/audio_controller.dart';
import 'package:notes_app/controllers/document_manager.dart';
import 'package:notes_app/controllers/canvas_controller.dart';
import 'package:notes_app/models/document.dart';
import 'package:provider/provider.dart';

// Mocks
class MockAudioController extends AudioController {
  @override
  bool get isRecording => false;
  @override
  bool get isPlaying => false;
  @override
  Duration get currentPosition => Duration.zero;
  @override
  Duration get totalDuration => const Duration(minutes: 1);
}

class MockDocumentManager extends DocumentManager {
  final NoteDocument? _activeDoc;
  MockDocumentManager({NoteDocument? activeDoc}) : _activeDoc = activeDoc;

  @override
  NoteDocument? get activeDocument => _activeDoc;
}

class MockCanvasController extends CanvasController {
  @override
  bool playbackMode = false;
}

void main() {
  testWidgets('AudioToolbar buttons have accessible tooltips', (tester) async {
    final doc = NoteDocument(id: '1', title: 'Test Note', audioPath: 'test.m4a');

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AudioController>(create: (_) => MockAudioController()),
          ChangeNotifierProvider<DocumentManager>(create: (_) => MockDocumentManager(activeDoc: doc)),
          ChangeNotifierProvider<CanvasController>(create: (_) => MockCanvasController()),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: AudioToolbar(),
          ),
        ),
      ),
    );

    // Verify buttons are present by icon
    expect(find.byIcon(Icons.fiber_manual_record), findsOneWidget); // Record
    expect(find.byIcon(Icons.play_arrow), findsOneWidget); // Play
    expect(find.byIcon(Icons.sync), findsOneWidget); // Sync

    // Verify tooltips are PRESENT and CORRECT (this confirms the UX fix)
    expect(find.byTooltip('Start recording'), findsOneWidget);
    expect(find.byTooltip('Play audio'), findsOneWidget);
    expect(find.byTooltip('Enable sync'), findsOneWidget);
  });
}
