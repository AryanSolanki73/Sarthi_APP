import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

/// Helper service to save and retrieve credentials locally using a JSON file.
class CredentialStorage {
  static const String _fileName = 'credentials.json';

  /// Returns the credentials file object from local app storage.
  static Future<File?> _getFile() async {
    try {
      if (Platform.environment.containsKey('FLUTTER_TEST')) {
        return null;
      }
      final directory = await getApplicationDocumentsDirectory();
      return File('${directory.path}/$_fileName');
    } catch (_) {
      return null;
    }
  }

  /// Saves the email and password to the local JSON file.
  static Future<void> saveCredentials({
    required String email,
    required String password,
  }) async {
    try {
      final file = await _getFile();
      if (file == null) return;
      final data = jsonEncode({
        'email': email,
        'password': password,
      });
      await file.writeAsString(data, flush: true);
    } catch (_) {
      // In case of permission or IO failure, continue without crashing.
    }
  }

  /// Reads and returns saved credentials from the local JSON file.
  static Future<Map<String, String>?> loadCredentials() async {
    try {
      final file = await _getFile();
      if (file == null || !await file.exists()) {
        return null;
      }

      final content = await file.readAsString();
      if (content.trim().isEmpty) {
        return null;
      }

      final dynamic decoded = jsonDecode(content);
      if (decoded is Map<String, dynamic>) {
        return {
          'email': decoded['email'] as String? ?? '',
          'password': decoded['password'] as String? ?? '',
        };
      }
      return null;
    } catch (e) {
      // If the file is unreadable or malformed, return null.
      return null;
    }
  }

  /// Deletes the credentials file from local storage.
  static Future<void> clearCredentials() async {
    try {
      final file = await _getFile();
      if (file != null && await file.exists()) {
        await file.delete();
      }
    } catch (_) {}
  }
}

