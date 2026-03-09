import 'dart:io';

// ignore_for_file: avoid_print
import 'package:khono/utils/version_control.dart';

void main(List<String> args) {
  final versionInfo = VersionControl.getVersionInfo();
  final version = versionInfo['version'];
  
  stdout.writeln('Generated Version: $version');
  stdout.writeln('Environment: ${versionInfo['environment']}');
  stdout.writeln('Date: ${versionInfo['year']}-${versionInfo['month'].toString().padLeft(2, '0')}-${versionInfo['day'].toString().padLeft(2, '0')}');
  stdout.writeln('Week: ${versionInfo['weekNumber']}');
  stdout.writeln('Day: ${versionInfo['dayOfWeek']}');
  stdout.writeln('Release: ${versionInfo['releaseNumber']}');
  
  // Write version to file for build processes
  final versionFile = File('build_version.txt');
  versionFile.writeAsStringSync(version);
  stdout.writeln('Version written to build_version.txt');
  
  // Create version info JSON
  final jsonFile = File('version_info.json');
  final jsonContent = '''
{
  "version": "$version",
  "environment": "${versionInfo['environment']}",
  "buildDate": "${versionInfo['year']}-${versionInfo['month'].toString().padLeft(2, '0')}-${versionInfo['day'].toString().padLeft(2, '0')}",
  "weekNumber": ${versionInfo['weekNumber']},
  "dayOfWeek": ${versionInfo['dayOfWeek']},
  "releaseNumber": ${versionInfo['releaseNumber']},
  "timestamp": "${versionInfo['timestamp']}"
}
''';
  jsonFile.writeAsStringSync(jsonContent);
  stdout.writeln('Version info written to version_info.json');
}
