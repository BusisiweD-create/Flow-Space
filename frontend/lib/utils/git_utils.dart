import 'dart:async';
import 'dart:io';

class GitUtils {
  /// Gets the current Git branch name
  static Future<String?> getCurrentBranchName() async {
    try {
      final result = await Process.run('git', ['branch', '--show-current']);
      if (result.exitCode == 0) {
        final branchName = result.stdout.toString().trim();
        return branchName.isNotEmpty ? branchName : null;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Gets the current Git branch name with fallback
  static Future<String> getBranchNameWithFallback() async {
    final branchName = await getCurrentBranchName();
    return branchName ?? 'unknown';
  }

  /// Checks if the current directory is a Git repository
  static Future<bool> isGitRepository() async {
    try {
      final result = await Process.run('git', ['rev-parse', '--is-inside-work-tree']);
      return result.exitCode == 0 && result.stdout.toString().trim() == 'true';
    } catch (e) {
      return false;
    }
  }
}