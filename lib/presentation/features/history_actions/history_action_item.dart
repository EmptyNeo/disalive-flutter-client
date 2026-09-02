import 'package:disalive/app/theme/app_theme.dart';
import 'package:disalive/domain/models/history_action.dart';
import 'package:flutter/cupertino.dart';

/// Системное действие в истории чата (участник добавлен/удалён, чат
/// переименован и т.п.).
///
/// Модели [HistoryAction] не было в контексте, поэтому здесь пока только
/// проверка на пустое действие и заглушка — реальную разметку под каждый
/// тип действия сделаем отдельно.
class HistoryActionItem extends StatelessWidget {
  const HistoryActionItem({super.key, required this.action});

  final HistoryAction? action;

  @override
  Widget build(BuildContext context) {
    if (action == null) return const SizedBox.shrink();

    // TODO: разобрать реальные поля HistoryAction и добавить разметку под
    // каждый тип действия (добавление/удаление участника, смена названия
    // или аватара чата и т.д.).
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Center(
        child: Text(
          '[в разработке]',
          style: AppText.lowTextStyle.copyWith(color: AppColors.greyple),
        ),
      ),
    );
  }
}