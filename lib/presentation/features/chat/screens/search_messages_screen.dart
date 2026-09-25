import 'dart:async';

import 'package:disalive/app/di/di.dart';
import 'package:disalive/app/theme/app_theme.dart';
import 'package:disalive/domain/enums/entity_type.dart';
import 'package:disalive/domain/enums/ui/message_tail_direction.dart';
import 'package:disalive/domain/models/chat.dart';
import 'package:disalive/domain/models/message.dart';
import 'package:disalive/domain/repositories/message_repository.dart';
import 'package:disalive/domain/repositories/user_repository.dart';
import 'package:disalive/presentation/features/message/message_item.dart';
import 'package:disalive/presentation/navigation/swipe_to_dismiss_route.dart';
import 'package:disalive/presentation/utils/ui/util_date.dart';
import 'package:disalive/presentation/widgets/buttons/glass_icon_button.dart'; // Убедись, что путь верный
import 'package:disalive/presentation/widgets/custom_back_button.dart';
import 'package:flutter/cupertino.dart';

class SearchMessagesScreen extends StatefulWidget {
  final Chat chat;

  const SearchMessagesScreen({super.key, required this.chat});

  /// Открывает экран поиска и возвращает выбранное сообщение (или null, если пользователь закрыл экран).
  static Future<Message?> open(BuildContext context, Chat chat) {
    return SwipeToDismissRoute.push<Message>(
      context,
      (context) => SearchMessagesScreen(chat: chat),
    );
  }

  @override
  State<SearchMessagesScreen> createState() => _SearchMessagesScreenState();
}

class _SearchMessagesScreenState extends State<SearchMessagesScreen> {
  final TextEditingController _queryController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  Timer? _debounceTimer;

  List<Message> _results = [];
  bool _isLoading = false;
  bool _hasSearched = false;
  String? _error;

  int? get _currentUserId => sl<UserRepository>().getCurrentUser()?.id;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _queryController.dispose();
    _focusNode.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onQueryChanged(String query) {
    _debounceTimer?.cancel();

    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      setState(() {
        _results = [];
        _isLoading = false;
        _hasSearched = false;
        _error = null;
      });
      return;
    }

    _debounceTimer = Timer(const Duration(milliseconds: 400), () {
      _performSearch(trimmed);
    });
  }

  Future<void> _performSearch(String query) async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final result = await sl<MessageRepository>().get(
        widget.chat.id,
        widget.chat.id,
        EntityType.chat,
        50,
        // Лимит результатов поиска
        0,
        // lastIdMessage
        null,
        // aroundId
        null,
        // newerThanId
        query, // searchQuery
      );

      if (!mounted) return;

      result.fold(
        (failure) {
          setState(() {
            _error = failure.message;
            _results = [];
            _isLoading = false;
            _hasSearched = true;
          });
        },
        (response) {
          setState(() {
            _results = response.messages;
            _isLoading = false;
            _hasSearched = true;
          });
        },
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _results = [];
        _isLoading = false;
        _hasSearched = true;
      });
    }
  }

  void _onMessageTap(Message message) {
    Navigator.pop(context, message);
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.transparent,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              color: AppColors.mainBackground,
              border: Border.all(
                color: AppColors.white.withValues(alpha: 0.12),
                width: 1,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Stack(
                children: [
                  Column(
                    children: [
                      _buildHeader(),
                      Expanded(child: _buildResultsList()),
                    ],
                  ),
                  const CustomBackButton(positioned: 8),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      // Немного увеличиваем нижний отступ для "воздуха"
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 🎯 Обертка для заголовка с фиксированной высотой
          Container(
            height: 40, // Примерная высота CustomBackButton для ровного центрирования
            alignment: Alignment.center,
            child: Text(
              'Поиск сообщений',
              style: AppText.highTextStyle,
            ),
          ),

          // 🎯 Явный отступ, чтобы поле поиска не прилипало к заголовку
          const SizedBox(height: 16),

          // 🎯 Поле ввода в стиле ChatInputArea
          ClipRRect(
            borderRadius: const BorderRadius.all(Radius.circular(20)),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.lightGrey,
                borderRadius: const BorderRadius.all(Radius.circular(20)),
                border: Border.all(
                  color: AppColors.white.withValues(alpha: 0.08),
                ),
              ),
              child: CupertinoTextField(
                controller: _queryController,
                focusNode: _focusNode,
                minLines: 1,
                maxLines: 1,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                placeholder: 'Введите текст для поиска...',
                placeholderStyle: AppText.mediumTextStyle.copyWith(
                  color: AppColors.greyple,
                ),
                style: AppText.mediumTextStyle.copyWith(color: AppColors.white),
                decoration: null, // Убираем стандартную декорацию
                clearButtonMode: OverlayVisibilityMode.editing,
                onChanged: _onQueryChanged,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsList() {
    if (_isLoading) {
      return const Center(child: CupertinoActivityIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'Ошибка поиска: $_error',
            style: AppText.mediumTextStyle.copyWith(color: AppColors.greyple),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    if (!_hasSearched) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'Начните вводить текст для поиска сообщений',
            style: AppText.mediumTextStyle.copyWith(color: AppColors.greyple),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    if (_results.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'Ничего не найдено',
            style: AppText.mediumTextStyle.copyWith(color: AppColors.greyple),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 16),
      itemCount: _results.length,
      itemBuilder: (context, index) {
        final message = _results[index];
        final isMine =
            _currentUserId != null && message.userId == _currentUserId;

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => _onMessageTap(message),
          child: Container(
            color: AppColors.transparent,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child:  MessageItem(
              message: message,
              isMine: isMine,
              isRead: true,
              // В поиске не важно, прочитано ли
              showSender: true,
              showAvatar: true,
              showTime: true,
              // Время уже выведено в заголовке
              tailDirection: MessageTailDirection.none,
              hasMessageAbove: false,
            ),
          ),
        );
      },
    );
  }
}