import 'package:flutter/material.dart';

import '../../../core/theme.dart';
import '../../places/models/place.dart';
import '../../places/widgets/place_card.dart';
import 'dashboard_common.dart';

class FavoritesHubTab extends StatelessWidget {
  const FavoritesHubTab({
    required this.favoriteListings,
    required this.savedPlaceIds,
    required this.bottomPadding,
    required this.onListingTap,
    required this.onSaveTap,
    super.key,
  });

  final List<Place> favoriteListings;
  final Set<String> savedPlaceIds;
  final double bottomPadding;
  final ValueChanged<Place> onListingTap;
  final ValueChanged<Place> onSaveTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.chezMoiColors;
    return SafeArea(
      top: false,
      bottom: false,
      child: CustomScrollView(
        slivers: [
          const SliverToBoxAdapter(
            child: DashboardPageHeader(title: 'Favoris'),
          ),
          if (favoriteListings.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: DashboardCenteredState(
                child: Text(
                  'Aucun favori pour le moment.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
            )
          else
            SliverPadding(
              padding: EdgeInsets.fromLTRB(12, 14, 12, bottomPadding),
              sliver: SliverGrid.builder(
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 0.60,
                    ),
                itemCount: favoriteListings.length,
                itemBuilder: (context, index) {
                  final listing = favoriteListings[index];
                  return _FavoriteFeedCard(
                    listing: listing,
                    saved: savedPlaceIds.contains(listing.id),
                    onListingTap: () => onListingTap(listing),
                    onSaveTap: () => onSaveTap(listing),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _FavoriteFeedCard extends StatelessWidget {
  const _FavoriteFeedCard({
    required this.listing,
    required this.saved,
    required this.onListingTap,
    required this.onSaveTap,
  });

  final Place listing;
  final bool saved;
  final VoidCallback onListingTap;
  final VoidCallback onSaveTap;

  @override
  Widget build(BuildContext context) {
    return PlaceCard(
      listing: listing,
      compact: true,
      saved: saved,
      showLocation: true,
      onSaveTap: onSaveTap,
      onTap: onListingTap,
    );
  }
}
