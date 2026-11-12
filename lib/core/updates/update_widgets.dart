import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pomodoro_focus/l10n/app_localizations.dart';
import '../../features/settings/presentation/settings_provider.dart';
import '../notifications/notification_service.dart';
import 'update_controller.dart';
import 'update_service.dart';

String updateStatus(AppLocalizations l10n, UpdateState state) {
  switch (state.phase) {
    case UpdatePhase.idle:
      return l10n.updatesDescription;
    case UpdatePhase.checking:
      return l10n.updatesChecking;
    case UpdatePhase.current:
      return l10n.updatesCurrent;
    case UpdatePhase.available:
      return l10n.updateAvailable(state.release!.version);
    case UpdatePhase.downloading:
      return l10n.updateDownloading((state.progress * 100).round());
    case UpdatePhase.opened:
      return l10n.updateInstallerOpened;
    case UpdatePhase.failed:
      switch (state.failure) {
        case UpdateFailure.unsupported:
          return l10n.updateUnsupported;
        case UpdateFailure.packageMissing:
          return l10n.updatePackageMissing;
        case UpdateFailure.integrity:
          return l10n.updateIntegrityError;
        case UpdateFailure.installer:
          return l10n.updateInstallerError;
        default:
          return l10n.updateNetworkError;
      }
  }
}

class UpdateHost extends ConsumerWidget {
  final Widget child;
  final bool compact;
  const UpdateHost({super.key, required this.child, this.compact = false});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!Platform.isLinux) return child;
    final l10n = AppLocalizations.of(context)!;
    final state = ref.watch(updateControllerProvider);
    ref.listen(updateControllerProvider, (previous, next) {
      if (next.phase == UpdatePhase.available &&
          previous?.release?.version != next.release?.version &&
          ref.read(settingsProvider).enableNotifications) {
        ref
            .read(notificationServiceProvider)
            .showNotification(
              id: 4200,
              title: l10n.updateAvailable(next.release!.version),
              body: l10n.updateNotificationBody,
            );
      }
    });
    if (compact) return child;
    return Column(
      children: [
        if (state.release != null)
          Material(
            color: Theme.of(context).colorScheme.secondaryContainer,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Wrap(
                  alignment: WrapAlignment.center,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    Text(
                      updateStatus(l10n, state),
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    if (state.phase != UpdatePhase.opened)
                      FilledButton.tonal(
                        onPressed:
                            ref.read(updateControllerProvider.notifier).busy
                            ? null
                            : () => ref
                                  .read(updateControllerProvider.notifier)
                                  .install(),
                        child: Text(l10n.updateAction),
                      ),
                  ],
                ),
              ),
            ),
          ),
        Expanded(child: child),
      ],
    );
  }
}

class UpdatesSettingsCard extends ConsumerWidget {
  const UpdatesSettingsCard({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!Platform.isLinux) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context)!;
    final state = ref.watch(updateControllerProvider);
    final controller = ref.read(updateControllerProvider.notifier);
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SwitchListTile(
            title: Text(l10n.automaticUpdates),
            subtitle: Text(l10n.updatesDescription),
            value: ref.watch(settingsProvider).automaticUpdates,
            onChanged: ref.read(settingsProvider.notifier).setAutomaticUpdates,
          ),
          ListTile(
            title: Text(l10n.updatesTitle),
            subtitle: Text(updateStatus(l10n, state)),
          ),
          if (state.phase == UpdatePhase.downloading)
            LinearProgressIndicator(value: state.progress),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                OutlinedButton(
                  onPressed: controller.busy ? null : () => controller.check(),
                  child: Text(l10n.checkUpdates),
                ),
                if (state.release != null)
                  FilledButton(
                    onPressed: controller.busy
                        ? null
                        : () => controller.install(),
                    child: Text(l10n.updateAction),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
