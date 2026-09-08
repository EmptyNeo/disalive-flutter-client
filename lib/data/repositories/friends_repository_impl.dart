import 'package:dartz/dartz.dart';
import 'package:disalive/app/di/di.dart';
import 'package:disalive/domain/enums/api_type.dart';
import 'package:disalive/domain/failures/failures.dart';
import 'package:disalive/domain/repositories/friends_repository.dart';
import 'package:disalive/domain/services/http_client_service.dart';

class FriendsRepositoryImpl extends FriendsRepository {
  final HttpClientService _httpClient = sl<HttpClientService>();

  @override
  Future<Either<Failure, bool>> toggleBlock(int chatId) async {
    final result = await _httpClient.postFormData<bool>(
      endpoint: 'friends/toggle_block.php',
      data: {"chatId": chatId},
      apiType: ApiType.v1,
      requireAuth: true,
      fromJson: (json) {
        return json is Map<String, dynamic>;
      },
    );

    return result;
  }

  @override
  Future<Either<Failure, bool>> delete(int chatId) async {
    final result = await _httpClient.postFormData<bool>(
      endpoint: 'friends/delete.php',
      data: {"chatId": chatId},
      apiType: ApiType.v1,
      requireAuth: true,
      fromJson: (json) {
        return json['success'];
      },
    );

    return result;
  }
}
