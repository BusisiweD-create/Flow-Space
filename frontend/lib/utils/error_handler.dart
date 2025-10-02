// Comprehensive error handling and user feedback system

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'dart:convert';

enum AppErrorType {
  network,        // Network connectivity issues
  server,         // Server errors (5xx)
  client,         // Client errors (4xx)
  authentication, // Authentication errors
  authorization,  // Authorization errors
  validation,     // Input validation errors
  database,       // Database/local storage errors
  unknown,       // Unknown errors
  timeout,        // Request timeout
  rateLimit,      // Rate limiting
  maintenance,    // Server maintenance
}

class AppError implements Exception {
  final AppErrorType type;
  final String message;
  final String? code;
  final int? statusCode;
  final dynamic originalError;
  final StackTrace? stackTrace;

  AppError({
    required this.type,
    required this.message,
    this.code,
    this.statusCode,
    this.originalError,
    this.stackTrace,
  });

  @override
  String toString() => 'AppError(type: \$type, message: "\$message", code: \$code, statusCode: \$statusCode)';

  // Factory methods for common error types
  factory AppError.network(String message, {dynamic originalError, StackTrace? stackTrace}) {
    return AppError(
      type: AppErrorType.network,
      message: message,
      originalError: originalError,
      stackTrace: stackTrace,
    );
  }

  factory AppError.server(String message, {int? statusCode, String? code, dynamic originalError, StackTrace? stackTrace}) {
    return AppError(
      type: AppErrorType.server,
      message: message,
      statusCode: statusCode,
      code: code,
      originalError: originalError,
      stackTrace: stackTrace,
    );
  }

  factory AppError.client(String message, {int? statusCode, String? code, dynamic originalError, StackTrace? stackTrace}) {
    return AppError(
      type: AppErrorType.client,
      message: message,
      statusCode: statusCode,
      code: code,
      originalError: originalError,
      stackTrace: stackTrace,
    );
  }

  factory AppError.authentication(String message, {int? statusCode, String? code, dynamic originalError, StackTrace? stackTrace}) {
    return AppError(
      type: AppErrorType.authentication,
      message: message,
      statusCode: statusCode,
      code: code,
      originalError: originalError,
      stackTrace: stackTrace,
    );
  }

  factory AppError.validation(String message, {String? code, int? statusCode, dynamic originalError, StackTrace? stackTrace}) {
    return AppError(
      type: AppErrorType.validation,
      message: message,
      code: code,
      statusCode: statusCode,
      originalError: originalError,
      stackTrace: stackTrace,
    );
  }

  factory AppError.unknown(String message, {int? statusCode, dynamic originalError, StackTrace? stackTrace}) {
    return AppError(
      type: AppErrorType.unknown,
      message: message,
      statusCode: statusCode,
      originalError: originalError,
      stackTrace: stackTrace,
    );
  }
  
  static AppError rateLimit(String s, {required int statusCode, String? code, required originalError, StackTrace? stackTrace}) {
    return AppError(type: AppErrorType.rateLimit, message: s, statusCode: statusCode, code: code, originalError: originalError, stackTrace: stackTrace);
  }
  
  static AppError timeout(String s, {required originalError, StackTrace? stackTrace}) {
    return AppError(type: AppErrorType.timeout, message: s, originalError: originalError, stackTrace: stackTrace);
  }
}

class ErrorHandler {
  static AppError handleHttpError(http.Response response, {dynamic originalError, StackTrace? stackTrace}) {
    final statusCode = response.statusCode;
    final body = response.body;
    
    try {
      final json = body.isNotEmpty ? Map<String, dynamic>.from(_jsonDecode(body)) : {};
      final errorMessage = json['detail'] ?? json['message'] ?? json['error'] ?? 'Unknown error';
      final errorCode = json['code']?.toString();

      switch (statusCode) {
        case 400:
          return AppError.validation(
            errorMessage.toString(),
            code: errorCode,
            statusCode: statusCode,
            originalError: originalError,
            stackTrace: stackTrace,
          );
        case 401:
          return AppError.authentication(
            errorMessage.toString(),
            code: errorCode,
            statusCode: statusCode,
            originalError: originalError,
            stackTrace: stackTrace,
          );
        case 403:
          return AppError.authentication(
            'Access forbidden',
            code: errorCode,
            statusCode: statusCode,
            originalError: originalError,
            stackTrace: stackTrace,
          );
        case 404:
          return AppError.client(
            'Resource not found',
            statusCode: statusCode,
            code: errorCode,
            originalError: originalError,
            stackTrace: stackTrace,
          );
        case 429:
          return AppError.rateLimit(
            'Too many requests',
            statusCode: statusCode,
            code: errorCode,
            originalError: originalError,
            stackTrace: stackTrace,
          );
        case 500:
        case 502:
        case 503:
        case 504:
          return AppError.server(
            errorMessage.toString(),
            statusCode: statusCode,
            code: errorCode,
            originalError: originalError,
            stackTrace: stackTrace,
          );
        default:
          return AppError.unknown(
            'HTTP error \$statusCode: \$errorMessage',
            statusCode: statusCode,
            originalError: originalError,
            stackTrace: stackTrace,
          );
      }
    } catch (_) {
      return AppError.unknown(
        'HTTP error \$statusCode: \$body',
        statusCode: statusCode,
        originalError: originalError,
        stackTrace: stackTrace,
      );
    }
  }

  static AppError handleException(dynamic error, [StackTrace? stackTrace]) {
    if (error is AppError) return error;
    
    final errorString = error.toString().toLowerCase();
    
    if (error is http.ClientException) {
      return AppError.network(
        'Network error: \${error.message}',
        originalError: error,
        stackTrace: stackTrace,
      );
    }
    
    if (errorString.contains('socket') ||
        errorString.contains('connection') ||
        errorString.contains('network') ||
        errorString.contains('host') ||
        errorString.contains('dns')) {
      return AppError.network(
        'Network connectivity issue',
        originalError: error,
        stackTrace: stackTrace,
      );
    }
    
    if (errorString.contains('timeout') || errorString.contains('timed out')) {
      return AppError.timeout(
        'Request timeout',
        originalError: error,
        stackTrace: stackTrace,
      );
    }
    
    return AppError.unknown(
      error.toString(),
      originalError: error,
      stackTrace: stackTrace,
    );
  }

  static String getUserFriendlyMessage(AppError error) {
    switch (error.type) {
      case AppErrorType.network:
        return 'Network connection issue. Please check your internet connection and try again.';
      case AppErrorType.server:
        return 'Server error occurred. Please try again later.';
      case AppErrorType.client:
        return 'Invalid request. Please check your input and try again.';
      case AppErrorType.authentication:
        return 'Authentication failed. Please log in again.';
      case AppErrorType.validation:
        return error.message;
      case AppErrorType.database:
        return 'Local data storage error. Please restart the app.';
      case AppErrorType.timeout:
        return 'Request timeout. Please try again.';
      case AppErrorType.rateLimit:
        return 'Too many requests. Please wait a moment and try again.';
      case AppErrorType.maintenance:
        return 'Server maintenance in progress. Please try again later.';
      case AppErrorType.unknown:
        return 'An unexpected error occurred. Please try again.';
      case AppErrorType.authorization:
        return 'Authorization Error';
    }
  }

  static bool shouldRetry(AppError error) {
    return error.type == AppErrorType.network ||
           error.type == AppErrorType.timeout ||
           error.type == AppErrorType.rateLimit ||
           (error.type == AppErrorType.server && error.statusCode != 500);
  }

  static Duration getRetryDelay(AppError error, int attempt) {
    const baseDelay = Duration(seconds: 2);
    return baseDelay * (1 << (attempt - 1)); // Exponential backoff
  }
}

class ErrorFeedback {
  static void showErrorSnackBar(BuildContext context, AppError error, {
    String? customMessage,
    Duration duration = const Duration(seconds: 4),
  }) {
    final message = customMessage ?? ErrorHandler.getUserFriendlyMessage(error);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: _getErrorColor(error.type),
        duration: duration,
        action: _getSnackBarAction(error, context),
      ),
    );
  }

  static SnackBarAction? _getSnackBarAction(AppError error, BuildContext context) {
    if (error.type == AppErrorType.authentication) {
      return SnackBarAction(
        label: 'Login',
        onPressed: () {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
        },
      );
    }
    
    if (ErrorHandler.shouldRetry(error)) {
      return SnackBarAction(
        label: 'Retry',
        onPressed: () {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          // This would typically trigger a retry mechanism
        },
      );
    }
    
    return null;
  }

  static Color _getErrorColor(AppErrorType type) {
    switch (type) {
      case AppErrorType.authentication:
        return Colors.orange;
      case AppErrorType.network:
        return Colors.blueGrey;
      case AppErrorType.server:
      case AppErrorType.unknown:
        return Colors.red;
      case AppErrorType.client:
      case AppErrorType.validation:
        return Colors.orangeAccent;
      case AppErrorType.database:
      case AppErrorType.timeout:
      case AppErrorType.rateLimit:
      case AppErrorType.maintenance:
        return Colors.blueGrey;
      case AppErrorType.authorization:
        return Colors.deepPurple;
    }
  }

  static Future<void> showErrorDialog(
    BuildContext context,
    AppError error, {
    String? title,
    String? customMessage,
    List<Widget>? actions,
  }) async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title ?? 'Error'),
        content: Text(customMessage ?? ErrorHandler.getUserFriendlyMessage(error)),
        actions: actions ?? [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}


Map<String, dynamic> _jsonDecode(String body) {
  return json.decode(body) as Map<String, dynamic>;
}