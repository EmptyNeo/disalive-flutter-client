import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:disalive/app/theme/app_theme.dart';
import 'package:disalive/presentation/navigation/swipe_to_dismiss_route.dart';
import 'package:disalive/presentation/widgets/custom_back_button.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';

class BannerCropModal extends StatefulWidget {
  final File file;
  static const double aspectRatio = 350 / 150;

  const BannerCropModal({super.key, required this.file});

  static Future<File?> open(BuildContext context, {required File file}) {
    return SwipeToDismissRoute.push<File>(
      context,
          (context) => BannerCropModal(file: file),
    );
  }

  @override
  State<BannerCropModal> createState() => _BannerCropModalState();
}

class _BannerCropModalState extends State<BannerCropModal> {
  ui.Image? _image;
  bool _isLoading = true;

  double _naturalWidth = 0;
  double _naturalHeight = 0;
  double _scale = 1.0;
  double _tx = 0.0;
  double _ty = 0.0;
  double _coverScale = 1.0;

  double _containerWidth = 0;
  double _containerHeight = 0;
  double _cropWidth = 0;
  double _cropHeight = 0;

  final GlobalKey _cropKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  Future<void> _loadImage() async {
    try {
      final bytes = await widget.file.readAsBytes();
      final decodedImage = await decodeImageFromList(bytes);
      if (mounted) {
        setState(() {
          _image = decodedImage;
          _naturalWidth = decodedImage.width.toDouble();
          _naturalHeight = decodedImage.height.toDouble();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) Navigator.of(context).pop();
    }
  }

  void _initTransform(double containerWidth, double containerHeight) {
    if (_naturalWidth == 0 || _naturalHeight == 0) return;
    _containerWidth = containerWidth;
    _containerHeight = containerHeight;

    double cropW = containerWidth;
    double cropH = cropW / BannerCropModal.aspectRatio;
    if (cropH > containerHeight) {
      cropH = containerHeight;
      cropW = cropH * BannerCropModal.aspectRatio;
    }
    _cropWidth = cropW;
    _cropHeight = cropH;

    _coverScale = math.max(cropW / _naturalWidth, cropH / _naturalHeight);
    _scale = _coverScale;

    final dispW = _naturalWidth * _scale;
    final dispH = _naturalHeight * _scale;
    _tx = (containerWidth - dispW) / 2;
    _ty = (containerHeight - dispH) / 2;
    _clampPosition();
  }

  void _clampPosition() {
    if (_containerWidth == 0) return;
    final dispW = _naturalWidth * _scale;
    final dispH = _naturalHeight * _scale;
    final cropX = (_containerWidth - _cropWidth) / 2;
    final cropY = (_containerHeight - _cropHeight) / 2;
    final minTx = cropX - (dispW - _cropWidth);
    final maxTx = cropX;
    final minTy = cropY - (dispH - _cropHeight);
    final maxTy = cropY;
    _tx = _tx.clamp(minTx, maxTx);
    _ty = _ty.clamp(minTy, maxTy);
  }

  void _setScaleKeepingCenter(double newScale) {
    if (_containerWidth == 0) return;
    final cropCenterX = _containerWidth / 2;
    final cropCenterY = _containerHeight / 2;
    final srcCenterX = (cropCenterX - _tx) / _scale;
    final srcCenterY = (cropCenterY - _ty) / _scale;
    _scale = newScale;
    _tx = cropCenterX - srcCenterX * _scale;
    _ty = cropCenterY - srcCenterY * _scale;
    _clampPosition();
  }

  void _reset() {
    if (_containerWidth == 0) return;
    _scale = _coverScale;
    final dispW = _naturalWidth * _scale;
    final dispH = _naturalHeight * _scale;
    _tx = (_containerWidth - dispW) / 2;
    _ty = (_containerHeight - dispH) / 2;
    _clampPosition();
    setState(() {});
  }

  Future<void> _applyCrop() async {
    try {
      final RenderRepaintBoundary boundary = _cropKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final ui.Image croppedImage = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await croppedImage.toByteData(format: ui.ImageByteFormat.png);
      final pngBytes = byteData!.buffer.asUint8List();

      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/cropped_banner_${DateTime.now().millisecondsSinceEpoch}.png');
      await tempFile.writeAsBytes(pngBytes);

      if (mounted) Navigator.of(context).pop(tempFile);
    } catch (e) {
      debugPrint("Banner crop error: $e");
      if (mounted) Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const CupertinoPageScaffold(
        backgroundColor: CupertinoColors.transparent,
        child: Center(child: CupertinoActivityIndicator(radius: 16)),
      );
    }

    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.transparent,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              color: AppColors.mainBackground,
              border: Border.all(color: AppColors.white.withValues(alpha: 0.12), width: 1),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Stack(
                children: [
                  // 🎯 Кнопка назад вынесена в отдельный переиспользуемый виджет
                  const CustomBackButton(),

                  Column(
                    children: [
                      // 🎯 1. Хедер: Stack убран, так как кнопка уже позиционирована абсолютно
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                        child: Center(
                          child: Text(
                            'Редактировать баннер',
                            style: AppText.highTextStyle.copyWith(fontSize: 17),
                          ),
                        ),
                      ),

                      // 🎯 2. Область обрезки
                      Expanded(
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final containerWidth = constraints.maxWidth;
                            final containerHeight = constraints.maxHeight - 120;

                            if (_containerWidth == 0 && containerWidth > 0) {
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                setState(() => _initTransform(containerWidth, containerHeight));
                              });
                            }

                            if (_containerWidth == 0) {
                              return const Center(child: CupertinoActivityIndicator(color: AppColors.blurple));
                            }

                            final cropX = (_containerWidth - _cropWidth) / 2;
                            final cropY = (_containerHeight - _cropHeight) / 2;

                            return Center(
                              child: GestureDetector(
                                onPanUpdate: (details) => setState(() {
                                  _tx += details.delta.dx;
                                  _ty += details.delta.dy;
                                  _clampPosition();
                                }),
                                onDoubleTap: _reset,
                                child: SizedBox(
                                  width: _containerWidth,
                                  height: _containerHeight,
                                  child: Stack(
                                    children: [
                                      Positioned(
                                        left: cropX,
                                        top: cropY,
                                        child: RepaintBoundary(
                                          key: _cropKey,
                                          child: ClipRect(
                                            child: Container(
                                              width: _cropWidth,
                                              height: _cropHeight,
                                              color: CupertinoColors.black,
                                              child: Stack(
                                                children: [
                                                  Positioned(
                                                    left: _tx - cropX,
                                                    top: _ty - cropY,
                                                    child: RawImage(
                                                      image: _image,
                                                      width: _naturalWidth * _scale,
                                                      height: _naturalHeight * _scale,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      IgnorePointer(
                                        child: CustomPaint(
                                          size: Size(_containerWidth, _containerHeight),
                                          painter: BannerHolePainter(
                                            cropRect: Rect.fromLTWH(cropX, cropY, _cropWidth, _cropHeight),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),

                      // 🎯 3. Контролы
                      if (_containerWidth > 0)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 90.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 32.0),
                                child: CupertinoSlider(
                                  value: _scale,
                                  min: _coverScale,
                                  max: _coverScale * 3.0,
                                  activeColor: AppColors.blurple,
                                  thumbColor: CupertinoColors.white,
                                  onChanged: (val) => setState(() => _setScaleKeepingCenter(val)),
                                ),
                              ),
                              CupertinoButton(
                                onPressed: _reset,
                                child: Text(
                                  'Сбросить масштаб',
                                  style: AppText.mediumTextStyle.copyWith(
                                    color: AppColors.greyple,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),

                  // 🎯 4. Плавающая кнопка "Применить"
                  Positioned(
                    left: 24,
                    right: 24,
                    bottom: 24,
                    child: CupertinoButton.filled(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      borderRadius: BorderRadius.circular(16),
                      onPressed: _applyCrop,
                      child: const Text(
                        'Применить',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class BannerHolePainter extends CustomPainter {
  final Rect cropRect;

  BannerHolePainter({required this.cropRect});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = CupertinoColors.black.withValues(alpha: 0.7)
      ..style = PaintingStyle.fill;

    final path = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRect(cropRect)
      ..fillType = PathFillType.evenOdd;

    canvas.drawPath(path, paint);

    final borderPaint = Paint()
      ..color = CupertinoColors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    canvas.drawRect(cropRect, borderPaint);
  }

  @override
  bool shouldRepaint(BannerHolePainter oldDelegate) => oldDelegate.cropRect != cropRect;
}