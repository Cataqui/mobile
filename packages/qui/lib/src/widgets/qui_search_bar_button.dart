import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:qui/gen/fonts.gen.dart';
import 'package:qui/src/icons/qui_icons.dart';
import 'package:qui/src/theme/qui_theme.dart';
import 'package:qui/src/theme/qui_theme_context.dart';

/// QUI search bar button that opens search through a tap action.
///
/// The button is intentionally display-only. Use [onTap] to open the real
/// search flow in the consuming app.
///
/// ```dart
/// QuiSearchBarButton(
///   placeholder: 'Start your search',
///   onTap: () {},
/// )
/// ```
class QuiSearchBarButton extends StatelessWidget {
  /// Creates a QUI search bar button.
  const QuiSearchBarButton({super.key, this.placeholder = 'Start your search', this.onTap});

  /// The default height of the search bar button.
  static const double searchBarHeight = 60;

  /// Text displayed in the center of the search bar button.
  final String placeholder;

  /// Called when the search bar button is tapped.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    const borderRadius = BorderRadius.all(Radius.circular(34));

    return Semantics(
      button: true,
      label: placeholder,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: borderRadius,
          boxShadow: [BoxShadow(color: context.qui.colors.searchBarButtonShadow, blurRadius: 24)],
        ),
        child: Material(
          color: context.qui.colors.searchBarButtonBackground,
          shape: RoundedRectangleBorder(
            borderRadius: borderRadius,
            side: BorderSide(color: context.qui.colors.background),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            borderRadius: borderRadius,
            child: SizedBox(
              height: searchBarHeight,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    QuiIcons.instance.build((assets) => assets.magnifierGlass,
                      width: 18,
                      height: 18,
                      colorFilter: ColorFilter.mode(context.qui.colors.textPrimary, BlendMode.srcIn),
                    ),
                    const SizedBox(width: 10),
                    Flexible(
                      child: Text(
                        placeholder,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: context.qui.colors.textPrimary,
                          fontFamily: FontFamily.inter,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Preview of the [QuiSearchBarButton] widget in its resting state.
@Preview(name: 'QuiSearchBarButton', group: 'Inputs')
Widget quiSearchBarButtonPreview() {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: QuiTheme.light(primaryColor: const Color(0xFFFF4A4B)),
    home: const Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            QuiSearchBarButton(placeholder: 'Search for an opportunity...'),
            SizedBox(height: 16),
            SizedBox(width: 280, child: QuiSearchBarButton(placeholder: 'Short')),
          ],
        ),
      ),
    ),
  );
}
