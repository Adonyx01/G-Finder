import 'dart:convert';

import 'package:http/http.dart' as http;

import '../core/backend_mode.dart';
import '../core/geoapify_config.dart';

class LocationSearchResult {
  const LocationSearchResult({
    required this.label,
    required this.city,
    required this.suburb,
    required this.formatted,
    required this.countryCode,
    required this.lat,
    required this.lng,
  });

  final String label;
  final String city;
  final String suburb;
  final String formatted;
  final String countryCode;
  final double lat;
  final double lng;

  static LocationSearchResult? fromFeature(Map<String, dynamic> feature) {
    final properties = feature['properties'];
    if (properties is! Map) return null;

    final lat = properties['lat'];
    final lon = properties['lon'];
    if (lat is! num || lon is! num) return null;

    final city = stringValue(
      properties['city'],
      fallback: stringValue(properties['county']),
    );
    final suburb = stringValue(
      properties['suburb'],
      fallback: stringValue(properties['district']),
    );
    final formatted = stringValue(properties['formatted']);
    final countryCode = stringValue(properties['country_code']).toUpperCase();
    final name = stringValue(properties['name']);
    final street = stringValue(properties['street']);
    final label = [
      if (suburb.isNotEmpty) suburb,
      if (city.isNotEmpty && city != suburb) city,
      if (name.isNotEmpty && name != suburb && name != city) name,
      if (street.isNotEmpty && street != name) street,
    ].join(', ');

    return LocationSearchResult(
      label: label.isNotEmpty
          ? label
          : formatted.isNotEmpty
          ? formatted
          : 'Position',
      city: city,
      suburb: suburb,
      formatted: formatted,
      countryCode: countryCode,
      lat: lat.toDouble(),
      lng: lon.toDouble(),
    );
  }

  static String stringValue(Object? value, {String fallback = ''}) {
    if (value == null) return fallback;
    final text = value.toString().trim();
    return text.isEmpty ? fallback : text;
  }
}

class LocationSearchService {
  LocationSearchService({http.Client? client})
    : _client = client ?? http.Client();

  final http.Client _client;

  static const _autocompleteEndpoint =
      'https://api.geoapify.com/v1/geocode/autocomplete';
  static const _reverseEndpoint = 'https://api.geoapify.com/v1/geocode/reverse';

  void dispose() {
    _client.close();
  }

  Future<List<LocationSearchResult>> autocomplete(
    String query, {
    required String countryCode,
    double? lat,
    double? lng,
  }) async {
    final trimmed = query.trim();
    if (trimmed.length < 2) return const [];

    if (BackendMode.isTemplate) {
      return _templateLocations
          .where(
            (location) =>
                location.label.toLowerCase().contains(trimmed.toLowerCase()) ||
                location.city.toLowerCase().contains(trimmed.toLowerCase()) ||
                location.suburb.toLowerCase().contains(trimmed.toLowerCase()),
          )
          .take(6)
          .toList(growable: false);
    }

    if (GeoapifyConfig.apiKey.trim().isEmpty) {
      throw const LocationSearchException('Recherche de lieu indisponible.');
    }

    final uri = Uri.parse(_autocompleteEndpoint).replace(
      queryParameters: {
        'text': trimmed,
        'filter': 'countrycode:${countryCode.toLowerCase()}',
        'limit': '6',
        'lang': 'fr',
        'format': 'geojson',
        if (lat != null && lng != null) 'bias': 'proximity:$lng,$lat',
        'apiKey': GeoapifyConfig.apiKey,
      },
    );

    try {
      final response = await _client.get(uri);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw const LocationSearchException('Recherche de lieu indisponible.');
      }
      return _parseFeatureCollection(response.body);
    } on LocationSearchException {
      rethrow;
    } catch (_) {
      throw const LocationSearchException('Recherche de lieu indisponible.');
    }
  }

  Future<LocationSearchResult?> reverseGeocode(
    double lat,
    double lng, {
    String? countryCode,
  }) async {
    if (BackendMode.isTemplate) {
      return _templateLocations.first;
    }

    if (GeoapifyConfig.apiKey.trim().isEmpty) {
      throw const LocationSearchException('Recherche de lieu indisponible.');
    }

    final uri = Uri.parse(_reverseEndpoint).replace(
      queryParameters: {
        'lat': lat.toString(),
        'lon': lng.toString(),
        if (countryCode != null && countryCode.isNotEmpty)
          'filter': 'countrycode:${countryCode.toLowerCase()}',
        'lang': 'fr',
        'format': 'geojson',
        'apiKey': GeoapifyConfig.apiKey,
      },
    );

    final response = await _client.get(uri);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw const LocationSearchException('Position introuvable.');
    }

    final results = _parseFeatureCollection(response.body);
    return results.isEmpty ? null : results.first;
  }

  List<LocationSearchResult> _parseFeatureCollection(String body) {
    final decoded = jsonDecode(body);
    if (decoded is! Map) return const [];

    final features = decoded['features'];
    if (features is! List) return const [];

    return features
        .whereType<Map<String, dynamic>>()
        .map(LocationSearchResult.fromFeature)
        .whereType<LocationSearchResult>()
        .toList();
  }
}

const _templateLocations = [
  LocationSearchResult(
    label: 'Batterie IV, Libreville',
    city: 'Libreville',
    suburb: 'Batterie IV',
    formatted: 'Batterie IV, Libreville, Gabon',
    countryCode: 'GA',
    lat: 0.4162,
    lng: 9.4325,
  ),
  LocationSearchResult(
    label: 'Centre-ville, Port-Gentil',
    city: 'Port-Gentil',
    suburb: 'Centre-ville',
    formatted: 'Centre-ville, Port-Gentil, Gabon',
    countryCode: 'GA',
    lat: -0.7193,
    lng: 8.7815,
  ),
  LocationSearchResult(
    label: 'Potos, Franceville',
    city: 'Franceville',
    suburb: 'Potos',
    formatted: 'Potos, Franceville, Gabon',
    countryCode: 'GA',
    lat: -1.6333,
    lng: 13.5833,
  ),
  LocationSearchResult(
    label: 'Akoakam, Oyem',
    city: 'Oyem',
    suburb: 'Akoakam',
    formatted: 'Akoakam, Oyem, Gabon',
    countryCode: 'GA',
    lat: 1.5995,
    lng: 11.5793,
  ),
  LocationSearchResult(
    label: 'Lambarene',
    city: 'Lambarene',
    suburb: '',
    formatted: 'Lambarene, Gabon',
    countryCode: 'GA',
    lat: -0.7001,
    lng: 10.2406,
  ),
];

class LocationSearchException implements Exception {
  const LocationSearchException(this.message);

  final String message;

  @override
  String toString() => message;
}
