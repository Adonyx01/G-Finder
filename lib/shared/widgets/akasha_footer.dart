import 'package:flutter/material.dart';

import '../../core/theme.dart';

class AkashaFooter extends StatelessWidget {
  const AkashaFooter({
    super.key,
    this.light = false,
    this.padding = const EdgeInsets.symmetric(vertical: 16),
  });

  final bool light;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final color = light
        ? Colors.white.withValues(alpha: 0.58)
        : context.chezMoiColors.textSecondary.withValues(alpha: 0.72);

    return Padding(
      padding: padding,
      child: Center(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            '© 2026, ChezMoi., Dataplay.',
            maxLines: 1,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
      ),
    );
  }
}
