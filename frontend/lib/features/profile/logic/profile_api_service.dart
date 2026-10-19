import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../../../core/config/api_config.dart';
import '../../auth/logic/auth_service.dart';
import '../models/user_profile.dart';

/// Service responsible for fetching and updating user profiles from FastAPI
class ProfileApiService {
  ProfileApiService({
    required this.authService,
    http.Client? client,
    String? baseUrl,
  })  : _client = client ?? http.Client(),
        _customBaseUrl = baseUrl;

  final AuthService authService;
  final http.Client _client;
  final String? _customBaseUrl;

  String get baseUrl => _customBaseUrl ?? ApiConfig.baseUrl;

  /// Helper to obtain headers with the authenticated Firebase Bearer token
  Future<Map<String, String>> _getAuthHeaders() async {
    final token = await authService.getIdToken();
    if (token == null || token.isEmpty) {
      throw HttpException(
        'Authentication token is unavailable. Please sign in to access your profile.',
      );
    }
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  /// Fetches the authenticated user's profile from `GET /users/me`
  Future<UserProfile> fetchProfile() async {
    final uri = Uri.parse('$baseUrl/users/me');

    try {
      final headers = await _getAuthHeaders();
      final response = await _client
          .get(uri, headers: headers)
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final dynamic decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) {
          return UserProfile.fromJson(decoded);
        }
        throw const FormatException('Unexpected response format for user profile.');
      } else if (response.statusCode == 401) {
        throw HttpException(
          'Your session has expired. Please sign in again.',
          uri: uri,
        );
      } else if (response.statusCode == 404) {
        throw HttpException('User profile was not found on the server.', uri: uri);
      } else {
        throw HttpException(
          'Failed to load profile (status ${response.statusCode}): ${response.reasonPhrase}',
          uri: uri,
        );
      }
    } on SocketException catch (e) {
      throw Exception(
        'Unable to connect to Kiko server at $baseUrl. ($e)',
      );
    } on TimeoutException {
      throw Exception(
        'Connection timed out while loading user profile.',
      );
    } on http.ClientException catch (e) {
      throw Exception(
        'Network error while connecting to server: ${e.message}',
      );
    } catch (e) {
      if (e is FormatException || e is HttpException) {
        rethrow;
      }
      throw Exception('Failed to load profile: $e');
    }
  }

  /// Updates permitted profile fields (display name) via `PATCH /users/me`
  Future<UserProfile> updateDisplayName(String newDisplayName) async {
    final trimmed = newDisplayName.trim();
    if (trimmed.isEmpty) {
      throw const FormatException('Display name cannot be empty.');
    }

    final uri = Uri.parse('$baseUrl/users/me');

    try {
      final headers = await _getAuthHeaders();
      final response = await _client
          .patch(
            uri,
            headers: headers,
            body: jsonEncode({'display_name': trimmed}),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final dynamic decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) {
          return UserProfile.fromJson(decoded);
        }
        throw const FormatException('Unexpected response format when updating profile.');
      } else if (response.statusCode == 401) {
        throw HttpException(
          'Your session has expired. Please sign in again.',
          uri: uri,
        );
      } else {
        throw HttpException(
          'Failed to update profile (status ${response.statusCode}): ${response.reasonPhrase}',
          uri: uri,
        );
      }
    } on SocketException catch (e) {
      throw Exception(
        'Unable to reach Kiko server at $baseUrl. ($e)',
      );
    } on TimeoutException {
      throw Exception(
        'Connection timed out while updating profile.',
      );
    } on http.ClientException catch (e) {
      throw Exception(
        'Network error while connecting to server: ${e.message}',
      );
    } catch (e) {
      if (e is FormatException || e is HttpException) {
        rethrow;
      }
      throw Exception('Failed to update profile: $e');
    }
  }
}
