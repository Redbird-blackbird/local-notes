import 'package:flutter/material.dart';
import '../../models/note_file.dart';
import '../../services/vault_service.dart';
import '../../theme/app_theme.dart';
import '../modals/search_modal.dart';

class SidebarView extends StatefulWidget {
  final VaultService vaultService;

  const SidebarView({
    super.key,
    required this.vaultService,
  });

  @override
  State<SidebarView> createState() => _SidebarViewState();
}

class _SidebarViewState extends State<SidebarView> {
  final Set<String> _collapsedFolders = {};
  bool _favoritesCollapsed = false;

  void _toggleFolder(String folder) {
    setState(() {
      if (_collapsedFolders.contains(folder)) {
        _collapsedFolders.remove(folder);
      } else {
        _collapsedFolders.add(folder);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sidebarBg = isDark ? AppTheme.darkSidebarBg : AppTheme.lightSidebarBg;
    final border = isDark ? AppTheme.darkBorder : AppTheme.lightBorder;
    final textColor = isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary;
    final mutedColor = isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary;
    final hoverBg = isDark ? AppTheme.darkSidebarHover : AppTheme.lightSidebarHover;
    final activeBg = isDark ? AppTheme.darkSidebarActive : AppTheme.lightSidebarActive;

    final vault = widget.vaultService;
    final foldersMap = vault.notesByFolder;
    final favorites = vault.favoriteNotes;

    return Container(
      width: 260,
      decoration: BoxDecoration(
        color: sidebarBg,
        border: Border(right: BorderSide(color: border, width: 1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Workspace / Vault Header
          Container(
            padding: const EdgeInsets.fromLTRB(14, 14, 10, 10),
            child: Row(
              children: [
                // Workspace Avatar
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: AppTheme.accentBlue.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: AppTheme.accentBlue.withValues(alpha: 0.3)),
                  ),
                  alignment: Alignment.center,
                  child: const Text('🗂️', style: TextStyle(fontSize: 14)),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    vault.vaultName,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                // Vault Menu Dropdown
                PopupMenuButton<String>(
                  icon: Icon(Icons.keyboard_arrow_down, size: 18, color: mutedColor),
                  tooltip: 'Vault options',
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  color: isDark ? AppTheme.darkCardBg : Colors.white,
                  offset: const Offset(0, 32),
                  onSelected: (val) async {
                    final messenger = ScaffoldMessenger.of(context);
                    if (val == 'open_folder') {
                      final success = await vault.pickLocalVaultFolder();
                      messenger.showSnackBar(
                        SnackBar(
                          content: Text(
                            success
                                ? 'Loaded local Obsidian vault "${vault.vaultName}"'
                                : 'Folder selection cancelled or not supported',
                          ),
                          behavior: SnackBarBehavior.floating,
                          duration: const Duration(seconds: 3),
                        ),
                      );
                    } else if (val == 'reset_sample') {
                      await vault.loadSampleVault();
                      messenger.showSnackBar(
                        const SnackBar(
                          content: Text('Curated sample vault restored'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    } else if (val == 'export_note') {
                      if (vault.activeNote != null) {
                        vault.exportNoteAsMarkdown(vault.activeNote!);
                      }
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'open_folder',
                      child: Row(
                        children: [
                          Icon(Icons.folder_open_rounded, size: 16, color: AppTheme.accentBlue),
                          const SizedBox(width: 10),
                          const Text('Open Local Folder (Obsidian)...', style: TextStyle(fontSize: 12.5)),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'reset_sample',
                      child: Row(
                        children: [
                          Icon(Icons.restart_alt_rounded, size: 16, color: mutedColor),
                          const SizedBox(width: 10),
                          const Text('Reset to Sample Vault', style: TextStyle(fontSize: 12.5)),
                        ],
                      ),
                    ),
                    if (vault.activeNote != null)
                      PopupMenuItem(
                        value: 'export_note',
                        child: Row(
                          children: [
                            Icon(Icons.download_rounded, size: 16, color: mutedColor),
                            const SizedBox(width: 10),
                            const Text('Export Active Note (.md)', style: TextStyle(fontSize: 12.5)),
                          ],
                        ),
                      ),
                  ],
                ),
                IconButton(
                  icon: Icon(Icons.keyboard_double_arrow_left, size: 18, color: mutedColor),
                  tooltip: 'Close sidebar',
                  onPressed: () => vault.toggleSidebar(),
                  splashRadius: 16,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),

          // Quick Action items: Search & New Page
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            child: Column(
              children: [
                _buildSidebarActionItem(
                  icon: Icons.search,
                  label: 'Search',
                  shortcut: 'Ctrl K',
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (ctx) => SearchModal(vaultService: vault),
                    );
                  },
                  isDark: isDark,
                  textColor: textColor,
                  mutedColor: mutedColor,
                  hoverBg: hoverBg,
                ),
                const SizedBox(height: 2),
                _buildSidebarActionItem(
                  icon: Icons.add_circle_outline,
                  label: 'New page',
                  onTap: () async {
                    await vault.createNote();
                  },
                  isDark: isDark,
                  textColor: textColor,
                  mutedColor: mutedColor,
                  hoverBg: hoverBg,
                ),
              ],
            ),
          ),

          const SizedBox(height: 6),
          Divider(height: 1, color: border.withValues(alpha: 0.6)),

          // Scrollable Pages & Folders tree
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                // Favorites section if any
                if (favorites.isNotEmpty) ...[
                  _buildSectionHeader(
                    title: 'FAVORITES',
                    isCollapsed: _favoritesCollapsed,
                    onToggle: () => setState(() => _favoritesCollapsed = !_favoritesCollapsed),
                    mutedColor: mutedColor,
                  ),
                  if (!_favoritesCollapsed)
                    ...favorites.map((note) => _buildNoteItem(
                          note: note,
                          isActive: vault.activeNote?.id == note.id,
                          onTap: () => vault.selectNote(note),
                          isDark: isDark,
                          textColor: textColor,
                          mutedColor: mutedColor,
                          hoverBg: hoverBg,
                          activeBg: activeBg,
                          depth: 1,
                        )),
                  const SizedBox(height: 10),
                ],

                // Folders & Notes
                _buildSectionHeader(
                  title: 'WORKSPACE',
                  mutedColor: mutedColor,
                ),

                ...foldersMap.entries.map((entry) {
                  final folderName = entry.key;
                  final notesInFolder = entry.value;
                  final isCollapsed = _collapsedFolders.contains(folderName);

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Folder Header
                      InkWell(
                        onTap: () => _toggleFolder(folderName),
                        borderRadius: BorderRadius.circular(4),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                          child: Row(
                            children: [
                              Icon(
                                isCollapsed ? Icons.chevron_right : Icons.keyboard_arrow_down,
                                size: 16,
                                color: mutedColor,
                              ),
                              const SizedBox(width: 4),
                              Icon(
                                isCollapsed ? Icons.folder_outlined : Icons.folder_open_outlined,
                                size: 16,
                                color: mutedColor,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  folderName,
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w500,
                                    color: textColor,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              // Quick Add Page to this folder button
                              IconButton(
                                icon: Icon(Icons.add, size: 15, color: mutedColor),
                                tooltip: 'Add page inside $folderName',
                                onPressed: () => vault.createNote(folder: folderName),
                                splashRadius: 12,
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Notes in Folder
                      if (!isCollapsed)
                        ...notesInFolder.map((note) => _buildNoteItem(
                              note: note,
                              isActive: vault.activeNote?.id == note.id,
                              onTap: () => vault.selectNote(note),
                              isDark: isDark,
                              textColor: textColor,
                              mutedColor: mutedColor,
                              hoverBg: hoverBg,
                              activeBg: activeBg,
                              depth: 1,
                            )),
                    ],
                  );
                }),
              ],
            ),
          ),

          // Bottom Bar: Local Sync Indicator & Theme Switch
          Divider(height: 1, color: border.withValues(alpha: 0.6)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Disk Connection Badge
                InkWell(
                  onTap: () => vault.pickLocalVaultFolder(),
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    decoration: BoxDecoration(
                      color: vault.isNativeFileSystem
                          ? AppTheme.accentGreen.withValues(alpha: 0.12)
                          : (isDark ? AppTheme.darkBorder : AppTheme.lightBorder).withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: vault.isNativeFileSystem
                            ? AppTheme.accentGreen.withValues(alpha: 0.3)
                            : Colors.transparent,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          vault.isNativeFileSystem ? Icons.check_circle_rounded : Icons.folder_open_rounded,
                          size: 14,
                          color: vault.isNativeFileSystem ? AppTheme.accentGreen : mutedColor,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            vault.isNativeFileSystem ? 'Syncing with Local Disk' : 'Open Local Folder...',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: vault.isNativeFileSystem ? AppTheme.accentGreen : mutedColor,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                // Theme Switcher & Add Page Quick Row
                Row(
                  children: [
                    InkWell(
                      onTap: () => vault.toggleTheme(),
                      borderRadius: BorderRadius.circular(4),
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: Row(
                          children: [
                            Icon(
                              isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
                              size: 16,
                              color: mutedColor,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              isDark ? 'Light mode' : 'Dark mode',
                              style: TextStyle(fontSize: 11.5, color: mutedColor),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${vault.notes.length} pages',
                      style: TextStyle(fontSize: 11, color: mutedColor.withValues(alpha: 0.7)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader({
    required String title,
    bool? isCollapsed,
    VoidCallback? onToggle,
    required Color mutedColor,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 12, 4),
      child: Row(
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
              color: mutedColor.withValues(alpha: 0.8),
            ),
          ),
          const Spacer(),
          if (onToggle != null && isCollapsed != null)
            InkWell(
              onTap: onToggle,
              child: Icon(
                isCollapsed ? Icons.keyboard_arrow_right : Icons.keyboard_arrow_down,
                size: 14,
                color: mutedColor,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSidebarActionItem({
    required IconData icon,
    required String label,
    String? shortcut,
    required VoidCallback onTap,
    required bool isDark,
    required Color textColor,
    required Color mutedColor,
    required Color hoverBg,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(5),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Row(
          children: [
            Icon(icon, size: 17, color: mutedColor),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: textColor,
                ),
              ),
            ),
            if (shortcut != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                decoration: BoxDecoration(
                  color: (isDark ? AppTheme.darkBorder : AppTheme.lightBorder).withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  shortcut,
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w600,
                    color: mutedColor,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoteItem({
    required NoteFile note,
    required bool isActive,
    required VoidCallback onTap,
    required bool isDark,
    required Color textColor,
    required Color mutedColor,
    required Color hoverBg,
    required Color activeBg,
    int depth = 0,
  }) {
    return Padding(
      padding: EdgeInsets.fromLTRB(10 + (depth * 10), 1, 10, 1),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(5),
        child: Container(
          decoration: BoxDecoration(
            color: isActive ? activeBg : Colors.transparent,
            borderRadius: BorderRadius.circular(5),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          child: Row(
            children: [
              Text(
                note.icon,
                style: const TextStyle(fontSize: 15),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  note.title.isEmpty ? 'Untitled' : note.title,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                    color: textColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (note.isFavorite)
                const Icon(Icons.star_rounded, size: 13, color: AppTheme.accentOrange)
              else
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_horiz, size: 15, color: mutedColor.withValues(alpha: 0.6)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                  color: isDark ? AppTheme.darkCardBg : Colors.white,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  splashRadius: 12,
                  onSelected: (val) {
                    if (val == 'favorite') {
                      widget.vaultService.toggleFavorite(note);
                    } else if (val == 'export') {
                      widget.vaultService.exportNoteAsMarkdown(note);
                    } else if (val == 'delete') {
                      widget.vaultService.deleteNote(note);
                    }
                  },
                  itemBuilder: (ctx) => [
                    PopupMenuItem(
                      value: 'favorite',
                      child: Text(note.isFavorite ? 'Remove from favorites' : 'Add to favorites', style: const TextStyle(fontSize: 12)),
                    ),
                    const PopupMenuItem(
                      value: 'export',
                      child: Text('Export Markdown (.md)', style: TextStyle(fontSize: 12)),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Text('Delete page', style: TextStyle(fontSize: 12, color: AppTheme.accentRed)),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
