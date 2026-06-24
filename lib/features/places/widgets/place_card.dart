import 'package:flutter/material.dart';

import '../../../core/theme.dart';
import '../models/place.dart';

const _priceDisplayColor = Color(0xFF1677E8);

class PlaceCard extends StatelessWidget {
  const PlaceCard({
    super.key,
    required this.listing,
    required this.onTap,
    this.compact = false,
    this.saved = false,
    this.onSaveTap,
    this.actionIcon,
    this.actionSelected,
    this.actionColor,
    this.actionTooltip,
    this.showLocation = true,
  });

  final Place listing;
  final VoidCallback onTap;
  final bool compact;
  final bool saved;
  final VoidCallback? onSaveTap;
  final IconData? actionIcon;
  final bool? actionSelected;
  final Color? actionColor;
  final String? actionTooltip;
  final bool showLocation;

  @override
  Widget build(BuildContext context) {
    final colors = context.chezMoiColors;
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final maxHeight = constraints.maxHeight.isFinite
              ? constraints.maxHeight
              : 360.0;
          final imageHeight = compact
              ? (maxHeight * 0.44).clamp(108.0, 148.0)
              : (maxHeight * 0.48).clamp(180.0, 265.0);

          return Container(
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: [
                BoxShadow(
                  color: colors.navy.withValues(alpha: 0.045),
                  blurRadius: 14,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: imageHeight,
                  width: double.infinity,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      _ListingImage(url: listing.coverImageUrl),
                      const _ImageShade(),
                      Positioned(
                        left: 12,
                        top: 12,
                        child: _ImageBadge(
                          label:
                              listing.starRatingLabel ??
                              listing.subtypeLabel,
                        ),
                      ),
                      if (listing.isFeatured)
                        const Positioned(
                          left: 12,
                          bottom: 12,
                          child: _ImageBadge(label: 'À la une'),
                        ),
                      if (!listing.hasCoordinates)
                        const Positioned(
                          left: 12,
                          bottom: 12,
                          child: _ImageBadge(label: 'Carte à préciser'),
                        ),
                      if (onSaveTap != null)
                        Positioned(
                          right: 10,
                          top: 10,
                          child: _IconBubble(
                            icon:
                                actionIcon ??
                                (saved
                                    ? Icons.favorite_rounded
                                    : Icons.favorite_border_rounded),
                            selected: actionSelected ?? saved,
                            color: actionColor ?? const Color(0xFFFF5A5F),
                            tooltip:
                                actionTooltip ??
                                (saved
                                    ? 'Retirer des favoris'
                                    : 'Ajouter aux favoris'),
                            onTap: onSaveTap!,
                          ),
                        ),
                    ],
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      compact ? 11 : 14,
                      compact ? 10 : 14,
                      compact ? 11 : 14,
                      compact ? 11 : 13,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          listing.subtypeLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: colors.textSecondary,
                            fontSize: compact ? 10.5 : 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: compact ? 6 : 7),
                        SizedBox(
                          height: compact ? 38 : 44,
                          child: Text(
                            listing.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: colors.textPrimary,
                              fontSize: compact ? 13.5 : 18,
                              height: 1.2,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        if (showLocation) ...[
                          SizedBox(height: compact ? 7 : 8),
                          SizedBox(
                            height: compact ? 18 : 20,
                            child: Row(
                              children: [
                                Icon(
                                  listing.hasCoordinates
                                      ? Icons.location_on_rounded
                                      : Icons.location_off_outlined,
                                  size: compact ? 14 : 15,
                                  color: colors.textSecondary,
                                ),
                                const SizedBox(width: 5),
                                Expanded(
                                  child: Text(
                                    listing.locationLabel,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: colors.textSecondary,
                                      fontSize: compact ? 12 : 13,
                                      height: 1.25,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        SizedBox(height: compact ? 7 : 10),
                        SizedBox(
                          height: compact ? 23 : 28,
                          child: listing.guestRatingLabel != null
                              ? _GuestRatingLine(
                                  listing: listing,
                                  compact: compact,
                                )
                              : _FactsLine(
                                  facts: [
                                    if (listing.capacityLabel != null)
                                      _FactItem(
                                        Icons.group_outlined,
                                        listing.capacityLabel!,
                                      ),
                                    _FactItem(
                                      Icons.hotel_outlined,
                                      listing.subtypeLabel,
                                    ),
                                  ],
                                  compact: compact,
                                ),
                        ),
                        const Spacer(),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    listing.priceLabel,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: _priceDisplayColor,
                                      fontSize: compact ? 16 : 20,
                                      height: 1.05,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  Text(
                                    'par nuit',
                                    style: TextStyle(
                                      color: colors.textSecondary,
                                      fontSize: compact ? 10.5 : 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (listing.distanceLabel != null)
                              _DistancePill(
                                label: listing.distanceLabel!,
                                compact: compact,
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _GuestRatingLine extends StatelessWidget {
  const _GuestRatingLine({required this.listing, required this.compact});

  final Place listing;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final score = listing.guestRatingLabel;
    if (score == null) return const SizedBox.shrink();
    final mention = listing.guestRatingMention;
    final reviews = listing.reviewCountLabel;
    final caption = [?mention, ?reviews].join(' · ');

    return Row(
      children: [
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 6 : 7,
            vertical: compact ? 3 : 4,
          ),
          decoration: BoxDecoration(
            color: _priceDisplayColor,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            score,
            style: TextStyle(
              color: Colors.white,
              fontSize: compact ? 11.5 : 13,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        const SizedBox(width: 7),
        Expanded(
          child: Text(
            caption,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: const Color(0xFF334155),
              fontSize: compact ? 11 : 12.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _ListingImage extends StatelessWidget {
  const _ListingImage({this.url});

  final String? url;

  @override
  Widget build(BuildContext context) {
    final imageUrl = url;

    if (imageUrl != null && imageUrl.isNotEmpty) {
      return Image.network(
        imageUrl,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return const _ImagePlaceholder();
        },
      );
    }
    return const _ImagePlaceholder();
  }
}

class _ImageShade extends StatelessWidget {
  const _ImageShade();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withValues(alpha: 0.10),
            Colors.transparent,
            Colors.black.withValues(alpha: 0.14),
          ],
        ),
      ),
    );
  }
}

class _ImagePlaceholder extends StatelessWidget {
  const _ImagePlaceholder();

  @override
  Widget build(BuildContext context) {
    final colors = context.chezMoiColors;
    return Container(
      color: const Color(0xFFEAF3F8),
      child: Center(
        child: Container(
          width: 74,
          height: 74,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.86),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: colors.border),
          ),
          child: Icon(
            Icons.hotel_outlined,
            size: 38,
            color: colors.primaryBlue.withValues(alpha: 0.78),
          ),
        ),
      ),
    );
  }
}

class _ImageBadge extends StatelessWidget {
  const _ImageBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = context.chezMoiColors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(999),
        boxShadow: [
          BoxShadow(
            color: colors.navy.withValues(alpha: 0.10),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Text(
        label,
        style: TextStyle(
          color: colors.textPrimary,
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _FactItem {
  const _FactItem(this.icon, this.label);

  final IconData icon;
  final String label;
}

class _FactsLine extends StatelessWidget {
  const _FactsLine({required this.facts, required this.compact});

  final List<_FactItem> facts;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final colors = context.chezMoiColors;
    return Row(
      children: [
        for (final fact in facts.take(3)) ...[
          Flexible(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  fact.icon,
                  size: compact ? 14 : 15,
                  color: colors.textSecondary,
                ),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    fact.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: const Color(0xFF334155),
                      fontSize: compact ? 11.5 : 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (fact != facts.take(3).last)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Text(
                '·',
                style: TextStyle(
                  color: colors.textSecondary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
        ],
      ],
    );
  }
}

class _DistancePill extends StatelessWidget {
  const _DistancePill({required this.label, required this.compact});

  final String label;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final colors = context.chezMoiColors;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 7 : 8,
        vertical: compact ? 4 : 5,
      ),
      decoration: BoxDecoration(
        color: colors.lightBlueAccent.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: colors.navy,
          fontSize: compact ? 10.5 : 11.5,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _IconBubble extends StatelessWidget {
  const _IconBubble({
    required this.icon,
    required this.onTap,
    required this.selected,
    required this.color,
    required this.tooltip,
  });

  final IconData icon;
  final VoidCallback onTap;
  final bool selected;
  final Color color;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: selected
            ? _priceDisplayColor
            : Colors.white.withValues(alpha: 0.95),
        shape: const CircleBorder(),
        elevation: selected ? 4 : 2,
        shadowColor: Colors.black.withValues(alpha: 0.18),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Icon(icon, size: 18, color: selected ? Colors.white : color),
          ),
        ),
      ),
    );
  }
}
