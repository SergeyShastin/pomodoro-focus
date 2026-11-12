import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pomodoro_focus/l10n/app_localizations.dart';
import 'package:timezone/timezone.dart' as tz;

class LocalClockCard extends StatelessWidget {
  final tz.Location localLocation;
  final DateTime currentTimestamp;
  final String localeCode;

  const LocalClockCard({
    super.key,
    required this.localLocation,
    required this.currentTimestamp,
    required this.localeCode,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    final localDt = tz.TZDateTime.from(currentTimestamp, localLocation);
    final isDay = localDt.hour >= 6 && localDt.hour < 20;

    final h = localDt.hour.toString().padLeft(2, '0');
    final m = localDt.minute.toString().padLeft(2, '0');
    final s = localDt.second.toString().padLeft(2, '0');
    final timeStr = '$h:$m:$s';
    final dateStr = DateFormat.MMMEd(localeCode).format(localDt);

    final readableLocation =
        localLocation.name.split('/').last.replaceAll('_', ' ');

    return Card(
      color: theme.colorScheme.primaryContainer,
      elevation: 0,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: theme.colorScheme.primary.withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.my_location,
                        size: 18,
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        l10n.localTime,
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: theme.colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    readableLocation,
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: theme.colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    dateStr,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onPrimaryContainer
                          .withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Icon(
                  isDay ? Icons.wb_sunny_outlined : Icons.nightlight_outlined,
                  color: isDay ? Colors.amber : theme.colorScheme.tertiary,
                  size: 24,
                ),
                const SizedBox(height: 6),
                Text(
                  timeStr,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontFeatures: const [FontFeature.tabularFigures()],
                    color: theme.colorScheme.onPrimaryContainer,
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
