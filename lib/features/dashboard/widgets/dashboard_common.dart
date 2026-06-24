import 'package:flutter/material.dart';

import '../../../core/theme.dart';

class DashboardPageHeader extends StatelessWidget {
  const DashboardPageHeader({required this.title, super.key});

  final String title;

  @override
  Widget build(BuildContext context) {
    final colors = context.chezMoiColors;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        20,
        MediaQuery.paddingOf(context).top + 16,
        20,
        22,
      ),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(
          bottom: BorderSide(color: colors.border.withValues(alpha: 0.7)),
        ),
      ),
      child: Text(
        title,
        style: TextStyle(
          color: colors.textPrimary,
          fontSize: 25,
          fontWeight: FontWeight.w600,
          height: 1.12,
        ),
      ),
    );
  }
}

class DashboardCenteredState extends StatelessWidget {
  const DashboardCenteredState({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: child,
        ),
      ),
    );
  }
}

class DashboardErrorState extends StatelessWidget {
  const DashboardErrorState({
    required this.message,
    required this.onRetry,
    super.key,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final colors = context.chezMoiColors;
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.wifi_off_rounded, size: 48, color: colors.danger),
          const SizedBox(height: 14),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Réessayer'),
          ),
        ],
      ),
    );
  }
}
