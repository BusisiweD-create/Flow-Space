// Error utility functions for common error handling patterns

import 'package:flutter/material.dart';
import 'error_handler.dart';

class ErrorUtils {
  // Show error snackbar with retry option
  static void showErrorSnackbar(
    BuildContext context,
    AppError error, {
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ErrorHandler.getUserFriendlyMessage(error)),
        backgroundColor: Colors.red,
        action: onAction != null
            ? SnackBarAction(
                label: actionLabel ?? 'Retry',
                onPressed: onAction,
                textColor: Colors.white,
              )
            : null,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  // Show success snackbar
  static void showSuccessSnackbar(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 2),
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: duration,
      ),
    );
  }

  // Show error dialog with details
  static Future<void> showErrorDialog(
    BuildContext context,
    AppError error, {
    String title = 'Error',
    bool showRetry = false,
    VoidCallback? onRetry,
    VoidCallback? onDismiss,
  }) async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(ErrorHandler.getUserFriendlyMessage(error)),
              if (error.originalError != null) ...[
                const SizedBox(height: 8),
                Text(
                  error.originalError.toString(),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ],
          ),
          actions: [
            if (showRetry && onRetry != null)
              TextButton(
                onPressed: onRetry,
                child: const Text('Retry'),
              ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                onDismiss?.call();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  // Handle common API errors with appropriate user feedback
  static void handleApiError(
    BuildContext context,
    dynamic error, {
    String? contextMessage,
    bool showDialog = false,
    VoidCallback? onRetry,
  }) {
    final appError = ErrorHandler.handleException(error);
    
    if (showDialog) {
      showErrorDialog(
        context,
        appError,
        title: contextMessage ?? 'Operation Failed',
        showRetry: onRetry != null,
        onRetry: onRetry,
      );
    } else {
      showErrorSnackbar(
        context,
        appError,
        actionLabel: onRetry != null ? 'Retry' : null,
        onAction: onRetry,
      );
    }
  }

  // Check if error is network-related
  static bool isNetworkError(dynamic error) {
    final appError = ErrorHandler.handleException(error);
    return appError.type == AppErrorType.network;
  }

  // Check if error is authentication-related
  static bool isAuthError(dynamic error) {
    final appError = ErrorHandler.handleException(error);
    return appError.type == AppErrorType.authentication;
  }

  // Check if error should trigger a logout
  static bool shouldLogoutOnError(dynamic error) {
    final appError = ErrorHandler.handleException(error);
    return appError.type == AppErrorType.authentication;
  }
}

// extension on AppError {
//   static get details => null;
// }