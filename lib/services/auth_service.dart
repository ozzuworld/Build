import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:keycloak_wrapper/keycloak_wrapper.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:logger/logger.dart';

/// Singleton service for managing Keycloak authentication
class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final _logger = Logger();
  final _storage = const FlutterSecureStorage();

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

      if (kIsWeb) {
        _logger.w('Keycloak OAuth not supported on web platform');
        _isInitialized = true;
        return;
      }

      _keycloakWrapper = KeycloakWrapper(
        keycloakConfig: KeycloakConfig(
          bundleIdentifier: 'com.streamflix.streamflix',
          clientId: clientId,
          frontendUrl: frontendUrl,
          realm: realm,
        ),
        keycloakCallbackUriScheme: 'streamflix',
      );

      // Listen to authentication state changes
      _keycloakWrapper!.onLogin = () async {
        _logger.i('User logged in successfully');
        _isAuthenticated = true;
        await _fetchUserInfo();
        _authStateController.add(true);
      };

      _keycloakWrapper!.onLogout = () {
        _logger.i('User logged out');
        _isAuthenticated = false;
        _userInfo = null;
        _authStateController.add(false);
      };

      // Check if there's a saved session
      final savedToken = await _storage.read(key: 'keycloak_access_token');
      if (savedToken != null) {
        _logger.i('Found saved authentication token');
        _isAuthenticated = true;
        await _fetchUserInfo();
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

      await _keycloakWrapper!.login();

      // Save token for persistence
      final token = await accessToken;
      if (token != null) {
        await _storage.write(key: 'keycloak_access_token', value: token);
      }

      return _isAuthenticated;
    } catch (e) {
      _logger.e('Login failed: $e');
      return false;
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
  Future<String?> get accessToken async {
    try {
      if (kIsWeb) return null;
      if (_keycloakWrapper == null) return null;
      return await _keycloakWrapper!.getAccessToken();
    } catch (e) {
      _logger.e('Error getting access token: $e');
      return null;
    }
  }

  /// Get ID token
  Future<String?> get idToken async {
    try {
      if (kIsWeb) return null;
      if (_keycloakWrapper == null) return null;
      return await _keycloakWrapper!.getIdToken();
    } catch (e) {
      _logger.e('Error getting ID token: $e');
      return null;
    }
  }

  /// Get refresh token
  Future<String?> get refreshToken async {
    try {
      if (kIsWeb) return null;
      if (_keycloakWrapper == null) return null;
      return await _keycloakWrapper!.getRefreshToken();
    } catch (e) {
      _logger.e('Error getting refresh token: $e');
      return null;
    }
  }

  /// Dispose resources
  void dispose() {
    _authStateController.close();
  }
}
