import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:ui';

Future<Uint8List> circleCrop(Uint8List bytes, {int size = 256}) async {
  final codec = await ui.instantiateImageCodec(bytes);
  final frame = await codec.getNextFrame();
  final image = frame.image;

  final w = image.width.toDouble();
  final h = image.height.toDouble();
  final side = w < h ? w : h;
  final srcRect = Rect.fromLTWH((w - side) / 2, (h - side) / 2, side, side);
  final dstRect = Rect.fromLTWH(0, 0, size.toDouble(), size.toDouble());

  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  canvas.clipPath(Path()..addOval(dstRect));
  canvas.drawImageRect(
    image,
    srcRect,
    dstRect,
    Paint()
      ..isAntiAlias = true
      ..filterQuality = FilterQuality.high,
  );

  final rounded = await recorder.endRecording().toImage(size, size);
  final data = await rounded.toByteData(format: ui.ImageByteFormat.png);

  image.dispose();
  rounded.dispose();

  return data!.buffer.asUint8List();
}