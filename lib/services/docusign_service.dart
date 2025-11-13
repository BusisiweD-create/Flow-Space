import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

/// DocuSign Integration Service
/// Note: This requires DocuSign API credentials to be configured
class DocuSignService {
  static const String _baseUrl = 'https://demo.docusign.net/restapi'; // Use demo for testing
  String? _accessToken;
  String? _accountId;
  
  // These should be set from environment variables or config
  String? _integrationKey;
  String? _userId;
  String? _rsaPrivateKey;
  
  /// Initialize DocuSign service with credentials
  void initialize({
    required String integrationKey,
    required String userId,
    required String rsaPrivateKey,
    String? accountId,
  }) {
    _integrationKey = integrationKey;
    _userId = userId;
    _rsaPrivateKey = rsaPrivateKey;
    _accountId = accountId;
  }
  
  /// Authenticate with DocuSign (JWT OAuth)
  Future<bool> authenticate() async {
    if (_integrationKey == null || _userId == null || _rsaPrivateKey == null) {
      debugPrint('❌ DocuSign credentials not configured');
      return false;
    }
    
    try {
      // Generate JWT token
      final jwt = _generateJWT();
      
      // Request access token
      final response = await http.post(
        Uri.parse('https://account.docusign.com/oauth/token'),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'grant_type': 'urn:ietf:params:oauth:grant-type:jwt-bearer',
          'assertion': jwt,
        },
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _accessToken = data['access_token'];
        _accountId = data['account_id'] ?? _accountId;
        debugPrint('✅ DocuSign authenticated successfully');
        return true;
      } else {
        debugPrint('❌ DocuSign authentication failed: ${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint('❌ DocuSign authentication error: $e');
      return false;
    }
  }
  
  /// Create an envelope (document to sign) for a report
  Future<String?> createEnvelope({
    required String reportId,
    required String reportTitle,
    required String reportContent,
    required String signerEmail,
    required String signerName,
    String? signerRole,
  }) async {
    if (_accessToken == null || _accountId == null) {
      debugPrint('❌ DocuSign not authenticated');
      return null;
    }
    
    try {
      // Create document from report content
      final documentBase64 = base64Encode(utf8.encode(_formatReportForDocuSign(reportTitle, reportContent)));
      
      // Create envelope definition
      final envelopeDefinition = {
        'emailSubject': 'Please sign: $reportTitle',
        'documents': [
          {
            'documentBase64': documentBase64,
            'name': '$reportTitle.pdf',
            'fileExtension': 'pdf',
            'documentId': '1',
          },
        ],
        'recipients': {
          'signers': [
            {
              'email': signerEmail,
              'name': signerName,
              'recipientId': '1',
              'routingOrder': '1',
              'tabs': {
                'signHereTabs': [
                  {
                    'documentId': '1',
                    'pageNumber': '1',
                    'recipientId': '1',
                    'xPosition': '100',
                    'yPosition': '100',
                  },
                ],
              },
            },
          ],
        },
        'status': 'sent',
      };
      
      // Send envelope
      final response = await http.post(
        Uri.parse('$_baseUrl/v2.1/accounts/$_accountId/envelopes'),
        headers: {
          'Authorization': 'Bearer $_accessToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(envelopeDefinition),
      );
      
      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final envelopeId = data['envelopeId'] as String;
        debugPrint('✅ DocuSign envelope created: $envelopeId');
        return envelopeId;
      } else {
        debugPrint('❌ Failed to create DocuSign envelope: ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('❌ Error creating DocuSign envelope: $e');
      return null;
    }
  }
  
  /// Get envelope status
  Future<Map<String, dynamic>?> getEnvelopeStatus(String envelopeId) async {
    if (_accessToken == null || _accountId == null) {
      return null;
    }
    
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/v2.1/accounts/$_accountId/envelopes/$envelopeId'),
        headers: {
          'Authorization': 'Bearer $_accessToken',
        },
      );
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      debugPrint('❌ Error getting envelope status: $e');
      return null;
    }
  }
  
  /// Generate JWT token for DocuSign authentication
  String _generateJWT() {
    // This is a simplified version - in production, use a proper JWT library
    // and implement RSA signing with the private key
    // Note: In production, properly sign this with RSA private key
    // This is a placeholder - you'll need to use a JWT library like 'dart_jsonwebtoken'
    // For now, return a placeholder token
    return 'placeholder_jwt_token';
  }
  
  String _formatReportForDocuSign(String title, String content) {
    return '''
SIGN-OFF REPORT

Title: $title

Content:
$content

---
This document requires your signature.
''';
  }
}

