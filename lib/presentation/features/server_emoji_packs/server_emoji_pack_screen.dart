import 'dart:io';

import 'package:disalive/app/di/di.dart';
import 'package:disalive/app/theme/app_theme.dart';
import 'package:disalive/domain/models/emojis/emoji_sheet_data.dart';
import 'package:disalive/domain/models/server.dart';
import 'package:disalive/domain/models/server_emoji_pack.dart';
import 'package:disalive/presentation/features/server_emoji_packs/bloc/server_emoji_packs_bloc.dart';
import 'package:disalive/presentation/features/role_members/widgets/role_screen_shell.dart';
import 'package:disalive/presentation/navigation/swipe_to_dismiss_route.dart';
import 'package:disalive/presentation/widgets/emoji_widget.dart';
import 'package:disalive/presentation/widgets/media_picker_bottom_sheet.dart';
import 'package:disalive/presentation/widgets/toasts/custom_toast.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:photo_manager/photo_manager.dart';

class ServerEmojiPackScreen extends StatefulWidget {
  const ServerEmojiPackScreen({super.key, required this.server});

  final Server server;

  static Future<void> open(BuildContext context, {required Server server}) {
    return SwipeToDismissRoute.push(
      context,
      (_) => BlocProvider(
        create: (_) =>
            sl<ServerEmojiPacksBloc>()..add(LoadServerEmojiPacks(server.id!)),
        child: ServerEmojiPackScreen(server: server),
      ),
    );
  }

  @override
  State<ServerEmojiPackScreen> createState() => _ServerEmojiPackScreenState();
}

class _ServerEmojiPackScreenState extends State<ServerEmojiPackScreen> {
  final TextEditingController _nameController = TextEditingController();
  File? _selectedFile;
  String? _selectedFileName;
  bool _uploadPending = false;
  String? _lastFailureMessage;

  int get _serverId => widget.server.id!;
  bool get _canManage => widget.server.isServerOwner;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _selectFile() async {
    final files = await MediaPickerBottomSheet.open(
      context: context,
      type: RequestType.image,
      onlyInitialType: true,
      allowMultiple: false,
      convertToJpg: false,
    );
    if (!mounted || files == null || files.isEmpty) return;
    final file = files.first;
    if (await file.length() > 1024 * 1024) {
      _showError('Максимальный размер эмодзи — 1 МБ');
      return;
    }
    setState(() {
      _selectedFile = file;
      _selectedFileName = file.path.split(RegExp(r'[/\\]')).last;
    });
  }

  void _upload() {
    final name = _nameController.text.trim();
    final file = _selectedFile;
    if (name.isEmpty || file == null) {
      _showError('Укажите название и выберите изображение');
      return;
    }
    context.read<ServerEmojiPacksBloc>().add(
      UploadServerEmoji(serverId: _serverId, name: name, file: file),
    );
    setState(() => _uploadPending = true);
  }

  void _showError(String message) {
    CustomToast.open(context: context, message: message);
  }

  List<EmojiSheetData> _buildPackSheets(ServerEmojiPack pack) {
    return pack.jsons ?? const [];
  }

  Widget _buildEmojiGrid(ServerEmojiPack pack, bool isWorking) {
    final emojis = <({EmojiSheetData sheet, String id})>[];
    for (final sheet in _buildPackSheets(pack)) {
      for (final id in sheet.emojis.keys) {
        emojis.add((sheet: sheet, id: id));
      }
    }
    if (emojis.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Text(
          'Здесь появятся загруженные эмодзи.',
          style: TextStyle(color: AppColors.greyple),
        ),
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth < 430 ? 3 : 5;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(vertical: 12),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: columns == 3 ? 0.86 : 0.78,
          ),
          itemCount: emojis.length,
          itemBuilder: (context, index) {
            final entry = emojis[index];
            final emoji = entry.sheet.emojis[entry.id]!;
            final canDelete = _canManage && int.tryParse(emoji.id) != null;
            return Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.lightGrey,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.divider),
              ),
              child: Column(
                children: [
                  Expanded(
                    child: Center(
                      child: EmojiWidget(
                        emoji: emoji,
                        sheetData: entry.sheet,
                        size: constraints.maxWidth < 430 ? 48 : 42,
                        animate: true,
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          emoji.name ?? emoji.id,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.greyple,
                          ),
                        ),
                      ),
                      if (canDelete)
                        SizedBox(
                          width: 28,
                          height: 28,
                          child: CupertinoButton(
                            padding: EdgeInsets.zero,
                            minimumSize: Size.zero,
                            onPressed: isWorking
                                ? null
                                : () =>
                                      context.read<ServerEmojiPacksBloc>().add(
                                        DeleteServerEmoji(
                                          serverId: _serverId,
                                          emojiId: int.parse(emoji.id),
                                        ),
                                      ),
                            child: Icon(
                              CupertinoIcons.trash,
                              size: 16,
                              color: AppColors.errorRed,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildContent(ServerEmojiPacksState state) {
    if (state.status == ServerEmojiPacksStatus.loading && state.packs.isEmpty) {
      return const Center(child: CupertinoActivityIndicator());
    }
    if (state.status == ServerEmojiPacksStatus.failure && state.packs.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              state.failure?.message ?? 'Не удалось загрузить набор эмодзи',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.greyple),
            ),
            CupertinoButton(
              onPressed: () => context.read<ServerEmojiPacksBloc>().add(
                LoadServerEmojiPacks(_serverId),
              ),
              child: const Text('Повторить'),
            ),
          ],
        ),
      );
    }

    final pack = state.packs.firstOrNull;
    if (pack == null) {
      return ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'В этом сервере пока нет набора эмодзи.',
            style: TextStyle(color: AppColors.greyple),
          ),
          if (_canManage) ...[
            const SizedBox(height: 18),
            _ActionButton(
              label: 'Создать набор эмодзи',
              isLoading: state.isWorking,
              onPressed: state.isWorking
                  ? null
                  : () => context.read<ServerEmojiPacksBloc>().add(
                      CreateServerEmojiPack(_serverId),
                    ),
            ),
          ],
        ],
      );
    }

    final packId = pack.id;
    final installed = pack.installed == true;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                pack.name ?? 'Набор эмодзи сервера',
                style: TextStyle(
                  color: AppColors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Text(
              '${_buildPackSheets(pack).fold<int>(0, (sum, sheet) => sum + sheet.emojis.length)} / 100',
              style: TextStyle(color: AppColors.greyple),
            ),
          ],
        ),
        if (packId != null) ...[
          const SizedBox(height: 12),
          _ActionButton(
            label: installed ? 'Удалить набор у себя' : 'Добавить набор к себе',
            isLoading: state.isWorking,
            onPressed: state.isWorking
                ? null
                : () => context.read<ServerEmojiPacksBloc>().add(
                    SetServerEmojiPackInstalled(
                      serverId: _serverId,
                      packId: packId,
                      installed: !installed,
                    ),
                  ),
          ),
        ],
        const SizedBox(height: 16),
        if (_canManage) ...[
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.white.withValues(alpha: 0.035),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.divider),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Добавить эмодзи',
                  style: TextStyle(
                    color: AppColors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 10),
                CupertinoTextField(
                  controller: _nameController,
                  placeholder: 'Название эмодзи',
                  maxLength: 50,
                  style: TextStyle(color: AppColors.white),
                  placeholderStyle: TextStyle(color: AppColors.greyple),
                  decoration: BoxDecoration(
                    color: AppColors.lightGrey,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.divider),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                ),
                const SizedBox(height: 10),
                CupertinoButton(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  color: AppColors.lightGrey,
                  onPressed: state.isWorking ? null : _selectFile,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _selectedFile == null
                            ? CupertinoIcons.photo_on_rectangle
                            : CupertinoIcons.checkmark_circle_fill,
                        size: 18,
                        color: _selectedFile == null
                            ? AppColors.greyple
                            : AppColors.green,
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          _selectedFileName ?? 'Выбрать изображение или GIF',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: AppColors.white),
                        ),
                      ),
                    ],
                  ),
                ),
                if (_selectedFile != null) ...[
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      height: 104,
                      width: double.infinity,
                      color: AppColors.lightGrey,
                      alignment: Alignment.center,
                      child: Image.file(
                        _selectedFile!,
                        fit: BoxFit.contain,
                        errorBuilder: (_, _, _) => Icon(
                          CupertinoIcons.photo,
                          color: AppColors.greyple,
                          size: 32,
                        ),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                Text(
                  'PNG, JPG, WEBP или GIF · до 1 МБ',
                  style: TextStyle(color: AppColors.greyple, fontSize: 12),
                ),
                const SizedBox(height: 10),
                _ActionButton(
                  label: 'Загрузить эмодзи',
                  isLoading: state.isWorking,
                  onPressed: state.isWorking || _uploadPending ? null : _upload,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
        if (_buildPackSheets(pack).isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              'Эмодзи набора',
              style: TextStyle(
                color: AppColors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        _buildEmojiGrid(pack, state.isWorking),
        if (_canManage)
          CupertinoButton(
            padding: const EdgeInsets.symmetric(vertical: 16),
            onPressed: state.isWorking
                ? null
                : () => context.read<ServerEmojiPacksBloc>().add(
                    DeleteServerEmojiPack(_serverId),
                  ),
            child: Text(
              'Удалить набор эмодзи',
              style: TextStyle(color: AppColors.errorRed),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ServerEmojiPacksBloc, ServerEmojiPacksState>(
      listenWhen: (previous, current) =>
          previous.failure != current.failure ||
          (_uploadPending && previous.isWorking && !current.isWorking),
      listener: (context, state) {
        final failureMessage = state.failure?.message;
        if (failureMessage != null && failureMessage != _lastFailureMessage) {
          _lastFailureMessage = failureMessage;
          _showError(failureMessage);
        } else if (failureMessage == null) {
          _lastFailureMessage = null;
        }
        if (_uploadPending && !state.isWorking) {
          setState(() {
            _uploadPending = false;
            if (state.failure == null) {
              _nameController.clear();
              _selectedFile = null;
              _selectedFileName = null;
            }
          });
        }
      },
      builder: (context, state) => RoleScreenShell(
        title: 'Эмодзи сервера',
        subtitle: widget.server.name ?? 'Сервер',
        child: _buildContent(state),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.onPressed,
    this.isLoading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    child: CupertinoButton.filled(
      onPressed: onPressed,
      child: isLoading
          ? const CupertinoActivityIndicator(color: CupertinoColors.white)
          : Text(label),
    ),
  );
}
