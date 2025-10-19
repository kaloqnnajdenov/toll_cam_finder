import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:toll_cam_finder/core/app_colors.dart';
import 'package:toll_cam_finder/core/app_messages.dart';
import 'package:toll_cam_finder/core/constants.dart';
import 'package:url_launcher/url_launcher.dart';

/// Single source of truth for the base map layer + OSM attribution,
/// with adjustable vertical placement.
class BaseTileLayer extends StatelessWidget {
  const BaseTileLayer({
    super.key,
    this.attributionLeft = AppConstants.mapAttributionLeftInset,
    this.attributionBottom = AppConstants.mapAttributionBottomInset,
    this.respectSafeArea = true,
    this.overlapBottomPx =
        AppConstants.mapAttributionOverlap, // positive moves it LOWER (toward/into inset)
  });

  /// Distance from the left screen edge.
  final double attributionLeft;

  /// Extra padding from the bottom edge *before* safe-area is considered.
  final double attributionBottom;

  /// If true (default), keeps the label above system insets (home indicator).
  final bool respectSafeArea;

  /// Positive values push the label DOWN by this many pixels
  /// (useful to sit closer to/inside the home-indicator area).
  final double overlapBottomPx;

  static final Uri _osmCopyrightUri =
      Uri.parse('https://www.openstreetmap.org/copyright');

  Future<void> _openOsmCopyright(BuildContext context) async {
    try {
      final ok = await launchUrl(
        _osmCopyrightUri,
        mode: LaunchMode.externalApplication,
      );
      if (!ok) _showLaunchError(context);
    } catch (_) {
      _showLaunchError(context);
    }
  }

  static void _showLaunchError(BuildContext context) {
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
      SnackBar(
        content: Text(AppMessages.osmCopyrightLaunchFailed),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // How much the OS reserves at the bottom (e.g., iOS home indicator).
    final safeBottom = respectSafeArea ? MediaQuery.of(context).padding.bottom : 0.0;

    // Final distance from the physical bottom of the screen.
    final effectiveBottom =
        (attributionBottom + safeBottom - overlapBottomPx).clamp(0.0, double.infinity);

    return Stack(
      children: [
        TileLayer(
          urlTemplate: AppConstants.mapURL,
          userAgentPackageName: AppConstants.userAgentPackageName,
        ),
        Positioned(
          left: attributionLeft,
          bottom: effectiveBottom,
          child: _OsmAttributionText(
            onLinkTap: () => _openOsmCopyright(context),
          ),
        ),
      ],
    );
  }
}

class _OsmAttributionText extends StatelessWidget {
  final VoidCallback onLinkTap;
  const _OsmAttributionText({required this.onLinkTap});

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppColors.of(context);
    final baseStyle = TextStyle(
      fontSize: AppConstants.mapAttributionFontSize,
      color: palette.secondaryText,
      height: AppConstants.mapAttributionLineHeight,
    );
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final linkStyle = baseStyle.copyWith(
      color: palette.secondaryText,
      decoration: TextDecoration.underline,
      fontWeight: FontWeight.w600,
    );

    return Container(
      child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: RichText(
        text: TextSpan(
        style: baseStyle,
        children: [
          const TextSpan(text: 'Map data from '),
          TextSpan(
          text: 'OpenStreetMap',
          style: linkStyle,
          recognizer: TapGestureRecognizer()..onTap = onLinkTap,
          ),
        ],
        ),
      ),
      ),
    );
  }
}
