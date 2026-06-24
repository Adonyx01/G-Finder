import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme.dart';
import '../../../services/location_search_service.dart';
import '../../dashboard/widgets/place_detail_sheet.dart';
import '../models/place.dart';
import '../services/place_service.dart';
import '../widgets/chezmoi_map_view.dart';
import '../widgets/listing_reference.dart';
import '../widgets/place_filter_sheet.dart';

class FullMapRouteExtra {
  const FullMapRouteExtra({
    required this.initialListing,
    this.openedFromPlace = false,
  });

  final Place initialListing;
  final bool openedFromPlace;
}

class FullMapScreen extends StatefulWidget {
  const FullMapScreen({
    super.key,
    this.initialListing,
    this.openedFromPlace = false,
  });

  final Place? initialListing;
  final bool openedFromPlace;

  @override
  State<FullMapScreen> createState() => _FullMapScreenState();
}

class _FullMapScreenState extends State<FullMapScreen> {
  final _placeService = PlaceService();
  final _locationSearchService = LocationSearchService();
  final _searchController = TextEditingController();
  Timer? _searchDebounce;
  List<Place> _listings = const [];
  List<NearbyPlace> _nearbyPlaces = const [];
  List<LocationSearchResult> _searchSuggestions = const [];
  PlaceFilter _filter = const PlaceFilter();
  ChezMoiProfile? _profile;
  String? _selectedListingId;
  String? _error;
  bool _loading = true;
  bool _searchingLocation = false;

  @override
  void initState() {
    super.initState();
    _selectedListingId = widget.initialListing?.id;
    _load();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    _locationSearchService.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final profile = await _placeService.loadCurrentProfile();
      if (widget.openedFromPlace && widget.initialListing != null) {
        final nearbyPlaces = await _placeService.loadNearbyPlaces(
          widget.initialListing!,
        );
        if (!mounted) return;
        setState(() {
          _profile = profile;
          _listings = [widget.initialListing!];
          _nearbyPlaces = nearbyPlaces;
          _selectedListingId = widget.initialListing!.id;
        });
        return;
      }

      final listings = await _placeService.loadActiveMapListings(
        userLocation: profile?.userLocation,
      );
      if (!mounted) return;
      final initialListing = widget.initialListing;
      final nextListings =
          initialListing == null ||
              listings.any((listing) => listing.id == initialListing.id)
          ? listings
          : [initialListing, ...listings];
      setState(() {
        _profile = profile;
        _listings = nextListings;
        _selectedListingId ??= initialListing?.id;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'Impossible de charger la carte.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _openDetails(Place listing) {
    setState(() => _selectedListingId = listing.id);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => PlaceDetailSheet(listing: listing),
    );
  }

  Future<void> _openFilters() async {
    final result = await showModalBottomSheet<PlaceFilter>(
      context: context,
      isScrollControlled: true,
      builder: (context) => PlaceFilterSheet(initialFilter: _filter),
    );
    if (result != null && mounted) {
      setState(() => _filter = result);
    }
  }

  void _searchLocations(String value) {
    _searchDebounce?.cancel();
    final query = value.split(',').last.trim();
    if (query.length < 2) {
      setState(() => _searchSuggestions = const []);
      return;
    }
    setState(() => _searchingLocation = true);
    _searchDebounce = Timer(const Duration(milliseconds: 300), () async {
      try {
        final suggestions = await _locationSearchService.autocomplete(
          query,
          countryCode: 'GA',
          lat: 0.3924,
          lng: 9.4582,
        );
        if (!mounted ||
            _searchController.text.split(',').last.trim() != query) {
          return;
        }
        setState(() {
          _searchSuggestions = suggestions;
          _searchingLocation = false;
        });
      } catch (_) {
        if (!mounted) return;
        setState(() {
          _searchSuggestions = const [];
          _searchingLocation = false;
        });
      }
    });
  }

  void _selectSearchLocation(LocationSearchResult result) {
    final zone = result.suburb.isNotEmpty
        ? result.suburb
        : result.city.isNotEmpty
        ? result.city
        : result.label;
    final zones = _searchController.text
        .split(',')
        .map((zone) => zone.trim())
        .where((zone) => zone.isNotEmpty)
        .toList();
    if (!_valueEndsWithComma(_searchController.text) && zones.isNotEmpty) {
      zones.removeLast();
    }
    zones.add(zone);
    setState(() {
      _searchController.text = '${zones.join(', ')}, ';
      _searchController.selection = TextSelection.collapsed(
        offset: _searchController.text.length,
      );
      _searchSuggestions = const [];
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.chezMoiColors;
    final selectedListing = _selectedListing;
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: ChezMoiMapView(
              listings: _listings,
              nearbyPlaces: widget.openedFromPlace
                  ? _nearbyPlaces
                  : const [],
              userLocation: _profile?.userLocation,
              selectedListingId: _selectedListingId,
              onListingSelected: widget.openedFromPlace
                  ? (_) {}
                  : _openDetails,
            ),
          ),
          if (widget.openedFromPlace)
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Align(
                  alignment: Alignment.topLeft,
                  child: IconButton.filledTonal(
                    onPressed: () => context.pop(),
                    icon: const Icon(Icons.arrow_back_rounded),
                    tooltip: 'Retour à l’établissement',
                  ),
                ),
              ),
            )
          else
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        IconButton.filledTonal(
                          onPressed: () => context.pop(),
                          icon: const Icon(Icons.arrow_back_rounded),
                          tooltip: 'Retour',
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            onChanged: _searchLocations,
                            decoration: InputDecoration(
                              hintText: 'Rechercher une zone',
                              prefixIcon: const Icon(
                                Icons.travel_explore_rounded,
                              ),
                              suffixIcon: _searchingLocation
                                  ? const Padding(
                                      padding: EdgeInsets.all(14),
                                      child: SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      ),
                                    )
                                  : _searchController.text.isEmpty
                                  ? null
                                  : IconButton(
                                      onPressed: () {
                                        setState(() {
                                          _searchController.clear();
                                          _searchSuggestions = const [];
                                        });
                                      },
                                      icon: const Icon(Icons.close_rounded),
                                      tooltip: 'Effacer',
                                    ),
                              filled: true,
                              fillColor: colors.surface.withValues(alpha: 0.96),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        IconButton.filled(
                          onPressed: _openFilters,
                          icon: const Icon(Icons.tune_rounded),
                          tooltip: 'Filtres',
                        ),
                      ],
                    ),
                    if (_searchSuggestions.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      _MapSearchSuggestions(
                        suggestions: _searchSuggestions,
                        onSelected: _selectSearchLocation,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          if (widget.openedFromPlace && selectedListing != null)
            SafeArea(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: _FocusedListingPanel(listing: selectedListing),
              ),
            ),
          if (!_loading && _listings.isEmpty)
            SafeArea(
              child: Align(
                alignment: Alignment.topCenter,
                child: Container(
                  margin: const EdgeInsets.only(top: 76, left: 16, right: 16),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: colors.surface.withValues(alpha: 0.94),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: colors.border),
                  ),
                  child: Text(
                    'Aucun établissement ne correspond aux filtres.',
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          if (_loading)
            ColoredBox(
              color: colors.background.withValues(alpha: 0.34),
              child: const Center(child: CircularProgressIndicator()),
            ),
          if (_error != null)
            SafeArea(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: colors.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: colors.border),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          _error!,
                          style: TextStyle(
                            color: colors.textPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: _load,
                        child: const Text('Réessayer'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Place? get _selectedListing {
    final selectedId = _selectedListingId;
    if (selectedId != null) {
      for (final listing in _listings) {
        if (listing.id == selectedId) return listing;
      }
    }
    return widget.initialListing;
  }
}

bool _valueEndsWithComma(String value) => value.trimRight().endsWith(',');

class _MapSearchSuggestions extends StatelessWidget {
  const _MapSearchSuggestions({
    required this.suggestions,
    required this.onSelected,
  });

  final List<LocationSearchResult> suggestions;
  final ValueChanged<LocationSearchResult> onSelected;

  @override
  Widget build(BuildContext context) {
    final colors = context.chezMoiColors;
    return Container(
      decoration: BoxDecoration(
        color: colors.surface.withValues(alpha: 0.98),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: colors.surface,
        child: Column(
          children: [
            for (final suggestion in suggestions.take(4))
              ListTile(
                dense: true,
                leading: Icon(Icons.place_outlined, color: colors.accent),
                title: Text(
                  suggestion.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: suggestion.formatted.isEmpty
                    ? null
                    : Text(
                        suggestion.formatted,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                onTap: () => onSelected(suggestion),
              ),
          ],
        ),
      ),
    );
  }
}

class _FocusedListingPanel extends StatelessWidget {
  const _FocusedListingPanel({required this.listing});

  final Place listing;

  @override
  Widget build(BuildContext context) {
    final colors = context.chezMoiColors;
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 0, 14, 14),
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      decoration: BoxDecoration(
        color: colors.surface.withValues(alpha: 0.97),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colors.border),
        boxShadow: [
          BoxShadow(
            color: colors.navy.withValues(alpha: 0.14),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  listing.priceLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF1677E8),
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  listing.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if ((listing.publicCode ?? '').trim().isNotEmpty) ...[
                  const SizedBox(height: 4),
                  ListingReference(code: listing.publicCode, compact: true),
                ],
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.location_on_rounded,
                      color: colors.textSecondary,
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        listing.locationLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: colors.textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
