import 'package:flutter/material.dart';

import 'brand_assets.dart';
import 'theme.dart';

/// The ChezMoi "C" icon mark.
class ChezMoiIcon extends StatelessWidget {
  const ChezMoiIcon({super.key, this.size = 72});

  final double size;

  @override
  Widget build(BuildContext context) {
    return BrandAssetImage(
      candidates: BrandAssets.iconCandidates,
      height: size,
      width: size,
      fallback: SizedBox(height: size, width: size),
    );
  }
}

/// The ChezMoi wordmark logo image.
class ChezMoiLogoMark extends StatelessWidget {
  const ChezMoiLogoMark({
    super.key,
    this.height = 40,
    this.lightOnDark = false,
    this.showPoweredBy = false,
  });

  final double height;
  final bool lightOnDark;
  final bool showPoweredBy;

  @override
  Widget build(BuildContext context) {
    final colors = context.chezMoiColors;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        BrandAssetImage(
          candidates: BrandAssets.logoCandidates,
          height: height,
          fallback: SizedBox(height: height),
        ),
        if (showPoweredBy) ...[
          const SizedBox(height: 8),
          Text(
            'Powered by LOKA',
            style: TextStyle(
              fontSize: height * 0.28,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.4,
              color: lightOnDark
                  ? Colors.white.withValues(alpha: 0.75)
                  : colors.textSecondary,
            ),
          ),
        ],
      ],
    );
  }
}

/// Stacked C icon + wordmark, used on welcome and branding surfaces.
class ChezMoiBrandStack extends StatelessWidget {
  const ChezMoiBrandStack({
    super.key,
    this.iconSize = 72,
    this.logoHeight = 56,
    this.showPoweredBy = false,
    this.lightOnDark = false,
    this.spacing = 16,
  });

  final double iconSize;
  final double logoHeight;
  final bool showPoweredBy;
  final bool lightOnDark;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ChezMoiLogoMark(
          height: logoHeight,
          lightOnDark: lightOnDark,
          showPoweredBy: showPoweredBy,
        ),
      ],
    );
  }
}

// Kept for backward compatibility in auth screens.
enum ChezMoiLogoSize { small, medium, large }

class ChezMoiLogo extends StatelessWidget {
  const ChezMoiLogo({
    super.key,
    this.showPoweredBy = false,
    this.size = ChezMoiLogoSize.medium,
    this.lightOnDark = true,
  });

  final bool showPoweredBy;
  final ChezMoiLogoSize size;
  final bool lightOnDark;

  @override
  Widget build(BuildContext context) {
    final logoHeight = switch (size) {
      ChezMoiLogoSize.large => 78.0,
      ChezMoiLogoSize.medium => 62.0,
      ChezMoiLogoSize.small => 48.0,
    };

    return ChezMoiLogoMark(
      height: logoHeight,
      lightOnDark: lightOnDark,
      showPoweredBy: showPoweredBy,
    );
  }
}
