import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:keycloak_wrapper/keycloak_wrapper.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:logger/logger.dart';
import 'package:dio/dio.dart';

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

  /// Authenticate with Jellyfin using Keycloak SSO
  /// The backend team has configured Jellyfin SSO with Keycloak
  Future<void> _authenticateWithJellyfin() async {
    try {
      _logger.i('🔐 Authenticating with Jellyfin via Keycloak SSO...');

      // Configure Jellyfin client with server URL
      _jellyfinClient.configure(
        serverUrl: AppConfig.jellyfinUrl,
      );
      _logger.i('Jellyfin client configured with server: ${AppConfig.jellyfinUrl}');

      // Get the Keycloak access token
      final keycloakToken = accessToken;
      if (keycloakToken == null) {
        _logger.e('❌ No Keycloak token available for SSO');
        return;
      }

      _logger.i('🎫 Using Keycloak token for SSO authentication');

      // Try SSO authentication with Keycloak token
      final ssoSuccess = await _authenticateWithJellyfinSSO(keycloakToken);

      if (ssoSuccess) {
        _logger.i('✅ Jellyfin SSO authentication successful!');
        return;
      }

      // If SSO fails, fall back to checking for stored credentials
      _logger.w('⚠️ SSO authentication failed, checking for stored credentials...');

      final jellyfinUsername = await _storage.read(key: 'jellyfin_username');
      final jellyfinPassword = await _storage.read(key: 'jellyfin_password');

      if (jellyfinUsername != null && jellyfinPassword != null) {
        _logger.i('Found stored Jellyfin credentials, attempting direct auth...');
        final result = await _jellyfinClient.authenticate(jellyfinUsername, jellyfinPassword);

        if (result.success) {
          _logger.i('✅ Jellyfin direct authentication successful!');
        } else {
          _logger.e('❌ Jellyfin direct authentication failed: ${result.error}');
        }
      } else {
        _logger.w('⚠️ No stored credentials available. User will need to configure Jellyfin access.');
      }
    } catch (e, stackTrace) {
      _logger.e('Error authenticating with Jellyfin: $e');
      _logger.e('Stack trace: $stackTrace');
      // Don't throw - allow app to continue even if Jellyfin auth fails
    }
  }

  /// Authenticate with Jellyfin using SSO and Keycloak token
  Future<bool> _authenticateWithJellyfinSSO(String keycloakToken) async {
    try {
      _logger.i('🔄 Initiating Jellyfin SSO with Keycloak token...');

      final dio = Dio();

      // Primary approach: Use backend API for token exchange
      // The backend validates the Keycloak token and returns a Jellyfin token
      try {
        _logger.i('Attempting backend token exchange...');
        final backendUrl = 'https://api.ozzu.world/api/jellyfin/token';

        final response = await dio.post(
          backendUrl,
          options: Options(
            headers: {
              'Authorization': 'Bearer $keycloakToken',
              'Content-Type': 'application/json',
            },
            sendTimeout: const Duration(seconds: 10),
            receiveTimeout: const Duration(seconds: 10),
          ),
          data: {
            'device_id': 'streamflix-tv-001',
            'device_name': 'StreamFlix TV App',
            'client_version': '1.0.0',
          },
        );

        _logger.i('Backend API response status: ${response.statusCode}');

        if (response.statusCode == 200) {
          final data = response.data;
          final token = data['access_token'] as String?;
          final userId = data['user_id'] as String?;

          if (token != null && userId != null) {
            // Store the Jellyfin token
            AppConfig.jellyfinToken = token;
            AppConfig.jellyfinUserId = userId;

            // Configure the client
            _jellyfinClient.configure(
              serverUrl: AppConfig.jellyfinUrl,
              accessToken: token,
              userId: userId,
            );

            _logger.i('✅ Backend token exchange successful!');
            return true;
          }
        }
      } on DioException catch (e) {
        if (e.type == DioExceptionType.connectionTimeout ||
            e.type == DioExceptionType.receiveTimeout) {
          _logger.w('⏱️ Backend API timeout - endpoint may not be implemented yet');
        } else if (e.response?.statusCode == 404) {
          _logger.w('⚠️ Backend API endpoint not found (404)');
        } else {
          _logger.e('Backend API error: ${e.message}');
        }
      } catch (e) {
        _logger.e('Backend token exchange failed: $e');
      }

      // The SSO redirect approach won't work for mobile apps
      // It requires browser interaction that Dio can't handle
      _logger.w('⚠️ Direct SSO endpoint not suitable for mobile apps');
      _logger.w('Browser-based SSO redirects require WebView or backend API');

      return false;

    } catch (e, stackTrace) {
      _logger.e('SSO authentication error: $e');
      _logger.e('Stack trace: $stackTrace');
      return false;
    }
  }

  /// Alternative: Use Keycloak token to get Jellyfin access via backend API
  /// This method is now deprecated - use _authenticateWithJellyfinSSO instead
  Future<bool> _authenticateWithJellyfinToken(String keycloakToken) async {
    // This method is no longer needed as the logic is now in _authenticateWithJellyfinSSO
    _logger.w('⚠️ Jellyfin SSO requires backend token exchange endpoint');
    _logger.w('Backend should implement: POST https://api.ozzu.world/api/jellyfin/token');
    _logger.w('See JELLYFIN_SSO_INTEGRATION.md for complete specification');
    return false;
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
