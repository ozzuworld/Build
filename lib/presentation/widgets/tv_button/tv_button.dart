import 'package:flutter/material.dart';

import '../../../core/navigation/tv_focus_manager.dart';
import '../../../core/theme/app_colors.dart';

enum TVButtonVariant { primary, secondary, ghost, danger }

class TVButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onSelect;
  final TVButtonVariant variant;
  final bool autofocus;
  final double? width;
  final bool isLoading;

  const TVButton({
    super.key,
    required this.label,
    this.icon,
    this.onSelect,
    this.variant = TVButtonVariant.primary,
    this.autofocus = false,
    this.width,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return TVFocusable(
      autofocus: autofocus,
      onSelect: isLoading ? null : onSelect,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        width: width,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        decoration: BoxDecoration(
          color: _backgroundColor,
          borderRadius: BorderRadius.circular(4),
          border: _border,
        ),
        child: Row(
          mainAxisSize: width == null ? MainAxisSize.min : MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isLoading) ...[
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: _foregroundColor,
                  strokeWidth: 2,
                ),
              ),
            ] else ...[
              if (icon != null) ...[
                Icon(icon, color: _foregroundColor, size: 22),
                const SizedBox(width: 10),
              ],
              Text(
                label,
                style: TextStyle(
                  color: _foregroundColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color get _backgroundColor {
    switch (variant) {
      case TVButtonVariant.primary:
        return Colors.white;
      case TVButtonVariant.secondary:
        return Colors.white24;
      case TVButtonVariant.ghost:
        return Colors.transparent;
      case TVButtonVariant.danger:
        return Colors.transparent;
    }
  }

  Color get _foregroundColor {
    switch (variant) {
      case TVButtonVariant.primary:
        return Colors.black;
      case TVButtonVariant.secondary:
        return Colors.white;
      case TVButtonVariant.ghost:
        return Colors.white;
      case TVButtonVariant.danger:
        return AppColors.error;
    }
  }

  Border? get _border {
    switch (variant) {
      case TVButtonVariant.ghost:
        return Border.all(color: Colors.white54);
      case TVButtonVariant.danger:
        return Border.all(color: AppColors.error);
      default:
        return null;
    }
  }
}

/// Icon-only button for TV
class TVIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onSelect;
  final bool autofocus;
  final Color? backgroundColor;
  final Color? iconColor;
  final double size;

  const TVIconButton({
    super.key,
    required this.icon,
    this.onSelect,
    this.autofocus = false,
    this.backgroundColor,
    this.iconColor,
    this.size = 48,
  });

  @override
  Widget build(BuildContext context) {
    return TVFocusable(
      autofocus: autofocus,
      onSelect: onSelect,
      borderRadius: BorderRadius.circular(size / 2),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: backgroundColor ?? Colors.white24,
          borderRadius: BorderRadius.circular(size / 2),
        ),
        child: Icon(
          icon,
          color: iconColor ?? Colors.white,
          size: size * 0.5,
        ),
      ),
    );
  }
}
