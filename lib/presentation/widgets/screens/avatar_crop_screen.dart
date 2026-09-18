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

class AvatarCropScreen extends StatefulWidget {
  final File file;

  const AvatarCropScreen({super.key, required this.file});

  static Future<File?> open(BuildContext context, {required File file}) {
    return SwipeToDismissRoute.push<File>(
      context,
          (context) => AvatarCropScreen(file: file),
    );
  }

  @override
  State<AvatarCropScreen> createState() => _AvatarCropScreenState();
}

class _AvatarCropScreenState extends State<AvatarCropScreen> {
  ui.Image? _image;
  bool _isLoading = true;

  double _naturalWidth = 0;
  double _naturalHeight = 0;
  double _containerSize = 0;

  double _scale = 1.0;
  double _tx = 0.0;
  double _ty = 0.0;
  double _coverScale = 1.0;

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

  void _initTransform(double containerSize) {
    if (_naturalWidth == 0 || _naturalHeight == 0) return;
    _containerSize = containerSize;
    _coverScale = math.max(containerSize / _naturalWidth, containerSize / _naturalHeight);
    _scale = _coverScale;
    final dispW = _naturalWidth * _scale;
    final dispH = _naturalHeight * _scale;
    _tx = (containerSize - dispW) / 2;
    _ty = (containerSize - dispH) / 2;
    _clampPosition();
  }

  void _clampPosition() {
    if (_containerSize == 0) return;
    final D = _containerSize;
    final dispW = _naturalWidth * _scale;
    final dispH = _naturalHeight * _scale;
    final minTx = math.min(0.0, D - dispW);
    const maxTx = 0.0;
    final minTy = math.min(0.0, D - dispH);
    const maxTy = 0.0;
    _tx = _tx.clamp(minTx, maxTx);
    _ty = _ty.clamp(minTy, maxTy);
  }

  void _setScaleKeepingCenter(double newScale) {
    if (_containerSize == 0) return;
    final D = _containerSize;
    final srcCenterX = (D / 2 - _tx) / _scale;
    final srcCenterY = (D / 2 - _ty) / _scale;
    _scale = newScale;
    _tx = D / 2 - srcCenterX * _scale;
    _ty = D / 2 - srcCenterY * _scale;
    _clampPosition();
  }

  void _reset() {
    if (_containerSize == 0) return;
    final D = _containerSize;
    _coverScale = math.max(D / _naturalWidth, D / _naturalHeight);
    _scale = _coverScale;
    final dispW = _naturalWidth * _scale;
    final dispH = _naturalHeight * _scale;
    _tx = (D - dispW) / 2;
    _ty = (D - dispH) / 2;
    setState(() {});
  }

  Future<void> _applyCrop() async {
    try {
      final RenderRepaintBoundary boundary = _cropKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final pngBytes = byteData!.buffer.asUint8List();

      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/cropped_avatar_${DateTime.now().millisecondsSinceEpoch}.png');
      await tempFile.writeAsBytes(pngBytes);

      if (mounted) Navigator.of(context).pop(tempFile);
    } catch (e) {
      debugPrint("Crop error: $e");
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
                  const CustomBackButton(positioned: 10,),

                  Column(
                    children: [
                      // 🎯 1. Хедер: Stack убран, так как кнопка уже позиционирована абсолютно
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Center(
                          child: Text(
                            'Редактировать аватар',
                            style: AppText.highTextStyle.copyWith(fontSize: 17),
                          ),
                        ),
                      ),

                      // 🎯 2. Область обрезки
                      Expanded(
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final maxSize = constraints.maxWidth;
                            final D = math.min(maxSize - 32, 320.0);

                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              if (_containerSize == 0) {
                                setState(() => _initTransform(D));
                              }
                            });

                            return Center(
                              child: GestureDetector(
                                onPanUpdate: (details) {
                                  setState(() {
                                    _tx += details.delta.dx;
                                    _ty += details.delta.dy;
                                    _clampPosition();
                                  });
                                },
                                child: SizedBox(
                                  width: D,
                                  height: D,
                                  child: Stack(
                                    children: [
                                      RepaintBoundary(
                                        key: _cropKey,
                                        child: ClipRect(
                                          child: Container(
                                            width: D,
                                            height: D,
                                            color: CupertinoColors.black,
                                            child: Stack(
                                              children: [
                                                Positioned(
                                                  left: _tx,
                                                  top: _ty,
                                                  child: RawImage(
                                                    image: _image,
                                                    width: _naturalWidth * _scale,
                                                    height: _naturalHeight * _scale,
                                                    fit: BoxFit.fill,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                      IgnorePointer(
                                        child: CustomPaint(
                                          size: Size(D, D),
                                          painter: HolePainter(),
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
                      if (_containerSize > 0)
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

class HolePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = CupertinoColors.black.withValues(alpha: 0.7)
      ..style = PaintingStyle.fill;

    final path = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addOval(Rect.fromCenter(center: Offset(size.width / 2, size.height / 2), width: size.width, height: size.height))
      ..fillType = PathFillType.evenOdd;

    canvas.drawPath(path, paint);

    final borderPaint = Paint()
      ..color = CupertinoColors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    canvas.drawOval(Rect.fromCenter(center: Offset(size.width / 2, size.height / 2), width: size.width, height: size.height), borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}