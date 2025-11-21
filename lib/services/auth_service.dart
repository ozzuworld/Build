import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:keycloak_wrapper/keycloak_wrapper.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:logger/logger.dart';

import '../data/jellyfin/jellyfin_client.dart';
import '../core/config/app_config.dart';

/// Singleton service for managing Keycloak authentication
class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final _logger = Logger();
  final _storage = const FlutterSecureStorage();
  final _jellyfinClient = JellyfinClient();

  KeycloakWrapper? _keycloakWrapper;
  final StreamController<bool> _authStateController =
      StreamController<bool>.broadcast();

  bool _isInitialized = false;
  bool _isAuthenticated = false;
  Map<String, dynamic>? _userInfo;

  // Getters
  bool get isInitialized => _isInitialized;
  bool get isAuthenticated => _isAuthenticated;
  Map<String, dynamic>? get userInfo => _userInfo;
  String? get displayName => _userInfo?['name'] as String?;
  String? get username => _userInfo?['preferred_username'] as String?;
  String? get email => _userInfo?['email'] as String?;
  Stream<bool> get authStateStream => _authStateController.stream;

  /// Initialize Keycloak authentication
  Future<void> initialize({
    required String frontendUrl,
    required String realm,
    required String clientId,
  }) async {
    try {
      _logger.i('Initializing Keycloak authentication...');
      _logger.i('Config - frontendUrl: $frontendUrl');
      _logger.i('Config - realm: $realm');
      _logger.i('Config - clientId: $clientId');
      _logger.i('Config - bundleIdentifier: com.streamflix.streamflix');

      if (kIsWeb) {
        _logger.w('Keycloak OAuth not supported on web platform');
        _isInitialized = true;
        return;
      }

      final keycloakConfig = KeycloakConfig(
        bundleIdentifier: 'com.streamflix.streamflix',
        clientId: clientId,
        frontendUrl: frontendUrl,
        realm: realm,
      );

      _logger.i('Creating KeycloakWrapper instance...');
      _keycloakWrapper = KeycloakWrapper(config: keycloakConfig);

      // Initialize the wrapper
      await _keycloakWrapper!.initialize();

      // Listen to authentication state changes
      _keycloakWrapper!.authenticationStream.listen((isAuthenticated) async {
        _logger.i('Authentication state changed: $isAuthenticated');
        _isAuthenticated = isAuthenticated;

        if (isAuthenticated) {
          await _fetchUserInfo();
        } else {
          _userInfo = null;
        }

        _authStateController.add(isAuthenticated);
      });

      // Check if there's a saved session
      final savedToken = await _storage.read(key: 'keycloak_access_token');
      if (savedToken != null) {
        _logger.i('Found saved authentication token');
        _isAuthenticated = true;
        await _fetchUserInfo();

        // Also ensure Jellyfin is authenticated on app restart
        if (AppConfig.jellyfinToken == null) {
          _logger.i('Jellyfin not authenticated, attempting authentication...');
          await _authenticateWithJellyfin();
        } else {
          _logger.i('Jellyfin already authenticated with stored token');
        }
      }

      _isInitialized = true;
      _logger.i('Keycloak authentication initialized successfully');
    } catch (e) {
      _logger.e('Error initializing Keycloak: $e');
      _isInitialized = true; // Still mark as initialized to prevent blocking
    }
  }

  /// Trigger login flow
  Future<bool> login() async {
    try {
      _logger.i('Starting login flow...');

      if (kIsWeb) {
        // Mock authentication for web platform
        _logger.i('Using mock authentication for web');
        _isAuthenticated = true;
        _userInfo = {
          'name': 'Web User',
          'preferred_username': 'webuser',
          'email': 'user@streamflix.tv',
        };
        _authStateController.add(true);
        return true;
      }

      if (_keycloakWrapper == null) {
        _logger.e('Keycloak not initialized');
        return false;
      }

      // Log the expected OAuth URL that should be constructed
      final authUrl = 'https://idp.ozzu.world/realms/allsafe/protocol/openid-connect/auth';
      final redirectUri = 'com.streamflix.streamflix://oauth2redirect';
      final clientId = 'streamflix-tv-app';

      _logger.i('===== EXPECTED OAUTH URL =====');
      _logger.i('Authorization URL: $authUrl');
      _logger.i('Client ID: $clientId');
      _logger.i('Redirect URI: $redirectUri');
      _logger.i('Full URL would be:');
      _logger.i('$authUrl?client_id=$clientId&redirect_uri=$redirectUri&response_type=code&scope=openid%20profile%20email');
      _logger.i('===== END EXPECTED OAUTH URL =====');

      _logger.i('Calling keycloak_wrapper.login()...');
      await _keycloakWrapper!.login();
      _logger.i('keycloak_wrapper.login() completed');

      // Save token for persistence
      final token = accessToken;
      if (token != null) {
        _logger.i('Access token received, saving...');
        await _storage.write(key: 'keycloak_access_token', value: token);
      } else {
        _logger.w('No access token received after login');
      }

      // Authenticate with Jellyfin after successful Keycloak login
      if (_isAuthenticated) {
        _logger.i('Keycloak login successful, authenticating with Jellyfin...');
        await _authenticateWithJellyfin();
      }

      _logger.i('Login result - isAuthenticated: $_isAuthenticated');
      return _isAuthenticated;
    } catch (e, stackTrace) {
      _logger.e('Login failed: $e');
      _logger.e('Stack trace: $stackTrace');
      return false;
    }
  }

  /// Authenticate with Jellyfin after Keycloak login
  /// Note: Jellyfin authentication is separate from Keycloak (no SSO integration)
  /// Following the ozzu-app pattern: hardcoded admin credentials for shared media server
  Future<void> _authenticateWithJellyfin() async {
    try {
      _logger.i('Authenticating with Jellyfin...');

      // Configure Jellyfin client with server URL
      _jellyfinClient.configure(
        serverUrl: AppConfig.jellyfinUrl,
      );
      _logger.i('Jellyfin client configured with server: ${AppConfig.jellyfinUrl}');

      // Try to load stored Jellyfin credentials first
      String? jellyfinUsername = await _storage.read(key: 'jellyfin_username');
      String? jellyfinPassword = await _storage.read(key: 'jellyfin_password');

      // If no stored credentials, use hardcoded admin credentials (shared media server pattern)
      // TODO: For production, these should be configured per deployment or stored securely
      if (jellyfinUsername == null || jellyfinPassword == null) {
        _logger.i('No stored Jellyfin credentials, using default admin credentials');
        jellyfinUsername = 'hadmin';  // Default admin username
        jellyfinPassword = 'Pokemon123!';  // Default admin password

        // Store these for future use
        await _storage.write(key: 'jellyfin_username', value: jellyfinUsername);
        await _storage.write(key: 'jellyfin_password', value: jellyfinPassword);
      }

      _logger.i('Attempting Jellyfin authentication with username: $jellyfinUsername');
      final result = await _jellyfinClient.authenticate(jellyfinUsername, jellyfinPassword);

      if (result.success) {
        _logger.i('✅ Jellyfin authentication successful!');
        _logger.i('Jellyfin User ID: ${result.userId}');
        _logger.i('Jellyfin Token stored: ${result.accessToken != null}');
      } else {
        _logger.e('❌ Jellyfin authentication failed: ${result.error}');
        // Even if Jellyfin auth fails, don't block Keycloak login
        // User can still see the app, but content won't load
      }
    } catch (e, stackTrace) {
      _logger.e('Error authenticating with Jellyfin: $e');
      _logger.e('Stack trace: $stackTrace');
      // Don't throw - allow app to continue even if Jellyfin auth fails
    }
  }

  /// Logout user
  Future<void> logout() async {
    try {
      _logger.i('Starting logout...');

      if (!kIsWeb && _keycloakWrapper != null) {
        await _keycloakWrapper!.logout();
      }

      // Clear stored tokens
      await _storage.delete(key: 'keycloak_access_token');

      // Clear Jellyfin configuration
      AppConfig.jellyfinToken = null;
      AppConfig.jellyfinUserId = null;

      _isAuthenticated = false;
      _userInfo = null;
      _authStateController.add(false);

      _logger.i('Logout completed');
    } catch (e) {
      _logger.e('Logout error: $e');
      // Force clear state even on error
      _isAuthenticated = false;
      _userInfo = null;
      _authStateController.add(false);
    }
  }

  /// Fetch user information from Keycloak
  Future<void> _fetchUserInfo() async {
    try {
      if (kIsWeb || _keycloakWrapper == null) return;

      final info = await _keycloakWrapper!.getUserInfo();
      _userInfo = info;
      _logger.i('User info fetched: ${_userInfo?['preferred_username']}');
    } catch (e) {
      _logger.e('Error fetching user info: $e');
    }
  }

  /// Get access token
  String? get accessToken {
    try {
      if (kIsWeb) return null;
      if (_keycloakWrapper == null) return null;
      return _keycloakWrapper!.accessToken;
    } catch (e) {
      _logger.e('Error getting access token: $e');
      return null;
    }
  }

  /// Get ID token
  String? get idToken {
    try {
      if (kIsWeb) return null;
      if (_keycloakWrapper == null) return null;
      return _keycloakWrapper!.idToken;
    } catch (e) {
      _logger.e('Error getting ID token: $e');
      return null;
    }
  }

  /// Get refresh token
  String? get refreshToken {
    try {
      if (kIsWeb) return null;
      if (_keycloakWrapper == null) return null;
      return _keycloakWrapper!.refreshToken;
    } catch (e) {
      _logger.e('Error getting refresh token: $e');
      return null;
    }
  }

  /// Configure Jellyfin credentials manually (for different deployments)
  Future<bool> configureJellyfinCredentials({
    required String username,
    required String password,
  }) async {
    try {
      _logger.i('Configuring custom Jellyfin credentials for user: $username');

      // Store credentials
      await _storage.write(key: 'jellyfin_username', value: username);
      await _storage.write(key: 'jellyfin_password', value: password);

      // Attempt authentication with new credentials
      _jellyfinClient.configure(serverUrl: AppConfig.jellyfinUrl);
      final result = await _jellyfinClient.authenticate(username, password);

      if (result.success) {
        _logger.i('✅ Jellyfin configured successfully');
        return true;
      } else {
        _logger.e('❌ Jellyfin configuration failed: ${result.error}');
        // Clear invalid credentials
        await _storage.delete(key: 'jellyfin_username');
        await _storage.delete(key: 'jellyfin_password');
        return false;
      }
    } catch (e) {
      _logger.e('Error configuring Jellyfin: $e');
      return false;
    }
  }

  /// Dispose resources
  void dispose() {
    _authStateController.close();
  }
}
