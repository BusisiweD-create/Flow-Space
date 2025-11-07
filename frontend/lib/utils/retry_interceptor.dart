// Retry interceptor for HTTP requests with exponential backoff

import 'package:http/http.dart' as http;
import 'error_handler.dart';

class RetryOptions {
  final int maxRetries;
  final Duration maxDelay;
  final bool retryOnNetworkErrors;
  final bool retryOnServerErrors;
  final bool retryOnClientErrors;

  const RetryOptions({
    this.maxRetries = 3,
    this.maxDelay = const Duration(seconds: 30),
    this.retryOnNetworkErrors = true,
    this.retryOnServerErrors = true,
    this.retryOnClientErrors = false,
  });
}

class RetryInterceptor {
  static Future<http.Response> executeWithRetry(
    Future<http.Response> Function() requestFn,
    RetryOptions options, {
    void Function(AppError error, int attempt, Duration delay)? onRetry,
  }) async {
    int attempt = 1;
    
    while (true) {
      try {
        final response = await requestFn();
        
        // Check if response indicates an error that should be retried
        if (response.statusCode >= 400) {
          final error = ErrorHandler.handleHttpError(response);
          
          if (_shouldRetryBasedOnOptions(error, options, attempt)) {
            final delay = ErrorHandler.getRetryDelay(error, attempt);
            await _delayWithCallback(delay, error, attempt, onRetry);
            attempt++;
            continue;
          }
          
          // If we shouldn't retry, throw the error
          throw error;
        }
        
        // Successful response
        return response;
      } catch (error) {
        final appError = ErrorHandler.handleException(error);
        
        if (_shouldRetryBasedOnOptions(appError, options, attempt)) {
          final delay = ErrorHandler.getRetryDelay(appError, attempt);
          await _delayWithCallback(delay, appError, attempt, onRetry);
          attempt++;
          continue;
        }
        
        // Max retries reached or shouldn't retry
        rethrow;
      }
    }
  }

  static bool _shouldRetryBasedOnOptions(AppError error, RetryOptions options, int attempt) {
    if (attempt >= options.maxRetries) return false;
    
    final shouldRetry = ErrorHandler.shouldRetry(error);
    
    if (!shouldRetry) return false;
    
    // Check specific retry options
    if (error.type == AppErrorType.network && !options.retryOnNetworkErrors) {
      return false;
    }
    
    if (error.type == AppErrorType.server && !options.retryOnServerErrors) {
      return false;
    }
    
    if (error.type == AppErrorType.client && !options.retryOnClientErrors) {
      return false;
    }
    
    return true;
  }

  static Future<void> _delayWithCallback(
    Duration delay,
    AppError error,
    int attempt,
    void Function(AppError error, int attempt, Duration delay)? callback,
  ) async {
    callback?.call(error, attempt, delay);
    await Future.delayed(delay);
  }

  static Future<T> wrapWithRetry<T>(
    Future<T> Function() fn,
    RetryOptions options, {
    void Function(AppError error, int attempt, Duration delay)? onRetry,
  }) async {
    int attempt = 1;
    
    while (true) {
      try {
        return await fn();
      } catch (error) {
        final appError = ErrorHandler.handleException(error);
        
        if (_shouldRetryBasedOnOptions(appError, options, attempt)) {
          final delay = ErrorHandler.getRetryDelay(appError, attempt);
          await _delayWithCallback(delay, appError, attempt, onRetry);
          attempt++;
          continue;
        }
        
        rethrow;
      }
    }
  }
}