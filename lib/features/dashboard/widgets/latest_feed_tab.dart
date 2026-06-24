import 'package:flutter/material.dart';

import '../../../core/theme.dart';
import '../../places/models/place.dart';
import '../../places/widgets/place_card.dart';
import 'dashboard_common.dart';

class LatestListingsTab extends StatefulWidget {
  const LatestListingsTab({
    required this.loader,
    required this.savedPlaceIds,
    required this.bottomPadding,
    required this.onListingTap,
    required this.onSaveTap,
    super.key,
  });

  final Future<List<Place>> Function() loader;
  final Set<String> savedPlaceIds;
  final double bottomPadding;
  final ValueChanged<Place> onListingTap;
  final ValueChanged<Place> onSaveTap;

  @override
  State<LatestListingsTab> createState() => _LatestListingsTabState();
}

class _LatestListingsTabState extends State<LatestListingsTab> {
  late Future<List<Place>> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.loader();
  }

  Future<void> _reload() async {
    final future = widget.loader();
    setState(() => _future = future);
    try {
      await future;
    } catch (_) {
      // The FutureBuilder renders the failed state.
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Place>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const SafeArea(
            child: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError) {
          return SafeArea(
            bottom: false,
            child: CustomScrollView(
              slivers: [
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: DashboardCenteredState(
                    child: DashboardErrorState(
                      message:
                          'Impossible de charger les nouveautés. Réessayez dans un instant.',
                      onRetry: _reload,
                    ),
                  ),
                ),
              ],
            ),
          );
        }
        return RefreshIndicator(
          onRefresh: _reload,
          child: _LatestFeedContent(
            listings: snapshot.data ?? const [],
            savedPlaceIds: widget.savedPlaceIds,
            bottomPadding: widget.bottomPadding,
            onListingTap: widget.onListingTap,
            onSaveTap: widget.onSaveTap,
          ),
        );
      },
    );
  }
}

class _LatestFeedContent extends StatelessWidget {
  const _LatestFeedContent({
    required this.listings,
    required this.savedPlaceIds,
    required this.bottomPadding,
    required this.onListingTap,
    required this.onSaveTap,
  });

  final List<Place> listings;
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
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          const SliverToBoxAdapter(
            child: DashboardPageHeader(title: 'Nouveautés'),
          ),
          if (listings.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: DashboardCenteredState(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.real_estate_agent_outlined,
                      color: colors.textSecondary,
                      size: 42,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Aucune nouveauté pour le moment.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'La prochaine belle adresse arrive sûrement bientôt. Repassez tout à l’heure.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: colors.textSecondary,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            SliverPadding(
              padding: EdgeInsets.fromLTRB(12, 10, 12, bottomPadding),
              sliver: SliverGrid.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 0.60,
                ),
                itemCount: listings.length,
                itemBuilder: (context, index) {
                  final listing = listings[index];
                  return FeedPlaceCardPost(
                    listing: listing,
                    saved: savedPlaceIds.contains(listing.id),
                    compact: true,
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

class FeedPlaceCardPost extends StatelessWidget {
  const FeedPlaceCardPost({
    super.key,
    required this.listing,
    required this.saved,
    required this.onListingTap,
    required this.onSaveTap,
    this.compact = false,
  });

  final Place listing;
  final bool saved;
  final VoidCallback onListingTap;
  final VoidCallback onSaveTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.sizeOf(context).width >= 720;

    if (compact) {
      return PlaceCard(
        listing: listing,
        compact: true,
        saved: saved,
        showLocation: true,
        onSaveTap: onSaveTap,
        onTap: onListingTap,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: isWide ? 480 : 440,
          child: PlaceCard(
            listing: listing,
            compact: false,
            saved: saved,
            showLocation: false,
            onSaveTap: onSaveTap,
            onTap: onListingTap,
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 10, 4, 0),
          child: Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              _LatestFeedMeta(
                icon: Icons.place_outlined,
                label: listing.locationLabel,
              ),
              _LatestFeedMeta(
                icon: Icons.hotel_outlined,
                label: listing.subtypeLabel,
              ),
              if (listing.viewCount > 0)
                _LatestFeedMeta(
                  icon: Icons.visibility_outlined,
                  label: '${listing.viewCount} vues',
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _LatestFeedMeta extends StatelessWidget {
  const _LatestFeedMeta({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = context.chezMoiColors;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: colors.textSecondary),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            color: colors.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
