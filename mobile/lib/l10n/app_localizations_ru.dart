// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get appTagline => 'Планируй вечером. Побеждай завтра.';

  @override
  String get navToday => 'Сегодня';

  @override
  String get navPlan => 'План';

  @override
  String get navStats => 'Прогресс';

  @override
  String get navHistory => 'История';

  @override
  String get navSettings => 'Настройки';

  @override
  String get emailLabel => 'Электронная почта';

  @override
  String get passwordLabel => 'Пароль';

  @override
  String get confirmPasswordLabel => 'Повторите пароль';

  @override
  String get logIn => 'Войти';

  @override
  String get createAccount => 'Создать аккаунт';

  @override
  String get buildYourStreak => 'Создайте свою серию';

  @override
  String get noAccountSignUp => 'Нет аккаунта? Зарегистрируйтесь';

  @override
  String get alreadyHaveAccount => 'У меня уже есть аккаунт';

  @override
  String get passwordHelperMinChars => 'Минимум 8 символов';

  @override
  String get validEmailRequired => 'Введите корректный адрес почты';

  @override
  String get passwordRequired => 'Введите пароль';

  @override
  String get passwordTooShort => 'Пароль должен содержать не менее 8 символов';

  @override
  String get passwordsDoNotMatch => 'Пароли не совпадают';

  @override
  String get loginFailed => 'Не удалось войти';

  @override
  String get signUpFailed => 'Не удалось зарегистрироваться';

  @override
  String greeting(String name) {
    return 'Привет, $name';
  }

  @override
  String get todaysProgress => 'Прогресс сегодня';

  @override
  String get keepGoing => 'Так держать!';

  @override
  String get allDone => 'Всё выполнено. Отличная работа!';

  @override
  String streakDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count дня',
      many: '$count дней',
      few: '$count дня',
      one: '$count день',
    );
    return '$_temp0';
  }

  @override
  String tasksPlanned(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count задачи',
      many: '$count задач',
      few: '$count задачи',
      one: '$count задача',
      zero: 'Пока ничего не запланировано',
    );
    return '$_temp0';
  }

  @override
  String get daySchedule => 'Расписание дня';

  @override
  String get now => 'СЕЙЧАС';

  @override
  String get about => 'О приложении';

  @override
  String get today => 'Сегодня';

  @override
  String get tomorrow => 'Завтра';

  @override
  String get yesterday => 'Вчера';

  @override
  String get anytime => 'В любое время';

  @override
  String get addTask => 'Добавить задачу';

  @override
  String get filter => 'Фильтр';

  @override
  String get all => 'Все';

  @override
  String get priority => 'Приоритет';

  @override
  String get category => 'Категория';

  @override
  String get categoryNone => 'Без категории';

  @override
  String get priorityHigh => 'Высокий';

  @override
  String get priorityMedium => 'Средний';

  @override
  String get priorityLow => 'Низкий';

  @override
  String get nothingPlanned => 'Ничего не запланировано';

  @override
  String get nothingPlannedMessage =>
      'Нажмите «Добавить задачу», чтобы спланировать этот день.';

  @override
  String get noMatches => 'Совпадений нет';

  @override
  String get noMatchesMessage => 'Попробуйте сбросить фильтры.';

  @override
  String progressDone(int done, int total) {
    return '$done из $total выполнено';
  }

  @override
  String get markDone => 'Отметить выполненной';

  @override
  String get markNotDone => 'Снять отметку';

  @override
  String get taskMoved => 'перенесена';

  @override
  String get taskSkipped => 'пропущена';

  @override
  String get edit => 'Изменить';

  @override
  String get skip => 'Пропустить';

  @override
  String get reschedule => 'Перенести';

  @override
  String get delete => 'Удалить';

  @override
  String get cancel => 'Отмена';

  @override
  String get save => 'Сохранить';

  @override
  String get change => 'Изменить';

  @override
  String get planTonight => 'Подготовь завтрашний день вечером';

  @override
  String get legendGoodDay => 'Хороший день';

  @override
  String get legendPartial => 'Частично';

  @override
  String get legendEmpty => 'Пусто';

  @override
  String get planningFor => 'Планируем на';

  @override
  String get generateFromTemplates => 'Создать из шаблонов';

  @override
  String get generatingRecurringTasks => 'Создаём повторяющиеся задачи…';

  @override
  String get nothingPlannedYet => 'Пока ничего не запланировано';

  @override
  String get planningEmptyMessage =>
      'Добавьте задачи на этот день или создайте их из повторяющихся шаблонов.';

  @override
  String get progressTitle => 'Прогресс';

  @override
  String get statStreak => 'Серия';

  @override
  String get statThisWeek => 'На этой неделе';

  @override
  String get statGoodDays => 'Успешных дней';

  @override
  String bestStreak(int count) {
    return 'рекорд $count';
  }

  @override
  String tasksCompletedRatio(int completed, int total) {
    return '$completed/$total выполнено';
  }

  @override
  String ofActiveDays(int count) {
    return 'из $count активных';
  }

  @override
  String get thisWeek => 'Эта неделя';

  @override
  String get last30Days => 'Последние 30 дней';

  @override
  String get completionByDay => 'Выполнение по дням';

  @override
  String metGoal(int pct) {
    return 'Цель $pct% достигнута';
  }

  @override
  String get belowGoal => 'Ниже цели';

  @override
  String get statsNeedConnection => 'Для статистики нужно подключение.';

  @override
  String get nothingOnThisDay => 'В этот день ничего нет';

  @override
  String get categories => 'Категории';

  @override
  String get newCategory => 'Новая категория';

  @override
  String get editCategory => 'Изменить категорию';

  @override
  String get nameLabel => 'Название';

  @override
  String get noCategoriesYet => 'Категорий пока нет';

  @override
  String get noCategoriesMessage =>
      'Группируйте задачи по сферам жизни — Работа, Учёба, Здоровье…';

  @override
  String get settingsAccount => 'Аккаунт';

  @override
  String get settingsAppearance => 'Внешний вид';

  @override
  String get settingsLanguage => 'Язык';

  @override
  String get settingsDiscipline => 'Дисциплина';

  @override
  String get settingsNotifications => 'Уведомления';

  @override
  String get settingsOrganise => 'Организация';

  @override
  String timezoneLabel(String timezone) {
    return 'Часовой пояс: $timezone';
  }

  @override
  String get themeMode => 'Режим отображения';

  @override
  String get themeSystem => 'Системная';

  @override
  String get themeLight => 'Светлая';

  @override
  String get themeDark => 'Тёмная';

  @override
  String get successfulDayThreshold => 'Порог «успешного дня»';

  @override
  String thresholdSubtitle(int pct) {
    return '$pct% выполненных задач — успешный день';
  }

  @override
  String get taskReminders => 'Напоминания о задачах';

  @override
  String get taskRemindersSubtitle =>
      'Локальные уведомления во время каждой задачи';

  @override
  String get defaultReminderTime => 'Время напоминания по умолчанию';

  @override
  String get logOut => 'Выйти';

  @override
  String get reminderAtStart => 'В момент начала';

  @override
  String reminderMinutesBefore(int minutes) {
    return 'За $minutes минут';
  }

  @override
  String get reminderOneHourBefore => 'За 1 час';

  @override
  String get newTask => 'Новая задача';

  @override
  String get editTask => 'Изменить задачу';

  @override
  String get titleLabel => 'Название';

  @override
  String get titleRequired => 'Название обязательно';

  @override
  String get notesOptional => 'Заметки (необязательно)';

  @override
  String get dateLabel => 'Дата';

  @override
  String get startTimeLabel => 'Время начала';

  @override
  String get durationLabel => 'Длительность (минуты, необязательно)';

  @override
  String get durationLabelShort => 'Длительность';

  @override
  String get minutesSuffix => 'мин';

  @override
  String get durationMustBePositive => 'Введите положительное число';

  @override
  String get reminderLabel => 'Напоминание';

  @override
  String get saveChanges => 'Сохранить изменения';

  @override
  String get recurringTemplates => 'Повторяющиеся шаблоны';

  @override
  String get newTemplate => 'Новый шаблон';

  @override
  String get editTemplate => 'Изменить шаблон';

  @override
  String get createTemplate => 'Создать шаблон';

  @override
  String get noRecurringTasks => 'Повторяющихся задач нет';

  @override
  String get noRecurringTasksMessage =>
      'Создайте шаблоны для привычек, которые вы повторяете, а затем добавляйте их на любой день с экрана «План».';

  @override
  String get repeats => 'Повторяется';

  @override
  String get everyDay => 'Каждый день';

  @override
  String get specificDays => 'Выбранные дни';

  @override
  String get pickAtLeastOneDay =>
      'Выберите хотя бы один день или вариант «Каждый день».';

  @override
  String get pause => 'Приостановить';

  @override
  String get resume => 'Возобновить';

  @override
  String get paused => 'приостановлен';

  @override
  String errorWithMessage(String message) {
    return 'Ошибка: $message';
  }

  @override
  String couldNotSave(String message) {
    return 'Не удалось сохранить: $message';
  }

  @override
  String get somethingWentWrong => 'Что-то пошло не так';

  @override
  String get serverTookTooLong => 'Сервер слишком долго не отвечает.';

  @override
  String get cannotReachServer =>
      'Не удаётся связаться с сервером. Проверьте подключение.';

  @override
  String get errorEmailTaken => 'Аккаунт с такой почтой уже существует.';

  @override
  String get errorBadCredentials => 'Неверная почта или пароль.';

  @override
  String get errorSessionExpired => 'Сессия истекла. Войдите снова.';

  @override
  String get errorCategoryNotFound => 'Этой категории больше не существует.';

  @override
  String get errorCategoryExists =>
      'Категория с таким названием уже существует.';

  @override
  String get errorValidation => 'Некоторые из введённых данных некорректны.';

  @override
  String get errorSameDate => 'Задача уже запланирована на эту дату.';

  @override
  String get errorTooManyAttempts => 'Слишком много попыток. Повторите позже.';

  @override
  String get eveningReminderTitle => 'Спланируйте завтрашний день';

  @override
  String get eveningReminderBody =>
      'Несколько минут вечером — и завтра пройдёт по плану.';

  @override
  String get eveningReminderTitle2 => 'Вечернее напоминание о планировании';

  @override
  String get eveningReminderSubtitle =>
      'Ежедневное напоминание спланировать задачи на завтра';

  @override
  String get eveningReminderTimeLabel => 'Время напоминания';

  @override
  String get notificationChannelName => 'Напоминания о задачах';

  @override
  String get notificationChannelDescription =>
      'Напоминания о запланированных задачах';

  @override
  String notificationScheduledFor(String time) {
    return 'Запланировано на $time';
  }

  @override
  String get weekdayShort1 => 'Пн';

  @override
  String get weekdayShort2 => 'Вт';

  @override
  String get weekdayShort3 => 'Ср';

  @override
  String get weekdayShort4 => 'Чт';

  @override
  String get weekdayShort5 => 'Пт';

  @override
  String get weekdayShort6 => 'Сб';

  @override
  String get weekdayShort7 => 'Вс';

  @override
  String get weekdayLong1 => 'Понедельник';

  @override
  String get weekdayLong2 => 'Вторник';

  @override
  String get weekdayLong3 => 'Среда';

  @override
  String get weekdayLong4 => 'Четверг';

  @override
  String get weekdayLong5 => 'Пятница';

  @override
  String get weekdayLong6 => 'Суббота';

  @override
  String get weekdayLong7 => 'Воскресенье';

  @override
  String get monthStandalone1 => 'Январь';

  @override
  String get monthStandalone2 => 'Февраль';

  @override
  String get monthStandalone3 => 'Март';

  @override
  String get monthStandalone4 => 'Апрель';

  @override
  String get monthStandalone5 => 'Май';

  @override
  String get monthStandalone6 => 'Июнь';

  @override
  String get monthStandalone7 => 'Июль';

  @override
  String get monthStandalone8 => 'Август';

  @override
  String get monthStandalone9 => 'Сентябрь';

  @override
  String get monthStandalone10 => 'Октябрь';

  @override
  String get monthStandalone11 => 'Ноябрь';

  @override
  String get monthStandalone12 => 'Декабрь';

  @override
  String get monthInDate1 => 'января';

  @override
  String get monthInDate2 => 'февраля';

  @override
  String get monthInDate3 => 'марта';

  @override
  String get monthInDate4 => 'апреля';

  @override
  String get monthInDate5 => 'мая';

  @override
  String get monthInDate6 => 'июня';

  @override
  String get monthInDate7 => 'июля';

  @override
  String get monthInDate8 => 'августа';

  @override
  String get monthInDate9 => 'сентября';

  @override
  String get monthInDate10 => 'октября';

  @override
  String get monthInDate11 => 'ноября';

  @override
  String get monthInDate12 => 'декабря';

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
