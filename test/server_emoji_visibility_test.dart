import 'package:dartz/dartz.dart';
import 'package:disalive/domain/failures/failures.dart';
import 'package:disalive/domain/models/emojis/emoji_sheet_data.dart';
import 'package:disalive/domain/models/server_emoji_pack.dart';
import 'package:disalive/domain/repositories/server_emoji_pack_repository.dart';
import 'package:disalive/domain/services/emojis_handler.dart';
import 'package:disalive/presentation/utils/ui/emoji_text_parser.dart';
import 'package:disalive/presentation/widgets/emoji_token.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

class _EmojiPacks implements ServerEmojiPackRepository {
  int categoryRequests = 0;

  @override
  Future<Either<Failure, List<ServerEmojiPack>>> getPacks({
    int? serverId,
    String? categoryId,
  }) async {
    if (categoryId == null) return const Right([]);
    categoryRequests++;
    await Future<void>.delayed(const Duration(milliseconds: 10));
    return Right([
      ServerEmojiPack(3, 9, 'External', categoryId, false, [
        EmojiSheetData.fromJson(categoryId, {
          'meta': {
            'frameSize': {'w': 66, 'h': 66},
            'size': {'w': 66, 'h': 66},
          },
          'frames': {
            '1': {'x': 0, 'y': 0, 'spritePath': '/images/external.png'},
          },
        }, isNetworkAsset: true),
      ]),
    ]);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  test(
    'loads an uninstalled server emoji category once for visible tokens',
    () async {
      final handler = EmojisHandler.instance;
      final repository = _EmojiPacks();
      await handler.loadServerEmojiPacks(repository, force: true);
      expect(handler.getEmojiById('server_external', '1'), isNull);

      final unresolved = EmojiTextParser.parse('[server_external:1]');
      expect((unresolved.single as WidgetSpan).child, isA<EmojiToken>());

      await Future.wait([
        handler.ensureServerCategory('server_external', '1', repository),
        handler.ensureServerCategory('server_external', '1', repository),
      ]);
      expect(repository.categoryRequests, 1);
      expect(handler.getEmojiById('server_external', '1'), isNotNull);
      expect(handler.getSheetDataByCategory('server_external'), isNotNull);
    },
  );
}
