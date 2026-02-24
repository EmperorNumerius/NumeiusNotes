import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:notes_app/controllers/document_manager.dart';
import 'package:notes_app/models/folder.dart';
import 'package:notes_app/models/document.dart';
import 'package:notes_app/services/pdf_service.dart';
import 'package:notes_app/widgets/ai_settings_dialog.dart';
import 'package:notes_app/config/app_config.dart';
import 'package:notes_app/widgets/flashcard_review_page.dart';

/// Home page — folder grid, recent notes, subject sidebar, search.
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String _searchQuery = '';
  String? _selectedSubject; // null = "All"
  String? _currentFolderId; // null = root
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final docMgr = context.watch<DocumentManager>();

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A1A),
      body: Row(
        children: [
          // ─── Sidebar ───────────────────────────────────
          _buildSidebar(docMgr),
          // ─── Main Area ─────────────────────────────────
          Expanded(child: _buildMainArea(docMgr)),
        ],
      ),
    );
  }

  // ─── Sidebar ────────────────────────────────────────────────

  Widget _buildSidebar(DocumentManager docMgr) {
    final subjects = docMgr.allSubjects.toList()..sort();

    return Container(
      width: 220,
      decoration: BoxDecoration(
        color: const Color(0xFF0F0F23),
        border: Border(
          right: BorderSide(color: Colors.white.withAlpha(15)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // App title
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 28, 20, 24),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF00D2FF), Color(0xFF7C3AED)],
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child:
                      const Icon(Icons.edit_note, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 10),
                const Text(
                  'Notes',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
          ),
          // Navigation items
          _sidebarItem(
            icon: Icons.home_rounded,
            label: 'All Notes',
            selected: _selectedSubject == null && _currentFolderId == null,
            onTap: () => setState(() {
              _selectedSubject = null;
              _currentFolderId = null;
            }),
          ),
          _sidebarItem(
            icon: Icons.access_time_rounded,
            label: 'Recent',
            selected: false,
            onTap: () => setState(() {
              _selectedSubject = null;
              _currentFolderId = null;
            }),
          ),
          const SizedBox(height: 16),
          // Subject filters
          if (subjects.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Row(
                children: [
                  Text(
                    'SUBJECTS',
                    style: TextStyle(
                      color: Colors.white.withAlpha(80),
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
            ),
            ...subjects.map((s) => _sidebarItem(
                  icon: Icons.label_rounded,
                  label: s,
                  selected: _selectedSubject == s,
                  onTap: () => setState(() {
                    _selectedSubject = s;
                    _currentFolderId = null;
                  }),
                )),
          ],
          const Spacer(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: _sidebarItem(
              icon: Icons.settings,
              label: 'AI Settings',
              selected: false,
              onTap: () {
                showDialog(
                  context: context,
                  builder: (_) => const AiSettingsDialog(),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'v2.1',
              style: TextStyle(color: Colors.white.withAlpha(40), fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sidebarItem({
    required IconData icon,
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 1),
      child: Material(
        color: selected ? const Color(0xFF1A1A3E) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Icon(icon,
                    size: 18,
                    color: selected
                        ? const Color(0xFF00D2FF)
                        : Colors.white.withAlpha(120)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      color:
                          selected ? Colors.white : Colors.white.withAlpha(180),
                      fontSize: 13,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── Main Area ──────────────────────────────────────────────

  Widget _buildMainArea(DocumentManager docMgr) {
    // Determine which notes to show
    List<NoteDocument> notes;
    List<NoteFolder> subFolders;

    if (_searchQuery.isNotEmpty) {
      notes = docMgr.searchNotes(_searchQuery);
      subFolders = [];
    } else if (_selectedSubject != null) {
      notes = docMgr.getNotesBySubject(_selectedSubject!);
      subFolders = [];
    } else {
      notes = docMgr.getNotesInFolder(_currentFolderId);
      subFolders = docMgr.getFoldersByParent(_currentFolderId);
    }

    final breadcrumb = _buildBreadcrumb(docMgr);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ─── Top bar ─────────────────────────────
        Container(
          height: 64,
          padding: const EdgeInsets.symmetric(horizontal: 24),
          decoration: BoxDecoration(
            color: const Color(0xFF0F0F23),
            border: Border(
              bottom: BorderSide(color: Colors.white.withAlpha(10)),
            ),
          ),
          child: Row(
            children: [
              // Breadcrumb
              if (breadcrumb != null) ...[
                breadcrumb,
                const SizedBox(width: 16),
              ],
              // Search
              Expanded(
                child: Container(
                  height: 36,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A2E),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (v) => setState(() => _searchQuery = v),
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'Search notes...',
                      hintStyle:
                          TextStyle(color: Colors.white.withAlpha(60), fontSize: 13),
                      prefixIcon: Icon(Icons.search,
                          color: Colors.white.withAlpha(60), size: 18),
                      border: InputBorder.none,
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              _buildEnvironmentBadge(),
              const SizedBox(width: 8),
              // New folder
              _topBarButton(
                icon: Icons.create_new_folder_rounded,
                tooltip: 'New Folder',
                onTap: () => _createFolder(docMgr),
              ),
              const SizedBox(width: 4),
              _topBarButton(
                icon: Icons.add_rounded,
                tooltip: 'New Note',
                color: const Color(0xFF00D2FF),
                onTap: () => _createNote(docMgr),
              ),
              const SizedBox(width: 4),
              _topBarButton(
                icon: Icons.style_rounded,
                tooltip: 'Review Flashcards',
                color: const Color(0xFFFF6B9A),
                onTap: () => _openFlashcardReview(docMgr),
              ),
              const SizedBox(width: 4),
              _topBarButton(
                icon: Icons.picture_as_pdf_rounded,
                tooltip: 'Import PDF',
                color: const Color(0xFFFF6B6B),
                onTap: () => _importPdf(docMgr),
              ),
            ],
          ),
        ),
        // ─── Content grid ────────────────────────
        Expanded(
          child: (subFolders.isEmpty && notes.isEmpty)
              ? _buildEmptyState()
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Folders
                      if (subFolders.isNotEmpty) ...[
                        Text(
                          'FOLDERS',
                          style: TextStyle(
                            color: Colors.white.withAlpha(80),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: subFolders
                              .map((f) => _buildFolderCard(f, docMgr))
                              .toList(),
                        ),
                        const SizedBox(height: 28),
                      ],
                      // Notes
                      if (notes.isNotEmpty) ...[
                        Text(
                          _currentFolderId != null ? 'NOTES' : 'RECENT NOTES',
                          style: TextStyle(
                            color: Colors.white.withAlpha(80),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: notes
                              .map((n) => _buildNoteCard(n, docMgr))
                              .toList(),
                        ),
                      ],
                    ],
                  ),
                ),
        ),
      ],
    );
  }


  Widget _buildEnvironmentBadge() {
    final env = AppConfig.environmentLabel;
    final codeMode = AppConfig.isExecutionMocked ? 'CODE:MOCK' : 'CODE:LIVE';
    final latexMode = AppConfig.isLatexMocked ? 'LATEX:MOCK' : 'LATEX:LIVE';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: AppConfig.hasAnyMockingEnabled
            ? const Color(0xFFFFB020).withAlpha(30)
            : const Color(0xFF00D2FF).withAlpha(25),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppConfig.hasAnyMockingEnabled
              ? const Color(0xFFFFB020).withAlpha(120)
              : const Color(0xFF00D2FF).withAlpha(110),
        ),
      ),
      child: Text(
        '$env • $codeMode • $latexMode',
        style: TextStyle(
          color: Colors.white.withAlpha(220),
          fontSize: 10,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  // ─── Breadcrumb ─────────────────────────────────────────────

  Widget? _buildBreadcrumb(DocumentManager docMgr) {
    if (_currentFolderId == null) return null;
    // Build path from root to current
    final path = <NoteFolder>[];
    String? id = _currentFolderId;
    while (id != null) {
      final f = docMgr.folders.firstWhere((f) => f.id == id);
      path.insert(0, f);
      id = f.parentId;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          onTap: () => setState(() => _currentFolderId = null),
          child: Icon(Icons.home_rounded,
              color: Colors.white.withAlpha(100), size: 16),
        ),
        ...path.map((f) => Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.chevron_right,
                    color: Colors.white.withAlpha(40), size: 16),
                InkWell(
                  onTap: () => setState(() => _currentFolderId = f.id),
                  child: Text(
                    f.name,
                    style: TextStyle(
                      color: f.id == _currentFolderId
                          ? Colors.white
                          : Colors.white.withAlpha(100),
                      fontSize: 13,
                      fontWeight: f.id == _currentFolderId
                          ? FontWeight.w600
                          : FontWeight.w400,
                    ),
                  ),
                ),
              ],
            )),
      ],
    );
  }

  // ─── Cards ──────────────────────────────────────────────────

  Widget _buildFolderCard(NoteFolder folder, DocumentManager docMgr) {
    final noteCount = docMgr.getNotesInFolder(folder.id).length;
    final color = Color(folder.colorValue);

    return SizedBox(
      width: 180,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => setState(() => _currentFolderId = folder.id),
          onLongPress: () => _showFolderMenu(folder, docMgr),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF141428),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withAlpha(40)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.folder_rounded, color: color, size: 28),
                const SizedBox(height: 10),
                Text(
                  folder.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '$noteCount note${noteCount == 1 ? '' : 's'}',
                  style: TextStyle(
                    color: Colors.white.withAlpha(80),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNoteCard(NoteDocument note, DocumentManager docMgr) {
    final isPdf = note.pdfPath != null;
    final timeAgo = _formatTimeAgo(note.updatedAt);

    return SizedBox(
      width: 200,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            docMgr.openInTab(note);
            Navigator.of(context).pushNamed('/editor');
          },
          onLongPress: () => _showNoteMenu(note, docMgr),
          child: Container(
            height: 140,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF141428),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withAlpha(12)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      isPdf ? Icons.picture_as_pdf : Icons.description_rounded,
                      color: isPdf
                          ? const Color(0xFFFF6B6B)
                          : const Color(0xFF00D2FF),
                      size: 18,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        note.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: Text(
                    note.blocks.isNotEmpty
                        ? note.blocks.first.content.isEmpty
                            ? 'Empty note'
                            : note.blocks.first.content
                        : 'Empty note',
                    style: TextStyle(
                      color: Colors.white.withAlpha(80),
                      fontSize: 11,
                      height: 1.4,
                    ),
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    if (note.subject.isNotEmpty) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF7C3AED).withAlpha(30),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          note.subject,
                          style: const TextStyle(
                            color: Color(0xFF7C3AED),
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                    ],
                    Text(
                      timeAgo,
                      style: TextStyle(
                        color: Colors.white.withAlpha(50),
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── Empty state ────────────────────────────────────────────

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.note_add_rounded,
              size: 48, color: Colors.white.withAlpha(40)),
          const SizedBox(height: 16),
          Text(
            'No notes yet',
            style: TextStyle(
                color: Colors.white.withAlpha(80),
                fontSize: 16,
                fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          Text(
            'Create a new note or folder to get started',
            style:
                TextStyle(color: Colors.white.withAlpha(40), fontSize: 13),
          ),
        ],
      ),
    );
  }

  // ─── Helpers ────────────────────────────────────────────────

  Widget _topBarButton({
    required IconData icon,
    required String tooltip,
    Color? color,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onTap,
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: (color ?? Colors.white).withAlpha(15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color ?? Colors.white70, size: 18),
          ),
        ),
      ),
    );
  }

  void _openFlashcardReview(DocumentManager docMgr) {
    final cards = FlashcardReviewPage.collectCardsFromDocuments(docMgr.documents);
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => FlashcardReviewPage(cards: cards),
      ),
    );
  }

  void _createFolder(DocumentManager docMgr) {
    final ctrl = TextEditingController(text: 'New Folder');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text('New Folder',
            style: TextStyle(color: Colors.white, fontSize: 16)),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Folder name',
            hintStyle: TextStyle(color: Colors.white.withAlpha(60)),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              docMgr.createFolder(
                  parentId: _currentFolderId, name: ctrl.text.trim());
              Navigator.pop(ctx);
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _createNote(DocumentManager docMgr) {
    docMgr.createDocument(folderId: _currentFolderId);
    Navigator.of(context).pushNamed('/editor');
  }

  Future<void> _importPdf(DocumentManager docMgr) async {
    final pdfPath = await PdfService.importPdf();
    if (pdfPath != null) {
      docMgr.createDocument(folderId: _currentFolderId, pdfPath: pdfPath);
      if (mounted) Navigator.of(context).pushNamed('/editor');
    }
  }

  void _showFolderMenu(NoteFolder folder, DocumentManager docMgr) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A2E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit, color: Colors.white70),
              title: const Text('Rename', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(ctx);
                _renameFolder(folder, docMgr);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Color(0xFFFF6B6B)),
              title: const Text('Delete',
                  style: TextStyle(color: Color(0xFFFF6B6B))),
              onTap: () {
                Navigator.pop(ctx);
                docMgr.deleteFolder(folder.id);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showNoteMenu(NoteDocument note, DocumentManager docMgr) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A2E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit, color: Colors.white70),
              title:
                  const Text('Rename', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(ctx);
                _renameNote(note, docMgr);
              },
            ),
            ListTile(
              leading:
                  const Icon(Icons.drive_file_move, color: Colors.white70),
              title: const Text('Move to Folder',
                  style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(ctx);
                _moveNoteToFolder(note, docMgr);
              },
            ),
            ListTile(
              leading:
                  const Icon(Icons.delete_outline, color: Color(0xFFFF6B6B)),
              title: const Text('Delete',
                  style: TextStyle(color: Color(0xFFFF6B6B))),
              onTap: () {
                Navigator.pop(ctx);
                docMgr.deleteDocument(note.id);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _renameFolder(NoteFolder folder, DocumentManager docMgr) {
    final ctrl = TextEditingController(text: folder.name);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text('Rename Folder',
            style: TextStyle(color: Colors.white, fontSize: 16)),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              docMgr.renameFolder(folder.id, ctrl.text.trim());
              Navigator.pop(ctx);
            },
            child: const Text('Rename'),
          ),
        ],
      ),
    );
  }

  void _renameNote(NoteDocument note, DocumentManager docMgr) {
    final ctrl = TextEditingController(text: note.title);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text('Rename Note',
            style: TextStyle(color: Colors.white, fontSize: 16)),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              docMgr.renameDocument(note.id, ctrl.text.trim());
              Navigator.pop(ctx);
            },
            child: const Text('Rename'),
          ),
        ],
      ),
    );
  }

  void _moveNoteToFolder(NoteDocument note, DocumentManager docMgr) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1A1A2E),
          title: const Text('Move to Folder',
              style: TextStyle(color: Colors.white, fontSize: 16)),
          content: SizedBox(
            width: 300,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.home, color: Colors.white70),
                  title: const Text('Root (No Folder)',
                      style: TextStyle(color: Colors.white)),
                  onTap: () {
                    docMgr.moveToFolder(note.id, null);
                    Navigator.pop(ctx);
                  },
                ),
                ...docMgr.folders.map((f) => ListTile(
                      leading: Icon(Icons.folder,
                          color: Color(f.colorValue)),
                      title: Text(f.name,
                          style: const TextStyle(color: Colors.white)),
                      onTap: () {
                        docMgr.moveToFolder(note.id, f.id);
                        Navigator.pop(ctx);
                      },
                    )),
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatTimeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dt.month}/${dt.day}/${dt.year}';
  }
}
