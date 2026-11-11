import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../models/note_file.dart';
import 'web_fs/web_fs_interface.dart';

/// Core service managing the local markdown vault, file operations,
/// and live sync with local folder / browser storage.
class VaultService extends ChangeNotifier {
  static const String _storageKeyNotes = 'local_notes_vault_v1';
  static const String _storageKeyVaultName = 'local_notes_vault_name';
  static const String _storageKeyActiveId = 'local_notes_active_id';
  static const String _storageKeyDarkMode = 'local_notes_dark_mode';

  final Map<String, String> _memoryStorage = {};

  String _vaultName = 'My Obsidian Vault';
  bool _isNativeFileSystem = false;
  List<NoteFile> _notes = [];
  NoteFile? _activeNote;
  bool _isDarkMode = false;
  bool _isSidebarOpen = true;
  String _searchQuery = '';
  bool _isSaving = false;
  String? _saveStatusMessage;

  // Getters
  String get vaultName => _vaultName;
  bool get isNativeFileSystem => _isNativeFileSystem;
  List<NoteFile> get notes => _notes;
  NoteFile? get activeNote => _activeNote;
  bool get isDarkMode => _isDarkMode;
  bool get isSidebarOpen => _isSidebarOpen;
  String get searchQuery => _searchQuery;
  bool get isSaving => _isSaving;
  String? get saveStatusMessage => _saveStatusMessage;

  List<NoteFile> get favoriteNotes => _notes.where((n) => n.isFavorite).toList();

  /// Group notes by folder
  Map<String, List<NoteFile>> get notesByFolder {
    final Map<String, List<NoteFile>> grouped = {};
    for (final note in filteredNotes) {
      final folder = note.folder.isEmpty ? 'Root' : note.folder;
      grouped.putIfAbsent(folder, () => []).add(note);
    }
    return grouped;
  }

  /// Filtered notes based on current search query
  List<NoteFile> get filteredNotes {
    if (_searchQuery.trim().isEmpty) return _notes;
    final q = _searchQuery.toLowerCase();
    return _notes.where((note) {
      return note.title.toLowerCase().contains(q) ||
          note.content.toLowerCase().contains(q) ||
          note.folder.toLowerCase().contains(q) ||
          note.tags.any((t) => t.toLowerCase().contains(q));
    }).toList();
  }

  String? _getStorageItem(String key) {
    final webVal = WebFsHelper.getStorage(key);
    if (webVal != null) return webVal;
    return _memoryStorage[key];
  }

  void _setStorageItem(String key, String value) {
    WebFsHelper.setStorage(key, value);
    _memoryStorage[key] = value;
  }

  /// Initialize service and restore persisted vault or sample data
  Future<void> initialize() async {
    final darkPref = _getStorageItem(_storageKeyDarkMode);
    _isDarkMode = darkPref == 'true';

    final savedVaultName = _getStorageItem(_storageKeyVaultName);
    if (savedVaultName != null && savedVaultName.isNotEmpty) {
      _vaultName = savedVaultName;
    }

    final savedJson = _getStorageItem(_storageKeyNotes);
    if (savedJson != null && savedJson.isNotEmpty) {
      try {
        final List<dynamic> list = jsonDecode(savedJson);
        _notes = list.map((item) => NoteFile.fromJson(item as Map<String, dynamic>)).toList();
      } catch (e) {
        debugPrint("Error restoring saved notes: $e");
      }
    }

    if (_notes.isEmpty) {
      _notes = _generateCuratedDemoNotes();
      await _persistNotesLocally();
    }

    final activeId = _getStorageItem(_storageKeyActiveId);
    if (activeId != null) {
      _activeNote = _notes.firstWhere(
        (n) => n.id == activeId,
        orElse: () => _notes.first,
      );
    } else {
      _activeNote = _notes.isNotEmpty ? _notes.first : null;
    }

    notifyListeners();
  }

  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    _setStorageItem(_storageKeyDarkMode, _isDarkMode ? 'true' : 'false');
    notifyListeners();
  }

  void toggleSidebar() {
    _isSidebarOpen = !_isSidebarOpen;
    notifyListeners();
  }

  void setSearchQuery(String q) {
    _searchQuery = q;
    notifyListeners();
  }

  void selectNote(NoteFile note) {
    _activeNote = note;
    _setStorageItem(_storageKeyActiveId, note.id);
    notifyListeners();
  }

  /// Open a real local directory on the user's computer via File System Access API
  Future<bool> pickLocalVaultFolder() async {
    try {
      final resultStr = await WebFsHelper.pickDirectory();
      if (resultStr == null) return false;

      final Map<String, dynamic> data = jsonDecode(resultStr);
      if (data['aborted'] == true) {
        return false;
      }

      if (data['success'] == true) {
        final String vName = data['vaultName'] as String? ?? 'Obsidian Vault';
        final List<dynamic> fileList = data['files'] as List<dynamic>? ?? [];

        final List<NoteFile> importedNotes = [];
        for (final f in fileList) {
          final String path = f['path'] as String;
          final String content = f['content'] as String;
          final int? lastMod = f['lastModified'] as int?;

          importedNotes.add(NoteFile.fromMarkdown(
            path: path,
            rawContent: content,
            lastModified: lastMod != null ? DateTime.fromMillisecondsSinceEpoch(lastMod) : DateTime.now(),
          ));
        }

        if (importedNotes.isEmpty) {
          importedNotes.add(NoteFile(
            id: 'Welcome.md',
            title: 'Welcome to $vName',
            content: '# $vName\n\nYour vault is ready. Create pages, write notes, and explore.\n\nAll notes will be saved as local `.md` files in this folder.',
            path: 'Welcome.md',
            folder: 'Root',
            icon: '✨',
          ));
        }

        _vaultName = vName;
        _notes = importedNotes;
        _isNativeFileSystem = true;
        _activeNote = _notes.first;

        _setStorageItem(_storageKeyVaultName, _vaultName);
        await _persistNotesLocally();

        _showSaveStatus("Vault '$vName' loaded from local disk");
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint("Error picking directory: $e");
      return false;
    }
  }

  /// Create a new note
  Future<NoteFile> createNote({String? folder, String? title, String? icon}) async {
    final targetFolder = folder ?? (_activeNote?.folder ?? 'Root');
    final noteTitle = title ?? 'Untitled';
    final noteIcon = icon ?? '📄';
    final safeName = noteTitle.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
    final relPath = targetFolder == 'Root' ? '$safeName.md' : '$targetFolder/$safeName.md';

    final newNote = NoteFile(
      id: '${relPath}_${DateTime.now().millisecondsSinceEpoch}',
      title: noteTitle,
      content: '',
      path: relPath,
      folder: targetFolder,
      icon: noteIcon,
      lastModified: DateTime.now(),
    );

    _notes.insert(0, newNote);
    _activeNote = newNote;

    await _syncNoteToDisk(newNote);
    await _persistNotesLocally();
    notifyListeners();
    return newNote;
  }

  /// Update active note content, title, icon, or cover
  Future<void> updateActiveNote({
    String? title,
    String? content,
    String? icon,
    String? coverUrl,
    bool? isFavorite,
    String? folder,
    List<String>? tags,
  }) async {
    if (_activeNote == null) return;

    if (title != null) _activeNote!.title = title;
    if (content != null) _activeNote!.content = content;
    if (icon != null) _activeNote!.icon = icon;
    if (coverUrl != null) {
      _activeNote!.coverUrl = coverUrl == '__remove__' ? null : coverUrl;
    }
    if (isFavorite != null) _activeNote!.isFavorite = isFavorite;
    if (folder != null) _activeNote!.folder = folder;
    if (tags != null) _activeNote!.tags = tags;
    _activeNote!.lastModified = DateTime.now();

    _showSaveStatus("Saving...");
    await _syncNoteToDisk(_activeNote!);
    await _persistNotesLocally();
    _showSaveStatus("Saved");
    notifyListeners();
  }

  /// Toggle favorite status of a note
  void toggleFavorite(NoteFile note) {
    note.isFavorite = !note.isFavorite;
    _persistNotesLocally();
    _syncNoteToDisk(note);
    notifyListeners();
  }

  /// Delete note
  Future<void> deleteNote(NoteFile note) async {
    _notes.removeWhere((n) => n.id == note.id);
    if (_activeNote?.id == note.id) {
      _activeNote = _notes.isNotEmpty ? _notes.first : null;
    }

    if (_isNativeFileSystem) {
      await WebFsHelper.deleteFile(note.path);
    }

    await _persistNotesLocally();
    notifyListeners();
  }

  /// Rename note title
  Future<void> renameNote(NoteFile note, String newTitle) async {
    note.title = newTitle;
    note.lastModified = DateTime.now();
    await _syncNoteToDisk(note);
    await _persistNotesLocally();
    notifyListeners();
  }

  /// Export note as markdown download
  void exportNoteAsMarkdown(NoteFile note) {
    final filename = '${note.title.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_')}.md';
    WebFsHelper.downloadFile(filename, note.toFullMarkdown());
  }

  /// Reset to Curated Sample Vault
  Future<void> loadSampleVault() async {
    _notes = _generateCuratedDemoNotes();
    _vaultName = 'Obsidian Knowledge Base';
    _isNativeFileSystem = false;
    _activeNote = _notes.first;

    _setStorageItem(_storageKeyVaultName, _vaultName);
    await _persistNotesLocally();
    notifyListeners();
  }

  /// Write note to real local disk via File System Access API
  Future<void> _syncNoteToDisk(NoteFile note) async {
    if (_isNativeFileSystem) {
      final markdownWithFrontmatter = note.toFullMarkdown();
      await WebFsHelper.saveFile(note.path, markdownWithFrontmatter);
    }
  }

  /// Save notes to browser storage
  Future<void> _persistNotesLocally() async {
    try {
      final jsonList = _notes.map((n) => n.toJson()).toList();
      _setStorageItem(_storageKeyNotes, jsonEncode(jsonList));
      if (_activeNote != null) {
        _setStorageItem(_storageKeyActiveId, _activeNote!.id);
      }
    } catch (e) {
      debugPrint("Persistence error: $e");
    }
  }

  void _showSaveStatus(String msg) {
    _saveStatusMessage = msg;
    _isSaving = msg == "Saving...";
    notifyListeners();
  }

  /// Curated demo notes showcasing Notion aesthetics & Obsidian markdown
  List<NoteFile> _generateCuratedDemoNotes() {
    return [
      NoteFile(
        id: 'welcome.md',
        path: 'Getting Started/Welcome to Local Notes.md',
        title: 'Welcome to Local Notes',
        folder: 'Getting Started',
        icon: '✨',
        coverUrl: 'gradient_sand',
        isFavorite: true,
        tags: ['guide', 'features'],
        content: '''
# Welcome to Local Notes

Local Notes gives your local Obsidian markdown vault the breathtaking minimalism and fluid experience of **Notion**. Everything is stored on your own computer as clean, portable `.md` files.

> [!NOTE]
> 💡 **Pure Local Markdown & Zero Lock-in**
> Your notes remain 100% standard markdown. If you open your folder in Obsidian or VS Code, every file, tag, and frontmatter metadata property is right where you expect it.

---

## ⚡ What Makes It Special

- **Clean Typography**: You don't see ugly markdown hashes or formatting clutter. Text reads with generous line-height and crisp proportions.
- **Interactive Blocks**: Check off to-dos with a single click, collapse sections, and paste code snippets with syntax highlighting.
- **Local Vault Integration**: Click **"Open Folder"** in the sidebar to bind this app to any folder on your hard drive.
- **Slash Commands**: Type `/` anywhere to summon the Notion command palette.

---

### Quick Start Checklist

- [x] Launch Local Notes
- [ ] Click the checkbox beside this item to test interactive to-dos
- [ ] Press **Ctrl + K** to open the instant Quick Switcher
- [ ] Click **"Open Folder"** in the sidebar to pick your Obsidian vault
- [ ] Toggle between **Notion Mode** and **Raw Markdown** in the top right

---

> "Simplicity is the prerequisite for reliability and aesthetic delight."
''',
      ),
      NoteFile(
        id: 'roadmap.md',
        path: 'Projects/Product Roadmap 2026.md',
        title: 'Product Roadmap 2026',
        folder: 'Projects',
        icon: '🚀',
        coverUrl: 'gradient_space',
        isFavorite: true,
        tags: ['work', 'strategy'],
        content: '''
# Product Roadmap 2026

Quarterly objectives and engineering milestones for next-generation local-first software.

> [!TIP]
> 🎯 **Q1 Priority**: Flawless cross-device sync and native Android packaging.

---

## Q1 Milestones

| Feature | Owner | Status | Priority |
| --- | --- | --- | --- |
| Notion-style Block Editor | Senior Dev | Completed | High |
| File System Access API | Core Team | Completed | High |
| Android & Mobile Shell | Mobile Team | In Progress | Medium |
| Instant Fuzzy Search | Search Team | Completed | High |

---

### Immediate Tasks

- [x] Polish light & dark mode color palettes
- [x] Implement smooth slash command menu
- [ ] Test directory pickers across all Chromium browsers
- [ ] Add PDF and clean markdown export
''',
      ),
      NoteFile(
        id: 'architecture.md',
        path: 'Engineering/Architecture & System Design.md',
        title: 'Architecture & System Design',
        folder: 'Engineering',
        icon: '💻',
        coverUrl: 'gradient_emerald',
        isFavorite: false,
        tags: ['dev', 'flutter'],
        content: '''
# Architecture & System Design

Technical blueprint for building a local-first markdown note workspace in Flutter Web.

## Core Abstraction Layers

1. **Storage Layer**: Uses the W3C File System Access API (`showDirectoryPicker`) to directly stream reads and writes to the user's local disk without server intermediaries.
2. **Block Parser Engine**: Converts raw markdown into Notion blocks and serializes blocks back to markdown on disk.
3. **Reactive UI Framework**: Stateless tree visualization with optimistic UI updates.

```dart
// Native File System Access Bridge
final dirHandle = await window.showDirectoryPicker();
final fileHandle = await dirHandle.getFileHandle('Note.md', create: true);
final writable = await fileHandle.createWritable();
await writable.write(markdownString);
await writable.close();
```

> [!NOTE]
> 📌 **Obsidian Compatibility**
> Files are saved in UTF-8 encoding with standard YAML frontmatter so Obsidian, Logseq, and Typora can read them simultaneously.
''',
      ),
      NoteFile(
        id: 'daily.md',
        path: 'Journal/Daily Journal & Reflections.md',
        title: 'Daily Journal & Reflections',
        folder: 'Journal',
        icon: '☕',
        coverUrl: 'gradient_sunset',
        isFavorite: false,
        tags: ['personal', 'habits'],
        content: '''
# Daily Journal & Reflections

A minimal daily check-in to clear the mind, organize priorities, and celebrate progress.

## Today's Highlights

- Morning espresso with 30 minutes of deep reading
- Focused 3-hour uninterrupted block on Local Notes architecture
- Afternoon walk in the crisp autumn air

---

### Daily Habits

- [x] Morning meditation (15 mins)
- [x] Read 20 pages of architecture books
- [x] 10,000 steps
- [ ] Drink 2.5L water
- [ ] Plan tomorrow's top 3 priorities

> "Focus is a muscle. Train it every single morning."
''',
      ),
      NoteFile(
        id: 'books.md',
        path: 'Knowledge/Reading List & Bookshelf.md',
        title: 'Reading List & Bookshelf',
        folder: 'Knowledge',
        icon: '📚',
        coverUrl: 'gradient_lavender',
        isFavorite: false,
        tags: ['books', 'learning'],
        content: '''
# Reading List & Bookshelf

Curated notes and memorable takeaways from impactful non-fiction and design literature.

## Currently Reading

- **The Design of Everyday Things** — Don Norman
  - *Key Takeaway*: Good design is actually a lot harder to notice than poor design, because good design fits our needs so naturally.

- **Designing Data-Intensive Applications** — Martin Kleppmann
  - *Key Takeaway*: Reliability, scalability, and maintainability are the true foundations of software architecture.

---

### Wishlist & Queue

- [ ] *Creative Selection* by Ken Kocienda
- [ ] *A Philosophy of Software Design* by John Ousterhout
- [ ] *The Visual Display of Quantitative Information* by Edward Tufte
''',
      ),
    ];
  }
}
