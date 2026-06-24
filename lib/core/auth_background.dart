import 'package:flutter/material.dart';

import 'app_background.dart';
import 'theme.dart';

/// Same warm background as [SplashScreen] and [WelcomeScreen].
const authScaffoldBackgroundColor = Color(0xFFF7F5F0);

/// Full-screen auth layout with the ChezMoi cream background.
class AuthBackgroundScaffold extends StatelessWidget {
  const AuthBackgroundScaffold({super.key, required this.body});

  final Widget body;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: authScaffoldBackgroundColor,
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          const Positioned.fill(child: ChezMoiBackgroundLayer()),
          SafeArea(child: body),
        ],
      ),
    );
  }
}

/// Centered auth form card used on login, signup, and OTP screens.
class AuthFormCard extends StatelessWidget {
  const AuthFormCard({super.key, required this.child, this.maxWidth = 420});

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    final colors = context.chezMoiColors;
    final width = MediaQuery.sizeOf(context).width;
    final horizontalPadding = width < 380 ? 14.0 : 24.0;
    final cardPadding = width < 380 ? 20.0 : 28.0;

    return Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: horizontalPadding,
          vertical: 24,
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: Material(
            color: colors.elevatedSurface,
            elevation: 8,
            shadowColor: Colors.black.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(8),
            clipBehavior: Clip.antiAlias,
            child: Padding(padding: EdgeInsets.all(cardPadding), child: child),
          ),
        ),
      ),
    );
  }
}
