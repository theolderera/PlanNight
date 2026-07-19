import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/l10n.dart';
import '../../core/providers.dart';
import '../../core/reminder_options.dart';
import '../../core/theme.dart';
import '../../core/widgets/app_widgets.dart';
import '../../data/repositories/category_repository.dart';
import '../../data/repositories/recurring_repository.dart';
import '../../data/repositories/task_repository.dart';
import '../auth/auth_controller.dart';

/// Settings: profile, appearance (theme, language, discipline threshold),
/// notifications (task + evening reminders), organisation links, and sign out.
/// Changes apply immediately and sync in the background (queued offline).
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final c = context.colors;
    final theme = Theme.of(context);
    final user = ref.watch(authControllerProvider).value;
    final controller = ref.read(authControllerProvider.notifier);
    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final selectedLead = reminderLeadMinutesOptions.contains(user.reminderLeadMinutes)
        ? user.reminderLeadMinutes
        : 0;

    // Display name + initial from the email local-part.
    final local = user.email.contains('@') ? user.email.split('@').first : user.email;
    final cleaned = local.replaceAll(RegExp(r'[._\-]+'), ' ').trim();
    final name = cleaned.isEmpty ? user.email : cleaned[0].toUpperCase() + cleaned.substring(1);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
          children: [
            Text(l10n.navSettings, style: theme.textTheme.displaySmall),
            const SizedBox(height: 18),

            // Profile card.
            SurfaceCard(
              child: Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(color: c.navy, borderRadius: BorderRadius.circular(16)),
                    alignment: Alignment.center,
                    child: Text(name[0].toUpperCase(),
                        style: TextStyle(fontFamily: AppFonts.mono, fontSize: 20, fontWeight: FontWeight.w700, color: c.onNavy)),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontFamily: AppFonts.sans, fontSize: 16, fontWeight: FontWeight.w700, color: c.ink)),
                        const SizedBox(height: 2),
                        Text(user.email,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontFamily: AppFonts.sans, fontSize: 12.5, fontWeight: FontWeight.w500, color: c.textMuted)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),

            SectionLabel(l10n.settingsAppearance),
            SurfaceCard(
              radius: 18,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.themeMode,
                      style: TextStyle(fontFamily: AppFonts.sans, fontSize: 13, fontWeight: FontWeight.w600, color: c.ink)),
                  const SizedBox(height: 11),
                  PillSegment(
                    options: [l10n.themeSystem, l10n.themeLight, l10n.themeDark],
                    selected: switch (user.theme) { 'light' => 1, 'dark' => 2, _ => 0 },
                    onSelect: (i) => controller.updateSettings(
                        theme: switch (i) { 1 => 'light', 2 => 'dark', _ => 'system' }),
                  ),
                  const SizedBox(height: 6),
                  const _RowDivider(),
                  _NavRow(
                    label: l10n.settingsLanguage,
                    trailing: _ValueChip(text: AppLocale.fromCode(user.language).nativeName),
                    onTap: () => _pickLanguage(context, ref, user.language),
                  ),
                  const _RowDivider(),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(l10n.successfulDayThreshold,
                                  style: TextStyle(fontFamily: AppFonts.sans, fontSize: 13, fontWeight: FontWeight.w600, color: c.ink)),
                            ),
                            Text('${user.streakThresholdPct}%', style: context.mono(size: 13, color: c.accent)),
                          ],
                        ),
                        _ThresholdSlider(
                          value: user.streakThresholdPct,
                          onChanged: (v) => controller.updateSettings(streakThresholdPct: v),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),

            SectionLabel(l10n.settingsNotifications),
            SurfaceCard(
              radius: 18,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  _ToggleRow(
                    icon: Icons.notifications_outlined,
                    label: l10n.taskReminders,
                    value: user.notificationsEnabled,
                    onChanged: (v) => controller.updateSettings(notificationsEnabled: v),
                  ),
                  const _RowDivider(),
                  _NavRow(
                    icon: Icons.schedule_rounded,
                    label: l10n.defaultReminderTime,
                    enabled: user.notificationsEnabled,
                    trailing: _ValueChip(text: reminderLeadLabel(l10n, selectedLead)),
                    onTap: user.notificationsEnabled
                        ? () => _pickReminder(context, ref, selectedLead)
                        : null,
                  ),
                  const _RowDivider(),
                  _ToggleRow(
                    icon: Icons.nightlight_outlined,
                    label: l10n.eveningReminderTitle2,
                    value: user.eveningReminderEnabled,
                    onChanged: user.notificationsEnabled
                        ? (v) => controller.updateSettings(eveningReminderEnabled: v)
                        : null,
                  ),
                  const _RowDivider(),
                  _NavRow(
                    icon: Icons.bedtime_outlined,
                    label: l10n.eveningReminderTimeLabel,
                    enabled: user.notificationsEnabled && user.eveningReminderEnabled,
                    trailing: _ValueChip(text: _formatHHmm(context, user.eveningReminderTime)),
                    onTap: user.notificationsEnabled && user.eveningReminderEnabled
                        ? () => _pickEveningTime(context, ref, user.eveningReminderTime)
                        : null,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),

            SectionLabel(l10n.settingsOrganise),
            SurfaceCard(
              radius: 18,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  _NavRow(
                    icon: Icons.label_outline_rounded,
                    label: l10n.categories,
                    trailing: Icon(Icons.chevron_right_rounded, color: c.textFaint),
                    onTap: () => context.push('/categories'),
                  ),
                  const _RowDivider(),
                  _NavRow(
                    icon: Icons.repeat_rounded,
                    label: l10n.recurringTemplates,
                    trailing: Icon(Icons.chevron_right_rounded, color: c.textFaint),
                    onTap: () => context.push('/templates'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),

            SectionLabel(l10n.settingsData),
            SurfaceCard(
              radius: 18,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _NavRow(
                icon: Icons.cloud_sync_outlined,
                label: l10n.resyncData,
                subtitle: l10n.resyncDataHint,
                trailing: Icon(Icons.chevron_right_rounded, color: c.textFaint),
                onTap: () => _repairSync(context, ref),
              ),
            ),
            const SizedBox(height: 24),

            // Sign out.
            GestureDetector(
              onTap: () => controller.logout(),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 15),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: c.dangerBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: c.dangerBorder, width: 1.5),
                ),
                child: Text(l10n.logOut,
                    style: TextStyle(fontFamily: AppFonts.sans, fontSize: 14, fontWeight: FontWeight.w700, color: c.danger)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Re-queue every locally-cached row and push it to the server. Recovers rows
  /// that never synced (e.g. writes dropped by an earlier bug). Idempotent:
  /// already-synced rows 409 and change nothing. Categories go first so tasks/
  /// templates that reference them land after their category exists.
  Future<void> _repairSync(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(SnackBar(content: Text(l10n.resyncInProgress)));

    await ref.read(categoryRepositoryProvider).resyncAll();
    await ref.read(recurringRepositoryProvider).resyncAll();
    await ref.read(taskRepositoryProvider).resyncAll();
    await ref.read(syncEngineProvider).syncNow();

    final pending = await ref.read(databaseProvider).pendingOutbox();
    if (!context.mounted) return;
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(SnackBar(
      content: Text(pending.isEmpty ? l10n.resyncDone : l10n.resyncPending(pending.length)),
    ));
  }

  String _formatHHmm(BuildContext context, String hhmm) {
    final parts = hhmm.split(':');
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts.length > 1 ? parts[1] : '');
    if (h == null || m == null) return hhmm;
    return TimeOfDay(hour: h, minute: m).format(context);
  }

  Future<void> _pickLanguage(BuildContext context, WidgetRef ref, String current) async {
    final picked = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final locale in AppLocale.values)
              ListTile(
                title: Text(locale.nativeName,
                    style: TextStyle(
                        fontFamily: AppFonts.sans,
                        fontWeight: locale.code == current ? FontWeight.w700 : FontWeight.w500,
                        color: locale.code == current ? context.colors.accent : context.colors.ink)),
                trailing: locale.code == current ? Icon(Icons.check_rounded, color: context.colors.accent) : null,
                onTap: () => Navigator.pop(ctx, locale.code),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (picked != null) ref.read(authControllerProvider.notifier).updateSettings(language: picked);
  }

  Future<void> _pickReminder(BuildContext context, WidgetRef ref, int current) async {
    final l10n = context.l10n;
    final picked = await showModalBottomSheet<int>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final m in reminderLeadMinutesOptions)
              ListTile(
                title: Text(reminderLeadLabel(l10n, m),
                    style: TextStyle(
                        fontFamily: AppFonts.sans,
                        fontWeight: m == current ? FontWeight.w700 : FontWeight.w500,
                        color: m == current ? context.colors.accent : context.colors.ink)),
                trailing: m == current ? Icon(Icons.check_rounded, color: context.colors.accent) : null,
                onTap: () => Navigator.pop(ctx, m),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (picked != null) ref.read(authControllerProvider.notifier).updateSettings(reminderLeadMinutes: picked);
  }

  Future<void> _pickEveningTime(BuildContext context, WidgetRef ref, String current) async {
    final parts = current.split(':');
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: int.tryParse(parts[0]) ?? 21,
        minute: int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0,
      ),
    );
    if (picked != null) {
      final hhmm = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      ref.read(authControllerProvider.notifier).updateSettings(eveningReminderTime: hhmm);
    }
  }
}

class _RowDivider extends StatelessWidget {
  const _RowDivider();
  @override
  Widget build(BuildContext context) => Divider(height: 1, thickness: 1, color: context.colors.divider);
}

class _ToggleRow extends StatelessWidget {
  const _ToggleRow({required this.icon, required this.label, required this.value, required this.onChanged});
  final IconData icon;
  final String label;
  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final enabled = onChanged != null;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: enabled ? c.accent : c.textFaint),
          const SizedBox(width: 12),
          Expanded(
            child: Text(label,
                style: TextStyle(
                    fontFamily: AppFonts.sans, fontSize: 13.5, fontWeight: FontWeight.w600,
                    color: enabled ? c.ink : c.textFaint)),
          ),
          Switch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}

class _NavRow extends StatelessWidget {
  const _NavRow(
      {this.icon, required this.label, this.subtitle, this.trailing, this.onTap, this.enabled = true});
  final IconData? icon;
  final String label;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return InkWell(
      onTap: enabled ? onTap : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 13),
        child: Row(
          children: [
            if (icon != null) ...[
              Icon(icon, size: 20, color: enabled ? c.accent : c.textFaint),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: TextStyle(
                          fontFamily: AppFonts.sans, fontSize: 13.5, fontWeight: FontWeight.w600,
                          color: enabled ? c.ink : c.textFaint)),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(subtitle!,
                        style: TextStyle(
                            fontFamily: AppFonts.sans, fontSize: 11.5, fontWeight: FontWeight.w500,
                            color: c.textMuted)),
                  ],
                ],
              ),
            ),
            ?trailing,
          ],
        ),
      ),
    );
  }
}

class _ValueChip extends StatelessWidget {
  const _ValueChip({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(color: c.surfaceAlt, borderRadius: BorderRadius.circular(10)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(text, style: TextStyle(fontFamily: AppFonts.sans, fontSize: 12.5, fontWeight: FontWeight.w600, color: c.ink)),
          const SizedBox(width: 5),
          Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: c.textMuted),
        ],
      ),
    );
  }
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
    return SliderTheme(
      data: SliderTheme.of(context).copyWith(
        trackHeight: 6,
        overlayShape: SliderComponentShape.noOverlay,
      ),
      child: Slider(
        value: _v,
        min: 50,
        max: 100,
        divisions: 10,
        label: '${_v.round()}%',
        onChanged: (v) => setState(() => _v = v),
        onChangeEnd: (v) => widget.onChanged(v.round()),
      ),
    );
  }
}
