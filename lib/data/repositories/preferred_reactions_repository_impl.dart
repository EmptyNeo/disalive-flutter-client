import 'package:dartz/dartz.dart';
import 'package:disalive/app/di/di.dart';
import 'package:disalive/domain/enums/api_type.dart';
import 'package:disalive/domain/failures/failures.dart';
import 'package:disalive/domain/models/preferred_reaction.dart';
import 'package:disalive/domain/repositories/preferred_reactions_repository.dart';
import 'package:disalive/domain/services/http_client_service.dart';

class PreferredReactionsRepositoryImpl extends PreferredReactionsRepository {
  final HttpClientService _httpClient = sl<HttpClientService>();
  final List<PreferredReaction> _preferredReactions = <PreferredReaction>[];

  @override
  Future<Either<Failure, List<PreferredReaction>>> get() async {
    if (_preferredReactions.isNotEmpty) {
      return Right(_preferredReactions);
    }

    final result = await _httpClient.postFormData<List<PreferredReaction>>(
      endpoint: 'preferredReactions/get.php',
      data: null,
      apiType: ApiType.v1,
      requireAuth: true,
      fromJson: (json) {
        if (json is List) {
          return json
              .map((e) => PreferredReaction.fromMap(e as Map<String, dynamic>))
              .toList();
        }
        return <PreferredReaction>[];
      },
    );

    result.fold((failure) => null, (response) {
      if (_preferredReactions.isEmpty && response.isNotEmpty) {
        _preferredReactions.clear();
        _preferredReactions.addAll(response);
      }
    });

    return result;
  }

  @override
  List<PreferredReaction> getCache() {
    return _preferredReactions;
  }
}
