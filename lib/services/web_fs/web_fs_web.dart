import 'dart:async';
import 'dart:convert';
import 'dart:html' as html;
import 'dart:js' show context;
import 'dart:js_interop';

import 'package:flutter/foundation.dart';

/// Web implementation using modern File System Access API & localStorage
class WebFsHelper {
  static bool get isSupported {
    final fs = context['localNotesFS'];
    if (fs == null) return false;

    try {
      return fs.callMethod('isSupported') == true;
    } on Object catch (error, stackTrace) {
      debugPrint('Could not detect File System Access API support: $error');
      debugPrintStack(stackTrace: stackTrace);
      return false;
    }
  }

  static Future<String?> pickDirectory() {
    final completer = Completer<String?>();
    final fs = context['localNotesFS'];
    if (fs == null) {
      completer.complete(null);
      return completer.future;
    }

    try {
      fs.callMethod('pickDirectory', [
        ((JSAny? result) {
          if (completer.isCompleted) return;
          try {
            completer.complete(result?.toString());
          } on Object catch (error, stackTrace) {
            debugPrint('Could not process directory picker result: $error');
            debugPrintStack(stackTrace: stackTrace);
            completer.complete(null);
          }
        }).toJS
      ]);
    } on Object catch (error, stackTrace) {
      debugPrint('Could not open directory picker: $error');
      debugPrintStack(stackTrace: stackTrace);
      completer.complete(null);
    }

    return completer.future;
  }

  static Future<bool> saveFile(String path, String content) {
    final completer = Completer<bool>();
    if (!_isValidPath(path)) return Future.value(false);
    final fs = context['localNotesFS'];
    if (fs == null) {
      completer.complete(false);
      return completer.future;
    }

    try {
      fs.callMethod('saveFile', [
        path,
        content,
        ((JSAny? result) {
          if (completer.isCompleted) return;
          if (result == null) {
            completer.complete(false);
            return;
          }
          try {
            completer.complete(_isSuccessfulResult(result));
          } on Object catch (error, stackTrace) {
            debugPrint('Could not process save result: $error');
            debugPrintStack(stackTrace: stackTrace);
            completer.complete(false);
          }
        }).toJS
      ]);
    } on Object catch (error, stackTrace) {
      debugPrint('Could not save file "$path": $error');
      debugPrintStack(stackTrace: stackTrace);
      completer.complete(false);
    }

    return completer.future;
  }

  static Future<bool> deleteFile(String path) {
    final completer = Completer<bool>();
    if (!_isValidPath(path)) return Future.value(false);
    final fs = context['localNotesFS'];
    if (fs == null) {
      completer.complete(false);
      return completer.future;
    }

    try {
      fs.callMethod('deleteFile', [
        path,
        ((JSAny? result) {
          if (completer.isCompleted) return;
          if (result == null) {
            completer.complete(false);
            return;
          }
          try {
            completer.complete(_isSuccessfulResult(result));
          } on Object catch (error, stackTrace) {
            debugPrint('Could not process delete result: $error');
            debugPrintStack(stackTrace: stackTrace);
            completer.complete(false);
          }
        }).toJS
      ]);
    } on Object catch (error, stackTrace) {
      debugPrint('Could not delete file "$path": $error');
      debugPrintStack(stackTrace: stackTrace);
      completer.complete(false);
    }

    return completer.future;
  }

  static void downloadFile(String filename, String content) {
    final fs = context['localNotesFS'];
    if (fs == null || filename.isEmpty) return;
    try {
      fs.callMethod('downloadFile', [filename, content]);
    } on Object catch (error, stackTrace) {
      debugPrint('Could not download file "$filename": $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  static String? getStorage(String key) {
    try {
      return html.window.localStorage[key];
    } on Object catch (error, stackTrace) {
      debugPrint('Could not read local storage key "$key": $error');
      debugPrintStack(stackTrace: stackTrace);
      return null;
    }
  }

  static void setStorage(String key, String value) {
    try {
      html.window.localStorage[key] = value;
    } on Object catch (error, stackTrace) {
      debugPrint('Could not write local storage key "$key": $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  static bool _isValidPath(String path) {
    if (path.isEmpty || path.startsWith('/') || path.contains('\\')) {
      debugPrint('Rejected invalid filesystem path: "$path"');
      return false;
    }
    final parts = path.split('/');
    return parts.every((part) => part.isNotEmpty && part != '.' && part != '..');
  }

  static bool _isSuccessfulResult(Object result) {
    final decoded = jsonDecode(result.toString());
    if (decoded is! Map<String, dynamic>) return false;
    return decoded['success'] == true;
  }
}
