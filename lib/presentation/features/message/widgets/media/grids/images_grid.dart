// lib/presentation/features/message/widgets/media_grid.dart
import 'package:disalive/domain/models/file_message.dart';
import 'package:disalive/presentation/features/message/widgets/media/items/image_item.dart';
import 'package:flutter/cupertino.dart';

/// Раскладка группы фото в сообщении в стиле Telegram.
///
/// Для 1–10 фото используются заранее заданные шаблоны (см. [_blocksFor]):
/// высота каждой ячейки известна до загрузки картинок, поэтому сетка не
/// "прыгает", пока изображения подгружаются. Больше 10 фото — обычный
/// скроллируемый GridView 3×N с фиксированной высотой в 3 видимых ряда.
///
/// Сам виджет ничего не знает о ширине бабла — она берётся из доступных
/// constraints (LayoutBuilder), поэтому его достаточно поместить в любой
/// контейнер с ограниченной шириной.
class ImagesGrid extends StatelessWidget {
  const ImagesGrid({
    super.key,
    required this.images,
    this.spacing = 2,
    this.cornerRadius = 8,
    this.onTapImage,
  });

  /// Только вложения-изображения (FileMessage.isImageFile). Остальные типы
  /// вложений сюда передавать не нужно — для них своя отрисовка.
  final List<FileMessage> images;

  /// Отступ между ячейками сетки.
  final double spacing;

  /// Радиус скругления внешних углов всей группы (внутренние стыки между
  /// фото всегда острые — как в Telegram).
  final double cornerRadius;

  /// Опциональный колбэк с индексом фото в [images] по тапу — например,
  /// для открытия полноэкранного просмотра.
  final ValueChanged<int>? onTapImage;

  static const int _maxTemplated = 10;
  static const int _scrollGridColumns = 3;
  static const int _scrollGridVisibleRows = 3;

  @override
  Widget build(BuildContext context) {
    if (images.isEmpty) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, constraints) {
        if (images.length > _maxTemplated) {
          return _buildScrollableGrid(constraints.maxWidth);
        }
        return _buildTemplatedGrid(constraints.maxWidth);
      },
    );
  }

  // Шаблоны раскладки по количеству фото. Каждый блок — это группа из
  // [rows] рядов по [cols] колонок; ячейки внутри блока — квадраты
  // (heightRatio == 1), кроме одиночных "широких" рядов, где высота
  // задаётся как доля от ширины.
  List<_GridBlock> _blocksFor(int count) {
    switch (count) {
      case 1:
        return const [_GridBlock(rows: 1, cols: 1, heightRatio: 0.72)];
      case 2:
        return const [_GridBlock(rows: 1, cols: 2)];
      case 3:
        return const [
          _GridBlock(rows: 1, cols: 1, heightRatio: 0.55),
          _GridBlock(rows: 1, cols: 2),
        ];
      case 4:
        return const [_GridBlock(rows: 2, cols: 2)];
      case 5:
        return const [
          _GridBlock(rows: 1, cols: 2),
          _GridBlock(rows: 1, cols: 3),
        ];
      case 6:
        return const [_GridBlock(rows: 2, cols: 3)];
      case 7:
        return const [
          _GridBlock(rows: 2, cols: 2),
          _GridBlock(rows: 1, cols: 3),
        ];
      case 8:
        return const [
          _GridBlock(rows: 1, cols: 2),
          _GridBlock(rows: 2, cols: 3),
        ];
      case 9:
        return const [_GridBlock(rows: 3, cols: 3)];
      case 10:
        return const [
          _GridBlock(rows: 2, cols: 2),
          _GridBlock(rows: 2, cols: 3),
        ];
      default:
        return const [];
    }
  }

  Widget _buildTemplatedGrid(double maxWidth) {
    final blocks = _blocksFor(images.length);
    final totalRows = blocks.fold<int>(0, (sum, block) => sum + block.rows);

    final rows = <Widget>[];
    var imageIndex = 0;
    var absoluteRow = 0;

    for (final block in blocks) {
      final cellWidth = (maxWidth - spacing * (block.cols - 1)) / block.cols;
      final cellHeight = cellWidth * block.heightRatio;

      for (var r = 0; r < block.rows; r++) {
        final isFirstRow = absoluteRow == 0;
        final isLastRow = absoluteRow == totalRows - 1;
        final cells = <Widget>[];

        for (var c = 0; c < block.cols; c++) {
          final isFirstCol = c == 0;
          final isLastCol = c == block.cols - 1;

          cells.add(
            _buildCell(
              file: images[imageIndex],
              index: imageIndex,
              width: cellWidth,
              height: cellHeight,
              radius: BorderRadius.only(
                topLeft: isFirstRow && isFirstCol
                    ? Radius.circular(cornerRadius)
                    : Radius.zero,
                topRight: isFirstRow && isLastCol
                    ? Radius.circular(cornerRadius)
                    : Radius.zero,
                bottomLeft: isLastRow && isFirstCol
                    ? Radius.circular(cornerRadius)
                    : Radius.zero,
                bottomRight: isLastRow && isLastCol
                    ? Radius.circular(cornerRadius)
                    : Radius.zero,
              ),
            ),
          );
          imageIndex++;

          if (!isLastCol) cells.add(SizedBox(width: spacing));
        }

        rows.add(Row(mainAxisSize: MainAxisSize.min, children: cells));
        if (!isLastRow) rows.add(SizedBox(height: spacing));
        absoluteRow++;
      }
    }

    return Column(mainAxisSize: MainAxisSize.min, children: rows);
  }

  Widget _buildScrollableGrid(double maxWidth) {
    final cellSize =
        (maxWidth - spacing * (_scrollGridColumns - 1)) / _scrollGridColumns;
    final gridHeight =
        cellSize * _scrollGridVisibleRows +
        spacing * (_scrollGridVisibleRows - 1);

    return ClipRRect(
      borderRadius: BorderRadius.circular(cornerRadius),
      child: SizedBox(
        width: maxWidth,
        height: gridHeight,
        child: GridView.builder(
          padding: EdgeInsets.zero,
          physics: const ClampingScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: _scrollGridColumns,
            mainAxisSpacing: spacing,
            crossAxisSpacing: spacing,
            childAspectRatio: 1,
          ),
          itemCount: images.length,
          itemBuilder: (context, index) => _buildCell(
            file: images[index],
            index: index,
            radius: BorderRadius.zero,
          ),
        ),
      ),
    );
  }

  Widget _buildCell({
    required FileMessage file,
    required int index,
    double? width,
    double? height,
    BorderRadius radius = BorderRadius.zero,
  }) {
    final image = ImageItem(
      key: ValueKey(file.id ?? file.objectKey ?? file.urlPath),
      pathImage: file.urlPath,
      width: width,
      height: height,
      borderRadius: radius,
    );

    final onTap = onTapImage;
    if (onTap == null) return image;

    return GestureDetector(onTap: () => onTap(index), child: image);
  }
}

class _GridBlock {
  const _GridBlock({
    required this.rows,
    required this.cols,
    this.heightRatio = 1,
  });

  final int rows;
  final int cols;

  /// Отношение высоты ячейки к её ширине. 1 — квадрат (по умолчанию для
  /// всех многоколоночных рядов), меньше 1 — приплюснутый прямоугольник
  /// (используется только для одиночных широких рядов).
  final double heightRatio;
}
