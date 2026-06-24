import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/theme.dart';
import '../models/place.dart';
import '../models/place_draft.dart';
import '../services/place_service.dart';
import '../services/template_places_data.dart';

/// Formulaire de publication d'un établissement (réservé aux annonceurs).
class PublishPlaceScreen extends StatefulWidget {
  const PublishPlaceScreen({super.key});

  @override
  State<PublishPlaceScreen> createState() => _PublishPlaceScreenState();
}

class _PublishPlaceScreenState extends State<PublishPlaceScreen> {
  final _formKey = GlobalKey<FormState>();
  final _placeService = PlaceService();
  final _picker = ImagePicker();

  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _subtypeController = TextEditingController();
  final _priceController = TextEditingController();
  final _maxGuestsController = TextEditingController();
  final _cityController = TextEditingController();
  final _neighborhoodController = TextEditingController();
  final _addressController = TextEditingController();

  String _category = 'hotel';
  final Set<String> _amenities = <String>{};
  final List<String> _imageUrls = <String>[];
  LatLng? _position;
  bool _uploading = false;
  bool _submitting = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _subtypeController.dispose();
    _priceController.dispose();
    _maxGuestsController.dispose();
    _cityController.dispose();
    _neighborhoodController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  String get _subtypeLabel => switch (_category) {
    'restaurant' => 'Type de cuisine (optionnel)',
    'activity' => "Type d'activité (optionnel)",
    _ => "Type d'hôtel (optionnel)",
  };

  String _priceUnitLabel(String unit) => switch (unit) {
    'night' => 'par nuit',
    'person' => 'par personne',
    'table' => 'par table',
    'session' => 'par séance',
    _ => '',
  };

  Future<void> _addPhotos() async {
    if (_uploading) return;
    final List<XFile> files = await _picker.pickMultiImage();
    if (files.isEmpty) return;
    setState(() => _uploading = true);
    try {
      for (final file in files) {
        final bytes = await file.readAsBytes();
        final ext = file.name.contains('.')
            ? file.name.split('.').last.toLowerCase()
            : 'jpg';
        final url = await _placeService.uploadPlacePhoto(
          bytes,
          fileExtension: ext,
        );
        if (!mounted) return;
        setState(() => _imageUrls.add(url));
      }
    } catch (_) {
      if (mounted) _showMessage('Échec du téléversement d\'une photo.');
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_position == null) {
      _showMessage('Placez votre établissement sur la carte.');
      return;
    }

    final unit = PlaceDraft.defaultPriceUnit(_category);
    final draft = PlaceDraft(
      category: _category,
      title: _titleController.text.trim(),
      latitude: _position!.latitude,
      longitude: _position!.longitude,
      description: _textOrNull(_descriptionController),
      subtype: _textOrNull(_subtypeController),
      price: num.tryParse(_priceController.text.trim()),
      priceUnit: unit,
      maxGuests: int.tryParse(_maxGuestsController.text.trim()),
      address: _textOrNull(_addressController),
      neighborhood: _textOrNull(_neighborhoodController),
      city: _textOrNull(_cityController),
      coverImageUrl: _imageUrls.isNotEmpty ? _imageUrls.first : null,
      imageUrls: List<String>.from(_imageUrls),
      amenities: _amenities.toList(),
    );

    setState(() => _submitting = true);
    try {
      await _placeService.createPlace(draft);
      if (!mounted) return;
      _showMessage('Établissement publié.');
      context.pop(true);
    } catch (_) {
      if (!mounted) return;
      _showMessage('La publication a échoué. Réessayez.');
      setState(() => _submitting = false);
    }
  }

  String? _textOrNull(TextEditingController c) {
    final value = c.text.trim();
    return value.isEmpty ? null : value;
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.chezMoiColors;
    final unit = PlaceDraft.defaultPriceUnit(_category);

    return Scaffold(
      appBar: AppBar(title: const Text('Publier un établissement')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            children: [
              _Label('Catégorie'),
              const SizedBox(height: 8),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(
                    value: 'hotel',
                    label: Text('Hôtel'),
                    icon: Icon(Icons.hotel_rounded),
                  ),
                  ButtonSegment(
                    value: 'restaurant',
                    label: Text('Resto'),
                    icon: Icon(Icons.restaurant_rounded),
                  ),
                  ButtonSegment(
                    value: 'activity',
                    label: Text('Activité'),
                    icon: Icon(Icons.hiking_rounded),
                  ),
                ],
                selected: {_category},
                onSelectionChanged: _submitting
                    ? null
                    : (s) => setState(() => _category = s.first),
              ),
              const SizedBox(height: 18),
              TextFormField(
                controller: _titleController,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Nom de l\'établissement',
                ),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Veuillez saisir un nom.'
                    : null,
                enabled: !_submitting,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _descriptionController,
                maxLines: 3,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Description (optionnel)',
                ),
                enabled: !_submitting,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _subtypeController,
                decoration: InputDecoration(labelText: _subtypeLabel),
                enabled: !_submitting,
              ),
              const SizedBox(height: 14),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _priceController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Prix (XAF)',
                        helperText: _priceUnitLabel(unit),
                      ),
                      validator: (v) {
                        final value = v?.trim() ?? '';
                        if (value.isEmpty) return null;
                        return num.tryParse(value) == null
                            ? 'Prix invalide.'
                            : null;
                      },
                      enabled: !_submitting,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _maxGuestsController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Capacité',
                        helperText: 'personnes',
                      ),
                      enabled: !_submitting,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _cityController,
                decoration: const InputDecoration(labelText: 'Ville'),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Veuillez saisir la ville.'
                    : null,
                enabled: !_submitting,
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _neighborhoodController,
                      decoration: const InputDecoration(
                        labelText: 'Quartier (optionnel)',
                      ),
                      enabled: !_submitting,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _addressController,
                      decoration: const InputDecoration(
                        labelText: 'Adresse (optionnel)',
                      ),
                      enabled: !_submitting,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              _Label('Équipements / services'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  for (final AmenityOption a in TemplateLodgingData.amenities)
                    FilterChip(
                      label: Text(a.label),
                      selected: _amenities.contains(a.label),
                      onSelected: _submitting
                          ? null
                          : (sel) => setState(() {
                              if (sel) {
                                _amenities.add(a.label);
                              } else {
                                _amenities.remove(a.label);
                              }
                            }),
                    ),
                ],
              ),
              const SizedBox(height: 22),
              _Label('Position'),
              const SizedBox(height: 4),
              Text(
                _position == null
                    ? 'Touchez la carte pour placer votre établissement.'
                    : 'Position : ${_position!.latitude.toStringAsFixed(4)}, ${_position!.longitude.toStringAsFixed(4)}',
                style: TextStyle(
                  color: _position == null
                      ? colors.textSecondary
                      : colors.primaryBlue,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: SizedBox(
                  height: 240,
                  child: FlutterMap(
                    options: MapOptions(
                      initialCenter: const LatLng(0.3924, 9.4582),
                      initialZoom: 11,
                      minZoom: 4,
                      maxZoom: 18,
                      onTap: _submitting
                          ? null
                          : (_, point) => setState(() => _position = point),
                    ),
                    children: [
                      TileLayer(
                        urlTemplate:
                            'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.example.chezmoi',
                      ),
                      if (_position != null)
                        MarkerLayer(
                          markers: [
                            Marker(
                              point: _position!,
                              width: 44,
                              height: 44,
                              alignment: Alignment.topCenter,
                              child: Icon(
                                Icons.location_on,
                                size: 44,
                                color: colors.primaryBlue,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 22),
              _Label('Photos'),
              const SizedBox(height: 8),
              if (_imageUrls.isNotEmpty)
                SizedBox(
                  height: 92,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _imageUrls.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 8),
                    itemBuilder: (context, index) =>
                        _PhotoThumb(
                          url: _imageUrls[index],
                          isCover: index == 0,
                          onRemove: _submitting
                              ? null
                              : () =>
                                    setState(() => _imageUrls.removeAt(index)),
                        ),
                  ),
                ),
              if (_imageUrls.isNotEmpty) const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: (_submitting || _uploading) ? null : _addPhotos,
                icon: _uploading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.add_a_photo_outlined),
                label: Text(_uploading ? 'Envoi…' : 'Ajouter des photos'),
              ),
              const SizedBox(height: 26),
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
                    : const Icon(Icons.publish_rounded),
                label: const Text('Publier'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontWeight: FontWeight.w700,
        fontSize: 15,
        color: context.chezMoiColors.textPrimary,
      ),
    );
  }
}

class _PhotoThumb extends StatelessWidget {
  const _PhotoThumb({
    required this.url,
    required this.isCover,
    required this.onRemove,
  });

  final String url;
  final bool isCover;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Image.network(
            url,
            width: 120,
            height: 92,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => Container(
              width: 120,
              height: 92,
              color: Colors.black12,
              child: const Icon(Icons.broken_image_outlined),
            ),
          ),
        ),
        if (isCover)
          Positioned(
            left: 4,
            bottom: 4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                'Couverture',
                style: TextStyle(color: Colors.white, fontSize: 10),
              ),
            ),
          ),
        if (onRemove != null)
          Positioned(
            right: 0,
            top: 0,
            child: GestureDetector(
              onTap: onRemove,
              child: Container(
                margin: const EdgeInsets.all(2),
                decoration: const BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, size: 16, color: Colors.white),
              ),
            ),
          ),
      ],
    );
  }
}
