import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/backend_mode.dart';
import '../models/reservation.dart';

class ReservationException implements Exception {
  const ReservationException(this.message);
  final String message;
  @override
  String toString() => message;
}

class ReservationService {
  ReservationService({SupabaseClient? client}) : _supabaseClient = client;

  final SupabaseClient? _supabaseClient;

  SupabaseClient get _client => _supabaseClient ?? Supabase.instance.client;

  /// Réservations simulées en mémoire (mode template, sans backend).
  static final List<Reservation> _templateReservations = [];

  bool get _isLoggedIn =>
      BackendMode.isTemplate || _client.auth.currentUser != null;

  Future<Reservation> createReservation(ReservationDraft draft) async {
    if (!_isLoggedIn) {
      throw const ReservationException(
        'Connectez-vous pour réserver un établissement.',
      );
    }

    final listing = draft.listing;
    final total = draft.estimatedTotal;

    if (BackendMode.isTemplate) {
      final reservation = Reservation(
        id: 'template-res-${DateTime.now().microsecondsSinceEpoch}',
        placeId: listing.id,
        category: listing.category,
        status: 'pending',
        startDate: draft.startDate,
        endDate: draft.endDate,
        timeSlot: draft.timeSlot,
        guests: draft.guests,
        totalPrice: total,
        currency: listing.currency,
        contactPhone: draft.contactPhone,
        note: draft.note,
        createdAt: DateTime.now(),
        placeTitle: listing.title,
        placeCity: listing.city,
        placeCoverImageUrl: listing.coverImageUrl,
      );
      _templateReservations.insert(0, reservation);
      return reservation;
    }

    final userId = _client.auth.currentUser!.id;
    final startDate = draft.startDate == null ? null : _date(draft.startDate!);
    final endDate = draft.endDate == null ? null : _date(draft.endDate!);
    final payload = <String, dynamic>{
      'user_id': userId,
      'place_id': listing.id,
      'category': listing.category,
      'status': 'pending',
      'guests': draft.guests,
      'currency': listing.currency,
      'start_date': ?startDate,
      'end_date': ?endDate,
      'time_slot': ?_clean(draft.timeSlot),
      'total_price': ?total,
      'contact_phone': ?_clean(draft.contactPhone),
      'note': ?_clean(draft.note),
    };

    try {
      final row = await _client
          .from('reservations')
          .insert(payload)
          .select('*, places(title, city, cover_image_url, image_urls)')
          .single();
      return Reservation.fromRow(Map<String, dynamic>.from(row));
    } on PostgrestException catch (error) {
      throw ReservationException(error.message);
    } catch (_) {
      throw const ReservationException(
        'Impossible d\'enregistrer la réservation. Réessayez.',
      );
    }
  }

  Future<List<Reservation>> loadMyReservations() async {
    if (BackendMode.isTemplate) {
      return List<Reservation>.unmodifiable(_templateReservations);
    }
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return const [];
    try {
      final rows = await _client
          .from('reservations')
          .select('*, places(title, city, cover_image_url, image_urls)')
          .eq('user_id', userId)
          .order('created_at', ascending: false);
      return (rows as List)
          .whereType<Map>()
          .map((row) => Reservation.fromRow(Map<String, dynamic>.from(row)))
          .toList(growable: false);
    } catch (_) {
      return const [];
    }
  }

  Future<void> cancelReservation(String id) async {
    if (id.isEmpty) return;
    if (BackendMode.isTemplate) {
      final index = _templateReservations.indexWhere((r) => r.id == id);
      if (index == -1) return;
      final current = _templateReservations[index];
      _templateReservations[index] = Reservation(
        id: current.id,
        placeId: current.placeId,
        category: current.category,
        status: 'cancelled',
        startDate: current.startDate,
        endDate: current.endDate,
        timeSlot: current.timeSlot,
        guests: current.guests,
        totalPrice: current.totalPrice,
        currency: current.currency,
        contactPhone: current.contactPhone,
        note: current.note,
        createdAt: current.createdAt,
        placeTitle: current.placeTitle,
        placeCity: current.placeCity,
        placeCoverImageUrl: current.placeCoverImageUrl,
      );
      return;
    }
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;
    await _client
        .from('reservations')
        .update({'status': 'cancelled'})
        .eq('id', id)
        .eq('user_id', userId);
  }

  String _date(DateTime value) {
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    return '${value.year}-$month-$day';
  }

  String? _clean(String? value) {
    final text = value?.trim() ?? '';
    return text.isEmpty ? null : text;
  }
}
