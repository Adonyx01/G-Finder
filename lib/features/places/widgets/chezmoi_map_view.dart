import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/theme.dart';
import '../models/place.dart';

class ChezMoiMapCoordinate {
  const ChezMoiMapCoordinate(this.latitude, this.longitude);

  final double latitude;
  final double longitude;
}

class ChezMoiMapView extends StatefulWidget {
  const ChezMoiMapView({
    super.key,
    required this.listings,
    required this.onListingSelected,
    this.userLocation,
    this.nearbyPlaces = const [],
    this.selectedListingId,
    this.compact = false,
  });

  static const libreville = ChezMoiMapCoordinate(0.3924, 9.4582);

  final List<Place> listings;
  final List<NearbyPlace> nearbyPlaces;
  final UserLocation? userLocation;
  final String? selectedListingId;
  final ValueChanged<Place> onListingSelected;
  final bool compact;

  @override
  State<ChezMoiMapView> createState() => _ChezMoiMapViewState();
}

class _ChezMoiMapViewState extends State<ChezMoiMapView> {
  late final MapController _mapController;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  List<Place> get _geoListings =>
      widget.listings.where((l) => l.hasCoordinates).toList();

  LatLng get _center {
    final geo = _geoListings;
    if (geo.isEmpty) {
      return LatLng(
        ChezMoiMapView.libreville.latitude,
        ChezMoiMapView.libreville.longitude,
      );
    }
    final latSum = geo.fold(0.0, (s, l) => s + l.latitude!);
    final lngSum = geo.fold(0.0, (s, l) => s + l.longitude!);
    return LatLng(latSum / geo.length, lngSum / geo.length);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.chezMoiColors;
    final geoListings = _geoListings;

    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: _center,
        initialZoom: geoListings.isEmpty ? 11.5 : 12.2,
        minZoom: 5,
        maxZoom: 18,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.example.chezmoi',
        ),
        if (widget.userLocation != null)
          MarkerLayer(
            markers: [
              Marker(
                point: LatLng(
                  widget.userLocation!.lat,
                  widget.userLocation!.lng,
                ),
                width: 28,
                height: 28,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: colors.primaryBlue, width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.18),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.my_location_rounded,
                    size: 14,
                    color: colors.primaryBlue,
                  ),
                ),
              ),
            ],
          ),
        MarkerLayer(
          markers: [
            for (final listing in geoListings)
              Marker(
                point: LatLng(listing.latitude!, listing.longitude!),
                width: listing.id == widget.selectedListingId ? 130 : 110,
                height: 36,
                alignment: Alignment.centerLeft,
                child: GestureDetector(
                  onTap: () => widget.onListingSelected(listing),
                  child: _ListingMarker(
                    listing: listing,
                    selected: listing.id == widget.selectedListingId,
                  ),
                ),
              ),
          ],
        ),
        RichAttributionWidget(
          attributions: [
            TextSourceAttribution('OpenStreetMap contributors'),
          ],
        ),
      ],
    );
  }
}

class _ListingMarker extends StatelessWidget {
  const _ListingMarker({required this.listing, required this.selected});

  final Place listing;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final colors = context.chezMoiColors;
    final bg = selected
        ? const Color(0xFF1E3A5F)
        : listing.isFeatured
        ? const Color(0xFF357ABD)
        : colors.primaryBlue;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: Colors.white, width: selected ? 2 : 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: selected ? 0.28 : 0.14),
            blurRadius: selected ? 18 : 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.home_rounded, size: 13, color: Colors.white),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              listing.price == null ? 'GabonTrip' : listing.priceLabel,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
