import 'dart:convert';
import 'dart:ui';
import 'package:dartz/dartz.dart';
import 'package:disalive/data/network/domain.dart';
import 'package:disalive/domain/enums/api_type.dart';
import 'package:disalive/domain/services/secure_storage_service.dart';
import 'package:http/http.dart' as http;
import 'package:disalive/domain/failures/failures.dart';

class HttpClientService {
  final http.Client _client;
  final SecureStorageService _secureStorage;

  HttpClientService({
    http.Client? client,
    required SecureStorageService secureStorage,
  }) : _client = client ?? http.Client(),
       _secureStorage = secureStorage;

  Future<Either<Failure, T>> postFormData<T>({
    required String endpoint,
    Map<String, dynamic>? data,
    required T Function(dynamic json) fromJson,
    ApiType apiType = ApiType.v1,
    bool requireAuth = true,
    String? errorMessage,
    VoidCallback? onUnauthorized,
  }) async {
    try {
      final formData = <String, String>{};

      if (requireAuth) {
        final keySession = await _secureStorage.getKeySession();
        if (keySession == null) {
          return Left(UnauthorizedFailure());
        }
        formData['keySession'] = keySession;
      }
      if (data != null) {
        data.forEach((key, value) {
          if (value != null) {
            formData[key] = value.toString();
          }
        });
      }

      final baseUrl = _getBaseUrl(apiType);

      final response = await _client.post(
        Uri.parse('$baseUrl$endpoint'),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: formData,
      );

      return _handleResponse<T>(
        response: response,
        fromJson: fromJson,
        endpoint: endpoint,
        onUnauthorized: onUnauthorized,
        errorMessage: errorMessage,
      );
    } catch (e) {
      return Left(NetworkFailure());
    }
  }

  Either<Failure, T> _handleResponse<T>({
    required http.Response response,
    required T Function(dynamic json) fromJson,
    required String endpoint,
    VoidCallback? onUnauthorized,
    String? errorMessage,
  }) {
    try {
      final Map<String, dynamic> jsonResponse;
      try {
        jsonResponse = jsonDecode(response.body);
      } catch (e) {
        return Left(ParsingFailure('Invalid JSON response'));
      }

      final bool success = jsonResponse['success'] ?? false;

      if (!success) {
        final error = jsonResponse['error'].toString();

        if (response.statusCode == 401 || response.statusCode == 403) {
          if (onUnauthorized != null) {
            onUnauthorized();
          }
          return Left(UnauthorizedFailure());
        }

        if (response.statusCode == 422) {
          final errors = jsonResponse['errors'];
          if (errors != null && errors is Map) {
            return Left(ValidationFailure(errors));
          }
        }

        if (response.statusCode == 500) {
          return Left(ServerFailure(error));
        }

        return Left(
          ClientFailure(errorMessage != null ? '$errorMessage: $error' : error),
        );
      }

      final data = jsonResponse['data'];

      if (data == null) {
        // Для некоторых запросов может не быть data, но success true
        try {
          return Right(fromJson({}));
        } catch (e) {
          return Left(
            ParsingFailure('Failed to parse empty response: ${e.toString()}'),
          );
        }
      }

      try {
        return Right(fromJson(data));
      } catch (e) {
        return Left(ParsingFailure('Failed to parse data: ${e.toString()}'));
      }
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  String _getBaseUrl(ApiType apiType) {
    switch (apiType) {
      case ApiType.v1:
        return Domain.api;
      case ApiType.php:
        return Domain.baseUrl;
    }
  }

  void dispose() {
    _client.close();
  }
}
