import 'package:disalive/app/theme/app_theme.dart';
import 'package:disalive/domain/models/sticker_pack.dart';
import 'package:disalive/presentation/features/stickers/bloc/stickers_pack_bloc.dart';
import 'package:disalive/presentation/widgets/toasts/custom_toast.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class StickerPackModal extends StatefulWidget {
  final StickerPack? existingPack;

  const StickerPackModal({super.key, this.existingPack});

  static Future<void> open(BuildContext context, {StickerPack? existingPack}) {
    final stickersPackBloc = context.read<StickersPackBloc>();
    return showCupertinoModalPopup<void>(
      context: context,
      builder: (context) => BlocProvider.value(
        value: stickersPackBloc,
        child: StickerPackModal(existingPack: existingPack),
      ),
    );
  }

  @override
  State<StickerPackModal> createState() => _StickerPackModalState();
}

class _StickerPackModalState extends State<StickerPackModal> {
  late TextEditingController _controller;
  final _focusNode = FocusNode();
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.existingPack?.name ?? '');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _handleSubmit() {
    final name = _controller.text.trim();
    if (name.isEmpty) {
      CustomToast.show(context: context, message: 'Введите название набора');
      return;
    }
    if (name.length > 50) {
      CustomToast.show(context: context, message: 'Максимум 50 символов');
      return;
    }

    setState(() => _isProcessing = true);

    if (widget.existingPack == null) {
      context.read<StickersPackBloc>().add(CreateStickerPack(name));
    } else {
      context.read<StickersPackBloc>().add(
        UpdateStickerPack(widget.existingPack!.id, name),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existingPack != null;

    return BlocListener<StickersPackBloc, StickersPackState>(
      listener: (context, state) {
        if (state is StickersPackError) {
          setState(() => _isProcessing = false);
          CustomToast.show(context: context, message: state.failure.message);
        } else if (state is StickersPackLoaded) {
          Navigator.of(context).pop();
        }
      },
      child: Padding(
        // 🎯 Сдвигаем весь блок вверх при появлении клавиатуры
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AppColors.glassPanelTop,
                      AppColors.glassPanelBottom,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: AppColors.divider.withValues(alpha: 0.6),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: CupertinoColors.black.withValues(alpha: 0.35),
                      blurRadius: 30,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 🎯 Граббер (полоска сверху)
                    const Padding(
                      padding: EdgeInsets.only(top: 10, bottom: 8),
                      child: Center(child: _GrabberHandle()),
                    ),

                    // 🎯 ОРИГИНАЛЬНЫЙ ЗАГОЛОВОК (как ты просил)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                      child: Text(
                        isEdit
                            ? 'Редактировать набор'
                            : 'Создать набор стикеров',
                        style: AppText.highTextStyle.copyWith(
                          color: AppColors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),

                    // 🎯 Поле ввода и кнопки
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          CupertinoTextField(
                            controller: _controller,
                            focusNode: _focusNode,
                            placeholder: 'Название набора',
                            maxLength: 50,
                            style: AppText.mediumTextStyle.copyWith(
                              color: AppColors.white,
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.actionGrey,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: AppColors.divider,
                                width: 1,
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              Expanded(
                                child: CupertinoButton(
                                  color: AppColors.actionGrey,
                                  borderRadius: BorderRadius.circular(12),
                                  onPressed: _isProcessing
                                      ? null
                                      : () {
                                          _focusNode.unfocus();
                                          Navigator.of(context).pop();
                                        },
                                  child: Text(
                                    'Отмена',
                                    style: TextStyle(color: AppColors.white),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: CupertinoButton.filled(
                                  borderRadius: BorderRadius.circular(12),
                                  onPressed: _isProcessing
                                      ? null
                                      : _handleSubmit,
                                  child: _isProcessing
                                      ? const SizedBox(
                                          height: 20,
                                          width: 20,
                                          child: CupertinoActivityIndicator(
                                            color: CupertinoColors.white,
                                          ),
                                        )
                                      : Text(isEdit ? 'Сохранить' : 'Создать'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GrabberHandle extends StatelessWidget {
  const _GrabberHandle();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 5,
      decoration: BoxDecoration(
        color: AppColors.greyple.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(3),
      ),
    );
  }
}
