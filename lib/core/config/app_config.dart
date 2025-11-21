import 'package:shared_preferences/shared_preferences.dart';

class AppConfig {
  static late SharedPreferences _prefs;

  // Default Server Configuration (Hardcoded)
  // Users will connect directly to this server without needing to enter the URL
  static const String defaultJellyfinUrl = 'http://tv.ozzu.world:8096';
  static const String defaultJellyseerrUrl = 'http://tv.ozzu.world:5055';

  static const String _jellyfinUrlKey = 'jellyfin_url';
  static const String _jellyfinTokenKey = 'jellyfin_token';
  static const String _jellyfinUserIdKey = 'jellyfin_user_id';
  static const String _jellyseerrUrlKey = 'jellyseerr_url';
  static const String _jellyseerrApiKeyKey = 'jellyseerr_api_key';

  static Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // Jellyfin Configuration
  static String get jellyfinUrl =>
      _prefs.getString(_jellyfinUrlKey) ?? defaultJellyfinUrl;
  static set jellyfinUrl(String? value) {
    if (value != null) {
      _prefs.setString(_jellyfinUrlKey, value);
    } else {
      _prefs.remove(_jellyfinUrlKey);
    }
  }

  static String? get jellyfinToken => _prefs.getString(_jellyfinTokenKey);
  static set jellyfinToken(String? value) {
    if (value != null) {
      _prefs.setString(_jellyfinTokenKey, value);
    } else {
      _prefs.remove(_jellyfinTokenKey);
    }
  }

  static String? get jellyfinUserId => _prefs.getString(_jellyfinUserIdKey);
  static set jellyfinUserId(String? value) {
    if (value != null) {
      _prefs.setString(_jellyfinUserIdKey, value);
    } else {
      _prefs.remove(_jellyfinUserIdKey);
    }
  }

  // Jellyseerr Configuration
  static String get jellyseerrUrl =>
      _prefs.getString(_jellyseerrUrlKey) ?? defaultJellyseerrUrl;
  static set jellyseerrUrl(String? value) {
    if (value != null) {
      _prefs.setString(_jellyseerrUrlKey, value);
    } else {
      _prefs.remove(_jellyseerrUrlKey);
    }
  }

  static String? get jellyseerrApiKey => _prefs.getString(_jellyseerrApiKeyKey);
  static set jellyseerrApiKey(String? value) {
    if (value != null) {
      _prefs.setString(_jellyseerrApiKeyKey, value);
    } else {
      _prefs.remove(_jellyseerrApiKeyKey);
    }
  }

  // Check if configured
  static bool get isJellyfinConfigured =>
      jellyfinUrl != null && jellyfinToken != null;

  static bool get isJellyseerrConfigured =>
      jellyseerrUrl != null && jellyseerrApiKey != null;

  // Clear all configuration
  static Future<void> clearAll() async {
    await _prefs.clear();
  }
}
