import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'backend_mode.dart';
import 'theme.dart';

class ChezMoiBackgroundLayer extends StatelessWidget {
  const ChezMoiBackgroundLayer({
    super.key,
    this.blurSigma = 1.5,
    this.imageOpacity = 0.68,
  });

  static const assetPaths = [
    'assets/images/villa1.jpg',
    'assets/images/villa2.jpg',
    'assets/images/villa3.jpg',
    'assets/images/villas.jpg',
    'assets/images/pool.jpg',
  ];

  static final assetPath = assetPaths[math.Random().nextInt(assetPaths.length)];

  final double blurSigma;
  final double imageOpacity;

  @override
  Widget build(BuildContext context) {
    final colors = context.chezMoiColors;

    if (BackendMode.isTemplate) {
      return DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              colors.background,
              colors.surface,
              colors.primaryBlue.withValues(alpha: 0.10),
            ],
          ),
        ),
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        ColoredBox(color: colors.background),
        ImageFiltered(
          imageFilter: ui.ImageFilter.blur(
            sigmaX: blurSigma,
            sigmaY: blurSigma,
          ),
          child: Opacity(
            opacity: imageOpacity,
            child: Image.asset(
              assetPath,
              fit: BoxFit.cover,
              alignment: Alignment.center,
            ),
          ),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                colors.background.withValues(alpha: 0.38),
                colors.background.withValues(alpha: 0.50),
                colors.background.withValues(alpha: 0.68),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
