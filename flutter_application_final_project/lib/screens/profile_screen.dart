import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import '../constants/app_colors.dart';
import '../widgets/top_bar.dart';
import '../widgets/sidebar.dart';

class ProfileScreen extends StatefulWidget {
  final String? userId;

  const ProfileScreen({Key? key, this.userId}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  int _selectedMenuIndex = 3; // Profile is at index 3
  bool _pushNotificationsEnabled = true;
  String _fallSensitivity = 'Medium';

  Map<String, dynamic>? userData;
  bool _isLoading = true;
  String? _errorMessage;
  User? _currentUser;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      print("👤 [ProfileScreen] Step 1: Getting current user from Firebase Auth...");
      
      // Get currently logged-in user from Firebase Auth
      _currentUser = FirebaseAuth.instance.currentUser;

      if (_currentUser == null) {
        print("❌ [ProfileScreen] No user logged in");
        setState(() {
          _errorMessage = 'Not logged in';
          _isLoading = false;
        });
        return;
      }

      print("✅ [ProfileScreen] Current user UID: ${_currentUser!.uid}");

      // Use the passed userId if available (e.g., viewing another user's profile)
      // Otherwise, use the currently logged-in user's UID
      final userId = widget.userId ?? _currentUser!.uid;
      print("👤 [ProfileScreen] Step 2: Loading profile for userId: $userId");

      // Connect to Firebase Realtime Database with explicit region
      print("🔗 [ProfileScreen] Step 3: Connecting to Firebase Realtime Database...");
      final database = FirebaseDatabase.instanceFor(
        app: Firebase.app(),
        databaseURL:
            "https://app-dev-safestefs-default-rtdb.asia-southeast1.firebasedatabase.app",
      );

      print("📖 [ProfileScreen] Step 4: Fetching user data from database...");
      
      // Add timeout to prevent infinite hanging
      final snapshot = await database
          .ref('users/$userId')
          .get()
          .timeout(
            const Duration(seconds: 5),
            onTimeout: () {
              throw TimeoutException('Database read timed out after 5 seconds');
            },
          );

      print("📦 [ProfileScreen] Step 5: Snapshot received");
      print("📦 [ProfileScreen] Snapshot exists: ${snapshot.exists}");
      print("📦 [ProfileScreen] Snapshot value type: ${snapshot.value.runtimeType}");

      if (snapshot.exists) {
        print("✅ [ProfileScreen] User profile found, processing data...");
        
        // Safely convert snapshot to Map
        final value = snapshot.value;
        
        if (value is Map) {
          final userData = Map<String, dynamic>.from(value);
          print("✅ [ProfileScreen] Profile data loaded successfully");
          print("📝 [ProfileScreen] User name: ${userData['name']}");
          
          setState(() {
            this.userData = userData;
            _isLoading = false;
          });
        } else {
          print("⚠️  [ProfileScreen] Unexpected snapshot value type: $value");
          setState(() {
            _errorMessage = 'Invalid profile data format';
            _isLoading = false;
          });
        }
      } else {
        print("⚠️  [ProfileScreen] User profile not found in database");
        setState(() {
          _errorMessage = 'User profile not found. Please complete registration.';
          _isLoading = false;
        });
      }
    } on TimeoutException catch (e) {
      print("❌ [ProfileScreen] Timeout Error: ${e.message}");
      if (mounted) {
        setState(() {
          _errorMessage = 'Connection timed out. Please check your internet and try again.';
          _isLoading = false;
        });
      }
    } on FirebaseException catch (e) {
      print("❌ [ProfileScreen] Firebase Error: ${e.code} - ${e.message}");
      if (mounted) {
        setState(() {
          _errorMessage = 'Database error: ${e.message}';
          _isLoading = false;
        });
      }
    } catch (e, stackTrace) {
      print("❌ [ProfileScreen] Unexpected Error: $e");
      print("📋 Stack trace: $stackTrace");
      if (mounted) {
        setState(() {
          _errorMessage = 'Error loading profile: $e';
          _isLoading = false;
        });
      }
    }
  }

  void _onMenuItemSelected(int index) {
    if (_selectedMenuIndex == index) return; // Don't navigate if already on this screen

    setState(() {
      _selectedMenuIndex = index;
    });

    // Navigate to different screens based on index
    switch (index) {
      case 0: // Dashboard
        Navigator.of(context).pushReplacementNamed('/');
        break;
      case 1: // History
        Navigator.of(context).pushReplacementNamed('/history');
        break;
      case 2: // Relatives
        Navigator.of(context).pushReplacementNamed('/relatives');
        break;
      case 3: // Profile - Already on profile screen
        break;
    }
  }

  void _onSignOut() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (mounted) {
                Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
              }
            },
            child: const Text('Sign Out', style: TextStyle(color: AppColors.dangerRed)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppColors.lightBackground,
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Loading profile...'),
            ],
          ),
        ),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        backgroundColor: AppColors.lightBackground,
        appBar: const TopBar(),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                color: AppColors.dangerRed,
                size: 48,
              ),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 24),
              if (_errorMessage == 'Not logged in')
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                  ),
                  child: const Text(
                    'Go to Login',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
            ],
          ),
        ),
      );
    }

    final isMobile = MediaQuery.of(context).size.width < 800;

    if (isMobile) {
      return _buildMobileLayout();
    } else {
      return _buildDesktopLayout();
    }
  }

  Widget _buildMobileLayout() {
    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      appBar: const TopBar(),
      drawer: Drawer(
        child: Sidebar(
          selectedIndex: _selectedMenuIndex,
          onItemSelected: _onMenuItemSelected,
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildProfileCard(),
            const SizedBox(height: 20),
            _buildDeviceStatus(),
            const SizedBox(height: 20),
            _buildApplicationSettings(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildDesktopLayout() {
    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      body: Row(
        children: [
          // Sidebar
          Sidebar(
            selectedIndex: _selectedMenuIndex,
            onItemSelected: _onMenuItemSelected,
          ),
          // Main Content
          Expanded(
            child: Column(
              children: [
                const TopBar(),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        _buildProfileCard(),
                        const SizedBox(height: 20),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: _buildDeviceStatus(),
                              ),
                              const SizedBox(width: 20),
                              Expanded(
                                child: _buildApplicationSettings(),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getInitials(String name) {
    return name
        .split(' ')
        .map((n) => n.isEmpty ? '' : n[0])
        .take(2)
        .join()
        .toUpperCase();
  }

  Widget _buildProfileCard() {
    if (userData == null) {
      return const SizedBox.shrink();
    }

    final name = userData!['name'] ?? 'Unknown User';
    final age = userData!['age'] ?? 0;
    final address = userData!['address'] ?? 'No address provided';
    final conditions = userData!['conditions'] as List<dynamic>? ?? [];
    final bloodType = userData!['blood_type'] ?? 'Unknown';
    final email = userData!['email'] ?? '';

    final isCurrentUser = widget.userId == null || widget.userId == _currentUser?.uid;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar with initials
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: const Color(0xFFE0E7FF),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                _getInitials(name),
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
          const SizedBox(width: 20),
          // User Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textDark,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$age years old • $address',
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.textMedium,
                            ),
                          ),
                          if (email.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                email,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textLight,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Health badges from Firebase
                Wrap(
                  spacing: 8,
                  children: [
                    ..._buildHealthBadges(conditions),
                    _buildHealthBadge('Blood Type: $bloodType', const Color(0xFFEF5350)),
                  ],
                ),
              ],
            ),
          ),
          // Status indicator
          if (isCurrentUser)
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.safeGreen,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check,
                color: Colors.white,
                size: 22,
              ),
            ),
        ],
      ),
    );
  }

  List<Widget> _buildHealthBadges(List<dynamic> conditions) {
    final colors = [
      const Color(0xFF1E88E5),
      const Color(0xFFFFA726),
      const Color(0xFF43A047),
      const Color(0xFFE91E63),
      const Color(0xFF9C27B0),
    ];

    return conditions.asMap().entries.map((entry) {
      final index = entry.key;
      final condition = entry.value.toString();
      final color = colors[index % colors.length];
      return _buildHealthBadge(condition, color);
    }).toList();
  }

  Widget _buildHealthBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget _buildDeviceStatus() {
    final deviceId = userData?['deviceId'] ?? 'Not configured';
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(
                Icons.smartphone,
                color: AppColors.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text(
                'Device Status',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Device details
          _buildDeviceDetailRow('Device ID', deviceId),
          const SizedBox(height: 12),
          _buildDeviceDetailRow('Firmware Version', 'v2.4.1'),
          const SizedBox(height: 12),
          _buildDeviceDetailRow('Last Sync', '10 mins ago'),
          const SizedBox(height: 16),
          // Battery Level
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.battery_full,
                  color: AppColors.safeGreen,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  'Battery Level',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textMedium,
                  ),
                ),
                const Spacer(),
                Text(
                  '85%',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppColors.safeGreen,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            color: AppColors.textMedium,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textDark,
          ),
        ),
      ],
    );
  }

  Widget _buildApplicationSettings() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(
                Icons.settings,
                color: AppColors.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text(
                'Application Settings',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Push Notifications Toggle
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Push Notifications',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Receive alerts on your phone',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textLight,
                    ),
                  ),
                ],
              ),
              Switch(
                value: _pushNotificationsEnabled,
                onChanged: (value) {
                  setState(() {
                    _pushNotificationsEnabled = value;
                  });
                },
                activeColor: AppColors.primary,
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Fall Sensitivity Dropdown
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: AppColors.textLight,
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Fall Sensitivity',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textDark,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              const Text(
                'Adjust detection threshold',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textLight,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: AppColors.textLight.withOpacity(0.3),
                    width: 1,
                  ),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: DropdownButton<String>(
                  value: _fallSensitivity,
                  isExpanded: true,
                  underline: const SizedBox(),
                  items: <String>['Low', 'Medium', 'High'].map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(
                        value,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textDark,
                        ),
                      ),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      _fallSensitivity = newValue ?? 'Medium';
                    });
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Sign Out Button
          GestureDetector(
            onTap: _onSignOut,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Color(0xFFFFE0E0),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                'Sign Out',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.dangerRed,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
