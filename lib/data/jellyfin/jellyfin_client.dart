import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/app_config.dart';
import '../../domain/models/media_item.dart';

final jellyfinClientProvider = Provider<JellyfinClient>((ref) {
  return JellyfinClient();
});

class JellyfinClient {
  late Dio _dio;
  String? _serverUrl;
  String? _accessToken;
  String? _userId;

  static const String _clientName = 'Streamflix';
  static const String _clientVersion = '1.0.0';
  static const String _deviceName = 'TV';
  static const String _deviceId = 'streamflix-tv-001';

  JellyfinClient() {
    _dio = Dio();
    _loadConfig();
  }

  void _loadConfig() {
    _serverUrl = AppConfig.jellyfinUrl;
    _accessToken = AppConfig.jellyfinToken;
    _userId = AppConfig.jellyfinUserId;
    _setupDio();
  }

  void _setupDio() {
    _dio.options = BaseOptions(
      baseUrl: _serverUrl ?? '',
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: _buildHeaders(),
    );
  }

  Map<String, String> _buildHeaders() {
    final authHeader = StringBuffer('MediaBrowser ');
    authHeader.write('Client="$_clientName", ');
    authHeader.write('Device="$_deviceName", ');
    authHeader.write('DeviceId="$_deviceId", ');
    authHeader.write('Version="$_clientVersion"');
    if (_accessToken != null) {
      authHeader.write(', Token="$_accessToken"');
    }

    return {
      'X-Emby-Authorization': authHeader.toString(),
      'Content-Type': 'application/json',
    };
  }

  /// Configure server connection
  void configure({
    required String serverUrl,
    String? accessToken,
    String? userId,
  }) {
    _serverUrl = serverUrl;
    _accessToken = accessToken;
    _userId = userId;
    AppConfig.jellyfinUrl = serverUrl;
    if (accessToken != null) AppConfig.jellyfinToken = accessToken;
    if (userId != null) AppConfig.jellyfinUserId = userId;
    _setupDio();
  }

  bool get isConfigured => _serverUrl != null && _accessToken != null;

  /// Authenticate with username and password
  Future<AuthResult> authenticate(String username, String password) async {
    try {
      final response = await _dio.post(
        '/Users/AuthenticateByName',
        data: {
          'Username': username,
          'Pw': password,
        },
      );

      final data = response.data;
      _accessToken = data['AccessToken'];
      _userId = data['User']['Id'];

      AppConfig.jellyfinToken = _accessToken;
      AppConfig.jellyfinUserId = _userId;
      _setupDio();

      return AuthResult(
        success: true,
        userId: _userId!,
        accessToken: _accessToken!,
        username: data['User']['Name'],
      );
    } on DioException catch (e) {
      return AuthResult(
        success: false,
        error: e.response?.data?['Message'] ?? 'Authentication failed',
      );
    }
  }

  /// Get public server info
  Future<Map<String, dynamic>?> getPublicSystemInfo() async {
    try {
      final response = await _dio.get('/System/Info/Public');
      return response.data;
    } catch (e) {
      return null;
    }
  }

  /// Get user's media libraries
  Future<List<MediaLibrary>> getLibraries() async {
    try {
      final response = await _dio.get('/Users/$_userId/Views');
      final items = response.data['Items'] as List;
      return items.map((item) => MediaLibrary.fromJson(item)).toList();
    } catch (e) {
      return [];
    }
  }

  /// Get items from a library
  Future<List<MediaItem>> getLibraryItems(
    String libraryId, {
    int limit = 20,
    int startIndex = 0,
    String? sortBy,
    String? sortOrder,
    List<String>? includeItemTypes,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'ParentId': libraryId,
        'Limit': limit,
        'StartIndex': startIndex,
        'SortBy': sortBy ?? 'DateCreated,SortName',
        'SortOrder': sortOrder ?? 'Descending',
        'Recursive': true,
        'Fields':
            'Overview,Genres,CommunityRating,CriticRating,RunTimeTicks,ProductionYear,PremiereDate,People,Studios',
        'ImageTypeLimit': 1,
        'EnableImageTypes': 'Primary,Backdrop,Thumb',
      };

      if (includeItemTypes != null) {
        queryParams['IncludeItemTypes'] = includeItemTypes.join(',');
      }

      final response = await _dio.get(
        '/Users/$_userId/Items',
        queryParameters: queryParams,
      );

      final items = response.data['Items'] as List;
      return items.map((item) => MediaItem.fromJson(item)).toList();
    } catch (e) {
      return [];
    }
  }

  /// Get continue watching items
  Future<List<MediaItem>> getContinueWatching({int limit = 12}) async {
    try {
      final response = await _dio.get(
        '/Users/$_userId/Items/Resume',
        queryParameters: {
          'Limit': limit,
          'Recursive': true,
          'Fields': 'Overview,Genres,CommunityRating,RunTimeTicks',
          'ImageTypeLimit': 1,
          'EnableImageTypes': 'Primary,Backdrop,Thumb',
          'MediaTypes': 'Video',
        },
      );

      final items = response.data['Items'] as List;
      return items.map((item) => MediaItem.fromJson(item)).toList();
    } catch (e) {
      return [];
    }
  }

  /// Get latest items from a library
  Future<List<MediaItem>> getLatestItems(String libraryId,
      {int limit = 16}) async {
    try {
      final response = await _dio.get(
        '/Users/$_userId/Items/Latest',
        queryParameters: {
          'ParentId': libraryId,
          'Limit': limit,
          'Fields': 'Overview,Genres,CommunityRating,RunTimeTicks',
          'ImageTypeLimit': 1,
          'EnableImageTypes': 'Primary,Backdrop,Thumb',
        },
      );

      final items = response.data as List;
      return items.map((item) => MediaItem.fromJson(item)).toList();
    } catch (e) {
      return [];
    }
  }

  /// Get item details
  Future<MediaItem?> getItemDetails(String itemId) async {
    try {
      final response = await _dio.get(
        '/Users/$_userId/Items/$itemId',
        queryParameters: {
          'Fields':
              'Overview,Genres,CommunityRating,CriticRating,RunTimeTicks,ProductionYear,PremiereDate,People,Studios,Chapters,MediaSources,MediaStreams',
        },
      );

      return MediaItem.fromJson(response.data);
    } catch (e) {
      return null;
    }
  }

  /// Get TV show seasons
  Future<List<MediaItem>> getSeasons(String seriesId) async {
    try {
      final response = await _dio.get(
        '/Shows/$seriesId/Seasons',
        queryParameters: {
          'UserId': _userId,
          'Fields': 'Overview,PrimaryImageAspectRatio',
        },
      );

      final items = response.data['Items'] as List;
      return items.map((item) => MediaItem.fromJson(item)).toList();
    } catch (e) {
      return [];
    }
  }

  /// Get episodes for a season
  Future<List<MediaItem>> getEpisodes(String seriesId, String seasonId) async {
    try {
      final response = await _dio.get(
        '/Shows/$seriesId/Episodes',
        queryParameters: {
          'UserId': _userId,
          'SeasonId': seasonId,
          'Fields': 'Overview,PrimaryImageAspectRatio,RunTimeTicks',
        },
      );

      final items = response.data['Items'] as List;
      return items.map((item) => MediaItem.fromJson(item)).toList();
    } catch (e) {
      return [];
    }
  }

  /// Get similar items
  Future<List<MediaItem>> getSimilarItems(String itemId,
      {int limit = 12}) async {
    try {
      final response = await _dio.get(
        '/Items/$itemId/Similar',
        queryParameters: {
          'UserId': _userId,
          'Limit': limit,
          'Fields': 'Overview,Genres,CommunityRating',
        },
      );

      final items = response.data['Items'] as List;
      return items.map((item) => MediaItem.fromJson(item)).toList();
    } catch (e) {
      return [];
    }
  }

  /// Search for items
  Future<List<MediaItem>> search(String query, {int limit = 24}) async {
    try {
      final response = await _dio.get(
        '/Users/$_userId/Items',
        queryParameters: {
          'SearchTerm': query,
          'Limit': limit,
          'Recursive': true,
          'Fields': 'Overview,Genres,CommunityRating',
          'IncludeItemTypes': 'Movie,Series,Episode',
        },
      );

      final items = response.data['Items'] as List;
      return items.map((item) => MediaItem.fromJson(item)).toList();
    } catch (e) {
      return [];
    }
  }

  /// Get streaming URL for an item
  String getStreamUrl(String itemId, {String? mediaSourceId}) {
    final params = <String, String>{
      'static': 'true',
      'api_key': _accessToken ?? '',
    };
    if (mediaSourceId != null) {
      params['MediaSourceId'] = mediaSourceId;
    }

    final queryString =
        params.entries.map((e) => '${e.key}=${e.value}').join('&');
    return '$_serverUrl/Videos/$itemId/stream?$queryString';
  }

  /// Get image URL
  String getImageUrl(
    String itemId, {
    String imageType = 'Primary',
    int? maxWidth,
    int? maxHeight,
    int? quality,
  }) {
    final params = <String, String>{};
    if (maxWidth != null) params['maxWidth'] = maxWidth.toString();
    if (maxHeight != null) params['maxHeight'] = maxHeight.toString();
    if (quality != null) params['quality'] = quality.toString();

    final queryString = params.isNotEmpty
        ? '?${params.entries.map((e) => '${e.key}=${e.value}').join('&')}'
        : '';

    return '$_serverUrl/Items/$itemId/Images/$imageType$queryString';
  }

  /// Report playback start
  Future<void> reportPlaybackStart(String itemId, {int? positionTicks}) async {
    try {
      await _dio.post(
        '/Sessions/Playing',
        data: {
          'ItemId': itemId,
          'PositionTicks': positionTicks ?? 0,
          'IsPaused': false,
          'PlayMethod': 'DirectStream',
        },
      );
    } catch (e) {
      // Ignore errors
    }
  }

  /// Report playback progress
  Future<void> reportPlaybackProgress(
    String itemId, {
    required int positionTicks,
    bool isPaused = false,
  }) async {
    try {
      await _dio.post(
        '/Sessions/Playing/Progress',
        data: {
          'ItemId': itemId,
          'PositionTicks': positionTicks,
          'IsPaused': isPaused,
          'PlayMethod': 'DirectStream',
        },
      );
    } catch (e) {
      // Ignore errors
    }
  }

  /// Report playback stopped
  Future<void> reportPlaybackStopped(
    String itemId, {
    required int positionTicks,
  }) async {
    try {
      await _dio.post(
        '/Sessions/Playing/Stopped',
        data: {
          'ItemId': itemId,
          'PositionTicks': positionTicks,
        },
      );
    } catch (e) {
      // Ignore errors
    }
  }
}

class AuthResult {
  final bool success;
  final String? userId;
  final String? accessToken;
  final String? username;
  final String? error;

  AuthResult({
    required this.success,
    this.userId,
    this.accessToken,
    this.username,
    this.error,
  });
}

class MediaLibrary {
  final String id;
  final String name;
  final String collectionType;

  MediaLibrary({
    required this.id,
    required this.name,
    required this.collectionType,
  });

  factory MediaLibrary.fromJson(Map<String, dynamic> json) {
    return MediaLibrary(
      id: json['Id'] ?? '',
      name: json['Name'] ?? '',
      collectionType: json['CollectionType'] ?? '',
    );
  }

  bool get isMovies => collectionType == 'movies';
  bool get isTvShows => collectionType == 'tvshows';
  bool get isMusic => collectionType == 'music';
}
