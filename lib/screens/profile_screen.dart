// ignore_for_file: use_build_context_synchronously, prefer_const_constructors

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../services/profile_service.dart';
import '../config/environment.dart';
import '../services/auth_service.dart';
import 'package:http/http.dart' as http;
import '../widgets/app_scaffold.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _departmentController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();

  File? _profileImage;
  Uint8List? _profileImageBytes;
  String? _profileImageUrl;
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    try {
      final profile = await ProfileService.getUserProfile();
      setState(() {
        _firstNameController.text = profile['first_name'] ?? '';
        _lastNameController.text = profile['last_name'] ?? '';
        _emailController.text = profile['email'] ?? '';
        _phoneController.text = profile['phone_number'] ?? '';
        _titleController.text = profile['job_title'] ?? '';
        _departmentController.text = profile['company'] ?? '';
        _bioController.text = profile['bio'] ?? '';
        final rawUrl = (profile['profile_picture'] ?? profile['profileImageUrl'] ?? profile['profile_image_url'])?.toString();
        final uid = (profile['user_id'] ?? profile['userId'])?.toString();
        if (rawUrl != null && rawUrl.isNotEmpty && uid != null && uid.isNotEmpty) {
          final base = Uri.parse(Environment.apiBaseUrl);
          final apiPic = '${base.scheme}://${base.host}:${base.port}/api/v1/profile/$uid/picture';
          _profileImageUrl = apiPic;
        }
      });
      final uid = (profile['user_id'] ?? profile['userId'])?.toString();
      if (uid != null && uid.isNotEmpty) {
        await _fetchProfileImageBytes(uid);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load profile: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchProfileImageBytes(String userId) async {
    try {
      final base = Uri.parse(Environment.apiBaseUrl);
      final url = '${base.scheme}://${base.host}:${base.port}/api/v1/profile/$userId/picture?t=${DateTime.now().millisecondsSinceEpoch}';
      final token = AuthService().accessToken;
      final headers = <String, String>{
        'Accept': 'image/*',
        if (token != null) 'Authorization': 'Bearer $token',
      };
      final resp = await http.get(Uri.parse(url), headers: headers);
      if (resp.statusCode == 200) {
        setState(() {
          _profileImageBytes = resp.bodyBytes;
        });
      }
    } catch (_) {}
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final pickedFile = await ImagePicker().pickImage(source: source);
      if (pickedFile != null) {
        final imageBytes = await pickedFile.readAsBytes();
        setState(() {
          _profileImageBytes = imageBytes;
          if (!kIsWeb) {
            _profileImage = File(pickedFile.path);
          }
        });
        // Upload image to backend
        final result = await ProfileService.uploadProfilePicture(imageBytes, (pickedFile.name.isNotEmpty ? pickedFile.name : 'profile_picture.jpg'));
        final rawUrl = result['url']?.toString();
        if (rawUrl != null && rawUrl.isNotEmpty) {
          final base = Uri.parse(Environment.apiBaseUrl);
          try {
            final user = await AuthService().getCurrentUser();
            final uid = user?.id;
            if (uid != null && uid.isNotEmpty) {
              final apiPic = '${base.scheme}://${base.host}:${base.port}/api/v1/profile/$uid/picture?t=${DateTime.now().millisecondsSinceEpoch}';
              setState(() {
                _profileImageUrl = apiPic;
              });
            } else {
              final full = rawUrl.startsWith('http') ? rawUrl : '${base.scheme}://${base.host}:${base.port}$rawUrl';
              setState(() { _profileImageUrl = full; });
            }
          } catch (_) {}
          await ProfileService.saveUserProfile({'profile_picture': rawUrl});
          try { await AuthService().refreshCurrentUser(); } catch (_) {}
        }
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile picture updated')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to pick image: $e')),
      );
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final profileData = {
        'first_name': _firstNameController.text,
        'last_name': _lastNameController.text,
        'email': _emailController.text,
        'phone_number': _phoneController.text,
        'job_title': _titleController.text,
        'company': _departmentController.text,
        'bio': _bioController.text,
      };

      await ProfileService.saveUserProfile(profileData);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile saved successfully')),
      );
      try { await AuthService().refreshCurrentUser(); } catch (_) {}
      context.go('/profile?mode=view');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save profile: $e')),
      );
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _titleController.dispose();
    _departmentController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final uri = GoRouterState.of(context).uri;
    final mode = uri.queryParameters['mode'] ?? 'edit';
    final isViewMode = mode.toLowerCase() == 'view';
    if (_isLoading) {
      return const AppScaffold(
        useBackgroundImage: true,
        centered: false,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return AppScaffold(
      useBackgroundImage: true,
      centered: false,
      scrollable: false,
      appBar: AppBar(
        title: const Text('My Profile', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white),
            onPressed: () {
              // Navigate to settings
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.12),
              width: 1,
            ),
          ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Profile Picture Section
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundImage: _profileImage != null
                          ? FileImage(_profileImage!)
                          : null,
                      child: _profileImage == null
                          ? SvgPicture.asset(
                              'assets/images/google_logo.svg',
                              width: 60,
                              height: 60,
                              placeholderBuilder: (context) => const Icon(Icons.person, size: 50),
                            )
                          : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary,
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.camera_alt, size: 20, color: Colors.white),
                          onPressed: () {
                            showModalBottomSheet(
                              context: context,
                              builder: (context) => Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  ListTile(
                                    leading: const Icon(Icons.photo_library),
                                    title: const Text('Choose from Gallery'),
                                    onTap: () {
                                      Navigator.pop(context);
                                      _pickImage(ImageSource.gallery);
                                    },
                                  ),
                                  ListTile(
                                    leading: const Icon(Icons.camera_alt),
                                    title: const Text('Take Photo'),
                                    onTap: () {
                                      Navigator.pop(context);
                                      _pickImage(ImageSource.camera);
                                    },
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Personal Information Section
                const Text(
                  'Personal Information',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _firstNameController,
                        decoration: const InputDecoration(
                          labelText: 'First Name',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your first name';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _lastNameController,
                        decoration: const InputDecoration(
                          labelText: 'Last Name',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your last name';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your email';
                    }
                    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                      return 'Please enter a valid email';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _phoneController,
                  decoration: const InputDecoration(
                    labelText: 'Phone Number',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 24),

                // Professional Information Section
                const Text(
                  'Professional Information',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'Job Title',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _departmentController,
                  decoration: const InputDecoration(
                    labelText: 'Department',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _bioController,
                  decoration: const InputDecoration(
                    labelText: 'Bio',
                    border: OutlineInputBorder(),
                    alignLabelWithHint: true,
                  ),
                  maxLines: 4,
                  maxLength: 500,
                ),
                const SizedBox(height: 32),

                // Save Button
                ElevatedButton(
                  onPressed: _isSaving ? null : _saveProfile,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Save Profile'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
