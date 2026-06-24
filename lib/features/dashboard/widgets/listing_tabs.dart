import 'package:flutter/material.dart';

import '../../../core/theme.dart';
import '../../places/models/place.dart';
import '../../places/widgets/place_card.dart';

class ListingGrid extends StatelessWidget {
  const ListingGrid({
    required this.listings,
    required this.selectedListingId,
    required this.savedPlaceIds,
    required this.onListingTap,
    required this.onSaveTap,
    this.onDeleteTap,
    super.key,
  });

  final List<Place> listings;
  final String? selectedListingId;
  final Set<String> savedPlaceIds;
  final ValueChanged<Place> onListingTap;
  final ValueChanged<Place> onSaveTap;
  final ValueChanged<Place>? onDeleteTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.chezMoiColors;
    final width = MediaQuery.sizeOf(context).width;
    final columns = width >= 1100
        ? 3
        : width >= 720
        ? 2
        : 2;
    final spacing = width >= 720 ? 18.0 : 16.0;
    final compact = columns > 1;

    return SliverGrid.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        mainAxisSpacing: spacing,
        crossAxisSpacing: spacing,
        childAspectRatio: columns == 1 ? 0.82 : 0.60,
      ),
      itemCount: listings.length,
      itemBuilder: (context, index) {
        final listing = listings[index];
        final selected = listing.id == selectedListingId;
        return DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: selected ? colors.primaryBlue : Colors.transparent,
              width: selected ? 2 : 0,
            ),
          ),
          child: PlaceCard(
            listing: listing,
            compact: compact,
            saved: savedPlaceIds.contains(listing.id),
            actionIcon: onDeleteTap == null
                ? null
                : Icons.delete_outline_rounded,
            actionSelected: onDeleteTap == null ? null : false,
            actionColor: onDeleteTap == null ? null : colors.danger,
            actionTooltip: onDeleteTap == null ? null : 'Supprimer',
            onSaveTap: () => onDeleteTap == null
                ? onSaveTap(listing)
                : onDeleteTap!(listing),
            onTap: () => onListingTap(listing),
          ),
        );
      },
    );
  }
}
