import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/l10n.dart';
import '../../core/reminder_options.dart';
import '../auth/auth_controller.dart';

/// Settings: appearance, language, discipline threshold, notification
/// preferences, and links to organisation screens. Changes apply immediately and
/// sync in the background (queued offline).
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final user = ref.watch(authControllerProvider).value;
    final controller = ref.read(authControllerProvider.notifier);
    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // A lead time set on another client might not be in our list; fall back to
    // "at start time" for the dropdown's selected value so it never asserts.
    final selectedLead = reminderLeadMinutesOptions.contains(user.reminderLeadMinutes)
        ? user.reminderLeadMinutes
        : 0;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.navSettings)),
      body: ListView(
        children: [
          _sectionHeader(context, l10n.settingsAccount),
          ListTile(
            leading: const Icon(Icons.person_outline),
            title: Text(user.email),
            subtitle: Text(l10n.timezoneLabel(user.timezone)),
          ),

          _sectionHeader(context, l10n.settingsAppearance),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SegmentedButton<String>(
              segments: [
                ButtonSegment(
                    value: 'system',
                    icon: const Icon(Icons.brightness_auto),
                    label: Text(l10n.themeSystem)),
                ButtonSegment(
                    value: 'light',
                    icon: const Icon(Icons.light_mode),
                    label: Text(l10n.themeLight)),
                ButtonSegment(
                    value: 'dark',
                    icon: const Icon(Icons.dark_mode),
                    label: Text(l10n.themeDark)),
              ],
              selected: {user.theme},
              onSelectionChanged: (s) => controller.updateSettings(theme: s.first),
            ),
          ),

          _sectionHeader(context, l10n.settingsLanguage),
          ListTile(
            leading: const Icon(Icons.translate),
            title: Text(l10n.settingsLanguage),
            // Each option is written in its own language, so a user who lands in
            // a language they can't read can still find their way out.
            subtitle: Text(AppLocale.fromCode(user.language).nativeName),
            trailing: DropdownButton<String>(
              value: AppLocale.fromCode(user.language).code,
              underline: const SizedBox.shrink(),
              onChanged: (code) {
                if (code != null) controller.updateSettings(language: code);
              },
              items: [
                for (final locale in AppLocale.values)
                  DropdownMenuItem(value: locale.code, child: Text(locale.nativeName)),
              ],
            ),
          ),

          _sectionHeader(context, l10n.settingsDiscipline),
          ListTile(
            title: Text(l10n.successfulDayThreshold),
            subtitle: Text(l10n.thresholdSubtitle(user.streakThresholdPct)),
          ),
          _ThresholdSlider(
            value: user.streakThresholdPct,
            onChanged: (v) => controller.updateSettings(streakThresholdPct: v),
          ),

          _sectionHeader(context, l10n.settingsNotifications),
          SwitchListTile(
            secondary: const Icon(Icons.notifications_outlined),
            title: Text(l10n.taskReminders),
            subtitle: Text(l10n.taskRemindersSubtitle),
            value: user.notificationsEnabled,
            onChanged: (v) => controller.updateSettings(notificationsEnabled: v),
          ),
          ListTile(
            enabled: user.notificationsEnabled,
            leading: const Icon(Icons.schedule),
            title: Text(l10n.defaultReminderTime),
            subtitle: Text(reminderLeadLabel(l10n, selectedLead)),
            trailing: DropdownButton<int>(
              value: selectedLead,
              underline: const SizedBox.shrink(),
              onChanged: user.notificationsEnabled
                  ? (v) => controller.updateSettings(reminderLeadMinutes: v ?? 0)
                  : null,
              items: [
                for (final minutes in reminderLeadMinutesOptions)
                  DropdownMenuItem(
                      value: minutes, child: Text(reminderLeadLabel(l10n, minutes))),
              ],
            ),
          ),

          _sectionHeader(context, l10n.settingsOrganise),
          ListTile(
            leading: const Icon(Icons.label_outline),
            title: Text(l10n.categories),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/categories'),
          ),
          ListTile(
            leading: const Icon(Icons.repeat),
            title: Text(l10n.recurringTemplates),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/templates'),
          ),

          const Divider(height: 32),
          ListTile(
            leading: Icon(Icons.logout, color: Theme.of(context).colorScheme.error),
            title: Text(l10n.logOut,
                style: TextStyle(color: Theme.of(context).colorScheme.error)),
            onTap: () => controller.logout(),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _sectionHeader(BuildContext context, String title) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
        child: Text(title,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.bold)),
      );
}

/// A slider (50–100%) for the streak "successful day" threshold. Local state so
/// dragging is smooth; commits on release.
class _ThresholdSlider extends StatefulWidget {
  const _ThresholdSlider({required this.value, required this.onChanged});
  final int value;
  final ValueChanged<int> onChanged;

  @override
  State<_ThresholdSlider> createState() => _ThresholdSliderState();
}

class _ThresholdSliderState extends State<_ThresholdSlider> {
  late double _v = widget.value.toDouble();

  @override
  void didUpdateWidget(covariant _ThresholdSlider old) {
    super.didUpdateWidget(old);
    if (old.value != widget.value) _v = widget.value.toDouble();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          Expanded(
            child: Slider(
              value: _v,
              min: 50,
              max: 100,
              divisions: 10,
              label: '${_v.round()}%',
              onChanged: (v) => setState(() => _v = v),
              onChangeEnd: (v) => widget.onChanged(v.round()),
            ),
          ),
          SizedBox(width: 44, child: Text('${_v.round()}%', textAlign: TextAlign.end)),
        ],
      ),
    );
  }
}
