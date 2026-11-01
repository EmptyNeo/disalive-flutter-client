import 'package:dartz/dartz.dart';
import 'package:disalive/app/di/di.dart';
import 'package:disalive/domain/enums/api_type.dart';
import 'package:disalive/domain/failures/failures.dart';
import 'package:disalive/domain/models/preferred_emoji.dart';
import 'package:disalive/domain/repositories/preferred_emojis_repository.dart';
import 'package:disalive/domain/services/http_client_service.dart';

class PreferredEmojisRepositoryImpl extends PreferredEmojisRepository {
  final HttpClientService _httpClient = sl<HttpClientService>();
  final List<PreferredEmoji> _preferredEmojis = <PreferredEmoji>[];

  @override
  Future<Either<Failure, List<PreferredEmoji>>> get() async {
    if (_preferredEmojis.isNotEmpty) {
      return Right(_preferredEmojis);
    }

    final result = await _httpClient.postFormData<List<PreferredEmoji>>(
      endpoint: 'preferredEmojis/get.php',
      data: null,
      apiType: ApiType.v1,
      requireAuth: true,
      fromJson: (json) {
        if (json is List) {
          return json
              .map((e) => PreferredEmoji.fromMap(e as Map<String, dynamic>))
              .toList();
        }
        return <PreferredEmoji>[];
      },
    );

    result.fold((failure) => null, (response) {
      if (_preferredEmojis.isEmpty && response.isNotEmpty) {
        _preferredEmojis.clear();
        _preferredEmojis.addAll(response);
      }
    });

    return result;
  }

  @override
  List<PreferredEmoji> getCache() {
    return _preferredEmojis;
  }
}
