import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/app_router.dart';
import '../../../core/backend_mode.dart';
import '../../../core/theme.dart';
import '../../../shared/widgets/akasha_footer.dart';
import '../../places/models/place.dart';
import '../../places/services/place_service.dart';
import '../../places/widgets/chezmoi_map_view.dart';
import '../../places/widgets/listing_reference.dart';
import '../../reservations/models/reservation.dart';
import '../../reservations/services/reservation_service.dart';

typedef PlaceContactNotice =
    void Function(
      BuildContext context,
      String message, {
      IconData icon,
      Color color,
    });

class PlaceDetailSheet extends StatefulWidget {
  const PlaceDetailSheet({
    super.key,
    required this.listing,
    this.onShowOnMap,
    this.onAuthRequired,
    this.onContactNotice,
  });

  final Place listing;
  final VoidCallback? onShowOnMap;
  final VoidCallback? onAuthRequired;
  final PlaceContactNotice? onContactNotice;

  @override
  State<PlaceDetailSheet> createState() => _PlaceDetailSheetState();
}

class _PlaceDetailSheetState extends State<PlaceDetailSheet> {
  late final Future<List<NearbyPlace>> _nearbyPlacesFuture;

  @override
  void initState() {
    super.initState();
    _nearbyPlacesFuture = PlaceService().loadNearbyPlaces(widget.listing);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.chezMoiColors;
    return DraggableScrollableSheet(
      initialChildSize: 0.92,
      minChildSize: 0.38,
      maxChildSize: 0.97,
      expand: false,
      builder: (context, scrollController) {
        return DecoratedBox(
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
          child: SafeArea(
            top: false,
            bottom: false,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 10, 12, 0),
                  child: Row(
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
                ),
                Expanded(
                  child: ListView(
                    controller: scrollController,
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 18),
                    children: [
                      _ListingPhotoGallery(urls: widget.listing.imageUrls),
                      const SizedBox(height: 20),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            widget.listing.priceLabel,
                            style: const TextStyle(
                              color: Color(0xFF1677E8),
                              fontSize: 25,
                              height: 1.05,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '/ nuit',
                            style: TextStyle(
                              color: colors.textSecondary,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        widget.listing.title,
                        style: TextStyle(
                          color: colors.textPrimary,
                          fontSize: 22,
                          height: 1.18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if ((widget.listing.publicCode ?? '')
                          .trim()
                          .isNotEmpty) ...[
                        const SizedBox(height: 8),
                        ListingReference(code: widget.listing.publicCode),
                      ],
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Icon(
                            widget.listing.hasCoordinates
                                ? Icons.location_on_rounded
                                : Icons.location_off_outlined,
                            color: colors.textSecondary,
                            size: 16,
                          ),
                          const SizedBox(width: 5),
                          Expanded(
                            child: Text(
                              widget.listing.locationLabel,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: colors.textSecondary,
                                fontSize: 13,
                                height: 1.3,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      _DetailFactsRow(listing: widget.listing),
                      const SizedBox(height: 18),
                      _DetailSectionTitle(label: 'Description'),
                      const SizedBox(height: 8),
                      Text(
                        (widget.listing.description ?? '').trim().isEmpty
                            ? 'Cet établissement ne contient pas encore de description détaillée.'
                            : widget.listing.description!.trim(),
                        style: TextStyle(
                          color: colors.textPrimary,
                          height: 1.55,
                          fontSize: 14.5,
                        ),
                      ),
                      if (widget.listing.amenities.isNotEmpty) ...[
                        const SizedBox(height: 22),
                        _DetailSectionTitle(label: 'Commodités'),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (final amenity in widget.listing.amenities)
                              _DetailChip(label: amenity),
                          ],
                        ),
                      ],
                      if (widget.listing.hasCoordinates) ...[
                        const SizedBox(height: 22),
                        FutureBuilder<List<NearbyPlace>>(
                          future: _nearbyPlacesFuture,
                          builder: (context, snapshot) {
                            return _NearbyPlacesPanel(
                              places: snapshot.data ?? const [],
                              loading:
                                  snapshot.connectionState ==
                                  ConnectionState.waiting,
                              error: snapshot.hasError,
                            );
                          },
                        ),
                        const SizedBox(height: 22),
                        _DetailSectionTitle(label: 'Carte'),
                        const SizedBox(height: 10),
                        FutureBuilder<List<NearbyPlace>>(
                          future: _nearbyPlacesFuture,
                          builder: (context, snapshot) => _DetailMapPreview(
                            listing: widget.listing,
                            nearbyPlaces: snapshot.data ?? const [],
                            onShowOnMap: widget.onShowOnMap,
                          ),
                        ),
                      ],
                      const SizedBox(height: 22),
                      const Divider(height: 1),
                      const SizedBox(height: 14),
                      _ReportListingButton(
                        listing: widget.listing,
                        onAuthRequired: widget.onAuthRequired,
                      ),
                    ],
                  ),
                ),
                _DetailActionBar(
                  onShowOnMap: widget.onShowOnMap,
                  onContact: () => openReservationForListing(
                    context,
                    widget.listing,
                    onAuthRequired: widget.onAuthRequired,
                    onNotice: widget.onContactNotice,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ReportListingButton extends StatelessWidget {
  const _ReportListingButton({required this.listing, this.onAuthRequired});

  final Place listing;
  final VoidCallback? onAuthRequired;

  @override
  Widget build(BuildContext context) {
    final colors = context.chezMoiColors;
    return OutlinedButton.icon(
      onPressed: () => _openReportListingSheet(
        context,
        listing,
        onAuthRequired: onAuthRequired,
      ),
      icon: Icon(Icons.flag_outlined, color: colors.danger),
      label: Text(
        'Signaler cet établissement',
        style: TextStyle(color: colors.danger, fontWeight: FontWeight.w700),
      ),
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: colors.danger.withValues(alpha: 0.28)),
        foregroundColor: colors.danger,
        minimumSize: const Size.fromHeight(44),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}

void _openReportListingSheet(
  BuildContext context,
  Place listing, {
  VoidCallback? onAuthRequired,
}) {
  if (BackendMode.useSupabase &&
      Supabase.instance.client.auth.currentUser == null) {
    if (onAuthRequired != null) {
      onAuthRequired();
    } else {
      _showDefaultAuthRequiredSheet(context);
    }
    return;
  }
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.22),
    builder: (context) => _ReportListingSheet(listing: listing),
  );
}

void openReservationForListing(
  BuildContext context,
  Place listing, {
  VoidCallback? onAuthRequired,
  PlaceContactNotice? onNotice,
}) {
  if (BackendMode.useSupabase &&
      Supabase.instance.client.auth.currentUser == null) {
    if (onAuthRequired != null) {
      onAuthRequired();
    } else {
      _showDefaultAuthRequiredSheet(context);
    }
    return;
  }
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.22),
    builder: (sheetContext) =>
        _ReservationSheet(hostContext: context, listing: listing, onNotice: onNotice),
  );
}

class _ReservationSheet extends StatefulWidget {
  const _ReservationSheet({
    required this.hostContext,
    required this.listing,
    this.onNotice,
  });

  final BuildContext hostContext;
  final Place listing;
  final PlaceContactNotice? onNotice;

  @override
  State<_ReservationSheet> createState() => _ReservationSheetState();
}

class _ReservationSheetState extends State<_ReservationSheet> {
  final _reservationService = ReservationService();
  DateTime? _startDate;
  DateTime? _endDate;
  String? _timeSlot;
  int _guests = 1;
  bool _submitting = false;

  Place get _listing => widget.listing;

  static const _slots = ['12:00', '13:00', '19:00', '20:00', '21:00'];

  ReservationDraft get _draft => ReservationDraft(
    listing: _listing,
    startDate: _startDate,
    endDate: _listing.isHotel ? _endDate : null,
    timeSlot: _listing.isHotel ? null : _timeSlot,
    guests: _guests,
  );

  Future<void> _pickDate({required bool isStart}) async {
    final now = DateTime.now();
    final initial = isStart
        ? (_startDate ?? now)
        : (_endDate ?? _startDate?.add(const Duration(days: 1)) ?? now);
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (picked == null) return;
    setState(() {
      if (isStart) {
        _startDate = picked;
        if (_endDate != null && !_endDate!.isAfter(picked)) {
          _endDate = picked.add(const Duration(days: 1));
        }
      } else {
        _endDate = picked;
      }
    });
  }

  bool get _isValid {
    if (_startDate == null) return false;
    if (_listing.isHotel && _endDate == null) return false;
    return true;
  }

  Future<void> _submit() async {
    if (!_isValid || _submitting) return;
    setState(() => _submitting = true);
    try {
      await _reservationService.createReservation(_draft);
      if (!mounted) return;
      Navigator.pop(context);
      final host = widget.hostContext;
      if (!host.mounted) return;
      widget.onNotice?.call(
        host,
        'Réservation enregistrée. Retrouvez-la dans « Mes réservations ».',
        icon: Icons.check_circle_rounded,
        color: const Color(0xFF16A34A),
      );
    } on ReservationException catch (error) {
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    } catch (_) {
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Réservation impossible. Réessayez.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.chezMoiColors;
    final total = _draft.estimatedTotal;
    final isHotel = _listing.isHotel;

    return Align(
      alignment: Alignment.bottomCenter,
      child: SafeArea(
        top: false,
        bottom: false,
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.fromLTRB(
            20,
            10,
            20,
            18 + MediaQuery.paddingOf(context).bottom,
          ),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            border: Border(top: BorderSide(color: colors.border)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const _SheetHeader(title: 'Réserver'),
              const SizedBox(height: 6),
              Text(
                _listing.title,
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _listing.nightlyPriceLabel,
                style: const TextStyle(
                  color: Color(0xFF1677E8),
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 14),
              if (isHotel) ...[
                Row(
                  children: [
                    Expanded(
                      child: _DateField(
                        label: 'Arrivée',
                        date: _startDate,
                        onTap: () => _pickDate(isStart: true),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _DateField(
                        label: 'Départ',
                        date: _endDate,
                        onTap: () => _pickDate(isStart: false),
                      ),
                    ),
                  ],
                ),
              ] else ...[
                _DateField(
                  label: 'Date',
                  date: _startDate,
                  onTap: () => _pickDate(isStart: true),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  children: [
                    for (final slot in _slots)
                      ChoiceChip(
                        label: Text(slot),
                        selected: _timeSlot == slot,
                        onSelected: (_) => setState(
                          () => _timeSlot = _timeSlot == slot ? null : slot,
                        ),
                      ),
                  ],
                ),
              ],
              const SizedBox(height: 12),
              _GuestStepper(
                label: isHotel ? 'Voyageurs' : 'Personnes',
                value: _guests,
                max: _listing.maxGuests ?? 12,
                onChanged: (v) => setState(() => _guests = v),
              ),
              if (total != null) ...[
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total estimé',
                      style: TextStyle(
                        color: colors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      _formatTotal(total, _listing.currency),
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _isValid && !_submitting ? _submit : null,
                icon: _submitting
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.event_available_rounded),
                label: Text(
                  _submitting ? 'Réservation…' : 'Confirmer la réservation',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTotal(num value, String currency) {
    final rounded = value.round().toString();
    final buffer = StringBuffer();
    for (var i = 0; i < rounded.length; i++) {
      final left = rounded.length - i;
      buffer.write(rounded[i]);
      if (left > 1 && left % 3 == 1) buffer.write(' ');
    }
    return '$buffer $currency';
  }
}

class _DateField extends StatelessWidget {
  const _DateField({required this.label, required this.date, required this.onTap});

  final String label;
  final DateTime? date;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.chezMoiColors;
    final text = date == null
        ? 'Choisir'
        : '${date!.day.toString().padLeft(2, '0')}/${date!.month.toString().padLeft(2, '0')}/${date!.year}';
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: colors.background,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: colors.border),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today_outlined, size: 18, color: colors.primaryBlue),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(color: colors.textSecondary, fontSize: 11),
                  ),
                  Text(
                    text,
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontWeight: FontWeight.w700,
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

class _GuestStepper extends StatelessWidget {
  const _GuestStepper({
    required this.label,
    required this.value,
    required this.max,
    required this.onChanged,
  });

  final String label;
  final int value;
  final int max;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.chezMoiColors;
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: colors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        IconButton.outlined(
          onPressed: value > 1 ? () => onChanged(value - 1) : null,
          icon: const Icon(Icons.remove),
        ),
        SizedBox(
          width: 36,
          child: Text(
            '$value',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        IconButton.outlined(
          onPressed: value < max ? () => onChanged(value + 1) : null,
          icon: const Icon(Icons.add),
        ),
      ],
    );
  }
}

void _showDefaultAuthRequiredSheet(BuildContext context) {
  String? redirect;
  try {
    final uri = GoRouterState.of(context).uri.toString();
    redirect = isValidRedirect(uri) ? uri : null;
  } catch (_) {
    redirect = null;
  }

  showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.22),
    builder: (context) => _DefaultAuthRequiredSheet(redirect: redirect),
  );
}

class _DefaultAuthRequiredSheet extends StatelessWidget {
  const _DefaultAuthRequiredSheet({required this.redirect});

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
          padding: EdgeInsets.fromLTRB(
            20,
            10,
            20,
            18 + MediaQuery.paddingOf(context).bottom,
          ),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            border: Border(top: BorderSide(color: colors.border)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const _SheetHeader(title: 'Réserver'),
              const SizedBox(height: 8),
              const _SheetBrandMark(icon: Icons.lock_outline_rounded),
              const SizedBox(height: 10),
              Text(
                'Connectez-vous pour envoyer une demande de réservation.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: colors.textSecondary,
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
                child: const Text('Se connecter'),
              ),
              const SizedBox(height: 10),
              Text(
                'Pas encore de compte ? Créez-en un en quelques secondes.',
                textAlign: TextAlign.center,
                style: TextStyle(color: colors.textSecondary, fontSize: 12.5),
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
        width: 62,
        height: 62,
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
                width: 42,
                height: 42,
                fit: BoxFit.contain,
              ),
            ),
            Icon(icon, color: colors.primaryBlue, size: 27),
          ],
        ),
      ),
    );
  }
}

class _DetailActionBar extends StatelessWidget {
  const _DetailActionBar({required this.onShowOnMap, required this.onContact});

  final VoidCallback? onShowOnMap;
  final VoidCallback onContact;

  @override
  Widget build(BuildContext context) {
    final colors = context.chezMoiColors;
    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        12 + MediaQuery.paddingOf(context).bottom,
      ),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(top: BorderSide(color: colors.border)),
        boxShadow: [
          BoxShadow(
            color: colors.textPrimary.withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      child: Row(
        children: [
          if (onShowOnMap != null) ...[
            SizedBox(
              width: 52,
              height: 48,
              child: Tooltip(
                message: 'Carte',
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    onShowOnMap!();
                  },
                  style: OutlinedButton.styleFrom(
                    shape: const CircleBorder(),
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(48, 48),
                  ),
                  child: const Icon(Icons.map_outlined),
                ),
              ),
            ),
            const SizedBox(width: 10),
          ],
          Expanded(
            flex: onShowOnMap == null ? 1 : 2,
            child: FilledButton.icon(
              onPressed: onContact,
              icon: const Icon(Icons.event_available_rounded),
              label: const Text('Réserver'),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailSectionTitle extends StatelessWidget {
  const _DetailSectionTitle({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = context.chezMoiColors;
    return Text(
      label,
      style: TextStyle(
        color: colors.textPrimary,
        fontSize: 15,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class _DetailFactsRow extends StatelessWidget {
  const _DetailFactsRow({required this.listing});

  final Place listing;

  @override
  Widget build(BuildContext context) {
    final facts = <({IconData icon, String label})>[
      (icon: Icons.hotel_outlined, label: listing.subtypeLabel),
      if (listing.starRatingLabel != null)
        (icon: Icons.star_rounded, label: listing.starRatingLabel!),
      if (listing.guestRatingLabel != null)
        (
          icon: Icons.reviews_outlined,
          label: listing.guestRatingMention == null
              ? listing.guestRatingLabel!
              : '${listing.guestRatingLabel!} · ${listing.guestRatingMention!}',
        ),
      if (listing.capacityLabel != null)
        (icon: Icons.group_outlined, label: listing.capacityLabel!),
      if (listing.distanceLabel != null)
        (icon: Icons.near_me_outlined, label: listing.distanceLabel!),
    ];
    final colors = context.chezMoiColors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors.border),
      ),
      child: Wrap(
        spacing: 12,
        runSpacing: 8,
        children: [
          for (final fact in facts)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(fact.icon, size: 15, color: colors.textSecondary),
                const SizedBox(width: 5),
                Text(
                  fact.label,
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 14,
                    height: 1.25,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _NearbyPlacesPanel extends StatelessWidget {
  const _NearbyPlacesPanel({
    required this.places,
    required this.loading,
    required this.error,
  });

  final List<NearbyPlace> places;
  final bool loading;
  final bool error;

  @override
  Widget build(BuildContext context) {
    final colors = context.chezMoiColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(child: _DetailSectionTitle(label: 'À proximité')),
            if (places.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: colors.lightBlueAccent,
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  '${places.length} lieux',
                  style: TextStyle(
                    color: colors.primaryBlue,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        if (loading)
          SizedBox(
            height: 96,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: 3,
              separatorBuilder: (_, _) => const SizedBox(width: 10),
              itemBuilder: (context, index) => Container(
                width: 210,
                decoration: BoxDecoration(
                  color: colors.background,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: colors.border),
                ),
              ),
            ),
          )
        else if (error && places.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colors.background,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: colors.border),
            ),
            child: Text(
              'Les lieux à proximité seront disponibles après synchronisation.',
              style: TextStyle(color: colors.textSecondary, fontSize: 13),
            ),
          )
        else if (places.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colors.background,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: colors.border),
            ),
            child: Text(
              'Aucun lieu important détecté autour de cette position.',
              style: TextStyle(color: colors.textSecondary, fontSize: 13),
            ),
          )
        else
          SizedBox(
            height: 98,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: places.length,
              separatorBuilder: (_, _) => const SizedBox(width: 10),
              itemBuilder: (context, index) =>
                  _NearbyPlaceCard(place: places[index]),
            ),
          ),
      ],
    );
  }
}

class _NearbyPlaceCard extends StatelessWidget {
  const _NearbyPlaceCard({required this.place});

  final NearbyPlace place;

  @override
  Widget build(BuildContext context) {
    final colors = context.chezMoiColors;
    final iconColor = _nearbyPlaceColor(place.iconKey);
    return Container(
      width: 210,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: colors.background.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: colors.border.withValues(alpha: 0.78)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.09),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              _nearbyPlaceIcon(place.iconKey),
              color: iconColor.withValues(alpha: 0.86),
              size: 18,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  place.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 12.8,
                    height: 1.15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  place.categoryLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colors.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                Text(
                  place.distanceLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colors.primaryBlue.withValues(alpha: 0.86),
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

IconData _nearbyPlaceIcon(String key) {
  return switch (key) {
    'bakery' => Icons.bakery_dining_rounded,
    'fast_food' => Icons.fastfood_rounded,
    'cafe' => Icons.local_cafe_rounded,
    'restaurant' || 'food' => Icons.restaurant_rounded,
    'pharmacy' => Icons.local_pharmacy_rounded,
    'hospital' => Icons.local_hospital_rounded,
    'clinic' || 'health' => Icons.medical_services_rounded,
    'supermarket' || 'cart' => Icons.shopping_cart_rounded,
    'mall' => Icons.local_mall_rounded,
    'market' || 'shop' => Icons.storefront_rounded,
    'airport' => Icons.flight_takeoff_rounded,
    'bus' || 'transit' || 'transport' => Icons.directions_bus_rounded,
    'fuel' => Icons.local_gas_station_rounded,
    'park' || 'leisure' => Icons.park_rounded,
    'beach' => Icons.beach_access_rounded,
    'gym' => Icons.fitness_center_rounded,
    'bank' => Icons.account_balance_rounded,
    'atm' => Icons.atm_rounded,
    'parking' => Icons.local_parking_rounded,
    'school' => Icons.school_rounded,
    'university' => Icons.account_balance_rounded,
    'hotel' => Icons.hotel_rounded,
    'activity' => Icons.hiking_rounded,
    _ => Icons.place_rounded,
  };
}

Color _nearbyPlaceColor(String key) {
  if (key == 'hotel') return const Color(0xFF1677E8);
  if (key == 'activity') return const Color(0xFF65A30D);
  if (['school', 'university'].contains(key)) return const Color(0xFF4F46E5);
  if (['cart', 'supermarket', 'mall', 'market', 'shop'].contains(key)) {
    return const Color(0xFF059669);
  }
  if (['health', 'pharmacy', 'hospital', 'clinic'].contains(key)) {
    return const Color(0xFFE11D48);
  }
  if (['transport', 'airport', 'bus', 'transit', 'fuel'].contains(key)) {
    return const Color(0xFF0284C7);
  }
  if (['food', 'restaurant', 'fast_food', 'cafe', 'bakery'].contains(key)) {
    return const Color(0xFFEA580C);
  }
  if (['leisure', 'park', 'beach', 'gym'].contains(key)) {
    return const Color(0xFF65A30D);
  }
  return const Color(0xFF475569);
}

class _DetailMapPreview extends StatelessWidget {
  const _DetailMapPreview({
    required this.listing,
    required this.nearbyPlaces,
    required this.onShowOnMap,
  });

  final Place listing;
  final List<NearbyPlace> nearbyPlaces;
  final VoidCallback? onShowOnMap;

  @override
  Widget build(BuildContext context) {
    final colors = context.chezMoiColors;
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        height: 190,
        child: Stack(
          fit: StackFit.expand,
          children: [
            ChezMoiMapView(
              listings: [listing],
              nearbyPlaces: nearbyPlaces,
              selectedListingId: listing.id,
              compact: true,
              onListingSelected: (_) {},
            ),
            if (onShowOnMap != null)
              Positioned(
                right: 10,
                top: 10,
                child: FilledButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    onShowOnMap!();
                  },
                  icon: const Icon(Icons.open_in_full_rounded, size: 16),
                  label: const Text('Agrandir'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    minimumSize: const Size(0, 38),
                  ),
                ),
              ),
            Positioned(
              left: 10,
              bottom: 10,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: colors.surface.withValues(alpha: 0.95),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: colors.border),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  child: Text(
                    listing.locationLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ListingPhotoGallery extends StatelessWidget {
  const _ListingPhotoGallery({required this.urls});

  final List<String> urls;

  @override
  Widget build(BuildContext context) {
    final colors = context.chezMoiColors;
    if (urls.isEmpty) {
      return AspectRatio(
        aspectRatio: 1.28,
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFFEAF3F8),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: colors.border),
          ),
          child: Center(
            child: Container(
              width: 82,
              height: 82,
              decoration: BoxDecoration(
                color: colors.surface.withValues(alpha: 0.86),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: colors.border),
              ),
              child: Icon(
                Icons.place_outlined,
                color: colors.primaryBlue,
                size: 44,
              ),
            ),
          ),
        ),
      );
    }

    return SizedBox(
      height: 300,
      child: PageView.builder(
        padEnds: false,
        itemCount: urls.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: EdgeInsets.only(right: index == urls.length - 1 ? 0 : 10),
            child: Stack(
              fit: StackFit.expand,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    urls[index],
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: colors.lightBlueAccent,
                      child: Icon(
                        Icons.broken_image_outlined,
                        color: colors.primaryBlue,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  right: 10,
                  bottom: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: colors.textPrimary.withValues(alpha: 0.76),
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Text(
                      '${index + 1}/${urls.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ReportListingSheet extends StatefulWidget {
  const _ReportListingSheet({required this.listing});

  final Place listing;

  @override
  State<_ReportListingSheet> createState() => _ReportListingSheetState();
}

class _ReportListingSheetState extends State<_ReportListingSheet> {
  final _placeService = PlaceService();
  final _messageController = TextEditingController();
  String? _selectedReason;
  bool _submitting = false;
  bool _sent = false;
  String? _errorMessage;

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.chezMoiColors;
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    return Align(
      alignment: Alignment.bottomCenter,
      child: SafeArea(
        top: false,
        bottom: false,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.88,
          ),
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(
              20,
              10,
              20,
              bottomInset + MediaQuery.viewInsetsOf(context).bottom + 20,
            ),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
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
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const _SheetHeader(title: 'Signaler cet établissement'),
                  const SizedBox(height: 10),
                  if (_sent)
                    _ReportSuccessState(onClose: () => Navigator.pop(context))
                  else ...[
                    _ReportListingSummary(listing: widget.listing),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedReason,
                      items: [
                        for (final reason in _reportReasons)
                          DropdownMenuItem(value: reason, child: Text(reason)),
                      ],
                      onChanged: _submitting
                          ? null
                          : (value) {
                              setState(() {
                                _selectedReason = value;
                                _errorMessage = null;
                              });
                            },
                      decoration: const InputDecoration(
                        labelText: 'Motif',
                        prefixIcon: Icon(Icons.flag_outlined),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _messageController,
                      enabled: !_submitting,
                      minLines: 4,
                      maxLines: 7,
                      maxLength: 2000,
                      textInputAction: TextInputAction.newline,
                      onChanged: (_) {
                        if (_errorMessage != null) {
                          setState(() => _errorMessage = null);
                        }
                      },
                      decoration: const InputDecoration(
                        labelText: 'Détails',
                        hintText:
                            'Ajoutez ce qui vous semble incorrect ou suspect.',
                        alignLabelWithHint: true,
                        prefixIcon: Icon(Icons.notes_rounded),
                      ),
                    ),
                    if (_errorMessage != null) ...[
                      const SizedBox(height: 6),
                      _ReportInlineMessage(message: _errorMessage!),
                    ],
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      onPressed: _submitting ? null : _submit,
                      icon: _submitting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.send_rounded),
                      label: Text(
                        _submitting ? 'Envoi en cours...' : 'Envoyer',
                      ),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'L’équipe ChezMoi vérifiera le signalement.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: colors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    final reason = _selectedReason?.trim() ?? '';
    final message = _messageController.text.trim();
    if (reason.isEmpty) {
      setState(() => _errorMessage = 'Sélectionnez un motif.');
      return;
    }
    setState(() {
      _submitting = true;
      _errorMessage = null;
    });
    try {
      await _placeService.reportPlace(
        listing: widget.listing,
        reason: reason,
        message: message,
      );
      if (!mounted) return;
      _messageController.clear();
      setState(() {
        _selectedReason = null;
        _sent = true;
      });
    } catch (_) {
      if (!mounted) return;
      setState(
        () => _errorMessage =
            'Impossible d’envoyer le signalement. Réessayez dans un instant.',
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }
}

class _ReportListingSummary extends StatelessWidget {
  const _ReportListingSummary({required this.listing});

  final Place listing;

  @override
  Widget build(BuildContext context) {
    final colors = context.chezMoiColors;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: [
          Icon(Icons.home_work_outlined, color: colors.textSecondary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                const SizedBox(height: 2),
                Text(
                  listing.locationLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ReportInlineMessage extends StatelessWidget {
  const _ReportInlineMessage({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final colors = context.chezMoiColors;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.error_outline_rounded, color: colors.danger, size: 18),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            message,
            style: TextStyle(
              color: colors.danger,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _ReportSuccessState extends StatelessWidget {
  const _ReportSuccessState({required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final colors = context.chezMoiColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colors.primaryBlue.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: colors.primaryBlue.withValues(alpha: 0.18),
            ),
          ),
          child: Column(
            children: [
              Icon(
                Icons.verified_outlined,
                color: colors.primaryBlue,
                size: 34,
              ),
              const SizedBox(height: 10),
              Text(
                'Merci, le signalement a bien été envoyé.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 14,
                  height: 1.35,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Notre équipe va vérifier cet établissement.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: colors.textSecondary,
                  fontSize: 13,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        FilledButton(onPressed: onClose, child: const Text('Fermer')),
      ],
    );
  }
}

const _reportReasons = [
  'Établissement frauduleux',
  'Prix incorrect ou trompeur',
  'Photos ou description mensongères',
  'Établissement indisponible',
  'Coordonnées suspectes',
  'Doublon',
  'Contenu inapproprié',
  'Autre problème',
];

class _SheetHeader extends StatelessWidget {
  const _SheetHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final colors = context.chezMoiColors;
    return Row(
      children: [
        Text(
          title,
          style: TextStyle(
            color: colors.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w600,
            height: 1.2,
          ),
        ),
        const Spacer(),
        IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.close_rounded),
          tooltip: 'Fermer',
        ),
      ],
    );
  }
}

class _DetailChip extends StatelessWidget {
  const _DetailChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = context.chezMoiColors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: colors.lightBlueAccent,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: colors.navy,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }
}
