# Local Notes 🗂️✨

> **A minimalist Notion-style knowledge workspace powered by your local Markdown files.**
> Designed for Obsidian users who love pure local `.md` files but want the clean, distraction-free aesthetic and interactive blocks of Notion.

---

## 🌟 Highlights & Key Features

### 🎨 Art-Directed Notion Aesthetics
- **Zero Markdown Clutter**: No raw hashes (`#`), asterisks (`**`), or brackets in your face while reading or writing.
- **Inter Typography**: Refined letter-spacing, generous line-height (1.68), and balanced visual hierarchy for effortless reading.
- **Notion Color System**: Authentic paper-warm light mode (`#F7F6F3` sidebar, `#37352F` charcoal text) and dark mode (`#191919` canvas, `#202020` sidebar).
- **Iconic Cover & Icon System**: Notion-style overlapping page icons (54px), curated minimal wallpapers, and gradients.
- **Interactive Checklists**: Clickable checkboxes that strike through text smoothly.
- **Pastel Callout Boxes**: Accent icon cards with customizable soft hues (yellow, blue, green, pink, orange, purple).
- **Code Snippets**: Monospace font card with language tag and instant "Copy code" feedback.
- **Blockquotes & Tables**: Clean vertical accent border quotes and database-style tables.

### 📂 Obsidian & Local Vault Interoperability
- **Pure Local Files**: All pages are stored as standard `.md` files. You can open the exact same vault folder in Obsidian, VS Code, or Typora with 100% compatibility.
- **Real Local Disk Sync**: Select any directory on your computer using the **"Open Local Folder"** button (powered by the W3C File System Access API). Edits are saved directly back to your local files on disk.
- **YAML Frontmatter Preservation**: Preserves `--- title, icon, cover, tags, favorite ---` seamlessly without breaking Obsidian plugins.
- **Curated Demo Vault**: Comes out of the box with sample notes on Architecture, Product Roadmap, Reading List, and Daily Reflections.

### ⚡ Notion Power Features
- **Slash Commands (`/`)**: Type `/` anywhere to summon the floating command menu (Headings, Todos, Bullet lists, Quotes, Callouts, Code blocks, Tables, Dividers).
- **Quick Switcher / Search (`Ctrl + K` / `Cmd + K`)**: Instant fuzzy search across titles, markdown content, and tags with snippet matching and keyboard navigation.
- **Dual Mode**: Seamlessly toggle between **⚡ Notion Mode** (WYSIWYG blocks) and **📄 Raw .md Mode** (direct markdown text editing).
- **Responsive & Cross-Platform**: Responsive sidebar (drawer on mobile, permanent on desktop) with clean architecture ready for Android or desktop builds.

---

## 🚀 Running the App

### 1. Run in Browser (Web)
```bash
flutter run -d chrome
```
or to build the web distribution:
```bash
flutter build web
```

### 2. Run on Android
```bash
flutter run -d android
```

### 3. Run on Windows Desktop
```bash
flutter run -d windows
```

---

## 📁 Project Architecture

```
lib/
├── main.dart                          # Application entrypoint & global shortcuts (Ctrl+K, Ctrl+S)
├── models/
│   ├── block_model.dart               # Notion block definitions & Markdown bi-directional parser
│   └── note_file.dart                 # Note entity, YAML frontmatter extractor & serializer
├── services/
│   ├── vault_service.dart             # Vault state, reactive operations, local storage persistence
│   └── web_fs/                        # Platform-independent filesystem abstraction
│       ├── web_fs_interface.dart      # Conditional export for Web vs Native (Android/Desktop)
│       ├── web_fs_stub.dart           # Native/Android fallback
│       └── web_fs_web.dart            # Modern W3C File System Access API & localStorage bridge
├── theme/
│   └── app_theme.dart                 # Art-directed Notion light & dark design tokens, typography
└── ui/
    ├── editor/
    │   ├── notion_editor_view.dart    # Signature Notion page header, overlapping icon, block canvas
    │   └── slash_command_menu.dart    # Floating '/' command palette
    ├── modals/
    │   ├── cover_picker_dialog.dart   # Curated Notion gradients & wallpapers
    │   ├── icon_picker_dialog.dart    # Categorized emoji & icon picker
    │   └── search_modal.dart          # Glassmorphic fuzzy quick switcher (Ctrl+K)
    └── sidebar/
        └── sidebar_view.dart          # Workspace header, favorites, folders tree & sync indicator
```
