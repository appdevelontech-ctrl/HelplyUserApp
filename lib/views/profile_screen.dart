import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
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
  late TextEditingController _statenameController;
  late TextEditingController _countryController;
  late TextEditingController _cityController;
  late TextEditingController _aboutController;
  late TextEditingController _departmentController;
  late TextEditingController _doc1Controller;
  late TextEditingController _doc2Controller;
  late TextEditingController _doc3Controller;
  late TextEditingController _pHealthHistoryController;
  late TextEditingController _cHealthStatusController;
  late TextEditingController _coverageController;
  late TextEditingController _typeController;
  String _gender = '1';
  DateTime? _dob;
  XFile? _profileImage;
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();

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
    _statenameController = TextEditingController(text: user?.statename ?? '');
    _countryController = TextEditingController(text: user?.country ?? '');
    _cityController = TextEditingController(text: user?.city ?? '');
    _aboutController = TextEditingController(text: user?.about ?? '');
    _departmentController = TextEditingController(text: user?.department?.join(', ') ?? '');
    _doc1Controller = TextEditingController(text: user?.doc1 ?? '');
    _doc2Controller = TextEditingController(text: user?.doc2 ?? '');
    _doc3Controller = TextEditingController(text: user?.doc3 ?? '');
    _pHealthHistoryController = TextEditingController(text: user?.pHealthHistory ?? '');
    _cHealthStatusController = TextEditingController(text: user?.cHealthStatus ?? '');
    _coverageController = TextEditingController(text: user?.coverage?.join(', ') ?? '');
    _typeController = TextEditingController(text: user?.type?.toString() ?? '');
    _gender = user?.gender ?? '1';
    _dob = user?.dob != null ? DateTime.tryParse(user!.dob!) : null;
  }

  Future<void> _loadFromSharedPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _usernameController.text = prefs.getString('username') ?? _usernameController.text;
        _emailController.text = prefs.getString('email') ?? _emailController.text;
        _phoneController.text = prefs.getString('phone') ?? _phoneController.text;
        _addressController.text = prefs.getString('address') ?? _addressController.text;
        _stateController.text = prefs.getString('state') ?? _stateController.text;
        _pincodeController.text = prefs.getString('pincode') ?? _pincodeController.text;
        _statenameController.text = prefs.getString('statename') ?? _statenameController.text;
        _countryController.text = prefs.getString('country') ?? _countryController.text;
        _cityController.text = prefs.getString('city') ?? _cityController.text;
        _aboutController.text = prefs.getString('about') ?? _aboutController.text;
        _departmentController.text = prefs.getStringList('department')?.join(', ') ?? _departmentController.text;
        _doc1Controller.text = prefs.getString('doc1') ?? _doc1Controller.text;
        _doc2Controller.text = prefs.getString('doc2') ?? _doc2Controller.text;
        _doc3Controller.text = prefs.getString('doc3') ?? _doc3Controller.text;
        _pHealthHistoryController.text = prefs.getString('pHealthHistory') ?? _pHealthHistoryController.text;
        _cHealthStatusController.text = prefs.getString('cHealthStatus') ?? _cHealthStatusController.text;
        _coverageController.text = prefs.getStringList('coverage')?.join(', ') ?? _coverageController.text;
        _typeController.text = prefs.getString('type') ?? _typeController.text;
        _gender = prefs.getString('gender') ?? _gender;
        _dob = prefs.getString('dob')?.isNotEmpty == true
            ? DateTime.tryParse(prefs.getString('dob')!)
            : _dob;
      });
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _stateController.dispose();
    _pincodeController.dispose();
    _statenameController.dispose();
    _countryController.dispose();
    _cityController.dispose();
    _aboutController.dispose();
    _departmentController.dispose();
    _doc1Controller.dispose();
    _doc2Controller.dispose();
    _doc3Controller.dispose();
    _pHealthHistoryController.dispose();
    _cHealthStatusController.dispose();
    _coverageController.dispose();
    _typeController.dispose();
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
    if (picked != null && picked != _dob) {
      setState(() {
        _dob = picked;
      });
    }
  }

  Future<void> _pickProfileImage() async {
    // final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    // if (pickedFile != null && mounted) {
    //   setState(() {
    //     _profileImage = pickedFile;
    //   });
    // }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<UserController>(
      builder: (context, controller, _) {
        final user = controller.user;
        final size = MediaQuery.of(context).size;
        final avatarRadius = (size.width * 0.18 > 80 ? 80 : size.width * 0.18).toDouble();

        return Scaffold(
          appBar: AppBar(
            title: const Text(
              'Profile',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            centerTitle: true,
            backgroundColor: Colors.transparent,
            elevation: 0,
            flexibleSpace: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xff004e92), Color(0xff000428)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
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
                    : Icon(
                  _isEditing ? Icons.save : Icons.edit,
                  color: Colors.white,
                ),
                onPressed: controller.isLoading
                    ? null
                    : () async {
                  if (_isEditing) {
                    if (_formKey.currentState!.validate()) {
                      final prefs = await SharedPreferences.getInstance();
                      final userId = prefs.getString('userId') ?? '';
                      if (userId.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('User ID not found. Please log in again.'),
                            backgroundColor: Colors.redAccent,
                          ),
                        );
                        return;
                      }

                      print('🚀 Initiating profile update for userId: $userId');
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
                        statename: _statenameController.text.trim(),
                        country: _countryController.text.trim(),
                        city: _cityController.text.trim(),
                        about: _aboutController.text.trim(),
                        setEmail: _emailController.text.trim(),
                        type: _typeController.text,
                        empType: int.tryParse(_typeController.text) ?? user?.empType,
                        department: _departmentController.text.isEmpty
                            ? []
                            : _departmentController.text.split(',').map((e) => e.trim()).toList(),
                        doc1: _doc1Controller.text.trim(),
                        doc2: _doc2Controller.text.trim(),
                        doc3: _doc3Controller.text.trim(),
                        pHealthHistory: _pHealthHistoryController.text.trim(),
                        cHealthStatus: _cHealthStatusController.text.trim(),
                        coverage: _coverageController.text.isEmpty
                            ? []
                            : _coverageController.text.split(',').map((e) => e.trim()).toList(),
                        profileImage: _profileImage,
                      );

                      print('🚀 Update result: $success, Error: ${controller.errorMessage}');
                      if (success) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Profile updated successfully'),
                            backgroundColor: Colors.green,
                            duration: Duration(seconds: 3),
                          ),
                        );
                        setState(() => _isEditing = false);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              controller.errorMessage ?? 'Failed to update profile. Please try again.',
                            ),
                            backgroundColor: Colors.redAccent,
                            duration: const Duration(seconds: 3),
                          ),
                        );
                      }
                    }
                  } else {
                    setState(() => _isEditing = true);
                  }
                },
              ),
            ],
          ),
          body: SafeArea(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xff004e92), Color(0xff000428)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: controller.isLoading && user == null
                  ? const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.orangeAccent),
                ),
              )
                  : user == null
                  ? Center(
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
                        backgroundColor: Colors.orangeAccent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () async {
                        final prefs = await SharedPreferences.getInstance();
                        final userId = prefs.getString('userId') ?? '';
                        if (userId.isNotEmpty) {
                          await controller.fetchUserDetails(userId);
                        }
                      },
                      child: const Text(
                        'Retry',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
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
                              backgroundImage: _profileImage != null
                                  ? FileImage(File(_profileImage!.path))
                                  : user.profile != null && user.profile!.isNotEmpty
                                  ? NetworkImage(user.profile!)
                                  : NetworkImage(
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
                                child: const Icon(
                                  Icons.camera_alt,
                                  color: Colors.white,
                                  size: 20,
                                ),
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
                        user.email ?? user.phone,
                        style: TextStyle(
                          fontSize: size.width * 0.04,
                          color: Colors.white70,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Profile Info Card
                      Card(
                        elevation: 6,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
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
                                value: user.phone,
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
                                    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                                        .hasMatch(value)) {
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
                                icon: Icons.location_city,
                                label: 'State Name',
                                value: user.statename ?? 'Not provided',
                                controller: _statenameController,
                                isEditing: _isEditing,
                              ),
                              const Divider(color: Colors.white38),
                              ProfileInfoRow(
                                icon: Icons.public,
                                label: 'Country',
                                value: user.country ?? 'Not provided',
                                controller: _countryController,
                                isEditing: _isEditing,
                              ),
                              const Divider(color: Colors.white38),
                              ProfileInfoRow(
                                icon: Icons.location_city,
                                label: 'City',
                                value: user.city ?? 'Not provided',
                                controller: _cityController,
                                isEditing: _isEditing,
                              ),
                              const Divider(color: Colors.white38),
                              ProfileInfoRow(
                                icon: Icons.info,
                                label: 'About',
                                value: user.about ?? 'Not provided',
                                controller: _aboutController,
                                isEditing: _isEditing,
                                keyboardType: TextInputType.multiline,
                                maxLines: 3,
                              ),
                              const Divider(color: Colors.white38),
                              ProfileInfoRow(
                                icon: Icons.work,
                                label: 'Department',
                                value: user.department?.join(', ') ?? 'Not provided',
                                controller: _departmentController,
                                isEditing: _isEditing,
                              ),
                              const Divider(color: Colors.white38),
                              ProfileInfoRow(
                                icon: Icons.description,
                                label: 'Document 1',
                                value: user.doc1 ?? 'Not provided',
                                controller: _doc1Controller,
                                isEditing: _isEditing,
                              ),
                              const Divider(color: Colors.white38),
                              ProfileInfoRow(
                                icon: Icons.description,
                                label: 'Document 2',
                                value: user.doc2 ?? 'Not provided',
                                controller: _doc2Controller,
                                isEditing: _isEditing,
                              ),
                              const Divider(color: Colors.white38),
                              ProfileInfoRow(
                                icon: Icons.description,
                                label: 'Document 3',
                                value: user.doc3 ?? 'Not provided',
                                controller: _doc3Controller,
                                isEditing: _isEditing,
                              ),
                              const Divider(color: Colors.white38),
                              ProfileInfoRow(
                                icon: Icons.healing,
                                label: 'Previous Health History',
                                value: user.pHealthHistory ?? 'Not provided',
                                controller: _pHealthHistoryController,
                                isEditing: _isEditing,
                                keyboardType: TextInputType.multiline,
                                maxLines: 3,
                              ),
                              const Divider(color: Colors.white38),
                              ProfileInfoRow(
                                icon: Icons.health_and_safety,
                                label: 'Current Health Status',
                                value: user.cHealthStatus ?? 'Not provided',
                                controller: _cHealthStatusController,
                                isEditing: _isEditing,
                                keyboardType: TextInputType.multiline,
                                maxLines: 3,
                              ),
                              const Divider(color: Colors.white38),
                              ProfileInfoRow(
                                icon: Icons.security,
                                label: 'Coverage',
                                value: user.coverage?.join(', ') ?? 'Not provided',
                                controller: _coverageController,
                                isEditing: _isEditing,
                              ),
                              const Divider(color: Colors.white38),
                              ProfileInfoRow(
                                icon: Icons.category,
                                label: 'Type',
                                value: user.type?.toString() ?? 'Not provided',
                                controller: _typeController,
                                isEditing: _isEditing,
                                keyboardType: TextInputType.number,
                                validator: (value) {
                                  if (value != null && value.isNotEmpty) {
                                    if (int.tryParse(value) == null) {
                                      return 'Please enter a valid number';
                                    }
                                  }
                                  return null;
                                },
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
                                    DropdownMenuItem(
                                      value: '1',
                                      child: Text('Male'),
                                    ),
                                    DropdownMenuItem(
                                      value: '2',
                                      child: Text('Female'),
                                    ),
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
                              ProfileInfoRow(
                                icon: Icons.calendar_today,
                                label: 'Date of Birth',
                                value: _dob != null
                                    ? '${_dob!.day}/${_dob!.month}/${_dob!.year}'
                                    : 'Not provided',
                                isEditing: _isEditing,
                                customInput: _isEditing
                                    ? InkWell(
                                  onTap: () => _selectDate(context),
                                  child: InputDecorator(
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
                                    child: Text(
                                      _dob != null
                                          ? '${_dob!.day}/${_dob!.month}/${_dob!.year}'
                                          : 'Select Date',
                                      style: const TextStyle(color: Colors.white),
                                    ),
                                  ),
                                )
                                    : null,
                              ),
                              const Divider(color: Colors.white38),
                              ProfileInfoRow(
                                icon: Icons.verified,
                                label: 'Verified',
                                value: user.verified == 1 ? 'Yes' : 'No',
                                isEditing: false, // Read-only
                              ),
                              const Divider(color: Colors.white38),
                              ProfileInfoRow(
                                icon: Icons.account_balance_wallet,
                                label: 'Wallet',
                                value: user.wallet?.toString() ?? '0',
                                isEditing: false, // Read-only
                              ),
                              const Divider(color: Colors.white38),
                              ProfileInfoRow(
                                icon: Icons.online_prediction,
                                label: 'Online Status',
                                value: user.online == 1 ? 'Online' : 'Offline',
                                isEditing: false, // Read-only
                              ),
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
                  style: TextStyle(
                    fontSize: size.width * 0.035,
                    color: Colors.white70,
                  ),
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