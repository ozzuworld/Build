import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/navigation/tv_focus_manager.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/jellyfin/jellyfin_client.dart';
import '../../../domain/models/media_item.dart';
import '../../widgets/carousel/content_carousel.dart';

class DetailsScreen extends ConsumerStatefulWidget {
  final String itemId;
  final String itemType;

  const DetailsScreen({
    super.key,
    required this.itemId,
    required this.itemType,
  });

  @override
  ConsumerState<DetailsScreen> createState() => _DetailsScreenState();
}

class _DetailsScreenState extends ConsumerState<DetailsScreen> {
  MediaItem? _item;
  List<MediaItem> _seasons = [];
  List<MediaItem> _episodes = [];
  List<MediaItem> _similar = [];
  String? _selectedSeasonId;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final client = ref.read(jellyfinClientProvider);

    final item = await client.getItemDetails(widget.itemId);
    if (item == null) return;

    setState(() => _item = item);

    // Load additional data based on type
    if (item.isSeries) {
      final seasons = await client.getSeasons(widget.itemId);
      setState(() {
        _seasons = seasons;
        if (seasons.isNotEmpty) {
          _selectedSeasonId = seasons.first.id;
        }
      });

      if (_selectedSeasonId != null) {
        await _loadEpisodes(_selectedSeasonId!);
      }
    }

    // Load similar items
    final similar = await client.getSimilarItems(widget.itemId, limit: 12);
    setState(() {
      _similar = similar;
      _isLoading = false;
    });
  }

  Future<void> _loadEpisodes(String seasonId) async {
    final client = ref.read(jellyfinClientProvider);
    final episodes = await client.getEpisodes(widget.itemId, seasonId);
    setState(() {
      _episodes = episodes;
      _selectedSeasonId = seasonId;
    });
  }

  void _playItem([MediaItem? episode]) {
    final itemId = episode?.id ?? widget.itemId;
    context.go('/player/$itemId');
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _item == null) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    final client = ref.watch(jellyfinClientProvider);
    final backdropUrl = client.getImageUrl(
      _item!.id,
      imageType: 'Backdrop',
      maxWidth: 1920,
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Background
          Positioned.fill(
            child: CachedNetworkImage(
              imageUrl: backdropUrl,
              fit: BoxFit.cover,
              color: Colors.black54,
              colorBlendMode: BlendMode.darken,
            ),
          ),

          // Gradient overlay
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    AppColors.background,
                  ],
                  stops: [0.0, 0.5],
                ),
              ),
            ),
          ),

          // Content
          CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: _buildHeader(),
              ),

              // Seasons tabs for TV shows
              if (_item!.isSeries && _seasons.isNotEmpty)
                SliverToBoxAdapter(
                  child: _buildSeasonTabs(),
                ),

              // Episodes for TV shows
              if (_item!.isSeries && _episodes.isNotEmpty)
                SliverToBoxAdapter(
                  child: _buildEpisodesList(),
                ),

              // Similar items
              if (_similar.isNotEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 32),
                    child: ContentCarousel(
                      title: 'More Like This',
                      items: _similar,
                      onItemSelect: (item) {
                        final type = item.isSeries ? 'series' : 'movie';
                        context.go('/details/${item.id}?type=$type');
                      },
                    ),
                  ),
                ),

              const SliverToBoxAdapter(
                child: SizedBox(height: 48),
              ),
            ],
          ),

          // Back button
          Positioned(
            top: 24,
            left: 24,
            child: TVFocusable(
              onSelect: () => context.go('/home'),
              borderRadius: BorderRadius.circular(24),
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Icon(Icons.arrow_back, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final client = ref.watch(jellyfinClientProvider);
    final posterUrl = client.getImageUrl(
      _item!.id,
      imageType: 'Primary',
      maxWidth: 400,
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(48, 100, 48, 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Poster
          Container(
            width: 250,
            height: 375,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.5),
                  blurRadius: 20,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: CachedNetworkImage(
                imageUrl: posterUrl,
                fit: BoxFit.cover,
              ),
            ),
          ),

          const SizedBox(width: 48),

          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                Text(
                  _item!.name,
                  style: const TextStyle(
                    fontSize: 42,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),

                const SizedBox(height: 16),

                // Metadata row
                Row(
                  children: [
                    if (_item!.communityRating != null) ...[
                      const Icon(Icons.star, color: AppColors.warning, size: 20),
                      const SizedBox(width: 4),
                      Text(
                        _item!.formattedRating,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 24),
                    ],
                    if (_item!.productionYear != null) ...[
                      Text(
                        _item!.productionYear.toString(),
                        style: const TextStyle(color: Colors.white70, fontSize: 16),
                      ),
                      const SizedBox(width: 24),
                    ],
                    if (_item!.formattedDuration.isNotEmpty) ...[
                      Text(
                        _item!.formattedDuration,
                        style: const TextStyle(color: Colors.white70, fontSize: 16),
                      ),
                      const SizedBox(width: 24),
                    ],
                    if (_item!.officialRating != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.white54),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          _item!.officialRating!,
                          style: const TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: 16),

                // Genres
                if (_item!.genres.isNotEmpty)
                  Text(
                    _item!.genres.join(' • '),
                    style: const TextStyle(color: Colors.white54, fontSize: 14),
                  ),

                const SizedBox(height: 24),

                // Overview
                if (_item!.overview != null)
                  Text(
                    _item!.overview!,
                    maxLines: 5,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                      height: 1.5,
                    ),
                  ),

                const SizedBox(height: 32),

                // Action buttons
                Row(
                  children: [
                    TVFocusable(
                      autofocus: true,
                      onSelect: () => _playItem(),
                      borderRadius: BorderRadius.circular(4),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 16,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.play_arrow, color: Colors.black, size: 28),
                            SizedBox(width: 8),
                            Text(
                              'Play',
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    TVFocusable(
                      onSelect: () {},
                      borderRadius: BorderRadius.circular(24),
                      child: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: const Icon(Icons.add, color: Colors.white),
                      ),
                    ),
                    const SizedBox(width: 12),
                    TVFocusable(
                      onSelect: () {},
                      borderRadius: BorderRadius.circular(24),
                      child: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Icon(
                          _item!.isFavorite
                              ? Icons.favorite
                              : Icons.favorite_border,
                          color: _item!.isFavorite ? AppColors.primary : Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSeasonTabs() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 48),
      child: SizedBox(
        height: 50,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: _seasons.length,
          itemBuilder: (context, index) {
            final season = _seasons[index];
            final isSelected = season.id == _selectedSeasonId;

            return Padding(
              padding: const EdgeInsets.only(right: 16),
              child: TVFocusable(
                onSelect: () => _loadEpisodes(season.id),
                borderRadius: BorderRadius.circular(4),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.white : Colors.white12,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    season.name,
                    style: TextStyle(
                      color: isSelected ? Colors.black : Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildEpisodesList() {
    final client = ref.watch(jellyfinClientProvider);

    return Padding(
      padding: const EdgeInsets.all(48),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Episodes',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          ...List.generate(_episodes.length, (index) {
            final episode = _episodes[index];
            final thumbUrl = client.getImageUrl(
              episode.id,
              imageType: 'Primary',
              maxWidth: 400,
            );

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: TVFocusable(
                onSelect: () => _playItem(episode),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  height: 120,
                  decoration: BoxDecoration(
                    color: AppColors.cardBackground,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      // Thumbnail
                      ClipRRect(
                        borderRadius: const BorderRadius.horizontal(
                          left: Radius.circular(8),
                        ),
                        child: SizedBox(
                          width: 200,
                          height: 120,
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              CachedNetworkImage(
                                imageUrl: thumbUrl,
                                fit: BoxFit.cover,
                              ),
                              const Center(
                                child: Icon(
                                  Icons.play_circle_outline,
                                  color: Colors.white70,
                                  size: 48,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Info
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                '${episode.indexNumber}. ${episode.name}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                episode.formattedDuration,
                                style: const TextStyle(
                                  color: Colors.white54,
                                  fontSize: 12,
                                ),
                              ),
                              if (episode.overview != null) ...[
                                const SizedBox(height: 8),
                                Text(
                                  episode.overview!,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.white54,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
