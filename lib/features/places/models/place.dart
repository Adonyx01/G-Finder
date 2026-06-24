import 'dart:math' as math;

class UserLocation {
  const UserLocation({required this.lat, required this.lng});

  final double lat;
  final double lng;
}

class Place {
  const Place({
    required this.id,
    required this.title,
    this.category = 'hotel',
    this.publicCode,
    this.description,
    this.subtype,
    this.price,
    this.currency = 'XAF',
    this.priceUnit = 'night',
    this.details = const {},
    this.starRating,
    this.guestRating,
    this.reviewCount = 0,
    this.maxGuests,
    this.address,
    this.neighborhood,
    this.city,
    this.countryCode,
    this.latitude,
    this.longitude,
    this.createdAt,
    this.isFeatured = false,
    this.viewCount = 0,
    this.coverImageUrl,
    this.imageUrls = const [],
    this.distanceKm,
    this.amenities = const [],
  });

  final String id;
  final String title;

  /// Catégorie du lieu : 'hotel', 'restaurant' ou 'activity'.
  final String category;
  final String? publicCode;
  final String? description;
  final String? subtype;
  final num? price;
  final String currency;

  /// Unité de prix : 'night', 'person', 'table', 'session'.
  final String priceUnit;

  /// Specs propres à la catégorie (cuisine, durée, difficulté…).
  final Map<String, dynamic> details;

  /// Classement officiel de l'établissement (0 à 5 étoiles).
  final int? starRating;

  /// Note moyenne des voyageurs sur 10 (style Booking).
  final double? guestRating;

  /// Nombre d'avis voyageurs.
  final int reviewCount;

  /// Capacité maximale (nombre de voyageurs).
  final int? maxGuests;
  final String? address;
  final String? neighborhood;
  final String? city;
  final String? countryCode;
  final double? latitude;
  final double? longitude;
  final DateTime? createdAt;
  final bool isFeatured;
  final int viewCount;
  final String? coverImageUrl;
  final List<String> imageUrls;
  final double? distanceKm;
  final List<String> amenities;

  bool get hasCoordinates => latitude != null && longitude != null;

  bool get isHotel => category == 'hotel';
  bool get isRestaurant => category == 'restaurant';
  bool get isActivity => category == 'activity';

  /// Libellé de la catégorie, ex. "Hôtel", "Restaurant", "Activité".
  String get categoryLabel {
    return switch (category) {
      'restaurant' => 'Restaurant',
      'activity' => 'Activité',
      _ => 'Hôtel',
    };
  }

  /// Sous-type lisible. Pour les hôtels on traduit les clés connues ;
  /// pour les restaurants/activités c'est un libellé libre (cuisine, type…).
  String get subtypeLabel {
    if (!isHotel) {
      final raw = subtype?.trim() ?? '';
      return raw.isEmpty ? categoryLabel : raw;
    }
    return switch (subtype) {
      'hotel' => 'Hôtel',
      'hostel' => 'Auberge',
      'motel' => 'Motel',
      'guesthouse' => "Maison d'hôtes",
      'apartment_hotel' => 'Appart-hôtel',
      'resort' => 'Resort',
      _ => 'Hôtel',
    };
  }

  /// Unité de prix lisible, ex. "/ nuit", "/ personne".
  String get priceUnitLabel {
    return switch (priceUnit) {
      'person' => '/ personne',
      'table' => '/ table',
      'session' => '/ séance',
      _ => '/ nuit',
    };
  }

  /// Valeur de [details] sous forme de texte, ou null si absente/vide.
  String? detail(String key) {
    final value = details[key];
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? null : text;
  }

  String get locationLabel {
    final parts = [
      if ((neighborhood ?? '').trim().isNotEmpty) neighborhood!.trim(),
      if ((city ?? '').trim().isNotEmpty) city!.trim(),
    ];
    return parts.isEmpty ? 'Localisation à confirmer' : parts.join(', ');
  }

  String get priceLabel {
    if (price == null) return 'Prix sur demande';
    final rounded = price!.round().toString();
    final buffer = StringBuffer();
    for (var i = 0; i < rounded.length; i++) {
      final left = rounded.length - i;
      buffer.write(rounded[i]);
      if (left > 1 && left % 3 == 1) buffer.write(' ');
    }
    return '${buffer.toString()} $currency';
  }

  /// Prix affiché avec son unité (ex. "82 000 XAF / nuit", "15 000 XAF / personne").
  String get nightlyPriceLabel =>
      price == null ? 'Prix sur demande' : '$priceLabel $priceUnitLabel';

  /// Libellé des étoiles, ex. "4 étoiles". Null si non classé.
  String? get starRatingLabel {
    final stars = starRating;
    if (stars == null || stars <= 0) return null;
    return stars <= 1 ? '$stars étoile' : '$stars étoiles';
  }

  /// Note voyageurs formatée sur 10, ex. "8,4". Null si aucun avis.
  String? get guestRatingLabel {
    final rating = guestRating;
    if (rating == null) return null;
    return rating.toStringAsFixed(1).replaceAll('.', ',');
  }

  /// Appréciation textuelle de la note voyageurs.
  String? get guestRatingMention {
    final rating = guestRating;
    if (rating == null) return null;
    if (rating >= 9) return 'Exceptionnel';
    if (rating >= 8) return 'Très bien';
    if (rating >= 7) return 'Bien';
    if (rating >= 6) return 'Correct';
    return 'Convenable';
  }

  /// Libellé du nombre d'avis, ex. "184 avis".
  String? get reviewCountLabel {
    if (reviewCount <= 0) return null;
    return reviewCount <= 1 ? '$reviewCount avis' : '$reviewCount avis';
  }

  /// Capacité, ex. "2 voyageurs".
  String? get capacityLabel {
    final guests = maxGuests;
    if (guests == null || guests <= 0) return null;
    return guests <= 1 ? "$guests voyageur" : '$guests voyageurs';
  }

  String? get distanceLabel {
    final distance = distanceKm;
    if (distance == null) return null;
    return '${distance.toStringAsFixed(1).replaceAll('.', ',')} km';
  }

  String get postedLabel {
    final date = createdAt;
    if (date == null) return 'Publié récemment';
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return 'Publié le $day/$month/${date.year}';
  }

  bool matchesSearch(String query) {
    final normalized = _normalizeSearchText(query);
    if (normalized.isEmpty) return true;
    final zones = normalized
        .split(',')
        .map((zone) => zone.trim())
        .where((zone) => zone.isNotEmpty)
        .toList();
    if (zones.length > 1) {
      return zones.any(matchesSearch);
    }
    final fields = [
      title,
      city,
      neighborhood,
      subtype,
      subtypeLabel,
      address,
      locationLabel,
    ].whereType<String>().map(_normalizeSearchText);
    return fields.any(
      (value) =>
          value.contains(normalized) ||
          normalized
              .split(' ')
              .any((part) => part.length > 2 && value.contains(part)),
    );
  }

  bool matchesFilter(PlaceFilter filter) {
    if (filter.category != null && category != filter.category) {
      return false;
    }
    if (filter.subtype != null && subtype != filter.subtype) {
      return false;
    }
    if (filter.amenityKeys.isNotEmpty) {
      // Le filtre porte des clés/labels d'équipement ; on les compare aux
      // libellés portés par le lieu (mode template).
      final labels = amenities.map(_normalizeSearchText).toSet();
      final wanted = filter.amenityKeys.map(_normalizeSearchText);
      if (!wanted.every(labels.contains)) return false;
    }
    if (filter.zones.isNotEmpty &&
        !filter.zones.any((zone) => matchesSearch(zone))) {
      return false;
    }
    if (filter.minPrice != null &&
        (price == null || price! < filter.minPrice!)) {
      return false;
    }
    if (filter.maxPrice != null &&
        (price == null || price! > filter.maxPrice!)) {
      return false;
    }
    if (filter.maxDistanceKm != null &&
        (distanceKm == null || distanceKm! > filter.maxDistanceKm!)) {
      return false;
    }
    return true;
  }

  Place copyWithDistance(UserLocation? userLocation) {
    if (userLocation == null || latitude == null || longitude == null) {
      return this;
    }
    return copyWith(
      distanceKm: haversineKm(
        userLocation.lat,
        userLocation.lng,
        latitude!,
        longitude!,
      ),
    );
  }

  Place copyWith({double? distanceKm}) {
    return Place(
      id: id,
      title: title,
      category: category,
      publicCode: publicCode,
      description: description,
      subtype: subtype,
      price: price,
      currency: currency,
      priceUnit: priceUnit,
      details: details,
      starRating: starRating,
      guestRating: guestRating,
      reviewCount: reviewCount,
      maxGuests: maxGuests,
      address: address,
      neighborhood: neighborhood,
      city: city,
      countryCode: countryCode,
      latitude: latitude,
      longitude: longitude,
      createdAt: createdAt,
      isFeatured: isFeatured,
      viewCount: viewCount,
      coverImageUrl: coverImageUrl,
      imageUrls: imageUrls,
      distanceKm: distanceKm ?? this.distanceKm,
      amenities: amenities,
    );
  }

  static Place fromMaps({
    required Map<String, dynamic> row,
    UserLocation? userLocation,
  }) {
    final imageUrls = stringListValue(row['image_urls']);
    final cover =
        nullableString(row['cover_image_url']) ??
        (imageUrls.isNotEmpty ? imageUrls.first : null);
    final listing = Place(
      id: stringValue(row['id'], fallback: ''),
      title: stringValue(row['title'], fallback: 'Lieu'),
      category: stringValue(row['category'], fallback: 'hotel'),
      publicCode: nullableString(row['public_code']),
      description: nullableString(row['description']),
      subtype: nullableString(row['subtype']),
      price: numValue(row['price']),
      currency: stringValue(row['currency'], fallback: 'XAF'),
      priceUnit: stringValue(row['price_unit'], fallback: 'night'),
      details: mapValue(row['details']),
      starRating: intValue(row['star_rating']),
      guestRating: doubleValue(row['guest_rating']),
      reviewCount: intValue(row['review_count']) ?? 0,
      maxGuests: intValue(row['max_guests']),
      address: nullableString(row['address']),
      neighborhood: nullableString(row['neighborhood']),
      city: nullableString(row['city']),
      countryCode: nullableString(row['country_code']),
      latitude: doubleValue(row['latitude']),
      longitude: doubleValue(row['longitude']),
      createdAt: dateValue(row['created_at']),
      isFeatured: row['is_featured'] == true,
      viewCount: intValue(row['view_count']) ?? 0,
      coverImageUrl: cover,
      imageUrls: imageUrls,
      amenities: stringListValue(row['amenities']),
    );
    return listing.copyWithDistance(userLocation);
  }
}

class NearbyPlace {
  const NearbyPlace({
    required this.id,
    required this.placeId,
    required this.name,
    required this.category,
    required this.categoryLabel,
    required this.iconKey,
    required this.latitude,
    required this.longitude,
    this.address,
    this.distanceMeters,
    this.routeDistanceMeters,
    this.routeDurationSeconds,
    this.sortOrder = 0,
    this.algorithmVersion,
    this.calculatedAt,
  });

  final String id;
  final String placeId;
  final String name;
  final String category;
  final String categoryLabel;
  final String iconKey;
  final double latitude;
  final double longitude;
  final String? address;
  final int? distanceMeters;
  final int? routeDistanceMeters;
  final int? routeDurationSeconds;
  final int sortOrder;
  final String? algorithmVersion;
  final DateTime? calculatedAt;

  bool get hasCoordinates => latitude.isFinite && longitude.isFinite;

  String get distanceLabel {
    final seconds = routeDurationSeconds;
    final meters = routeDistanceMeters ?? distanceMeters;
    if (seconds != null && seconds > 0) {
      final duration = _formatDuration(seconds);
      return meters == null
          ? '$duration en voiture'
          : '$duration en voiture · ${_formatDistance(meters)}';
    }
    if (meters != null) return _formatDistance(meters);
    return 'Distance indisponible';
  }

  static NearbyPlace fromRow(Map<String, dynamic> row) {
    return NearbyPlace(
      id: stringValue(
        row['id'],
        fallback: stringValue(row['provider_place_id']),
      ),
      placeId: stringValue(row['place_id']),
      name: stringValue(row['name'], fallback: 'Lieu à proximité'),
      category: stringValue(row['category'], fallback: 'services'),
      categoryLabel: stringValue(
        row['category_label'],
        fallback: 'À proximité',
      ),
      iconKey: stringValue(
        row['icon_key'],
        fallback: stringValue(row['category'], fallback: 'place'),
      ),
      latitude: doubleValue(row['latitude']) ?? 0,
      longitude: doubleValue(row['longitude']) ?? 0,
      address: nullableString(row['address']),
      distanceMeters: intValue(row['distance_meters']),
      routeDistanceMeters: intValue(row['route_distance_meters']),
      routeDurationSeconds: intValue(row['route_duration_seconds']),
      sortOrder: intValue(row['sort_order']) ?? 0,
      algorithmVersion: nullableString(row['algorithm_version']),
      calculatedAt: dateValue(row['calculated_at']),
    );
  }
}

String _formatDuration(int seconds) {
  final minutes = math.max(1, (seconds / 60).round());
  if (minutes < 60) return '$minutes min';
  final hours = minutes ~/ 60;
  final rest = minutes % 60;
  return rest == 0 ? '$hours h' : '$hours h $rest min';
}

String _formatDistance(int meters) {
  if (meters < 1000) return '$meters m';
  final km = meters / 1000;
  return '${km.toStringAsFixed(km < 10 ? 1 : 0).replaceAll('.', ',')} km';
}

class AmenityOption {
  const AmenityOption({required this.key, required this.label});

  final String key;
  final String label;

  static AmenityOption fromRow(Map<String, dynamic> row) {
    return AmenityOption(
      key: stringValue(row['key']),
      label: stringValue(row['label']),
    );
  }
}

class ChezMoiProfile {
  const ChezMoiProfile({
    required this.id,
    required this.email,
    required this.prenom,
    required this.nom,
    required this.displayName,
    required this.phone,
    required this.location,
    required this.countryCode,
    required this.countryName,
    required this.accountType,
    required this.avatarUrl,
    this.companyName = '',
    this.locationLat,
    this.locationLng,
  });

  final String id;
  final String email;
  final String prenom;
  final String nom;
  final String displayName;
  final String phone;
  final String location;
  final String countryCode;
  final String countryName;
  final String accountType;
  final String avatarUrl;
  final String companyName;
  final double? locationLat;
  final double? locationLng;

  String get fullName {
    if (isAnnonceur && companyName.trim().isNotEmpty) return companyName.trim();
    if (displayName.trim().isNotEmpty) return displayName.trim();
    final name = '$prenom $nom'.trim();
    if (name.isNotEmpty) return name;
    if (email.trim().isNotEmpty) return email.trim();
    return 'Utilisateur ChezMoi';
  }

  bool get isAnnonceur => accountType == 'annonceur';

  String get accountTypeLabel => isAnnonceur ? 'Annonceur' : 'Voyageur';

  UserLocation? get userLocation {
    if (locationLat == null || locationLng == null) return null;
    return UserLocation(lat: locationLat!, lng: locationLng!);
  }

  static ChezMoiProfile fromRow(
    Map<String, dynamic> row, {
    String fallbackEmail = '',
  }) {
    return ChezMoiProfile(
      id: stringValue(row['id']),
      email: stringValue(row['email'], fallback: fallbackEmail),
      prenom: stringValue(row['prenom']),
      nom: stringValue(row['nom']),
      displayName: stringValue(row['display_name']),
      phone: stringValue(row['phone']),
      location: stringValue(row['location']),
      countryCode: stringValue(row['country_code'], fallback: 'GA'),
      countryName: stringValue(row['country_name'], fallback: 'Gabon'),
      accountType: stringValue(row['account_type'], fallback: 'traveler'),
      avatarUrl: stringValue(row['avatar_url']),
      companyName: stringValue(row['company_name']),
      locationLat: doubleValue(row['location_lat']),
      locationLng: doubleValue(row['location_lng']),
    );
  }
}

class PlaceFilter {
  const PlaceFilter({
    this.category,
    this.subtype,
    this.minPrice,
    this.maxPrice,
    this.zones = const [],
    this.amenityKeys = const {},
    this.maxDistanceKm,
    this.availableNow = false,
  });

  /// Catégorie ciblée : 'hotel', 'restaurant', 'activity' (null = toutes).
  final String? category;
  final String? subtype;
  final num? minPrice;
  final num? maxPrice;
  final List<String> zones;
  final Set<String> amenityKeys;
  final double? maxDistanceKm;
  final bool availableNow;

  bool get isEmpty =>
      category == null &&
      subtype == null &&
      minPrice == null &&
      maxPrice == null &&
      zones.isEmpty &&
      amenityKeys.isEmpty &&
      maxDistanceKm == null &&
      !availableNow;
}

double haversineKm(double lat1, double lng1, double lat2, double lng2) {
  const radiusKm = 6371.0;
  final dLat = _degreesToRadians(lat2 - lat1);
  final dLng = _degreesToRadians(lng2 - lng1);
  final a =
      math.sin(dLat / 2) * math.sin(dLat / 2) +
      math.cos(_degreesToRadians(lat1)) *
          math.cos(_degreesToRadians(lat2)) *
          math.sin(dLng / 2) *
          math.sin(dLng / 2);
  final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  return radiusKm * c;
}

double _degreesToRadians(double degrees) => degrees * math.pi / 180;

String stringValue(Object? value, {String fallback = ''}) {
  final text = value?.toString().trim() ?? '';
  return text.isEmpty ? fallback : text;
}

String? nullableString(Object? value) {
  final text = value?.toString().trim() ?? '';
  return text.isEmpty ? null : text;
}

num? numValue(Object? value) {
  if (value is num) return value;
  if (value == null) return null;
  return num.tryParse(value.toString());
}

int? intValue(Object? value) {
  if (value is int) return value;
  if (value is num) return value.round();
  if (value == null) return null;
  return int.tryParse(value.toString());
}

double? doubleValue(Object? value) {
  if (value is double) return value;
  if (value is num) return value.toDouble();
  if (value == null) return null;
  return double.tryParse(value.toString());
}

DateTime? dateValue(Object? value) {
  if (value == null) return null;
  return DateTime.tryParse(value.toString());
}

/// Convertit une colonne Postgres `text[]` (List) en `List<String>` propre.
List<String> stringListValue(Object? value) {
  if (value is! List) return const [];
  return value
      .map((item) => item?.toString().trim() ?? '')
      .where((item) => item.isNotEmpty)
      .toList(growable: false);
}

/// Convertit une colonne `jsonb` en `Map<String, dynamic>`.
Map<String, dynamic> mapValue(Object? value) {
  if (value is Map) return Map<String, dynamic>.from(value);
  return const {};
}

String _normalizeSearchText(String value) {
  return value
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'\s+'), ' ')
      .replaceAll(RegExp(r'\s*,\s*'), ',');
}
