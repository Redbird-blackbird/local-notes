import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'services/vault_service.dart';
import 'theme/app_theme.dart';
import 'ui/editor/notion_editor_view.dart';
import 'ui/modals/search_modal.dart';
import 'ui/sidebar/sidebar_view.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final vaultService = VaultService();
  await vaultService.initialize();
  runApp(LocalNotesApp(vaultService: vaultService));
}

class LocalNotesApp extends StatelessWidget {
  final VaultService vaultService;

  const LocalNotesApp({super.key, required this.vaultService});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: vaultService,
      builder: (context, _) {
        return MaterialApp(
          title: 'Local Notes',
          debugShowCheckedModeBanner: false,
          themeMode: vaultService.isDarkMode ? ThemeMode.dark : ThemeMode.light,
          theme: AppTheme.lightTheme(),
          darkTheme: AppTheme.darkTheme(),
          home: LocalNotesMainScreen(vaultService: vaultService),
        );
      },
    );
  }
}

class LocalNotesMainScreen extends StatefulWidget {
  final VaultService vaultService;

  const LocalNotesMainScreen({super.key, required this.vaultService});

  @override
  State<LocalNotesMainScreen> createState() => _LocalNotesMainScreenState();
}

class _LocalNotesMainScreenState extends State<LocalNotesMainScreen> {
  final FocusNode _keyboardFocusNode = FocusNode();

  @override
  void dispose() {
    _keyboardFocusNode.dispose();
    super.dispose();
  }

  void _openSearch() {
    showDialog(
      context: context,
      builder: (ctx) => SearchModal(vaultService: widget.vaultService),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vault = widget.vaultService;
    final screenWidth = MediaQuery.of(context).size.width;
    final isCompact = screenWidth < 768;

    return Focus(
      focusNode: _keyboardFocusNode,
      autofocus: true,
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent) {
          // Ctrl+K or Cmd+K
          final isControlOrCmd = HardwareKeyboard.instance.isControlPressed ||
              HardwareKeyboard.instance.isMetaPressed;
          if (isControlOrCmd && event.logicalKey == LogicalKeyboardKey.keyK) {
            _openSearch();
            return KeyEventResult.handled;
          }
          // Ctrl+S or Cmd+S
          if (isControlOrCmd && event.logicalKey == LogicalKeyboardKey.keyS) {
            if (vault.activeNote != null) {
              vault.updateActiveNote();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Note saved to vault'),
                  duration: Duration(milliseconds: 900),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
            return KeyEventResult.handled;
          }
        }
        return KeyEventResult.ignored;
      },
      child: Scaffold(
        drawer: isCompact ? Drawer(child: SidebarView(vaultService: vault)) : null,
        body: SafeArea(
          child: Row(
            children: [
              // Permanent Sidebar for larger screens
              if (!isCompact && vault.isSidebarOpen)
                SidebarView(vaultService: vault),

              // Main Notion-style Note Editor Area
              Expanded(
                child: NotionEditorView(vaultService: vault),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
