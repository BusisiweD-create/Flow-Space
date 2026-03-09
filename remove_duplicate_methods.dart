// ignore_for_file: avoid_print

import 'dart:io';

void main() {
  const filePath = r'C:\Flow\lib\screens\role_dashboard_screen.dart';
  final file = File(filePath);
  
  if (!file.existsSync()) {
    print('File not found: \$filePath');
    return;
  }
  
  final content = file.readAsStringSync();
  
  // Find the position of the first duplicate method
  final firstDuplicatePos = content.indexOf('  Future<void> _clearCache() async {');
  if (firstDuplicatePos == -1) {
    print('No duplicate methods found.');
    return;
  }
  
  // Find the position where the duplicate methods end (before the closing brace)
  final lastBracePos = content.lastIndexOf('}');
  
  if (lastBracePos == -1) {
    print('Could not find closing brace.');
    return;
  }
  
  // Extract the content before duplicates and after duplicates
  final contentBeforeDuplicates = content.substring(0, firstDuplicatePos);
  final contentAfterDuplicates = content.substring(lastBracePos + 1);
  
  // Reconstruct the file content without duplicates
  final fixedContent = contentBeforeDuplicates + contentAfterDuplicates;
  
  // Write the fixed content back to the file
  file.writeAsStringSync(fixedContent);
  
  print('Removed duplicate method declarations from \$filePath');
  print('Removed methods: _clearCache, _optimizeDatabase, _runDiagnostics');
}