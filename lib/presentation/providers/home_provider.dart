import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/jellyfin/jellyfin_client.dart';
import '../../domain/models/media_item.dart';

class HomeData {
  final MediaItem? featured;
  final List<MediaItem> continueWatching;
  final List<MediaItem> latestMovies;
  final List<MediaItem> latestTvShows;
  final List<MediaLibrary> libraries;
  final Map<String, List<MediaItem>> libraryItems;

  HomeData({
    this.featured,
    this.continueWatching = const [],
    this.latestMovies = const [],
    this.latestTvShows = const [],
    this.libraries = const [],
    this.libraryItems = const {},
  });
}

final homeDataProvider = FutureProvider<HomeData>((ref) async {
  final client = ref.watch(jellyfinClientProvider);

  if (!client.isConfigured) {
    return HomeData();
  }

  // Fetch libraries first
  final libraries = await client.getLibraries();

  // Find movies and TV show libraries
  MediaLibrary? moviesLibrary;
  MediaLibrary? tvShowsLibrary;

  for (final library in libraries) {
    if (library.isMovies && moviesLibrary == null) {
      moviesLibrary = library;
    } else if (library.isTvShows && tvShowsLibrary == null) {
      tvShowsLibrary = library;
    }
  }

  // Fetch content in parallel
  final futures = await Future.wait([
    client.getContinueWatching(limit: 12),
    moviesLibrary != null
        ? client.getLatestItems(moviesLibrary.id, limit: 16)
        : Future.value(<MediaItem>[]),
    tvShowsLibrary != null
        ? client.getLatestItems(tvShowsLibrary.id, limit: 16)
        : Future.value(<MediaItem>[]),
  ]);

  final continueWatching = futures[0];
  final latestMovies = futures[1];
  final latestTvShows = futures[2];

  // Determine featured item
  MediaItem? featured;
  if (latestMovies.isNotEmpty) {
    featured = latestMovies.first;
  } else if (latestTvShows.isNotEmpty) {
    featured = latestTvShows.first;
  }

  // Fetch items for each library
  final libraryItems = <String, List<MediaItem>>{};
  for (final library in libraries) {
    if (library.isMovies || library.isTvShows) continue; // Already shown
    final items = await client.getLatestItems(library.id, limit: 12);
    if (items.isNotEmpty) {
      libraryItems[library.id] = items;
    }
  }

  return HomeData(
    featured: featured,
    continueWatching: continueWatching,
    latestMovies: latestMovies,
    latestTvShows: latestTvShows,
    libraries: libraries.where((l) => !l.isMovies && !l.isTvShows).toList(),
    libraryItems: libraryItems,
  );
});

// Provider to refresh home data
final homeRefreshProvider = Provider<void Function()>((ref) {
  return () => ref.invalidate(homeDataProvider);
});
