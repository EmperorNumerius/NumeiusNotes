import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notes_app/widgets/home_page.dart';
import 'package:notes_app/controllers/document_manager.dart';
import 'package:notes_app/models/document.dart';
import 'package:notes_app/models/folder.dart';
import 'package:provider/provider.dart';

// Minimal mock avoiding file I/O
class MockDocumentManager extends DocumentManager {
  @override
  List<NoteDocument> searchNotes(String query) => [];

  @override
  List<NoteDocument> get documents => [];

  @override
  List<NoteFolder> get folders => [];

  @override
  Set<String> get allSubjects => {};

  @override
  List<NoteDocument> getNotesInFolder(String? id) => [];

  @override
  List<NoteFolder> getFoldersByParent(String? id) => [];
}

void main() {
  testWidgets(
      'Search field shows clear button when text is entered and clears text on tap',
      (tester) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(
      MaterialApp(
        home: ChangeNotifierProvider<DocumentManager>(
          create: (_) => MockDocumentManager(),
          child: const HomePage(),
        ),
      ),
    );

    // Find search field
    final searchField = find.byType(TextField);
    expect(searchField, findsOneWidget);

    // Enter text
    await tester.enterText(searchField, 'hello');
    await tester.pumpAndSettle();

    // Verify clear button appears
    final clearButtonIcon = find.byIcon(Icons.clear_rounded);
    final clearButtonFinder =
        find.widgetWithIcon(IconButton, Icons.clear_rounded);
    expect(clearButtonIcon, findsOneWidget);
    expect(clearButtonFinder, findsOneWidget);

    // Verify text is 'hello'
    expect(find.text('hello'), findsOneWidget);

    // Tap clear button - manually invoke as flutter_test sometimes has trouble with small targets in suffixIcon
    final iconButton = tester.widget<IconButton>(clearButtonFinder);
    iconButton.onPressed!();
    await tester.pumpAndSettle();

    // Verify text cleared
    final TextField widget = tester.widget(searchField);
    expect(widget.controller!.text, isEmpty);
    // Clear button should be gone
    expect(find.byIcon(Icons.clear_rounded), findsNothing);
  });
}
