import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../data/jellyfin/jellyfin_client.dart';
import '../../../domain/models/media_item.dart';

class PlayerScreen extends ConsumerStatefulWidget {
  final String itemId;

  const PlayerScreen({
    super.key,
    required this.itemId,
  });

  @override
  ConsumerState<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends ConsumerState<PlayerScreen> {
  MediaItem? _item;
  bool _isLoading = true;
  bool _showControls = true;
  bool _isPlaying = false;
  bool _isBuffering = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  Timer? _hideControlsTimer;
  Timer? _progressReportTimer;

  // Note: In a real app, you would use media_kit here
  // This is a placeholder UI that shows how the player would look

  @override
  void initState() {
    super.initState();
    _loadItem();
    _startHideControlsTimer();
  }

  @override
  void dispose() {
    _hideControlsTimer?.cancel();
    _progressReportTimer?.cancel();
    _reportPlaybackStopped();
    super.dispose();
  }

  Future<void> _loadItem() async {
    final client = ref.read(jellyfinClientProvider);
    final item = await client.getItemDetails(widget.itemId);

    if (item != null) {
      setState(() {
        _item = item;
        _isLoading = false;
        _duration = Duration(
          microseconds: (item.runTimeTicks ?? 0) ~/ 10,
        );
        _position = Duration(
          microseconds: (item.userDataPlaybackPositionTicks ?? 0) ~/ 10,
        );
      });

      // Report playback start
      await client.reportPlaybackStart(
        widget.itemId,
        positionTicks: item.userDataPlaybackPositionTicks,
      );

      // Start progress reporting
      _startProgressReporting();

      // Auto-play
      setState(() => _isPlaying = true);
    }
  }

  void _startHideControlsTimer() {
    _hideControlsTimer?.cancel();
    _hideControlsTimer = Timer(const Duration(seconds: 5), () {
      if (_isPlaying && mounted) {
        setState(() => _showControls = false);
      }
    });
  }

  void _startProgressReporting() {
    _progressReportTimer?.cancel();
    _progressReportTimer = Timer.periodic(
      const Duration(seconds: 10),
      (_) => _reportProgress(),
    );
  }

  Future<void> _reportProgress() async {
    if (_item == null) return;
    final client = ref.read(jellyfinClientProvider);
    await client.reportPlaybackProgress(
      widget.itemId,
      positionTicks: _position.inMicroseconds * 10,
      isPaused: !_isPlaying,
    );
  }

  Future<void> _reportPlaybackStopped() async {
    if (_item == null) return;
    final client = ref.read(jellyfinClientProvider);
    await client.reportPlaybackStopped(
      widget.itemId,
      positionTicks: _position.inMicroseconds * 10,
    );
  }

  void _showControlsAndResetTimer() {
    setState(() => _showControls = true);
    _startHideControlsTimer();
  }

  void _togglePlayPause() {
    setState(() => _isPlaying = !_isPlaying);
    _showControlsAndResetTimer();
  }

  void _seekRelative(Duration offset) {
    final newPosition = _position + offset;
    setState(() {
      _position = Duration(
        microseconds: newPosition.inMicroseconds.clamp(
          0,
          _duration.inMicroseconds,
        ),
      );
    });
    _showControlsAndResetTimer();
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '${twoDigits(hours)}:${twoDigits(minutes)}:${twoDigits(seconds)}';
    }
    return '${twoDigits(minutes)}:${twoDigits(seconds)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Focus(
        autofocus: true,
        onKeyEvent: (node, event) {
          if (event is KeyDownEvent) {
            switch (event.logicalKey) {
              case LogicalKeyboardKey.select:
              case LogicalKeyboardKey.enter:
              case LogicalKeyboardKey.space:
                _togglePlayPause();
                return KeyEventResult.handled;

              case LogicalKeyboardKey.arrowLeft:
                _seekRelative(const Duration(seconds: -10));
                return KeyEventResult.handled;

              case LogicalKeyboardKey.arrowRight:
                _seekRelative(const Duration(seconds: 10));
                return KeyEventResult.handled;

              case LogicalKeyboardKey.arrowUp:
              case LogicalKeyboardKey.arrowDown:
                _showControlsAndResetTimer();
                return KeyEventResult.handled;

              case LogicalKeyboardKey.goBack:
              case LogicalKeyboardKey.escape:
                context.go('/home');
                return KeyEventResult.handled;
            }
          }
          return KeyEventResult.ignored;
        },
        child: GestureDetector(
          onTap: _showControlsAndResetTimer,
          child: Stack(
            children: [
              // Video placeholder (in real app, this would be VideoPlayer)
              Container(
                color: Colors.black,
                child: Center(
                  child: _isLoading
                      ? const CircularProgressIndicator(color: AppColors.primary)
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _isPlaying
                                  ? Icons.play_circle_filled
                                  : Icons.pause_circle_filled,
                              color: Colors.white24,
                              size: 120,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Video Player Placeholder',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.3),
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Use media_kit for actual playback',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.2),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                ),
              ),

              // Buffering indicator
              if (_isBuffering)
                const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),

              // Controls overlay
              AnimatedOpacity(
                opacity: _showControls ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 300),
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black54,
                        Colors.transparent,
                        Colors.transparent,
                        Colors.black54,
                      ],
                      stops: [0.0, 0.2, 0.8, 1.0],
                    ),
                  ),
                  child: Column(
                    children: [
                      // Top bar
                      _buildTopBar(),

                      const Spacer(),

                      // Center controls
                      _buildCenterControls(),

                      const Spacer(),

                      // Bottom bar with progress
                      _buildBottomBar(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => context.go('/home'),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _item?.name ?? '',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (_item?.isEpisode == true)
                    Text(
                      _item?.seriesName ?? '',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCenterControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Rewind 10s
        IconButton(
          icon: const Icon(Icons.replay_10, color: Colors.white, size: 48),
          onPressed: () => _seekRelative(const Duration(seconds: -10)),
        ),

        const SizedBox(width: 48),

        // Play/Pause
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: Colors.white24,
            borderRadius: BorderRadius.circular(40),
          ),
          child: IconButton(
            icon: Icon(
              _isPlaying ? Icons.pause : Icons.play_arrow,
              color: Colors.white,
              size: 48,
            ),
            onPressed: _togglePlayPause,
          ),
        ),

        const SizedBox(width: 48),

        // Forward 10s
        IconButton(
          icon: const Icon(Icons.forward_10, color: Colors.white, size: 48),
          onPressed: () => _seekRelative(const Duration(seconds: 10)),
        ),
      ],
    );
  }

  Widget _buildBottomBar() {
    final progress = _duration.inMicroseconds > 0
        ? _position.inMicroseconds / _duration.inMicroseconds
        : 0.0;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Progress bar
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 4,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
                activeTrackColor: AppColors.primary,
                inactiveTrackColor: Colors.white24,
                thumbColor: AppColors.primary,
                overlayColor: AppColors.primary.withOpacity(0.3),
              ),
              child: Slider(
                value: progress.clamp(0.0, 1.0),
                onChanged: (value) {
                  final newPosition = Duration(
                    microseconds: (value * _duration.inMicroseconds).toInt(),
                  );
                  setState(() => _position = newPosition);
                },
                onChangeEnd: (_) => _showControlsAndResetTimer(),
              ),
            ),

            // Time labels
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _formatDuration(_position),
                    style: const TextStyle(color: Colors.white70),
                  ),
                  Text(
                    _formatDuration(_duration),
                    style: const TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
