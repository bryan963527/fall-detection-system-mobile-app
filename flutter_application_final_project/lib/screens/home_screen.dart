import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../models/activity_model.dart';
import '../widgets/status_card.dart';
import '../widgets/action_buttons.dart';
import '../widgets/recent_activity.dart';
import '../widgets/sidebar.dart';
import '../widgets/top_bar.dart';
import 'history_screen.dart';
import 'profile_screen.dart';
import 'relatives_screen.dart';
import 'settings_screen.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_core/firebase_core.dart';

// Function to simulate an IoT fall detection trigger
void triggerFallAlert() async {
  try {
    // 1. Point to a node in your database called "fall_alerts"
    DatabaseReference databaseRef = FirebaseDatabase.instance.ref(
      "fall_alerts",
    );

    // 2. Push a new record with a unique ID
    await databaseRef.push().set({
      "status": "CRITICAL: Fall Detected!",
      "timestamp": DateTime.now().toIso8601String(),
      "device_id": "elderly_sensor_01",
      "resolved": false,
    });

    print("✅ Alert successfully sent to Firebase!");
  } catch (e) {
    print("❌ Failed to send alert: $e");
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedMenuIndex = 0;

  final List<ActivityLog> recentActivities = [
    const ActivityLog(
      activity: 'Normal movement detected',
      time: 'Today, 10:31 AM',
      status: 'Safe',
    ),
    const ActivityLog(
      activity: 'Normal movement detected',
      time: 'Today, 10:32 AM',
      status: 'Safe',
    ),
    const ActivityLog(
      activity: 'Normal movement detected',
      time: 'Today, 10:33 AM',
      status: 'Safe',
    ),
  ];

  void _onMenuItemSelected(int index) {
    setState(() {
      _selectedMenuIndex = index;
    });

    // Navigate to different screens based on index
    switch (index) {
      case 0: // Dashboard - Already on home screen
        break;
      case 1: // History
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const HistoryScreen()),
        );
        break;
      case 2: // Relatives
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const RelativesScreen()),
        );
        break;
      case 3: // Profile
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const ProfileScreen()),
        );
        break;
      case 4: // setttings
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const SettingsScreen()),
        );
        break;
    }
  }

  void _onEmergencyCall() {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Emergency call initiated')));
  }

  void _onCheckVitals() async {
    // 1. Keep the SnackBar so the user knows the button worked
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Checking vitals... Sending to database...'),
      ),
    );

    try {
      // 2. Explicitly point to your specific Asia-Southeast database URL
      DatabaseReference databaseRef = FirebaseDatabase.instanceFor(
        app: Firebase.app(),
        databaseURL:
            'https://app-dev-safestefs-default-rtdb.asia-southeast1.firebasedatabase.app/',
      ).ref("vitals_logs");

      // 3. Push some dummy vitals data
      await databaseRef.push().set({
        "event": "Manual Vitals Check",
        "timestamp": DateTime.now().toIso8601String(),
        "heart_rate": 75, // Dummy data
        "blood_pressure": "120/80", // Dummy data
        "oxygen_level": "98%", // Dummy data
        "status": "Normal",
      });

      print("✅ Vitals check successfully sent to Firebase!");
    } catch (e) {
      print("❌ Failed to send vitals check: $e");
    }
  }

  void _onNotifyRelatives() {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Notifying relatives...')));
  }

  @override
  Widget build(BuildContext context) {
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
            StatusCard(
              status: 'Safe',
              message: 'Monitoring active. No unusual activity detected.',
              battery: '85%',
              signal: 'Good',
            ),
            ActionButtonsRow(
              onEmergencyCall: _onEmergencyCall,
              onCheckVitals: _onCheckVitals,
              onNotifyRelatives: _onNotifyRelatives,
            ),
            RecentActivitySection(activities: recentActivities),
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
                        StatusCard(
                          status: 'Safe',
                          message:
                              'Monitoring active. No unusual activity detected.',
                          battery: '85%',
                          signal: 'Good',
                        ),
                        ActionButtonsRow(
                          onEmergencyCall: _onEmergencyCall,
                          onCheckVitals: _onCheckVitals,
                          onNotifyRelatives: _onNotifyRelatives,
                        ),
                        RecentActivitySection(activities: recentActivities),
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
}
