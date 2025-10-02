// ignore_for_file: unused_element, avoid_print, prefer_final_locals, require_trailing_commas, unused_import

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/environment.dart';
import 'api_service.dart';

class ProfileService {
  static const String _userIdKey = 'current_user_id';

  static Future<String> _getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString(_userIdKey);
    if (userId == null || userId.isEmpty) {
      throw Exception('No user ID found. Please log in first.');
    }
    return userId;
  }

  static Future<Map<String, dynamic>> getUserProfile() async {
    try {
      final userId = await _getUserId();
      final response = await http.get(
        Uri.parse('${Environment.apiBaseUrl}/profile/$userId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load profile: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching profile: $e');
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> saveUserProfile(Map<String, dynamic> profile) async {
    try {
      final userId = await _getUserId();
      
      final existingProfile = await _checkProfileExists(userId);
      
      final response = await (existingProfile
          ? http.put(
              Uri.parse('${Environment.apiBaseUrl}/profile/$userId'),
              headers: {'Content-Type': 'application/json'},
              body: json.encode(profile),
            )
          : http.post(
              Uri.parse('${Environment.apiBaseUrl}/profile/'),
              headers: {'Content-Type': 'application/json'},
              body: json.encode({...profile, 'user_id': userId}),
            ));

      if (response.statusCode == 200 || response.statusCode == 201) {
        final savedProfile = json.decode(response.body);
        await _saveLocalProfile(savedProfile);
        return savedProfile;
      } else {
        throw Exception('Failed to save profile: ${response.statusCode}');
      }
    } catch (e) {
      print('Error saving profile: $e');
      await _saveLocalProfile(profile);
      return profile;
    }
  }

  static Future<bool> _checkProfileExists(String userId) async {
    try {
      final response = await http.get(
        Uri.parse('${Environment.apiBaseUrl}/profile/$userId'),
        headers: {'Content-Type': 'application/json'},
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  static Future<Map<String, dynamic>> uploadProfilePicture(List<int> imageBytes, String fileName) async {
    try {
      final userId = await _getUserId();
      
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${Environment.apiBaseUrl}/profile/$userId/upload-picture'),
      );
      
      request.files.add(http.MultipartFile.fromBytes(
        'file',
        imageBytes,
        filename: fileName,
      ));

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        return json.decode(responseBody);
      } else {
        throw Exception('Failed to upload picture: ${response.statusCode}');
      }
    } catch (e) {
      print('Error uploading picture: $e');
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> _getLocalProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final profileJson = prefs.getString('user_profile');
    
    if (profileJson != null) {
      return json.decode(profileJson);
    } else {
      return {
        'user_id': '',
        'first_name': '',
        'last_name': '',
        'email': '',
        'phone_number': '',
        'profile_picture': '',
        'bio': '',
        'job_title': '',
        'company': '',
        'location': '',
        'website': '',
        'date_of_birth': null,
      };
    }
  }

  static Future<void> _saveLocalProfile(Map<String, dynamic> profile) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_profile', json.encode(profile));
  }
}