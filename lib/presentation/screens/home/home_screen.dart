import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../data/jellyfin/jellyfin_client.dart';
import '../../../domain/models/media_item.dart';
import '../../providers/home_provider.dart';
import '../../widgets/carousel/content_carousel.dart';
import '../../widgets/hero_banner/hero_banner.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final ScrollController _scrollController = ScrollController();
  int _selectedNavIndex = 0;

  final List<String> _navItems = ['Home', 'Movies', 'TV Shows', 'Search', 'Settings'];

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onItemSelect(MediaItem item) {
    final type = item.isSeries ? 'series' : 'movie';
    context.go('/details/${item.id}?type=$type');
  }

  void _onPlayItem(MediaItem item) {
    if (item.isSeries) {
      // Go to details to select episode
      context.go('/details/${item.id}?type=series');
    } else {
      context.go('/player/${item.id}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final homeData = ref.watch(homeDataProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Focus(
        autofocus: true,
        onKeyEvent: (node, event) {
          if (event is KeyDownEvent) {
            // Handle menu navigation
            if (event.logicalKey == LogicalKeyboardKey.arrowUp &&
                _scrollController.offset < 100) {
              // Focus on nav bar
              return KeyEventResult.ignored;
            }
          }
          return KeyEventResult.ignored;
        },
        child: Stack(
          children: [
            // Main Content
            homeData.when(
              data: (data) => _buildContent(data),
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
              error: (error, stack) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, color: AppColors.error, size: 48),
                    const SizedBox(height: 16),
                    Text(
                      'Error loading content',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      error.toString(),
                      style: const TextStyle(color: Colors.white54),
                    ),
                  ],
                ),
              ),
            ),

            // Top Navigation Bar
            _buildNavBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildNavBar() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        height: 80,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.background,
              AppColors.background.withOpacity(0.8),
              Colors.transparent,
            ],
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 48),
        child: Row(
          children: [
            // Logo
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.play_arrow_rounded,
                color: Colors.white,
                size: 28,
              ),
            ),
            const SizedBox(width: 48),

            // Nav Items
            Expanded(
              child: Row(
                children: List.generate(_navItems.length, (index) {
                  final isSelected = index == _selectedNavIndex;
                  return Padding(
                    padding: const EdgeInsets.only(right: 32),
                    child: _NavItem(
                      title: _navItems[index],
                      isSelected: isSelected,
                      onSelect: () {
                        setState(() => _selectedNavIndex = index);
                        switch (index) {
                          case 3:
                            context.go('/search');
                            break;
                          case 4:
                            context.go('/settings');
                            break;
                        }
                      },
                    ),
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(HomeData data) {
    return CustomScrollView(
      controller: _scrollController,
      slivers: [
        // Hero Banner
        if (data.featured != null)
          SliverToBoxAdapter(
            child: HeroBanner(
              item: data.featured!,
              onPlay: () => _onPlayItem(data.featured!),
              onMoreInfo: () => _onItemSelect(data.featured!),
            ),
          ),

        // Continue Watching
        if (data.continueWatching.isNotEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(top: 24),
              child: ContentCarousel(
                title: 'Continue Watching',
                items: data.continueWatching,
                isLandscape: true,
                onItemSelect: _onItemSelect,
              ),
            ),
          ),

        // Latest Movies
        if (data.latestMovies.isNotEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(top: 24),
              child: ContentCarousel(
                title: 'Latest Movies',
                items: data.latestMovies,
                onItemSelect: _onItemSelect,
              ),
            ),
          ),

        // Latest TV Shows
        if (data.latestTvShows.isNotEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(top: 24),
              child: ContentCarousel(
                title: 'Latest TV Shows',
                items: data.latestTvShows,
                onItemSelect: _onItemSelect,
              ),
            ),
          ),

        // Library Sections
        ...data.libraries.map((library) {
          final items = data.libraryItems[library.id] ?? [];
          if (items.isEmpty) return const SliverToBoxAdapter(child: SizedBox());

          return SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(top: 24),
              child: ContentCarousel(
                title: library.name,
                items: items,
                onItemSelect: _onItemSelect,
              ),
            ),
          );
        }),

        // Bottom padding
        const SliverToBoxAdapter(
          child: SizedBox(height: 48),
        ),
      ],
    );
  }
}

class _NavItem extends StatelessWidget {
  final String title;
  final bool isSelected;
  final VoidCallback onSelect;

  const _NavItem({
    required this.title,
    required this.isSelected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Focus(
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent) {
          if (event.logicalKey == LogicalKeyboardKey.select ||
              event.logicalKey == LogicalKeyboardKey.enter) {
            onSelect();
            return KeyEventResult.handled;
          }
        }
        return KeyEventResult.ignored;
      },
      child: Builder(
        builder: (context) {
          final isFocused = Focus.of(context).hasFocus;
          return GestureDetector(
            onTap: onSelect,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: isSelected || isFocused
                        ? AppColors.primary
                        : Colors.transparent,
                    width: 2,
                  ),
                ),
              ),
              child: Text(
                title,
                style: TextStyle(
                  color: isSelected || isFocused ? Colors.white : Colors.white70,
                  fontSize: 16,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
