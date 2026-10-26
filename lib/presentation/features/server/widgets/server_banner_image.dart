import 'package:cached_network_image/cached_network_image.dart';
import 'package:disalive/data/network/domain.dart';
import 'package:flutter/cupertino.dart';

class ServerBannerImage extends StatelessWidget {
  const ServerBannerImage({super.key, required this.path, this.height});

  final String path;
  final double? height;

  @override
  Widget build(BuildContext context) {
    final transformed = Domain.transformUrl(path);
    final uri = Uri.tryParse(transformed);
    final url = uri != null && uri.hasScheme
        ? transformed
        : Uri.parse(Domain.imageDomain).resolve(transformed).toString();
    return CachedNetworkImage(
      imageUrl: url,
      width: double.infinity,
      height: height,
      fit: BoxFit.cover,
      errorWidget: (_, _, _) => const SizedBox.shrink(),
    );
  }
}
