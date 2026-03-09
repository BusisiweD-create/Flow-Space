// ignore_for_file: avoid_print
import 'dart:io';
import 'package:khono/utils/version_control.dart';
import 'package:khono/utils/version_config.dart';
import 'package:khono/services/deployment_service.dart';

void main(List<String> args) async {
  if (args.isEmpty) {
    _showUsage();
    return;
  }

  final environment = args[0].toUpperCase();
  final approvals = args.skip(1).toList();

  try {
    // Validate environment
    if (!VersionConfig.isValidEnvironment(environment)) {
      throw Exception('Invalid environment: $environment. Valid options: ${VersionConfig.environments.keys.join(', ')}');
    }

    // Validate approvals for production environments
    if (['PROD', 'UAT'].contains(environment)) {
      await DeploymentService.validateDeployment(environment, approvals);
    }

    // Auto-increment version for production deployments
    if (environment == 'PROD') {
      stdout.writeln('🔄 Auto-incrementing version for production deployment...');
      await _autoIncrementVersion();
    }

    // Switch environment
    await DeploymentService.switchEnvironment(environment);

    // Generate deployment artifacts
    await _generateDeploymentArtifacts(environment);

    stdout.writeln('\n🚀 Deployment Summary:');
    stdout.writeln('   Environment: $environment');
    stdout.writeln('   Version: ${VersionControl.generateVersionNumber()}');
    stdout.writeln('   Display Name: ${VersionConfig.getEnvironmentDisplayName(environment)}');
    stdout.writeln('   Timestamp: ${DateTime.now().toIso8601String()}');
    
    if (approvals.isNotEmpty) {
      stdout.writeln('   Approvals: ${approvals.join(', ')}');
    }

    stdout.writeln('\n✅ Environment switch completed successfully!');
    stdout.writeln('\n📋 Next Steps:');
    stdout.writeln('   1. Commit the changes to version control');
    stdout.writeln('   2. Run: flutter build web');
    stdout.writeln('   3. Deploy to $environment environment');

  } catch (e) {
    stderr.writeln('❌ Deployment failed: $e');
    exit(1);
  }
}

Future<void> _autoIncrementVersion() async {
  try {
    // Run the auto-increment script
    final result = await Process.run('dart', ['scripts/auto_increment_version.dart', '--increment']);
    
    if (result.exitCode != 0) {
      throw Exception('Failed to auto-increment version: ${result.stderr}');
    }
    
    stdout.writeln('✅ Version auto-incremented successfully');
  } catch (e) {
    stderr.writeln('⚠️ Warning: Could not auto-increment version: $e');
  }
}

void _showUsage() {
  stdout.writeln('🔧 Flow Space Environment Deployment Tool');
  stdout.writeln('');
  stdout.writeln('Usage: dart scripts/deploy_environment.dart <ENVIRONMENT> [APPROVALS...]');
  stdout.writeln('');
  stdout.writeln('Environments:');
  VersionConfig.environments.forEach((env, name) {
    final required = VersionConfig.requiredApprovals[env] ?? [];
    stdout.writeln('   $env - $name ${required.isNotEmpty ? '(requires: ${required.join(', ')})' : ''}');
  });
  stdout.writeln('');
  stdout.writeln('Examples:');
  stdout.writeln('   dart scripts/deploy_environment.dart SIT');
  stdout.writeln('   dart scripts/deploy_environment.dart UAT senior-developer qa-lead');
  stdout.writeln('   dart scripts/deploy_environment.dart PROD senior-developer tech-lead devops');
  stdout.writeln('');
}

Future<void> _generateDeploymentArtifacts(String environment) async {
  final version = VersionControl.generateVersionNumber();
  final timestamp = DateTime.now().toIso8601String();
  
  // Generate deployment manifest
  final manifest = {
    'environment': environment,
    'version': version,
    'displayName': VersionConfig.getEnvironmentDisplayName(environment),
    'colors': VersionConfig.getEnvironmentColors(environment),
    'pipeline': VersionConfig.pipelineConfig[environment],
    'requiredApprovals': VersionConfig.requiredApprovals[environment],
    'timestamp': timestamp,
    'buildInfo': {
      'flutterVersion': '3.10.0',
      'dartVersion': '3.0.0',
      'platform': 'web',
    },
  };

  final manifestFile = File('deployment_manifest.json');
  await manifestFile.writeAsString(_formatJson(manifest));

  // Generate version tag
  final tagFile = File('version_tag.txt');
  await tagFile.writeAsString(version);

  stdout.writeln('📄 Generated deployment artifacts:');
  stdout.writeln('   - deployment_manifest.json');
  stdout.writeln('   - version_tag.txt');
}

String _formatJson(Map<String, dynamic> json) {
  String result = '{\n';
  json.forEach((key, value) {
    result += '  "$key": ${_formatJsonValue(value)},\n';
  });
  result += '}';
  return result;
}

String _formatJsonValue(dynamic value) {
  if (value is String) return '"$value"';
  if (value is Map) {
    String result = '{\n';
    value.forEach((k, v) {
      result += '    "$k": ${_formatJsonValue(v)},\n';
    });
    result += '  }';
    return result;
  }
  if (value is List) {
    String result = '[\n';
    for (var item in value) {
      result += '    ${_formatJsonValue(item)},\n';
    }
    result += '  ]';
    return result;
  }
  return value.toString();
}
