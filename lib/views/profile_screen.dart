import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
  String _gender = '1'; // Default to match payload
  DateTime? _dob;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    final user = Provider.of<UserController>(context, listen: false).user;
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
    _gender = user?.gender ?? '1';
    _dob = user?.dob != null ? DateTime.tryParse(user!.dob!) : null;

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
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _dob ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _dob) {
      setState(() {
        _dob = picked;
      });
    }
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
                        setEmail: _emailController.text.trim(), // Match SetEmail to email
                      );

                      print('🚀 Update result: $success, Error: ${controller.errorMessage}');
                      if (success) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Profile updated successfully'),
                            backgroundColor: Colors.green,
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
                      onPressed: () async {
                        final prefs = await SharedPreferences.getInstance();
                        final userId = prefs.getString('userId') ?? '';
                        if (userId.isNotEmpty) {
                          await controller.fetchUserDetails(userId);
                        }
                      },
                      child: const Text('Retry'),
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
                      // Profile Avatar
                      CircleAvatar(
                        radius: avatarRadius,
                        backgroundImage: NetworkImage(
                          'https://i.pravatar.cc/150?img=${(user.username ?? 'User').hashCode % 70}',
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
                isEditing
                    ? TextFormField(
                  controller: controller,
                  style: const TextStyle(color: Colors.white),
                  keyboardType: keyboardType,
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