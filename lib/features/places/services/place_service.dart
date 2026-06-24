import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/backend_mode.dart';
import '../models/place.dart';
import '../models/place_draft.dart';
import 'template_places_data.dart';

/// Accès au catalogue unifié `places` (hôtels / restaurants / activités),
/// aux favoris (`saved_places`) et aux actions de compte/support.
class PlaceService {
  PlaceService({SupabaseClient? client}) : _supabaseClient = client;

  static const int defaultListingPageSize = 20;
  static const String nearbyAlgorithmVersion = 'nearby-icon-v3';

  final SupabaseClient? _supabaseClient;

  SupabaseClient get _client => _supabaseClient ?? Supabase.instance.client;

  Future<ChezMoiProfile?> loadCurrentProfile() async {
    if (BackendMode.isTemplate) return null;
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return null;
    try {
      final profile = await _client
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();
      if (profile == null) return null;
      return ChezMoiProfile.fromRow(
        profile,
        fallbackEmail: _client.auth.currentUser?.email ?? '',
      );
    } catch (_) {
      return null;
    }
  }

  Future<List<Place>> loadActiveListings({
    UserLocation? userLocation,
    int offset = 0,
    int limit = defaultListingPageSize,
    PlaceFilter filter = const PlaceFilter(),
    String searchQuery = '',
  }) async {
    if (BackendMode.isTemplate) {
      return TemplateLodgingData.queryListings(
        userLocation: userLocation,
        offset: offset,
        limit: limit,
        filter: filter,
        searchQuery: searchQuery,
      );
    }
    final rows = await _loadPlaces(
      offset: offset,
      limit: limit,
      filter: filter,
      searchQuery: searchQuery,
    );
    return _hydrate(rows, userLocation: userLocation);
  }

  // ----- Côté annonceur : publier / gérer ses établissements -------------

  /// Les établissements appartenant à l'annonceur connecté.
  Future<List<Place>> loadMyPlaces({UserLocation? userLocation}) async {
    if (BackendMode.isTemplate) {
      return [
        for (final place in TemplateLodgingData.userPlaces)
          place.copyWithDistance(userLocation),
      ];
    }
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return const [];
    final rows = await _client
        .from('places')
        .select()
        .eq('owner_id', userId)
        .order('created_at', ascending: false);
    return _hydrate(_rowsToMaps(rows), userLocation: userLocation);
  }

  /// Publie un nouvel établissement (status 'active' immédiat).
  Future<void> createPlace(PlaceDraft draft) async {
    if (BackendMode.isTemplate) {
      TemplateLodgingData.userPlaces.insert(0, draft.toTemplatePlace());
      return;
    }
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw const PlaceActionException('Utilisateur non connecte.');
    }
    await _client.from('places').insert(draft.toInsert(userId));
  }

  /// Supprime un établissement (RLS : seul le propriétaire y est autorisé).
  Future<void> deletePlace(String placeId) async {
    if (BackendMode.isTemplate) {
      TemplateLodgingData.userPlaces.removeWhere((p) => p.id == placeId);
      return;
    }
    await _client.from('places').delete().eq('id', placeId);
  }

  /// Téléverse une photo sur Supabase Storage et renvoie son URL publique.
  Future<String> uploadPlacePhoto(
    Uint8List bytes, {
    required String fileExtension,
  }) async {
    if (BackendMode.isTemplate) {
      return 'https://picsum.photos/seed/up${DateTime.now().millisecondsSinceEpoch}/800/600';
    }
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw const PlaceActionException('Utilisateur non connecte.');
    }
    final ext = fileExtension.isEmpty ? 'jpg' : fileExtension;
    final path = '$userId/${DateTime.now().millisecondsSinceEpoch}.$ext';
    await _client.storage
        .from('place-photos')
        .uploadBinary(
          path,
          bytes,
          fileOptions: const FileOptions(upsert: true),
        );
    return _client.storage.from('place-photos').getPublicUrl(path);
  }

  Future<List<Place>> loadLatestActiveListings({
    UserLocation? userLocation,
    int offset = 0,
    int limit = defaultListingPageSize,
    PlaceFilter filter = const PlaceFilter(),
  }) async {
    if (BackendMode.isTemplate) {
      return TemplateLodgingData.queryListings(
        userLocation: userLocation,
        offset: offset,
        limit: limit,
        filter: filter,
      );
    }
    final rows = await _loadPlaces(
      offset: offset,
      limit: limit,
      filter: filter,
      prioritizeFeatured: false,
    );
    return _hydrate(rows, userLocation: userLocation);
  }

  Future<int> countActiveListings({
    PlaceFilter filter = const PlaceFilter(),
    String searchQuery = '',
  }) async {
    if (BackendMode.isTemplate) {
      return TemplateLodgingData.queryListings(
        filter: filter,
        searchQuery: searchQuery,
      ).length;
    }
    try {
      final amenityLabels = await _amenityLabelsForKeys(filter.amenityKeys);
      if (filter.amenityKeys.isNotEmpty && amenityLabels.isEmpty) return 0;

      var query = _client
          .from('places')
          .count(CountOption.exact)
          .eq('status', 'active');
      query = _applyFilters(query, filter, amenityLabels, searchQuery);
      return await query;
    } catch (_) {
      return 0;
    }
  }

  Future<List<Place>> loadActiveMapListings({
    UserLocation? userLocation,
    int offset = 0,
    int limit = 100,
    PlaceFilter filter = const PlaceFilter(),
  }) async {
    if (BackendMode.isTemplate) {
      return TemplateLodgingData.queryListings(
        userLocation: userLocation,
        offset: offset,
        limit: limit,
        filter: filter,
        requireCoordinates: true,
      );
    }
    final rows = await _loadPlaces(
      offset: offset,
      limit: limit,
      filter: filter,
      requireCoordinates: true,
      prioritizeFeatured: false,
    );
    return _hydrate(rows, userLocation: userLocation);
  }

  Future<Set<String>> loadSavedPlaceIds() async {
    if (BackendMode.isTemplate) return {};
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return {};
    try {
      final rows = await _client
          .from('saved_places')
          .select('place_id')
          .eq('user_id', userId);
      return _rowsToMaps(rows)
          .map((row) => stringValue(row['place_id']))
          .where((id) => id.isNotEmpty)
          .toSet();
    } catch (_) {
      return {};
    }
  }

  Future<List<Place>> loadSavedListings({
    UserLocation? userLocation,
  }) async {
    if (BackendMode.isTemplate) return const [];
    final savedIds = await loadSavedPlaceIds();
    if (savedIds.isEmpty) return const [];
    final rows = await _loadPlaces(
      placeIds: savedIds.toList(growable: false),
      limit: savedIds.length,
      prioritizeFeatured: false,
    );
    return _hydrate(rows, userLocation: userLocation);
  }

  Future<void> setSavedPlace({
    required String placeId,
    required bool saved,
  }) async {
    if (BackendMode.isTemplate) return;
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;
    if (saved) {
      await _client.from('saved_places').upsert({
        'user_id': userId,
        'place_id': placeId,
      });
    } else {
      await _client
          .from('saved_places')
          .delete()
          .eq('user_id', userId)
          .eq('place_id', placeId);
    }
  }

  Future<List<AmenityOption>> loadAmenities() async {
    if (BackendMode.isTemplate) return TemplateLodgingData.amenities;
    try {
      final rows = await _client
          .from('amenities')
          .select()
          .order('sort_order');
      return _rowsToMaps(rows)
          .map(AmenityOption.fromRow)
          .where((a) => a.key.isNotEmpty && a.label.isNotEmpty)
          .toList(growable: false);
    } catch (_) {
      return const [];
    }
  }

  /// « Lieux à proximité » : les autres établissements du catalogue les plus
  /// proches du lieu ouvert, classés par distance. Calcul 100 % local
  /// (haversine) — aucune table ni edge function externe requise.
  Future<List<NearbyPlace>> loadNearbyPlaces(
    Place listing, {
    bool forceRefresh = false,
  }) async {
    final lat = listing.latitude;
    final lng = listing.longitude;
    if (lat == null || lng == null) return const [];

    final catalogue = await loadActiveListings(limit: 200);

    final ranked = <({Place place, double km})>[];
    for (final place in catalogue) {
      if (place.id == listing.id) continue;
      final plat = place.latitude;
      final plng = place.longitude;
      if (plat == null || plng == null) continue;
      ranked.add((place: place, km: haversineKm(lat, lng, plat, plng)));
    }
    ranked.sort((a, b) => a.km.compareTo(b.km));

    final nearest = ranked.take(6).toList(growable: false);
    return [
      for (var i = 0; i < nearest.length; i++)
        NearbyPlace(
          id: nearest[i].place.id,
          placeId: listing.id,
          name: nearest[i].place.title,
          category: nearest[i].place.category,
          categoryLabel: nearest[i].place.categoryLabel,
          iconKey: nearest[i].place.category,
          latitude: nearest[i].place.latitude ?? 0,
          longitude: nearest[i].place.longitude ?? 0,
          address: nearest[i].place.locationLabel,
          distanceMeters: (nearest[i].km * 1000).round(),
          sortOrder: i,
          algorithmVersion: nearbyAlgorithmVersion,
          calculatedAt: DateTime.now(),
        ),
    ];
  }

  Future<void> submitSupportRequest({
    required String reason,
    required String message,
  }) async {
    if (BackendMode.isTemplate) return;
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw const PlaceActionException('Utilisateur non connecté.');
    }
    final profile = await loadCurrentProfile();
    final fallbackEmail = _client.auth.currentUser?.email ?? '';
    final resolvedEmail = profile?.email.isNotEmpty == true
        ? profile!.email
        : fallbackEmail;

    await _client.from('support_requests').insert({
      if (resolvedEmail.isNotEmpty) 'email': resolvedEmail,
      'subject': reason.trim(),
      'reason': reason.trim(),
      'message': message.trim(),
      'status': 'new',
      'user_id': userId,
    });
  }

  Future<void> reportPlace({
    required Place listing,
    required String reason,
    String? message,
  }) async {
    if (BackendMode.isTemplate) return;
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw const PlaceActionException('Utilisateur non connecté.');
    }
    final cleanReason = reason.trim();
    final cleanMessage = message?.trim() ?? '';
    if (cleanReason.isEmpty) {
      throw const PlaceActionException('Motif manquant.');
    }
    try {
      await _client.from('place_reports').insert({
        'place_id': listing.id,
        'reporter_id': userId,
        'reason': cleanReason,
        if (cleanMessage.isNotEmpty) 'message': cleanMessage,
        'status': 'new',
      });
    } on PostgrestException catch (error) {
      if (!error.message.contains('place_reports')) rethrow;
      await submitSupportRequest(
        reason: 'Établissement suspect',
        message:
            'Signalement\n'
            'Établissement: ${listing.title}\n'
            'ID: ${listing.id}\n'
            'Motif: $cleanReason\n\n'
            '${cleanMessage.isEmpty ? 'Aucun détail ajouté.' : cleanMessage}',
      );
    }
  }

  Future<void> requestAccountDeletion({String? reason}) async {
    if (BackendMode.isTemplate) return;
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw const PlaceActionException('Utilisateur non connecté.');
    }
    final existing = await _client
        .from('account_deletion_requests')
        .select('id')
        .eq('user_id', userId)
        .eq('status', 'pending')
        .maybeSingle();
    if (existing != null) return;

    final profile = await loadCurrentProfile();
    final email = profile?.email.isNotEmpty == true
        ? profile!.email
        : _client.auth.currentUser?.email ?? '';

    await _client.from('account_deletion_requests').insert({
      'user_id': userId,
      if (email.isNotEmpty) 'email': email,
      if (reason?.trim().isNotEmpty == true) 'reason': reason!.trim(),
      'status': 'pending',
    });
  }

  Future<void> updateProfile(Map<String, dynamic> values) async {
    if (BackendMode.isTemplate) return;
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;
    await _client.from('profiles').update(values).eq('id', userId);
  }

  // ----- Helpers internes ------------------------------------------------

  List<Place> _hydrate(
    List<Map<String, dynamic>> rows, {
    UserLocation? userLocation,
  }) {
    return [
      for (final row in rows)
        Place.fromMaps(row: row, userLocation: userLocation),
    ];
  }

  Future<List<Map<String, dynamic>>> _loadPlaces({
    List<String>? placeIds,
    int offset = 0,
    int limit = defaultListingPageSize,
    PlaceFilter filter = const PlaceFilter(),
    String searchQuery = '',
    bool requireCoordinates = false,
    bool prioritizeFeatured = true,
  }) async {
    final amenityLabels = await _amenityLabelsForKeys(filter.amenityKeys);
    if (filter.amenityKeys.isNotEmpty && amenityLabels.isEmpty) return const [];

    var query = _client.from('places').select().eq('status', 'active');
    if (placeIds != null) {
      if (placeIds.isEmpty) return const [];
      query = query.inFilter('id', placeIds);
    }
    if (requireCoordinates) {
      query = query.not('latitude', 'is', null).not('longitude', 'is', null);
    }
    query = _applyFilters(query, filter, amenityLabels, searchQuery);

    final rows =
        await (prioritizeFeatured
                ? query
                      .order('is_featured', ascending: false)
                      .order('created_at', ascending: false)
                : query.order('created_at', ascending: false))
            .order('id', ascending: false)
            .range(offset, offset + limit - 1);
    return _rowsToMaps(rows);
  }

  /// Applique catégorie / sous-type / prix / équipements / recherche.
  /// Générique sur le type de requête (select renvoie une liste, count un int) ;
  /// les méthodes de `PostgrestFilterBuilder<T>` renvoient le même `T`, sans cast.
  PostgrestFilterBuilder<T> _applyFilters<T>(
    PostgrestFilterBuilder<T> query,
    PlaceFilter filter,
    List<String> amenityLabels,
    String searchQuery,
  ) {
    var q = query;
    if (filter.category != null && filter.category!.isNotEmpty) {
      q = q.eq('category', filter.category!);
    }
    if (filter.subtype != null && filter.subtype!.isNotEmpty) {
      q = q.eq('subtype', filter.subtype!);
    }
    if (filter.minPrice != null) {
      q = q.gte('price', filter.minPrice!);
    }
    if (filter.maxPrice != null) {
      q = q.lte('price', filter.maxPrice!);
    }
    if (amenityLabels.isNotEmpty) {
      q = q.contains('amenities', amenityLabels);
    }
    final terms = _searchTerms(searchQuery, filter.zones);
    if (terms.isNotEmpty) {
      q = q.or(
        terms
            .expand(
              (term) => [
                'title.ilike.%$term%',
                'city.ilike.%$term%',
                'neighborhood.ilike.%$term%',
                'address.ilike.%$term%',
              ],
            )
            .join(','),
      );
    }
    return q;
  }

  /// Traduit des clés d'équipement en libellés (colonne `places.amenities`).
  Future<List<String>> _amenityLabelsForKeys(Set<String> keys) async {
    if (keys.isEmpty) return const [];
    try {
      final rows = _rowsToMaps(
        await _client
            .from('amenities')
            .select('label')
            .inFilter('key', keys.toList(growable: false)),
      );
      return rows
          .map((row) => stringValue(row['label']))
          .where((label) => label.isNotEmpty)
          .toList(growable: false);
    } catch (_) {
      return const [];
    }
  }

  List<String> _searchTerms(String searchQuery, List<String> zones) {
    return [...searchQuery.split(','), ...zones]
        .map(_sanitizeSearchTerm)
        .where((term) => term.length >= 2)
        .toSet()
        .toList(growable: false);
  }

  String _sanitizeSearchTerm(String value) {
    return value
        .trim()
        .replaceAll(RegExp(r'[%_,()]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ');
  }

  List<Map<String, dynamic>> _rowsToMaps(Object? rows) {
    if (rows is! List) return const [];
    return rows
        .whereType<Map>()
        .map((row) => Map<String, dynamic>.from(row))
        .toList();
  }
}

class PlaceActionException implements Exception {
  const PlaceActionException(this.message);

  final String message;

  @override
  String toString() => message;
}
