import 'package:dartz/dartz.dart';
import 'package:disalive/app/di/di.dart';
import 'package:disalive/domain/enums/api_type.dart';
import 'package:disalive/domain/failures/failures.dart';
import 'package:disalive/domain/models/friend_request.dart';
import 'package:disalive/domain/repositories/requests_repository.dart';
import 'package:disalive/domain/services/http_client_service.dart';

class RequestsRepositoryImpl extends RequestsRepository {
  final HttpClientService _httpClient = sl<HttpClientService>();
  List<FriendRequest> _requests = [];

  @override
  Future<Either<Failure, List<FriendRequest>>> get() async {
    final result = await _httpClient.postFormData<List<FriendRequest>>(
      endpoint: 'requests/get.php',
      data: null,
      apiType: ApiType.v1,
      requireAuth: true,
      fromJson: (json) {
        if (json is List) {
          return json
              .map((e) => FriendRequest.fromMap(e as Map<String, dynamic>))
              .toList();
        }
        return <FriendRequest>[];
      },
    );

    result.fold((failure) => null, (requests) {
      _requests = requests;
    });

    return result;
  }

  @override
  Future<Either<Failure, bool>> send(String username) async {
    final result = await _httpClient.postFormData<bool>(
      endpoint: 'requests/send.php',
      data: {'username': username},
      apiType: ApiType.v1,
      requireAuth: true,
      fromJson: (json) {
        final request = FriendRequest.fromMap(json as Map<String, dynamic>);
        final exists = _requests.any((r) => r.id == request.id);
        if (!exists) {
          _requests.insert(0, request);
        }
        return true;
      },
    );

    return result;
  }

  @override
  Future<Either<Failure, bool>> cancel(String username) async {
    final result = await _httpClient.postFormData<bool>(
      endpoint: 'requests/cancel.php',
      data: {'username': username},
      apiType: ApiType.v1,
      requireAuth: true,
      fromJson: (json) {
        bool success = json['success'] == true;
        if (success) {
          _requests.removeWhere((r) => r.user?.username == username);
        }
        return success;
      },
    );

    return result;
  }

  @override
  Future<Either<Failure, bool>> accept(String username) async {
    final result = await _httpClient.postFormData<bool>(
      endpoint: 'friends/create.php',
      data: {'username': username},
      apiType: ApiType.v1,
      requireAuth: true,
      fromJson: (json) {
        bool success = json['success'] == true;
        if (success) {
          _requests.removeWhere((r) => r.user?.username == username);
        }
        return success;
      },
    );

    return result;
  }

  @override
  List<FriendRequest> getCached() {
    return _requests;
  }
}
