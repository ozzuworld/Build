import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/navigation/tv_focus_manager.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/jellyfin/jellyfin_client.dart';
import '../../../domain/models/media_item.dart';

class MediaCard extends ConsumerWidget {
  final MediaItem item;
  final VoidCallback? onSelect;
  final bool autofocus;
  final double width;
  final double height;
  final bool showTitle;
  final bool showProgress;

  const MediaCard({
    super.key,
    required this.item,
    this.onSelect,
    this.autofocus = false,
    this.width = 180,
    this.height = 270,
    this.showTitle = true,
    this.showProgress = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final jellyfinClient = ref.watch(jellyfinClientProvider);
    final imageUrl = jellyfinClient.getImageUrl(
      item.id,
      imageType: 'Primary',
      maxWidth: (width * 2).toInt(),
    );

    return TVFocusable(
      onSelect: onSelect,
      autofocus: autofocus,
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        width: width,
        height: height + (showTitle ? 50 : 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Poster Image
            Stack(
              children: [
                Container(
                  width: width,
                  height: height,
                  decoration: BoxDecoration(
                    color: AppColors.cardBackground,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: CachedNetworkImage(
                      imageUrl: imageUrl,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: AppColors.cardBackground,
                        child: const Center(
                          child: CircularProgressIndicator(
                            color: AppColors.primary,
                            strokeWidth: 2,
                          ),
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: AppColors.cardBackground,
                        child: const Icon(
                          Icons.movie_outlined,
                          color: Colors.white24,
                          size: 48,
                        ),
                      ),
                    ),
                  ),
                ),

                // Rating Badge
                if (item.communityRating != null)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black87,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.star,
                            color: AppColors.warning,
                            size: 12,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            item.formattedRating,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                // Progress Bar
                if (showProgress && item.playedPercentage != null && item.playedPercentage! > 0)
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 4,
                      decoration: const BoxDecoration(
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(8),
                          bottomRight: Radius.circular(8),
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(8),
                          bottomRight: Radius.circular(8),
                        ),
                        child: LinearProgressIndicator(
                          value: item.playedPercentage! / 100,
                          backgroundColor: Colors.black54,
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            AppColors.primary,
                          ),
                        ),
                      ),
                    ),
                  ),

                // Played Indicator
                if (item.isPlayed)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 12,
                      ),
                    ),
                  ),
              ],
            ),

            // Title
            if (showTitle) ...[
              const SizedBox(height: 8),
              Text(
                item.isEpisode ? item.episodeTitle : item.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (item.productionYear != null)
                Text(
                  item.productionYear.toString(),
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 11,
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Landscape card variant for episodes and continue watching
class MediaCardLandscape extends ConsumerWidget {
  final MediaItem item;
  final VoidCallback? onSelect;
  final bool autofocus;
  final double width;
  final double height;

  const MediaCardLandscape({
    super.key,
    required this.item,
    this.onSelect,
    this.autofocus = false,
    this.width = 320,
    this.height = 180,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final jellyfinClient = ref.watch(jellyfinClientProvider);
    final imageUrl = jellyfinClient.getImageUrl(
      item.id,
      imageType: 'Backdrop',
      maxWidth: (width * 2).toInt(),
    );

    return TVFocusable(
      onSelect: onSelect,
      autofocus: autofocus,
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        width: width,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                Container(
                  width: width,
                  height: height,
                  decoration: BoxDecoration(
                    color: AppColors.cardBackground,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: CachedNetworkImage(
                      imageUrl: imageUrl,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: AppColors.cardBackground,
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: AppColors.cardBackground,
                        child: const Icon(
                          Icons.movie_outlined,
                          color: Colors.white24,
                          size: 48,
                        ),
                      ),
                    ),
                  ),
                ),

                // Gradient overlay
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      gradient: AppColors.cardGradient,
                    ),
                  ),
                ),

                // Duration
                Positioned(
                  bottom: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black87,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      item.formattedDuration,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

                // Progress Bar
                if (item.playedPercentage != null && item.playedPercentage! > 0)
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: ClipRRect(
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(8),
                        bottomRight: Radius.circular(8),
                      ),
                      child: LinearProgressIndicator(
                        value: item.playedPercentage! / 100,
                        backgroundColor: Colors.black54,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          AppColors.primary,
                        ),
                        minHeight: 4,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              item.isEpisode
                  ? item.seriesName ?? item.name
                  : item.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (item.isEpisode)
              Text(
                item.episodeTitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 12,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
