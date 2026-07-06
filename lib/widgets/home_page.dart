import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final _searchFocusNode = FocusNode();
  String _searchQuery = '';
  String? _selectedSubject; // null = "All"
  String? _currentFolderId; // null = root
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final docMgr = context.watch<DocumentManager>();

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.keyN, control: true): () =>
            _createNote(docMgr),
        const SingleActivator(LogicalKeyboardKey.keyN, meta: true): () =>
            _createNote(docMgr),
        const SingleActivator(LogicalKeyboardKey.keyN,
            control: true, shift: true): () => _createFolder(docMgr),
        const SingleActivator(LogicalKeyboardKey.keyN, meta: true, shift: true):
            () => _createFolder(docMgr),
        const SingleActivator(LogicalKeyboardKey.keyF, control: true): () =>
            _searchFocusNode.requestFocus(),
        const SingleActivator(LogicalKeyboardKey.keyF, meta: true): () =>
            _searchFocusNode.requestFocus(),
      },
      child: Focus(
        autofocus: true,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isCompact = constraints.maxWidth < 700;
            return Scaffold(
              key: _scaffoldKey,
              backgroundColor: const Color(0xFF0A0A1A),
              drawer: isCompact ? Drawer(child: _buildSidebar(docMgr)) : null,
              body: Row(
                children: [
                  // ─── Sidebar ───────────────────────────────────
                  if (!isCompact) _buildSidebar(docMgr),
                  // ─── Main Area ─────────────────────────────────
                  Expanded(child: _buildMainArea(docMgr, isCompact)),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  // ─── Sidebar ────────────────────────────────────────────────

  Widget _buildSidebar(DocumentManager docMgr) {
    final subjects = docMgr.allSubjects.toList()..sort();

    return Container(
      width: 240,
      decoration: BoxDecoration(
        color: const Color(0xFF0D0D20),
        border: Border(
          right: BorderSide(color: Colors.white.withAlpha(12)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // App title
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 32, 20, 24),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF00D2FF), Color(0xFF7C3AED)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF00D2FF).withAlpha(50),
                        blurRadius: 12,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.edit_note,
                      color: Colors.white, size: 22),
                ),
                const SizedBox(width: 12),
                const Text(
                  'NumeiusNotes',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
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
          const SizedBox(height: 8),
          // Subject filters
          if (subjects.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
              child: Row(
                children: [
                  Text(
                    'SUBJECTS',
                    style: TextStyle(
                      color: Colors.white.withAlpha(60),
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.4,
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
          Divider(color: Colors.white.withAlpha(10), height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: _sidebarItem(
              icon: Icons.settings_rounded,
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
            padding: const EdgeInsets.only(left: 20, bottom: 20),
            child: Text(
              'v2.1',
              style: TextStyle(color: Colors.white.withAlpha(30), fontSize: 11),
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      child: Material(
        color: selected
            ? const Color(0xFF00D2FF).withAlpha(18)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          hoverColor: Colors.white.withAlpha(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            child: Row(
              children: [
                Icon(icon,
                    size: 18,
                    color: selected
                        ? const Color(0xFF00D2FF)
                        : Colors.white.withAlpha(100)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      color:
                          selected ? Colors.white : Colors.white.withAlpha(160),
                      fontSize: 14,
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

  Widget _buildMainArea(DocumentManager docMgr, bool isCompact) {
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
              if (isCompact) ...[
                IconButton(
                  icon: const Icon(Icons.menu_rounded, color: Colors.white70),
                  onPressed: () => _scaffoldKey.currentState?.openDrawer(),
                  tooltip: 'Menu',
                ),
                const SizedBox(width: 8),
              ],
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
                    focusNode: _searchFocusNode,
                    onChanged: (v) => setState(() => _searchQuery = v),
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'Search notes...',
                      hintStyle: TextStyle(
                          color: Colors.white.withAlpha(60), fontSize: 13),
                      prefixIcon: Icon(Icons.search,
                          color: Colors.white.withAlpha(60), size: 18),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: Icon(Icons.clear_rounded,
                                  color: Colors.white.withAlpha(60), size: 18),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                              },
                              tooltip: 'Clear search',
                              splashRadius: 20,
                              constraints: const BoxConstraints(),
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
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
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Folders
                      if (subFolders.isNotEmpty) ...[
                        _sectionHeader('FOLDERS'),
                        const SizedBox(height: 12),
                        LayoutBuilder(
                          builder: (ctx, bc) {
                            return GridView.extent(
                              maxCrossAxisExtent: 220,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                              childAspectRatio: 2.4,
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              children: subFolders
                                  .map((f) => _buildFolderCard(f, docMgr))
                                  .toList(),
                            );
                          },
                        ),
                        const SizedBox(height: 28),
                      ],
                      // Notes
                      if (notes.isNotEmpty) ...[
                        _sectionHeader(
                          _currentFolderId != null ? 'NOTES' : 'RECENT NOTES',
                        ),
                        const SizedBox(height: 12),
                        LayoutBuilder(
                          builder: (ctx, bc) {
                            return GridView.extent(
                              maxCrossAxisExtent: 260,
                              crossAxisSpacing: 14,
                              mainAxisSpacing: 14,
                              childAspectRatio: 1.15,
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              children: notes
                                  .map((n) => _buildNoteCard(n, docMgr))
                                  .toList(),
                            );
                          },
                        ),
                      ],
                    ],
                  ),
                ),
        ),
      ],
    );
  }

  Widget _sectionHeader(String label) {
    return Text(
      label,
      style: TextStyle(
        color: Colors.white.withAlpha(90),
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.4,
      ),
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

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => setState(() => _currentFolderId = folder.id),
        onLongPress: () => _showFolderMenu(folder, docMgr),
        hoverColor: Colors.white.withAlpha(6),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF131326),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withAlpha(35)),
          ),
          child: Row(
            children: [
              Icon(Icons.folder_rounded, color: color, size: 24),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
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
                    Text(
                      '$noteCount note${noteCount == 1 ? '' : 's'}',
                      style: TextStyle(
                        color: Colors.white.withAlpha(60),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded,
                  color: Colors.white.withAlpha(40), size: 18),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNoteCard(NoteDocument note, DocumentManager docMgr) {
    final isPdf = note.pdfPath != null;
    final timeAgo = _formatTimeAgo(note.updatedAt);
    final preview =
        note.blocks.isNotEmpty && note.blocks.first.content.isNotEmpty
            ? note.blocks.first.content
            : null;
    final accentColor =
        isPdf ? const Color(0xFFFF6B6B) : const Color(0xFF00D2FF);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {
          docMgr.openInTab(note);
          Navigator.of(context).pushNamed('/editor');
        },
        onLongPress: () => _showNoteMenu(note, docMgr),
        hoverColor: Colors.white.withAlpha(6),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF131326),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withAlpha(12)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(40),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: accentColor.withAlpha(20),
                      borderRadius: BorderRadius.circular(7),
                    ),
                    child: Icon(
                      isPdf
                          ? Icons.picture_as_pdf_rounded
                          : Icons.description_rounded,
                      color: accentColor,
                      size: 15,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      note.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Tooltip(
                    message: 'Note options',
                    child: MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: GestureDetector(
                        onTap: () => _showNoteMenu(note, docMgr),
                        child: Icon(
                          Icons.more_horiz_rounded,
                          size: 18,
                          color: Colors.white.withAlpha(50),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Expanded(
                child: Text(
                  preview ?? 'Empty note',
                  style: TextStyle(
                    color: Colors.white.withAlpha(preview != null ? 90 : 50),
                    fontSize: 12,
                    height: 1.5,
                    fontStyle:
                        preview != null ? FontStyle.normal : FontStyle.italic,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  if (note.subject.isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFF7C3AED).withAlpha(25),
                        borderRadius: BorderRadius.circular(5),
                        border: Border.all(
                          color: const Color(0xFF7C3AED).withAlpha(50),
                        ),
                      ),
                      child: Text(
                        note.subject,
                        style: const TextStyle(
                          color: Color(0xFFB07FFF),
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const Spacer(),
                  ] else
                    const Spacer(),
                  Text(
                    timeAgo,
                    style: TextStyle(
                      color: Colors.white.withAlpha(45),
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ],
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
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: const Color(0xFF00D2FF).withAlpha(15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF00D2FF).withAlpha(30)),
            ),
            child: Icon(
              Icons.note_add_rounded,
              size: 36,
              color: const Color(0xFF00D2FF).withAlpha(120),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'No notes yet',
            style: TextStyle(
              color: Colors.white.withAlpha(120),
              fontSize: 18,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create a new note or import a PDF to get started',
            style: TextStyle(color: Colors.white.withAlpha(50), fontSize: 13),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _emptyStateButton(
                label: 'New Note',
                icon: Icons.add_rounded,
                color: const Color(0xFF00D2FF),
                onTap: () => _createNote(context.read<DocumentManager>()),
              ),
              const SizedBox(width: 12),
              _emptyStateButton(
                label: 'Import PDF',
                icon: Icons.picture_as_pdf_rounded,
                color: const Color(0xFFFF6B6B),
                onTap: () => _importPdf(context.read<DocumentManager>()),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _emptyStateButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: color.withAlpha(18),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
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
    final c = color ?? Colors.white70;
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          hoverColor: c.withAlpha(15),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: c.withAlpha(12),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: c.withAlpha(20)),
            ),
            child: Icon(icon, color: c, size: 19),
          ),
        ),
      ),
    );
  }

  void _openFlashcardReview(DocumentManager docMgr) {
    final cards =
        FlashcardReviewPage.collectCardsFromDocuments(docMgr.documents);
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => FlashcardReviewPage(cards: cards),
      ),
    );
  }

  void _createFolder(DocumentManager docMgr) {
    showDialog(
      context: context,
      builder: (ctx) => _TextInputDialog(
        title: 'New Folder',
        initialText: 'New Folder',
        hintText: 'Folder name',
        confirmLabel: 'Create',
        onConfirm: (text) => docMgr.createFolder(
          parentId: _currentFolderId,
          name: text,
        ),
      ),
    );
  }

  void _createNote(DocumentManager docMgr) {
    docMgr.createDocument(folderId: _currentFolderId);
    Navigator.of(context).pushNamed('/editor');
  }

  Future<void> _importPdf(DocumentManager docMgr) async {
    final bundle = await PdfService.importPdfBundle();
    if (bundle != null) {
      docMgr.createDocument(
        folderId: _currentFolderId,
        pdfOriginalPath: bundle.originalPath,
        pdfWorkingPath: bundle.workingPath,
      );
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
              title:
                  const Text('Rename', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(ctx);
                _renameFolder(folder, docMgr);
              },
            ),
            ListTile(
              leading:
                  const Icon(Icons.delete_outline, color: Color(0xFFFF6B6B)),
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
              leading: const Icon(Icons.drive_file_move, color: Colors.white70),
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
    showDialog(
      context: context,
      builder: (ctx) => _TextInputDialog(
        title: 'Rename Folder',
        initialText: folder.name,
        confirmLabel: 'Rename',
        onConfirm: (text) => docMgr.renameFolder(folder.id, text),
      ),
    );
  }

  void _renameNote(NoteDocument note, DocumentManager docMgr) {
    showDialog(
      context: context,
      builder: (ctx) => _TextInputDialog(
        title: 'Rename Note',
        initialText: note.title,
        confirmLabel: 'Rename',
        onConfirm: (text) => docMgr.renameDocument(note.id, text),
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
                      leading: Icon(Icons.folder, color: Color(f.colorValue)),
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

class _TextInputDialog extends StatefulWidget {
  final String title;
  final String initialText;
  final String? hintText;
  final String confirmLabel;
  final ValueChanged<String> onConfirm;

  const _TextInputDialog({
    required this.title,
    required this.initialText,
    this.hintText,
    required this.confirmLabel,
    required this.onConfirm,
  });

  @override
  State<_TextInputDialog> createState() => _TextInputDialogState();
}

class _TextInputDialogState extends State<_TextInputDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialText);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF1A1A2E),
      title: Text(widget.title,
          style: const TextStyle(color: Colors.white, fontSize: 16)),
      content: TextField(
        controller: _controller,
        autofocus: true,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: widget.hintText,
          hintStyle: TextStyle(color: Colors.white.withAlpha(60)),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            widget.onConfirm(_controller.text.trim());
            Navigator.pop(context);
          },
          child: Text(widget.confirmLabel),
        ),
      ],
    );
  }
}
