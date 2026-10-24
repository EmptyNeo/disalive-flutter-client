// lib/presentation/features/dm_sidebar/widgets/dm_normal_header.dart

import 'package:disalive/app/theme/app_theme.dart';
import 'package:disalive/presentation/features/requests/bloc/requests_bloc.dart';
import 'package:disalive/presentation/features/requests/requests_screen.dart';
import 'package:disalive/presentation/widgets/buttons/glass_button.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class DmNormalHeader extends StatelessWidget {
  final bool isReconnect;
  final VoidCallback onSearchTap;
  final VoidCallback? onReadAllTap;

  const DmNormalHeader({
    super.key,
    required this.isReconnect,
    required this.onSearchTap,
    this.onReadAllTap,
  });

  static const double _buttonRadius = 32;

  @override
  Widget build(BuildContext context) {
    String title = isReconnect ? 'Соединение...' : 'Личные сообщения';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 18, 16, 14),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: AppColors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
              if (onReadAllTap != null)
                Semantics(
                  label: 'Прочитать все чаты',
                  button: true,
                  child: CupertinoButton(
                    key: const ValueKey('read_all_chats'),
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(32, 32),
                    onPressed: onReadAllTap,
                    child: const Icon(
                      CupertinoIcons.checkmark_circle,
                      size: 21,
                    ),
                  ),
                ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              GlassButton(
                borderRadius: _buttonRadius,
                padding: const EdgeInsets.all(11),
                onTap: onSearchTap,
                child: Icon(
                  CupertinoIcons.search,
                  color: AppColors.white.withValues(alpha: 0.75),
                  size: 18,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: BlocBuilder<RequestsBloc, RequestsState>(
                  builder: (context, state) {
                    final requestsCount = state is RequestsLoaded
                        ? state.requests.where((r) => r.isIncoming).length
                        : 0;

                    return GlassButton(
                      borderRadius: _buttonRadius,
                      padding: const EdgeInsets.symmetric(
                        vertical: 11,
                        horizontal: 14,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.max,
                        children: [
                          Icon(
                            CupertinoIcons.person_add_solid,
                            color: AppColors.white.withValues(alpha: 0.75),
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    'Добавить в друзья',
                                    style: TextStyle(
                                      color: AppColors.white.withValues(
                                        alpha: 0.85,
                                      ),
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                    softWrap: false,
                                  ),
                                ),

                                if (requestsCount > 0) ...[
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.errorRed,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      requestsCount > 99
                                          ? '99+'
                                          : requestsCount.toString(),
                                      style: const TextStyle(
                                        color: CupertinoColors.white,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        height: 1.2,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                      onTap: () {
                        RequestsScreen.open(context);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
