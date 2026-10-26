import 'dart:io';

import 'package:bloc/bloc.dart';
import 'package:disalive/domain/repositories/gifs_repository.dart';
import 'package:path_provider/path_provider.dart';

sealed class GifCropEvent {}

class GifCropRequested extends GifCropEvent {
  GifCropRequested(this.image, this.x, this.y, this.width, this.height);

  final File image;
  final int x;
  final int y;
  final int width;
  final int height;
}

enum GifCropStatus { idle, loading, success, failure }

class GifCropState {
  const GifCropState(this.status, {this.file, this.error});

  final GifCropStatus status;
  final File? file;
  final String? error;
}

class GifCropBloc extends Bloc<GifCropEvent, GifCropState> {
  GifCropBloc(GifsRepository repository)
    : super(const GifCropState(GifCropStatus.idle)) {
    on<GifCropRequested>((event, emit) async {
      emit(const GifCropState(GifCropStatus.loading));
      final result = await repository.crop(
        event.image,
        x: event.x,
        y: event.y,
        width: event.width,
        height: event.height,
      );
      if (emit.isDone) return;
      await result.fold(
        (failure) async =>
            emit(GifCropState(GifCropStatus.failure, error: failure.message)),
        (bytes) async {
          try {
            final dir = await getTemporaryDirectory();
            final file = File(
              '${dir.path}/cropped_gif_${DateTime.now().microsecondsSinceEpoch}.gif',
            );
            await file.writeAsBytes(bytes);
            if (emit.isDone) return;
            emit(GifCropState(GifCropStatus.success, file: file));
          } catch (_) {
            if (emit.isDone) return;
            emit(
              const GifCropState(
                GifCropStatus.failure,
                error: 'Не удалось сохранить GIF',
              ),
            );
          }
        },
      );
    });
  }
}
