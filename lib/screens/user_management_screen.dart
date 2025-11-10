// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user.dart';
import '../models/user_role.dart';
import '../services/api_client.dart';
import '../services/backend_api_service.dart';
import '../services/error_handler.dart';
import '../widgets/role_guard.dart';

class UserManagementScreen extends ConsumerStatefulWidget {
  const UserManagementScreen({super.key});

  @override
  ConsumerState<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends ConsumerState<UserManagementScreen> {
  final BackendApiService _apiService = BackendApiService();
  final ErrorHandler _errorHandler = ErrorHandler();
  
  List<User> _users = [];
  List<User> _filteredUsers = [];
  bool _isLoading = true;
  String _searchQuery = '';
  UserRole? _filterRole;
  bool _showInactive = false;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    try {
      setState(() => _isLoading = true);
      final response = await _apiService.getUsers();
      
      if (response.isSuccess && response.data != null) {
        final List<dynamic> usersData = response.data!['users'] ?? response.data!;
        final users = usersData.map((userData) => _apiService.parseUserFromResponse(
          ApiResponse.success(userData, response.statusCode),
        ),).whereType<User>().toList();
        
        setState(() {
          _users = users;
          _filteredUsers = _users;
          _isLoading = false;
        });
      } else {
        _errorHandler.showErrorSnackBar(context, 'Failed to load users: ${response.error}');
        setState(() => _isLoading = false);
      }
    } catch (e) {
      _errorHandler.showErrorSnackBar(context, 'Error loading users: $e');
      setState(() => _isLoading = false);
    }
  }

  void _filterUsers() {
    List<User> filtered = _users;
    
    // Filter by search query
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((user) =>
        user.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
        user.email.toLowerCase().contains(_searchQuery.toLowerCase()),
      ).toList();
    }
    
    // Filter by role
    if (_filterRole != null) {
      filtered = filtered.where((user) => user.role == _filterRole).toList();
    }
    
    // Filter by active status
    if (!_showInactive) {
      filtered = filtered.where((user) => user.isActive).toList();
    }
    
    setState(() => _filteredUsers = filtered);
  }

  Future<void> _deleteUser(User user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete User'),
        content: Text('Are you sure you want to delete ${user.name}? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final response = await _apiService.deleteUser(user.id);
        if (response.isSuccess) {
          _errorHandler.showSuccessSnackBar(context, 'User deleted successfully');
          _loadUsers(); // Reload users
        } else {
          _errorHandler.showErrorSnackBar(context, 'Failed to delete user: ${response.error}');
        }
      } catch (e) {
        _errorHandler.showErrorSnackBar(context, 'Error deleting user: $e');
      }
    }
  }

  Future<void> _updateUserRole(User user, UserRole newRole) async {
    try {
      final response = await _apiService.updateUserRole(user.id, newRole);
      if (response.isSuccess) {
        _errorHandler.showSuccessSnackBar(context, 'User role updated successfully');
        _loadUsers(); // Reload users
      } else {
        _errorHandler.showErrorSnackBar(context, 'Failed to update role: ${response.error}');
      }
    } catch (e) {
      _errorHandler.showErrorSnackBar(context, 'Error updating role: $e');
    }
  }

  Future<void> _toggleUserStatus(User user) async {
    try {
      final updates = {'isActive': !user.isActive};
      final response = await _apiService.updateUser(user.id, updates);
      if (response.isSuccess) {
        final status = !user.isActive ? 'activated' : 'deactivated';
        _errorHandler.showSuccessSnackBar(context, 'User $status successfully');
        _loadUsers(); // Reload users
      } else {
        _errorHandler.showErrorSnackBar(context, 'Failed to update user status: ${response.error}');
      }
    } catch (e) {
      _errorHandler.showErrorSnackBar(context, 'Error updating user status: $e');
    }
  }

  Widget _buildUserCard(User user) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: user.role.color,
                  child: Text(
                    user.name.split(' ').map((n) => n[0]).join(),
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.name,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        user.email,
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                Chip(
                  label: Text(
                    user.role.displayName,
                    style: TextStyle(
                      color: user.role.color.computeLuminance() > 0.5 ? Colors.black : Colors.white,
                      fontSize: 12,
                    ),
                  ),
                  backgroundColor: user.role.color,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Chip(
                  label: Text(user.isActive ? 'Active' : 'Inactive'),
                  backgroundColor: user.isActive ? Colors.green[100] : Colors.grey[300],
                  labelStyle: TextStyle(
                    color: user.isActive ? Colors.green[800] : Colors.grey[600],
                  ),
                ),
                const Spacer(),
                PopupMenuButton<String>(
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'edit',
                      child: const Text('Edit User'),
                      onTap: () => _showEditUserDialog(user),
                    ),
                    PopupMenuItem(
                      value: 'role',
                      child: const Text('Change Role'),
                      onTap: () => _showChangeRoleDialog(user),
                    ),
                    PopupMenuItem(
                      value: 'status',
                      child: Text(user.isActive ? 'Deactivate' : 'Activate'),
                      onTap: () => _toggleUserStatus(user),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: const Text('Delete User', style: TextStyle(color: Colors.red)),
                      onTap: () => _deleteUser(user),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showChangeRoleDialog(User user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change User Role'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: UserRole.values.map((role) {
            return ListTile(
              leading: Icon(role.icon, color: role.color),
              title: Text(role.displayName),
              subtitle: Text(role.description),
              onTap: () {
                Navigator.pop(context);
                _updateUserRole(user, role);
              },
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _showEditUserDialog(User user) {
    // Placeholder for edit user dialog
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Edit user functionality coming soon'),
        backgroundColor: Colors.blue,
        duration: Duration(seconds: 3),
      ),
    );
  }

  Widget _buildFilters() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search users...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (value) {
                setState(() => _searchQuery = value);
                _filterUsers();
              },
            ),
          ),
          const SizedBox(width: 8),
          DropdownButton<UserRole?>(
            value: _filterRole,
            hint: const Text('Filter by role'),
            items: [
              const DropdownMenuItem(value: null, child: Text('All Roles')),
              ...UserRole.values.map((role) => DropdownMenuItem(
                value: role,
                child: Text(role.displayName),
              ),),
            ],
            onChanged: (value) {
              setState(() => _filterRole = value);
              _filterUsers();
            },
          ),
          const SizedBox(width: 8),
          FilterChip(
            label: const Text('Show Inactive'),
            selected: _showInactive,
            onSelected: (selected) {
              setState(() => _showInactive = selected);
              _filterUsers();
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return RoleGuard(
      requiredPermission: 'manage_users',
      child: Scaffold(
        appBar: AppBar(
          title: const Text('User Management'),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loadUsers,
            ),
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  _buildFilters(),
                  Expanded(
                    child: _filteredUsers.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.people_outline, size: 64, color: Colors.grey),
                                const SizedBox(height: 16),
                                Text(
                                  _users.isEmpty ? 'No users found' : 'No users match your filters',
                                  style: const TextStyle(fontSize: 18, color: Colors.grey),
                                ),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _loadUsers,
                            child: ListView.builder(
                              itemCount: _filteredUsers.length,
                              itemBuilder: (context, index) => _buildUserCard(_filteredUsers[index]),
                            ),
                          ),
                  ),
                ],
              ),
      ),
    );
  }
}