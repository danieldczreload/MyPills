import 'dart:io';

import 'package:dio/dio.dart';
import 'package:my_pills/core/errors/failure.dart';
import 'package:my_pills/core/network/api_client.dart';
import 'package:my_pills/core/result/result.dart';

class MediaUploadService {
  MediaUploadService(this._apiClient);

  final ApiClient _apiClient;

  /// Uploads an image file to the backend and returns the public relative URL.
  Future<Result<String>> uploadImage(File file) async {
    try {
      final fileName = file.path.split('/').last;
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          file.path,
          filename: fileName,
        ),
      });

      final response = await _apiClient.dio.post<Map<String, dynamic>>(
        '/uploads',
        data: formData,
      );

      if (response.statusCode == 201 && response.data != null) {
        final url = response.data!['url'] as String?;
        if (url != null) {
          return Result.success(url);
        }
      }

      return const Result.failure(
        Failure.server(statusCode: 500, message: 'Invalid upload response'),
      );
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.connectionTimeout) {
        return const Result.failure(Failure.network());
      }
      return Result.failure(
        Failure.server(
          statusCode: e.response?.statusCode ?? 500,
          message: e.message,
        ),
      );
    } on Object catch (e, st) {
      return Result.failure(Failure.unexpected(error: e, stackTrace: st));
    }
  }
}
