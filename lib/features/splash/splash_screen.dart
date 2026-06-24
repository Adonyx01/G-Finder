import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/app_background.dart';
import '../../core/auth_background.dart';
import '../../core/chezmoi_logo.dart';
import '../../core/theme.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key, this.nextRoute});

  /// When null, the splash decides the route based on the current session.
  final String? nextRoute;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _logoSlide;
  late final Animation<double> _logoOpacity;
  Timer? _navigationTimer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    _logoSlide = Tween<Offset>(begin: const Offset(0, 0.35), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _controller,
            curve: const Interval(0.35, 0.85, curve: Curves.easeOutCubic),
          ),
        );

    _logoOpacity = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.35, 0.85, curve: Curves.easeOut),
    );

    _controller.forward();
    _navigationTimer = Timer(const Duration(milliseconds: 2800), _navigateNext);
  }

  void _navigateNext() {
    if (!mounted) return;
    final destination = widget.nextRoute ?? _resolveInitialRoute();
    context.go(destination);
  }

  String _resolveInitialRoute() {
    return '/loading-dashboard';
  }

  @override
  void dispose() {
    _navigationTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.chezMoiColors;
    final loadingDashboard = widget.nextRoute == '/dashboard';

    return Scaffold(
      backgroundColor: authScaffoldBackgroundColor,
      body: Stack(
        children: [
          const Positioned.fill(
            child: ChezMoiBackgroundLayer(blurSigma: 10, imageOpacity: 0.32),
          ),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SlideTransition(
                  position: _logoSlide,
                  child: FadeTransition(
                    opacity: _logoOpacity,
                    child: ChezMoiLogoMark(
                      height: loadingDashboard ? 168 : 148,
                      lightOnDark: false,
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                FadeTransition(
                  opacity: _logoOpacity,
                  child: Text(
                    'Hôtels, restaurants et activités au Gabon.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      color: colors.textSecondary,
                      fontWeight: FontWeight.w400,
                      letterSpacing: 0.1,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class DashboardLoaderScreen extends StatefulWidget {
  const DashboardLoaderScreen({super.key});

  @override
  State<DashboardLoaderScreen> createState() => _DashboardLoaderScreenState();
}

class _DashboardLoaderScreenState extends State<DashboardLoaderScreen> {
  Timer? _navigationTimer;

  @override
  void initState() {
    super.initState();
    _navigationTimer = Timer(const Duration(milliseconds: 650), () {
      if (mounted) context.go('/dashboard');
    });
  }

  @override
  void dispose() {
    _navigationTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.chezMoiColors;
    return Scaffold(
      backgroundColor: colors.background,
      body: Stack(
        children: [
          const Positioned.fill(
            child: ChezMoiBackgroundLayer(blurSigma: 10, imageOpacity: 0.30),
          ),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const ChezMoiLogoMark(height: 116, lightOnDark: false),
                const SizedBox(height: 24),
                SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.4,
                    color: colors.accent,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
