import 'package:flutter/material.dart';

import '../../../core/theme.dart';

class DashboardBottomNavBar extends StatelessWidget {
  const DashboardBottomNavBar({
    super.key,
    required this.selectedIndex,
    required this.onSelected,
    this.items = defaultItems,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final List<DashboardBottomNavItem> items;

  static const defaultItems = [
    DashboardBottomNavItem(
      index: 0,
      icon: Icons.home_outlined,
      selectedIcon: Icons.home_rounded,
      label: 'Accueil',
    ),
    DashboardBottomNavItem(
      index: 1,
      icon: Icons.map_outlined,
      selectedIcon: Icons.map_rounded,
      label: 'Carte',
    ),
    DashboardBottomNavItem(
      index: 2,
      icon: Icons.newspaper_outlined,
      selectedIcon: Icons.newspaper_rounded,
      label: 'Nouveautés',
    ),
    DashboardBottomNavItem(
      index: 3,
      icon: Icons.favorite_border_rounded,
      selectedIcon: Icons.favorite_rounded,
      label: 'Favoris',
    ),
    DashboardBottomNavItem(
      index: 4,
      icon: Icons.settings_outlined,
      selectedIcon: Icons.settings_rounded,
      label: 'Paramètres',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final colors = context.chezMoiColors;
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(8, 8, 8, 8 + bottomInset),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(top: BorderSide(color: colors.border)),
        boxShadow: [
          BoxShadow(
            color: colors.navy.withValues(alpha: 0.10),
            blurRadius: 18,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: Row(
        children: items
            .map(
              (item) => _NavItem(
                index: item.index,
                selectedIndex: selectedIndex,
                icon: item.icon,
                selectedIcon: item.selectedIcon,
                label: item.label,
                onSelected: onSelected,
              ),
            )
            .toList(growable: false),
      ),
    );
  }
}

class DashboardBottomNavItem {
  const DashboardBottomNavItem({
    required this.index,
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });

  final int index;
  final IconData icon;
  final IconData selectedIcon;
  final String label;
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.index,
    required this.selectedIndex,
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.onSelected,
  });

  final int index;
  final int selectedIndex;
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final colors = context.chezMoiColors;
    final selected = index == selectedIndex;

    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => onSelected(index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          margin: const EdgeInsets.symmetric(horizontal: 2),
          padding: const EdgeInsets.symmetric(vertical: 7),
          decoration: BoxDecoration(
            color: selected ? colors.lightBlueAccent : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                selected ? selectedIcon : icon,
                size: 22,
                color: selected ? colors.navy : colors.textSecondary,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: selected ? colors.navy : colors.textSecondary,
                  fontSize: 10,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
