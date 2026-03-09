// ignore_for_file: avoid_print
import 'dart:io';
import 'dart:convert';

class AutoIncrementVersion {
  static const String versionFilePath = 'lib/utils/version_control.dart';
  static const String versionHistoryPath = 'version_history.json';
  
  static Future<void> incrementReleaseNumber() async {
    try {
      // Read current version file
      final versionFile = File(versionFilePath);
      if (!await versionFile.exists()) {
        throw Exception('Version control file not found');
      }
      
      final content = await versionFile.readAsString();
      
      // Get current date and environment
      final now = DateTime.now();
      const environment = 'PROD';
      final year = now.year;
      final month = now.month.toString().padLeft(2, '0');
      final day = now.day.toString().padLeft(2, '0');
      
      // Read version history to get last release number for today
      final historyFile = File(versionHistoryPath);
      List<Map<String, dynamic>> history = [];
      
      if (await historyFile.exists()) {
        try {
          final historyContent = await historyFile.readAsString();
          history = List<Map<String, dynamic>>.from(
            json.decode(historyContent)
          );
        } catch (e) {
          history = [];
        }
      }
      
      // Find the last release for today
      int lastReleaseNumber = 0;
      final today = '$year-$month-$day';
      
      for (final entry in history) {
        if (entry['date'] == today && entry['environment'] == environment) {
          final releaseNum = int.tryParse(entry['releaseNumber'].toString()) ?? 0;
          if (releaseNum > lastReleaseNumber) {
            lastReleaseNumber = releaseNum;
          }
        }
      }
      
      // Increment release number
      final newReleaseNumber = lastReleaseNumber + 1;
      final newVersion = '$environment-$year-$month-$day-${newReleaseNumber.toString().padLeft(2, '0')}';
      
      // Update version file
      final newContent = content.replaceAll(
        RegExp(r"static const String environment = '[^']*';"),
        "static const String environment = '$environment';"
      );
      
      await versionFile.writeAsString(newContent);
      
      // Add to history
      history.add({
        'date': today,
        'environment': environment,
        'releaseNumber': newReleaseNumber,
        'version': newVersion,
        'timestamp': now.toIso8601String(),
      });
      
      await historyFile.writeAsString(json.encode(history));
      
      // Generate version info file
      final versionInfo = {
        'version': newVersion,
        'environment': environment,
        'releaseNumber': newReleaseNumber,
        'date': today,
        'timestamp': now.toIso8601String(),
      };
      
      await File('version_info.json').writeAsString(json.encode(versionInfo));
      
      stdout.writeln('✅ Version incremented to: $newVersion');
      stdout.writeln('📅 Date: $today');
      stdout.writeln('🔄 Release: $newReleaseNumber');
      
    } catch (e) {
      stderr.writeln('❌ Failed to increment version: $e');
      exit(1);
    }
  }
  
  static Future<String> getCurrentVersion() async {
    try {
      final versionFile = File(versionFilePath);
      if (!await versionFile.exists()) {
        return 'PROD-2026-01-20-01';
      }
      
      // Use the generateVersionNumber method
      final now = DateTime.now();
      final year = now.year;
      final month = now.month.toString().padLeft(2, '0');
      final day = now.day.toString().padLeft(2, '0');
      
      return 'PROD-$year-$month-$day-01'; // Default to release 01
    } catch (e) {
      return 'PROD-2026-01-20-01';
    }
  }
}

void main(List<String> args) async {
  if (args.contains('--increment')) {
    await AutoIncrementVersion.incrementReleaseNumber();
  } else {
    final currentVersion = await AutoIncrementVersion.getCurrentVersion();
    stdout.writeln('Current version: $currentVersion');
  }
}
