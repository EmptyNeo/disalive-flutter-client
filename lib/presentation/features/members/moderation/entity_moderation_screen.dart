import 'package:disalive/app/di/di.dart';
import 'package:disalive/app/theme/app_theme.dart';
import 'package:disalive/domain/enums/entity_type.dart';
import 'package:disalive/domain/models/entity_key.dart';
import 'package:disalive/domain/models/entity_moderation.dart';
import 'package:disalive/domain/repositories/members_repository.dart';
import 'package:disalive/presentation/features/role_members/widgets/role_screen_shell.dart';
import 'package:disalive/presentation/navigation/swipe_to_dismiss_route.dart';
import 'package:disalive/presentation/widgets/build_avatar.dart';
import 'package:disalive/presentation/widgets/toasts/custom_toast.dart';
import 'package:flutter/cupertino.dart';

class EntityModerationScreen extends StatefulWidget {
  const EntityModerationScreen({
    super.key,
    required this.entityId,
    required this.entityType,
    required this.entityName,
  });

  final int entityId;
  final EntityType entityType;
  final String entityName;

  static Future<void> open(
    BuildContext context, {
    required int entityId,
    required EntityType entityType,
    required String entityName,
  }) => SwipeToDismissRoute.push<void>(
    context,
    (_) => EntityModerationScreen(
      entityId: entityId,
      entityType: entityType,
      entityName: entityName,
    ),
  );

  @override
  State<EntityModerationScreen> createState() => _EntityModerationScreenState();
}

class _EntityModerationScreenState extends State<EntityModerationScreen> {
  List<EntityModeration> _entries = const [];
  String? _error;
  bool _loading = true;
  final Set<int> _savingIds = {};

  EntityKey get _entityKey =>
      EntityKey(entityId: widget.entityId, entityType: widget.entityType);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final result = await sl<MembersRepository>().getModeration(_entityKey);
    if (!mounted) return;
    result.fold(
      (failure) => setState(() {
        _loading = false;
        _error = failure.message;
      }),
      (entries) => setState(() {
        _loading = false;
        _entries = entries;
      }),
    );
  }

  Future<void> _clear(EntityModeration entry) async {
    if (!_savingIds.add(entry.id)) return;
    setState(() {});
    final result = await sl<MembersRepository>().moderate(
      entityKey: _entityKey,
      userId: entry.userId,
      action: entry.isBan ? 'unban' : 'unmute',
    );
    if (!mounted) return;
    _savingIds.remove(entry.id);
    result.fold(
      (failure) => CustomToast.open(context: context, message: failure.message),
      (_) => setState(
        () => _entries = _entries.where((item) => item.id != entry.id).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => RoleScreenShell(
    title: 'Ограничения',
    subtitle: widget.entityName,
    child: _body(),
  );

  Widget _body() {
    if (_loading) return const Center(child: CupertinoActivityIndicator());
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.greyple),
              ),
              const SizedBox(height: 12),
              CupertinoButton(onPressed: _load, child: const Text('Повторить')),
            ],
          ),
        ),
      );
    }
    if (_entries.isEmpty) {
      return Center(
        child: Text(
          'Активных ограничений нет',
          style: TextStyle(color: AppColors.greyple),
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
      itemCount: _entries.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) => _entryCard(_entries[index]),
    );
  }

  Widget _entryCard(EntityModeration entry) {
    final name = entry.displayName?.trim().isNotEmpty == true
        ? entry.displayName!.trim()
        : (entry.username ?? 'Участник');
    final isSaving = _savingIds.contains(entry.id);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.lightGrey,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              BuildAvatar(
                url: entry.pathImage ?? '',
                wh: 38,
                size: 22,
                isBookmark: false,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.mediumTextStyle.copyWith(
                        color: AppColors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      entry.isBan ? 'Блокировка' : 'Ограничение сообщений',
                      style: TextStyle(color: AppColors.greyple, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (entry.reason?.trim().isNotEmpty == true) ...[
            const SizedBox(height: 10),
            Text(
              entry.reason!.trim(),
              style: TextStyle(color: AppColors.white, fontSize: 13),
            ),
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Text(
                  _expiryLabel(entry.expiresAt),
                  style: TextStyle(color: AppColors.greyple, fontSize: 12),
                ),
              ),
              CupertinoButton(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                minimumSize: const Size(0, 36),
                onPressed: isSaving ? null : () => _clear(entry),
                child: isSaving
                    ? const CupertinoActivityIndicator()
                    : Text(entry.isBan ? 'Разблокировать' : 'Размутить'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _expiryLabel(String? value) {
    if (value == null || value.isEmpty) return 'Бессрочно';
    final date = DateTime.tryParse(value)?.toLocal();
    if (date == null) return 'До $value';
    String twoDigits(int number) => number.toString().padLeft(2, '0');
    return 'До ${twoDigits(date.day)}.${twoDigits(date.month)}.${date.year} '
        '${twoDigits(date.hour)}:${twoDigits(date.minute)}';
  }
}
