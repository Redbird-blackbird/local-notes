import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../models/note_file.dart';
import '../../models/block_model.dart';
import '../../services/vault_service.dart';
import '../../theme/app_theme.dart';
import '../modals/cover_picker_dialog.dart';
import '../modals/icon_picker_dialog.dart';
import '../modals/move_note_dialog.dart';
import 'slash_command_menu.dart';

class NotionEditorView extends StatefulWidget {
  final VaultService vaultService;

  const NotionEditorView({
    super.key,
    required this.vaultService,
  });

  @override
  State<NotionEditorView> createState() => _NotionEditorViewState();
}

class _NotionEditorViewState extends State<NotionEditorView> {
  late TextEditingController _titleController;
  late TextEditingController _rawMarkdownController;
  List<NotionBlock> _blocks = [];
  String? _lastLoadedNoteId;
  bool _isRawMode = false;
  bool _isFullWidth = false;

  // Slash menu state
  OverlayEntry? _slashMenuOverlay;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _rawMarkdownController = TextEditingController();
    _syncNoteData();
  }

  @override
  void didUpdateWidget(covariant NotionEditorView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.vaultService.activeNote?.id != _lastLoadedNoteId) {
      _syncNoteData();
    }
  }

  void _syncNoteData() {
    final note = widget.vaultService.activeNote;
    if (note == null) {
      _lastLoadedNoteId = null;
      return;
    }
    _lastLoadedNoteId = note.id;
    _titleController.text = note.title;
    _rawMarkdownController.text = note.content;
    _blocks = BlockParser.parseMarkdown(note.content);
  }

  void _saveBlocksToNote() {
    final note = widget.vaultService.activeNote;
    if (note == null) return;
    final markdown = BlockParser.blocksToMarkdown(_blocks);
    _rawMarkdownController.text = markdown;
    widget.vaultService.updateActiveNote(
      content: markdown,
      title: _titleController.text.trim().isEmpty ? 'Untitled' : _titleController.text.trim(),
    );
  }

  void _saveRawToNote(String raw) {
    widget.vaultService.updateActiveNote(
      content: raw,
      title: _titleController.text.trim().isEmpty ? 'Untitled' : _titleController.text.trim(),
    );
    _blocks = BlockParser.parseMarkdown(raw);
  }

  void _removeSlashMenu() {
    _slashMenuOverlay?.remove();
    _slashMenuOverlay = null;
  }

  void _showSlashMenu(BuildContext context, int blockIndex, Offset position) {
    _removeSlashMenu();

    final overlay = Overlay.of(context);
    _slashMenuOverlay = OverlayEntry(
      builder: (ctx) {
        return Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: _removeSlashMenu,
              ),
            ),
            Positioned(
              left: position.dx.clamp(20.0, MediaQuery.of(context).size.width - 340.0),
              top: position.dy.clamp(60.0, MediaQuery.of(context).size.height - 400.0),
              child: Material(
                color: Colors.transparent,
                child: SlashCommandMenu(
                  onSelect: (blockType, {defaultText}) {
                    _insertBlockAt(blockIndex + 1, blockType, defaultText: defaultText);
                    _removeSlashMenu();
                  },
                  onDismiss: _removeSlashMenu,
                ),
              ),
            ),
          ],
        );
      },
    );

    overlay.insert(_slashMenuOverlay!);
  }

  String? _autoFocusBlockId;

  void _insertBlockAt(int index, BlockType type, {String? defaultText}) {
    final newBlock = NotionBlock(
      id: 'block_${DateTime.now().millisecondsSinceEpoch}_${_blocks.length}',
      type: type,
      text: defaultText ?? '',
    );
    if (type == BlockType.callout) {
      newBlock.calloutIcon = '💡';
      newBlock.calloutColor = 'yellow';
    } else if (type == BlockType.code) {
      newBlock.codeLanguage = 'dart';
    } else if (type == BlockType.table) {
      newBlock.tableData = [
        ['Feature', 'Status', 'Notes'],
        ['Local Markdown', 'Done', 'Pure .md files'],
        ['Notion UI', 'Done', 'Clean aesthetics'],
      ];
    }
    setState(() {
      if (index >= _blocks.length) {
        _blocks.add(newBlock);
      } else {
        _blocks.insert(index, newBlock);
      }
      _autoFocusBlockId = newBlock.id;
    });
    _saveBlocksToNote();
  }

  void _handleEnterOnBlock(int index) {
    final current = _blocks[index];
    final nextType = current.type;
    int? nextNumber;
    if (nextType == BlockType.numbered) {
      nextNumber = (current.numberIndex ?? 1) + 1;
    }

    final newBlock = NotionBlock(
      id: 'block_${DateTime.now().millisecondsSinceEpoch}_${_blocks.length}',
      type: nextType,
      text: '',
      isChecked: false,
      numberIndex: nextNumber,
    );

    setState(() {
      _blocks.insert(index + 1, newBlock);
      _autoFocusBlockId = newBlock.id;
    });
    _saveBlocksToNote();
  }

  void _handleBackspaceOnEmpty(int index) {
    final block = _blocks[index];
    if (block.type != BlockType.paragraph) {
      setState(() {
        block.type = BlockType.paragraph;
      });
      _saveBlocksToNote();
    } else if (_blocks.length > 1) {
      setState(() {
        _blocks.removeAt(index);
        final prevIndex = (index - 1).clamp(0, _blocks.length - 1);
        _autoFocusBlockId = _blocks[prevIndex].id;
      });
      _saveBlocksToNote();
    }
  }

  void _handleTurnInto(int index, BlockType newType) {
    setState(() {
      _blocks[index].type = newType;
      if (newType == BlockType.numbered && _blocks[index].numberIndex == null) {
        _blocks[index].numberIndex = 1;
      }
    });
    _saveBlocksToNote();
  }

  void _handleDuplicate(int index) {
    final orig = _blocks[index];
    final copy = orig.copyWith(
      id: 'block_${DateTime.now().millisecondsSinceEpoch}_${_blocks.length}',
    );
    setState(() {
      _blocks.insert(index + 1, copy);
      _autoFocusBlockId = copy.id;
    });
    _saveBlocksToNote();
  }

  void _handleReorderItem(int oldIndex, int newIndex) {
    setState(() {
      final item = _blocks.removeAt(oldIndex);
      _blocks.insert(newIndex, item);
    });
    _saveBlocksToNote();
  }

  void _deleteBlockAt(int index) {
    if (_blocks.length <= 1) {
      setState(() {
        _blocks[0].text = '';
        _blocks[0].type = BlockType.paragraph;
      });
    } else {
      setState(() {
        _blocks.removeAt(index);
      });
    }
    _saveBlocksToNote();
  }

  @override
  void dispose() {
    _removeSlashMenu();
    _titleController.dispose();
    _rawMarkdownController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final note = widget.vaultService.activeNote;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppTheme.darkBg : AppTheme.lightBg;
    final textColor = isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary;
    final mutedColor = isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary;
    final border = isDark ? AppTheme.darkBorder : AppTheme.lightBorder;

    if (note == null) {
      return _buildEmptyState(isDark, textColor, mutedColor);
    }

    final maxContentWidth = _isFullWidth ? double.infinity : 780.0;
    final hasCover = note.coverUrl != null;

    return Container(
      color: bg,
      child: Column(
        children: [
          // Top Navigation & Action Bar
          _buildTopActionBar(note, isDark, textColor, mutedColor, border),

          // Scrollable Editor Canvas
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  // Cover Image Header (if present)
                  if (hasCover)
                    _buildCoverBanner(note, isDark, textColor, mutedColor),

                  // Center Constrained Content
                  Center(
                    child: Container(
                      constraints: BoxConstraints(maxWidth: maxContentWidth),
                      padding: EdgeInsets.symmetric(
                        horizontal: _isFullWidth ? 48 : 36,
                        vertical: hasCover ? 0 : 28,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Page Icon (Overlapping cover if cover exists)
                          _buildIconAndHoverBar(note, hasCover, isDark, textColor, mutedColor),

                          const SizedBox(height: 14),

                          // Page Title Input
                          _buildTitleInput(note, textColor, mutedColor),

                          const SizedBox(height: 12),

                          // Metadata Bar (last edited, word count, tags)
                          _buildMetadataBar(note, isDark, mutedColor),

                          const SizedBox(height: 24),
                          Divider(height: 1, color: border.withValues(alpha: 0.55)),
                          const SizedBox(height: 24),

                          // Content Area: Notion WYSIWYG vs Raw Markdown
                          if (_isRawMode)
                            _buildRawMarkdownEditor(isDark, textColor, border)
                          else
                            _buildNotionBlockCanvas(isDark, textColor, mutedColor, border),

                          const SizedBox(height: 160),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopActionBar(
    NoteFile note,
    bool isDark,
    Color textColor,
    Color mutedColor,
    Color border,
  ) {
    final vault = widget.vaultService;
    final isNarrow = MediaQuery.of(context).size.width < 600;
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkBg : AppTheme.lightBg,
        border: Border(bottom: BorderSide(color: border, width: 1)),
      ),
      child: Row(
        children: [
          // Sidebar Toggle Button
          if (!vault.isSidebarOpen)
            IconButton(
              icon: Icon(Icons.menu, size: 18, color: mutedColor),
              tooltip: 'Open sidebar',
              onPressed: () => vault.toggleSidebar(),
              splashRadius: 16,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          if (!vault.isSidebarOpen) const SizedBox(width: 12),

          // Breadcrumbs (shrink/ellipsize on narrow screens)
          Expanded(
            child: Row(
              children: [
          Flexible(
            child: Text(
              vault.vaultName,
              style: TextStyle(fontSize: 12, color: mutedColor, fontWeight: FontWeight.w500),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Text('/', style: TextStyle(fontSize: 12, color: mutedColor.withValues(alpha: 0.4))),
          ),
          Flexible(
          child: InkWell(
            onTap: () {
              showDialog(
                context: context,
                builder: (ctx) => MoveNoteDialog(note: note, vaultService: vault),
              );
            },
            borderRadius: BorderRadius.circular(4),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.folder_outlined, size: 13, color: mutedColor),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      note.folder,
                      style: TextStyle(fontSize: 12, color: mutedColor, fontWeight: FontWeight.w500),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Text('/', style: TextStyle(fontSize: 12, color: mutedColor.withValues(alpha: 0.4))),
          ),
          Flexible(
            child: Text(
              note.title.isEmpty ? 'Untitled' : note.title,
              style: TextStyle(fontSize: 12, color: textColor, fontWeight: FontWeight.w600),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),

              ],
            ),
          ),

          // Save Indicator with pulsing dot
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: (isDark ? AppTheme.darkCardBg : AppTheme.lightSidebarBg).withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: vault.isSaving ? AppTheme.accentOrange : AppTheme.accentGreen,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: (vault.isSaving ? AppTheme.accentOrange : AppTheme.accentGreen).withValues(alpha: 0.4),
                        blurRadius: 4,
                        spreadRadius: 1,
                      )
                    ],
                  ),
                ),
                if (!isNarrow) const SizedBox(width: 6),
                if (!isNarrow) Text(
                  vault.saveStatusMessage ?? 'Saved',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: mutedColor),
                ),
              ],
            ),
          ),

          SizedBox(width: isNarrow ? 6 : 12),

          // View Mode Switcher Pill (Notion vs Raw)
          Container(
            decoration: BoxDecoration(
              color: isDark ? AppTheme.darkCardBg : AppTheme.lightSidebarBg,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: border),
            ),
            padding: const EdgeInsets.all(2),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildModeTab(isNarrow ? '⚡' : '⚡ Notion', !_isRawMode, () => setState(() => _isRawMode = false), isDark, textColor, mutedColor),
                _buildModeTab(isNarrow ? '📄' : '📄 Raw .md', _isRawMode, () => setState(() => _isRawMode = true), isDark, textColor, mutedColor),
              ],
            ),
          ),

          const SizedBox(width: 8),

          // Favorite Button
          IconButton(
            icon: Icon(
              note.isFavorite ? Icons.star_rounded : Icons.star_outline_rounded,
              size: 20,
              color: note.isFavorite ? AppTheme.accentOrange : mutedColor,
            ),
            tooltip: note.isFavorite ? 'Favorited' : 'Add to favorites',
            onPressed: () => vault.toggleFavorite(note),
            splashRadius: 16,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),

          const SizedBox(width: 8),

          // More Options Menu
          PopupMenuButton<String>(
            icon: Icon(Icons.more_horiz, size: 20, color: mutedColor),
            tooltip: 'Style & settings',
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            color: isDark ? AppTheme.darkCardBg : Colors.white,
            onSelected: (val) {
              if (val == 'full_width') {
                setState(() => _isFullWidth = !_isFullWidth);
              } else if (val == 'move_folder') {
                showDialog(
                  context: context,
                  builder: (ctx) => MoveNoteDialog(note: note, vaultService: vault),
                );
              } else if (val == 'export') {
                vault.exportNoteAsMarkdown(note);
              } else if (val == 'copy_markdown') {
                Clipboard.setData(ClipboardData(text: note.toFullMarkdown()));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Markdown copied to clipboard'), duration: Duration(seconds: 2)),
                );
              } else if (val == 'delete') {
                vault.deleteNote(note);
              }
            },
            itemBuilder: (ctx) => [
              PopupMenuItem(
                value: 'move_folder',
                child: Row(
                  children: [
                    Icon(Icons.drive_file_move_outlined, size: 16, color: mutedColor),
                    const SizedBox(width: 10),
                    const Text('Move to folder...', style: TextStyle(fontSize: 12.5)),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'full_width',
                child: Row(
                  children: [
                    Icon(
                      _isFullWidth ? Icons.check_box_outlined : Icons.check_box_outline_blank,
                      size: 16,
                      color: mutedColor,
                    ),
                    const SizedBox(width: 10),
                    const Text('Full width', style: TextStyle(fontSize: 12.5)),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'export',
                child: Row(
                  children: [
                    Icon(Icons.download_rounded, size: 16, color: mutedColor),
                    const SizedBox(width: 10),
                    const Text('Export .md file', style: TextStyle(fontSize: 12.5)),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'copy_markdown',
                child: Row(
                  children: [
                    Icon(Icons.copy_rounded, size: 16, color: mutedColor),
                    const SizedBox(width: 10),
                    const Text('Copy raw markdown', style: TextStyle(fontSize: 12.5)),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete_outline, size: 16, color: AppTheme.accentRed),
                    const SizedBox(width: 10),
                    Text('Delete note', style: TextStyle(fontSize: 12.5, color: AppTheme.accentRed)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildModeTab(
    String label,
    bool isSelected,
    VoidCallback onTap,
    bool isDark,
    Color textColor,
    Color mutedColor,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? AppTheme.darkSidebarActive : Colors.white)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(4),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  )
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            color: isSelected ? textColor : mutedColor,
          ),
        ),
      ),
    );
  }

  Widget _buildCoverBanner(
    NoteFile note,
    bool isDark,
    Color textColor,
    Color mutedColor,
  ) {
    return Stack(
      children: [
        Container(
          height: 200,
          width: double.infinity,
          decoration: CoverPickerDialog.getDecoration(note.coverUrl!),
        ),
        Positioned(
          bottom: 12,
          right: 24,
          child: Row(
            children: [
              _buildCoverActionPill(
                label: 'Change cover',
                icon: Icons.image_outlined,
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (ctx) => CoverPickerDialog(
                      currentCover: note.coverUrl,
                      onSelectCover: (c) => widget.vaultService.updateActiveNote(coverUrl: c),
                      onRemoveCover: () => widget.vaultService.updateActiveNote(coverUrl: '__remove__'),
                    ),
                  );
                },
              ),
              const SizedBox(width: 8),
              _buildCoverActionPill(
                label: 'Remove',
                icon: Icons.close,
                onTap: () => widget.vaultService.updateActiveNote(coverUrl: '__remove__'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCoverActionPill({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            color: Colors.black.withValues(alpha: 0.45),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 13, color: Colors.white),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: Colors.white),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIconAndHoverBar(
    NoteFile note,
    bool hasCover,
    bool isDark,
    Color textColor,
    Color mutedColor,
  ) {
    return Transform.translate(
      offset: Offset(0, hasCover ? -36 : 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Notion Signature Overlapping Page Icon
          InkWell(
            onTap: () {
              showDialog(
                context: context,
                builder: (ctx) => IconPickerDialog(
                  currentIcon: note.icon,
                  onSelectIcon: (ic) => widget.vaultService.updateActiveNote(icon: ic),
                  onRemoveIcon: () => widget.vaultService.updateActiveNote(icon: '📄'),
                ),
              );
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: hasCover
                  ? BoxDecoration(
                      color: isDark ? AppTheme.darkBg : AppTheme.lightBg,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.12),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    )
                  : null,
              child: Text(
                note.icon,
                style: TextStyle(fontSize: hasCover ? 62 : 54),
              ),
            ),
          ),
          const SizedBox(width: 14),

          // Quick "Add cover" button if no cover
          if (!hasCover)
            TextButton.icon(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (ctx) => CoverPickerDialog(
                    currentCover: note.coverUrl,
                    onSelectCover: (c) => widget.vaultService.updateActiveNote(coverUrl: c),
                    onRemoveCover: () {},
                  ),
                );
              },
              icon: Icon(Icons.image_outlined, size: 14, color: mutedColor),
              label: Text('Add cover', style: TextStyle(fontSize: 12, color: mutedColor)),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                minimumSize: Size.zero,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTitleInput(NoteFile note, Color textColor, Color mutedColor) {
    return TextField(
      controller: _titleController,
      style: GoogleFonts.inter(
        fontSize: 34,
        fontWeight: FontWeight.w700,
        color: textColor,
        letterSpacing: -0.7,
      ),
      decoration: InputDecoration(
        hintText: 'Untitled',
        hintStyle: GoogleFonts.inter(
          fontSize: 34,
          fontWeight: FontWeight.w700,
          color: mutedColor.withValues(alpha: 0.35),
          letterSpacing: -0.7,
        ),
        border: InputBorder.none,
        contentPadding: EdgeInsets.zero,
      ),
      onChanged: (val) {
        widget.vaultService.renameNote(note, val.trim().isEmpty ? 'Untitled' : val.trim());
      },
    );
  }

  Widget _buildMetadataBar(NoteFile note, bool isDark, Color mutedColor) {
    final dateFormat = DateFormat('MMM d, yyyy • h:mm a');
    final metaRow = Row(
      children: [
        Icon(Icons.access_time_rounded, size: 13, color: mutedColor.withValues(alpha: 0.7)),
        const SizedBox(width: 6),
        Text(
          dateFormat.format(note.lastModified),
          style: TextStyle(fontSize: 12, color: mutedColor.withValues(alpha: 0.8)),
        ),
        const SizedBox(width: 16),
        Text(
          '${note.wordCount} words',
          style: TextStyle(fontSize: 12, color: mutedColor.withValues(alpha: 0.8)),
        ),
        const SizedBox(width: 8),
        Text('•', style: TextStyle(fontSize: 12, color: mutedColor.withValues(alpha: 0.4))),
        const SizedBox(width: 8),
        Text(
          note.readingTime,
          style: TextStyle(fontSize: 12, color: mutedColor.withValues(alpha: 0.8)),
        ),
        if (note.tags.isNotEmpty) ...[
          const SizedBox(width: 16),
          ...note.tags.map(
            (tag) => Padding(
              padding: const EdgeInsets.only(right: 6),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: (isDark ? AppTheme.darkBorder : AppTheme.lightBorder).withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text('#$tag', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: mutedColor)),
              ),
            ),
          ),
        ],
      ],
    );
    return SingleChildScrollView(scrollDirection: Axis.horizontal, child: metaRow);
  }

  Widget _buildRawMarkdownEditor(bool isDark, Color textColor, Color border) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCardBg : AppTheme.lightCardBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: border),
      ),
      padding: const EdgeInsets.all(16),
      child: TextField(
        controller: _rawMarkdownController,
        maxLines: null,
        style: GoogleFonts.jetBrainsMono(
          fontSize: 13.5,
          color: textColor,
          height: 1.6,
        ),
        decoration: const InputDecoration(
          border: InputBorder.none,
          hintText: 'Write raw markdown here...',
        ),
        onChanged: _saveRawToNote,
      ),
    );
  }

  Widget _buildNotionBlockCanvas(
    bool isDark,
    Color textColor,
    Color mutedColor,
    Color border,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Theme(
          data: Theme.of(context).copyWith(
            canvasColor: Colors.transparent,
            shadowColor: Colors.transparent,
          ),
          child: ReorderableListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            buildDefaultDragHandles: false,
            itemCount: _blocks.length,
            onReorderItem: _handleReorderItem,
            proxyDecorator: (Widget child, int index, Animation<double> animation) {
              return Material(
                elevation: 6,
                color: isDark ? AppTheme.darkCardBg : Colors.white,
                shadowColor: Colors.black26,
                borderRadius: BorderRadius.circular(6),
                child: child,
              );
            },
            itemBuilder: (context, i) {
              return Container(
                key: ValueKey(_blocks[i].id),
                child: _buildBlockItem(i, _blocks[i], isDark, textColor, mutedColor, border),
              );
            },
          ),
        ),

        // Bottom click-to-add block area
        InkWell(
          onTap: () => _insertBlockAt(_blocks.length, BlockType.paragraph),
          borderRadius: BorderRadius.circular(6),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Row(
              children: [
                Icon(Icons.add, size: 16, color: mutedColor.withValues(alpha: 0.4)),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    'Click to add a block, or type "/" for commands',
                    style: TextStyle(
                      fontSize: 13.5,
                      color: mutedColor.withValues(alpha: 0.4),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBlockItem(
    int index,
    NotionBlock block,
    bool isDark,
    Color textColor,
    Color mutedColor,
    Color border,
  ) {
    return NotionBlockWidget(
      key: ValueKey(block.id),
      block: block,
      index: index,
      isDark: isDark,
      textColor: textColor,
      mutedColor: mutedColor,
      border: border,
      shouldAutoFocus: _autoFocusBlockId == block.id,
      onChanged: (newText) {
        block.text = newText;
        _saveBlocksToNote();
      },
      onToggleTodo: (val) {
        setState(() {
          block.isChecked = val;
        });
        _saveBlocksToNote();
      },
      onDelete: () => _deleteBlockAt(index),
      onInsertBelow: () => _insertBlockAt(index + 1, BlockType.paragraph),
      onEnterPressed: () => _handleEnterOnBlock(index),
      onBackspaceOnEmpty: () => _handleBackspaceOnEmpty(index),
      onTurnInto: (type) => _handleTurnInto(index, type),
      onDuplicate: () => _handleDuplicate(index),
      onRequestSlashMenu: (pos) => _showSlashMenu(context, index, pos),
    );
  }

  Widget _buildEmptyState(bool isDark, Color textColor, Color mutedColor) {
    final vault = widget.vaultService;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: isDark ? AppTheme.darkCardBg : AppTheme.lightSidebarBg,
              shape: BoxShape.circle,
              border: Border.all(color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder),
            ),
            alignment: Alignment.center,
            child: const Text('📝', style: TextStyle(fontSize: 32)),
          ),
          const SizedBox(height: 18),
          Text(
            'Select a note to start reading',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: textColor,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Pick a note from the sidebar or select a local vault folder.',
            style: TextStyle(fontSize: 13.5, color: mutedColor),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ElevatedButton.icon(
                onPressed: () => vault.createNote(),
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Create New Page'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accentBlue,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                ),
              ),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                onPressed: () => vault.pickLocalVaultFolder(),
                icon: const Icon(Icons.folder_open_rounded, size: 16),
                label: const Text('Open Obsidian Folder'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: textColor,
                  side: BorderSide(color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder),
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class NotionBlockWidget extends StatefulWidget {
  final NotionBlock block;
  final int index;
  final bool isDark;
  final Color textColor;
  final Color mutedColor;
  final Color border;
  final ValueChanged<String> onChanged;
  final ValueChanged<bool> onToggleTodo;
  final VoidCallback onDelete;
  final VoidCallback onInsertBelow;
  final Function(Offset pos) onRequestSlashMenu;
  final bool shouldAutoFocus;
  final VoidCallback? onEnterPressed;
  final VoidCallback? onBackspaceOnEmpty;
  final ValueChanged<BlockType>? onTurnInto;
  final VoidCallback? onDuplicate;

  const NotionBlockWidget({
    super.key,
    required this.block,
    required this.index,
    required this.isDark,
    required this.textColor,
    required this.mutedColor,
    required this.border,
    required this.onChanged,
    required this.onToggleTodo,
    required this.onDelete,
    required this.onInsertBelow,
    required this.onRequestSlashMenu,
    this.shouldAutoFocus = false,
    this.onEnterPressed,
    this.onBackspaceOnEmpty,
    this.onTurnInto,
    this.onDuplicate,
  });

  @override
  State<NotionBlockWidget> createState() => _NotionBlockWidgetState();
}

class _NotionBlockWidgetState extends State<NotionBlockWidget> {
  late TextEditingController _textCtrl;
  late FocusNode _focusNode;
  bool _isHovered = false;
  bool _isCopied = false;

  @override
  void initState() {
    super.initState();
    _textCtrl = TextEditingController(text: widget.block.text);
    _focusNode = FocusNode();
    _focusNode.addListener(_onFocusChange);
    if (widget.shouldAutoFocus) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _focusNode.requestFocus();
          _textCtrl.selection = TextSelection.fromPosition(
            TextPosition(offset: _textCtrl.text.length),
          );
        }
      });
    }
  }

  @override
  void didUpdateWidget(covariant NotionBlockWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.block.text != widget.block.text && _textCtrl.text != widget.block.text) {
      _textCtrl.text = widget.block.text;
    }
    if (widget.shouldAutoFocus && !oldWidget.shouldAutoFocus) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _focusNode.requestFocus();
          _textCtrl.selection = TextSelection.fromPosition(
            TextPosition(offset: _textCtrl.text.length),
          );
        }
      });
    }
  }

  void _onFocusChange() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    _textCtrl.dispose();
    super.dispose();
  }

  /// Shows a bottom-sheet with block actions (delete, duplicate, turn into).
  /// Used on mobile / touch where the hover overlay is unavailable.
  void _showBlockOptionsSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(
                width: 36, height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 8),
              ListTile(
                leading: const Icon(Icons.delete_outline, color: AppTheme.accentRed),
                title: const Text('Delete block',
                    style: TextStyle(color: AppTheme.accentRed)),
                onTap: () {
                  Navigator.of(ctx).pop();
                  widget.onDelete();
                },
              ),
              ListTile(
                leading: const Icon(Icons.copy_rounded),
                title: const Text('Duplicate'),
                onTap: () {
                  Navigator.of(ctx).pop();
                  widget.onDuplicate?.call();
                },
              ),
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                child: Text('TURN INTO',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                      color: Colors.grey,
                    )),
              ),
              ...[
                (BlockType.paragraph, 'Text', Icons.text_fields),
                (BlockType.heading1, 'Heading 1', Icons.title),
                (BlockType.heading2, 'Heading 2', Icons.format_size),
                (BlockType.heading3, 'Heading 3', Icons.text_format),
                (BlockType.todo, 'To-do', Icons.check_box_outlined),
                (BlockType.bullet, 'Bullet list', Icons.format_list_bulleted),
                (BlockType.numbered, 'Numbered list', Icons.format_list_numbered),
                (BlockType.callout, 'Callout', Icons.lightbulb_outline),
                (BlockType.quote, 'Quote', Icons.format_quote),
                (BlockType.code, 'Code', Icons.code),
              ].map((r) => ListTile(
                leading: Icon(r.$3),
                title: Text(r.$2),
                dense: true,
                onTap: () {
                  Navigator.of(ctx).pop();
                  widget.onTurnInto?.call(r.$1);
                },
              )),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  Widget _wrapKeyboardInterceptor({
    required Widget child,
    bool isListType = false,
  }) {
    return Focus(
      onKeyEvent: (FocusNode node, KeyEvent event) {
        if (event is KeyDownEvent) {
          if ((event.logicalKey == LogicalKeyboardKey.enter ||
               event.logicalKey == LogicalKeyboardKey.numpadEnter) &&
              !HardwareKeyboard.instance.isShiftPressed) {
            if (isListType) {
              if (_textCtrl.text.trim().isEmpty) {
                widget.onTurnInto?.call(BlockType.paragraph);
              } else {
                widget.onEnterPressed?.call();
              }
              return KeyEventResult.handled;
            } else if (widget.block.type == BlockType.paragraph) {
              widget.onInsertBelow();
              return KeyEventResult.handled;
            }
          } else if (event.logicalKey == LogicalKeyboardKey.backspace) {
            if (_textCtrl.text.isEmpty) {
              widget.onBackspaceOnEmpty?.call();
              return KeyEventResult.handled;
            }
          }
        }
        return KeyEventResult.ignored;
      },
      child: child,
    );
  }

  PopupMenuItem<String> _buildTurnIntoMenuItem(BlockType type, String label, IconData icon) {
    return PopupMenuItem(
      value: 'turn_${type.name}',
      child: Row(
        children: [
          Icon(icon, size: 14, color: widget.mutedColor),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final block = widget.block;

    return GestureDetector(
      onLongPress: _showBlockOptionsSheet,
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2.5),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hover Handle (+ / drag / options / delete)
            SizedBox(
              width: 84,
              height: 28,
              child: (_isHovered || _focusNode.hasFocus)
                  ? FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Slash / Add menu (+)
                        InkWell(
                          onTap: () {
                            final box = context.findRenderObject() as RenderBox?;
                            final pos = box != null ? box.localToGlobal(Offset.zero) : Offset.zero;
                            widget.onRequestSlashMenu(pos + const Offset(32, 28));
                          },
                          borderRadius: BorderRadius.circular(3),
                          child: Padding(
                            padding: const EdgeInsets.all(2),
                            child: Icon(Icons.add, size: 14, color: widget.mutedColor),
                          ),
                        ),
                        // Drag handle only (no longer wraps the menu, so taps reach the popup)
                        ReorderableDragStartListener(
                          index: widget.index,
                          child: MouseRegion(
                            cursor: SystemMouseCursors.grab,
                            child: Padding(
                              padding: const EdgeInsets.all(2),
                              child: Icon(Icons.drag_indicator, size: 14, color: widget.mutedColor),
                            ),
                          ),
                        ),
                        // Block options menu (delete / duplicate / turn into)
                        PopupMenuButton<String>(
                              icon: Icon(Icons.more_horiz, size: 14, color: widget.mutedColor),
                              tooltip: 'Block options',
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              color: widget.isDark ? AppTheme.darkCardBg : Colors.white,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              splashRadius: 12,
                              onSelected: (val) {
                                if (val == 'delete') {
                                  widget.onDelete();
                                } else if (val == 'duplicate') {
                                  widget.onDuplicate?.call();
                                } else if (val.startsWith('turn_')) {
                                  final typeName = val.substring(5);
                                  final match = BlockType.values.firstWhere(
                                    (e) => e.name == typeName,
                                    orElse: () => BlockType.paragraph,
                                  );
                                  widget.onTurnInto?.call(match);
                                }
                              },
                              itemBuilder: (ctx) => [
                                PopupMenuItem(
                                  value: 'delete',
                                  child: Row(
                                    children: const [
                                      Icon(Icons.delete_outline, size: 15, color: AppTheme.accentRed),
                                      SizedBox(width: 8),
                                      Text('Delete block', style: TextStyle(fontSize: 12, color: AppTheme.accentRed)),
                                    ],
                                  ),
                                ),
                                PopupMenuItem(
                                  value: 'duplicate',
                                  child: Row(
                                    children: [
                                      Icon(Icons.copy_rounded, size: 15, color: widget.mutedColor),
                                      const SizedBox(width: 8),
                                      const Text('Duplicate', style: TextStyle(fontSize: 12)),
                                    ],
                                  ),
                                ),
                                const PopupMenuDivider(),
                                const PopupMenuItem(
                                  enabled: false,
                                  child: Text('TURN INTO', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
                                ),
                                _buildTurnIntoMenuItem(BlockType.paragraph, 'Text', Icons.text_fields),
                                _buildTurnIntoMenuItem(BlockType.heading1, 'Heading 1', Icons.title),
                                _buildTurnIntoMenuItem(BlockType.heading2, 'Heading 2', Icons.format_size),
                                _buildTurnIntoMenuItem(BlockType.heading3, 'Heading 3', Icons.text_format),
                                _buildTurnIntoMenuItem(BlockType.todo, 'To-do list', Icons.check_box_outlined),
                                _buildTurnIntoMenuItem(BlockType.bullet, 'Bulleted list', Icons.format_list_bulleted),
                                _buildTurnIntoMenuItem(BlockType.numbered, 'Numbered list', Icons.format_list_numbered),
                                _buildTurnIntoMenuItem(BlockType.callout, 'Callout', Icons.lightbulb_outline),
                                _buildTurnIntoMenuItem(BlockType.quote, 'Quote', Icons.format_quote),
                                _buildTurnIntoMenuItem(BlockType.code, 'Code block', Icons.code),
                              ],
                            ),
                        // Quick Delete Block Button
                        InkWell(
                          onTap: widget.onDelete,
                          borderRadius: BorderRadius.circular(3),
                          child: Padding(
                            padding: const EdgeInsets.all(2),
                            child: Tooltip(
                              message: 'Delete block',
                              child: Icon(Icons.close, size: 13, color: widget.mutedColor.withValues(alpha: 0.6)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                  : const SizedBox.shrink(),
            ),
            const SizedBox(width: 4),

            // Block Content Rendering
            Expanded(
              child: _buildBlockContent(block),
            ),
          ],
        ),
      ),
    ),
    );
  }

  Widget _buildBlockContent(NotionBlock block) {
    switch (block.type) {
      case BlockType.heading1:
        return _buildEditableHeading(fontSize: 26, fontWeight: FontWeight.w700, topPadding: 16);
      case BlockType.heading2:
        return _buildEditableHeading(fontSize: 21, fontWeight: FontWeight.w600, topPadding: 12);
      case BlockType.heading3:
        return _buildEditableHeading(fontSize: 17, fontWeight: FontWeight.w600, topPadding: 8);
      case BlockType.todo:
        return _buildTodoBlock(block);
      case BlockType.bullet:
        return _buildBulletBlock(block);
      case BlockType.numbered:
        return _buildNumberedBlock(block);
      case BlockType.callout:
        return _buildCalloutBlock(block);
      case BlockType.quote:
        return _buildQuoteBlock(block);
      case BlockType.code:
        return _buildCodeBlock(block);
      case BlockType.divider:
        return _buildDividerBlock();
      case BlockType.table:
        return _buildTableBlock(block);
      case BlockType.paragraph:
        return _buildParagraphBlock();
    }
  }

  Widget _buildParagraphBlock() {
    return _wrapKeyboardInterceptor(
      child: TextField(
        controller: _textCtrl,
        focusNode: _focusNode,
        maxLines: null,
        style: GoogleFonts.inter(
          fontSize: 15,
          fontWeight: FontWeight.w400,
          color: widget.textColor,
          height: 1.68,
        ),
        decoration: InputDecoration(
          border: InputBorder.none,
          isDense: true,
          contentPadding: EdgeInsets.zero,
          hintText: _isHovered ? 'Type "/" for commands...' : null,
          hintStyle: TextStyle(
            color: widget.mutedColor.withValues(alpha: 0.35),
            fontSize: 14,
          ),
        ),
        onChanged: (val) {
          if (val == '/') {
            final box = context.findRenderObject() as RenderBox?;
            final pos = box != null ? box.localToGlobal(Offset.zero) : Offset.zero;
            widget.onRequestSlashMenu(pos + const Offset(0, 24));
          }
          widget.onChanged(val);
        },
      ),
    );
  }

  Widget _buildEditableHeading({
    required double fontSize,
    required FontWeight fontWeight,
    required double topPadding,
  }) {
    return _wrapKeyboardInterceptor(
      child: Padding(
        padding: EdgeInsets.only(top: topPadding, bottom: 2),
        child: TextField(
          controller: _textCtrl,
          focusNode: _focusNode,
          maxLines: null,
          style: GoogleFonts.inter(
            fontSize: fontSize,
            fontWeight: fontWeight,
            color: widget.textColor,
            letterSpacing: -0.4,
          ),
          decoration: const InputDecoration(
            border: InputBorder.none,
            isDense: true,
            contentPadding: EdgeInsets.zero,
            hintText: 'Heading...',
          ),
          onChanged: widget.onChanged,
        ),
      ),
    );
  }

  Widget _buildTodoBlock(NotionBlock block) {
    return _wrapKeyboardInterceptor(
      isListType: true,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 3, right: 8),
            child: InkWell(
              onTap: () => widget.onToggleTodo(!block.isChecked),
              borderRadius: BorderRadius.circular(4),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 17,
                height: 17,
                decoration: BoxDecoration(
                  color: block.isChecked ? AppTheme.accentBlue : Colors.transparent,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: block.isChecked ? AppTheme.accentBlue : widget.mutedColor,
                    width: 1.6,
                  ),
                ),
                alignment: Alignment.center,
                child: block.isChecked
                    ? const Icon(Icons.check, size: 13, color: Colors.white)
                    : null,
              ),
            ),
          ),
          Expanded(
            child: TextField(
              controller: _textCtrl,
              focusNode: _focusNode,
              maxLines: null,
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w400,
                color: block.isChecked ? widget.mutedColor : widget.textColor,
                decoration: block.isChecked ? TextDecoration.lineThrough : null,
                height: 1.55,
              ),
              decoration: const InputDecoration(
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
                hintText: 'To-do item...',
              ),
              onChanged: widget.onChanged,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBulletBlock(NotionBlock block) {
    return _wrapKeyboardInterceptor(
      isListType: true,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 8, right: 10, left: 4),
            child: Container(
              width: 5.5,
              height: 5.5,
              decoration: BoxDecoration(
                color: widget.textColor.withValues(alpha: 0.85),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Expanded(
            child: TextField(
              controller: _textCtrl,
              focusNode: _focusNode,
              maxLines: null,
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w400,
                color: widget.textColor,
                height: 1.6,
              ),
              decoration: const InputDecoration(
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
              onChanged: widget.onChanged,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNumberedBlock(NotionBlock block) {
    final idx = block.numberIndex ?? 1;
    return _wrapKeyboardInterceptor(
      isListType: true,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1, right: 8),
            child: Text(
              '$idx.',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: widget.mutedColor,
              ),
            ),
          ),
          Expanded(
            child: TextField(
              controller: _textCtrl,
              focusNode: _focusNode,
              maxLines: null,
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w400,
                color: widget.textColor,
                height: 1.6,
              ),
              decoration: const InputDecoration(
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
              onChanged: widget.onChanged,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalloutBlock(NotionBlock block) {
    final style = AppTheme.calloutColors[block.calloutColor ?? 'yellow'] ??
        AppTheme.calloutColors['yellow']!;

    return _wrapKeyboardInterceptor(
      child: Container(
        decoration: BoxDecoration(
          color: style.bg(widget.isDark),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: style.border(widget.isDark), width: 1),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              block.calloutIcon ?? '💡',
              style: const TextStyle(fontSize: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _textCtrl,
                focusNode: _focusNode,
                maxLines: null,
                style: GoogleFonts.inter(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w400,
                  color: widget.textColor,
                  height: 1.55,
                ),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                  hintText: 'Callout text...',
                ),
                onChanged: widget.onChanged,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuoteBlock(NotionBlock block) {
    return _wrapKeyboardInterceptor(
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            left: BorderSide(
              color: widget.textColor.withValues(alpha: 0.85),
              width: 3.5,
            ),
          ),
        ),
        padding: const EdgeInsets.only(left: 14, top: 2, bottom: 2),
        child: TextField(
          controller: _textCtrl,
          focusNode: _focusNode,
          maxLines: null,
          style: GoogleFonts.inter(
            fontSize: 15.5,
            fontStyle: FontStyle.italic,
            color: widget.textColor,
            height: 1.6,
          ),
          decoration: const InputDecoration(
            border: InputBorder.none,
            isDense: true,
            contentPadding: EdgeInsets.zero,
            hintText: 'Empty quote...',
          ),
          onChanged: widget.onChanged,
        ),
      ),
    );
  }

  Widget _buildCodeBlock(NotionBlock block) {
    return Container(
      decoration: BoxDecoration(
        color: widget.isDark ? AppTheme.darkCardBg : const Color(0xFFF7F6F3),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: widget.border),
      ),
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: (widget.isDark ? AppTheme.darkBorder : AppTheme.lightBorder).withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  block.codeLanguage?.toUpperCase() ?? 'CODE',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: widget.mutedColor,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const Spacer(),
              InkWell(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: _textCtrl.text));
                  setState(() => _isCopied = true);
                  Future.delayed(const Duration(seconds: 2), () {
                    if (mounted) setState(() => _isCopied = false);
                  });
                },
                borderRadius: BorderRadius.circular(4),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  child: Row(
                    children: [
                      Icon(
                        _isCopied ? Icons.check : Icons.copy_rounded,
                        size: 13,
                        color: _isCopied ? AppTheme.accentGreen : widget.mutedColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _isCopied ? 'Copied!' : 'Copy',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: _isCopied ? AppTheme.accentGreen : widget.mutedColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _textCtrl,
            maxLines: null,
            style: GoogleFonts.jetBrainsMono(
              fontSize: 13,
              color: widget.textColor,
              height: 1.55,
            ),
            decoration: const InputDecoration(
              border: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.zero,
              hintText: '// Paste or write code here',
            ),
            onChanged: widget.onChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildDividerBlock() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Divider(
        height: 1,
        color: widget.border.withValues(alpha: 0.7),
      ),
    );
  }

  Widget _buildTableBlock(NotionBlock block) {
    final rows = block.tableData ?? [
      ['Column 1', 'Column 2'],
      ['Value 1', 'Value 2'],
    ];

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: widget.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Table(
        border: TableBorder.all(color: widget.border, width: 1),
        children: rows.asMap().entries.map((entry) {
          final rIdx = entry.key;
          final rowCells = entry.value;
          final isHeader = rIdx == 0;

          return TableRow(
            decoration: BoxDecoration(
              color: isHeader
                  ? (widget.isDark ? AppTheme.darkCardBg : AppTheme.lightSidebarBg)
                  : Colors.transparent,
            ),
            children: rowCells.asMap().entries.map((cEntry) {
              final cIdx = cEntry.key;
              final cellText = cEntry.value;

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                child: TextFormField(
                  initialValue: cellText,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: isHeader ? FontWeight.w600 : FontWeight.w400,
                    color: widget.textColor,
                  ),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                  onChanged: (newVal) {
                    rows[rIdx][cIdx] = newVal;
                    block.tableData = rows;
                    widget.onChanged('');
                  },
                ),
              );
            }).toList(),
          );
        }).toList(),
      ),
    );
  }
}
