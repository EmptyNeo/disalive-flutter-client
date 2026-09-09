import 'dart:io';
import 'dart:typed_data';
import 'package:disalive/app/di/di.dart';
import 'package:disalive/domain/repositories/permission_repository.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:image_picker/image_picker.dart';
import 'package:disalive/app/theme/app_theme.dart';

class MediaPickerBottomSheet extends StatefulWidget {
  final RequestType initialType;
  final bool allowMultiple;

  const MediaPickerBottomSheet({
    super.key,
    this.initialType = RequestType.image,
    this.allowMultiple = false,
  });

  static Future<List<File>?> open({
    required BuildContext context,
    RequestType type = RequestType.image,
    bool allowMultiple = false,
  }) {
    return showCupertinoModalPopup<List<File>?>(
      context: context,
      builder: (context) => MediaPickerBottomSheet(
        initialType: type,
        allowMultiple: allowMultiple,
      ),
    );
  }

  @override
  State<MediaPickerBottomSheet> createState() => _MediaPickerBottomSheetState();
}

class _MediaPickerBottomSheetState extends State<MediaPickerBottomSheet>
    with SingleTickerProviderStateMixin {
  List<AssetEntity> _assets = [];
  final Set<AssetEntity> _selectedAssets = {};
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  int _currentPage = 0;
  RequestType _currentType = RequestType.image;

  late final AnimationController _slideController;
  double _dragExtent = 0;

  static const double _dismissDistance = 120;
  static const double _dismissVelocity = 700;

  @override
  void initState() {
    super.initState();
    _currentType = widget.initialType;
    _fetchAssets();
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
  }

  Future<void> _fetchAssets() async {
    setState(() {
      _isLoading = true;
      _assets = [];
      _currentPage = 0;
      _hasMore = true;
    });
    _selectedAssets.clear();

    final permissionService = sl<PermissionRepository>();
    final hasPhotos = await permissionService.requestPhotosPermission();

    if (!hasPhotos) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    await _loadPage();
  }

  Future<void> _loadPage() async {
    // Явно просим у PhotoManager сортировку "сначала новые" — без этого
    // на части устройств альбом "Все" отдаётся от старых к новым, и тогда
    // даже постраничная сортировка внутри одной страницы не помогает:
    // первой страницей всё равно приходят самые старые фото.
    final albums = await PhotoManager.getAssetPathList(
      type: _currentType,
      onlyAll: true,
      filterOption: FilterOptionGroup(
        orders: [OrderOption(type: OrderOptionType.createDate, asc: false)],
      ),
    );

    if (albums.isEmpty) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasMore = false;
        });
      }
      return;
    }

    final recentAlbum = albums.first;
    final assets = await recentAlbum.getAssetListPaged(
      page: _currentPage,
      size: 60,
    );

    if (mounted) {
      setState(() {
        // Страницы уже приходят отсортированными от новых к старым,
        // дополнительная сортировка здесь не нужна.
        _assets.addAll(assets);
        _hasMore = assets.length == 60;
        _currentPage++;
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore || !_hasMore) return;
    setState(() => _isLoadingMore = true);
    await _loadPage();
    if (mounted) setState(() => _isLoadingMore = false);
  }

  Future<void> _takePhoto() async {
    final permissionService = sl<PermissionRepository>();
    final hasCamera = await permissionService.requestCameraPermission();
    if (!hasCamera) return;

    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.camera);
    if (pickedFile != null && mounted) {
      Navigator.of(context).pop([File(pickedFile.path)]);
    }
  }

  Future<void> _pickFiles() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: widget.allowMultiple,
      type: FileType.any,
    );
    if (result != null && mounted) {
      final files = result.paths
          .where((p) => p != null)
          .map((p) => File(p!))
          .toList();
      if (files.isNotEmpty) {
        Navigator.of(context).pop(files);
      }
    }
  }

  Future<void> _selectAsset(AssetEntity asset) async {
    if (widget.allowMultiple) {
      // Множественный выбор
      setState(() {
        if (_selectedAssets.contains(asset)) {
          _selectedAssets.remove(asset);
        } else {
          _selectedAssets.add(asset);
        }
      });
    } else {
      // Одиночный выбор - сразу возвращаем
      final file = await asset.file;
      if (file != null && mounted) {
        Navigator.of(context).pop([file]);
      }
    }
  }

  Future<void> _confirmSelection() async {
    if (_selectedAssets.isEmpty) return;

    final files = <File>[];
    for (final asset in _selectedAssets) {
      final file = await asset.file;
      if (file != null) {
        files.add(file);
      }
    }

    if (files.isNotEmpty && mounted) {
      Navigator.of(context).pop(files);
    }
  }

  @override
  void dispose() {
    _slideController.dispose();
    super.dispose();
  }

  void _handleGrabberDragUpdate(DragUpdateDetails details) {
    // Тянуть вверх выше исходной позиции нельзя — карточка не "прыгает"
    // выше своего места в разложенном виде.
    if (_dragExtent <= 0 && details.delta.dy < 0) return;
    setState(() {
      _dragExtent = (_dragExtent + details.delta.dy).clamp(0, 600);
    });
  }

  void _handleGrabberDragEnd(DragEndDetails details) {
    final velocity = details.velocity.pixelsPerSecond.dy;
    if (_dragExtent > _dismissDistance || velocity > _dismissVelocity) {
      _dismissSheet();
    } else {
      _snapBack();
    }
  }

  void _snapBack() {
    final animation = Tween<double>(begin: _dragExtent, end: 0).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
    );
    void listener() => setState(() => _dragExtent = animation.value);
    animation.addListener(listener);
    _slideController
        .forward(from: 0)
        .whenComplete(() => animation.removeListener(listener));
  }

  // Довозим карточку своим Transform полностью за экран и только потом
  // вызываем pop — иначе встроенная exit-анимация showCupertinoModalPopup
  // стартует с нулевого смещения поверх уже сдвинутой карточки, и получается
  // рывок. Так к моменту pop() карточки уже не видно, и он проходит незаметно.
  void _dismissSheet() {
    final screenHeight = MediaQuery.sizeOf(context).height;
    final animation = Tween<double>(
      begin: _dragExtent,
      end: screenHeight,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeIn));
    void listener() => setState(() => _dragExtent = animation.value);
    animation.addListener(listener);
    _slideController.forward(from: 0).whenComplete(() {
      animation.removeListener(listener);
      if (mounted) {
        FocusScope.of(context).unfocus();
        Navigator.of(context).pop();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        // Добавляем слушатель скролла для пагинации
        scrollController.addListener(() {
          if (scrollController.position.pixels >=
              scrollController.position.maxScrollExtent - 200) {
            _loadMore();
          }
        });

        return Transform.translate(
          offset: Offset(0, _dragExtent),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.mainBackground,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
              border: Border.all(
                color: AppColors.white.withValues(alpha: 0.12),
                width: 1,
              ),
            ),
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
              child: Stack(
                children: [
                  Column(
                    children: [
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onVerticalDragUpdate: _handleGrabberDragUpdate,
                        onVerticalDragEnd: _handleGrabberDragEnd,
                        child: _buildHeader(),
                      ),

                      // Сетка
                      Expanded(
                        child: _isLoading
                            ? const Center(child: CupertinoActivityIndicator())
                            : GridView.builder(
                                controller: scrollController,
                                padding: const EdgeInsets.all(2),
                                gridDelegate:
                                    const SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 3,
                                      crossAxisSpacing: 2,
                                      mainAxisSpacing: 2,
                                    ),
                                itemCount:
                                    _assets.length + 2 + (_hasMore ? 1 : 0),
                                itemBuilder: (context, index) {
                                  if (index == 0) return _buildCameraTile();
                                  if (index == 1) return _buildFileTile();
                                  if (index >= _assets.length + 2) {
                                    return const Center(
                                      child: CupertinoActivityIndicator(
                                        radius: 9,
                                      ),
                                    );
                                  }

                                  final asset = _assets[index - 2];
                                  final isSelected = _selectedAssets.contains(
                                    asset,
                                  );

                                  return GestureDetector(
                                    onTap: () => _selectAsset(asset),
                                    child: Stack(
                                      fit: StackFit.expand,
                                      children: [
                                        AssetThumbnail(asset: asset),
                                        if (widget.allowMultiple)
                                          Positioned(
                                            top: 4,
                                            right: 4,
                                            child: Container(
                                              width: 22,
                                              height: 22,
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                color: isSelected
                                                    ? AppColors.blurple
                                                    : CupertinoColors.black
                                                          .withValues(
                                                            alpha: 0.45,
                                                          ),
                                                border: Border.all(
                                                  color: CupertinoColors.white
                                                      .withValues(alpha: 0.85),
                                                  width: 1.5,
                                                ),
                                              ),
                                              child: isSelected
                                                  ? const Icon(
                                                      CupertinoIcons.checkmark,
                                                      color:
                                                          CupertinoColors.white,
                                                      size: 13,
                                                    )
                                                  : null,
                                            ),
                                          ),
                                        if (asset.type == AssetType.video)
                                          const Positioned(
                                            bottom: 4,
                                            right: 4,
                                            child: Icon(
                                              CupertinoIcons.play_circle_fill,
                                              color: CupertinoColors.white,
                                              size: 20,
                                            ),
                                          ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                      ),
                    ],
                  ),

                  // Кнопка "Готово"
                  Positioned(
                    bottom: 16,
                    right: 16,
                    child: AnimatedScale(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeOutBack,
                      scale: _selectedAssets.isNotEmpty ? 1.0 : 0.0,
                      child: GestureDetector(
                        onTap: _confirmSelection,
                        child: Container(
                          width: 54,
                          height: 54,
                          decoration: BoxDecoration(
                            color: AppColors.blurple,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: CupertinoColors.white.withValues(
                                alpha: 0.18,
                              ),
                              width: 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: CupertinoColors.black.withValues(
                                  alpha: 0.3,
                                ),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Center(
                            child: _selectedAssets.length > 1
                                ? Text(
                                    '${_selectedAssets.length}',
                                    style: AppText.mediumTextStyle.copyWith(
                                      color: AppColors.onBlurple,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 17,
                                    ),
                                  )
                                : Icon(
                                    CupertinoIcons.checkmark,
                                    color: AppColors.onBlurple,
                                    size: 22,
                                  ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: AppColors.white.withValues(alpha: 0.08),
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 36,
            height: 4,
            margin: const EdgeInsets.only(bottom: 14),
            decoration: BoxDecoration(
              color: AppColors.white.withValues(alpha: 0.24),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Галерея',
                style: AppText.highTextStyle.copyWith(
                  color: AppColors.white,
                  fontSize: 18,
                ),
              ),
              _buildTypeSelector(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTypeSelector() {
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: AppColors.actionGrey,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: AppColors.white.withValues(alpha: 0.08),
          width: 1,
        ),
      ),
      child: CupertinoSlidingSegmentedControl<RequestType>(
        groupValue: _currentType,
        backgroundColor: CupertinoColors.transparent,
        thumbColor: AppColors.blurple,
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
        children: {
          RequestType.image: _buildSegmentLabel('Фото', RequestType.image),
          RequestType.video: _buildSegmentLabel('Видео', RequestType.video),
          RequestType.all: _buildSegmentLabel('Всё', RequestType.all),
        },
        onValueChanged: (val) {
          if (val != null && val != _currentType) {
            setState(() => _currentType = val);
            _fetchAssets();
          }
        },
      ),
    );
  }

  Widget _buildSegmentLabel(String label, RequestType type) {
    final isSelected = type == _currentType;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Text(
        label,
        style: AppText.lowTextStyle.copyWith(
          color: isSelected ? AppColors.onBlurple : AppColors.greyple,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildCameraTile() {
    return GestureDetector(
      onTap: _takePhoto,
      child: Container(
        color: AppColors.glassPanelBottom,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              CupertinoIcons.camera_fill,
              color: AppColors.blurple,
              size: 28,
            ),
            const SizedBox(height: 8),
            Text(
              'Камера',
              style: AppText.lowTextStyle.copyWith(color: AppColors.greyple),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFileTile() {
    return GestureDetector(
      onTap: _pickFiles,
      child: Container(
        color: AppColors.glassPanelBottom,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(CupertinoIcons.doc_fill, color: AppColors.blurple, size: 28),
            const SizedBox(height: 8),
            Text(
              'Файлы',
              style: AppText.lowTextStyle.copyWith(color: AppColors.greyple),
            ),
          ],
        ),
      ),
    );
  }
}

class AssetThumbnail extends StatefulWidget {
  final AssetEntity asset;

  const AssetThumbnail({super.key, required this.asset});

  @override
  State<AssetThumbnail> createState() => _AssetThumbnailState();
}

class _AssetThumbnailState extends State<AssetThumbnail> {
  late Future<Uint8List?> _thumbnailFuture;

  @override
  void initState() {
    super.initState();
    _thumbnailFuture = widget.asset.thumbnailDataWithSize(
      const ThumbnailSize(200, 200),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uint8List?>(
      future: _thumbnailFuture,
      builder: (_, snapshot) {
        if (snapshot.connectionState == ConnectionState.done &&
            snapshot.data != null) {
          return Image.memory(snapshot.data!, fit: BoxFit.cover);
        }
        return Container(color: AppColors.actionGrey);
      },
    );
  }
}
