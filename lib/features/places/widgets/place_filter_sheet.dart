import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/theme.dart';
import '../../../services/location_search_service.dart';
import '../models/place.dart';

class PlaceFilterSheet extends StatefulWidget {
  const PlaceFilterSheet({super.key, required this.initialFilter});

  final PlaceFilter initialFilter;

  @override
  State<PlaceFilterSheet> createState() => _PlaceFilterSheetState();
}

class _PlaceFilterSheetState extends State<PlaceFilterSheet> {
  late String? _subtype = widget.initialFilter.subtype;
  late final _zonesController = TextEditingController(
    text: widget.initialFilter.zones.join(', '),
  );
  final _locationSearchService = LocationSearchService();
  Timer? _zoneDebounce;
  bool _searchingZone = false;
  List<LocationSearchResult> _zoneSuggestions = const [];
  late final _minBudgetController = TextEditingController(
    text: widget.initialFilter.minPrice?.round().toString() ?? '',
  );
  late final _maxBudgetController = TextEditingController(
    text: widget.initialFilter.maxPrice?.round().toString() ?? '',
  );

  @override
  void dispose() {
    _zoneDebounce?.cancel();
    _locationSearchService.dispose();
    _minBudgetController.dispose();
    _maxBudgetController.dispose();
    _zonesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.chezMoiColors;

    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 6,
          bottom: MediaQuery.viewInsetsOf(context).bottom + 16,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
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
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Affiner la recherche',
                        style: TextStyle(
                          color: colors.textPrimary,
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        "Combinez zones, type d'établissement et budget.",
                        style: TextStyle(
                          color: colors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton.filledTonal(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                  tooltip: 'Retour',
                ),
              ],
            ),
            const SizedBox(height: 16),
            _SectionLabel(label: 'Où chercher ?'),
            TextField(
              controller: _zonesController,
              onChanged: _searchZones,
              decoration: const InputDecoration(
                labelText: 'Zones',
                hintText: 'Ex. Akanda, Glass, Nzeng-Ayong',
                prefixIcon: Icon(Icons.travel_explore_rounded),
              ),
            ),
            if (_searchingZone) ...[
              const SizedBox(height: 8),
              const LinearProgressIndicator(minHeight: 2),
            ],
            if (_zoneSuggestions.isNotEmpty) ...[
              const SizedBox(height: 8),
              _ZoneSuggestionPanel(
                suggestions: _zoneSuggestions,
                onSelected: _selectZone,
              ),
            ],
            const SizedBox(height: 16),
            _SectionLabel(label: "Type d'établissement"),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _FilterChoice(
                  label: 'Tous',
                  icon: Icons.apps_rounded,
                  selected: _subtype == null,
                  onTap: () => setState(() => _subtype = null),
                ),
                _FilterChoice(
                  label: 'Hotel',
                  icon: Icons.hotel_rounded,
                  selected: _subtype == 'hotel',
                  onTap: () => setState(() => _subtype = 'hotel'),
                ),
                _FilterChoice(
                  label: 'Auberge',
                  icon: Icons.house_rounded,
                  selected: _subtype == 'hostel',
                  onTap: () => setState(() => _subtype = 'hostel'),
                ),
                _FilterChoice(
                  label: 'Motel',
                  icon: Icons.local_hotel_rounded,
                  selected: _subtype == 'motel',
                  onTap: () => setState(() => _subtype = 'motel'),
                ),
                _FilterChoice(
                  label: "Maison d'hotes",
                  icon: Icons.cottage_rounded,
                  selected: _subtype == 'guesthouse',
                  onTap: () => setState(() => _subtype = 'guesthouse'),
                ),
                _FilterChoice(
                  label: 'Appart-hotel',
                  icon: Icons.apartment_rounded,
                  selected: _subtype == 'apartment_hotel',
                  onTap: () => setState(() => _subtype = 'apartment_hotel'),
                ),
                _FilterChoice(
                  label: 'Resort',
                  icon: Icons.beach_access_rounded,
                  selected: _subtype == 'resort',
                  onTap: () => setState(() => _subtype = 'resort'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _SectionLabel(label: 'Budget'),
            LayoutBuilder(
              builder: (context, constraints) {
                final narrow = constraints.maxWidth < 360;
                final minField = TextField(
                  controller: _minBudgetController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Minimum',
                    prefixIcon: Icon(Icons.payments_outlined),
                  ),
                );
                final maxField = TextField(
                  controller: _maxBudgetController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Maximum',
                    prefixIcon: Icon(Icons.account_balance_wallet_outlined),
                  ),
                );
                if (narrow) {
                  return Column(
                    children: [minField, const SizedBox(height: 12), maxField],
                  );
                }
                return Row(
                  children: [
                    Expanded(child: minField),
                    const SizedBox(width: 12),
                    Expanded(child: maxField),
                  ],
                );
              },
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () =>
                        Navigator.pop(context, const PlaceFilter()),
                    icon: const Icon(Icons.restart_alt_rounded),
                    label: const Text('Réinitialiser'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => Navigator.pop(context, _buildFilter()),
                    icon: const Icon(Icons.check_rounded),
                    label: const Text('Appliquer'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  PlaceFilter _buildFilter() {
    return PlaceFilter(
      subtype: _subtype,
      minPrice: num.tryParse(_minBudgetController.text.trim()),
      maxPrice: num.tryParse(_maxBudgetController.text.trim()),
      zones: _zonesController.text
          .split(',')
          .map((zone) => zone.trim())
          .where((zone) => zone.isNotEmpty)
          .toList(),
    );
  }

  void _searchZones(String value) {
    _zoneDebounce?.cancel();
    final query = value.split(',').last.trim();
    if (query.length < 2) {
      setState(() {
        _zoneSuggestions = const [];
        _searchingZone = false;
      });
      return;
    }
    setState(() => _searchingZone = true);
    _zoneDebounce = Timer(const Duration(milliseconds: 300), () async {
      try {
        final suggestions = await _locationSearchService.autocomplete(
          query,
          countryCode: 'GA',
          lat: 0.3924,
          lng: 9.4582,
        );
        if (!mounted || _zonesController.text.split(',').last.trim() != query) {
          return;
        }
        setState(() {
          _zoneSuggestions = suggestions;
          _searchingZone = false;
        });
      } catch (_) {
        if (!mounted) return;
        setState(() {
          _zoneSuggestions = const [];
          _searchingZone = false;
        });
      }
    });
  }

  void _selectZone(LocationSearchResult result) {
    final selected = result.suburb.isNotEmpty
        ? result.suburb
        : result.city.isNotEmpty
        ? result.city
        : result.label;
    final zones = _zonesController.text
        .split(',')
        .map((zone) => zone.trim())
        .where((zone) => zone.isNotEmpty)
        .toList();
    if (!valueEndsWithComma(_zonesController.text) && zones.isNotEmpty) {
      zones.removeLast();
    }
    zones.add(selected);
    setState(() {
      _zonesController.text = '${zones.join(', ')}, ';
      _zonesController.selection = TextSelection.collapsed(
        offset: _zonesController.text.length,
      );
      _zoneSuggestions = const [];
      _searchingZone = false;
    });
  }
}

bool valueEndsWithComma(String value) => value.trimRight().endsWith(',');

class _ZoneSuggestionPanel extends StatelessWidget {
  const _ZoneSuggestionPanel({
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
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.border),
        boxShadow: [
          BoxShadow(
            color: colors.textPrimary.withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: colors.surface,
        child: Column(
          children: [
            for (final suggestion in suggestions.take(4))
              ListTile(
                dense: true,
                leading: Icon(Icons.place_outlined, color: colors.accent),
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

class _FilterChoice extends StatelessWidget {
  const _FilterChoice({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.chezMoiColors;
    return InkWell(
      borderRadius: BorderRadius.circular(99),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: selected
              ? colors.accent.withValues(alpha: 0.14)
              : colors.surface,
          borderRadius: BorderRadius.circular(99),
          border: Border.all(
            color: selected ? colors.accent : colors.border,
            width: selected ? 1.4 : 1,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: colors.accent.withValues(alpha: 0.13),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 17,
              color: selected ? colors.accent : colors.textSecondary,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: colors.textPrimary,
                fontWeight: selected ? FontWeight.w900 : FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = context.chezMoiColors;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        label,
        style: TextStyle(
          color: colors.textPrimary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
