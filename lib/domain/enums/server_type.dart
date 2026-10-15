enum ServerType {
  none('NONE', 'Без категории'),
  games('GAMES', 'Игры'),
  music('MUSIC', 'Музыка'),
  entertainment('ENTERTAINMENT', 'Развлечения'),
  scienceAndTechnology('SCIENCE_AND_TECHNOLOGY', 'Наука и технологии'),
  education('EDUCATION', 'Образование'),
  sports('SPORTS', 'Спорт');

  final String value;
  final String label;

  const ServerType(this.value, this.label);

  static ServerType fromString(String? value) {
    return ServerType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => ServerType.none,
    );
  }
}
