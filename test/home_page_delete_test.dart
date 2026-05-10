import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notes_app/widgets/home_page.dart';
import 'package:notes_app/controllers/document_manager.dart';
import 'package:notes_app/models/document.dart';
import 'package:notes_app/models/folder.dart';
import 'package:provider/provider.dart';

// Mocks
class MockDocumentManager extends DocumentManager {
  final List<NoteFolder> _folders = [];
  final List<NoteDocument> _documents = [];
  int deleteFolderCount = 0;
  int deleteDocumentCount = 0;

  @override
  List<NoteFolder> get folders => _folders;

  @override
  List<NoteDocument> get documents => _documents;

  @override
  List<NoteDocument> getNotesInFolder(String? id) =>
      _documents.where((d) => d.folderId == id).toList();

  @override
  List<NoteFolder> getFoldersByParent(String? id) =>
      _folders.where((f) => f.parentId == id).toList();

  @override
  Set<String> get allSubjects => {};

  @override
  List<NoteDocument> searchNotes(String query) => [];

  @override
  void deleteFolder(String folderId) { deleteFolderCount++; }

  @override
  void deleteDocument(String docId) { deleteDocumentCount++; }

  void seedFolder(NoteFolder f) => _folders.add(f);
  void seedDocument(NoteDocument d) => _documents.add(d);
}

void main() {
  testWidgets('Delete folder and document test with confirmation', (tester) async {
    FlutterError.onError = (FlutterErrorDetails details) {
      if (details.exception is FlutterError && (details.exception as FlutterError).message.contains('RenderFlex overflowed')) {
        return;
      }
      FlutterError.presentError(details);
    };

    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final docMgr = MockDocumentManager();
    docMgr.seedFolder(NoteFolder(id: 'f1', name: 'My Folder'));
    docMgr.seedDocument(NoteDocument(id: 'd1', title: 'My Note', blocks: []));

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ChangeNotifierProvider<DocumentManager>(
            create: (_) => docMgr,
            child: const HomePage(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final folderCard = find.text('My Folder');
    expect(folderCard, findsOneWidget);

    await tester.longPress(folderCard);
    await tester.pumpAndSettle();

    final menuDeleteBtn = find.text('Delete');
    expect(menuDeleteBtn, findsOneWidget);
    await tester.tap(menuDeleteBtn);
    await tester.pumpAndSettle();

    // Check if dialog is displayed
    expect(find.text('Delete Folder'), findsOneWidget);

    // Cancel first
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(docMgr.deleteFolderCount, 0);

    // Tap again
    await tester.longPress(folderCard);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    // Confirm
    final dialogDeleteBtn = find.widgetWithText(TextButton, 'Delete');
    expect(dialogDeleteBtn, findsOneWidget);
    await tester.tap(dialogDeleteBtn);
    await tester.pumpAndSettle();

    expect(docMgr.deleteFolderCount, 1);

    // Test Document deletion
    final noteCard = find.text('My Note');
    expect(noteCard, findsOneWidget);

    await tester.longPress(noteCard);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    // Check if dialog is displayed
    expect(find.text('Delete Note'), findsOneWidget);

    // Cancel first
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(docMgr.deleteDocumentCount, 0);

    // Tap again
    await tester.longPress(noteCard);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    // Confirm
    final dialogDeleteNoteBtn = find.widgetWithText(TextButton, 'Delete');
    expect(dialogDeleteNoteBtn, findsOneWidget);
    await tester.tap(dialogDeleteNoteBtn);
    await tester.pumpAndSettle();

    expect(docMgr.deleteDocumentCount, 1);
  });
}
