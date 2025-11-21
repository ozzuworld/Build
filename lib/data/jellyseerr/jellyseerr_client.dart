import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/app_config.dart';

final jellyseerrClientProvider = Provider<JellyseerrClient>((ref) {
  return JellyseerrClient();
});

class JellyseerrClient {
  late Dio _dio;
  String? _serverUrl;
  String? _apiKey;

  JellyseerrClient() {
    _dio = Dio();
    _loadConfig();
  }

  void _loadConfig() {
    _serverUrl = AppConfig.jellyseerrUrl;
    _apiKey = AppConfig.jellyseerrApiKey;
    _setupDio();
  }

  void _setupDio() {
    _dio.options = BaseOptions(
      baseUrl: _serverUrl != null ? '$_serverUrl/api/v1' : '',
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
        if (_apiKey != null) 'X-Api-Key': _apiKey,
      },
    );
  }

  void configure({required String serverUrl, required String apiKey}) {
    _serverUrl = serverUrl;
    _apiKey = apiKey;
    AppConfig.jellyseerrUrl = serverUrl;
    AppConfig.jellyseerrApiKey = apiKey;
    _setupDio();
  }

  bool get isConfigured => _serverUrl != null && _apiKey != null;

  /// Search for movies and TV shows on TMDB via Jellyseerr
  Future<SearchResults> search(String query, {int page = 1}) async {
    try {
      final response = await _dio.get(
        '/search',
        queryParameters: {
          'query': query,
          'page': page,
        },
      );

      return SearchResults.fromJson(response.data);
    } catch (e) {
      return SearchResults(results: [], page: 1, totalPages: 0, totalResults: 0);
    }
  }

  /// Get movie details from TMDB
  Future<MediaDetails?> getMovieDetails(int tmdbId) async {
    try {
      final response = await _dio.get('/movie/$tmdbId');
      return MediaDetails.fromJson(response.data);
    } catch (e) {
      return null;
    }
  }

  /// Get TV show details from TMDB
  Future<MediaDetails?> getTvDetails(int tmdbId) async {
    try {
      final response = await _dio.get('/tv/$tmdbId');
      return MediaDetails.fromJson(response.data);
    } catch (e) {
      return null;
    }
  }

  /// Request a movie
  Future<RequestResult> requestMovie(int tmdbId) async {
    try {
      final response = await _dio.post(
        '/request',
        data: {
          'mediaType': 'movie',
          'mediaId': tmdbId,
        },
      );

      return RequestResult(
        success: true,
        mediaId: response.data['id'],
        status: response.data['status'],
      );
    } on DioException catch (e) {
      return RequestResult(
        success: false,
        error: e.response?.data?['message'] ?? 'Request failed',
      );
    }
  }

  /// Request a TV show
  Future<RequestResult> requestTvShow(
    int tmdbId, {
    List<int>? seasons,
  }) async {
    try {
      final response = await _dio.post(
        '/request',
        data: {
          'mediaType': 'tv',
          'mediaId': tmdbId,
          if (seasons != null)
            'seasons': seasons.map((s) => {'seasonNumber': s}).toList(),
        },
      );

      return RequestResult(
        success: true,
        mediaId: response.data['id'],
        status: response.data['status'],
      );
    } on DioException catch (e) {
      return RequestResult(
        success: false,
        error: e.response?.data?['message'] ?? 'Request failed',
      );
    }
  }

  /// Get user's requests
  Future<List<MediaRequest>> getRequests({
    int page = 1,
    int pageSize = 20,
    String? status,
  }) async {
    try {
      final response = await _dio.get(
        '/request',
        queryParameters: {
          'take': pageSize,
          'skip': (page - 1) * pageSize,
          if (status != null) 'filter': status,
        },
      );

      final results = response.data['results'] as List;
      return results.map((r) => MediaRequest.fromJson(r)).toList();
    } catch (e) {
      return [];
    }
  }

  /// Get trending movies
  Future<List<TmdbMedia>> getTrendingMovies({int page = 1}) async {
    try {
      final response = await _dio.get(
        '/discover/movies',
        queryParameters: {'page': page},
      );

      final results = response.data['results'] as List;
      return results.map((r) => TmdbMedia.fromJson(r)).toList();
    } catch (e) {
      return [];
    }
  }

  /// Get trending TV shows
  Future<List<TmdbMedia>> getTrendingTvShows({int page = 1}) async {
    try {
      final response = await _dio.get(
        '/discover/tv',
        queryParameters: {'page': page},
      );

      final results = response.data['results'] as List;
      return results.map((r) => TmdbMedia.fromJson(r)).toList();
    } catch (e) {
      return [];
    }
  }

  /// Get TMDB image URL
  String getImageUrl(String? path, {String size = 'w500'}) {
    if (path == null) return '';
    return 'https://image.tmdb.org/t/p/$size$path';
  }
}

// Data classes

class SearchResults {
  final List<TmdbMedia> results;
  final int page;
  final int totalPages;
  final int totalResults;

  SearchResults({
    required this.results,
    required this.page,
    required this.totalPages,
    required this.totalResults,
  });

  factory SearchResults.fromJson(Map<String, dynamic> json) {
    return SearchResults(
      results: (json['results'] as List?)
              ?.map((r) => TmdbMedia.fromJson(r))
              .toList() ??
          [],
      page: json['page'] ?? 1,
      totalPages: json['totalPages'] ?? 0,
      totalResults: json['totalResults'] ?? 0,
    );
  }
}

class TmdbMedia {
  final int id;
  final String mediaType;
  final String? title;
  final String? name;
  final String? overview;
  final String? posterPath;
  final String? backdropPath;
  final double? voteAverage;
  final String? releaseDate;
  final String? firstAirDate;
  final MediaStatus? mediaStatus;

  TmdbMedia({
    required this.id,
    required this.mediaType,
    this.title,
    this.name,
    this.overview,
    this.posterPath,
    this.backdropPath,
    this.voteAverage,
    this.releaseDate,
    this.firstAirDate,
    this.mediaStatus,
  });

  String get displayTitle => title ?? name ?? '';
  String get displayDate => releaseDate ?? firstAirDate ?? '';
  bool get isMovie => mediaType == 'movie';
  bool get isTv => mediaType == 'tv';

  factory TmdbMedia.fromJson(Map<String, dynamic> json) {
    return TmdbMedia(
      id: json['id'] ?? 0,
      mediaType: json['mediaType'] ?? 'movie',
      title: json['title'],
      name: json['name'],
      overview: json['overview'],
      posterPath: json['posterPath'],
      backdropPath: json['backdropPath'],
      voteAverage: (json['voteAverage'] as num?)?.toDouble(),
      releaseDate: json['releaseDate'],
      firstAirDate: json['firstAirDate'],
      mediaStatus: json['mediaInfo'] != null
          ? MediaStatus.fromJson(json['mediaInfo'])
          : null,
    );
  }
}

class MediaDetails {
  final int id;
  final String mediaType;
  final String? title;
  final String? name;
  final String? overview;
  final String? posterPath;
  final String? backdropPath;
  final double? voteAverage;
  final int? runtime;
  final List<String> genres;
  final MediaStatus? mediaStatus;
  final List<Season>? seasons;

  MediaDetails({
    required this.id,
    required this.mediaType,
    this.title,
    this.name,
    this.overview,
    this.posterPath,
    this.backdropPath,
    this.voteAverage,
    this.runtime,
    this.genres = const [],
    this.mediaStatus,
    this.seasons,
  });

  String get displayTitle => title ?? name ?? '';

  factory MediaDetails.fromJson(Map<String, dynamic> json) {
    return MediaDetails(
      id: json['id'] ?? 0,
      mediaType: json['mediaType'] ?? 'movie',
      title: json['title'],
      name: json['name'],
      overview: json['overview'],
      posterPath: json['posterPath'],
      backdropPath: json['backdropPath'],
      voteAverage: (json['voteAverage'] as num?)?.toDouble(),
      runtime: json['runtime'],
      genres: (json['genres'] as List?)
              ?.map((g) => g['name'] as String)
              .toList() ??
          [],
      mediaStatus: json['mediaInfo'] != null
          ? MediaStatus.fromJson(json['mediaInfo'])
          : null,
      seasons: (json['seasons'] as List?)
          ?.map((s) => Season.fromJson(s))
          .toList(),
    );
  }
}

class Season {
  final int id;
  final int seasonNumber;
  final String? name;
  final int? episodeCount;

  Season({
    required this.id,
    required this.seasonNumber,
    this.name,
    this.episodeCount,
  });

  factory Season.fromJson(Map<String, dynamic> json) {
    return Season(
      id: json['id'] ?? 0,
      seasonNumber: json['seasonNumber'] ?? 0,
      name: json['name'],
      episodeCount: json['episodeCount'],
    );
  }
}

class MediaStatus {
  final int status;
  final bool downloadStatus;

  MediaStatus({
    required this.status,
    required this.downloadStatus,
  });

  bool get isAvailable => status == 5;
  bool get isPartiallyAvailable => status == 4;
  bool get isPending => status == 2;
  bool get isProcessing => status == 3;

  String get statusText {
    switch (status) {
      case 1:
        return 'Unknown';
      case 2:
        return 'Pending';
      case 3:
        return 'Processing';
      case 4:
        return 'Partially Available';
      case 5:
        return 'Available';
      default:
        return 'Not Requested';
    }
  }

  factory MediaStatus.fromJson(Map<String, dynamic> json) {
    return MediaStatus(
      status: json['status'] ?? 0,
      downloadStatus: json['downloadStatus'] ?? false,
    );
  }
}

class MediaRequest {
  final int id;
  final String status;
  final String mediaType;
  final TmdbMedia? media;
  final DateTime? createdAt;

  MediaRequest({
    required this.id,
    required this.status,
    required this.mediaType,
    this.media,
    this.createdAt,
  });

  factory MediaRequest.fromJson(Map<String, dynamic> json) {
    return MediaRequest(
      id: json['id'] ?? 0,
      status: json['status']?.toString() ?? 'pending',
      mediaType: json['type'] ?? 'movie',
      media: json['media'] != null ? TmdbMedia.fromJson(json['media']) : null,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'])
          : null,
    );
  }
}

class RequestResult {
  final bool success;
  final int? mediaId;
  final int? status;
  final String? error;

  RequestResult({
    required this.success,
    this.mediaId,
    this.status,
    this.error,
  });
}
