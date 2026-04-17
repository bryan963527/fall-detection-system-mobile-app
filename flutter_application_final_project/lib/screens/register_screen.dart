import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_core/firebase_core.dart';
import '../constants/app_colors.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  // Controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _emergencyContactNameController = TextEditingController();
  final TextEditingController _emergencyContactNumberController = TextEditingController();

  // Google Sign-In data
  String? _googleUid;
  late String _googleEmail;
  late String _googleDisplayName;
  String? _googlePhotoUrl;
  String _authProvider = 'email'; // 'email' or 'google'
  bool _isEmailEditable = true;
  bool _argumentsInitialized = false;

  DateTime? _selectedDOB;
  String _selectedBloodType = 'A+';
  final List<String> _bloodTypes = ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'];

  @override
  void initState() {
    super.initState();
    print("📝 [RegisterScreen] initState() called");
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    // Only initialize arguments once
    if (!_argumentsInitialized) {
      print("📝 [RegisterScreen] didChangeDependencies() - Initializing arguments");
      _initializeGoogleData();
      _argumentsInitialized = true;
    }
  }

  void _initializeGoogleData() {
    try {
      print("📝 [RegisterScreen] Retrieving route arguments...");
      
      // Safely retrieve arguments passed from LoginScreen
      final route = ModalRoute.of(context);
      print("📝 [RegisterScreen] Route: $route");
      
      final settings = route?.settings;
      print("📝 [RegisterScreen] Settings: $settings");
      
      final rawArguments = settings?.arguments;
      print("📝 [RegisterScreen] Raw arguments: $rawArguments (type: ${rawArguments.runtimeType})");

      // Safely cast arguments
      final arguments = rawArguments is Map<String, dynamic> ? rawArguments : null;
      
      if (arguments == null) {
        print("⚠️  [RegisterScreen] No arguments passed or invalid type");
        print("📝 [RegisterScreen] Defaulting to email registration");
        _authProvider = 'email';
        _isEmailEditable = true;
        return;
      }

      print("✅ [RegisterScreen] Arguments retrieved successfully");

      // Safely extract values with null-coalescing
      _googleUid = arguments['uid'] as String?;
      _googleEmail = (arguments['email'] as String?) ?? '';
      _googleDisplayName = (arguments['displayName'] as String?) ?? 'User';
      _googlePhotoUrl = arguments['photoUrl'] as String?;
      _authProvider = arguments['provider'] as String? ?? 'email';

      print("📝 [RegisterScreen] UID: $_googleUid");
      print("📝 [RegisterScreen] Email: $_googleEmail");
      print("📝 [RegisterScreen] Display Name: $_googleDisplayName");
      print("📝 [RegisterScreen] Provider: $_authProvider");

      // Pre-fill fields if coming from Google
      if (_authProvider == 'google' && _googleEmail.isNotEmpty) {
        print("📝 [RegisterScreen] Pre-filling fields from Google data");
        
        _emailController.text = _googleEmail;
        print("✅ [RegisterScreen] Email pre-filled: $_googleEmail");
        
        if (_googleDisplayName.isNotEmpty) {
          _nameController.text = _googleDisplayName;
          print("✅ [RegisterScreen] Name pre-filled: $_googleDisplayName");
        }
        
        _isEmailEditable = false; // Disable email editing for Google users
        print("✅ [RegisterScreen] Email field disabled (Google user)");
      } else {
        print("📝 [RegisterScreen] Email registration - all fields editable");
        _isEmailEditable = true;
      }
    } catch (e, stackTrace) {
      print("❌ [RegisterScreen] Error initializing Google data: $e");
      print("📋 Stack trace: $stackTrace");
      // Fail gracefully - default to email registration
      _authProvider = 'email';
      _isEmailEditable = true;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _ageController.dispose();
    _addressController.dispose();
    _emergencyContactNameController.dispose();
    _emergencyContactNumberController.dispose();
    super.dispose();
  }

  // Calculate age from DOB
  int? _calculateAge(DateTime dob) {
    final today = DateTime.now();
    int age = today.year - dob.year;
    if (today.month < dob.month || (today.month == dob.month && today.day < dob.day)) {
      age--;
    }
    return age > 0 ? age : null;
  }

  // Pick date of birth
  Future<void> _pickDateOfBirth() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1930),
      lastDate: DateTime.now(),
    );

    if (pickedDate != null) {
      final age = _calculateAge(pickedDate);
      setState(() {
        _selectedDOB = pickedDate;
        if (age != null) {
          _ageController.text = age.toString();
        }
      });
    }
  }

  // Validate email format
  bool _isValidEmail(String email) {
    return RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$').hasMatch(email);
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    print("--- REGISTRATION DEBUG: STARTING ---");
    print("Provider: $_authProvider");

    try {
      String uid;

      // Handle email registration or Google user profile completion
      if (_authProvider == 'google') {
        // For Google sign-in, use the existing user
        print("📝 [Register] Using existing Google-authenticated user");
        final user = FirebaseAuth.instance.currentUser;
        if (user == null) {
          throw Exception('No authenticated user found. Please sign in again.');
        }
        uid = user.uid;
        print("✅ [Register] Using Google user ID: $uid");
      } else {
        // For email registration, create new user
        print("📝 [Register] Creating new email user...");
        UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
        uid = userCredential.user!.uid;
        print("✅ [Register] Email user created. UID: $uid");
      }

      // Save complete profile to Realtime Database with timeout
      print("📝 [Register] Saving user profile to database...");
      final database = FirebaseDatabase.instanceFor(
        app: Firebase.app(),
        databaseURL:
            "https://app-dev-safestefs-default-rtdb.asia-southeast1.firebasedatabase.app",
      );
      
      DatabaseReference userRef = database.ref("users/$uid");

      final int age = int.tryParse(_ageController.text.trim()) ?? 0;

      final userData = {
        "name": _nameController.text.trim(),
        "email": _emailController.text.trim(),
        "age": age,
        "dob": _selectedDOB?.toIso8601String() ?? '',
        "address": _addressController.text.trim(),
        "blood_type": _selectedBloodType,
        "conditions": [],
        "deviceId": "watch001",
        "emergency_contact_name": _emergencyContactNameController.text.trim(),
        "emergency_contact_number": _emergencyContactNumberController.text.trim(),
        "provider": _authProvider,
        "photo_url": _googlePhotoUrl,
        "created_at": DateTime.now().toIso8601String(),
      };

      print("📝 [Register] User data: $userData");

      // Write to database with timeout
      await userRef.set(userData).timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          throw TimeoutException('Database write timed out after 5 seconds');
        },
      );

      print("✅ [Register] Profile saved successfully!");

      // Navigate to Home Screen
      if (mounted) {
        print("📝 [Register] Navigating to Home Screen...");
        setState(() => _isLoading = false);
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Registration completed successfully! 🎉'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
        Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
      }
    } on FirebaseAuthException catch (e) {
      print("❌ [Register] Firebase Auth Error: ${e.code} - ${e.message}");

      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message ?? "Registration failed. Please try again."),
            backgroundColor: AppColors.dangerRed,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } on TimeoutException catch (e) {
      print("❌ [Register] Timeout Error: ${e.message}");
      
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Database connection timed out. Please check your internet."),
            backgroundColor: AppColors.dangerRed,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e, stackTrace) {
      print("❌ [Register] Unexpected Error: $e");
      print("📋 Stack trace: $stackTrace");

      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("An error occurred: ${e.toString()}"),
            backgroundColor: AppColors.dangerRed,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
    print("--- REGISTRATION DEBUG: FINISHED ---");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textDark),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 600),
            padding: const EdgeInsets.all(32.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Create Account',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Join GyroStep and stay safe',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textMedium,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Account Details Section
                  const Text(
                    'Account Information',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 12),

                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Full Name',
                      prefixIcon: Icon(Icons.person_outline),
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) => value!.isEmpty ? 'Full name is required' : null,
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    enabled: _isEmailEditable,
                    decoration: InputDecoration(
                      labelText: 'Email Address',
                      prefixIcon: const Icon(Icons.email_outlined),
                      border: const OutlineInputBorder(),
                      helperText: _authProvider == 'google' ? 'Auto-filled from Google' : null,
                    ),
                    validator: (value) {
                      if (value!.isEmpty) return 'Email is required';
                      if (!_isValidEmail(value)) return 'Enter a valid email';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  if (_authProvider == 'email') ...[
                    TextFormField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Password',
                        prefixIcon: Icon(Icons.lock_outline),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value!.isEmpty) return 'Password is required';
                        if (value.length < 6) return 'Password must be at least 6 characters';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _confirmPasswordController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Confirm Password',
                        prefixIcon: Icon(Icons.lock_outline),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value!.isEmpty) return 'Please confirm your password';
                        if (value != _passwordController.text) return 'Passwords do not match';
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                  ] else ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.blue.shade600, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Password is managed by Google',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.blue.shade700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Health & Personal Details Section
                  const Text(
                    'Health & Personal Information',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Date of Birth Picker
                  GestureDetector(
                    onTap: _pickDateOfBirth,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Colors.grey.withOpacity(0.5),
                          width: 1,
                        ),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today_outlined, color: AppColors.textMedium),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _selectedDOB == null
                                  ? 'Select Date of Birth'
                                  : 'DOB: ${_selectedDOB!.toLocal().toString().split(' ')[0]}',
                              style: TextStyle(
                                fontSize: 14,
                                color: _selectedDOB == null ? AppColors.textLight : AppColors.textDark,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Age and Blood Type Row
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _ageController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Age',
                            prefixIcon: Icon(Icons.cake_outlined),
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value!.isEmpty) return 'Required';
                            final age = int.tryParse(value);
                            if (age == null || age <= 0) return 'Invalid age';
                            if (age < 18) return 'Must be 18+';
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: _selectedBloodType,
                          decoration: const InputDecoration(
                            labelText: 'Blood Type',
                            prefixIcon: Icon(Icons.bloodtype_outlined),
                            border: OutlineInputBorder(),
                          ),
                          items: _bloodTypes
                              .map((type) => DropdownMenuItem(
                                    value: type,
                                    child: Text(type),
                                  ))
                              .toList(),
                          onChanged: (newValue) => setState(() => _selectedBloodType = newValue!),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _addressController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Address',
                      prefixIcon: Icon(Icons.location_on_outlined),
                      border: OutlineInputBorder(),
                      alignLabelWithHint: true,
                    ),
                    validator: (value) => value!.isEmpty ? 'Address is required' : null,
                  ),
                  const SizedBox(height: 24),

                  // Emergency Contact Section
                  const Text(
                    'Emergency Contact (Optional)',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 12),

                  TextFormField(
                    controller: _emergencyContactNameController,
                    decoration: const InputDecoration(
                      labelText: 'Emergency Contact Name',
                      prefixIcon: Icon(Icons.person_outline),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _emergencyContactNumberController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Emergency Contact Number',
                      prefixIcon: Icon(Icons.phone_outlined),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 32),

                  ElevatedButton(
                    onPressed: _isLoading ? null : _register,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.safeGreen,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            'Complete Registration',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
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
  }
}
