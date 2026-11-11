/// Stub implementation for non-web platforms (Android, iOS, Desktop)
class WebFsHelper {
  static bool get isSupported => false;

  static Future<String?> pickDirectory() async => null;

  static Future<bool> saveFile(String path, String content) async => false;

  static Future<bool> deleteFile(String path) async => false;

  static void downloadFile(String filename, String content) {}

  static String? getStorage(String key) => null;

  static void setStorage(String key, String value) {}
}
