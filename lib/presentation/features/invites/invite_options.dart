enum InviteLifetime {
  forever('Бессрочно', null),
  minutes30('30 минут', Duration(minutes: 30)),
  hour1('1 час', Duration(hours: 1)),
  hours6('6 часов', Duration(hours: 6)),
  hours12('12 часов', Duration(hours: 12)),
  day1('1 день', Duration(days: 1)),
  days7('7 дней', Duration(days: 7)),
  days30('30 дней', Duration(days: 30));

  const InviteLifetime(this.label, this.duration);

  final String label;
  final Duration? duration;

  int? get durationSeconds => duration?.inSeconds;

  String get validityText => this == forever
      ? 'Ваша ссылка-приглашение будет действовать бессрочно.'
      : 'Ваша ссылка-приглашение будет действовать $label.';
}

enum InviteUsageLimit {
  unlimited('Без ограничений', 0),
  once('1 раз', 1),
  five('5 раз', 5),
  ten('10 раз', 10),
  twentyFive('25 раз', 25),
  hundred('100 раз', 100);

  const InviteUsageLimit(this.label, this.value);

  final String label;
  final int value;
}
