import 'package:flutter/material.dart';
import '../../models/note_file.dart';
import '../../services/vault_service.dart';
import '../../theme/app_theme.dart';

class MoveNoteDialog extends StatefulWidget {
  final NoteFile note;
  final VaultService vaultService;

  const MoveNoteDialog({
    super.key,
    required this.note,
    required this.vaultService,
  });

  @override
  State<MoveNoteDialog> createState() => _MoveNoteDialogState();
}

class _MoveNoteDialogState extends State<MoveNoteDialog> {
  late TextEditingController _searchCtrl;
  late TextEditingController _newFolderCtrl;
  bool _isCreatingFolder = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _searchCtrl = TextEditingController();
    _newFolderCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _newFolderCtrl.dispose();
    super.dispose();
  }

  Future<void> _moveTo(String folder) async {
    if (folder == widget.note.folder) {
      Navigator.of(context).pop();
      return;
    }

    final messenger = ScaffoldMessenger.of(context);
    final targetFolder = folder;
    await widget.vaultService.moveNoteToFolder(widget.note, targetFolder);

    if (mounted) {
      Navigator.of(context).pop(true);
      messenger.showSnackBar(
        SnackBar(
          content: Text('Moved "${widget.note.title}" to $targetFolder'),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _createAndMove() async {
    final name = _newFolderCtrl.text.trim();
    if (name.isEmpty) return;

    final err = await widget.vaultService.createFolder(name);
    if (err != null) {
      setState(() => _errorMessage = err);
      return;
    }

    await _moveTo(name);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppTheme.darkCardBg : Colors.white;
    final textColor = isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary;
    final mutedColor = isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary;
    final border = isDark ? AppTheme.darkBorder : AppTheme.lightBorder;
    final hoverBg = isDark ? AppTheme.darkSidebarHover : AppTheme.lightSidebarHover;

    final folders = widget.vaultService.allFolders;
    final filterQuery = _searchCtrl.text.trim().toLowerCase();
    final filteredFolders = filterQuery.isEmpty
        ? folders
        : folders.where((f) => f.toLowerCase().contains(filterQuery)).toList();

    final notesByFolder = widget.vaultService.notesByFolder;

    return Dialog(
      backgroundColor: bg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: border, width: 1),
      ),
      elevation: 16,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420, maxHeight: 520),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: AppTheme.accentBlue.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.drive_file_move_outlined, size: 18, color: AppTheme.accentBlue),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Move to folder',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: textColor,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Currently in: ${widget.note.folder}',
                          style: TextStyle(fontSize: 12, color: mutedColor),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, size: 18, color: mutedColor),
                    onPressed: () => Navigator.of(context).pop(),
                    splashRadius: 16,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Search Filter Bar
              Container(
                decoration: BoxDecoration(
                  color: (isDark ? AppTheme.darkBg : AppTheme.lightSidebarBg).withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: border),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                child: Row(
                  children: [
                    Icon(Icons.search, size: 16, color: mutedColor),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _searchCtrl,
                        style: TextStyle(fontSize: 13, color: textColor),
                        decoration: InputDecoration(
                          hintText: 'Search or filter folders...',
                          hintStyle: TextStyle(fontSize: 13, color: mutedColor.withValues(alpha: 0.6)),
                          border: InputBorder.none,
                          isDense: true,
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // Folder List
              Flexible(
                child: filteredFolders.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.symmetric(vertical: 32),
                        child: Center(
                          child: Text(
                            'No matching folders found',
                            style: TextStyle(fontSize: 13, color: mutedColor),
                          ),
                        ),
                      )
                    : ListView.separated(
                        shrinkWrap: true,
                        itemCount: filteredFolders.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 2),
                        itemBuilder: (context, index) {
                          final folder = filteredFolders[index];
                          final isCurrent = folder == widget.note.folder;
                          final count = notesByFolder[folder]?.length ?? 0;

                          return InkWell(
                            onTap: () => _moveTo(folder),
                            borderRadius: BorderRadius.circular(6),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              decoration: BoxDecoration(
                                color: isCurrent ? hoverBg : Colors.transparent,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    folder == 'Root' ? Icons.folder_special_outlined : Icons.folder_outlined,
                                    size: 17,
                                    color: isCurrent ? AppTheme.accentBlue : mutedColor,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      folder,
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: isCurrent ? FontWeight.w600 : FontWeight.w400,
                                        color: isCurrent ? textColor : textColor.withValues(alpha: 0.9),
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: (isDark ? AppTheme.darkBorder : AppTheme.lightBorder).withValues(alpha: 0.5),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      '$count',
                                      style: TextStyle(fontSize: 10.5, color: mutedColor, fontWeight: FontWeight.w500),
                                    ),
                                  ),
                                  if (isCurrent) ...[
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: AppTheme.accentBlue.withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: const Text(
                                        'Current',
                                        style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: AppTheme.accentBlue),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),

              const SizedBox(height: 12),
              Divider(height: 1, color: border),
              const SizedBox(height: 12),

              // Create New Folder & Move section
              if (!_isCreatingFolder)
                InkWell(
                  onTap: () => setState(() => _isCreatingFolder = true),
                  borderRadius: BorderRadius.circular(6),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    child: Row(
                      children: [
                        const Icon(Icons.add_circle_outline, size: 16, color: AppTheme.accentBlue),
                        const SizedBox(width: 8),
                        Text(
                          'Create new folder and move here...',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.accentBlue,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _newFolderCtrl,
                            autofocus: true,
                            style: TextStyle(fontSize: 13, color: textColor),
                            decoration: InputDecoration(
                              hintText: 'Enter new folder name...',
                              hintStyle: TextStyle(fontSize: 13, color: mutedColor.withValues(alpha: 0.6)),
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(6),
                                borderSide: BorderSide(color: border),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(6),
                                borderSide: const BorderSide(color: AppTheme.accentBlue),
                              ),
                            ),
                            onSubmitted: (_) => _createAndMove(),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: _createAndMove,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.accentBlue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                          ),
                          child: const Text('Move', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                        ),
                        const SizedBox(width: 4),
                        IconButton(
                          icon: Icon(Icons.close, size: 16, color: mutedColor),
                          onPressed: () => setState(() {
                            _isCreatingFolder = false;
                            _errorMessage = null;
                            _newFolderCtrl.clear();
                          }),
                        ),
                      ],
                    ),
                    if (_errorMessage != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 6, left: 4),
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(fontSize: 11.5, color: AppTheme.accentRed),
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
}
