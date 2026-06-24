import '../../places/models/place.dart';

/// Une réservation faite par un voyageur sur un lieu (hôtel/resto/activité).
class Reservation {
  const Reservation({
    required this.id,
    required this.placeId,
    required this.category,
    required this.status,
    this.startDate,
    this.endDate,
    this.timeSlot,
    this.guests = 1,
    this.totalPrice,
    this.currency = 'XAF',
    this.contactPhone,
    this.note,
    this.createdAt,
    this.placeTitle,
    this.placeCity,
    this.placeCoverImageUrl,
  });

  final String id;
  final String placeId;
  final String category;
  final String status;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? timeSlot;
  final int guests;
  final num? totalPrice;
  final String currency;
  final String? contactPhone;
  final String? note;
  final DateTime? createdAt;

  // Champs enrichis depuis la table places (pour l'affichage).
  final String? placeTitle;
  final String? placeCity;
  final String? placeCoverImageUrl;

  bool get isHotel => category == 'hotel';

  String get statusLabel {
    return switch (status) {
      'confirmed' => 'Confirmée',
      'cancelled' => 'Annulée',
      'completed' => 'Terminée',
      _ => 'En attente',
    };
  }

  String get categoryLabel {
    return switch (category) {
      'restaurant' => 'Restaurant',
      'activity' => 'Activité',
      _ => 'Hôtel',
    };
  }

  /// Libellé de période lisible selon la catégorie.
  String get scheduleLabel {
    final start = startDate;
    if (start == null) return 'Date à confirmer';
    final startText = _formatDate(start);
    if (isHotel && endDate != null) {
      return 'Du $startText au ${_formatDate(endDate!)}';
    }
    final slot = timeSlot?.trim() ?? '';
    return slot.isEmpty ? startText : '$startText · $slot';
  }

  String get guestsLabel => guests <= 1 ? '$guests personne' : '$guests personnes';

  String? get totalPriceLabel {
    final value = totalPrice;
    if (value == null) return null;
    final rounded = value.round().toString();
    final buffer = StringBuffer();
    for (var i = 0; i < rounded.length; i++) {
      final left = rounded.length - i;
      buffer.write(rounded[i]);
      if (left > 1 && left % 3 == 1) buffer.write(' ');
    }
    return '$buffer $currency';
  }

  static Reservation fromRow(Map<String, dynamic> row) {
    final place = row['places'];
    final placeMap = place is Map ? Map<String, dynamic>.from(place) : null;
    final images = stringListValue(placeMap?['image_urls']);
    return Reservation(
      id: stringValue(row['id']),
      placeId: stringValue(row['place_id']),
      category: stringValue(row['category'], fallback: 'hotel'),
      status: stringValue(row['status'], fallback: 'pending'),
      startDate: dateValue(row['start_date']),
      endDate: dateValue(row['end_date']),
      timeSlot: nullableString(row['time_slot']),
      guests: intValue(row['guests']) ?? 1,
      totalPrice: numValue(row['total_price']),
      currency: stringValue(row['currency'], fallback: 'XAF'),
      contactPhone: nullableString(row['contact_phone']),
      note: nullableString(row['note']),
      createdAt: dateValue(row['created_at']),
      placeTitle: nullableString(placeMap?['title']),
      placeCity: nullableString(placeMap?['city']),
      placeCoverImageUrl:
          nullableString(placeMap?['cover_image_url']) ??
          (images.isNotEmpty ? images.first : null),
    );
  }

  static String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }
}

/// Données nécessaires pour créer une réservation.
class ReservationDraft {
  const ReservationDraft({
    required this.listing,
    this.startDate,
    this.endDate,
    this.timeSlot,
    this.guests = 1,
    this.contactPhone,
    this.note,
  });

  final Place listing;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? timeSlot;
  final int guests;
  final String? contactPhone;
  final String? note;

  /// Prix total estimé : prix unitaire × (nuits ou personnes).
  num? get estimatedTotal {
    final unit = listing.price;
    if (unit == null) return null;
    if (listing.isHotel) {
      final nights = _nights;
      return unit * (nights <= 0 ? 1 : nights);
    }
    return unit * (guests <= 0 ? 1 : guests);
  }

  int get _nights {
    final start = startDate;
    final end = endDate;
    if (start == null || end == null) return 1;
    final diff = end.difference(start).inDays;
    return diff <= 0 ? 1 : diff;
  }
}
