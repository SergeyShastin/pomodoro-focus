import 'package:flutter/material.dart';
import 'package:pomodoro_focus/l10n/app_localizations.dart';
import 'package:timezone/timezone.dart' as tz;
import '../../domain/world_clock_city.dart';

class CityClockCard extends StatelessWidget {
  final WorldClockCity city;
  final tz.Location localLocation;
  final DateTime currentTimestamp;
  final String localeCode;
  final VoidCallback onDelete;
  final int index;

  const CityClockCard({
    super.key,
    required this.city,
    required this.localLocation,
    required this.currentTimestamp,
    required this.localeCode,
    required this.onDelete,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    final isDay = city.isDay(currentTimestamp);
    final timeStr = city.formattedTime(currentTimestamp);
    final dateStr = city.formattedDate(currentTimestamp, localeCode);
    final offsetHours =
        city.getOffsetHoursDifferenceFrom(localLocation, currentTimestamp);

    final String offsetLabel;
    if (offsetHours > 0) {
      offsetLabel = l10n.aheadOfLocal(offsetHours);
    } else if (offsetHours < 0) {
      offsetLabel = l10n.behindLocal(-offsetHours);
    } else {
      offsetLabel = l10n.sameTime;
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            // Left info: City, country, offset pill & date
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          city.name,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.secondaryContainer,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          offsetLabel,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSecondaryContainer,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${city.country.isNotEmpty ? '${city.country} • ' : ''}$dateStr',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            // Right info: day/night icon, time, delete and drag handle
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isDay ? Icons.wb_sunny_outlined : Icons.nightlight_outlined,
                  color: isDay ? Colors.amber : theme.colorScheme.tertiary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  timeStr,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                const SizedBox(width: 4),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 20),
                  tooltip: l10n.delete,
                  onPressed: onDelete,
                ),
                ReorderableDragStartListener(
                  index: index,
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                    child: Icon(Icons.drag_handle, size: 20),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
