import 'package:flutter/foundation.dart';

/// Configuration for backend API connectivity across platforms
abstract final class ApiConfig {
  /// Optional environment override via `--dart-define=API_BASE_URL=...`
  static const String _envBaseUrl = String.fromEnvironment('API_BASE_URL');

  /// Runtime override, useful for manual settings or testing
  static String? _customBaseUrl;

  static void setCustomBaseUrl(String? url) {
    _customBaseUrl = url;
  }

  /// Resolves the appropriate base URL based on target platform and environment
  static String get baseUrl {
    if (_customBaseUrl != null && _customBaseUrl!.isNotEmpty) {
      return _customBaseUrl!;
    }
    if (_envBaseUrl.isNotEmpty) {
      return _envBaseUrl;
    }

    // Flutter Web: Browser connects to localhost on host machine
    if (kIsWeb) {
      return 'http://127.0.0.1:8000';
    }

    // Android Emulator: 10.0.2.2 routes to host machine's 127.0.0.1
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8000';
    }

    // Desktop platforms (Linux, macOS, Windows) and iOS simulator
    return 'http://127.0.0.1:8000';
  }
}
