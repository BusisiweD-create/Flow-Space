import 'dart:convert';
// ignore: depend_on_referenced_packages
import 'package:http/http.dart' as http;
import 'notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/environment.dart';
import 'package:flutter/foundation.dart';
import 'auth_service.dart';

class SprintDatabaseService {
  static const String _baseUrl = Environment.apiBaseUrl;
  final NotificationService _notificationService = NotificationService();
  final AuthService _authService = AuthService();
  
  // API Client for making HTTP requests
  Future<http.Response> _post(String endpoint, Map<String, dynamic> data) async {
    return await http.post(
      Uri.parse('$_baseUrl$endpoint'),
      headers: _headers,
      body: jsonEncode(data),
    );
  }
  

  // Get authentication token from AuthService
  String? get _token => _authService.accessToken;

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    if (_token != null) 'Authorization': 'Bearer $_token',
  };

  // ===== SPRINT MANAGEMENT =====

  /// Get all sprints for the current user
  Future<List<Map<String, dynamic>>> getSprints({String? projectId, String? projectKey}) async {
    try {
      final uri = Uri.parse('$_baseUrl/sprints').replace(queryParameters: {
        if (projectId != null && projectId.isNotEmpty) 'project_id': projectId,
        if (projectKey != null && projectKey.isNotEmpty) 'project_key': projectKey,
      });
      final response = await http.get(uri, headers: _headers);

      if (response.statusCode == 200) {
        final dynamic data = jsonDecode(response.body);
        List<Map<String, dynamic>> list;
        if (data is List) {
          list = List<Map<String, dynamic>>.from(data);
        } else {
          final List<dynamic> items = (data is Map)
              ? (data['data'] ?? data['sprints'] ?? data['items'] ?? [])
              : [];
          list = items.cast<Map<String, dynamic>>();
        }

        // Client-side filter if backend doesn't honor query
        if ((projectId != null && projectId.isNotEmpty) || (projectKey != null && projectKey.isNotEmpty)) {
          list = list.where((s) {
            final pid = (s['project_id'] ?? s['projectId'] ?? (s['project'] is Map ? (s['project']['id']?.toString()) : null))?.toString();
            final pkey = (s['project_key'] ?? s['projectKey'] ?? (s['project'] is Map ? (s['project']['key']?.toString()) : null))?.toString();
            final idMatch = projectId != null && projectId.isNotEmpty && pid == projectId;
            final keyMatch = projectKey != null && projectKey.isNotEmpty && pkey == projectKey;
            return (projectId != null && projectId.isNotEmpty) ? idMatch : keyMatch;
          }).toList();
        }

        await _saveCachedSprints(list, projectId: projectId, projectKey: projectKey);
        return list;
      }
      return await _getCachedSprints(projectId: projectId, projectKey: projectKey);
    } catch (e) {
      debugPrint('❌ Error fetching sprints: $e');
      return await _getCachedSprints(projectId: projectId, projectKey: projectKey);
    }
  }

  /// Create a new sprint
  Future<Map<String, dynamic>> createSprint({
    required String name,
    String? description,
    required DateTime startDate,
    required DateTime endDate,
    String? goal,
    int? boardId,
    String? projectId,
    int plannedPoints = 0,
  }) async {
    try {
      final body = {
        'name': name,
        'description': description ?? '',
        'start_date': startDate.toIso8601String(),
        'end_date': endDate.toIso8601String(),
        if (goal != null) 'goal': goal,
        if (boardId != null) 'boardId': boardId,
        if (projectId != null) 'project_id': projectId,
        'planned_points': plannedPoints,
      };

      debugPrint('🚀 Creating sprint with data: $body');
      final response = await http.post(
        Uri.parse('$_baseUrl/sprints'),
        headers: _headers,
        body: jsonEncode(body),
      );

      debugPrint('📡 Sprint creation response: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          debugPrint('✅ Sprint "$name" created successfully');
          
          // Send notification for sprint creation
          try {
            final token = _authService.accessToken;
            if (token != null) {
              _notificationService.setAuthToken(token);
              final user = _authService.currentUser;
              final userName = user?.name ?? 'Unknown User';
              
              await _notificationService.notifySprintCreated(
                sprintName: name,
                projectName: projectId ?? 'Current Project',
                createdBy: userName,
              );
            }
          } catch (e) {
            debugPrint('❌ Error sending sprint creation notification: $e');
          }
          
          final created = Map<String, dynamic>.from(data['data']);
          // Cache: prepend to global and project-specific cache
          try {
            await _prependCachedSprint(created, projectId: projectId);
          } catch (_) {}
          return created;
        } else {
          throw Exception(data['error'] ?? 'Failed to create sprint');
        }
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['error'] ?? 'Failed to create sprint');
      }
    } catch (e) {
      debugPrint('❌ Error creating sprint: $e');
      rethrow;
    }
  }

  /// Update sprint
  Future<Map<String, dynamic>?> updateSprint({
    required int sprintId,
    String? name,
    String? goal,
    String? state,
    DateTime? startDate,
    DateTime? endDate,
    String? projectId,
  }) async {
    try {
      final body = <String, dynamic>{};
      if (name != null) body['name'] = name;
      if (goal != null) body['goal'] = goal;
      if (state != null) body['state'] = state;
      if (startDate != null) body['startDate'] = startDate.toIso8601String();
      if (endDate != null) body['endDate'] = endDate.toIso8601String();
      if (projectId != null) body['project_id'] = projectId;

      final response = await http.put(
        Uri.parse('$_baseUrl/sprints/$sprintId'),
        headers: _headers,
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          debugPrint('✅ Sprint $sprintId updated successfully');
          return data['data'];
        }
      }
      
      debugPrint('❌ Failed to update sprint: ${response.statusCode}');
      return null;
    } catch (e) {
      debugPrint('❌ Error updating sprint: $e');
      return null;
    }
  }

  // ===== PROJECT MANAGEMENT =====

  /// Create a new project
  Future<Map<String, dynamic>?> createProject({
    required String name,
    String? key,
    String? description,
    String? projectType,
    DateTime? startDate,
    DateTime? endDate,
    String? clientEmail,
  }) async {
    try {
      final body = {
        'name': name,
        if (key != null) 'key': key,
        if (description != null) 'description': description,
        if (projectType != null) 'projectType': projectType,
        if (startDate != null) 'start_date': startDate.toIso8601String(),
        if (endDate != null) 'end_date': endDate.toIso8601String(),
        if (clientEmail != null) 'client_email': clientEmail,
      };

      final response = await http.post(
        Uri.parse('$_baseUrl/projects'),
        headers: _headers,
        body: jsonEncode(body),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final dynamic data = jsonDecode(response.body);
        if (data is Map) {
          final dynamic item = data['data'] ?? data['project'] ?? data;
          if (item is Map) return Map<String, dynamic>.from(item);
          if (item is List && item.isNotEmpty) return Map<String, dynamic>.from(item.first);
        }
        if (data is List && data.isNotEmpty) {
          return Map<String, dynamic>.from(data.first);
        }
      }
      return null;
    } catch (e) {
      debugPrint('❌ Error creating project: $e');
      return null;
    }
  }

  /// Get all projects
  Future<List<Map<String, dynamic>>> getProjects() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/projects'),
        headers: _headers,
      );
      if (response.statusCode == 200) {
        final dynamic data = jsonDecode(response.body);
        if (data is List) {
          return List<Map<String, dynamic>>.from(data);
        }
        final List<dynamic> items = (data is Map)
            ? (data['data'] ?? data['projects'] ?? data['items'] ?? [])
            : [];
        return items.cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e) {
      debugPrint('❌ Error fetching projects: $e');
      return [];
    }
  }

  // ===== TICKET MANAGEMENT =====

  /// Get all tickets for a sprint
  Future<List<Map<String, dynamic>>> getSprintTickets(String sprintId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/sprints/$sprintId/tickets'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final dynamic raw = jsonDecode(response.body);
        if (raw is List) {
          final list = raw.cast<Map<String, dynamic>>();
          await _saveCachedTickets(sprintId, list);
          return list;
        }
        if (raw is Map) {
          final List<dynamic> items = raw['data'] ?? raw['tickets'] ?? raw['items'] ?? [];
          debugPrint('✅ Fetched ${items.length} tickets for sprint $sprintId');
          final list = items.cast<Map<String, dynamic>>();
          await _saveCachedTickets(sprintId, list);
          return list;
        }
      }
      debugPrint('❌ Failed to fetch tickets: ${response.statusCode}');
      return await _getCachedTickets(sprintId);
    } catch (e) {
      debugPrint('❌ Error fetching tickets: $e');
      return await _getCachedTickets(sprintId);
    }
  }

  /// Get sprint details by ID
  Future<Map<String, dynamic>?> getSprintDetails(String sprintId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/sprints/$sprintId'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final dynamic raw = jsonDecode(response.body);
        if (raw is Map) {
          final dynamic body = raw['data'] ?? raw['sprint'] ?? raw;
          if (body is Map) {
            debugPrint('✅ Fetched sprint details for sprint $sprintId');
            return Map<String, dynamic>.from(body);
          }
          if (body is List && body.isNotEmpty) {
            debugPrint('✅ Fetched sprint details for sprint $sprintId');
            return Map<String, dynamic>.from(body.first);
          }
        } else if (raw is List && raw.isNotEmpty) {
          return Map<String, dynamic>.from(raw.first);
        }
      }
      debugPrint('❌ Failed to fetch sprint details: ${response.statusCode}');
      return null;
    } catch (e) {
      debugPrint('❌ Error fetching sprint details: $e');
      return null;
    }
  }

  /// Create a new ticket
  Future<Map<String, dynamic>?> createTicket({
    required String sprintId,
    required String title,
    required String description,
    String? assignee,
    required String priority,
    required String type,
  }) async {
    try {
      debugPrint('🎫 Creating ticket: $title for sprint $sprintId');
      
      final body = {
        'sprintId': int.tryParse(sprintId) ?? sprintId,
        'title': title,
        'description': description,
        'assignee': assignee,
        'priority': priority,
        'type': type,
        'status': 'To Do',
      };

      try {
        final user = await _authService.getCurrentUser();
        final reporter = (user != null)
            ? user.email
            : null;
        if (reporter != null && reporter.toString().isNotEmpty) {
          body['reporter'] = reporter;
        }
      } catch (e) {
        // Continue without reporter if user retrieval fails
      }

      final response = await _post('/tickets', body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final dynamic raw = jsonDecode(response.body);
        if (raw is Map && (raw['success'] == true || raw.containsKey('data'))) {
          debugPrint('✅ Ticket "$title" created successfully');
          final created = Map<String, dynamic>.from(raw['data'] ?? raw);
          try { await _prependCachedTicket(sprintId, created); } catch (_) {}
          return created;
        }
      }
      
      debugPrint('❌ Failed to create ticket: ${response.statusCode}');
      return null;
    } catch (e) {
      debugPrint('❌ Error creating ticket: $e');
      return null;
    }
  }

  /// Update ticket status (for drag and drop)
  Future<bool> updateTicketStatus({
    required String ticketId,
    required String status,
  }) async {
    try {
      final body = {'status': status};

      final response = await http.put(
        Uri.parse('$_baseUrl/tickets/$ticketId/status'),
        headers: _headers,
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          debugPrint('✅ Ticket $ticketId status updated to $status');
          try { await _updateCachedTicketStatus(ticketId, status); } catch (_) {}
          return true;
        }
      }
      
      debugPrint('❌ Failed to update ticket status: ${response.statusCode}');
      return false;
    } catch (e) {
      debugPrint('❌ Error updating ticket status: $e');
      return false;
    }
  }

  // Ticket cache helpers
  static String _ticketsKey(String sprintId) => 'cached_tickets_$sprintId';

  static Future<void> _saveCachedTickets(String sprintId, List<Map<String, dynamic>> tickets) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_ticketsKey(sprintId), jsonEncode(tickets));
    } catch (e) {
      debugPrint('❌ Error caching tickets: $e');
    }
  }

  static Future<List<Map<String, dynamic>>> _getCachedTickets(String sprintId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final s = prefs.getString(_ticketsKey(sprintId));
      if (s != null && s.isNotEmpty) {
        final list = jsonDecode(s);
        if (list is List) return List<Map<String, dynamic>>.from(list);
      }
    } catch (e) {
      debugPrint('❌ Error reading cached tickets: $e');
    }
    return [];
  }

  static Future<void> _prependCachedTicket(String sprintId, Map<String, dynamic> ticket) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final s = prefs.getString(_ticketsKey(sprintId));
      final list = (s != null && s.isNotEmpty)
          ? List<Map<String, dynamic>>.from(jsonDecode(s))
          : <Map<String, dynamic>>[];
      list.insert(0, ticket);
      await prefs.setString(_ticketsKey(sprintId), jsonEncode(list));
    } catch (e) {
      debugPrint('❌ Error updating cached tickets: $e');
    }
  }

  static Future<void> _updateCachedTicketStatus(String ticketId, String status) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // Iterate all cached ticket lists and update matching ticket
      final keys = prefs.getKeys().where((k) => k.startsWith('cached_tickets_'));
      for (final key in keys) {
        final s = prefs.getString(key);
        if (s == null || s.isEmpty) continue;
        final list = List<Map<String, dynamic>>.from(jsonDecode(s));
        bool changed = false;
        for (final t in list) {
          final id = (t['id']?.toString() ?? t['ticket_id']?.toString() ?? t['key']?.toString() ?? '').toString();
          if (id == ticketId) {
            t['status'] = status;
            changed = true;
            break;
          }
        }
        if (changed) await prefs.setString(key, jsonEncode(list));
      }
    } catch (e) {
      debugPrint('❌ Error updating cached ticket status: $e');
    }
  }

  /// Update ticket details
  Future<Map<String, dynamic>?> updateTicket({
    required String ticketId,
    String? summary,
    String? description,
    String? assignee,
    String? priority,
    List<String>? labels,
  }) async {
    try {
      final body = <String, dynamic>{};
      if (summary != null) body['summary'] = summary;
      if (description != null) body['description'] = description;
      if (assignee != null) body['assignee'] = assignee;
      if (priority != null) body['priority'] = priority;
      if (labels != null) body['labels'] = labels;

      final response = await http.put(
        Uri.parse('$_baseUrl/tickets/$ticketId'),
        headers: _headers,
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          debugPrint('✅ Ticket $ticketId updated successfully');
          return data['data'];
        }
      }
      
      debugPrint('❌ Failed to update ticket: ${response.statusCode}');
      return null;
    } catch (e) {
      debugPrint('❌ Error updating ticket: $e');
      return null;
    }
  }

  // Send collaborator invitation email
  Future<Map<String, dynamic>?> sendCollaboratorInvitation({
    required String email,
    required String role,
    required String projectName,
  }) async {
    try {
      debugPrint('📧 Sending invitation to $email as $role for project $projectName');
      
      final response = await _post('/collaborators/invite', {
        'email': email,
        'role': role,
        'projectName': projectName,
      });

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          debugPrint('✅ Invitation sent successfully');
          return data;
        }
      }
      
      debugPrint('❌ Failed to send invitation: ${response.statusCode}');
      return null;
    } catch (e) {
      debugPrint('❌ Error sending invitation: $e');
      return null;
    }
  }

  /// Update sprint status
  Future<bool> updateSprintStatus({
    required String sprintId,
    required String status,
    double? progress,
    String? oldStatus,
    String? sprintName,
  }) async {
    try {
      final body = {
        'status': status,
        if (progress != null) 'progress': progress,
      };

      final response = await http.put(
        Uri.parse('$_baseUrl/sprints/$sprintId'),
        headers: _headers,
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          debugPrint('✅ Sprint $sprintId status updated to $status');
          try { await _updateCachedSprintStatus(sprintId, status, progress: progress); } catch (_) {}
          
          // Send notification for sprint status change
          if (oldStatus != null && sprintName != null) {
            try {
              final token = _authService.accessToken;
              if (token != null) {
                _notificationService.setAuthToken(token);
                final user = _authService.currentUser;
                final userName = user?.name ?? 'Unknown User';
                
                await _notificationService.notifySprintStatusChange(
                  sprintName: sprintName,
                  oldStatus: oldStatus,
                  newStatus: status,
                  changedBy: userName,
                );
              }
            } catch (e) {
              debugPrint('❌ Error sending sprint status notification: $e');
            }
          }
          
          return true;
        }
      }

      debugPrint('❌ Failed to update sprint status: ${response.statusCode}');
      return false;
    } catch (e) {
      debugPrint('❌ Error updating sprint status: $e');
      return false;
    }
  }

  /// Update sprint progress only
  Future<bool> updateSprintProgress({
    required String sprintId,
    required double progress,
  }) async {
    try {
      final body = {'progress': progress};

      final response = await http.put(
        Uri.parse('$_baseUrl/sprints/$sprintId'),
        headers: _headers,
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          debugPrint('✅ Sprint $sprintId progress updated to $progress');
          try { await _updateCachedSprintProgress(sprintId, progress); } catch (_) {}
          return true;
        }
      }

      debugPrint('❌ Failed to update sprint progress: ${response.statusCode}');
      return false;
    } catch (e) {
      debugPrint('❌ Error updating sprint progress: $e');
      return false;
    }
  }

  // ===== Local cache helpers =====
  static String _sprintsKey({String? projectId, String? projectKey}) {
    if (projectId != null && projectId.isNotEmpty) return 'cached_sprints_project_$projectId';
    if (projectKey != null && projectKey.isNotEmpty) return 'cached_sprints_projectKey_$projectKey';
    return 'cached_sprints_all';
  }

  static Future<void> _saveCachedSprints(List<Map<String, dynamic>> sprints, {String? projectId, String? projectKey}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = _sprintsKey(projectId: projectId, projectKey: projectKey);
      await prefs.setString(key, jsonEncode(sprints));
      // Also maintain a global cache snapshot
      await prefs.setString('cached_sprints_all', jsonEncode(sprints));
    } catch (e) {
      debugPrint('❌ Error caching sprints: $e');
    }
  }

  static Future<List<Map<String, dynamic>>> _getCachedSprints({String? projectId, String? projectKey}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? jsonStr = prefs.getString(_sprintsKey(projectId: projectId, projectKey: projectKey));
      if (jsonStr == null || jsonStr.isEmpty) {
        jsonStr = prefs.getString('cached_sprints_all');
      }
      if (jsonStr != null && jsonStr.isNotEmpty) {
        final list = jsonDecode(jsonStr);
        if (list is List) {
          return List<Map<String, dynamic>>.from(list);
        }
      }
    } catch (e) {
      debugPrint('❌ Error reading cached sprints: $e');
    }
    return [];
  }

  static Future<void> _prependCachedSprint(Map<String, dynamic> sprint, {String? projectId}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final sprintId = (sprint['id']?.toString() ?? sprint['sprint_id']?.toString() ?? '').toString();

      // Update global cache with de-dup
      final allStr = prefs.getString('cached_sprints_all');
      final allList = (allStr != null && allStr.isNotEmpty)
          ? List<Map<String, dynamic>>.from(jsonDecode(allStr))
          : <Map<String, dynamic>>[];
      allList.removeWhere((e) => (e['id']?.toString() ?? e['sprint_id']?.toString() ?? '') == sprintId);
      allList.insert(0, sprint);
      await prefs.setString('cached_sprints_all', jsonEncode(allList));

      // Determine project id/key from param or sprint payload
      final pid = (projectId ?? sprint['project_id']?.toString() ?? sprint['projectId']?.toString());
      final pkey = (sprint['project_key']?.toString() ?? sprint['projectKey']?.toString());

      // Update projectId cache if available
      if (pid != null && pid.isNotEmpty) {
        final pIdKey = _sprintsKey(projectId: pid);
        final pStr = prefs.getString(pIdKey);
        final pList = (pStr != null && pStr.isNotEmpty)
            ? List<Map<String, dynamic>>.from(jsonDecode(pStr))
            : <Map<String, dynamic>>[];
        pList.removeWhere((e) => (e['id']?.toString() ?? e['sprint_id']?.toString() ?? '') == sprintId);
        pList.insert(0, sprint);
        await prefs.setString(pIdKey, jsonEncode(pList));
      }

      // Update projectKey cache if available
      if (pkey != null && pkey.isNotEmpty) {
        final pKeyKey = _sprintsKey(projectKey: pkey);
        final pkStr = prefs.getString(pKeyKey);
        final pkList = (pkStr != null && pkStr.isNotEmpty)
            ? List<Map<String, dynamic>>.from(jsonDecode(pkStr))
            : <Map<String, dynamic>>[];
        pkList.removeWhere((e) => (e['id']?.toString() ?? e['sprint_id']?.toString() ?? '') == sprintId);
        pkList.insert(0, sprint);
        await prefs.setString(pKeyKey, jsonEncode(pkList));
      }
    } catch (e) {
      debugPrint('❌ Error updating cached sprint: $e');
    }
  }

  static Future<void> _removeCachedSprint(String sprintId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys().where((k) => k.startsWith('cached_sprints_'));
      for (final key in keys) {
        final s = prefs.getString(key);
        if (s == null || s.isEmpty) continue;
        final list = List<Map<String, dynamic>>.from(jsonDecode(s));
        list.removeWhere((e) => (e['id']?.toString() ?? e['sprint_id']?.toString() ?? '') == sprintId);
        await prefs.setString(key, jsonEncode(list));
      }
    } catch (e) {
      debugPrint('❌ Error removing cached sprint: $e');
    }
  }

  static Future<void> _updateCachedSprintStatus(String sprintId, String status, {double? progress}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys().where((k) => k.startsWith('cached_sprints_'));
      for (final key in keys) {
        final s = prefs.getString(key);
        if (s == null || s.isEmpty) continue;
        final list = List<Map<String, dynamic>>.from(jsonDecode(s));
        bool changed = false;
        for (final e in list) {
          final id = (e['id']?.toString() ?? e['sprint_id']?.toString() ?? '').toString();
          if (id == sprintId) {
            e['status'] = status;
            if (progress != null) e['progress'] = progress;
            changed = true;
            break;
          }
        }
        if (changed) await prefs.setString(key, jsonEncode(list));
      }
    } catch (e) {
      debugPrint('❌ Error updating cached sprint status: $e');
    }
  }

  static Future<void> _updateCachedSprintProgress(String sprintId, double progress) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys().where((k) => k.startsWith('cached_sprints_'));
      for (final key in keys) {
        final s = prefs.getString(key);
        if (s == null || s.isEmpty) continue;
        final list = List<Map<String, dynamic>>.from(jsonDecode(s));
        bool changed = false;
        for (final e in list) {
          final id = (e['id']?.toString() ?? e['sprint_id']?.toString() ?? '').toString();
          if (id == sprintId) {
            e['progress'] = progress;
            changed = true;
            break;
          }
        }
        if (changed) await prefs.setString(key, jsonEncode(list));
      }
    } catch (e) {
      debugPrint('❌ Error updating cached sprint progress: $e');
    }
  }

  Future<bool> deleteSprint(String sprintId) async {
    try {
      final response = await http.delete(
        Uri.parse('$_baseUrl/sprints/$sprintId'),
        headers: _headers,
      );
      if (response.statusCode == 200 || response.statusCode == 204) {
        try { await _removeCachedSprint(sprintId); } catch (_) {}
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('❌ Error deleting sprint: $e');
      return false;
    }
  }

  /// Backfill legacy sprints to associate with projects
  Future<Map<String, dynamic>?> backfillSprintProjects() async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/sprints/backfill-projects'),
        headers: _headers,
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is Map) {
          return Map<String, dynamic>.from(data['data'] ?? data);
        }
      }
      return null;
    } catch (e) {
      debugPrint('❌ Error backfilling sprint projects: $e');
      return null;
    }
  }
}
