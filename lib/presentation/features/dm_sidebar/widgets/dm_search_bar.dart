import 'dart:ui';

import 'package:disalive/app/theme/app_theme.dart';
import 'package:disalive/presentation/features/chat/bloc/chat_bloc.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class DmSearchBar extends StatelessWidget {
  final TextEditingController _searchController;
  final Function(bool) _toggleSearch;

  const DmSearchBar({
    super.key,
    required TextEditingController searchController,
    required Function(bool) toggleSearch,
  }) : _searchController = searchController,
       _toggleSearch = toggleSearch;

  static const double _buttonRadius = 32;

  @override
  Widget build(BuildContext context) {
    return Padding(
      key: key,
      // Уменьшен нижний отступ с 14 до 8 для компактности
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(_buttonRadius),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.actionGrey.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(_buttonRadius),
                  border: Border.all(color: AppColors.white.withOpacity(0.08)),
                ),
                child: Row(
                  children: [
                    const SizedBox(width: 14),
                    Icon(
                      CupertinoIcons.search,
                      color: AppColors.white.withOpacity(0.6),
                      size: 18,
                    ),
                    const SizedBox(width: 10),

                    // Само поле ввода
                    Expanded(
                      child: CupertinoTextField(
                        controller: _searchController,
                        autofocus: true,
                        placeholder: 'Поиск...',
                        placeholderStyle: AppText.mediumTextStyle.copyWith(
                          color: AppColors.white.withOpacity(0.4),
                        ),
                        style: AppText.mediumTextStyle.copyWith(
                          color: AppColors.white,
                        ),
                        decoration: null,
                        // Убираем стандартную рамку Cupertino
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        onChanged: (value) {
                          context.read<ChatBloc>().add(SearchChats(value));

                          if (value.trim().isEmpty) {
                            context.read<ChatBloc>().add(GetChats());
                          }
                        },
                      ),
                    ),

                    // Кнопка отмены поиска ВНУТРИ поля
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      // Гарантирует срабатывание тапа по всей области padding
                      onTap: () => _toggleSearch(false),
                      child: Padding(
                        padding: const EdgeInsets.all(10.0),
                        child: Icon(
                          CupertinoIcons.xmark_circle_fill,
                          color: AppColors.white.withOpacity(0.5),
                          size: 20,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
