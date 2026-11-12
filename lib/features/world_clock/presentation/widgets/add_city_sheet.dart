import 'package:flutter/material.dart';
import 'package:pomodoro_focus/l10n/app_localizations.dart';
import '../../domain/cities_catalog.dart';
import '../../domain/world_clock_city.dart';

class AddCitySheet extends StatefulWidget {
  final List<WorldClockCity> currentCities;
  final ValueChanged<WorldClockCity> onCitySelected;

  const AddCitySheet({
    super.key,
    required this.currentCities,
    required this.onCitySelected,
  });

  @override
  State<AddCitySheet> createState() => _AddCitySheetState();
}

class _AddCitySheetState extends State<AddCitySheet> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    final filtered = availableCitiesCatalog.where((city) {
      final matchesQuery = _query.isEmpty ||
          city.name.toLowerCase().contains(_query.toLowerCase()) ||
          city.country.toLowerCase().contains(_query.toLowerCase()) ||
          city.timezone.toLowerCase().contains(_query.toLowerCase());
      final alreadyAdded = widget.currentCities.any((c) => c.id == city.id);
      return matchesQuery && !alreadyAdded;
    }).toList();

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            children: [
              // Drag Handle
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Search Field
              TextField(
                autofocus: true,
                decoration: InputDecoration(
                  hintText: l10n.searchCityHint,
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _query.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () => setState(() => _query = ''),
                        )
                      : null,
                ),
                onChanged: (val) => setState(() => _query = val),
              ),
              const SizedBox(height: 12),
              // Results List
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final city = filtered[index];
                    return ListTile(
                      title: Text(city.name),
                      subtitle: Text('${city.country} (${city.timezone})'),
                      trailing: const Icon(Icons.add_circle_outline),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      onTap: () {
                        widget.onCitySelected(city);
                        Navigator.of(context).pop();
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

