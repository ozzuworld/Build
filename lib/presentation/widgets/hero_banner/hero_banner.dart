import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/navigation/tv_focus_manager.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/jellyfin/jellyfin_client.dart';
import '../../../domain/models/media_item.dart';

class HeroBanner extends ConsumerWidget {
  final MediaItem item;
  final VoidCallback? onPlay;
  final VoidCallback? onMoreInfo;

  const HeroBanner({
    super.key,
    required this.item,
    this.onPlay,
    this.onMoreInfo,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final jellyfinClient = ref.watch(jellyfinClientProvider);
    final backdropUrl = jellyfinClient.getImageUrl(
      item.id,
      imageType: 'Backdrop',
      maxWidth: 1920,
    );

    return SizedBox(
      height: 600,
      child: Stack(
        children: [
          // Background Image
          Positioned.fill(
            child: CachedNetworkImage(
              imageUrl: backdropUrl,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                color: AppColors.background,
              ),
              errorWidget: (context, url, error) => Container(
                color: AppColors.background,
              ),
            ),
          ),

          // Gradient Overlays
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Color(0x80141414),
                    Color(0xFF141414),
                  ],
                  stops: [0.0, 0.6, 1.0],
                ),
              ),
            ),
          ),

          // Side gradient for text readability
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    Color(0xCC141414),
                    Colors.transparent,
                  ],
                  stops: [0.0, 0.6],
                ),
              ),
            ),
          ),

          // Content
          Positioned(
            left: 48,
            bottom: 120,
            right: 400,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Title
                Text(
                  item.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    shadows: [
                      Shadow(
                        color: Colors.black54,
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),

                const SizedBox(height: 16),

                // Metadata Row
                Row(
                  children: [
                    if (item.communityRating != null) ...[
                      const Icon(Icons.star, color: AppColors.warning, size: 18),
                      const SizedBox(width: 4),
                      Text(
                        item.formattedRating,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 16),
                    ],
                    if (item.productionYear != null) ...[
                      Text(
                        item.productionYear.toString(),
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(width: 16),
                    ],
                    if (item.formattedDuration.isNotEmpty) ...[
                      Text(
                        item.formattedDuration,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(width: 16),
                    ],
                    if (item.officialRating != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.white54),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          item.officialRating!,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: 16),

                // Genres
                if (item.genres.isNotEmpty)
                  Text(
                    item.genres.take(3).join(' • '),
                    style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 14,
                    ),
                  ),

                const SizedBox(height: 16),

                // Overview
                if (item.overview != null)
                  Text(
                    item.overview!,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                      height: 1.4,
                    ),
                  ),

                const SizedBox(height: 24),

                // Action Buttons
                Row(
                  children: [
                    TVFocusable(
                      autofocus: true,
                      onSelect: onPlay,
                      borderRadius: BorderRadius.circular(4),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
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
                      onSelect: onMoreInfo,
                      borderRadius: BorderRadius.circular(4),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.info_outline, color: Colors.white, size: 28),
                            SizedBox(width: 8),
                            Text(
                              'More Info',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
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
}
