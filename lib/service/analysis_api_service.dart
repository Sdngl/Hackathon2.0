import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';

class AnalysisApiService {
  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: 'http://192.168.137.1:8000/api/v1/',
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 90),
    ),
  );

  Future<Map<String, dynamic>> analyzeImage({
    required XFile image,
    required String type,
  }) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      throw Exception('User is not logged in.');
    }

    final token = await user.getIdToken();

    String endpoint;

    switch (type) {
      case 'meal':
        endpoint = 'analyze/meal/';
        break;
      case 'medicine':
        endpoint = 'analyze/medicine/';
        break;
      case 'report':
        endpoint = 'analyze/report/';
        break;
      default:
        throw Exception('Invalid analysis type.');
    }

    final formData = FormData.fromMap({
      'image': await MultipartFile.fromFile(
        image.path,
        filename: image.name,
      ),
    });

    final response = await _dio.post(
      endpoint,
      data: formData,
      options: Options(
        headers: {
          'Authorization': 'Bearer $token',
        },
      ),
    );

    return _extractResponseData(response.data);
  }

  Future<Map<String, dynamic>> analyzeSavedImage({
    required String recordId,
    required String type,
  }) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      throw Exception('User is not logged in.');
    }

    final token = await user.getIdToken();

    String endpoint;

    switch (type) {
      case 'meal':
        endpoint = 'analyze/meal/';
        break;
      case 'medicine':
        endpoint = 'analyze/medicine/';
        break;
      case 'report':
        endpoint = 'analyze/report/';
        break;
      default:
        throw Exception('Invalid analysis type.');
    }

    final response = await _dio.post(
      endpoint,
      data: {
        'record_id': recordId,
      },
      options: Options(
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ),
    );

    return _extractResponseData(response.data);
  }

  Future<Map<String, dynamic>> sendMessage({
    required String message,
    required List<Map<String, dynamic>> history,
    required Map<String, dynamic> context,
  }) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      throw Exception('User is not logged in.');
    }

    final token = await user.getIdToken();

    final response = await _dio.post(
      'chat/',
      data: {
        'message': message,
        'history': history,
        'context': context,
      },
      options: Options(
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ),
    );

    return _extractResponseData(response.data);
  }

  Map<String, dynamic> _extractResponseData(dynamic responseData) {
    if (responseData is! Map) {
      throw Exception('Invalid response from server.');
    }

    final map = Map<String, dynamic>.from(responseData);

    if (map['success'] == false) {
      final error = map['error'];

      if (error is Map && error['message'] != null) {
        throw Exception(error['message'].toString());
      }

      throw Exception('The server could not process the request.');
    }

    if (map['data'] is Map) {
      return Map<String, dynamic>.from(map['data']);
    }

    return map;
  }
}
