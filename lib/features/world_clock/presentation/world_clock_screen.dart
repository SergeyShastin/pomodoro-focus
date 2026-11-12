import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pomodoro_focus/l10n/app_localizations.dart';
import 'widgets/add_city_sheet.dart';
import 'widgets/city_clock_card.dart';
import 'widgets/local_clock_card.dart';
import 'world_clock_provider.dart';

class WorldClockScreen extends ConsumerWidget {
  const WorldClockScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final worldClockState = ref.watch(worldClockProvider);
    final notifier = ref.read(worldClockProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.worldClockTitle),
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: Text(l10n.addCity),
        onPressed: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            useSafeArea: true,
            builder: (ctx) => AddCitySheet(
              currentCities: worldClockState.cities,
              onCitySelected: (city) => notifier.addCity(city),
            ),
          );
        },
      ),
      body: Column(
        children: [
          // Pinned Local Time Card
          LocalClockCard(
            localLocation: worldClockState.localLocation,
            currentTimestamp: worldClockState.currentTimestamp,
            localeCode: 'en',
          ),
          // Reorderable Cities List
          Expanded(
            child: ReorderableListView.builder(
              padding: const EdgeInsets.only(bottom: 88, top: 4),
              itemCount: worldClockState.cities.length,
              buildDefaultDragHandles: false,
              onReorder: (oldIndex, newIndex) {
                notifier.reorderCities(oldIndex, newIndex);
              },
              itemBuilder: (context, index) {
                final city = worldClockState.cities[index];
                return CityClockCard(
                  key: ValueKey(city.id),
                  index: index,
                  city: city,
                  localLocation: worldClockState.localLocation,
                  currentTimestamp: worldClockState.currentTimestamp,
                  localeCode: 'en',
                  onDelete: () => notifier.removeCity(city.id),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
