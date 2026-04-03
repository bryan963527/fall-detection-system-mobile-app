import 'package:flutter/material.dart';
import 'dart:async';
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
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedMenuIndex = 0;
  
  // Firebase real-time sensor data
  Map<String, dynamic> _sensorData = {
    'ax': '--',
    'ay': '--',
    'az': '--',
    'acc': '--',
    'temperature': '--',
    'pressure': '--',
    'fallDetected': false,
  };
  
  late StreamSubscription<DatabaseEvent> _dataListener;
  bool _hasShownFallAlert = false;
  bool _isFallAlertDialogOpen = false;

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
        Navigator.of(context).pushReplacementNamed('/history');
        break;
      case 2: // Relatives
        Navigator.of(context).pushReplacementNamed('/relatives');
        break;
      case 3: // Profile
        Navigator.of(context).pushReplacementNamed('/profile');
        break;
      case 4: // Settings
        Navigator.of(context).pushReplacementNamed('/settings');
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
  void initState() {
    super.initState();
    _setupFirebaseListener();
  }

  @override
  void dispose() {
    _dataListener.cancel();
    super.dispose();
  }

  void _setupFirebaseListener() {
    try {
      DatabaseReference ref = FirebaseDatabase.instance.ref('devices/watch001/live');
      
      _dataListener = ref.onValue.listen((DatabaseEvent event) {
        if (!mounted) return;

        final dynamic data = event.snapshot.value;

        setState(() {
          if (data is Map) {
            _sensorData = Map<String, dynamic>.from(data as Map);
          }

          // Check for fall detection and show alert only once
          bool fallDetected = _sensorData['fallDetected'] ?? false;
          if (fallDetected && !_isFallAlertDialogOpen && !_hasShownFallAlert) {
            _showFallAlertDialog();
          }
        });
      }, onError: (error) {
        print('❌ Firebase listener error: $error');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error reading sensor data: $error')),
        );
      });
    } catch (e) {
      print('❌ Failed to setup Firebase listener: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to connect to device: $e')),
      );
    }
  }

  void _showFallAlertDialog() {
    if (_isFallAlertDialogOpen) return;

    _isFallAlertDialogOpen = true;
    _hasShownFallAlert = true;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            '⚠️ FALL DETECTED',
            style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
          ),
          content: const Text(
            'A fall has been detected by the device!\n\n'
            'Immediate action is required. Emergency services have been notified.',
            style: TextStyle(fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _isFallAlertDialogOpen = false;
              },
              child: const Text('ACKNOWLEDGE', style: TextStyle(color: Colors.red)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              onPressed: () {
                Navigator.of(context).pop();
                _isFallAlertDialogOpen = false;
                _onEmergencyCall();
              },
              child: const Text('CALL EMERGENCY'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSensorDataWidget() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Live Sensor Data',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 16),
              _buildSensorRow('Acceleration (m/s²)', _formatValue(_sensorData['acc'])),
              _buildSensorRow('X-Axis', _formatValue(_sensorData['ax'])),
              _buildSensorRow('Y-Axis', _formatValue(_sensorData['ay'])),
              _buildSensorRow('Z-Axis', _formatValue(_sensorData['az'])),
              _buildSensorRow('Temperature (°C)', _formatValue(_sensorData['temperature'])),
              _buildSensorRow('Pressure (hPa)', _formatValue(_sensorData['pressure'])),
              const SizedBox(height: 12),
              _buildFallStatusRow(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSensorRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.grey,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFallStatusRow() {
    bool fallDetected = _sensorData['fallDetected'] ?? false;
    Color statusColor = fallDetected ? Colors.red : Colors.green;
    String statusText = fallDetected ? 'FALL DETECTED ⚠️' : 'Normal';

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: statusColor, width: 2),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Fall Status',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            statusText,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: statusColor,
            ),
          ),
        ],
      ),
    );
  }

  String _formatValue(dynamic value) {
    if (value == null) return '--';
    if (value is num) {
      return value.toStringAsFixed(2);
    }
    return value.toString();
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
            _buildSensorDataWidget(),
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
                        _buildSensorDataWidget(),
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
