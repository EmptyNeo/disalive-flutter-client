import 'package:disalive/domain/models/chat.dart';
import 'package:disalive/presentation/features/chat/bloc/chat_bloc.dart';
import 'package:disalive/presentation/features/dm_sidebar/widgets/dm_list_area.dart';
import 'package:disalive/presentation/features/dm_sidebar/widgets/dm_normal_header.dart';
import 'package:disalive/presentation/features/dm_sidebar/widgets/dm_search_bar.dart';
import 'package:flutter/cupertino.dart';
import 'package:disalive/app/theme/app_theme.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class DirectMessagesSidebar extends StatefulWidget {
  final List<Chat> chats;
  final bool isLoading;
  final bool isReconnect;

  const DirectMessagesSidebar({
    super.key,
    required this.chats,
    required this.isReconnect,
    this.isLoading = false,
  });

  @override
  State<DirectMessagesSidebar> createState() => _DirectMessagesSidebarState();
}

class _DirectMessagesSidebarState extends State<DirectMessagesSidebar> {
  bool _isSearchActive = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  static const double _panelRadius = 28;

  void _toggleSearch(bool isActive) {
    setState(() {
      _isSearchActive = isActive;
      if (!isActive) {
        _searchController.clear();
        context.read<ChatBloc>().add(SearchChats(''));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(_panelRadius),
          ),
          border: Border.all(
            color: AppColors.white.withValues(alpha: 0.10),
            width: 1,
          ),
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(_panelRadius),
          ),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.lightGrey.withValues(alpha: 0.72),
                  AppColors.lightGrey.withValues(alpha: 0.55),
                ],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Анимированная область заголовка/поиска
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  transitionBuilder:
                      (Widget child, Animation<double> animation) {
                        return SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0.1, 0.0),
                            end: Offset.zero,
                          ).animate(animation),
                          child: FadeTransition(
                            opacity: animation,
                            child: child,
                          ),
                        );
                      },
                  child: _isSearchActive
                      ? DmSearchBar(
                          key: const ValueKey('search'),
                          searchController: _searchController,
                          toggleSearch: _toggleSearch,
                        )
                      : DmNormalHeader(
                          key: const ValueKey('header'),
                          isReconnect: widget.isReconnect,
                          onSearchTap: () => _toggleSearch(true),
                        ),
                ),

                // Уменьшенный отступ снизу (было 14, стало 8)
                const SizedBox(height: 8),

                Container(
                  width: double.infinity,
                  height: 1,
                  color: AppColors.white.withOpacity(0.10),
                ),

                Expanded(
                  child: DmListArea(
                    chats: widget.chats,
                    isLoading: widget.isLoading,
                    isSearchActive: _isSearchActive,
                    isReconnect: widget.isReconnect,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
