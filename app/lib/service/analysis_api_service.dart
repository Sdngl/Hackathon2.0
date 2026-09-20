import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;

class AnalysisTypeMismatchException implements Exception {
  final String expectedType;
  final String? actualType;

  const AnalysisTypeMismatchException({
    required this.expectedType,
    this.actualType,
  });

  String get userMessage {
    switch (expectedType) {
      case 'meal':
        return 'This doesn\'t look like a meal. Please scan food.';

      case 'medicine':
        return 'This doesn\'t look like a medicine. Please scan a medicine.';

      case 'report':
        return 'This doesn\'t look like a medical report. Please scan a report.';

      default:
        return 'The scanned item does not match the selected scan type.';
    }
  }

  @override
  String toString() => userMessage;
}

class AnalysisApiService {
  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: 'https://backend-seva-production.up.railway.app/api/v1/',
      /* baseUrl: 'http://192.168.137.1:8000/api/v1/', */
      connectTimeout: const Duration(seconds: 60),
      receiveTimeout: const Duration(seconds: 90),
    ),
  );

  Future<Map<String, dynamic>> analyzeReportFile({
    required String filePath,
  }) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      throw Exception(
        'User is not logged in.',
      );
    }

    final token = await user.getIdToken(true);

    final fileName = path.basename(filePath);

    final extension = path.extension(filePath).toLowerCase();

    String contentType;

    switch (extension) {
      case '.pdf':
        contentType = 'application/pdf';
        break;

      case '.jpg':
      case '.jpeg':
        contentType = 'image/jpeg';
        break;

      case '.png':
        contentType = 'image/png';
        break;

      default:
        throw Exception(
          'Unsupported report file. '
              'Please select a PDF, JPG, JPEG, or PNG.',
        );
    }

    final formData = FormData.fromMap(
      {
        'file': await MultipartFile.fromFile(
          filePath,
          filename: fileName,
          contentType: DioMediaType.parse(
            contentType,
          ),
        ),
      },
    );

    Response<dynamic> response;

    try {
      response = await _dio.post(
        'analyze/report/',
        data: formData,
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
        ),
      );
    } on DioException catch (e) {
      throw _friendlyDioException(e);
    }

    final result = _extractResponseData(
      response.data,
    );

    _validateAnalysisType(
      result: result,
      expectedType: 'report',
    );

    return result;
  }

  Future<Map<String, dynamic>> analyzeImage({
    required XFile image,
    required String type,
  }) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      throw Exception(
        'User is not logged in.',
      );
    }

    final normalizedType = type.trim().toLowerCase();

    final token = await user.getIdToken();

    String endpoint;

    switch (normalizedType) {
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
        throw Exception(
          'Invalid analysis type.',
        );
    }

    final formData = FormData.fromMap(
      {
        'image': await MultipartFile.fromFile(
          image.path,
          filename: image.name,
        ),
      },
    );

    Response<dynamic> response;

    try {
      response = await _dio.post(
        endpoint,
        data: formData,
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
        ),
      );
    } on DioException catch (e) {
      throw _friendlyDioException(e);
    }

    final result = _extractResponseData(
      response.data,
    );

    _validateAnalysisType(
      result: result,
      expectedType: normalizedType,
    );

    return result;
  }

  Future<Map<String, dynamic>> analyzeSavedImage({
    required String recordId,
    required String type,
  }) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      throw Exception(
        'User is not logged in.',
      );
    }

    final normalizedType = type.trim().toLowerCase();

    final token = await user.getIdToken();

    String endpoint;

    switch (normalizedType) {
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
        throw Exception(
          'Invalid analysis type.',
        );
    }

    Response<dynamic> response;

    try {
      response = await _dio.post(
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
    } on DioException catch (e) {
      throw _friendlyDioException(e);
    }

    final result = _extractResponseData(
      response.data,
    );

    _validateAnalysisType(
      result: result,
      expectedType: normalizedType,
    );

    return result;
  }

  Future<Map<String, dynamic>> sendMessage({
    required String message,
    required List<Map<String, dynamic>> history,
    required Map<String, dynamic> context,
  }) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      throw Exception(
        'User is not logged in.',
      );
    }

    final token = await user.getIdToken();

    Response<dynamic> response;

    try {
      response = await _dio.post(
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
    } on DioException catch (e) {
      throw _friendlyDioException(e);
    }

    return _extractResponseData(
      response.data,
    );
  }

  Exception _friendlyDioException(
      DioException e,
      ) {
    final statusCode = e.response?.statusCode;

    // Try to use a clean error message returned by Django.
    final responseData = e.response?.data;

    if (responseData is Map) {
      final map = Map<String, dynamic>.from(
        responseData,
      );

      final error = map['error'];

      if (error is Map &&
          error['message'] != null) {
        final message = error['message']
            .toString()
            .trim();

        if (message.isNotEmpty) {
          return Exception(message);
        }
      }

      if (map['message'] != null) {
        final message = map['message']
            .toString()
            .trim();

        if (message.isNotEmpty) {
          return Exception(message);
        }
      }

      if (map['detail'] != null) {
        final message = map['detail']
            .toString()
            .trim();

        if (message.isNotEmpty) {
          return Exception(message);
        }
      }
    }

    if (statusCode == 400) {
      return Exception(
        'The request could not be processed. Please check the image and try again.',
      );
    }

    if (statusCode == 401 ||
        statusCode == 403) {
      return Exception(
        'Your session has expired. Please sign in again.',
      );
    }

    if (statusCode == 404) {
      return Exception(
        'The requested service could not be found.',
      );
    }

    if (statusCode == 408) {
      return Exception(
        'The request took too long. Please try again.',
      );
    }

    if (statusCode == 413) {
      return Exception(
        'The selected file is too large. Please choose a smaller file.',
      );
    }

    if (statusCode == 429) {
      return Exception(
        'AI usage limit reached. Please try again later.',
      );
    }

    if (statusCode == 500 ||
        statusCode == 502 ||
        statusCode == 503 ||
        statusCode == 504) {
      return Exception(
        'The server is temporarily unavailable. Please try again later.',
      );
    }

    if (e.type ==
        DioExceptionType.connectionTimeout ||
        e.type ==
            DioExceptionType.sendTimeout ||
        e.type ==
            DioExceptionType.receiveTimeout) {
      return Exception(
        'The request took too long. Please try again.',
      );
    }

    if (e.type ==
        DioExceptionType.connectionError) {
      return Exception(
        'Could not connect to the server. Check your internet connection.',
      );
    }

    if (e.type ==
        DioExceptionType.cancel) {
      return Exception(
        'The request was cancelled.',
      );
    }

    return Exception(
      'Something went wrong. Please try again.',
    );
  }

  void _validateAnalysisType({
    required Map<String, dynamic> result,
    required String expectedType,
  }) {
    final expected =
    expectedType.trim().toLowerCase();

    // -------------------------
    // MEAL VALIDATION
    // -------------------------
    if (expected == 'meal') {
      final foods = result['foods'];

      if (foods is! List ||
          foods.isEmpty) {
        throw AnalysisTypeMismatchException(
          expectedType: 'meal',
          actualType:
          _detectTypeFromResult(result),
        );
      }

      return;
    }

    // -------------------------
    // MEDICINE VALIDATION
    // -------------------------
    if (expected == 'medicine') {
      final resultText =
      result.toString().toLowerCase();

      final looksLikeMedicine =
          resultText.contains('medicine') ||
              resultText
                  .contains('medication') ||
              resultText.contains('tablet') ||
              resultText.contains('capsule') ||
              resultText.contains('drug') ||
              resultText
                  .contains('generic_name') ||
              resultText
                  .contains('medicine_name');

      if (!looksLikeMedicine) {
        throw AnalysisTypeMismatchException(
          expectedType: 'medicine',
          actualType:
          _detectTypeFromResult(result),
        );
      }

      return;
    }

    // -------------------------
    // REPORT VALIDATION
    // -------------------------
    if (expected == 'report') {
      final resultText =
      result.toString().toLowerCase();

      final looksLikeReport =
          resultText.contains('report') ||
              resultText
                  .contains('laboratory') ||
              resultText
                  .contains('lab result') ||
              resultText
                  .contains('test result') ||
              resultText
                  .contains('reference range') ||
              resultText.contains('patient');

      if (!looksLikeReport) {
        throw AnalysisTypeMismatchException(
          expectedType: 'report',
          actualType:
          _detectTypeFromResult(result),
        );
      }

      return;
    }

    throw Exception(
      'Unsupported analysis type.',
    );
  }

  String? _detectTypeFromResult(
      Map<String, dynamic> result,
      ) {
    final text =
    result.toString().toLowerCase();

    if (text.contains('medicine') ||
        text.contains('medication') ||
        text.contains('tablet') ||
        text.contains('capsule') ||
        text.contains('blister pack')) {
      return 'medicine';
    }

    if (text.contains('food') ||
        text.contains('meal') ||
        text.contains('calories') ||
        text.contains('protein')) {
      return 'meal';
    }

    if (text.contains('medical report') ||
        text.contains('laboratory') ||
        text.contains('reference range') ||
        text.contains('test result')) {
      return 'report';
    }

    return null;
  }

  Map<String, dynamic> _extractResponseData(
      dynamic responseData,
      ) {
    if (responseData is! Map) {
      throw Exception(
        'Invalid response from server.',
      );
    }

    final map =
    Map<String, dynamic>.from(
      responseData,
    );

    if (map['success'] == false) {
      final error = map['error'];

      if (error is Map &&
          error['message'] != null) {
        throw Exception(
          error['message'].toString(),
        );
      }

      throw Exception(
        'The server could not process the request.',
      );
    }

    if (map['data'] is Map) {
      return Map<String, dynamic>.from(
        map['data'],
      );
    }

    return map;
  }
}