import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/app_config.dart';
import '../../../core/navigation/tv_focus_manager.dart';
import '../../../core/theme/app_colors.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Focus(
        autofocus: true,
        onKeyEvent: (node, event) {
          if (event is KeyDownEvent) {
            if (event.logicalKey == LogicalKeyboardKey.goBack ||
                event.logicalKey == LogicalKeyboardKey.escape) {
              context.go('/home');
              return KeyEventResult.handled;
            }
          }
          return KeyEventResult.ignored;
        },
        child: Row(
          children: [
            // Sidebar
            Container(
              width: 300,
              color: AppColors.surface,
              padding: const EdgeInsets.all(32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Back button
                  TVFocusable(
                    autofocus: true,
                    onSelect: () => context.go('/home'),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white12,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.arrow_back, color: Colors.white, size: 20),
                          SizedBox(width: 12),
                          Text(
                            'Back',
                            style: TextStyle(color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  const Text(
                    'Settings',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 32),

                  _SettingsNavItem(
                    icon: Icons.dns_outlined,
                    title: 'Server',
                    isSelected: true,
                    onSelect: () {},
                  ),

                  _SettingsNavItem(
                    icon: Icons.person_outline,
                    title: 'Account',
                    onSelect: () {},
                  ),

                  _SettingsNavItem(
                    icon: Icons.play_circle_outline,
                    title: 'Playback',
                    onSelect: () {},
                  ),

                  _SettingsNavItem(
                    icon: Icons.info_outline,
                    title: 'About',
                    onSelect: () {},
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(48),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Server Connection',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Server info card
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: AppColors.cardBackground,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: AppColors.success.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(24),
                                ),
                                child: const Icon(
                                  Icons.check_circle,
                                  color: AppColors.success,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Connected to Jellyfin',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    AppConfig.jellyfinUrl ?? 'Not configured',
                                    style: const TextStyle(
                                      color: Colors.white54,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),

                          const SizedBox(height: 24),

                          // Jellyseerr section
                          const Text(
                            'Jellyseerr',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            AppConfig.isJellyseerrConfigured
                                ? 'Connected: ${AppConfig.jellyseerrUrl}'
                                : 'Not configured',
                            style: const TextStyle(
                              color: Colors.white54,
                              fontSize: 14,
                            ),
                          ),

                          const SizedBox(height: 24),

                          // Configure Jellyseerr button
                          TVFocusable(
                            onSelect: () => _showJellyseerrDialog(context),
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 14,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'Configure Jellyseerr',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 48),

                    // Sign out button
                    TVFocusable(
                      onSelect: () => _signOut(context),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.error),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.logout, color: AppColors.error, size: 20),
                            SizedBox(width: 12),
                            Text(
                              'Sign Out',
                              style: TextStyle(
                                color: AppColors.error,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 48),

                    // App info
                    const Text(
                      'Streamflix v1.0.0',
                      style: TextStyle(color: Colors.white38),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'A Netflix-like client for Jellyfin',
                      style: TextStyle(color: Colors.white24, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showJellyseerrDialog(BuildContext context) {
    // In a real app, show a dialog to configure Jellyseerr
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Jellyseerr configuration dialog would open here'),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  void _signOut(BuildContext context) async {
    await AppConfig.clearAll();
    if (context.mounted) {
      context.go('/login');
    }
  }
}

class _SettingsNavItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool isSelected;
  final VoidCallback onSelect;

  const _SettingsNavItem({
    required this.icon,
    required this.title,
    this.isSelected = false,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: TVFocusable(
        onSelect: onSelect,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary.withOpacity(0.2) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: isSelected
                ? Border.all(color: AppColors.primary.withOpacity(0.5))
                : null,
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: isSelected ? AppColors.primary : Colors.white70,
                size: 20,
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.white70,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
