import 'dart:async';
import 'package:dio/dio.dart';
import '../config/app_config.dart';
import 'storage_service.dart';

/// HTTP客户端
class HttpClient {
  HttpClient._();
  static final HttpClient instance = HttpClient._();

  late Dio _dio;
  bool _isRefreshing = false;
  final List<void Function(String)> _pendingRequests = [];

  Dio get dio => _dio;

  void init() {
    _dio = Dio(
      BaseOptions(
        baseUrl: AppConfig.baseUrl,
        connectTimeout: const Duration(milliseconds: AppConfig.connectTimeout),
        receiveTimeout: const Duration(milliseconds: AppConfig.receiveTimeout),
        headers: {'Content-Type': 'application/json'},
      ),
    );

    // 请求拦截器
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          final token = StorageService.instance.accessToken;
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }

          // 添加用户ID头
          final userInfo = StorageService.instance.userInfo;
          if (userInfo != null && userInfo['userId'] != null) {
            options.headers['X-User-Id'] = userInfo['userId'].toString();
          }

          return handler.next(options);
        },
        onResponse: (response, handler) {
          return handler.next(response);
        },
        onError: (error, handler) async {
          // 处理401未授权错误
          if (error.response?.statusCode == 401) {
            // 如果是刷新token的请求本身401，直接失败，避免无限递归
            // ✅ 修复Bug4: 判断路径与实际refresh token路径一致
            if (error.requestOptions.path.contains(
              '/api/v1/auth/refresh-token',
            )) {
              await StorageService.instance.clearTokens();
              return handler.next(error);
            }

            if (_isRefreshing) {
              // 已在刷新中，排队等待
              final completer = Completer<Response>();
              _pendingRequests.add((newToken) {
                error.requestOptions.headers['Authorization'] =
                    'Bearer $newToken';
                _dio
                    .fetch(error.requestOptions)
                    .then(completer.complete)
                    .catchError(completer.completeError);
              });
              try {
                final response = await completer.future;
                return handler.resolve(response);
              } catch (e) {
                return handler.next(error);
              }
            }

            _isRefreshing = true;
            final refreshed = await _refreshToken();
            _isRefreshing = false;

            if (refreshed) {
              final newToken = StorageService.instance.accessToken!;
              // 执行所有排队的请求
              for (final callback in _pendingRequests) {
                callback(newToken);
              }
              _pendingRequests.clear();

              // 重试当前请求
              final options = error.requestOptions;
              options.headers['Authorization'] = 'Bearer $newToken';
              try {
                final response = await _dio.fetch(options);
                return handler.resolve(response);
              } catch (e) {
                return handler.next(error);
              }
            } else {
              _pendingRequests.clear();
            }
          }
          return handler.next(error);
        },
      ),
    );
  }

  Future<bool> _refreshToken() async {
    final refreshToken = StorageService.instance.refreshToken;
    if (refreshToken == null) return false;

    try {
      final response = await _dio.post(
        '/api/v1/auth/refresh-token',
        queryParameters: {'refreshToken': refreshToken},
      );

      final responseData = response.data as Map<String, dynamic>;
      if (responseData['code'] == 200) {
        final data = responseData['data'] as Map<String, dynamic>;
        await StorageService.instance.saveTokens(
          accessToken: data['accessToken'] as String,
          refreshToken: data['refreshToken'] as String,
        );
        return true;
      }
    } catch (e) {
      // ignore refresh token error
    }

    await StorageService.instance.clearTokens();
    return false;
  }

  // GET请求
  Future<ApiResponse> get(String path, {Map<String, dynamic>? params}) async {
    try {
      final response = await _dio.get(path, queryParameters: params);
      return ApiResponse.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      return ApiResponse.error(_handleError(e));
    }
  }

  // POST请求
  Future<ApiResponse> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? params,
  }) async {
    try {
      final response = await _dio.post(
        path,
        data: data,
        queryParameters: params,
      );
      return ApiResponse.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      return ApiResponse.error(_handleError(e));
    }
  }

  // PUT请求
  Future<ApiResponse> put(
    String path, {
    dynamic data,
    Map<String, dynamic>? params,
  }) async {
    try {
      final response = await _dio.put(
        path,
        data: data,
        queryParameters: params,
      );
      return ApiResponse.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      return ApiResponse.error(_handleError(e));
    }
  }

  // DELETE请求
  Future<ApiResponse> delete(String path, {dynamic data}) async {
    try {
      final response = await _dio.delete(path, data: data);
      return ApiResponse.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      return ApiResponse.error(_handleError(e));
    }
  }

  // 上传文件
  Future<ApiResponse> upload(
    String path, {
    required String filePath,
    String fieldName = 'file',
    Map<String, dynamic>? extraData,
    ProgressCallback? onProgress,
  }) async {
    try {
      final formData = FormData.fromMap({
        fieldName: await MultipartFile.fromFile(filePath),
        if (extraData != null) ...extraData,
      });

      final response = await _dio.post(
        path,
        data: formData,
        onSendProgress: onProgress,
      );
      return ApiResponse.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      return ApiResponse.error(_handleError(e));
    }
  }

  String _handleError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
        return '连接超时';
      case DioExceptionType.sendTimeout:
        return '请求超时';
      case DioExceptionType.receiveTimeout:
        return '响应超时';
      case DioExceptionType.badResponse:
        final code = e.response?.statusCode;
        if (code == 401) return '未授权，请重新登录';
        if (code == 403) return '无权限访问';
        if (code == 404) return '请求资源不存在';
        if (code == 500) return '服务器错误';
        return '请求失败($code)';
      case DioExceptionType.cancel:
        return '请求取消';
      default:
        return '网络异常';
    }
  }
}

/// API响应封装
class ApiResponse {
  final int code;
  final String message;
  final dynamic data;

  ApiResponse({required this.code, required this.message, this.data});

  factory ApiResponse.fromJson(Map<String, dynamic> json) {
    return ApiResponse(
      code: (json['code'] as num?)?.toInt() ?? 0,
      message: (json['message'] as String?) ?? '',
      data: json['data'],
    );
  }

  factory ApiResponse.error(String message) {
    return ApiResponse(code: -1, message: message);
  }

  bool get isSuccess => code == 200;
}
