import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'package:qui/gen/assets.gen.dart';
import 'package:qui/gen/fonts.gen.dart';
import 'package:qui/src/theme/qui_theme.dart';
import 'package:qui/src/theme/qui_theme_context.dart';

/// Cataquí search bar with resting and active visual modes.
///
/// In resting mode the bar shows a soft gray background with a magnifier
/// icon and a placeholder.  When the field is focused or contains text it
/// switches to active mode, displaying a brand-colored border and shadow
/// and replacing the magnifier with a clear (cross) icon.
///
/// Set [isFrostedGlass] to true for a blurred translucent background that
/// lets underlying content show through with a blur effect.
///
/// ```dart
/// QuiSearchBar(
///   placeholder: 'Buscar oportunidades...',
///   onChanged: (value) => print(value),
/// )
/// ```
class QuiSearchBar extends StatefulWidget {
  /// Creates a Cataquí search bar.
  const QuiSearchBar({
    super.key,
    this.placeholder = 'Search',
    this.onChanged,
    this.onSubmitted,
    this.controller,
    this.isFrostedGlass = false,
  });

  /// Placeholder text displayed when the field is empty and unfocused.
  final String placeholder;

  /// Called whenever the text value changes.
  final ValueChanged<String>? onChanged;

  /// Called when the user submits the search (e.g. presses enter).
  final ValueChanged<String>? onSubmitted;

  /// An optional external [TextEditingController].
  ///
  /// When null an internal controller is created and disposed automatically.
  final TextEditingController? controller;

  /// Whether the search bar has a frosted glass (blurred translucent)
  /// background instead of the solid resting color.
  final bool isFrostedGlass;

  @override
  State<QuiSearchBar> createState() => _QuiSearchBarState();
}

class _QuiSearchBarState extends State<QuiSearchBar> {
  static const _horizontalPadding = 20.0;

  late final FocusNode _focusNode;
  late final TextEditingController _controller;

  bool get _isActive => _focusNode.hasFocus || _controller.text.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode()..addListener(_onStateChanged);
    _controller = widget.controller ?? TextEditingController();
    _controller.addListener(_onStateChanged);
  }

  @override
  void dispose() {
    _focusNode
      ..removeListener(_onStateChanged)
      ..dispose();

    _controller.removeListener(_onStateChanged);

    if (widget.controller == null) _controller.dispose();

    super.dispose();
  }

  void _onStateChanged() {
    setState(() {});
  }

  void _onIconTap() {
    final wasActive = _isActive;

    if (_controller.text.isNotEmpty) {
      _controller.clear();
      widget.onChanged?.call('');
    }

    if (wasActive) {
      _focusNode.unfocus();
    } else {
      _focusNode.requestFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.qui.colors;
    final isActive = _isActive;

    final icon = AnimatedSwitcher(
      duration: 250.ms,
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      transitionBuilder: (child, animation) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1, 0),
            end: Offset.zero,
          ).animate(animation),
          child: FadeTransition(opacity: animation, child: child),
        );
      },
      child: SizedBox(
        key: ValueKey(isActive),
        width: 20,
        height: 20,
        child: isActive
            ? Center(
                child: Assets.icons.cross.svg(
                  width: 16,
                  height: 16,
                  package: 'qui',
                  colorFilter: ColorFilter.mode(
                    colors.primary,
                    BlendMode.srcIn,
                  ),
                ),
              )
            : Center(
                child: Assets.icons.magnifierGlass.svg(
                  width: 20,
                  height: 20,
                  package: 'qui',
                  colorFilter: ColorFilter.mode(
                    colors.searchBarPlaceholder,
                    BlendMode.srcIn,
                  ),
                ),
              ),
      ),
    );

    Widget content = Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: TextField(
            controller: _controller,
            focusNode: _focusNode,
            onChanged: widget.onChanged,
            onSubmitted: (value) {
              widget.onSubmitted?.call(value);
              _focusNode.unfocus();
            },
            textInputAction: TextInputAction.search,
            textAlignVertical: TextAlignVertical.center,
            expands: true,
            maxLines: null,
            decoration: InputDecoration(
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: _horizontalPadding,
              ),
              hintText: widget.placeholder,
              hintStyle: TextStyle(
                color: colors.searchBarPlaceholder,
                fontFamily: FontFamily.inter,
              ),
            ),
            style: const TextStyle(fontFamily: FontFamily.inter),
          ),
        ),
        GestureDetector(
          onTap: _onIconTap,
          behavior: HitTestBehavior.opaque,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.only(right: _horizontalPadding),
              child: icon,
            ),
          ),
        ),
      ],
    );

    if (widget.isFrostedGlass) {
      content = ClipRRect(
        borderRadius: BorderRadius.circular(27.5),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: ColoredBox(
            color: colors.frostedGlassBackground,
            child: content,
          ),
        ),
      );
    }

    return TapRegion(
      onTapOutside: (_) => _focusNode.unfocus(),
      child: Container(
        height: 65,
        clipBehavior: Clip.antiAlias,
        decoration: ShapeDecoration(
          color: widget.isFrostedGlass
              ? colors.background.withValues(alpha: 0.6)
              : colors.searchBarBackground,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(27.5),
            side: widget.isFrostedGlass
                ? BorderSide(color: colors.frostedGlassBorder)
                : BorderSide.none,
          ),
        ),
        child: content,
      ),
    );
  }
}

/// Preview of the [QuiSearchBar] widget in its resting state.
@Preview(name: 'QuiSearchBar', group: 'Inputs')
Widget quiSearchBarPreview() {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: QuiTheme.light(primaryColor: const Color(0xFFFF4A4B)),
    home: const Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            QuiSearchBar(placeholder: 'Search for an opportunity...'),
            SizedBox(height: 16),
            SizedBox(width: 280, child: QuiSearchBar(placeholder: 'Short')),
          ],
        ),
      ),
    ),
  );
}

/// Preview of the [QuiSearchBar] with frosted glass background.
@Preview(name: 'QuiSearchBar — Frosted', group: 'Inputs')
Widget quiSearchBarFrostedPreview() {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: QuiTheme.light(primaryColor: const Color(0xFFFF4A4B)),
    home: Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFFF6B6B), Color(0xFF4ECDC4), Color(0xFFFFE66D)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: const Padding(
          padding: EdgeInsets.all(20),
          child: Column(
            children: [
              SizedBox(height: 60),
              QuiSearchBar(
                placeholder: 'Buscar oportunidades...',
                isFrostedGlass: true,
              ),
              SizedBox(height: 16),
              SizedBox(
                width: 280,
                child: QuiSearchBar(placeholder: 'Short', isFrostedGlass: true),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
