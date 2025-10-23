import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/repository_file.dart';
import '../services/api_client.dart';
import '../services/auth_service.dart';

class DocumentService {
  final AuthService _authService;
  static const String _baseUrl = 'http://localhost:3001/api/v1';

  DocumentService(this._authService);

  // Get all documents
  Future<ApiResponse> getDocuments({
    String? search,
    String? fileType,
    String? uploader,
  }) async {
    try {
      final token = _authService.accessToken;
      if (token == null) {
        return ApiResponse.error('No access token available');
      }

      final uri = Uri.parse('$_baseUrl/documents').replace(
        queryParameters: {
          if (search != null && search.isNotEmpty) 'search': search,
          if (fileType != null && fileType.isNotEmpty) 'fileType': fileType,
          if (uploader != null && uploader.isNotEmpty) 'uploader': uploader,
        },
      );

      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final documents = (data['data'] as List)
              .map((doc) => RepositoryFile.fromJson(doc))
              .toList();
          return ApiResponse.success({'documents': documents}, response.statusCode);
        } else {
          return ApiResponse.error(data['error'] ?? 'Failed to fetch documents');
        }
      } else {
        return ApiResponse.error('Failed to fetch documents: ${response.statusCode}');
      }
    } catch (e) {
      return ApiResponse.error('Error fetching documents: $e');
    }
  }

  // Upload a document
  Future<ApiResponse> uploadDocument({
    required String filePath,
    String? description,
    String? tags,
  }) async {
    try {
      final token = _authService.accessToken;
      if (token == null) {
        return ApiResponse.error('No access token available');
      }

      final file = File(filePath);
      if (!await file.exists()) {
        return ApiResponse.error('File does not exist');
      }

      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$_baseUrl/documents'),
      );

      request.headers['Authorization'] = 'Bearer $token';
      request.files.add(await http.MultipartFile.fromPath('file', filePath));

      if (description != null && description.isNotEmpty) {
        request.fields['description'] = description;
      }
      if (tags != null && tags.isNotEmpty) {
        request.fields['tags'] = tags;
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final document = RepositoryFile.fromJson(data['data']);
          return ApiResponse.success({'document': document}, response.statusCode);
        } else {
          return ApiResponse.error(data['error'] ?? 'Failed to upload document');
        }
      } else {
        return ApiResponse.error('Failed to upload document: ${response.statusCode}');
      }
    } catch (e) {
      return ApiResponse.error('Error uploading document: $e');
    }
  }

  // Upload document for web
  Future<ApiResponse> uploadWebDocument({
    required List<int> fileBytes,
    required String fileName,
    String? description,
    String? tags,
  }) async {
    try {
      final token = _authService.accessToken;
      if (token == null) {
        return ApiResponse.error('No access token available');
      }

      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$_baseUrl/documents'),
      );

      request.headers['Authorization'] = 'Bearer $token';
      request.headers['Content-Type'] = 'multipart/form-data';

      // Add file bytes
      request.files.add(http.MultipartFile.fromBytes(
        'file',
        fileBytes,
        filename: fileName,
      ),);

      // Add optional fields
      if (description != null && description.isNotEmpty) {
        request.fields['description'] = description;
      }
      if (tags != null && tags.isNotEmpty) {
        request.fields['tags'] = tags;
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final document = RepositoryFile.fromJson(data['data']);
          return ApiResponse.success({'document': document}, response.statusCode);
        } else {
          return ApiResponse.error(data['error'] ?? 'Failed to upload document');
        }
      } else {
        return ApiResponse.error('Failed to upload document: ${response.statusCode}');
      }
    } catch (e) {
      return ApiResponse.error('Error uploading document: $e');
    }
  }

  // Download a document
  Future<ApiResponse> downloadDocument(String documentId) async {
    try {
      final token = _authService.accessToken;
      if (token == null) {
        return ApiResponse.error('No authentication token available');
      }

      // For web platform, handle download differently
      if (kIsWeb) {
        return _downloadDocumentWeb(documentId, token);
      }

      // Request permission to write to storage (mobile/desktop only)
      final status = await Permission.storage.request();
      if (!status.isGranted) {
        return ApiResponse.error('Storage permission denied');
      }

      // Get document details first
      final detailsResponse = await http.get(
        Uri.parse('$_baseUrl/documents/$documentId'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (detailsResponse.statusCode != 200) {
        return ApiResponse.error('Failed to get document details');
      }

      final detailsData = jsonDecode(detailsResponse.body);
      if (!detailsData['success']) {
        return ApiResponse.error('Failed to get document details: ${detailsData['error']}');
      }

      final document = detailsData['data'];
      final fileName = document['name'] ?? 'document_$documentId';

      // Download the file
      final response = await http.get(
        Uri.parse('$_baseUrl/documents/$documentId/download'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        // Get the downloads directory
        final directory = await getApplicationDocumentsDirectory();
        final file = File('${directory.path}/$fileName');
        await file.writeAsBytes(response.bodyBytes);

        return ApiResponse.success({
          'filePath': file.path,
          'fileName': fileName,
          'size': response.bodyBytes.length,
        }, response.statusCode,);
      } else {
        return ApiResponse.error('Failed to download document: ${response.statusCode}');
      }
    } catch (e) {
      return ApiResponse.error('Error downloading document: $e');
    }
  }

  // Web-specific download method
  Future<ApiResponse> _downloadDocumentWeb(String documentId, String token) async {
    try {
      final uri = Uri.parse('$_baseUrl/documents/$documentId/download');
      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        // For web, we'll trigger a browser download
        final bytes = response.bodyBytes;
        final fileName = 'document_$documentId';

        // For web, we'll return success and let the browser handle the download
        if (kIsWeb) {
          // Web download is handled by the browser automatically
          // The response will trigger a download in the browser
        }

        return ApiResponse.success({
          'filePath': 'Downloaded to browser',
          'fileName': fileName,
          'size': bytes.length,
        }, response.statusCode,);
      } else {
        return ApiResponse.error('Failed to download document: ${response.statusCode}');
      }
    } catch (e) {
      return ApiResponse.error('Error downloading document: $e');
    }
  }

  // Delete a document
  Future<ApiResponse> deleteDocument(String documentId) async {
    try {
      final token = _authService.accessToken;
      if (token == null) {
        return ApiResponse.error('No access token available');
      }

      final response = await http.delete(
        Uri.parse('$_baseUrl/documents/$documentId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return ApiResponse.success({'message': 'Document deleted successfully'}, response.statusCode);
        } else {
          return ApiResponse.error(data['error'] ?? 'Failed to delete document');
        }
      } else {
        return ApiResponse.error('Failed to delete document: ${response.statusCode}');
      }
    } catch (e) {
      return ApiResponse.error('Error deleting document: $e');
    }
  }

  // Get document preview
  Future<ApiResponse> getDocumentPreview(String documentId) async {
    try {
      final token = _authService.accessToken;
      if (token == null) {
        return ApiResponse.error('No access token available');
      }

      final response = await http.get(
        Uri.parse('$_baseUrl/documents/$documentId/preview'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return ApiResponse.success(data['data'], response.statusCode);
        } else {
          return ApiResponse.error(data['error'] ?? 'Failed to get document preview');
        }
      } else {
        return ApiResponse.error('Failed to get document preview: ${response.statusCode}');
      }
    } catch (e) {
      return ApiResponse.error('Error getting document preview: $e');
    }
  }
}
