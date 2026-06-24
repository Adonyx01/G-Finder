import 'place.dart';

/// Données saisies par un annonceur pour publier un établissement.
class PlaceDraft {
  PlaceDraft({
    required this.category,
    required this.title,
    required this.latitude,
    required this.longitude,
    this.description,
    this.subtype,
    this.price,
    this.currency = 'XAF',
    this.priceUnit = 'night',
    this.maxGuests,
    this.address,
    this.neighborhood,
    this.city,
    this.coverImageUrl,
    this.imageUrls = const [],
    this.amenities = const [],
    this.details = const {},
  });

  final String category;
  final String title;
  final double latitude;
  final double longitude;
  final String? description;
  final String? subtype;
  final num? price;
  final String currency;
  final String priceUnit;
  final int? maxGuests;
  final String? address;
  final String? neighborhood;
  final String? city;
  final String? coverImageUrl;
  final List<String> imageUrls;
  final List<String> amenities;
  final Map<String, dynamic> details;

  /// Unité de prix par défaut selon la catégorie.
  static String defaultPriceUnit(String category) {
    switch (category) {
      case 'restaurant':
        return 'table';
      case 'activity':
        return 'person';
      default:
        return 'night';
    }
  }

  /// Charge utile pour l'insertion dans la table `places`.
  Map<String, dynamic> toInsert(String ownerId) {
    return {
      'owner_id': ownerId,
      'category': category,
      'title': title,
      'description': description,
      'subtype': subtype,
      'price': price,
      'currency': currency,
      'price_unit': priceUnit,
      'max_guests': maxGuests,
      'address': address,
      'neighborhood': neighborhood,
      'city': city,
      'latitude': latitude,
      'longitude': longitude,
      'cover_image_url': coverImageUrl,
      'image_urls': imageUrls,
      'amenities': amenities,
      'details': details,
      'status': 'active',
    };
  }

  /// Représentation `Place` pour le mode démo (en mémoire, sans backend).
  Place toTemplatePlace() {
    return Place(
      id: 'user-${DateTime.now().microsecondsSinceEpoch}',
      title: title,
      category: category,
      description: description,
      subtype: subtype,
      price: price,
      currency: currency,
      priceUnit: priceUnit,
      maxGuests: maxGuests,
      address: address,
      neighborhood: neighborhood,
      city: city,
      countryCode: 'GA',
      latitude: latitude,
      longitude: longitude,
      coverImageUrl: coverImageUrl,
      imageUrls: imageUrls,
      amenities: amenities,
      details: details,
      createdAt: DateTime.now(),
    );
  }
}
