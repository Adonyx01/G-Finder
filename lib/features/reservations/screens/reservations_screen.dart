import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme.dart';
import '../models/reservation.dart';
import '../services/reservation_service.dart';

class ReservationsScreen extends StatefulWidget {
  const ReservationsScreen({super.key});

  @override
  State<ReservationsScreen> createState() => _ReservationsScreenState();
}

class _ReservationsScreenState extends State<ReservationsScreen> {
  final _service = ReservationService();
  late Future<List<Reservation>> _future;

  @override
  void initState() {
    super.initState();
    _future = _service.loadMyReservations();
  }

  Future<void> _refresh() async {
    final next = _service.loadMyReservations();
    setState(() => _future = next);
    await next;
  }

  Future<void> _cancel(Reservation reservation) async {
    await _service.cancelReservation(reservation.id);
    await _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.chezMoiColors;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes réservations'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () =>
              context.canPop() ? context.pop() : context.go('/dashboard'),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<List<Reservation>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            final reservations = snapshot.data ?? const <Reservation>[];
            if (reservations.isEmpty) {
              return _EmptyState(colors: colors);
            }
            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              itemCount: reservations.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) => _ReservationCard(
                reservation: reservations[index],
                onCancel: () => _cancel(reservations[index]),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.colors});

  final ChezMoiColors colors;

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        SizedBox(height: MediaQuery.sizeOf(context).height * 0.18),
        Icon(
          Icons.event_busy_outlined,
          size: 56,
          color: colors.textSecondary,
        ),
        const SizedBox(height: 16),
        Center(
          child: Text(
            'Aucune réservation pour le moment',
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'Réservez un hôtel, un restaurant ou une activité depuis l\'accueil.',
              textAlign: TextAlign.center,
              style: TextStyle(color: colors.textSecondary, height: 1.4),
            ),
          ),
        ),
      ],
    );
  }
}

class _ReservationCard extends StatelessWidget {
  const _ReservationCard({required this.reservation, required this.onCancel});

  final Reservation reservation;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final colors = context.chezMoiColors;
    final cancellable =
        reservation.status == 'pending' || reservation.status == 'confirmed';

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Thumb(url: reservation.placeCoverImageUrl),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              reservation.placeTitle ?? 'Établissement',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: colors.textPrimary,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          _StatusBadge(reservation: reservation),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${reservation.categoryLabel}'
                        '${reservation.placeCity != null ? ' · ${reservation.placeCity}' : ''}',
                        style: TextStyle(
                          color: colors.textSecondary,
                          fontSize: 12.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _MetaRow(
                        icon: Icons.event_outlined,
                        text: reservation.scheduleLabel,
                      ),
                      const SizedBox(height: 4),
                      _MetaRow(
                        icon: Icons.group_outlined,
                        text: reservation.guestsLabel,
                      ),
                      if (reservation.totalPriceLabel != null) ...[
                        const SizedBox(height: 4),
                        _MetaRow(
                          icon: Icons.payments_outlined,
                          text: 'Total estimé : ${reservation.totalPriceLabel}',
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (cancellable)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
              child: Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: onCancel,
                  icon: const Icon(Icons.cancel_outlined, size: 18),
                  label: const Text('Annuler'),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFFEF4444),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Thumb extends StatelessWidget {
  const _Thumb({required this.url});

  final String? url;

  @override
  Widget build(BuildContext context) {
    final colors = context.chezMoiColors;
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: SizedBox(
        width: 64,
        height: 64,
        child: url == null
            ? Container(
                color: colors.background,
                child: Icon(Icons.image_outlined, color: colors.textSecondary),
              )
            : Image.network(
                url!,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Container(
                  color: colors.background,
                  child: Icon(Icons.image_outlined, color: colors.textSecondary),
                ),
              ),
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = context.chezMoiColors;
    return Row(
      children: [
        Icon(icon, size: 15, color: colors.textSecondary),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: TextStyle(color: colors.textSecondary, fontSize: 12.5),
          ),
        ),
      ],
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.reservation});

  final Reservation reservation;

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (reservation.status) {
      'confirmed' => (const Color(0xFFDCFCE7), const Color(0xFF15803D)),
      'cancelled' => (const Color(0xFFFEE2E2), const Color(0xFFB91C1C)),
      'completed' => (const Color(0xFFE0E7FF), const Color(0xFF3730A3)),
      _ => (const Color(0xFFFEF3C7), const Color(0xFF92400E)),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        reservation.statusLabel,
        style: TextStyle(color: fg, fontSize: 11, fontWeight: FontWeight.w800),
      ),
    );
  }
}
