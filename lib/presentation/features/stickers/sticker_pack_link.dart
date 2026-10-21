import 'package:disalive/data/network/domain.dart';

String stickerPackUrl(int packId) =>
    '${Domain.imageDomain}addstickers/index.php?packId=$packId';

final RegExp _stickerPackPattern = RegExp(
  r'(?:https?://)?disalive\.ru/addstickers/index\.php\?packId=([0-9]+)(?![A-Za-z0-9_=&/?-]|\.[0-9])',
  caseSensitive: false,
);

class StickerPackLink {
  const StickerPackLink({required this.packId, required this.url});

  final int packId;
  final String url;
}

StickerPackLink? stickerPackLinkFromText(String? text) {
  if (text == null) return null;
  for (final match in _stickerPackPattern.allMatches(text)) {
    if (match.start > 0 &&
        RegExp(r'[A-Za-z0-9_.-]').hasMatch(text[match.start - 1])) {
      continue;
    }
    final packId = int.tryParse(match.group(1)!);
    if (packId == null || packId <= 0) continue;
    return StickerPackLink(packId: packId, url: match.group(0)!);
  }
  return null;
}
