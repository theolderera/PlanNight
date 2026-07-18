import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ru.dart';
import 'app_localizations_tg.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ru'),
    Locale('tg'),
  ];

  /// Subtitle under the app name on the login screen.
  ///
  /// In en, this message translates to:
  /// **'Plan tonight. Win tomorrow.'**
  String get appTagline;

  /// Bottom navigation tab: the current day's tasks.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get navToday;

  /// Bottom navigation tab: plan an upcoming day.
  ///
  /// In en, this message translates to:
  /// **'Plan'**
  String get navPlan;

  /// Bottom navigation tab: progress charts.
  ///
  /// In en, this message translates to:
  /// **'Stats'**
  String get navStats;

  /// Bottom navigation tab: calendar of past days.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get navHistory;

  /// Bottom navigation tab: preferences.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get navSettings;

  /// No description provided for @emailLabel.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get emailLabel;

  /// No description provided for @passwordLabel.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get passwordLabel;

  /// No description provided for @confirmPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Confirm password'**
  String get confirmPasswordLabel;

  /// No description provided for @logIn.
  ///
  /// In en, this message translates to:
  /// **'Log in'**
  String get logIn;

  /// No description provided for @createAccount.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get createAccount;

  /// Heading on the sign-up screen.
  ///
  /// In en, this message translates to:
  /// **'Build your streak'**
  String get buildYourStreak;

  /// No description provided for @noAccountSignUp.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account? Sign up'**
  String get noAccountSignUp;

  /// No description provided for @alreadyHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'I already have an account'**
  String get alreadyHaveAccount;

  /// No description provided for @passwordHelperMinChars.
  ///
  /// In en, this message translates to:
  /// **'At least 8 characters'**
  String get passwordHelperMinChars;

  /// No description provided for @validEmailRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email'**
  String get validEmailRequired;

  /// No description provided for @passwordRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter your password'**
  String get passwordRequired;

  /// No description provided for @passwordTooShort.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 8 characters'**
  String get passwordTooShort;

  /// No description provided for @passwordsDoNotMatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get passwordsDoNotMatch;

  /// No description provided for @loginFailed.
  ///
  /// In en, this message translates to:
  /// **'Login failed'**
  String get loginFailed;

  /// No description provided for @signUpFailed.
  ///
  /// In en, this message translates to:
  /// **'Sign up failed'**
  String get signUpFailed;

  /// Personal greeting on the Today header.
  ///
  /// In en, this message translates to:
  /// **'Hello, {name}'**
  String greeting(String name);

  /// Title of the progress hero card on Today.
  ///
  /// In en, this message translates to:
  /// **'Today\'s progress'**
  String get todaysProgress;

  /// Encouraging tail shown when the day is not yet complete.
  ///
  /// In en, this message translates to:
  /// **'Keep going!'**
  String get keepGoing;

  /// Shown in the progress hero when every task is complete.
  ///
  /// In en, this message translates to:
  /// **'All done. Great work!'**
  String get allDone;

  /// Streak length as a short chip label.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} day} other{{count} days}}'**
  String streakDays(int count);

  /// Summary of how many tasks a planned day holds.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{Nothing planned yet} one{{count} task planned} other{{count} tasks planned}}'**
  String tasksPlanned(int count);

  /// Heading above the Today task list.
  ///
  /// In en, this message translates to:
  /// **'Day schedule'**
  String get daySchedule;

  /// Tag on the task whose time is happening now.
  ///
  /// In en, this message translates to:
  /// **'NOW'**
  String get now;

  /// Settings row opening app info.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @tomorrow.
  ///
  /// In en, this message translates to:
  /// **'Tomorrow'**
  String get tomorrow;

  /// No description provided for @yesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get yesterday;

  /// Shown instead of a clock time for a task with no start time.
  ///
  /// In en, this message translates to:
  /// **'Anytime'**
  String get anytime;

  /// No description provided for @addTask.
  ///
  /// In en, this message translates to:
  /// **'Add task'**
  String get addTask;

  /// No description provided for @filter.
  ///
  /// In en, this message translates to:
  /// **'Filter'**
  String get filter;

  /// No description provided for @all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get all;

  /// No description provided for @priority.
  ///
  /// In en, this message translates to:
  /// **'Priority'**
  String get priority;

  /// No description provided for @category.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get category;

  /// Dropdown option meaning the task has no category.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get categoryNone;

  /// No description provided for @priorityHigh.
  ///
  /// In en, this message translates to:
  /// **'High'**
  String get priorityHigh;

  /// No description provided for @priorityMedium.
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get priorityMedium;

  /// No description provided for @priorityLow.
  ///
  /// In en, this message translates to:
  /// **'Low'**
  String get priorityLow;

  /// No description provided for @nothingPlanned.
  ///
  /// In en, this message translates to:
  /// **'Nothing planned'**
  String get nothingPlanned;

  /// No description provided for @nothingPlannedMessage.
  ///
  /// In en, this message translates to:
  /// **'Tap “Add task” to plan this day.'**
  String get nothingPlannedMessage;

  /// No description provided for @noMatches.
  ///
  /// In en, this message translates to:
  /// **'No matches'**
  String get noMatches;

  /// No description provided for @noMatchesMessage.
  ///
  /// In en, this message translates to:
  /// **'Try clearing your filters.'**
  String get noMatchesMessage;

  /// Daily completion summary above the task list.
  ///
  /// In en, this message translates to:
  /// **'{done} of {total} done'**
  String progressDone(int done, int total);

  /// No description provided for @markDone.
  ///
  /// In en, this message translates to:
  /// **'Mark done'**
  String get markDone;

  /// No description provided for @markNotDone.
  ///
  /// In en, this message translates to:
  /// **'Mark not done'**
  String get markNotDone;

  /// Suffix on a task that was rescheduled to another day.
  ///
  /// In en, this message translates to:
  /// **'moved'**
  String get taskMoved;

  /// Suffix on a task the user chose to skip.
  ///
  /// In en, this message translates to:
  /// **'skipped'**
  String get taskSkipped;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @skip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get skip;

  /// No description provided for @reschedule.
  ///
  /// In en, this message translates to:
  /// **'Reschedule'**
  String get reschedule;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @change.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get change;

  /// Subtitle on the Plan screen.
  ///
  /// In en, this message translates to:
  /// **'Prepare tomorrow, tonight'**
  String get planTonight;

  /// History calendar legend: a day that met the goal.
  ///
  /// In en, this message translates to:
  /// **'Good day'**
  String get legendGoodDay;

  /// No description provided for @legendPartial.
  ///
  /// In en, this message translates to:
  /// **'Partial'**
  String get legendPartial;

  /// No description provided for @legendEmpty.
  ///
  /// In en, this message translates to:
  /// **'Empty'**
  String get legendEmpty;

  /// No description provided for @planningFor.
  ///
  /// In en, this message translates to:
  /// **'Planning for'**
  String get planningFor;

  /// No description provided for @generateFromTemplates.
  ///
  /// In en, this message translates to:
  /// **'Generate from templates'**
  String get generateFromTemplates;

  /// No description provided for @generatingRecurringTasks.
  ///
  /// In en, this message translates to:
  /// **'Generating recurring tasks…'**
  String get generatingRecurringTasks;

  /// No description provided for @nothingPlannedYet.
  ///
  /// In en, this message translates to:
  /// **'Nothing planned yet'**
  String get nothingPlannedYet;

  /// No description provided for @planningEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'Add tasks for this day, or generate them from your recurring templates.'**
  String get planningEmptyMessage;

  /// App bar title of the statistics screen.
  ///
  /// In en, this message translates to:
  /// **'Progress'**
  String get progressTitle;

  /// No description provided for @statStreak.
  ///
  /// In en, this message translates to:
  /// **'Streak'**
  String get statStreak;

  /// No description provided for @statThisWeek.
  ///
  /// In en, this message translates to:
  /// **'This week'**
  String get statThisWeek;

  /// No description provided for @statGoodDays.
  ///
  /// In en, this message translates to:
  /// **'Good days'**
  String get statGoodDays;

  /// Longest streak, shown under the current streak.
  ///
  /// In en, this message translates to:
  /// **'best {count}'**
  String bestStreak(int count);

  /// No description provided for @tasksCompletedRatio.
  ///
  /// In en, this message translates to:
  /// **'{completed}/{total} done'**
  String tasksCompletedRatio(int completed, int total);

  /// Sub-label: successful days out of the days that had tasks.
  ///
  /// In en, this message translates to:
  /// **'of {count} active'**
  String ofActiveDays(int count);

  /// Button that jumps the chart back to the current week.
  ///
  /// In en, this message translates to:
  /// **'This week'**
  String get thisWeek;

  /// No description provided for @last30Days.
  ///
  /// In en, this message translates to:
  /// **'Last 30 days'**
  String get last30Days;

  /// No description provided for @completionByDay.
  ///
  /// In en, this message translates to:
  /// **'Completion by day'**
  String get completionByDay;

  /// Chart legend for days that reached the user's threshold.
  ///
  /// In en, this message translates to:
  /// **'Met {pct}% goal'**
  String metGoal(int pct);

  /// No description provided for @belowGoal.
  ///
  /// In en, this message translates to:
  /// **'Below goal'**
  String get belowGoal;

  /// No description provided for @statsNeedConnection.
  ///
  /// In en, this message translates to:
  /// **'Stats need a connection.'**
  String get statsNeedConnection;

  /// No description provided for @nothingOnThisDay.
  ///
  /// In en, this message translates to:
  /// **'Nothing on this day'**
  String get nothingOnThisDay;

  /// No description provided for @categories.
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get categories;

  /// No description provided for @newCategory.
  ///
  /// In en, this message translates to:
  /// **'New category'**
  String get newCategory;

  /// No description provided for @editCategory.
  ///
  /// In en, this message translates to:
  /// **'Edit category'**
  String get editCategory;

  /// No description provided for @nameLabel.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get nameLabel;

  /// No description provided for @noCategoriesYet.
  ///
  /// In en, this message translates to:
  /// **'No categories yet'**
  String get noCategoriesYet;

  /// No description provided for @noCategoriesMessage.
  ///
  /// In en, this message translates to:
  /// **'Group tasks by area of life — Work, Study, Health…'**
  String get noCategoriesMessage;

  /// No description provided for @settingsAccount.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get settingsAccount;

  /// No description provided for @settingsAppearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get settingsAppearance;

  /// No description provided for @settingsLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsLanguage;

  /// No description provided for @settingsDiscipline.
  ///
  /// In en, this message translates to:
  /// **'Discipline'**
  String get settingsDiscipline;

  /// No description provided for @settingsNotifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get settingsNotifications;

  /// No description provided for @settingsOrganise.
  ///
  /// In en, this message translates to:
  /// **'Organise'**
  String get settingsOrganise;

  /// No description provided for @timezoneLabel.
  ///
  /// In en, this message translates to:
  /// **'Timezone: {timezone}'**
  String timezoneLabel(String timezone);

  /// Label above the theme (system/light/dark) selector.
  ///
  /// In en, this message translates to:
  /// **'Display mode'**
  String get themeMode;

  /// No description provided for @themeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get themeSystem;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// No description provided for @successfulDayThreshold.
  ///
  /// In en, this message translates to:
  /// **'“Successful day” threshold'**
  String get successfulDayThreshold;

  /// No description provided for @thresholdSubtitle.
  ///
  /// In en, this message translates to:
  /// **'{pct}% of tasks completed counts as a good day'**
  String thresholdSubtitle(int pct);

  /// No description provided for @taskReminders.
  ///
  /// In en, this message translates to:
  /// **'Task reminders'**
  String get taskReminders;

  /// No description provided for @taskRemindersSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Local notifications at each task\'s time'**
  String get taskRemindersSubtitle;

  /// No description provided for @defaultReminderTime.
  ///
  /// In en, this message translates to:
  /// **'Default reminder time'**
  String get defaultReminderTime;

  /// No description provided for @logOut.
  ///
  /// In en, this message translates to:
  /// **'Log out'**
  String get logOut;

  /// No description provided for @reminderAtStart.
  ///
  /// In en, this message translates to:
  /// **'At start time'**
  String get reminderAtStart;

  /// No description provided for @reminderMinutesBefore.
  ///
  /// In en, this message translates to:
  /// **'{minutes} minutes before'**
  String reminderMinutesBefore(int minutes);

  /// No description provided for @reminderOneHourBefore.
  ///
  /// In en, this message translates to:
  /// **'1 hour before'**
  String get reminderOneHourBefore;

  /// No description provided for @newTask.
  ///
  /// In en, this message translates to:
  /// **'New task'**
  String get newTask;

  /// No description provided for @editTask.
  ///
  /// In en, this message translates to:
  /// **'Edit task'**
  String get editTask;

  /// No description provided for @titleLabel.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get titleLabel;

  /// No description provided for @titleRequired.
  ///
  /// In en, this message translates to:
  /// **'Title is required'**
  String get titleRequired;

  /// No description provided for @notesOptional.
  ///
  /// In en, this message translates to:
  /// **'Notes (optional)'**
  String get notesOptional;

  /// No description provided for @dateLabel.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get dateLabel;

  /// No description provided for @startTimeLabel.
  ///
  /// In en, this message translates to:
  /// **'Start time'**
  String get startTimeLabel;

  /// No description provided for @durationLabel.
  ///
  /// In en, this message translates to:
  /// **'Duration (minutes, optional)'**
  String get durationLabel;

  /// Short duration field caption in the compact time/duration row.
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get durationLabelShort;

  /// Abbreviated minutes unit shown as an input suffix.
  ///
  /// In en, this message translates to:
  /// **'min'**
  String get minutesSuffix;

  /// No description provided for @durationMustBePositive.
  ///
  /// In en, this message translates to:
  /// **'Enter a positive number'**
  String get durationMustBePositive;

  /// No description provided for @reminderLabel.
  ///
  /// In en, this message translates to:
  /// **'Reminder'**
  String get reminderLabel;

  /// No description provided for @saveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save changes'**
  String get saveChanges;

  /// No description provided for @recurringTemplates.
  ///
  /// In en, this message translates to:
  /// **'Recurring templates'**
  String get recurringTemplates;

  /// No description provided for @newTemplate.
  ///
  /// In en, this message translates to:
  /// **'New template'**
  String get newTemplate;

  /// No description provided for @editTemplate.
  ///
  /// In en, this message translates to:
  /// **'Edit template'**
  String get editTemplate;

  /// No description provided for @createTemplate.
  ///
  /// In en, this message translates to:
  /// **'Create template'**
  String get createTemplate;

  /// No description provided for @noRecurringTasks.
  ///
  /// In en, this message translates to:
  /// **'No recurring tasks'**
  String get noRecurringTasks;

  /// No description provided for @noRecurringTasksMessage.
  ///
  /// In en, this message translates to:
  /// **'Create templates for habits you repeat, then generate them onto any day from the Plan screen.'**
  String get noRecurringTasksMessage;

  /// No description provided for @repeats.
  ///
  /// In en, this message translates to:
  /// **'Repeats'**
  String get repeats;

  /// No description provided for @everyDay.
  ///
  /// In en, this message translates to:
  /// **'Every day'**
  String get everyDay;

  /// No description provided for @specificDays.
  ///
  /// In en, this message translates to:
  /// **'Specific days'**
  String get specificDays;

  /// No description provided for @pickAtLeastOneDay.
  ///
  /// In en, this message translates to:
  /// **'Pick at least one day, or choose “Every day”.'**
  String get pickAtLeastOneDay;

  /// No description provided for @pause.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get pause;

  /// No description provided for @resume.
  ///
  /// In en, this message translates to:
  /// **'Resume'**
  String get resume;

  /// Suffix on a template whose generation is turned off.
  ///
  /// In en, this message translates to:
  /// **'paused'**
  String get paused;

  /// No description provided for @errorWithMessage.
  ///
  /// In en, this message translates to:
  /// **'Error: {message}'**
  String errorWithMessage(String message);

  /// No description provided for @couldNotSave.
  ///
  /// In en, this message translates to:
  /// **'Could not save: {message}'**
  String couldNotSave(String message);

  /// No description provided for @somethingWentWrong.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get somethingWentWrong;

  /// No description provided for @serverTookTooLong.
  ///
  /// In en, this message translates to:
  /// **'The server took too long to respond.'**
  String get serverTookTooLong;

  /// No description provided for @cannotReachServer.
  ///
  /// In en, this message translates to:
  /// **'Cannot reach the server. Check your connection.'**
  String get cannotReachServer;

  /// No description provided for @errorEmailTaken.
  ///
  /// In en, this message translates to:
  /// **'An account with this email already exists.'**
  String get errorEmailTaken;

  /// No description provided for @errorBadCredentials.
  ///
  /// In en, this message translates to:
  /// **'Invalid email or password.'**
  String get errorBadCredentials;

  /// No description provided for @errorSessionExpired.
  ///
  /// In en, this message translates to:
  /// **'Your session expired. Please log in again.'**
  String get errorSessionExpired;

  /// No description provided for @errorCategoryNotFound.
  ///
  /// In en, this message translates to:
  /// **'That category no longer exists.'**
  String get errorCategoryNotFound;

  /// No description provided for @errorCategoryExists.
  ///
  /// In en, this message translates to:
  /// **'A category with that name already exists.'**
  String get errorCategoryExists;

  /// No description provided for @errorValidation.
  ///
  /// In en, this message translates to:
  /// **'Some of the details you entered aren\'t valid.'**
  String get errorValidation;

  /// No description provided for @errorSameDate.
  ///
  /// In en, this message translates to:
  /// **'The task is already scheduled on that date.'**
  String get errorSameDate;

  /// No description provided for @errorTooManyAttempts.
  ///
  /// In en, this message translates to:
  /// **'Too many attempts. Please try again later.'**
  String get errorTooManyAttempts;

  /// Title of the daily evening notification nudging the user to plan the next day.
  ///
  /// In en, this message translates to:
  /// **'Plan tomorrow'**
  String get eveningReminderTitle;

  /// No description provided for @eveningReminderBody.
  ///
  /// In en, this message translates to:
  /// **'A few minutes tonight sets up a winning day tomorrow.'**
  String get eveningReminderBody;

  /// Settings switch label for the daily evening nudge.
  ///
  /// In en, this message translates to:
  /// **'Evening planning reminder'**
  String get eveningReminderTitle2;

  /// No description provided for @eveningReminderSubtitle.
  ///
  /// In en, this message translates to:
  /// **'A daily nudge to plan tomorrow\'s tasks'**
  String get eveningReminderSubtitle;

  /// No description provided for @eveningReminderTimeLabel.
  ///
  /// In en, this message translates to:
  /// **'Reminder time'**
  String get eveningReminderTimeLabel;

  /// No description provided for @notificationChannelName.
  ///
  /// In en, this message translates to:
  /// **'Task reminders'**
  String get notificationChannelName;

  /// No description provided for @notificationChannelDescription.
  ///
  /// In en, this message translates to:
  /// **'Reminders for your scheduled tasks'**
  String get notificationChannelDescription;

  /// No description provided for @notificationScheduledFor.
  ///
  /// In en, this message translates to:
  /// **'Scheduled for {time}'**
  String notificationScheduledFor(String time);

  /// Abbreviated Monday. 1..7 = Monday..Sunday, matching DateTime.weekday.
  ///
  /// In en, this message translates to:
  /// **'Mon'**
  String get weekdayShort1;

  /// No description provided for @weekdayShort2.
  ///
  /// In en, this message translates to:
  /// **'Tue'**
  String get weekdayShort2;

  /// No description provided for @weekdayShort3.
  ///
  /// In en, this message translates to:
  /// **'Wed'**
  String get weekdayShort3;

  /// No description provided for @weekdayShort4.
  ///
  /// In en, this message translates to:
  /// **'Thu'**
  String get weekdayShort4;

  /// No description provided for @weekdayShort5.
  ///
  /// In en, this message translates to:
  /// **'Fri'**
  String get weekdayShort5;

  /// No description provided for @weekdayShort6.
  ///
  /// In en, this message translates to:
  /// **'Sat'**
  String get weekdayShort6;

  /// No description provided for @weekdayShort7.
  ///
  /// In en, this message translates to:
  /// **'Sun'**
  String get weekdayShort7;

  /// No description provided for @weekdayLong1.
  ///
  /// In en, this message translates to:
  /// **'Monday'**
  String get weekdayLong1;

  /// No description provided for @weekdayLong2.
  ///
  /// In en, this message translates to:
  /// **'Tuesday'**
  String get weekdayLong2;

  /// No description provided for @weekdayLong3.
  ///
  /// In en, this message translates to:
  /// **'Wednesday'**
  String get weekdayLong3;

  /// No description provided for @weekdayLong4.
  ///
  /// In en, this message translates to:
  /// **'Thursday'**
  String get weekdayLong4;

  /// No description provided for @weekdayLong5.
  ///
  /// In en, this message translates to:
  /// **'Friday'**
  String get weekdayLong5;

  /// No description provided for @weekdayLong6.
  ///
  /// In en, this message translates to:
  /// **'Saturday'**
  String get weekdayLong6;

  /// No description provided for @weekdayLong7.
  ///
  /// In en, this message translates to:
  /// **'Sunday'**
  String get weekdayLong7;

  /// Month name on its own, e.g. a calendar header “January 2026”.
  ///
  /// In en, this message translates to:
  /// **'January'**
  String get monthStandalone1;

  /// No description provided for @monthStandalone2.
  ///
  /// In en, this message translates to:
  /// **'February'**
  String get monthStandalone2;

  /// No description provided for @monthStandalone3.
  ///
  /// In en, this message translates to:
  /// **'March'**
  String get monthStandalone3;

  /// No description provided for @monthStandalone4.
  ///
  /// In en, this message translates to:
  /// **'April'**
  String get monthStandalone4;

  /// No description provided for @monthStandalone5.
  ///
  /// In en, this message translates to:
  /// **'May'**
  String get monthStandalone5;

  /// No description provided for @monthStandalone6.
  ///
  /// In en, this message translates to:
  /// **'June'**
  String get monthStandalone6;

  /// No description provided for @monthStandalone7.
  ///
  /// In en, this message translates to:
  /// **'July'**
  String get monthStandalone7;

  /// No description provided for @monthStandalone8.
  ///
  /// In en, this message translates to:
  /// **'August'**
  String get monthStandalone8;

  /// No description provided for @monthStandalone9.
  ///
  /// In en, this message translates to:
  /// **'September'**
  String get monthStandalone9;

  /// No description provided for @monthStandalone10.
  ///
  /// In en, this message translates to:
  /// **'October'**
  String get monthStandalone10;

  /// No description provided for @monthStandalone11.
  ///
  /// In en, this message translates to:
  /// **'November'**
  String get monthStandalone11;

  /// No description provided for @monthStandalone12.
  ///
  /// In en, this message translates to:
  /// **'December'**
  String get monthStandalone12;

  /// Month as used inside a full date, e.g. “8 January 2026”. Russian needs the genitive case here (января) and Tajik the izofat (январи), which is why this is a separate set from monthStandalone.
  ///
  /// In en, this message translates to:
  /// **'January'**
  String get monthInDate1;

  /// No description provided for @monthInDate2.
  ///
  /// In en, this message translates to:
  /// **'February'**
  String get monthInDate2;

  /// No description provided for @monthInDate3.
  ///
  /// In en, this message translates to:
  /// **'March'**
  String get monthInDate3;

  /// No description provided for @monthInDate4.
  ///
  /// In en, this message translates to:
  /// **'April'**
  String get monthInDate4;

  /// No description provided for @monthInDate5.
  ///
  /// In en, this message translates to:
  /// **'May'**
  String get monthInDate5;

  /// No description provided for @monthInDate6.
  ///
  /// In en, this message translates to:
  /// **'June'**
  String get monthInDate6;

  /// No description provided for @monthInDate7.
  ///
  /// In en, this message translates to:
  /// **'July'**
  String get monthInDate7;

  /// No description provided for @monthInDate8.
  ///
  /// In en, this message translates to:
  /// **'August'**
  String get monthInDate8;

  /// No description provided for @monthInDate9.
  ///
  /// In en, this message translates to:
  /// **'September'**
  String get monthInDate9;

  /// No description provided for @monthInDate10.
  ///
  /// In en, this message translates to:
  /// **'October'**
  String get monthInDate10;

  /// No description provided for @monthInDate11.
  ///
  /// In en, this message translates to:
  /// **'November'**
  String get monthInDate11;

  /// No description provided for @monthInDate12.
  ///
  /// In en, this message translates to:
  /// **'December'**
  String get monthInDate12;

  /// A full date, e.g. “Wednesday, 8 July 2026”.
  ///
  /// In en, this message translates to:
  /// **'{weekday}, {day} {month} {year}'**
  String dateLong(String weekday, int day, String month, int year);

  /// A short date, e.g. “Wed, 8 Jul”. Uses the abbreviated weekday.
  ///
  /// In en, this message translates to:
  /// **'{weekday}, {day} {month}'**
  String dateShort(String weekday, int day, String month);

  /// Calendar header, e.g. “July 2026”.
  ///
  /// In en, this message translates to:
  /// **'{month} {year}'**
  String monthAndYear(String month, int year);

  /// A week range in the stats header, e.g. “Mon, 6 Jul – Sun, 12 Jul”.
  ///
  /// In en, this message translates to:
  /// **'{from} – {to}'**
  String dateRange(String from, String to);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ru', 'tg'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ru':
      return AppLocalizationsRu();
    case 'tg':
      return AppLocalizationsTg();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
