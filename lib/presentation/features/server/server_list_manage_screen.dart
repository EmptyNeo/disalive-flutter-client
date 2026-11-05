import 'package:disalive/app/theme/app_theme.dart';
import 'package:disalive/domain/models/server.dart';
import 'package:disalive/domain/models/server_list_layout.dart';
import 'package:disalive/presentation/features/server/bloc/server_list_cubit.dart';
import 'package:disalive/presentation/widgets/toasts/custom_toast.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart'
    show DefaultMaterialLocalizations, ReorderableListView;
import 'package:flutter_bloc/flutter_bloc.dart';

class ServerListManageScreen extends StatefulWidget {
  const ServerListManageScreen({
    super.key,
    required this.cubit,
    required this.servers,
  });
  final ServerListCubit cubit;
  final List<Server> servers;

  static Future<void> open(
    BuildContext context,
    ServerListCubit cubit,
    List<Server> servers,
  ) => Navigator.of(context).push(
    CupertinoPageRoute<void>(
      builder: (_) => ServerListManageScreen(cubit: cubit, servers: servers),
    ),
  );

  @override
  State<ServerListManageScreen> createState() => _ServerListManageScreenState();
}

class _ServerListManageScreenState extends State<ServerListManageScreen> {
  int? _folderId;
  Server? _server(int id) {
    for (final server in widget.servers) {
      if (server.id == id) return server;
    }
    return null;
  }

  Future<void> _editFolderName({int? folderId, String? currentName}) async {
    final controller = TextEditingController(text: currentName ?? '');
    final name = await showCupertinoDialog<String>(
      context: context,
      builder: (dialogContext) => CupertinoAlertDialog(
        title: Text(folderId == null ? 'Новая папка' : 'Переименовать папку'),
        content: Padding(
          padding: const EdgeInsets.only(top: 12),
          child: CupertinoTextField(
            controller: controller,
            autofocus: true,
            maxLength: 50,
            placeholder: 'Название папки',
          ),
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Отмена'),
          ),
          CupertinoDialogAction(
            onPressed: () =>
                Navigator.pop(dialogContext, controller.text.trim()),
            child: const Text('Сохранить'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (!mounted || name == null) return;
    if (name.isEmpty || name.runes.length > 50) {
      CustomToast.open(
        context: context,
        message: 'Название папки должно содержать от 1 до 50 символов',
      );
      return;
    }
    if (folderId == null) {
      await widget.cubit.createFolder(name);
    } else {
      await widget.cubit.renameFolder(folderId, name);
    }
  }

  Future<void> _moveServer(int serverId, ServerListLayout layout) async {
    final destination = await showCupertinoModalPopup<int>(
      context: context,
      builder: (popupContext) => CupertinoActionSheet(
        title: const Text('Переместить сервер'),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () => Navigator.pop(popupContext, 0),
            child: const Text('Без папки'),
          ),
          for (final folder in layout.items.where(
            (item) => item.isFolder && item.folderId != null,
          ))
            CupertinoActionSheetAction(
              onPressed: () => Navigator.pop(popupContext, folder.folderId),
              child: Text(folder.name ?? 'Папка'),
            ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(popupContext),
          child: const Text('Отмена'),
        ),
      ),
    );
    if (destination != null) {
      await widget.cubit.moveServer(
        serverId,
        folderId: destination == 0 ? null : destination,
      );
    }
  }

  Future<void> _folderActions(ServerListItem folder) async {
    final action = await showCupertinoModalPopup<String>(
      context: context,
      builder: (popupContext) => CupertinoActionSheet(
        title: Text(folder.name ?? 'Папка'),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () => Navigator.pop(popupContext, 'rename'),
            child: const Text('Переименовать'),
          ),
          CupertinoActionSheetAction(
            onPressed: () => Navigator.pop(popupContext, 'delete'),
            isDestructiveAction: true,
            child: const Text('Удалить папку'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(popupContext),
          child: const Text('Отмена'),
        ),
      ),
    );
    if (!mounted || folder.folderId == null) return;
    if (action == 'rename') {
      await _editFolderName(
        folderId: folder.folderId,
        currentName: folder.name,
      );
    } else if (action == 'delete') {
      final confirmed = await showCupertinoDialog<bool>(
        context: context,
        builder: (dialogContext) => CupertinoAlertDialog(
          title: const Text('Удалить папку?'),
          content: const Text('Серверы из папки останутся в общем списке.'),
          actions: [
            CupertinoDialogAction(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Отмена'),
            ),
            CupertinoDialogAction(
              isDestructiveAction: true,
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Удалить'),
            ),
          ],
        ),
      );
      if (confirmed != true || !mounted) return;
      await widget.cubit.deleteFolder(folder.folderId!);
      if (mounted && _folderId == folder.folderId) {
        setState(() => _folderId = null);
      }
    }
  }

  @override
  Widget build(
    BuildContext context,
  ) => BlocConsumer<ServerListCubit, ServerListState>(
    bloc: widget.cubit,
    listener: (context, state) {
      if (state.error != null) {
        CustomToast.open(context: context, message: state.error!);
      }
    },
    builder: (context, state) {
      final folder = state.layout.items
          .where((item) => item.isFolder && item.folderId == _folderId)
          .firstOrNull;
      final isFolderView = _folderId != null && folder != null;
      final rootItems = state.layout.items;
      final children = folder?.servers ?? const <int>[];
      return CupertinoPageScaffold(
        backgroundColor: AppColors.mainBackground,
        navigationBar: CupertinoNavigationBar(
          backgroundColor: AppColors.mainBackground,
          middle: Text(
            isFolderView ? folder.name ?? 'Папка' : 'Список серверов',
          ),
          leading: isFolderView
              ? CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: () => setState(() => _folderId = null),
                  child: const Icon(CupertinoIcons.back),
                )
              : null,
          trailing: isFolderView
              ? CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: state.saving ? null : () => _folderActions(folder),
                  child: const Icon(CupertinoIcons.ellipsis),
                )
              : CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: !state.loaded || state.saving
                      ? null
                      : () => _editFolderName(),
                  child: const Icon(CupertinoIcons.folder_badge_plus),
                ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              if (!isFolderView && state.loaded)
                Align(
                  alignment: Alignment.centerRight,
                  child: CupertinoButton(
                    onPressed: state.saving ? null : () => _editFolderName(),
                    child: const Text('Новая папка'),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
                child: Text(
                  'Зажмите значок справа, чтобы изменить порядок. Через «•••» переместите сервер в папку.',
                  style: TextStyle(color: AppColors.greyple, fontSize: 13),
                ),
              ),
              if (state.error != null)
                CupertinoButton(
                  onPressed: state.saving ? null : widget.cubit.load,
                  child: const Text('Не удалось обновить список · Повторить'),
                ),
              if (state.saving) const CupertinoActivityIndicator(),
              Expanded(
                child: !state.loaded
                    ? const Center(child: CupertinoActivityIndicator())
                    : Localizations.override(
                        context: context,
                        delegates: const [
                          DefaultMaterialLocalizations.delegate,
                        ],
                        child: ReorderableListView.builder(
                          buildDefaultDragHandles: false,
                          itemCount: isFolderView
                              ? children.length
                              : rootItems.length,
                          onReorder: state.saving
                              ? (_, _) {}
                              : (oldIndex, newIndex) {
                                  if (isFolderView) {
                                    widget.cubit.reorderFolder(
                                      folder.folderId!,
                                      oldIndex,
                                      newIndex,
                                    );
                                  } else {
                                    widget.cubit.reorderRoot(
                                      oldIndex,
                                      newIndex,
                                    );
                                  }
                                },
                          itemBuilder: (context, index) {
                            final item = isFolderView
                                ? ServerListItem.server(children[index])
                                : rootItems[index];
                            final server = item.serverId == null
                                ? null
                                : _server(item.serverId!);
                            return Container(
                              key: ValueKey(
                                isFolderView
                                    ? 'child_${item.serverId}'
                                    : item.isFolder
                                    ? 'folder_${item.folderId}'
                                    : 'server_${item.serverId}',
                              ),
                              margin: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.lightGrey,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Row(
                                children: [
                                  const SizedBox(width: 14),
                                  Icon(
                                    item.isFolder
                                        ? CupertinoIcons.folder_fill
                                        : CupertinoIcons.group_solid,
                                    color: AppColors.blurple,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: CupertinoButton(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 13,
                                      ),
                                      alignment: Alignment.centerLeft,
                                      onPressed: item.isFolder
                                          ? () => setState(
                                              () => _folderId = item.folderId,
                                            )
                                          : () {},
                                      child: Text(
                                        item.isFolder
                                            ? '${item.name} · ${item.servers.length}'
                                            : (server?.name ?? 'Сервер'),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: AppColors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                  if (!item.isFolder)
                                    CupertinoButton(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                      ),
                                      onPressed: state.saving
                                          ? null
                                          : () => _moveServer(
                                              item.serverId!,
                                              state.layout,
                                            ),
                                      child: const Icon(
                                        CupertinoIcons.ellipsis,
                                      ),
                                    ),
                                  if (item.isFolder)
                                    CupertinoButton(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                      ),
                                      onPressed: state.saving
                                          ? null
                                          : () => _folderActions(item),
                                      child: const Icon(
                                        CupertinoIcons.ellipsis,
                                      ),
                                    ),
                                  ReorderableDelayedDragStartListener(
                                    index: index,
                                    child: Padding(
                                      padding: const EdgeInsets.fromLTRB(
                                        8,
                                        12,
                                        14,
                                        12,
                                      ),
                                      child: Icon(
                                        CupertinoIcons.line_horizontal_3,
                                        color: AppColors.greyple,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
