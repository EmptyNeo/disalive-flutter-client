enum ComplaintSeverity {
  low('low', 'Низкая', 'Незначительное нарушение'),
  medium('medium', 'Средняя', 'Нарушение правил сообщества'),
  high('high', 'Высокая', 'Серьёзное нарушение'),
  critical('critical', 'Критическая', 'Экстренная ситуация');

  const ComplaintSeverity(this.value, this.displayName, this.description);

  final String value;
  final String displayName;
  final String description;
}
