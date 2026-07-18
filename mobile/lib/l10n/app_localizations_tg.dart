// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Tajik (`tg`).
class AppLocalizationsTg extends AppLocalizations {
  AppLocalizationsTg([String locale = 'tg']) : super(locale);

  @override
  String get appTagline => 'Шабона нақша кун. Фардо ғалаба кун.';

  @override
  String get navToday => 'Имрӯз';

  @override
  String get navPlan => 'Нақша';

  @override
  String get navStats => 'Пешрафт';

  @override
  String get navHistory => 'Таърих';

  @override
  String get navSettings => 'Танзимот';

  @override
  String get emailLabel => 'Почтаи электронӣ';

  @override
  String get passwordLabel => 'Парол';

  @override
  String get confirmPasswordLabel => 'Паролро такрор кунед';

  @override
  String get logIn => 'Ворид шудан';

  @override
  String get createAccount => 'Сохтани ҳисоб';

  @override
  String get buildYourStreak => 'Пайдарпайии худро созед';

  @override
  String get noAccountSignUp => 'Ҳисоб надоред? Сабти ном кунед';

  @override
  String get alreadyHaveAccount => 'Ман аллакай ҳисоб дорам';

  @override
  String get passwordHelperMinChars => 'Ҳадди аққал 8 аломат';

  @override
  String get validEmailRequired => 'Почтаи электронии дурустро ворид кунед';

  @override
  String get passwordRequired => 'Паролро ворид кунед';

  @override
  String get passwordTooShort => 'Парол бояд ҳадди аққал 8 аломат бошад';

  @override
  String get passwordsDoNotMatch => 'Паролҳо мувофиқат намекунанд';

  @override
  String get loginFailed => 'Ворид шудан муяссар нашуд';

  @override
  String get signUpFailed => 'Сабти ном муяссар нашуд';

  @override
  String greeting(String name) {
    return 'Салом, $name';
  }

  @override
  String get todaysProgress => 'Пешрафти имрӯз';

  @override
  String get keepGoing => 'Ҳамин тавр давом деҳ!';

  @override
  String get allDone => 'Ҳама иҷро шуд. Офарин!';

  @override
  String streakDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count рӯз',
      one: '$count рӯз',
    );
    return '$_temp0';
  }

  @override
  String tasksPlanned(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count вазифа ба нақша гирифта шуд',
      one: '$count вазифа ба нақша гирифта шуд',
      zero: 'Ҳанӯз ҳеҷ чиз ба нақша гирифта нашудааст',
    );
    return '$_temp0';
  }

  @override
  String get daySchedule => 'Ҷадвали рӯз';

  @override
  String get now => 'ҲОЗИР';

  @override
  String get about => 'Дар бораи барнома';

  @override
  String get today => 'Имрӯз';

  @override
  String get tomorrow => 'Фардо';

  @override
  String get yesterday => 'Дирӯз';

  @override
  String get anytime => 'Ҳар вақт';

  @override
  String get addTask => 'Илова кардани вазифа';

  @override
  String get filter => 'Филтр';

  @override
  String get all => 'Ҳама';

  @override
  String get priority => 'Афзалият';

  @override
  String get category => 'Категория';

  @override
  String get categoryNone => 'Бе категория';

  @override
  String get priorityHigh => 'Баланд';

  @override
  String get priorityMedium => 'Миёна';

  @override
  String get priorityLow => 'Паст';

  @override
  String get nothingPlanned => 'Ҳеҷ чиз ба нақша гирифта нашудааст';

  @override
  String get nothingPlannedMessage =>
      'Барои ба нақша гирифтани ин рӯз «Илова кардани вазифа»-ро зер кунед.';

  @override
  String get noMatches => 'Мувофиқат ёфт нашуд';

  @override
  String get noMatchesMessage => 'Кӯшиш кунед филтрҳоро тоза кунед.';

  @override
  String progressDone(int done, int total) {
    return '$done аз $total иҷро шуд';
  }

  @override
  String get markDone => 'Иҷрошуда қайд кардан';

  @override
  String get markNotDone => 'Қайдро бардоштан';

  @override
  String get taskMoved => 'кӯчонида шуд';

  @override
  String get taskSkipped => 'гузаронида шуд';

  @override
  String get edit => 'Таҳрир';

  @override
  String get skip => 'Гузарондан';

  @override
  String get reschedule => 'Ба рӯзи дигар кӯчондан';

  @override
  String get delete => 'Нест кардан';

  @override
  String get cancel => 'Бекор кардан';

  @override
  String get save => 'Нигоҳ доштан';

  @override
  String get change => 'Тағйир додан';

  @override
  String get planTonight => 'Фардоятро имшаб тайёр кун';

  @override
  String get legendGoodDay => 'Рӯзи хуб';

  @override
  String get legendPartial => 'Қисман';

  @override
  String get legendEmpty => 'Холӣ';

  @override
  String get planningFor => 'Нақша барои';

  @override
  String get generateFromTemplates => 'Аз қолабҳо сохтан';

  @override
  String get generatingRecurringTasks => 'Вазифаҳои такрорӣ сохта мешаванд…';

  @override
  String get nothingPlannedYet => 'Ҳанӯз ҳеҷ чиз ба нақша гирифта нашудааст';

  @override
  String get planningEmptyMessage =>
      'Барои ин рӯз вазифаҳо илова кунед ё онҳоро аз қолабҳои такрории худ созед.';

  @override
  String get progressTitle => 'Пешрафт';

  @override
  String get statStreak => 'Пайдарпайӣ';

  @override
  String get statThisWeek => 'Ин ҳафта';

  @override
  String get statGoodDays => 'Рӯзҳои муваффақ';

  @override
  String bestStreak(int count) {
    return 'рекорд $count';
  }

  @override
  String tasksCompletedRatio(int completed, int total) {
    return '$completed/$total иҷро шуд';
  }

  @override
  String ofActiveDays(int count) {
    return 'аз $count рӯзи фаъол';
  }

  @override
  String get thisWeek => 'Ҳафтаи ҷорӣ';

  @override
  String get last30Days => '30 рӯзи охир';

  @override
  String get completionByDay => 'Иҷро аз рӯи рӯзҳо';

  @override
  String metGoal(int pct) {
    return 'Ҳадафи $pct% иҷро шуд';
  }

  @override
  String get belowGoal => 'Поёнтар аз ҳадаф';

  @override
  String get statsNeedConnection => 'Барои омор пайвасти интернет лозим аст.';

  @override
  String get nothingOnThisDay => 'Дар ин рӯз ҳеҷ чиз нест';

  @override
  String get categories => 'Категорияҳо';

  @override
  String get newCategory => 'Категорияи нав';

  @override
  String get editCategory => 'Таҳрири категория';

  @override
  String get nameLabel => 'Ном';

  @override
  String get noCategoriesYet => 'Ҳанӯз категория нест';

  @override
  String get noCategoriesMessage =>
      'Вазифаҳоро аз рӯи соҳаҳои ҳаёт гурӯҳбандӣ кунед — Кор, Таҳсил, Саломатӣ…';

  @override
  String get settingsAccount => 'Ҳисоб';

  @override
  String get settingsAppearance => 'Намуди зоҳирӣ';

  @override
  String get settingsLanguage => 'Забон';

  @override
  String get settingsDiscipline => 'Интизом';

  @override
  String get settingsNotifications => 'Огоҳиномаҳо';

  @override
  String get settingsOrganise => 'Ташкил';

  @override
  String timezoneLabel(String timezone) {
    return 'Минтақаи вақт: $timezone';
  }

  @override
  String get themeMode => 'Режими намоиш';

  @override
  String get themeSystem => 'Системавӣ';

  @override
  String get themeLight => 'Равшан';

  @override
  String get themeDark => 'Торик';

  @override
  String get successfulDayThreshold => 'Ҳадди «рӯзи муваффақ»';

  @override
  String thresholdSubtitle(int pct) {
    return '$pct% вазифаҳои иҷрошуда — рӯзи муваффақ';
  }

  @override
  String get taskReminders => 'Ёдоварии вазифаҳо';

  @override
  String get taskRemindersSubtitle =>
      'Огоҳиномаҳои маҳаллӣ дар вақти ҳар вазифа';

  @override
  String get defaultReminderTime => 'Вақти ёдоварӣ бо нобаёнӣ';

  @override
  String get logOut => 'Баромадан';

  @override
  String get reminderAtStart => 'Дар вақти оғоз';

  @override
  String reminderMinutesBefore(int minutes) {
    return '$minutes дақиқа пеш';
  }

  @override
  String get reminderOneHourBefore => '1 соат пеш';

  @override
  String get newTask => 'Вазифаи нав';

  @override
  String get editTask => 'Таҳрири вазифа';

  @override
  String get titleLabel => 'Сарлавҳа';

  @override
  String get titleRequired => 'Сарлавҳа ҳатмист';

  @override
  String get notesOptional => 'Қайдҳо (ихтиёрӣ)';

  @override
  String get dateLabel => 'Сана';

  @override
  String get startTimeLabel => 'Вақти оғоз';

  @override
  String get durationLabel => 'Давомнокӣ (дақиқа, ихтиёрӣ)';

  @override
  String get durationLabelShort => 'Давомнокӣ';

  @override
  String get minutesSuffix => 'дақ';

  @override
  String get durationMustBePositive => 'Рақами мусбат ворид кунед';

  @override
  String get reminderLabel => 'Ёдоварӣ';

  @override
  String get saveChanges => 'Нигоҳ доштани тағйирот';

  @override
  String get recurringTemplates => 'Қолабҳои такрорӣ';

  @override
  String get newTemplate => 'Қолаби нав';

  @override
  String get editTemplate => 'Таҳрири қолаб';

  @override
  String get createTemplate => 'Сохтани қолаб';

  @override
  String get noRecurringTasks => 'Вазифаҳои такрорӣ нестанд';

  @override
  String get noRecurringTasksMessage =>
      'Барои одатҳое, ки такрор мекунед, қолаб созед, баъд онҳоро аз экрани «Нақша» ба ҳар рӯз илова кунед.';

  @override
  String get repeats => 'Такрор мешавад';

  @override
  String get everyDay => 'Ҳар рӯз';

  @override
  String get specificDays => 'Рӯзҳои муайян';

  @override
  String get pickAtLeastOneDay =>
      'Ҳадди аққал як рӯзро интихоб кунед ё «Ҳар рӯз»-ро гиред.';

  @override
  String get pause => 'Таваққуф';

  @override
  String get resume => 'Идома';

  @override
  String get paused => 'таваққуф шуд';

  @override
  String errorWithMessage(String message) {
    return 'Хатогӣ: $message';
  }

  @override
  String couldNotSave(String message) {
    return 'Нигоҳ доштан муяссар нашуд: $message';
  }

  @override
  String get somethingWentWrong => 'Чизе нодуруст рафт';

  @override
  String get serverTookTooLong => 'Сервер хеле дер ҷавоб дод.';

  @override
  String get cannotReachServer =>
      'Ба сервер пайваст шуда нашуд. Пайвасти худро тафтиш кунед.';

  @override
  String get errorEmailTaken =>
      'Ҳисоб бо ин почтаи электронӣ аллакай мавҷуд аст.';

  @override
  String get errorBadCredentials => 'Почтаи электронӣ ё парол нодуруст аст.';

  @override
  String get errorSessionExpired =>
      'Сессияи шумо ба охир расид. Аз нав ворид шавед.';

  @override
  String get errorCategoryNotFound => 'Ин категория дигар вуҷуд надорад.';

  @override
  String get errorCategoryExists => 'Категория бо ин ном аллакай мавҷуд аст.';

  @override
  String get errorValidation =>
      'Баъзе маълумоти воридкардаи шумо нодуруст аст.';

  @override
  String get errorSameDate =>
      'Вазифа аллакай ба ҳамин сана ба нақша гирифта шудааст.';

  @override
  String get errorTooManyAttempts =>
      'Кӯшишҳо аз ҳад зиёданд. Баъдтар такрор кунед.';

  @override
  String get eveningReminderTitle => 'Фардоро нақша кунед';

  @override
  String get eveningReminderBody =>
      'Якчанд дақиқаи имшаб — ва фардо аз рӯи нақша мегузарад.';

  @override
  String get eveningReminderTitle2 => 'Ёдоварии шабонаи нақшагузорӣ';

  @override
  String get eveningReminderSubtitle =>
      'Ёдоварии ҳаррӯза барои нақша кардани вазифаҳои фардо';

  @override
  String get eveningReminderTimeLabel => 'Вақти ёдоварӣ';

  @override
  String get notificationChannelName => 'Ёдоварии вазифаҳо';

  @override
  String get notificationChannelDescription =>
      'Ёдоварӣ барои вазифаҳои ба нақша гирифтаи шумо';

  @override
  String notificationScheduledFor(String time) {
    return 'Барои соати $time ба нақша гирифта шудааст';
  }

  @override
  String get weekdayShort1 => 'Дш';

  @override
  String get weekdayShort2 => 'Сш';

  @override
  String get weekdayShort3 => 'Чш';

  @override
  String get weekdayShort4 => 'Пш';

  @override
  String get weekdayShort5 => 'Ҷм';

  @override
  String get weekdayShort6 => 'Шн';

  @override
  String get weekdayShort7 => 'Яш';

  @override
  String get weekdayLong1 => 'Душанбе';

  @override
  String get weekdayLong2 => 'Сешанбе';

  @override
  String get weekdayLong3 => 'Чоршанбе';

  @override
  String get weekdayLong4 => 'Панҷшанбе';

  @override
  String get weekdayLong5 => 'Ҷумъа';

  @override
  String get weekdayLong6 => 'Шанбе';

  @override
  String get weekdayLong7 => 'Якшанбе';

  @override
  String get monthStandalone1 => 'Январ';

  @override
  String get monthStandalone2 => 'Феврал';

  @override
  String get monthStandalone3 => 'Март';

  @override
  String get monthStandalone4 => 'Апрел';

  @override
  String get monthStandalone5 => 'Май';

  @override
  String get monthStandalone6 => 'Июн';

  @override
  String get monthStandalone7 => 'Июл';

  @override
  String get monthStandalone8 => 'Август';

  @override
  String get monthStandalone9 => 'Сентябр';

  @override
  String get monthStandalone10 => 'Октябр';

  @override
  String get monthStandalone11 => 'Ноябр';

  @override
  String get monthStandalone12 => 'Декабр';

  @override
  String get monthInDate1 => 'январи';

  @override
  String get monthInDate2 => 'феврали';

  @override
  String get monthInDate3 => 'марти';

  @override
  String get monthInDate4 => 'апрели';

  @override
  String get monthInDate5 => 'майи';

  @override
  String get monthInDate6 => 'июни';

  @override
  String get monthInDate7 => 'июли';

  @override
  String get monthInDate8 => 'августи';

  @override
  String get monthInDate9 => 'сентябри';

  @override
  String get monthInDate10 => 'октябри';

  @override
  String get monthInDate11 => 'ноябри';

  @override
  String get monthInDate12 => 'декабри';

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
