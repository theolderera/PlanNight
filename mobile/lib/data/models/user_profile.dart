/// The authenticated user's profile & settings, mirroring `GET /users/me`.
class UserProfile {
  const UserProfile({
    required this.id,
    required this.email,
    required this.timezone,
    required this.language,
    required this.theme,
    required this.streakThresholdPct,
    required this.notificationsEnabled,
    required this.reminderLeadMinutes,
    required this.eveningReminderEnabled,
    required this.eveningReminderTime,
  });

  final String id;
  final String email;
  final String timezone;

  /// UI language code: 'en' | 'ru' | 'tg'. Stored server-side so the choice
  /// follows the account to another device. See `AppLocale` in core/l10n.dart.
  final String language;

  /// 'light' | 'dark' | 'system'
  final String theme;
  final int streakThresholdPct;
  final bool notificationsEnabled;
  final int reminderLeadMinutes;

  /// The daily "plan tomorrow" nudge: on/off and its 'HH:MM' wall-clock time.
  final bool eveningReminderEnabled;
  final String eveningReminderTime;

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
        id: json['id'] as String,
        email: json['email'] as String,
        timezone: json['timezone'] as String? ?? 'UTC',
        language: json['language'] as String? ?? 'en',
        theme: json['theme'] as String? ?? 'system',
        streakThresholdPct: (json['streakThresholdPct'] as num?)?.toInt() ?? 80,
        notificationsEnabled: json['notificationsEnabled'] as bool? ?? true,
        reminderLeadMinutes: (json['reminderLeadMinutes'] as num?)?.toInt() ?? 0,
        eveningReminderEnabled: json['eveningReminderEnabled'] as bool? ?? true,
        eveningReminderTime: json['eveningReminderTime'] as String? ?? '21:00',
      );

  UserProfile copyWith({
    String? timezone,
    String? language,
    String? theme,
    int? streakThresholdPct,
    bool? notificationsEnabled,
    int? reminderLeadMinutes,
    bool? eveningReminderEnabled,
    String? eveningReminderTime,
  }) =>
      UserProfile(
        id: id,
        email: email,
        timezone: timezone ?? this.timezone,
        language: language ?? this.language,
        theme: theme ?? this.theme,
        streakThresholdPct: streakThresholdPct ?? this.streakThresholdPct,
        notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
        reminderLeadMinutes: reminderLeadMinutes ?? this.reminderLeadMinutes,
        eveningReminderEnabled:
            eveningReminderEnabled ?? this.eveningReminderEnabled,
        eveningReminderTime: eveningReminderTime ?? this.eveningReminderTime,
      );
}
