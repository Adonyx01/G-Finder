import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/app_background.dart';
import '../../core/app_router.dart';
import '../../core/backend_mode.dart';
import '../../core/theme.dart';
import '../../features/account/account_capabilities.dart';
import '../../features/places/models/place.dart';
import '../../features/places/screens/full_map_screen.dart';
import '../../features/places/services/place_service.dart';
import '../../features/places/widgets/chezmoi_map_view.dart';
import '../../features/places/widgets/listing_reference.dart';
import '../../services/location_search_service.dart';
import '../../shared/widgets/akasha_footer.dart';
import 'widgets/bottom_nav_bar.dart';
import 'widgets/dashboard_common.dart';
import 'widgets/favorites_tab.dart';
import 'widgets/latest_feed_tab.dart';
import 'widgets/listing_tabs.dart';
import 'widgets/profile_tab.dart';
import 'widgets/place_detail_sheet.dart';

const Object _unchanged = Object();

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _searchController = TextEditingController();
  final _placeService = PlaceService();
  final _accountService = AccountCapabilitiesService();
  final _locationSearchService = LocationSearchService();
  final _homeScrollController = ScrollController();
  final _mapSearchController = TextEditingController();
  final _minBudgetController = TextEditingController();
  final _maxBudgetController = TextEditingController();
  Timer? _searchDebounce;
  Timer? _mapSearchDebounce;
  Timer? _countDebounce;
  StreamSubscription<AuthState>? _authSubscription;
  OverlayEntry? _topNoticeEntry;

  List<Place> _listings = [];
  List<Place> _savedListings = const [];
  List<AmenityOption> _amenities = const [];
  Set<String> _savedPlaceIds = {};
  PlaceFilter _filter = const PlaceFilter();
  int _selectedTabIndex = 0;
  bool _notifyNewMatches = true;
  bool _notifyEnquiries = true;
  bool _pinRent = true;
  bool _requestingAccountDeletion = false;
  ChezMoiProfile? _profile;
  bool _isLoading = true;
  bool _profileLoading = true;
  bool _searchingLocation = false;
  bool _loadingMoreListings = false;
  bool _hasMoreListings = true;
  bool _loadingMapListings = false;
  bool _signingOut = false;
  bool _hasSearched = false;
  bool _showAmenities = false;
  bool _countLoading = false;
  bool _searchingMapLocation = false;
  AccountCapabilities _account = AccountCapabilities.signedOut(loading: true);
  int _nextListingOffset = 0;
  int? _matchingCount;
  String? _error;
  String? _mapError;
  String? _selectedListingId;
  List<Place> _mapListings = const [];
  List<LocationSearchResult> _searchSuggestions = const [];
  List<LocationSearchResult> _mapSearchSuggestions = const [];

  bool get _hasCurrentUser =>
      BackendMode.isTemplate ||
      Supabase.instance.client.auth.currentUser != null;

  @override
  void initState() {
    super.initState();
    _homeScrollController.addListener(_maybeLoadMoreListings);
    _searchController.addListener(_scheduleSearchCount);
    _minBudgetController.addListener(_handleMinBudgetChanged);
    _maxBudgetController.addListener(_scheduleSearchCount);
    if (BackendMode.useSupabase) {
      _authSubscription = Supabase.instance.client.auth.onAuthStateChange
          .listen(_handleAuthStateChanged);
    }
    _loadBootstrap();
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _searchDebounce?.cancel();
    _mapSearchDebounce?.cancel();
    _countDebounce?.cancel();
    _searchController.removeListener(_scheduleSearchCount);
    _topNoticeEntry?.remove();
    _minBudgetController.removeListener(_handleMinBudgetChanged);
    _maxBudgetController.removeListener(_scheduleSearchCount);
    _minBudgetController.dispose();
    _maxBudgetController.dispose();
    _mapSearchController.dispose();
    _homeScrollController.dispose();
    _locationSearchService.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _showTopNotice(
    String message, {
    IconData icon = Icons.check_rounded,
    Color color = const Color(0xFF16A34A),
  }) {
    _topNoticeEntry?.remove();
    final overlay = Overlay.of(context);
    final entry = OverlayEntry(
      builder: (context) {
        final colors = context.chezMoiColors;
        return Positioned(
          top: MediaQuery.paddingOf(context).top + 12,
          left: 16,
          right: 16,
          child: IgnorePointer(
            child: Material(
              color: Colors.transparent,
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: -18, end: 0),
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOutCubic,
                builder: (context, value, child) =>
                    Transform.translate(offset: Offset(0, value), child: child),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: colors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: color.withValues(alpha: 0.24)),
                    boxShadow: [
                      BoxShadow(
                        color: colors.navy.withValues(alpha: 0.14),
                        blurRadius: 22,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(icon, color: color, size: 18),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          message,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: colors.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
    _topNoticeEntry = entry;
    overlay.insert(entry);
    Future<void>.delayed(const Duration(seconds: 1), () {
      if (_topNoticeEntry != entry) return;
      entry.remove();
      _topNoticeEntry = null;
    });
  }

  List<Place> get _visibleListings => _listings;

  List<Place> get _favoriteListings {
    final byId = <String, Place>{
      for (final listing in _savedListings) listing.id: listing,
      for (final listing in _listings)
        if (_savedPlaceIds.contains(listing.id)) listing.id: listing,
      for (final listing in _mapListings)
        if (_savedPlaceIds.contains(listing.id)) listing.id: listing,
    };
    return byId.values.toList(growable: false);
  }

  List<Place> get _visibleMapListings =>
      _pinRent ? _mapListings : const <Place>[];

  int _tabForAccount(AccountCapabilities account, int currentTab) {
    const travelerTabs = {0, 1, 2, 3, 4};
    return travelerTabs.contains(currentTab) ? currentTab : 0;
  }

  int get _bottomNavSelectedIndex {
    if (_selectedTabIndex == 6) return 0;
    return _selectedTabIndex;
  }

  Future<void> _loadBootstrap() async {
    setState(() {
      _isLoading = false;
      _account = AccountCapabilities.signedOut(loading: true);
      _profileLoading = true;
    });
    try {
      final results = await Future.wait([
        _accountService.loadCurrent(),
        _placeService.loadSavedPlaceIds(),
        _placeService.loadAmenities(),
        _placeService.loadSavedListings(),
      ]);
      final account = results[0] as AccountCapabilities;
      final savedIds = results[1] as Set<String>;
      final amenities = results[2] as List<AmenityOption>;
      final savedListings = results[3] as List<Place>;
      if (!mounted) return;
      setState(() {
        _account = account;
        _profile = account.profile;
        _selectedTabIndex = _tabForAccount(account, _selectedTabIndex);
        _savedPlaceIds = savedIds;
        _savedListings = savedListings;
        _amenities = amenities;
        _profileLoading = false;
      });
      await _loadLocalPreferences();
      _scheduleSearchCount();
    } catch (_) {
      if (!mounted) return;
      setState(() => _profileLoading = false);
    }
  }

  Future<void> _loadLocalPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _notifyNewMatches =
          prefs.getBool('chezmoi_notify_new_matches') ?? _notifyNewMatches;
      _notifyEnquiries =
          prefs.getBool('chezmoi_notify_enquiries') ?? _notifyEnquiries;
      _pinRent = prefs.getBool('chezmoi_pin_rent') ?? _pinRent;
    });
  }

  Future<void> _setLocalPreference(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  void _handleAuthStateChanged(AuthState state) {
    if (!mounted) return;
    if (state.event == AuthChangeEvent.signedIn ||
        state.event == AuthChangeEvent.tokenRefreshed ||
        state.event == AuthChangeEvent.userUpdated) {
      setState(() {
        _account = AccountCapabilities.signedOut(loading: true);
        _profileLoading = true;
      });
      _loadBootstrap();
      return;
    }
    if (state.event == AuthChangeEvent.signedOut) {
      setState(() {
        _account = AccountCapabilities.signedOut();
        _profile = null;
        _selectedTabIndex = _tabForAccount(
          AccountCapabilities.signedOut(),
          _selectedTabIndex,
        );
        _savedPlaceIds = {};
        _savedListings = const [];
        _profileLoading = false;
      });
    }
  }

  Future<void> _loadListings() async {
    setState(() {
      _isLoading = true;
      _loadingMoreListings = false;
      _hasMoreListings = true;
      _nextListingOffset = 0;
      _listings = const [];
      _error = null;
    });
    try {
      final account = await _accountService.loadCurrent();
      final profile = account.profile;
      final results = await Future.wait([
        _placeService.loadActiveListings(
          userLocation: profile?.userLocation,
          offset: 0,
          limit: PlaceService.defaultListingPageSize,
          filter: _filter,
          searchQuery: _searchController.text,
        ),
        _placeService.loadSavedPlaceIds(),
        _placeService.loadSavedListings(userLocation: profile?.userLocation),
      ]);
      final listings = results[0] as List<Place>;
      final savedIds = results[1] as Set<String>;
      final savedListings = results[2] as List<Place>;
      if (!mounted) return;
      setState(() {
        _account = account;
        _profile = profile;
        _selectedTabIndex = _tabForAccount(account, _selectedTabIndex);
        _listings = listings;
        if (_selectedTabIndex == 1) _mapListings = listings;
        _savedPlaceIds = savedIds;
        _savedListings = savedListings;
        _profileLoading = false;
        _hasMoreListings =
            listings.length == PlaceService.defaultListingPageSize;
        _nextListingOffset = listings.length;
        _selectedListingId = _selectedListingIdFor(listings);
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _profileLoading = false;
        _error = 'Impossible de charger les établissements.';
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadMoreListings() async {
    if (_isLoading || _loadingMoreListings || !_hasMoreListings) return;
    setState(() => _loadingMoreListings = true);
    try {
      final nextListings = await _placeService.loadActiveListings(
        userLocation: _profile?.userLocation,
        offset: _nextListingOffset,
        limit: PlaceService.defaultListingPageSize,
        filter: _filter,
        searchQuery: _searchController.text,
      );
      if (!mounted) return;
      final existingIds = _listings.map((listing) => listing.id).toSet();
      setState(() {
        _listings = [
          ..._listings,
          ...nextListings.where((listing) => !existingIds.contains(listing.id)),
        ];
        _hasMoreListings =
            nextListings.length == PlaceService.defaultListingPageSize;
        _nextListingOffset += nextListings.length;
        _selectedListingId = _selectedListingIdFor(_listings);
      });
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Impossible de charger plus d\'établissements.')),
      );
    } finally {
      if (mounted) setState(() => _loadingMoreListings = false);
    }
  }

  Future<void> _loadMapListings() async {
    if (_loadingMapListings) return;
    setState(() {
      _loadingMapListings = true;
      _mapError = null;
    });
    try {
      final profile = _profile ?? await _placeService.loadCurrentProfile();
      final listings = <Place>[];
      var offset = 0;
      const batchSize = 100;
      while (true) {
        final batch = await _placeService.loadActiveMapListings(
          userLocation: profile?.userLocation,
          offset: offset,
          limit: batchSize,
        );
        listings.addAll(batch);
        if (batch.length < batchSize) break;
        offset += batch.length;
      }
      if (!mounted) return;
      setState(() {
        _profile = profile;
        _mapListings = listings;
        _selectedListingId = _selectedListingIdFor(listings);
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _mapError = 'Impossible de charger la carte.');
    } finally {
      if (mounted) setState(() => _loadingMapListings = false);
    }
  }

  void _maybeLoadMoreListings() {
    if ((_selectedTabIndex != 0 && _selectedTabIndex != 6) ||
        !_hasSearched ||
        !_homeScrollController.hasClients) {
      return;
    }
    if (_homeScrollController.position.extentAfter < 700) {
      _loadMoreListings();
    }
  }

  Future<void> _signOut() async {
    setState(() => _signingOut = true);
    try {
      if (BackendMode.useSupabase) {
        await Supabase.instance.client.auth.signOut();
      }
      if (mounted) context.go('/loading-dashboard');
    } finally {
      if (mounted) setState(() => _signingOut = false);
    }
  }

  Future<void> _confirmSignOut() async {
    final shouldSignOut = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.22),
      builder: (context) => const _SignOutSheet(),
    );
    if (shouldSignOut == true) await _signOut();
  }

  Future<void> _refreshHome() {
    if (_hasSearched) return _loadListings();
    return _loadBootstrap();
  }

  void _performSearch() {
    FocusScope.of(context).unfocus();
    final nextFilter = _filterWithBudget();
    setState(() {
      _hasSearched = true;
      _filter = nextFilter;
      _selectedTabIndex = 6;
    });
    _showTopNotice(
      'Filtres appliqués',
      icon: Icons.tune_rounded,
      color: const Color(0xFF1677E8),
    );
    _loadListings();
  }

  void _scheduleSearchCount() {
    _countDebounce?.cancel();
    _countDebounce = Timer(const Duration(milliseconds: 300), _loadSearchCount);
  }

  Future<void> _loadSearchCount() async {
    if (!mounted) return;
    setState(() => _countLoading = true);
    final count = await _placeService.countActiveListings(
      filter: _filterWithBudget(),
      searchQuery: _searchController.text,
    );
    if (!mounted) return;
    setState(() {
      _matchingCount = count;
      _countLoading = false;
    });
  }

  void _handleMinBudgetChanged() {
    final min = num.tryParse(_minBudgetController.text.trim());
    final max = num.tryParse(_maxBudgetController.text.trim());
    if (min == null && _maxBudgetController.text.trim().isNotEmpty) {
      _maxBudgetController.clear();
    } else if (min != null && max != null && max < min) {
      _maxBudgetController.text = min.round().toString();
      _maxBudgetController.selection = TextSelection.collapsed(
        offset: _maxBudgetController.text.length,
      );
    }
    _scheduleSearchCount();
  }

  void _updateInlineFilter({Object? subtype = _unchanged}) {
    setState(() {
      _filter = PlaceFilter(
        category: _filter.category,
        subtype: identical(subtype, _unchanged)
            ? _filter.subtype
            : subtype as String?,
        minPrice: _filter.minPrice,
        maxPrice: _filter.maxPrice,
        zones: _filter.zones,
        amenityKeys: _filter.amenityKeys,
        maxDistanceKm: _filter.maxDistanceKm,
        availableNow: _filter.availableNow,
      );
    });
    _scheduleSearchCount();
  }

  void _selectCategory(String? category) {
    FocusScope.of(context).unfocus();
    setState(() {
      _filter = PlaceFilter(
        category: category,
        // Le sous-type (types d'hotel) ne concerne que les hotels.
        subtype: category == 'hotel' ? _filter.subtype : null,
        minPrice: _filter.minPrice,
        maxPrice: _filter.maxPrice,
        zones: _filter.zones,
        amenityKeys: _filter.amenityKeys,
        maxDistanceKm: _filter.maxDistanceKm,
        availableNow: _filter.availableNow,
      );
    });
    _scheduleSearchCount();
  }

  PlaceFilter _filterWithBudget() {
    return PlaceFilter(
      category: _filter.category,
      subtype: _filter.subtype,
      minPrice: num.tryParse(_minBudgetController.text.trim()),
      maxPrice: num.tryParse(_maxBudgetController.text.trim()),
      zones: _filter.zones,
      amenityKeys: _filter.amenityKeys,
      maxDistanceKm: _filter.maxDistanceKm,
      availableNow: _filter.availableNow,
    );
  }

  void _toggleAmenities() {
    setState(() => _showAmenities = !_showAmenities);
  }

  void _toggleAmenity(String key, bool selected) {
    setState(() {
      final amenityKeys = {..._filter.amenityKeys};
      if (selected) {
        amenityKeys.add(key);
      } else {
        amenityKeys.remove(key);
      }
      _filter = PlaceFilter(
        category: _filter.category,
        subtype: _filter.subtype,
        minPrice: _filter.minPrice,
        maxPrice: _filter.maxPrice,
        zones: _filter.zones,
        amenityKeys: amenityKeys,
        maxDistanceKm: _filter.maxDistanceKm,
        availableNow: _filter.availableNow,
      );
    });
    _scheduleSearchCount();
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

  void _searchMapLocations(String value) {
    _mapSearchDebounce?.cancel();
    final query = value.split(',').last.trim();
    if (query.length < 2) {
      setState(() {
        _mapSearchSuggestions = const [];
        _searchingMapLocation = false;
      });
      return;
    }
    setState(() => _searchingMapLocation = true);
    _mapSearchDebounce = Timer(const Duration(milliseconds: 300), () async {
      try {
        final suggestions = await _locationSearchService.autocomplete(
          query,
          countryCode: 'GA',
          lat: 0.3924,
          lng: 9.4582,
        );
        if (!mounted ||
            _mapSearchController.text.split(',').last.trim() != query) {
          return;
        }
        setState(() {
          _mapSearchSuggestions = suggestions;
          _searchingMapLocation = false;
        });
      } catch (_) {
        if (!mounted) return;
        setState(() {
          _mapSearchSuggestions = const [];
          _searchingMapLocation = false;
        });
      }
    });
  }

  void _selectMapSearchLocation(LocationSearchResult result) {
    final zone = result.suburb.isNotEmpty
        ? result.suburb
        : result.city.isNotEmpty
        ? result.city
        : result.label;
    setState(() {
      _mapSearchController.text = zone;
      _mapSearchController.selection = TextSelection.collapsed(
        offset: _mapSearchController.text.length,
      );
      _mapSearchSuggestions = const [];
    });
    _focusMapZone(zone);
  }

  void _clearMapSearch() {
    setState(() {
      _mapSearchController.clear();
      _mapSearchSuggestions = const [];
    });
  }

  void _focusMapZone(String zone) {
    final query = zone.trim();
    if (query.isEmpty) return;
    for (final listing in _mapListings) {
      if (listing.hasCoordinates && listing.matchesSearch(query)) {
        setState(() => _selectedListingId = listing.id);
        return;
      }
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Aucun établissement trouvé dans cette zone.')),
    );
  }

  Future<void> _toggleSaved(Place listing) async {
    if (!_hasCurrentUser) {
      _showAuthRequiredSheet(
        context,
        title: 'Ajouter aux favoris',
        message:
            'Connectez-vous pour enregistrer vos établissements préférés et les retrouver facilement.',
      );
      return;
    }
    final nextSaved = !_savedPlaceIds.contains(listing.id);
    setState(() {
      if (nextSaved) {
        _savedPlaceIds.add(listing.id);
        if (!_savedListings.any((item) => item.id == listing.id)) {
          _savedListings = [listing, ..._savedListings];
        }
      } else {
        _savedPlaceIds.remove(listing.id);
        _savedListings = _savedListings
            .where((item) => item.id != listing.id)
            .toList(growable: false);
      }
    });
    try {
      await _placeService.setSavedPlace(
        placeId: listing.id,
        saved: nextSaved,
      );
      if (!mounted) return;
      _showTopNotice(
        nextSaved
            ? 'Ajouté aux favoris'
            : 'Retiré des favoris',
        icon: nextSaved ? Icons.favorite_rounded : Icons.heart_broken_rounded,
        color: nextSaved ? const Color(0xFFFF5A5F) : const Color(0xFF6B7280),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() {
        if (nextSaved) {
          _savedPlaceIds.remove(listing.id);
          _savedListings = _savedListings
              .where((item) => item.id != listing.id)
              .toList(growable: false);
        } else {
          _savedPlaceIds.add(listing.id);
          if (!_savedListings.any((item) => item.id == listing.id)) {
            _savedListings = [listing, ..._savedListings];
          }
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Impossible de mettre à jour le favori.')),
      );
    }
  }

  void _openPlaceDetails(Place listing) {
    setState(() => _selectedListingId = listing.id);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      enableDrag: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.22),
      builder: (context) => PlaceDetailSheet(
        listing: listing,
        onContactNotice: _showFloatingTopNotice,
        onAuthRequired: () => _showAuthRequiredSheet(
          context,
          title: 'Réserver',
          message: 'Connectez-vous pour envoyer une demande de réservation.',
        ),
        onShowOnMap: listing.hasCoordinates
            ? () => _showListingOnMap(listing)
            : null,
      ),
    );
  }

  void _contactSupport() {
    if (!_hasCurrentUser) {
      _showAuthRequiredSheet(
        context,
        title: 'Contacter le support',
        message:
            'Connectez-vous pour contacter l\'équipe ChezMoi avec votre compte.',
      );
      return;
    }
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.22),
      builder: (context) => SupportRequestSheet(profile: _profile),
    );
  }

  void _openAccountSettings() {
    if (!_hasCurrentUser) {
      _showAuthRequiredSheet(
        context,
        title: 'Paramètres de compte',
        message:
            'Connectez-vous pour modifier les informations de votre compte.',
      );
      return;
    }
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.22),
      builder: (context) => AccountSettingsSheet(
        profile: _profile,
        onSignOut: () {
          Navigator.pop(context);
          _confirmSignOut();
        },
        onDeactivate: _requestAccountDeletion,
      ),
    );
  }

  void _openFavoritesTab() {
    if (!_hasCurrentUser) {
      _showAuthRequiredSheet(
        context,
        title: 'Favoris',
        message:
            'Connectez-vous pour retrouver facilement les établissements que vous aimez.',
      );
      return;
    }
    setState(() => _selectedTabIndex = 3);
  }

  void _openPreferences() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.22),
      builder: (context) => AppPreferencesSheet(
        notifyNewMatches: _notifyNewMatches,
        notifyEnquiries: _notifyEnquiries,
        pinRent: _pinRent,
        onNotifyNewMatchesChanged: (value) {
          setState(() => _notifyNewMatches = value);
          _setLocalPreference('chezmoi_notify_new_matches', value);
        },
        onNotifyEnquiriesChanged: (value) {
          setState(() => _notifyEnquiries = value);
          _setLocalPreference('chezmoi_notify_enquiries', value);
        },
        onPinRentChanged: (value) {
          setState(() => _pinRent = value);
          _setLocalPreference('chezmoi_pin_rent', value);
        },
      ),
    );
  }

  Future<void> _requestAccountDeletion() async {
    if (_requestingAccountDeletion) return;
    final shouldRequest = await showDialog<bool>(
      context: context,
      builder: (context) {
        final colors = context.chezMoiColors;
        return AlertDialog(
          icon: Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: colors.danger.withValues(alpha: 0.10),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.no_accounts_outlined, color: colors.danger),
          ),
          title: const Text('Désactiver le compte ?'),
          content: Text(
            'Nous enregistrerons votre demande de suppression. L\'équipe ChezMoi vérifiera vos favoris, réservations et demandes associées avant fermeture définitive.',
            textAlign: TextAlign.center,
            style: TextStyle(color: colors.textSecondary, height: 1.35),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Annuler'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: colors.danger),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Envoyer la demande'),
            ),
          ],
        );
      },
    );
    if (shouldRequest != true) return;

    setState(() => _requestingAccountDeletion = true);
    try {
      await _placeService.requestAccountDeletion(
        reason: 'Demande depuis les paramètres ChezMoi.',
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Demande de désactivation envoyée.')),
      );
      await _signOut();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Impossible d\'envoyer la demande.')),
      );
    } finally {
      if (mounted) setState(() => _requestingAccountDeletion = false);
    }
  }

  void _selectListing(Place listing, {bool openDetails = true}) {
    setState(() => _selectedListingId = listing.id);
    if (openDetails) _openPlaceDetails(listing);
  }

  void _openMapListingPreview(Place listing) {
    setState(() => _selectedListingId = listing.id);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.22),
      builder: (context) => _MapListingPreviewSheet(
        listing: listing,
        onViewDetails: () {
          Navigator.pop(context);
          _openPlaceDetails(listing);
        },
        onContact: () {
          Navigator.pop(context);
          openReservationForListing(
            context,
            listing,
            onAuthRequired: () => _showAuthRequiredSheet(
              context,
              title: 'Réserver',
              message:
                  'Connectez-vous pour envoyer une demande de réservation.',
            ),
            onNotice: _showFloatingTopNotice,
          );
        },
      ),
    );
  }

  Future<void> _showListingOnMap(Place listing) async {
    if (!listing.hasCoordinates) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Cet établissement n\'a pas encore de position sur la carte.',
          ),
        ),
      );
      return;
    }
    setState(() => _selectedListingId = listing.id);
    await context.push(
      '/map',
      extra: FullMapRouteExtra(
        initialListing: listing,
        openedFromPlace: true,
      ),
    );
    if (!mounted) return;
    _openPlaceDetails(listing);
  }

  void _selectBottomNav(int index) {
    if (index == 3 && !_hasCurrentUser) {
      _showAuthRequiredSheet(
        context,
        title: 'Favoris',
        message:
            'Connectez-vous pour retrouver facilement les établissements que vous aimez.',
      );
      return;
    }
    setState(() => _selectedTabIndex = index);
    if (index == 1 && _mapListings.isEmpty) {
      _loadMapListings();
    }
  }

  String? _selectedListingIdFor(List<Place> listings) {
    if (listings.any((listing) => listing.id == _selectedListingId)) {
      return _selectedListingId;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.chezMoiColors;
    final visibleListings = _visibleListings;

    if (_profileLoading && _account.loading) {
      return Scaffold(
        backgroundColor: colors.background,
        body: const Stack(
          children: [
            Positioned.fill(child: ChezMoiBackgroundLayer()),
            Center(child: CircularProgressIndicator()),
          ],
        ),
      );
    }

    return Scaffold(
      extendBody: _selectedTabIndex == 1,
      backgroundColor: colors.background,
      body: Stack(
        children: [
          if (_selectedTabIndex != 1)
            const Positioned.fill(child: ChezMoiBackgroundLayer()),
          Positioned.fill(child: _buildSelectedTab(visibleListings)),
          if (_signingOut)
            Positioned.fill(
              child: ColoredBox(
                color: colors.background.withValues(alpha: 0.72),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 18,
                    ),
                    decoration: BoxDecoration(
                      color: colors.surface,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: colors.border),
                      boxShadow: [
                        BoxShadow(
                          color: colors.textPrimary.withValues(alpha: 0.10),
                          blurRadius: 20,
                          offset: const Offset(0, 14),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.4,
                            color: colors.primaryBlue,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Déconnexion...',
                          style: TextStyle(
                            color: colors.textPrimary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: DashboardBottomNavBar(
        selectedIndex: _bottomNavSelectedIndex,
        items: DashboardBottomNavBar.defaultItems,
        onSelected: _selectBottomNav,
      ),
    );
  }

  Widget _buildSelectedTab(List<Place> visibleListings) {
    return switch (_selectedTabIndex) {
      1 => _MapTab(
        visibleListings: _visibleMapListings,
        selectedListingId: _selectedListingId,
        profile: _profile,
        loading: _loadingMapListings,
        error: _mapError,
        bottomPadding: _dashboardBottomPadding(context, underBottomBar: true),
        onRetry: _loadMapListings,
        onListingTap: _openMapListingPreview,
        mapSearchController: _mapSearchController,
        mapSearchSuggestions: _mapSearchSuggestions,
        searchingMapLocation: _searchingMapLocation,
        onMapSearchChanged: _searchMapLocations,
        onMapSearchSubmitted: _focusMapZone,
        onMapSuggestionSelected: _selectMapSearchLocation,
        onClearMapSearch: _clearMapSearch,
      ),
      2 => LatestListingsTab(
        loader: () => _placeService.loadLatestActiveListings(
          userLocation: _profile?.userLocation,
        ),
        savedPlaceIds: _savedPlaceIds,
        bottomPadding: _dashboardBottomPadding(context),
        onListingTap: _openPlaceDetails,
        onSaveTap: _toggleSaved,
      ),
      3 => FavoritesHubTab(
        favoriteListings: _favoriteListings,
        savedPlaceIds: _savedPlaceIds,
        bottomPadding: _dashboardBottomPadding(context),
        onListingTap: _openPlaceDetails,
        onSaveTap: _toggleSaved,
      ),
      4 => ProfileTab(
        profile: _profile,
        account: _account,
        loadingProfile: _profileLoading,
        bottomPadding: _dashboardBottomPadding(context),
        onOpenFavorites: _openFavoritesTab,
        onOpenAccountSettings: _openAccountSettings,
        onOpenPreferences: _openPreferences,
        onContactSupport: _contactSupport,
      ),
      6 => _SearchResultsTab(
        loading: _isLoading,
        loadingMore: _loadingMoreListings,
        error: _error,
        listings: visibleListings,
        savedPlaceIds: _savedPlaceIds,
        scrollController: _homeScrollController,
        bottomPadding: _dashboardBottomPadding(context),
        onBackToSearch: () => setState(() => _selectedTabIndex = 0),
        onRetry: _loadListings,
        onListingTap: _openPlaceDetails,
        onSaveTap: _toggleSaved,
      ),
      _ => _MapHomeTab(
        latestLoader: () => _placeService.loadLatestActiveListings(
          userLocation: _profile?.userLocation,
          limit: 6,
        ),
        loading: _isLoading,
        loadingMore: _loadingMoreListings,
        error: _error,
        allListingsEmpty: _listings.isEmpty,
        hasSearched: _hasSearched,
        visibleListings: visibleListings,
        savedPlaceIds: _savedPlaceIds,
        amenities: _amenities,
        filter: _filter,
        showAmenities: _showAmenities,
        matchingCount: _matchingCount,
        countLoading: _countLoading,
        minBudgetController: _minBudgetController,
        maxBudgetController: _maxBudgetController,
        scrollController: _homeScrollController,
        searchController: _searchController,
        searchSuggestions: _searchSuggestions,
        searchingLocation: _searchingLocation,
        bottomPadding: _dashboardBottomPadding(context),
        onRefresh: _refreshHome,
        onRetry: _loadListings,
        onToggleAmenities: _toggleAmenities,
        onAmenityChanged: _toggleAmenity,
        onSearch: _performSearch,
        onSearchChanged: _searchLocations,
        onSuggestionSelected: _selectSearchLocation,
        onSubtypeChanged: (value) =>
            _updateInlineFilter(subtype: value),
        onCategoryChanged: _selectCategory,
        onResetFilters: () {
          _searchController.clear();
          _minBudgetController.clear();
          _maxBudgetController.clear();
          setState(() {
            _filter = const PlaceFilter();
            _listings = const [];
            _error = null;
            _hasSearched = false;
            _showAmenities = false;
            _matchingCount = null;
          });
          _scheduleSearchCount();
          _showTopNotice(
            'Recherche réinitialisée',
            icon: Icons.restart_alt_rounded,
            color: const Color(0xFF1677E8),
          );
        },
        onListingTap: (listing) => _selectListing(listing),
        onSaveTap: _toggleSaved,
        onExpandMap: () => _selectBottomNav(1),
      ),
    };
  }
}

double _dashboardBottomPadding(
  BuildContext context, {
  bool underBottomBar = false,
}) {
  final bottomInset = MediaQuery.paddingOf(context).bottom;
  return underBottomBar ? 116 + bottomInset : 18;
}

void _showFloatingTopNotice(
  BuildContext context,
  String message, {
  IconData icon = Icons.check_rounded,
  Color color = const Color(0xFF16A34A),
}) {
  final overlay = Overlay.of(context);
  late final OverlayEntry entry;
  entry = OverlayEntry(
    builder: (context) {
      final colors = context.chezMoiColors;
      return Positioned(
        top: MediaQuery.paddingOf(context).top + 12,
        left: 16,
        right: 16,
        child: IgnorePointer(
          child: Material(
            color: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: color.withValues(alpha: 0.24)),
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
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, color: color, size: 18),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      message,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
  overlay.insert(entry);
  Future<void>.delayed(const Duration(seconds: 1), entry.remove);
}

void _showAuthRequiredSheet(
  BuildContext context, {
  required String title,
  required String message,
}) {
  final redirect = _currentAuthRedirect(context);
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.22),
    builder: (context) =>
        _AuthRequiredSheet(title: title, message: message, redirect: redirect),
  );
}

String? _currentAuthRedirect(BuildContext context) {
  try {
    final uri = GoRouterState.of(context).uri.toString();
    return isValidRedirect(uri) ? uri : null;
  } catch (_) {
    return null;
  }
}

class _AuthRequiredSheet extends StatelessWidget {
  const _AuthRequiredSheet({
    required this.title,
    required this.message,
    required this.redirect,
  });

  final String title;
  final String message;
  final String? redirect;

  @override
  Widget build(BuildContext context) {
    final colors = context.chezMoiColors;
    return Align(
      alignment: Alignment.bottomCenter,
      child: SafeArea(
        top: false,
        bottom: false,
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            border: Border(top: BorderSide(color: colors.border)),
            boxShadow: [
              BoxShadow(
                color: colors.textPrimary.withValues(alpha: 0.10),
                blurRadius: 20,
                offset: const Offset(0, -8),
              ),
            ],
          ),
          padding: EdgeInsets.fromLTRB(
            20,
            10,
            20,
            18 + MediaQuery.paddingOf(context).bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 5,
                  decoration: BoxDecoration(
                    color: colors.border,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              const _SheetBrandMark(icon: Icons.lock_outline_rounded),
              const SizedBox(height: 14),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: colors.textSecondary,
                  fontSize: 15,
                  height: 1.35,
                  fontWeight: FontWeight.w400,
                ),
              ),
              const SizedBox(height: 18),
              FilledButton(
                onPressed: () {
                  Navigator.pop(context);
                  context.go(authRouteWithRedirect('/login', redirect));
                },
                child: const Text('Connexion'),
              ),
              const SizedBox(height: 4),
              Center(
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    foregroundColor: colors.textSecondary.withValues(
                      alpha: 0.62,
                    ),
                    textStyle: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                    minimumSize: const Size(0, 34),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text('Plus tard'),
                ),
              ),
              const SizedBox(height: 10),
              const AkashaFooter(),
            ],
          ),
        ),
      ),
    );
  }
}

class _SheetBrandMark extends StatelessWidget {
  const _SheetBrandMark({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final colors = context.chezMoiColors;
    return Center(
      child: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          color: colors.lightBlueAccent,
          shape: BoxShape.circle,
          border: Border.all(color: colors.border),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Opacity(
              opacity: 0.16,
              child: Image.asset(
                'assets/images/nnn.png',
                width: 44,
                height: 44,
                fit: BoxFit.contain,
              ),
            ),
            Icon(icon, color: colors.primaryBlue, size: 28),
          ],
        ),
      ),
    );
  }
}

class _SignOutSheet extends StatelessWidget {
  const _SignOutSheet();

  @override
  Widget build(BuildContext context) {
    final colors = context.chezMoiColors;
    return Align(
      alignment: Alignment.bottomCenter,
      child: SafeArea(
        top: false,
        bottom: false,
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            border: Border(top: BorderSide(color: colors.border)),
            boxShadow: [
              BoxShadow(
                color: colors.textPrimary.withValues(alpha: 0.10),
                blurRadius: 20,
                offset: const Offset(0, -8),
              ),
            ],
          ),
          padding: EdgeInsets.fromLTRB(
            18,
            10,
            18,
            18 + MediaQuery.paddingOf(context).bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 5,
                  decoration: BoxDecoration(
                    color: colors.border,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: colors.danger.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: colors.danger.withValues(alpha: 0.16),
                      ),
                    ),
                    child: Icon(
                      Icons.logout_rounded,
                      color: colors.danger,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Se déconnecter ?',
                          style: TextStyle(
                            color: colors.textPrimary,
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            height: 1.18,
                          ),
                        ),
                        const SizedBox(height: 7),
                        Text(
                          'Vous pourrez revenir quand vous voulez. Vos favoris et réservations sont conservés.',
                          style: TextStyle(
                            color: colors.textSecondary,
                            fontSize: 14,
                            height: 1.45,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 44,
                    height: 44,
                    child: ClipRect(
                      child: Align(
                        alignment: Alignment.center,
                        heightFactor: 0.42,
                        child: Image.asset(
                          'assets/images/nnn.png',
                          height: 106,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Annuler'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: colors.danger,
                      ),
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Déconnexion'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MapHomeTab extends StatelessWidget {
  const _MapHomeTab({
    required this.latestLoader,
    required this.loading,
    required this.loadingMore,
    required this.error,
    required this.allListingsEmpty,
    required this.hasSearched,
    required this.visibleListings,
    required this.savedPlaceIds,
    required this.amenities,
    required this.filter,
    required this.showAmenities,
    required this.matchingCount,
    required this.countLoading,
    required this.minBudgetController,
    required this.maxBudgetController,
    required this.scrollController,
    required this.searchController,
    required this.searchSuggestions,
    required this.searchingLocation,
    required this.bottomPadding,
    required this.onRefresh,
    required this.onRetry,
    required this.onToggleAmenities,
    required this.onAmenityChanged,
    required this.onSearch,
    required this.onSearchChanged,
    required this.onSuggestionSelected,
    required this.onSubtypeChanged,
    required this.onCategoryChanged,
    required this.onResetFilters,
    required this.onListingTap,
    required this.onSaveTap,
    required this.onExpandMap,
  });

  final Future<List<Place>> Function() latestLoader;
  final bool loading;
  final bool loadingMore;
  final String? error;
  final bool allListingsEmpty;
  final bool hasSearched;
  final List<Place> visibleListings;
  final Set<String> savedPlaceIds;
  final List<AmenityOption> amenities;
  final PlaceFilter filter;
  final bool showAmenities;
  final int? matchingCount;
  final bool countLoading;
  final TextEditingController minBudgetController;
  final TextEditingController maxBudgetController;
  final ScrollController scrollController;
  final TextEditingController searchController;
  final List<LocationSearchResult> searchSuggestions;
  final bool searchingLocation;
  final double bottomPadding;
  final Future<void> Function() onRefresh;
  final VoidCallback onRetry;
  final VoidCallback onToggleAmenities;
  final void Function(String key, bool selected) onAmenityChanged;
  final VoidCallback onSearch;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<LocationSearchResult> onSuggestionSelected;
  final ValueChanged<String?> onSubtypeChanged;
  final ValueChanged<String?> onCategoryChanged;
  final VoidCallback onResetFilters;
  final ValueChanged<Place> onListingTap;
  final ValueChanged<Place> onSaveTap;
  final VoidCallback onExpandMap;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: RefreshIndicator(
        onRefresh: onRefresh,
        child: CustomScrollView(
          controller: scrollController,
          slivers: [
            SliverToBoxAdapter(
              child: _HomeSearchPanel(
                searchController: searchController,
                minBudgetController: minBudgetController,
                maxBudgetController: maxBudgetController,
                suggestions: searchSuggestions,
                searchingLocation: searchingLocation,
                amenities: amenities,
                filter: filter,
                showAmenities: showAmenities,
                matchingCount: matchingCount,
                countLoading: countLoading,
                onChanged: onSearchChanged,
                onSuggestionSelected: onSuggestionSelected,
                onSubtypeChanged: onSubtypeChanged,
                onCategoryChanged: onCategoryChanged,
                onToggleAmenities: onToggleAmenities,
                onAmenityChanged: onAmenityChanged,
                onResetFilters: onResetFilters,
                onSearch: onSearch,
              ),
            ),
            SliverToBoxAdapter(
              child: _HomeLatestSection(
                loader: latestLoader,
                savedPlaceIds: savedPlaceIds,
                onListingTap: onListingTap,
                onSaveTap: onSaveTap,
                onExpandMap: onExpandMap,
              ),
            ),
            SliverFillRemaining(
              hasScrollBody: false,
              fillOverscroll: true,
              child: Padding(
                padding: EdgeInsets.fromLTRB(18, 28, 18, bottomPadding),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    AkashaFooter(padding: EdgeInsets.symmetric(vertical: 4)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MapTab extends StatelessWidget {
  const _MapTab({
    required this.visibleListings,
    required this.selectedListingId,
    required this.profile,
    required this.loading,
    required this.error,
    required this.bottomPadding,
    required this.onRetry,
    required this.onListingTap,
    required this.mapSearchController,
    required this.mapSearchSuggestions,
    required this.searchingMapLocation,
    required this.onMapSearchChanged,
    required this.onMapSearchSubmitted,
    required this.onMapSuggestionSelected,
    required this.onClearMapSearch,
  });

  final List<Place> visibleListings;
  final String? selectedListingId;
  final ChezMoiProfile? profile;
  final bool loading;
  final String? error;
  final double bottomPadding;
  final VoidCallback onRetry;
  final ValueChanged<Place> onListingTap;
  final TextEditingController mapSearchController;
  final List<LocationSearchResult> mapSearchSuggestions;
  final bool searchingMapLocation;
  final ValueChanged<String> onMapSearchChanged;
  final ValueChanged<String> onMapSearchSubmitted;
  final ValueChanged<LocationSearchResult> onMapSuggestionSelected;
  final VoidCallback onClearMapSearch;

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.paddingOf(context).top + 18;
    final mappedCount = visibleListings
        .where((listing) => listing.hasCoordinates)
        .length;
    return Stack(
      children: [
        Positioned.fill(
          child: ChezMoiMapView(
            listings: visibleListings,
            userLocation: profile?.userLocation,
            selectedListingId: selectedListingId,
            onListingSelected: onListingTap,
          ),
        ),
        if (error != null)
          Positioned(
            left: 16,
            right: 16,
            top: topPadding,
            child: _MapOverlayMessage(message: error!, onRetry: onRetry),
          )
        else if (!loading && visibleListings.isEmpty)
          Positioned(
            left: 16,
            right: 16,
            top: topPadding,
            child: const _MapOverlayMessage(message: 'Aucun établissement trouvé'),
          ),
        if (!loading &&
            error == null &&
            visibleListings.isNotEmpty &&
            mappedCount == 0)
          Positioned(
            left: 16,
            right: 16,
            top: topPadding,
            child: const _MapOverlayMessage(
              message: 'Aucun établissement n\'a de position précise.',
            ),
          ),
        Positioned(
          left: 16,
          right: 16,
          top: topPadding,
          child: _MapSearchOverlay(
            controller: mapSearchController,
            suggestions: mapSearchSuggestions,
            searchingLocation: searchingMapLocation,
            onChanged: onMapSearchChanged,
            onSubmitted: onMapSearchSubmitted,
            onSuggestionSelected: onMapSuggestionSelected,
            onClear: onClearMapSearch,
          ),
        ),
      ],
    );
  }
}

class _HomeLatestSection extends StatefulWidget {
  const _HomeLatestSection({
    required this.loader,
    required this.savedPlaceIds,
    required this.onListingTap,
    required this.onSaveTap,
    required this.onExpandMap,
  });

  final Future<List<Place>> Function() loader;
  final Set<String> savedPlaceIds;
  final ValueChanged<Place> onListingTap;
  final ValueChanged<Place> onSaveTap;
  final VoidCallback onExpandMap;

  @override
  State<_HomeLatestSection> createState() => _HomeLatestSectionState();
}

class _HomeLatestSectionState extends State<_HomeLatestSection> {
  late Future<List<Place>> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.loader();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.chezMoiColors;
    return FutureBuilder<List<Place>>(
      future: _future,
      builder: (context, snapshot) {
        final listings = snapshot.data ?? const <Place>[];
        if (snapshot.connectionState != ConnectionState.done) {
          return const Padding(
            padding: EdgeInsets.fromLTRB(18, 34, 18, 16),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        if (listings.isEmpty) return const SizedBox.shrink();

        final mapListings = listings
            .where((listing) => listing.hasCoordinates)
            .take(4)
            .toList(growable: false);

        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 30, 16, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'À la une',
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: 22,
                        height: 1.1,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  Text(
                    'Derniers ajouts',
                    style: TextStyle(
                      color: colors.textSecondary,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              GridView.builder(
                itemCount: listings.take(4).length,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 0.60,
                ),
                itemBuilder: (context, index) {
                  final listing = listings[index];
                  return FeedPlaceCardPost(
                    listing: listing,
                    saved: widget.savedPlaceIds.contains(listing.id),
                    compact: true,
                    onSaveTap: () => widget.onSaveTap(listing),
                    onListingTap: () => widget.onListingTap(listing),
                  );
                },
              ),
              if (mapListings.isNotEmpty) ...[
                const SizedBox(height: 18),
                _HomeMapPreview(
                  listings: mapListings,
                  selectedListingId: mapListings.first.id,
                  onListingTap: widget.onListingTap,
                  onExpandMap: widget.onExpandMap,
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _HomeMapPreview extends StatelessWidget {
  const _HomeMapPreview({
    required this.listings,
    required this.selectedListingId,
    required this.onListingTap,
    required this.onExpandMap,
  });

  final List<Place> listings;
  final String? selectedListingId;
  final ValueChanged<Place> onListingTap;
  final VoidCallback onExpandMap;

  @override
  Widget build(BuildContext context) {
    final colors = context.chezMoiColors;
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        height: 220,
        child: Stack(
          fit: StackFit.expand,
          children: [
            ChezMoiMapView(
              listings: listings,
              selectedListingId: selectedListingId,
              compact: true,
              onListingSelected: onListingTap,
            ),
            Positioned(
              left: 12,
              right: 12,
              top: 12,
              child: Row(
                children: [
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: colors.surface.withValues(alpha: 0.95),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: colors.border),
                    ),
                  ),
                  const Spacer(),
                  FilledButton.icon(
                    onPressed: onExpandMap,
                    icon: const Icon(Icons.open_in_full_rounded, size: 16),
                    label: const Text('Agrandir'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      minimumSize: const Size(0, 38),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MapSearchOverlay extends StatelessWidget {
  const _MapSearchOverlay({
    required this.controller,
    required this.suggestions,
    required this.searchingLocation,
    required this.onChanged,
    required this.onSubmitted,
    required this.onSuggestionSelected,
    required this.onClear,
  });

  final TextEditingController controller;
  final List<LocationSearchResult> suggestions;
  final bool searchingLocation;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onSubmitted;
  final ValueChanged<LocationSearchResult> onSuggestionSelected;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final colors = context.chezMoiColors;
    return Column(
      children: [
        Material(
          color: colors.surface.withValues(alpha: 0.96),
          borderRadius: BorderRadius.circular(18),
          elevation: 8,
          shadowColor: colors.navy.withValues(alpha: 0.14),
          child: TextField(
            controller: controller,
            onChanged: onChanged,
            onSubmitted: onSubmitted,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: 'Rechercher une zone',
              prefixIcon: Icon(
                Icons.travel_explore_rounded,
                color: colors.primaryBlue,
              ),
              suffixIcon: searchingLocation
                  ? const Padding(
                      padding: EdgeInsets.all(14),
                      child: SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : controller.text.isEmpty
                  ? null
                  : IconButton(
                      onPressed: onClear,
                      icon: const Icon(Icons.close_rounded),
                      tooltip: 'Effacer',
                    ),
              filled: true,
              fillColor: Colors.transparent,
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
            ),
          ),
        ),
        if (suggestions.isNotEmpty) ...[
          const SizedBox(height: 8),
          _LocationSuggestionPanel(
            suggestions: suggestions,
            onSelected: onSuggestionSelected,
          ),
        ],
      ],
    );
  }
}

class _SearchResultsTab extends StatelessWidget {
  const _SearchResultsTab({
    required this.loading,
    required this.loadingMore,
    required this.error,
    required this.listings,
    required this.savedPlaceIds,
    required this.scrollController,
    required this.bottomPadding,
    required this.onBackToSearch,
    required this.onRetry,
    required this.onListingTap,
    required this.onSaveTap,
  });

  final bool loading;
  final bool loadingMore;
  final String? error;
  final List<Place> listings;
  final Set<String> savedPlaceIds;
  final ScrollController scrollController;
  final double bottomPadding;
  final VoidCallback onBackToSearch;
  final VoidCallback onRetry;
  final ValueChanged<Place> onListingTap;
  final ValueChanged<Place> onSaveTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.chezMoiColors;
    return SafeArea(
      top: false,
      bottom: false,
      child: CustomScrollView(
        controller: scrollController,
        slivers: [
          SliverToBoxAdapter(
            child: Container(
              padding: EdgeInsets.fromLTRB(
                12,
                MediaQuery.paddingOf(context).top + 10,
                16,
                16,
              ),
              decoration: BoxDecoration(
                color: colors.surface,
                border: Border(
                  bottom: BorderSide(
                    color: colors.border.withValues(alpha: 0.7),
                  ),
                ),
              ),
              child: Row(
                children: [
                  IconButton.filledTonal(
                    onPressed: onBackToSearch,
                    icon: const Icon(Icons.arrow_back_rounded),
                    tooltip: 'Modifier la recherche',
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Résultats',
                          style: TextStyle(
                            color: colors.textPrimary,
                            fontSize: 25,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (!loading && error == null)
                          Text(
                            '${listings.length} établissement${listings.length > 1 ? 's' : ''} trouvé${listings.length > 1 ? 's' : ''}',
                            style: TextStyle(
                              color: colors.textSecondary,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 16)),
          if (loading)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(child: CircularProgressIndicator()),
            )
          else if (error != null)
            SliverFillRemaining(
              hasScrollBody: false,
              child: DashboardCenteredState(
                child: DashboardErrorState(message: error!, onRetry: onRetry),
              ),
            )
          else if (listings.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: DashboardCenteredState(
                child: _NoFilterResults(onReset: onBackToSearch),
              ),
            )
          else ...[
            SliverPadding(
              padding: EdgeInsets.fromLTRB(
                16,
                0,
                16,
                loadingMore ? 18 : bottomPadding,
              ),
              sliver: ListingGrid(
                listings: listings,
                selectedListingId: null,
                savedPlaceIds: savedPlaceIds,
                onListingTap: onListingTap,
                onSaveTap: onSaveTap,
              ),
            ),
            if (loadingMore)
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(0, 0, 0, bottomPadding),
                  child: const Center(child: CircularProgressIndicator()),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _MapOverlayMessage extends StatelessWidget {
  const _MapOverlayMessage({required this.message, this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final colors = context.chezMoiColors;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Icon(Icons.map_outlined, color: colors.primaryBlue),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  color: colors.textPrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            if (onRetry != null)
              TextButton(onPressed: onRetry, child: const Text('Réessayer')),
          ],
        ),
      ),
    );
  }
}

class _MapListingPreviewSheet extends StatelessWidget {
  const _MapListingPreviewSheet({
    required this.listing,
    required this.onViewDetails,
    required this.onContact,
  });

  final Place listing;
  final VoidCallback onViewDetails;
  final VoidCallback onContact;

  @override
  Widget build(BuildContext context) {
    final colors = context.chezMoiColors;
    final maxHeight = MediaQuery.sizeOf(context).height * 0.74;
    return Align(
      alignment: Alignment.bottomCenter,
      child: SafeArea(
        top: false,
        bottom: false,
        child: Container(
          width: double.infinity,
          constraints: BoxConstraints(maxHeight: maxHeight),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            border: Border(top: BorderSide(color: colors.border)),
            boxShadow: [
              BoxShadow(
                color: colors.textPrimary.withValues(alpha: 0.10),
                blurRadius: 20,
                offset: const Offset(0, -8),
              ),
            ],
          ),
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              12,
              10,
              12,
              16 + MediaQuery.paddingOf(context).bottom,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const Spacer(),
                    Container(
                      width: 42,
                      height: 5,
                      decoration: BoxDecoration(
                        color: colors.border,
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded),
                      tooltip: 'Fermer',
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: AspectRatio(
                    aspectRatio: 1.95,
                    child: listing.coverImageUrl == null
                        ? ColoredBox(
                            color: colors.lightBlueAccent,
                            child: Icon(
                              Icons.home_work_outlined,
                              color: colors.primaryBlue,
                              size: 42,
                            ),
                          )
                        : Image.network(
                            listing.coverImageUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                ColoredBox(
                                  color: colors.lightBlueAccent,
                                  child: Icon(
                                    Icons.home_work_outlined,
                                    color: colors.primaryBlue,
                                    size: 42,
                                  ),
                                ),
                          ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  listing.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 20,
                    height: 1.15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  listing.priceLabel,
                  style: const TextStyle(
                    color: Color(0xFF1677E8),
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                if ((listing.publicCode ?? '').trim().isNotEmpty) ...[
                  const SizedBox(height: 6),
                  ListingReference(code: listing.publicCode),
                ],
                const SizedBox(height: 7),
                Row(
                  children: [
                    Icon(
                      Icons.location_on_rounded,
                      size: 16,
                      color: colors.textSecondary,
                    ),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        listing.locationLabel,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: colors.textSecondary,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _DetailChip(
                      icon: Icons.hotel_rounded,
                      label: listing.subtypeLabel,
                    ),
                  ],
                ),
                if (listing.guestRatingLabel != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                    decoration: BoxDecoration(
                      color: colors.surface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: colors.border),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1677E8),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            listing.guestRatingLabel!,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        const SizedBox(width: 9),
                        Expanded(
                          child: Text(
                            [
                              ?listing.guestRatingMention,
                              ?listing.reviewCountLabel,
                            ].join(' · '),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: colors.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: onViewDetails,
                        child: const Text('Voir la fiche'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: onContact,
                        icon: const Icon(Icons.event_available_rounded),
                        label: const Text('Réserver'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ChezMoiHomeBrand extends StatelessWidget {
  const _ChezMoiHomeBrand();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        height: 118,
        child: ClipRect(
          child: Align(
            alignment: Alignment.center,
            heightFactor: 0.42,
            child: Image.asset(
              'assets/images/nnn.png',
              height: 282,
              fit: BoxFit.contain,
            ),
          ),
        ),
      ),
    );
  }
}

class _TopSearchBar extends StatelessWidget {
  const _TopSearchBar({
    required this.controller,
    required this.suggestions,
    required this.searchingLocation,
    required this.onChanged,
    required this.onSuggestionSelected,
  });

  final TextEditingController controller;
  final List<LocationSearchResult> suggestions;
  final bool searchingLocation;
  final ValueChanged<String> onChanged;
  final ValueChanged<LocationSearchResult> onSuggestionSelected;

  @override
  Widget build(BuildContext context) {
    final colors = context.chezMoiColors;

    return Column(
      children: [
        TextField(
          controller: controller,
          onChanged: onChanged,
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            hintText: 'Ville, quartier ou zone',
            prefixIcon: Icon(
              Icons.travel_explore_rounded,
              color: colors.primaryBlue,
            ),
            suffixIcon: searchingLocation
                ? const Padding(
                    padding: EdgeInsets.all(14),
                    child: SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : null,
            filled: true,
            fillColor: colors.surface,
            contentPadding: const EdgeInsets.symmetric(vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: colors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: colors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: colors.primaryBlue, width: 1.4),
            ),
          ),
        ),
        if (suggestions.isNotEmpty) ...[
          const SizedBox(height: 8),
          _LocationSuggestionPanel(
            suggestions: suggestions,
            onSelected: onSuggestionSelected,
          ),
        ],
      ],
    );
  }
}

class _HomeSearchPanel extends StatelessWidget {
  const _HomeSearchPanel({
    required this.searchController,
    required this.minBudgetController,
    required this.maxBudgetController,
    required this.suggestions,
    required this.searchingLocation,
    required this.amenities,
    required this.filter,
    required this.showAmenities,
    required this.matchingCount,
    required this.countLoading,
    required this.onChanged,
    required this.onSuggestionSelected,
    required this.onSubtypeChanged,
    required this.onCategoryChanged,
    required this.onToggleAmenities,
    required this.onAmenityChanged,
    required this.onResetFilters,
    required this.onSearch,
  });

  final TextEditingController searchController;
  final TextEditingController minBudgetController;
  final TextEditingController maxBudgetController;
  final List<LocationSearchResult> suggestions;
  final bool searchingLocation;
  final List<AmenityOption> amenities;
  final PlaceFilter filter;
  final bool showAmenities;
  final int? matchingCount;
  final bool countLoading;
  final ValueChanged<String> onChanged;
  final ValueChanged<LocationSearchResult> onSuggestionSelected;
  final ValueChanged<String?> onSubtypeChanged;
  final ValueChanged<String?> onCategoryChanged;
  final VoidCallback onToggleAmenities;
  final void Function(String key, bool selected) onAmenityChanged;
  final VoidCallback onResetFilters;
  final VoidCallback onSearch;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(18, 6, 18, 2),
          child: _ChezMoiHomeBrand(),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _TopSearchBar(
                controller: searchController,
                suggestions: suggestions,
                searchingLocation: searchingLocation,
                onChanged: onChanged,
                onSuggestionSelected: onSuggestionSelected,
              ),
              const SizedBox(height: 14),
              _CategoryChoiceBar(
                selected: filter.category,
                onChanged: onCategoryChanged,
              ),
              const SizedBox(height: 14),
              _BasicSearchFilters(
                filter: filter,
                minBudgetController: minBudgetController,
                maxBudgetController: maxBudgetController,
                onSubtypeChanged: onSubtypeChanged,
              ),
              const SizedBox(height: 12),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                child: showAmenities
                    ? _AmenitySearchChoices(
                        amenities: amenities,
                        selectedKeys: filter.amenityKeys,
                        onChanged: onAmenityChanged,
                      )
                    : const SizedBox.shrink(),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Tooltip(
                    message: showAmenities
                        ? 'Masquer les filtres'
                        : 'Plus de filtres',
                    child: IconButton.filledTonal(
                      onPressed: onToggleAmenities,
                      icon: Icon(
                        showAmenities
                            ? Icons.remove_rounded
                            : Icons.add_rounded,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  TextButton.icon(
                    onPressed: onResetFilters,
                    icon: const Icon(Icons.restart_alt_rounded),
                    label: const Text('Effacer'),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              FilledButton.icon(
                onPressed: onSearch,
                icon: const Icon(Icons.search_rounded),
                label: Text(_searchButtonLabel()),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _searchButtonLabel() {
    if (countLoading) return 'Recherche...';
    final count = matchingCount;
    if (count == null || count <= 0) return 'Voir les établissements';
    return 'Voir ${_formatCount(count)} établissement${count > 1 ? 's' : ''}';
  }

  String _formatCount(int value) {
    return value.toString().replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (_) => ' ',
    );
  }
}

class _CategoryChoiceBar extends StatelessWidget {
  const _CategoryChoiceBar({required this.selected, required this.onChanged});

  final String? selected;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.chezMoiColors;
    const options = <(String?, String, IconData)>[
      (null, 'Tous', Icons.apps_rounded),
      ('hotel', 'Hôtels', Icons.hotel_rounded),
      ('restaurant', 'Restaurants', Icons.restaurant_rounded),
      ('activity', 'Activités', Icons.hiking_rounded),
    ];

    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.zero,
        itemCount: options.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final (value, label, icon) = options[index];
          final isSelected = selected == value;
          return GestureDetector(
            onTap: () => onChanged(value),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: isSelected ? colors.primaryBlue : colors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? colors.primaryBlue : colors.border,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    icon,
                    size: 18,
                    color: isSelected ? Colors.white : colors.textSecondary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? Colors.white : colors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _BasicSearchFilters extends StatelessWidget {
  const _BasicSearchFilters({
    required this.filter,
    required this.minBudgetController,
    required this.maxBudgetController,
    required this.onSubtypeChanged,
  });

  final PlaceFilter filter;
  final TextEditingController minBudgetController;
  final TextEditingController maxBudgetController;
  final ValueChanged<String?> onSubtypeChanged;

  @override
  Widget build(BuildContext context) {
    final showHotelType =
        filter.category == null || filter.category == 'hotel';
    final fields = [
      if (showHotelType)
        _FilterPickerField<String?>(
          label: "Type d'hôtel",
          value: filter.subtype,
          icon: Icons.hotel_outlined,
          options: const [
            _FilterOption(value: null, label: 'Tous'),
            _FilterOption(value: 'hotel', label: 'Hotel'),
            _FilterOption(value: 'hostel', label: 'Auberge'),
            _FilterOption(value: 'motel', label: 'Motel'),
            _FilterOption(value: 'guesthouse', label: "Maison d'hotes"),
            _FilterOption(value: 'apartment_hotel', label: 'Appart-hotel'),
            _FilterOption(value: 'resort', label: 'Resort'),
          ],
          onChanged: onSubtypeChanged,
        ),
      _PriceField(
        label: 'Budget min',
        controller: minBudgetController,
        icon: Icons.payments_outlined,
      ),
      _PriceField(
        label: 'Budget max',
        controller: maxBudgetController,
        icon: Icons.account_balance_wallet_outlined,
        minController: minBudgetController,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final twoColumns = constraints.maxWidth >= 520;
        if (!twoColumns) {
          return Column(
            children: [
              for (var i = 0; i < fields.length; i++) ...[
                fields[i],
                if (i != fields.length - 1) const SizedBox(height: 10),
              ],
            ],
          );
        }
        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final field in fields)
              SizedBox(width: (constraints.maxWidth - 10) / 2, child: field),
          ],
        );
      },
    );
  }
}

class _PriceField extends StatelessWidget {
  const _PriceField({
    required this.label,
    required this.controller,
    required this.icon,
    this.minController,
  });

  final String label;
  final TextEditingController controller;
  final IconData icon;
  final TextEditingController? minController;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: label,
        hintText: 'Tous',
        prefixIcon: Icon(icon),
        suffixIcon: IconButton(
          onPressed: () => _openPriceOptions(context),
          icon: const Icon(Icons.keyboard_arrow_down_rounded),
          tooltip: 'Choisir un montant',
        ),
      ),
    );
  }

  void _openPriceOptions(BuildContext context) {
    final colors = context.chezMoiColors;
    final minValue = minController == null
        ? null
        : num.tryParse(minController!.text.trim());
    final options = _priceOptions()
        .where((value) => minValue == null || value >= minValue)
        .toList(growable: false);
    showModalBottomSheet<void>(
      context: context,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 42,
                height: 5,
                decoration: BoxDecoration(
                  color: colors.border,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              const SizedBox(height: 14),
              _PriceOptionTile(
                label: 'Tous',
                selected: controller.text.trim().isEmpty,
                onTap: () {
                  controller.clear();
                  Navigator.pop(context);
                },
              ),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: options.length,
                  itemBuilder: (context, index) {
                    final value = options[index];
                    final label = _formatCfa(value);
                    return _PriceOptionTile(
                      label: label,
                      selected: controller.text.trim() == value.toString(),
                      onTap: () {
                        controller.text = value.toString();
                        controller.selection = TextSelection.collapsed(
                          offset: controller.text.length,
                        );
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PriceOptionTile extends StatelessWidget {
  const _PriceOptionTile({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.chezMoiColors;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: selected ? colors.lightBlueAccent : colors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: selected
              ? colors.primaryBlue.withValues(alpha: 0.42)
              : colors.border,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: ListTile(
          title: Text(
            label,
            style: TextStyle(
              color: colors.textPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
          trailing: selected
              ? Icon(Icons.check_rounded, color: colors.primaryBlue)
              : null,
          onTap: onTap,
        ),
      ),
    );
  }
}

List<num> _priceOptions() {
  return const [
    25000,
    50000,
    75000,
    100000,
    150000,
    200000,
    250000,
    300000,
    350000,
    400000,
    450000,
    500000,
    750000,
    1000000,
    1500000,
    2000000,
    3000000,
    5000000,
    7500000,
    10000000,
    15000000,
    25000000,
  ];
}

String _formatCfa(num value) {
  final text = value.round().toString().replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (_) => ' ',
  );
  return '$text CFA';
}

class _FilterOption<T> {
  const _FilterOption({required this.value, required this.label});

  final T value;
  final String label;
}

class _FilterPickerField<T> extends StatelessWidget {
  const _FilterPickerField({
    required this.label,
    required this.value,
    required this.icon,
    required this.options,
    required this.onChanged,
  });

  final String label;
  final T value;
  final IconData icon;
  final List<_FilterOption<T>> options;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.chezMoiColors;
    final selected = options.firstWhere(
      (option) => option.value == value,
      orElse: () => options.first,
    );
    return Material(
      color: colors.surface,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => _openOptions(context),
        child: Container(
          constraints: const BoxConstraints(minHeight: 56),
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: colors.border),
          ),
          child: Row(
            children: [
              Icon(icon, color: colors.primaryBlue, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: colors.textSecondary,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      selected.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.keyboard_arrow_down_rounded,
                color: colors.primaryBlue,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openOptions(BuildContext context) {
    final colors = context.chezMoiColors;
    showModalBottomSheet<void>(
      context: context,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 42,
                height: 5,
                decoration: BoxDecoration(
                  color: colors.border,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              const SizedBox(height: 14),
              for (final option in options)
                Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: option.value == value
                        ? colors.lightBlueAccent
                        : colors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: option.value == value
                          ? colors.primaryBlue.withValues(alpha: 0.42)
                          : colors.border,
                    ),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Material(
                    color: Colors.transparent,
                    child: ListTile(
                      title: Text(
                        option.label,
                        style: TextStyle(
                          color: colors.textPrimary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      trailing: option.value == value
                          ? Icon(Icons.check_rounded, color: colors.primaryBlue)
                          : null,
                      onTap: () {
                        Navigator.pop(context);
                        onChanged(option.value);
                      },
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AmenitySearchChoices extends StatelessWidget {
  const _AmenitySearchChoices({
    required this.amenities,
    required this.selectedKeys,
    required this.onChanged,
  });

  final List<AmenityOption> amenities;
  final Set<String> selectedKeys;
  final void Function(String key, bool selected) onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.chezMoiColors;
    if (amenities.isEmpty) {
      return Container(
        key: const ValueKey('empty-amenities'),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colors.border),
        ),
        child: Text(
          'Aucune commodité disponible pour le moment.',
          style: TextStyle(
            color: colors.textSecondary,
            fontWeight: FontWeight.w700,
          ),
        ),
      );
    }

    final visibleAmenities = amenities.take(10).toList(growable: false);
    return Container(
      key: const ValueKey('amenities'),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.border),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final cellWidth = (constraints.maxWidth - 32) / 5;
          return Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final amenity in visibleAmenities)
                SizedBox(
                  width: cellWidth,
                  child: _AmenityMiniChoice(
                    amenity: amenity,
                    selected: selectedKeys.contains(amenity.key),
                    onChanged: onChanged,
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _AmenityMiniChoice extends StatelessWidget {
  const _AmenityMiniChoice({
    required this.amenity,
    required this.selected,
    required this.onChanged,
  });

  final AmenityOption amenity;
  final bool selected;
  final void Function(String key, bool selected) onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.chezMoiColors;
    return Material(
      color: selected ? colors.navy : colors.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => onChanged(amenity.key, !selected),
        child: Container(
          height: 58,
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 7),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: selected ? colors.navy : colors.border),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                selected ? Icons.check_circle_rounded : Icons.add_rounded,
                color: selected ? Colors.white : colors.primaryBlue,
                size: 17,
              ),
              const SizedBox(height: 3),
              Text(
                amenity.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: selected ? Colors.white : colors.textPrimary,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LocationSuggestionPanel extends StatelessWidget {
  const _LocationSuggestionPanel({
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
        color: colors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: colors.surface,
        child: Column(
          children: [
            for (final suggestion in suggestions.take(4))
              ListTile(
                dense: true,
                leading: Icon(Icons.place_outlined, color: colors.primaryBlue),
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

class _NoFilterResults extends StatelessWidget {
  const _NoFilterResults({required this.onReset});

  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    final colors = context.chezMoiColors;
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.manage_search_rounded,
            size: 48,
            color: colors.primaryBlue,
          ),
          const SizedBox(height: 12),
          Text(
            'Aucun établissement ne correspond à votre recherche.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: onReset,
            child: const Text('Réinitialiser'),
          ),
        ],
      ),
    );
  }
}

bool _valueEndsWithComma(String value) => value.trimRight().endsWith(',');

class _DetailChip extends StatelessWidget {
  const _DetailChip({required this.label, this.icon});

  final String label;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final colors = context.chezMoiColors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: colors.lightBlueAccent,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, color: colors.navy, size: 14),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              color: colors.navy,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
