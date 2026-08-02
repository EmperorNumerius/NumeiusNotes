import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notes_app/widgets/home_page.dart';
import 'package:notes_app/controllers/document_manager.dart';
import 'package:notes_app/models/document.dart';
import 'package:notes_app/models/folder.dart';
import 'package:provider/provider.dart';

class MockDocumentManager extends DocumentManager {
  @override
  List<NoteDocument> searchNotes(String query) => [];

  final List<NoteFolder> _mockFolders = [
    NoteFolder(id: 'folder1', name: 'Test Folder', parentId: null, colorValue: 0xFF000000),
  ];

  final List<NoteDocument> _mockDocuments = [
     NoteDocument(id: 'note1', title: 'Test Note', blocks: [], updatedAt: DateTime.now()),
  ];

  @override
  List<NoteDocument> get documents => _mockDocuments;

  @override
  List<NoteFolder> get folders => _mockFolders;

  @override
  Set<String> get allSubjects => {};

  @override
  List<NoteDocument> getNotesInFolder(String? id) {
    if (id == 'folder1') return [];
    if (id == null) return _mockDocuments; // Show in root for test simplicity
    return [];
  }

  @override
  List<NoteFolder> getFoldersByParent(String? id) {
    if (id == null) return _mockFolders;
    return [];
  }

  bool createFolderCalled = false;
  bool renameFolderCalled = false;
  bool renameDocumentCalled = false;

  @override
  NoteFolder createFolder({String? parentId, String name = 'New Folder'}) {
    createFolderCalled = true;
    return NoteFolder(id: 'mock_id', name: name, parentId: parentId);
  }

  @override
  void renameFolder(String folderId, String newName) {
    renameFolderCalled = true;
  }

  @override
  void renameDocument(String docId, String newTitle) {
    renameDocumentCalled = true;
  }
}

void main() {
  testWidgets('Create folder dialog appears and functions correctly', (tester) async {
    final mockDocMgr = MockDocumentManager();
    await tester.pumpWidget(
      MaterialApp(
        home: ChangeNotifierProvider<DocumentManager>(
          create: (_) => mockDocMgr,
          child: const HomePage(),
        ),
      ),
    );

    // Find "New Folder" button in the top bar
    final newFolderButton = find.byTooltip('New Folder');
    expect(newFolderButton, findsOneWidget);

    // Tap it
    await tester.tap(newFolderButton);
    await tester.pumpAndSettle();

    // Verify dialog appears
    expect(find.text('New Folder'), findsNWidgets(2)); // Title and default text
    expect(find.byType(AlertDialog), findsOneWidget);

    // Tap Create
    final createButton = find.text('Create');
    await tester.tap(createButton);
    await tester.pumpAndSettle();

    // Verify folder created
    expect(mockDocMgr.createFolderCalled, isTrue);
    // Verify dialog closed
    expect(find.byType(AlertDialog), findsNothing);
  });

  testWidgets('Rename folder dialog appears and functions correctly', (tester) async {
    final mockDocMgr = MockDocumentManager();
    await tester.pumpWidget(
      MaterialApp(
        home: ChangeNotifierProvider<DocumentManager>(
          create: (_) => mockDocMgr,
          child: const HomePage(),
        ),
      ),
    );

    // Find the folder card
    final folderCard = find.text('Test Folder');
    expect(folderCard, findsOneWidget);

    // Long press to open menu
    await tester.longPress(folderCard);
    await tester.pumpAndSettle();

    // Verify bottom sheet appears
    expect(find.text('Rename'), findsOneWidget);
    expect(find.text('Delete'), findsOneWidget);

    // Tap Rename
    await tester.tap(find.text('Rename'));
    await tester.pumpAndSettle();

    // Verify dialog appears
    expect(find.text('Rename Folder'), findsOneWidget);
    expect(find.byType(AlertDialog), findsOneWidget);
    expect(find.widgetWithText(TextField, 'Test Folder'), findsOneWidget);

    // Tap Rename
    // Since there are multiple "Rename" texts (menu item and button), we need to be specific or tap the last one
    final renameButton = find.widgetWithText(TextButton, 'Rename');
    await tester.tap(renameButton);
    await tester.pumpAndSettle();

    // Verify rename called
    expect(mockDocMgr.renameFolderCalled, isTrue);
    // Verify dialog closed
    expect(find.byType(AlertDialog), findsNothing);
  });

  testWidgets('Rename note dialog appears and functions correctly', (tester) async {
    final mockDocMgr = MockDocumentManager();
    await tester.pumpWidget(
      MaterialApp(
        home: ChangeNotifierProvider<DocumentManager>(
          create: (_) => mockDocMgr,
          child: const HomePage(),
        ),
      ),
    );

    // Find the note card
    final noteCard = find.text('Test Note');
    expect(noteCard, findsOneWidget);

    // Long press to open menu
    await tester.tap(find.byIcon(Icons.more_horiz_rounded));
    await tester.pumpAndSettle();

    // Verify bottom sheet appears
    expect(find.text('Rename'), findsOneWidget);
    expect(find.text('Move to Folder'), findsOneWidget);
    expect(find.text('Delete'), findsOneWidget);

    // Tap Rename
    await tester.tap(find.text('Rename'));
    await tester.pumpAndSettle();

    // Verify dialog appears
    expect(find.text('Rename Note'), findsOneWidget);
    expect(find.byType(AlertDialog), findsOneWidget);
    expect(find.widgetWithText(TextField, 'Test Note'), findsOneWidget);

    // Tap Rename
    final renameButton = find.widgetWithText(TextButton, 'Rename');
    await tester.tap(renameButton);
    await tester.pumpAndSettle();

    // Verify rename called
    expect(mockDocMgr.renameDocumentCalled, isTrue);
    // Verify dialog closed
    expect(find.byType(AlertDialog), findsNothing);
  });
}
