import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../domain/models/media_item.dart';
import '../media_card/media_card.dart';

class ContentCarousel extends StatefulWidget {
  final String title;
  final List<MediaItem> items;
  final void Function(MediaItem item)? onItemSelect;
  final bool isLandscape;
  final bool autofocus;
  final double? itemWidth;
  final double? itemHeight;

  const ContentCarousel({
    super.key,
    required this.title,
    required this.items,
    this.onItemSelect,
    this.isLandscape = false,
    this.autofocus = false,
    this.itemWidth,
    this.itemHeight,
  });

  @override
  State<ContentCarousel> createState() => _ContentCarouselState();
}

class _ContentCarouselState extends State<ContentCarousel> {
  final ScrollController _scrollController = ScrollController();
  int _focusedIndex = 0;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToIndex(int index) {
    final itemWidth = widget.isLandscape
        ? (widget.itemWidth ?? 320) + 16
        : (widget.itemWidth ?? 180) + 16;

    final targetOffset = index * itemWidth - 100;
    _scrollController.animateTo(
      targetOffset.clamp(0.0, _scrollController.position.maxScrollExtent),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 8),
          child: Text(
            widget.title,
            style: Theme.of(context).textTheme.headlineMedium,
          ),
        ),

        // Horizontal List
        SizedBox(
          height: widget.isLandscape
              ? (widget.itemHeight ?? 180) + 60
              : (widget.itemHeight ?? 270) + 60,
          child: Focus(
            onKeyEvent: (node, event) {
              if (event is KeyDownEvent) {
                if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
                  if (_focusedIndex > 0) {
                    setState(() => _focusedIndex--);
                    _scrollToIndex(_focusedIndex);
                  }
                  return KeyEventResult.handled;
                } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
                  if (_focusedIndex < widget.items.length - 1) {
                    setState(() => _focusedIndex++);
                    _scrollToIndex(_focusedIndex);
                  }
                  return KeyEventResult.handled;
                }
              }
              return KeyEventResult.ignored;
            },
            child: ListView.builder(
              controller: _scrollController,
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 48),
              itemCount: widget.items.length,
              itemBuilder: (context, index) {
                final item = widget.items[index];

                return Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: widget.isLandscape
                      ? MediaCardLandscape(
                          item: item,
                          autofocus: widget.autofocus && index == 0,
                          width: widget.itemWidth ?? 320,
                          height: widget.itemHeight ?? 180,
                          onSelect: () => widget.onItemSelect?.call(item),
                        )
                      : MediaCard(
                          item: item,
                          autofocus: widget.autofocus && index == 0,
                          width: widget.itemWidth ?? 180,
                          height: widget.itemHeight ?? 270,
                          onSelect: () => widget.onItemSelect?.call(item),
                        ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
