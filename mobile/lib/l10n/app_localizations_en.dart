// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTagline => 'Plan tonight. Win tomorrow.';

  @override
  String get navToday => 'Today';

  @override
  String get navPlan => 'Plan';

  @override
  String get navStats => 'Stats';

  @override
  String get navHistory => 'History';

  @override
  String get navSettings => 'Settings';

  @override
  String get emailLabel => 'Email';

  @override
  String get passwordLabel => 'Password';

  @override
  String get confirmPasswordLabel => 'Confirm password';

  @override
  String get logIn => 'Log in';

  @override
  String get createAccount => 'Create account';

  @override
  String get buildYourStreak => 'Build your streak';

  @override
  String get noAccountSignUp => 'Don\'t have an account? Sign up';

  @override
  String get alreadyHaveAccount => 'I already have an account';

  @override
  String get passwordHelperMinChars => 'At least 8 characters';

  @override
  String get validEmailRequired => 'Enter a valid email';

  @override
  String get passwordRequired => 'Enter your password';

  @override
  String get passwordTooShort => 'Password must be at least 8 characters';

  @override
  String get passwordsDoNotMatch => 'Passwords do not match';

  @override
  String get loginFailed => 'Login failed';

  @override
  String get signUpFailed => 'Sign up failed';

  @override
  String greeting(String name) {
    return 'Hello, $name';
  }

  @override
  String get todaysProgress => 'Today\'s progress';

  @override
  String get keepGoing => 'Keep going!';

  @override
  String get allDone => 'All done. Great work!';

  @override
  String streakDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days',
      one: '$count day',
    );
    return '$_temp0';
  }

  @override
  String tasksPlanned(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tasks planned',
      one: '$count task planned',
      zero: 'Nothing planned yet',
    );
    return '$_temp0';
  }

  @override
  String get daySchedule => 'Day schedule';

  @override
  String get now => 'NOW';

  @override
  String get about => 'About';

  @override
  String get today => 'Today';

  @override
  String get tomorrow => 'Tomorrow';

  @override
  String get yesterday => 'Yesterday';

  @override
  String get anytime => 'Anytime';

  @override
  String get addTask => 'Add task';

  @override
  String get filter => 'Filter';

  @override
  String get all => 'All';

  @override
  String get priority => 'Priority';

  @override
  String get category => 'Category';

  @override
  String get categoryNone => 'None';

  @override
  String get priorityHigh => 'High';

  @override
  String get priorityMedium => 'Medium';

  @override
  String get priorityLow => 'Low';

  @override
  String get nothingPlanned => 'Nothing planned';

  @override
  String get nothingPlannedMessage => 'Tap “Add task” to plan this day.';

  @override
  String get noMatches => 'No matches';

  @override
  String get noMatchesMessage => 'Try clearing your filters.';

  @override
  String progressDone(int done, int total) {
    return '$done of $total done';
  }

  @override
  String get markDone => 'Mark done';

  @override
  String get markNotDone => 'Mark not done';

  @override
  String get taskMoved => 'moved';

  @override
  String get taskSkipped => 'skipped';

  @override
  String get edit => 'Edit';

  @override
  String get skip => 'Skip';

  @override
  String get reschedule => 'Reschedule';

  @override
  String get delete => 'Delete';

  @override
  String get cancel => 'Cancel';

  @override
  String get save => 'Save';

  @override
  String get change => 'Change';

  @override
  String get planTonight => 'Prepare tomorrow, tonight';

  @override
  String get legendGoodDay => 'Good day';

  @override
  String get legendPartial => 'Partial';

  @override
  String get legendEmpty => 'Empty';

  @override
  String get planningFor => 'Planning for';

  @override
  String get generateFromTemplates => 'Generate from templates';

  @override
  String get generatingRecurringTasks => 'Generating recurring tasks…';

  @override
  String get nothingPlannedYet => 'Nothing planned yet';

  @override
  String get planningEmptyMessage =>
      'Add tasks for this day, or generate them from your recurring templates.';

  @override
  String get progressTitle => 'Progress';

  @override
  String get statStreak => 'Streak';

  @override
  String get statThisWeek => 'This week';

  @override
  String get statGoodDays => 'Good days';

  @override
  String bestStreak(int count) {
    return 'best $count';
  }

  @override
  String tasksCompletedRatio(int completed, int total) {
    return '$completed/$total done';
  }

  @override
  String ofActiveDays(int count) {
    return 'of $count active';
  }

  @override
  String get thisWeek => 'This week';

  @override
  String get last30Days => 'Last 30 days';

  @override
  String get completionByDay => 'Completion by day';

  @override
  String metGoal(int pct) {
    return 'Met $pct% goal';
  }

  @override
  String get belowGoal => 'Below goal';

  @override
  String get statsNeedConnection => 'Stats need a connection.';

  @override
  String get nothingOnThisDay => 'Nothing on this day';

  @override
  String get categories => 'Categories';

  @override
  String get newCategory => 'New category';

  @override
  String get editCategory => 'Edit category';

  @override
  String get nameLabel => 'Name';

  @override
  String get noCategoriesYet => 'No categories yet';

  @override
  String get noCategoriesMessage =>
      'Group tasks by area of life — Work, Study, Health…';

  @override
  String get settingsAccount => 'Account';

  @override
  String get settingsAppearance => 'Appearance';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get settingsDiscipline => 'Discipline';

  @override
  String get settingsNotifications => 'Notifications';

  @override
  String get settingsOrganise => 'Organise';

  @override
  String timezoneLabel(String timezone) {
    return 'Timezone: $timezone';
  }

  @override
  String get themeMode => 'Display mode';

  @override
  String get themeSystem => 'System';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get successfulDayThreshold => '“Successful day” threshold';

  @override
  String thresholdSubtitle(int pct) {
    return '$pct% of tasks completed counts as a good day';
  }

  @override
  String get taskReminders => 'Task reminders';

  @override
  String get taskRemindersSubtitle =>
      'Local notifications at each task\'s time';

  @override
  String get defaultReminderTime => 'Default reminder time';

  @override
  String get logOut => 'Log out';

  @override
  String get reminderAtStart => 'At start time';

  @override
  String reminderMinutesBefore(int minutes) {
    return '$minutes minutes before';
  }

  @override
  String get reminderOneHourBefore => '1 hour before';

  @override
  String get newTask => 'New task';

  @override
  String get editTask => 'Edit task';

  @override
  String get titleLabel => 'Title';

  @override
  String get titleRequired => 'Title is required';

  @override
  String get notesOptional => 'Notes (optional)';

  @override
  String get dateLabel => 'Date';

  @override
  String get startTimeLabel => 'Start time';

  @override
  String get durationLabel => 'Duration (minutes, optional)';

  @override
  String get durationLabelShort => 'Duration';

  @override
  String get minutesSuffix => 'min';

  @override
  String get durationMustBePositive => 'Enter a positive number';

  @override
  String get reminderLabel => 'Reminder';

  @override
  String get saveChanges => 'Save changes';

  @override
  String get recurringTemplates => 'Recurring templates';

  @override
  String get newTemplate => 'New template';

  @override
  String get editTemplate => 'Edit template';

  @override
  String get createTemplate => 'Create template';

  @override
  String get noRecurringTasks => 'No recurring tasks';

  @override
  String get noRecurringTasksMessage =>
      'Create templates for habits you repeat, then generate them onto any day from the Plan screen.';

  @override
  String get repeats => 'Repeats';

  @override
  String get everyDay => 'Every day';

  @override
  String get specificDays => 'Specific days';

  @override
  String get pickAtLeastOneDay =>
      'Pick at least one day, or choose “Every day”.';

  @override
  String get pause => 'Pause';

  @override
  String get resume => 'Resume';

  @override
  String get paused => 'paused';

  @override
  String errorWithMessage(String message) {
    return 'Error: $message';
  }

  @override
  String couldNotSave(String message) {
    return 'Could not save: $message';
  }

  @override
  String get somethingWentWrong => 'Something went wrong';

  @override
  String get serverTookTooLong => 'The server took too long to respond.';

  @override
  String get cannotReachServer =>
      'Cannot reach the server. Check your connection.';

  @override
  String get errorEmailTaken => 'An account with this email already exists.';

  @override
  String get errorBadCredentials => 'Invalid email or password.';

  @override
  String get errorSessionExpired =>
      'Your session expired. Please log in again.';

  @override
  String get errorCategoryNotFound => 'That category no longer exists.';

  @override
  String get errorCategoryExists => 'A category with that name already exists.';

  @override
  String get errorValidation =>
      'Some of the details you entered aren\'t valid.';

  @override
  String get errorSameDate => 'The task is already scheduled on that date.';

  @override
  String get errorTooManyAttempts =>
      'Too many attempts. Please try again later.';

  @override
  String get eveningReminderTitle => 'Plan tomorrow';

  @override
  String get eveningReminderBody =>
      'A few minutes tonight sets up a winning day tomorrow.';

  @override
  String get eveningReminderTitle2 => 'Evening planning reminder';

  @override
  String get eveningReminderSubtitle =>
      'A daily nudge to plan tomorrow\'s tasks';

  @override
  String get eveningReminderTimeLabel => 'Reminder time';

  @override
  String get notificationChannelName => 'Task reminders';

  @override
  String get notificationChannelDescription =>
      'Reminders for your scheduled tasks';

  @override
  String notificationScheduledFor(String time) {
    return 'Scheduled for $time';
  }

  @override
  String get weekdayShort1 => 'Mon';

  @override
  String get weekdayShort2 => 'Tue';

  @override
  String get weekdayShort3 => 'Wed';

  @override
  String get weekdayShort4 => 'Thu';

  @override
  String get weekdayShort5 => 'Fri';

  @override
  String get weekdayShort6 => 'Sat';

  @override
  String get weekdayShort7 => 'Sun';

  @override
  String get weekdayLong1 => 'Monday';

  @override
  String get weekdayLong2 => 'Tuesday';

  @override
  String get weekdayLong3 => 'Wednesday';

  @override
  String get weekdayLong4 => 'Thursday';

  @override
  String get weekdayLong5 => 'Friday';

  @override
  String get weekdayLong6 => 'Saturday';

  @override
  String get weekdayLong7 => 'Sunday';

  @override
  String get monthStandalone1 => 'January';

  @override
  String get monthStandalone2 => 'February';

  @override
  String get monthStandalone3 => 'March';

  @override
  String get monthStandalone4 => 'April';

  @override
  String get monthStandalone5 => 'May';

  @override
  String get monthStandalone6 => 'June';

  @override
  String get monthStandalone7 => 'July';

  @override
  String get monthStandalone8 => 'August';

  @override
  String get monthStandalone9 => 'September';

  @override
  String get monthStandalone10 => 'October';

  @override
  String get monthStandalone11 => 'November';

  @override
  String get monthStandalone12 => 'December';

  @override
  String get monthInDate1 => 'January';

  @override
  String get monthInDate2 => 'February';

  @override
  String get monthInDate3 => 'March';

  @override
  String get monthInDate4 => 'April';

  @override
  String get monthInDate5 => 'May';

  @override
  String get monthInDate6 => 'June';

  @override
  String get monthInDate7 => 'July';

  @override
  String get monthInDate8 => 'August';

  @override
  String get monthInDate9 => 'September';

  @override
  String get monthInDate10 => 'October';

  @override
  String get monthInDate11 => 'November';

  @override
  String get monthInDate12 => 'December';

  @override
  String dateLong(String weekday, int day, String month, int year) {
    return '$weekday, $day $month $year';
  }

  @override
  String dateShort(String weekday, int day, String month) {
    return '$weekday, $day $month';
  }

  @override
  String monthAndYear(String month, int year) {
    return '$month $year';
  }

  @override
  String dateRange(String from, String to) {
    return '$from – $to';
  }
}
