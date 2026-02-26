import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notes_app/widgets/home_page.dart';
import 'package:notes_app/controllers/document_manager.dart';
import 'package:notes_app/models/document.dart';
import 'package:notes_app/models/folder.dart';
import 'package:notes_app/models/content_block.dart';
import 'package:provider/provider.dart';

// Mocks
class MockDocumentManager extends DocumentManager {
  final List<NoteFolder> _folders = [];
  final List<NoteDocument> _documents = [];

  @override
  List<NoteFolder> get folders => _folders;

  @override
  List<NoteDocument> get documents => _documents;

  @override
  List<NoteDocument> getNotesInFolder(String? id) => _documents.where((d) => d.folderId == id).toList();

  @override
  List<NoteFolder> getFoldersByParent(String? id) => _folders.where((f) => f.parentId == id).toList();

  @override
  Set<String> get allSubjects => {};

  @override
  List<NoteDocument> searchNotes(String query) => [];

  @override
  NoteFolder createFolder({String? parentId, String name = 'New Folder'}) {
    return NoteFolder(id: 'new', name: name);
  }

  @override
  void renameFolder(String folderId, String newName) {}

  @override
  void renameDocument(String docId, String newTitle) {}

  @override
  void deleteFolder(String folderId) {}

  @override
  void deleteDocument(String docId) {}

  @override
  void moveToFolder(String docId, String? folderId) {}
}

void main() {
  testWidgets('HomePage dialogs open and close correctly', (tester) async {
    // Set explicit size for tablet layout to ensure sidebar and main area are visible if needed,
    // though for compact layout (default 800x600 for tests) it might show sidebar in drawer.
    // HomePage uses `constraints.maxWidth < 700` for compact.
    // Default test surface size is 800x600. So it is NOT compact.
    // Sidebar is visible.

    await tester.pumpWidget(
      MaterialApp(
        home: ChangeNotifierProvider<DocumentManager>(
          create: (_) => MockDocumentManager(),
  List<NoteDocument> getNotesBySubject(String subject) => [];

  @override
  NoteFolder createFolder({String? parentId, String name = 'New Folder'}) {
    final folder = NoteFolder(id: 'folder_${_folders.length}', name: name, parentId: parentId);
    _folders.add(folder);
    notifyListeners();
    return folder;
  }

  @override
  void renameFolder(String folderId, String newName) {
     final f = _folders.firstWhere((f) => f.id == folderId);
     f.name = newName;
     notifyListeners();
  }

  @override
  void renameDocument(String docId, String newTitle) {
    final d = _documents.firstWhere((d) => d.id == docId);
    d.title = newTitle;
    notifyListeners();
  }

  void seedFolder(NoteFolder f) => _folders.add(f);
  void seedDocument(NoteDocument d) => _documents.add(d);
}

void main() {
  testWidgets('Create Folder dialog works', (tester) async {
    final docMgr = MockDocumentManager();
    await tester.pumpWidget(
      MaterialApp(
        home: ChangeNotifierProvider<DocumentManager>(
          create: (_) => docMgr,
          child: const HomePage(),
        ),
      ),
    );

    final newFolderBtn = find.byTooltip('New Folder');
    expect(newFolderBtn, findsOneWidget);
    await tester.tap(newFolderBtn);
    await tester.pumpAndSettle();

    expect(find.text('New Folder'), findsNWidgets(2));

    // Find the TextField inside the AlertDialog
    final dialogTextField = find.descendant(of: find.byType(AlertDialog), matching: find.byType(TextField));
    await tester.enterText(dialogTextField, 'My Awesome Folder');
    await tester.tap(find.text('Create'));
    await tester.pumpAndSettle();

    expect(docMgr.folders.any((f) => f.name == 'My Awesome Folder'), isTrue);
    expect(find.text('My Awesome Folder'), findsOneWidget);
  });

  testWidgets('Rename Folder dialog works', (tester) async {
    final docMgr = MockDocumentManager();
    docMgr.seedFolder(NoteFolder(id: 'f1', name: 'Old Folder'));

    await tester.pumpWidget(
      MaterialApp(
        home: ChangeNotifierProvider<DocumentManager>(
          create: (_) => docMgr,
          child: const HomePage(),
        ),
      ),
    );

    final folderCard = find.text('Old Folder');
    expect(folderCard, findsOneWidget);

    await tester.longPress(folderCard);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Rename'));
    await tester.pumpAndSettle();

    expect(find.text('Rename Folder'), findsOneWidget);

    final dialogTextField = find.descendant(of: find.byType(AlertDialog), matching: find.byType(TextField));
    await tester.enterText(dialogTextField, 'New Name Folder');
    await tester.tap(find.text('Rename'));
    await tester.pumpAndSettle();

    expect(docMgr.folders.first.name, 'New Name Folder');
    expect(find.text('New Name Folder'), findsOneWidget);
  });

  testWidgets('Rename Note dialog works', (tester) async {
    final docMgr = MockDocumentManager();
    docMgr.seedDocument(NoteDocument(
      id: 'd1',
      title: 'Old Note',
      blocks: [ContentBlock(id: 'b1', type: ContentBlockType.text)],
    ));

    await tester.pumpWidget(
      MaterialApp(
        home: ChangeNotifierProvider<DocumentManager>(
          create: (_) => docMgr,
          child: const HomePage(),
        ),
      ),
    );

    final noteCard = find.text('Old Note');
    expect(noteCard, findsOneWidget);

    await tester.longPress(noteCard);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Rename'));
    await tester.pumpAndSettle();

    expect(find.text('Rename Note'), findsOneWidget);

    final dialogTextField = find.descendant(of: find.byType(AlertDialog), matching: find.byType(TextField));
    await tester.enterText(dialogTextField, 'New Name Note');
    await tester.tap(find.text('Rename'));
    await tester.pumpAndSettle();

    expect(docMgr.documents.first.title, 'New Name Note');
    expect(find.text('New Name Note'), findsOneWidget);
  });
}
