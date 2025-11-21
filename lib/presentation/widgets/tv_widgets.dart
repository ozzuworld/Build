import 'package:flutter/material.dart';

/// Specialized TV focusable widget for content cards (movies, shows, etc.)
/// Optimized for media content display with predefined dimensions and scaling
class TVFocusableCard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final bool autofocus;
  final double width;
  final double height;
  final double focusScale;
  final BorderRadius borderRadius;

  const TVFocusableCard({
    super.key,
    required this.child,
    this.onTap,
    this.autofocus = false,
    this.width = 120,
    this.height = 180,
    this.focusScale = 1.08,
    this.borderRadius = const BorderRadius.all(Radius.circular(8)),
  });

  @override
  State<TVFocusableCard> createState() => _TVFocusableCardState();
}

class _TVFocusableCardState extends State<TVFocusableCard> {
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    return Focus(
      autofocus: widget.autofocus,
      onFocusChange: (focused) {
        setState(() => _isFocused = focused);
      },
      onKeyEvent: (node, event) {
        if (_isFocused &&
            widget.onTap != null &&
            (event.logicalKey.keyLabel == 'Select' ||
                event.logicalKey.keyLabel == 'Enter')) {
          widget.onTap!();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: widget.width,
        height: widget.height,
        transform: Matrix4.identity()
          ..scale(_isFocused ? widget.focusScale : 1.0),
        transformAlignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: widget.borderRadius,
          border: _isFocused
              ? Border.all(
                  color: Colors.white,
                  width: 3,
                )
              : null,
          boxShadow: _isFocused
              ? [
                  BoxShadow(
                    color: Colors.white.withOpacity(0.3),
                    blurRadius: 12,
                    spreadRadius: 2,
                  ),
                ]
              : null,
        ),
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: widget.borderRadius,
          child: widget.child,
        ),
      ),
    );
  }
}

/// Specialized TV focusable widget for buttons
/// Optimized for interactive controls with predefined styling
class TVFocusableButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final bool autofocus;
  final double? width;
  final double? height;
  final double focusScale;
  final BorderRadius borderRadius;
  final Color? backgroundColor;
  final Color focusBorderColor;
  final EdgeInsetsGeometry padding;

  const TVFocusableButton({
    super.key,
    required this.child,
    this.onTap,
    this.autofocus = false,
    this.width,
    this.height,
    this.focusScale = 1.05,
    this.borderRadius = const BorderRadius.all(Radius.circular(8)),
    this.backgroundColor,
    this.focusBorderColor = Colors.blueAccent,
    this.padding = const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
  });

  @override
  State<TVFocusableButton> createState() => _TVFocusableButtonState();
}

class _TVFocusableButtonState extends State<TVFocusableButton> {
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    return Focus(
      autofocus: widget.autofocus,
      onFocusChange: (focused) {
        setState(() => _isFocused = focused);
      },
      onKeyEvent: (node, event) {
        if (_isFocused &&
            widget.onTap != null &&
            (event.logicalKey.keyLabel == 'Select' ||
                event.logicalKey.keyLabel == 'Enter')) {
          widget.onTap!();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: widget.width,
        height: widget.height,
        transform: Matrix4.identity()
          ..scale(_isFocused ? widget.focusScale : 1.0),
        transformAlignment: Alignment.center,
        padding: widget.padding,
        decoration: BoxDecoration(
          color: widget.backgroundColor,
          borderRadius: widget.borderRadius,
          border: _isFocused
              ? Border.all(
                  color: widget.focusBorderColor,
                  width: 2,
                )
              : null,
          boxShadow: _isFocused
              ? [
                  BoxShadow(
                    color: widget.focusBorderColor.withOpacity(0.4),
                    blurRadius: 10,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: widget.borderRadius,
          child: Center(child: widget.child),
        ),
      ),
    );
  }
}

/// Specialized TV focusable widget for list items
/// Optimized for horizontal rows with full-width highlighting
class TVFocusableListItem extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final bool autofocus;
  final Color? backgroundColor;
  final Color focusColor;
  final EdgeInsetsGeometry padding;

  const TVFocusableListItem({
    super.key,
    required this.child,
    this.onTap,
    this.autofocus = false,
    this.backgroundColor,
    this.focusColor = const Color(0xFF1E88E5),
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
  });

  @override
  State<TVFocusableListItem> createState() => _TVFocusableListItemState();
}

class _TVFocusableListItemState extends State<TVFocusableListItem> {
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    return Focus(
      autofocus: widget.autofocus,
      onFocusChange: (focused) {
        setState(() => _isFocused = focused);
      },
      onKeyEvent: (node, event) {
        if (_isFocused &&
            widget.onTap != null &&
            (event.logicalKey.keyLabel == 'Select' ||
                event.logicalKey.keyLabel == 'Enter')) {
          widget.onTap!();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: widget.padding,
        decoration: BoxDecoration(
          color: _isFocused ? widget.focusColor : widget.backgroundColor,
          borderRadius: BorderRadius.circular(8),
        ),
        child: InkWell(
          onTap: widget.onTap,
          child: widget.child,
        ),
      ),
    );
  }
}
