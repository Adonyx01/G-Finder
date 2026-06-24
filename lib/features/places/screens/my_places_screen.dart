import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme.dart';
import '../models/place.dart';
import '../services/place_service.dart';

/// Espace annonceur : liste et gestion de ses propres établissements.
class MyPlacesScreen extends StatefulWidget {
  const MyPlacesScreen({super.key});

  @override
  State<MyPlacesScreen> createState() => _MyPlacesScreenState();
}

class _MyPlacesScreenState extends State<MyPlacesScreen> {
  final _service = PlaceService();
  late Future<List<Place>> _future;

  @override
  void initState() {
    super.initState();
    _future = _service.loadMyPlaces();
  }

  void _reload() {
    setState(() => _future = _service.loadMyPlaces());
  }

  Future<void> _openPublish() async {
    final created = await context.push<bool>('/publish-place');
    if (created == true) _reload();
  }

  Future<void> _confirmDelete(Place place) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer ?'),
        content: Text('Supprimer définitivement « ${place.title} » ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await _service.deletePlace(place.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Établissement supprimé.')),
      );
      _reload();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('La suppression a échoué.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes établissements'),
        actions: [
          IconButton(
            tooltip: 'Publier',
            onPressed: _openPublish,
            icon: const Icon(Icons.add_business_outlined),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openPublish,
        icon: const Icon(Icons.add),
        label: const Text('Publier'),
      ),
      body: RefreshIndicator(
        onRefresh: () async => _reload(),
        child: FutureBuilder<List<Place>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return _MessageView(
                icon: Icons.error_outline,
                message: 'Impossible de charger vos établissements.',
              );
            }
            final places = snapshot.data ?? const <Place>[];
            if (places.isEmpty) {
              return _MessageView(
                icon: Icons.storefront_outlined,
                message:
                    "Vous n'avez pas encore publié d'établissement.\nAppuyez sur « Publier » pour commencer.",
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
              itemCount: places.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) => _MyPlaceCard(
                place: places[index],
                onDelete: () => _confirmDelete(places[index]),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _MyPlaceCard extends StatelessWidget {
  const _MyPlaceCard({required this.place, required this.onDelete});

  final Place place;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final colors = context.chezMoiColors;
    final cover = place.coverImageUrl;
    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.horizontal(
              left: Radius.circular(14),
            ),
            child: SizedBox(
              width: 96,
              height: 96,
              child: (cover != null && cover.isNotEmpty)
                  ? Image.network(
                      cover,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => _coverFallback(colors),
                    )
                  : _coverFallback(colors),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    place.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: colors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    [
                      place.categoryLabel,
                      if (place.city != null && place.city!.isNotEmpty)
                        place.city!,
                    ].join(' · '),
                    style: TextStyle(color: colors.textSecondary, fontSize: 13),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    place.priceLabel,
                    style: TextStyle(
                      color: colors.primaryBlue,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
          IconButton(
            tooltip: 'Supprimer',
            onPressed: onDelete,
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
    );
  }

  Widget _coverFallback(ChezMoiColors colors) {
    return Container(
      color: colors.background,
      child: Icon(Icons.image_outlined, color: colors.textSecondary),
    );
  }
}

class _MessageView extends StatelessWidget {
  const _MessageView({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    final colors = context.chezMoiColors;
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 80),
      children: [
        Icon(icon, size: 56, color: colors.textSecondary),
        const SizedBox(height: 16),
        Text(
          message,
          textAlign: TextAlign.center,
          style: TextStyle(color: colors.textSecondary, fontSize: 15),
        ),
      ],
    );
  }
}
