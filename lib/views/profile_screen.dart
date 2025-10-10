import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:http/http.dart' as http;
import '../controllers/user_controller.dart';
import '../models/user.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isEditing = false;
  late TextEditingController _usernameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  late TextEditingController _stateController;
  late TextEditingController _pincodeController;
  late TextEditingController _passwordController;
  late TextEditingController _confirmPasswordController;
  String _gender = '1';
  DateTime? _dob;
  XFile? _profileImage;
  final _formKey = GlobalKey<FormState>();
  final _passwordFormKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    final user = Provider.of<UserController>(context, listen: false).user;
    _initializeControllers(user);
    _loadFromSharedPreferences();
  }

  void _initializeControllers(AppUser? user) {
    _usernameController = TextEditingController(text: user?.username ?? '');
    _emailController = TextEditingController(text: user?.email ?? '');
    _phoneController = TextEditingController(text: user?.phone ?? '');
    _addressController = TextEditingController(text: user?.address ?? '');
    _stateController = TextEditingController(text: user?.state ?? '');
    _pincodeController = TextEditingController(text: user?.pincode ?? '');
    _passwordController = TextEditingController();
    _confirmPasswordController = TextEditingController();
    _gender = user?.gender ?? '1';
    _dob = user?.dob != null ? DateTime.tryParse(user!.dob!) : null;
  }

  Future<void> _loadFromSharedPreferences() async {
    if (!mounted) return;
    setState(() => _errorMessage = null);
    await EasyLoading.show(status: 'Loading profile data...');
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('userId') ?? '';
      if (userId.isNotEmpty) {
        await Provider.of<UserController>(context, listen: false).fetchUserDetails(userId);
        final updatedPrefs = await SharedPreferences.getInstance();
        if (mounted) {
          setState(() {
            _usernameController.text = updatedPrefs.getString('username') ?? _usernameController.text;
            _emailController.text = updatedPrefs.getString('email') ?? _emailController.text;
            _phoneController.text = updatedPrefs.getString('phone') ?? _phoneController.text;
            _addressController.text = updatedPrefs.getString('address') ?? _addressController.text;
            _stateController.text = updatedPrefs.getString('state') ?? _stateController.text;
            _pincodeController.text = updatedPrefs.getString('pincode') ?? _pincodeController.text;
            _gender = updatedPrefs.getString('gender') ?? _gender;
            _dob = updatedPrefs.getString('dob')?.isNotEmpty == true
                ? DateTime.tryParse(updatedPrefs.getString('dob')!)
                : _dob;
          });
        }
        await EasyLoading.dismiss();
      } else {
        throw Exception('User ID not found');
      }
    } catch (e) {
      setState(() => _errorMessage = 'Failed to load profile data: $e');
      await EasyLoading.showError(_errorMessage!);
      debugPrint('❌ Error loading profile data: $e');
    }
  }

  Future<void> _refreshProfile() async {
    await EasyLoading.show(status: 'Refreshing profile...');
    try {
      await _loadFromSharedPreferences();
      await EasyLoading.showSuccess('Profile refreshed successfully');
    } catch (e) {
      setState(() => _errorMessage = 'Failed to refresh profile: $e');
      await EasyLoading.showError(_errorMessage!);
    }
  }

  Future<void> _changePassword() async {
    if (_passwordFormKey.currentState!.validate()) {
      await EasyLoading.show(status: 'Updating password...');
      try {
        final prefs = await SharedPreferences.getInstance();
        final userId = prefs.getString('userId') ?? '';
        if (userId.isEmpty) {
          await EasyLoading.showError('User ID not found. Please log in again.');
          return;
        }

        final response = await http.put(
          Uri.parse('https://backend-olxs.onrender.com/update-profile/$userId'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'password': _passwordController.text.trim(),
            'password2': _confirmPasswordController.text.trim(),
          }),
        );

        print("Response is: ${response.body}");
        if (response.statusCode == 200) {
          await EasyLoading.showSuccess('Password updated successfully');
          _passwordController.clear();
          _confirmPasswordController.clear();
          Navigator.of(context).pop();
        } else {
          await EasyLoading.showError('Failed to update password: ${response.body}');
        }
      } catch (e) {
        await EasyLoading.showError('Failed to update password: $e');
        debugPrint('❌ Error updating password: $e');
      }
    }
  }

  void _showChangePasswordDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xff000428),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text(
            'Change Password',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          content: Form(
            key: _passwordFormKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _passwordController,
                  style: const TextStyle(color: Colors.white),
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'New Password',
                    labelStyle: const TextStyle(color: Colors.white70),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.1),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a new password';
                    }
                    if (value.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _confirmPasswordController,
                  style: const TextStyle(color: Colors.white),
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Confirm Password',
                    labelStyle: const TextStyle(color: Colors.white70),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.1),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please confirm your password';
                    }
                    if (value != _passwordController.text) {
                      return 'Passwords do not match';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: _changePassword,
              child: const Text('Update', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _stateController.dispose();
    _pincodeController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _dob ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Colors.orangeAccent,
              onPrimary: Colors.white,
              surface: Color(0xff004e92),
              onSurface: Colors.white,
            ),
            dialogBackgroundColor: const Color(0xff000428),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _dob && mounted) {
      setState(() {
        _dob = picked;
      });
    }
  }

  Future<void> _pickProfileImage() async {
    await EasyLoading.show(status: 'Picking image...');
    try {
      final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null && mounted) {
        setState(() {
          _profileImage = pickedFile;
        });
        await EasyLoading.showSuccess('Image selected successfully');
      } else {
        await EasyLoading.dismiss();
      }
    } catch (e) {
      await EasyLoading.showError('Failed to pick image: $e');
      debugPrint('❌ Error picking image: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<UserController>(
      builder: (context, controller, _) {
        final user = controller.user;
        final size = MediaQuery.of(context).size;
        final avatarRadius = (size.width * 0.18 > 80 ? 80 : size.width * 0.18).toDouble();

        if (_errorMessage != null) {
          return Scaffold(
            body: RefreshIndicator(
              onRefresh: _refreshProfile,
              color: Colors.blueAccent,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: SizedBox(
                  height: size.height,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _errorMessage!,
                          style: const TextStyle(fontSize: 16, color: Colors.red),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blueAccent,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: _refreshProfile,
                          child: const Text('Retry', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text(
              'Profile',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            centerTitle: true,
            backgroundColor: Colors.blue[700],
            elevation: 3,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              IconButton(
                icon: controller.isLoading
                    ? const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  strokeWidth: 2,
                )
                    : Icon(_isEditing ? Icons.save : Icons.edit, color: Colors.white),
                onPressed: controller.isLoading
                    ? null
                    : () async {
                  if (_isEditing) {
                    if (_formKey.currentState!.validate()) {
                      await EasyLoading.show(status: 'Updating profile...');
                      final prefs = await SharedPreferences.getInstance();
                      final userId = prefs.getString('userId') ?? '';
                      if (userId.isEmpty) {
                        await EasyLoading.showError('User ID not found. Please log in again.');
                        return;
                      }

                      debugPrint('🚀 Initiating profile update for userId: $userId');
                      final success = await controller.updateUserDetails(
                        userId: userId,
                        username: _usernameController.text.trim(),
                        phone: _phoneController.text.trim(),
                        email: _emailController.text.trim(),
                        pincode: _pincodeController.text.trim(),
                        address: _addressController.text.trim(),
                        state: _stateController.text.trim(),
                        gender: _gender,
                        dob: _dob != null ? _dob!.toIso8601String() : '',
                        profileImage: _profileImage,
                      );

                      debugPrint('🚀 Update result: $success, Error: ${controller.errorMessage}');
                      if (success) {
                        await EasyLoading.showSuccess('Profile updated successfully');
                        if (mounted) {
                          setState(() => _isEditing = false);
                        }
                      } else {
                        await EasyLoading.showError(
                            controller.errorMessage ?? 'Failed to update profile. Please try again.');
                      }
                    }
                  } else {
                    setState(() => _isEditing = true);
                  }
                },
              ),
            ],
          ),
          body: RefreshIndicator(
            onRefresh: _refreshProfile,
            color: Colors.blueAccent,
            child: SingleChildScrollView(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xff004e92), Color(0xff000428)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: controller.isLoading && user == null
                    ? SizedBox(
                  height: size.height,
                  child: const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.orangeAccent),
                    ),
                  ),
                )
                    : user == null
                    ? SizedBox(
                  height: size.height,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Failed to load user data',
                          style: TextStyle(color: Colors.white, fontSize: 18),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blueAccent,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: _refreshProfile,
                          child: const Text(
                            'Retry',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
                    : SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: size.width * 0.06,
                    vertical: size.height * 0.02,
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        // Profile Image
                        GestureDetector(
                          onTap: _isEditing ? _pickProfileImage : null,
                          child: Stack(
                            alignment: Alignment.bottomRight,
                            children: [
                              CircleAvatar(
                                radius: avatarRadius,
                                backgroundColor: Colors.white.withOpacity(0.1),
                                backgroundImage: NetworkImage(
                                  'https://i.pravatar.cc/150?img=${(user.username ?? 'User').hashCode % 70}',
                                ) as ImageProvider,
                              ),
                              if (_isEditing)
                                Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: Colors.orangeAccent,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          user.username ?? 'User',
                          style: TextStyle(
                            fontSize: size.width * 0.06,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          user.email ?? user.phone ?? 'Not provided',
                          style: TextStyle(
                            fontSize: size.width * 0.04,
                            color: Colors.white70,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blueAccent,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: _showChangePasswordDialog,
                          child: const Text(
                            'Change Password',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(height: 24),
                        // Profile Info Card
                        Card(
                          elevation: 6,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          color: Colors.white.withOpacity(0.1),
                          child: Padding(
                            padding: EdgeInsets.all(size.width * 0.05),
                            child: Column(
                              children: [
                                ProfileInfoRow(
                                  icon: Icons.person,
                                  label: 'Username',
                                  value: user.username ?? 'Not provided',
                                  controller: _usernameController,
                                  isEditing: _isEditing,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please enter a username';
                                    }
                                    return null;
                                  },
                                ),
                                const Divider(color: Colors.white38),
                                ProfileInfoRow(
                                  icon: Icons.phone,
                                  label: 'Phone',
                                  value: user.phone ?? 'Not provided',
                                  controller: _phoneController,
                                  isEditing: _isEditing,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please enter a phone number';
                                    }
                                    if (!RegExp(r'^\d{10}$').hasMatch(value)) {
                                      return 'Please enter a valid 10-digit phone number';
                                    }
                                    return null;
                                  },
                                  keyboardType: TextInputType.phone,
                                ),
                                const Divider(color: Colors.white38),
                                ProfileInfoRow(
                                  icon: Icons.email,
                                  label: 'Email',
                                  value: user.email ?? 'Not provided',
                                  controller: _emailController,
                                  isEditing: _isEditing,
                                  validator: (value) {
                                    if (value != null && value.isNotEmpty) {
                                      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                                        return 'Please enter a valid email';
                                      }
                                    }
                                    return null;
                                  },
                                  keyboardType: TextInputType.emailAddress,
                                ),
                                const Divider(color: Colors.white38),
                                ProfileInfoRow(
                                  icon: Icons.location_on,
                                  label: 'Address',
                                  value: user.address ?? 'Not provided',
                                  controller: _addressController,
                                  isEditing: _isEditing,
                                ),
                                const Divider(color: Colors.white38),
                                ProfileInfoRow(
                                  icon: Icons.location_city,
                                  label: 'State',
                                  value: user.state ?? 'Not provided',
                                  controller: _stateController,
                                  isEditing: _isEditing,
                                ),
                                const Divider(color: Colors.white38),
                                ProfileInfoRow(
                                  icon: Icons.pin_drop,
                                  label: 'Pincode',
                                  value: user.pincode ?? 'Not provided',
                                  controller: _pincodeController,
                                  isEditing: _isEditing,
                                  validator: (value) {
                                    if (value != null && value.isNotEmpty) {
                                      if (!RegExp(r'^\d{6}$').hasMatch(value)) {
                                        return 'Please enter a valid 6-digit pincode';
                                      }
                                    }
                                    return null;
                                  },
                                  keyboardType: TextInputType.number,
                                ),
                                const Divider(color: Colors.white38),
                                ProfileInfoRow(
                                  icon: Icons.person_outline,
                                  label: 'Gender',
                                  value: _gender == '1' ? 'Male' : 'Female',
                                  isEditing: _isEditing,
                                  customInput: _isEditing
                                      ? DropdownButtonFormField<String>(
                                    value: _gender,
                                    decoration: InputDecoration(
                                      filled: true,
                                      fillColor: Colors.white.withOpacity(0.1),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: BorderSide.none,
                                      ),
                                      contentPadding: EdgeInsets.symmetric(
                                        horizontal: size.width * 0.03,
                                        vertical: size.height * 0.015,
                                      ),
                                    ),
                                    style: const TextStyle(color: Colors.white),
                                    dropdownColor: Colors.black87,
                                    items: const [
                                      DropdownMenuItem(value: '1', child: Text('Male')),
                                      DropdownMenuItem(value: '2', child: Text('Female')),
                                    ],
                                    onChanged: (value) {
                                      setState(() {
                                        _gender = value!;
                                      });
                                    },
                                  )
                                      : null,
                                ),
                                const Divider(color: Colors.white38),

                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class ProfileInfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final TextEditingController? controller;
  final bool isEditing;
  final String? Function(String?)? validator;
  final TextInputType keyboardType;
  final Widget? customInput;
  final int maxLines;

  const ProfileInfoRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.controller,
    this.isEditing = false,
    this.validator,
    this.keyboardType = TextInputType.text,
    this.customInput,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: size.height * 0.01),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.orangeAccent, size: size.width * 0.06),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: size.width * 0.035, color: Colors.white70),
                ),
                isEditing && customInput != null
                    ? customInput!
                    : isEditing
                    ? TextFormField(
                  controller: controller,
                  style: const TextStyle(color: Colors.white),
                  keyboardType: keyboardType,
                  maxLines: maxLines,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.1),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: size.width * 0.03,
                      vertical: size.height * 0.015,
                    ),
                  ),
                  validator: validator,
                )
                    : Text(
                  value,
                  style: TextStyle(
                    fontSize: size.width * 0.04,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}