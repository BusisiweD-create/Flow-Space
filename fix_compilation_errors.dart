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
  
  // Fix ApiResponse property access errors
  var fixedContent = content;
  
  // Fix response.success -> response.isSuccess
  fixedContent = fixedContent.replaceAll('response.success', 'response.isSuccess');
  
  // Fix response.message -> response.error
  fixedContent = fixedContent.replaceAll('response.message', 'response.error');
  
  // Write the fixed content back to the file
  file.writeAsStringSync(fixedContent);
  
  print('Fixed ApiResponse property access errors in \$filePath');
  print('Changes made:');
  print('- response.success -> response.isSuccess');
  print('- response.message -> response.error');
}