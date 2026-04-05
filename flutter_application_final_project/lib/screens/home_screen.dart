import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:intl/intl.dart';
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
import '../services/firebase_service.dart';

// Function to simulate an IoT fall detection trigger
void triggerFallAlert() async {
  try {
    print('🚨 [HomeScreen] Triggering fall alert');
    
    final alertId = DateTime.now().millisecondsSinceEpoch.toString();
    
    await FirebaseService.writeWithTimeout(
      'fall_alerts/$alertId',
      {
        "status": "CRITICAL: Fall Detected!",
        "timestamp": DateTime.now().toIso8601String(),
        "device_id": "elderly_sensor_01",
        "resolved": false,
      },
      timeout: const Duration(seconds: 5),
    );

    print("✅ [HomeScreen] Alert successfully sent to Firebase!");
  } on TimeoutException {
    print("❌ [HomeScreen] Fall alert timeout");
  } on FirebaseException catch (e) {
    print("❌ [HomeScreen] Firebase error sending alert: ${e.code} - ${e.message}");
  } catch (e) {
    print("❌ [HomeScreen] Error sending fall alert: $e");
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
  
  List<ActivityLog> _recentActivities = [];
  late StreamSubscription<DatabaseEvent> _dataListener;
  late StreamSubscription<DatabaseEvent> _historyListener;
  bool _hasShownFallAlert = false;
  bool _isFallAlertDialogOpen = false;
  bool _isLoadingHistory = true;
  String? _historyError;

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
    _setupHistoryListener();
  }

  @override
  void dispose() {
    _dataListener.cancel();
    _historyListener.cancel();
    super.dispose();
  }

  void _setupHistoryListener() {
    try {
      print('📖 [HomeScreen] Setting up history listener for watch001');
      
      DatabaseReference historyRef = FirebaseService.ref('history/watch001');
      
      _historyListener = historyRef.onValue.listen((DatabaseEvent event) {
        if (!mounted) return;

        print('📖 [HomeScreen] History snapshot received');
        setState(() {
          _isLoadingHistory = false;
          _historyError = null;
          _recentActivities = _convertToActivityList(event.snapshot);
          print('✅ [HomeScreen] Loaded ${_recentActivities.length} activities');
        });
      }, onError: (error) {
        if (!mounted) return;
        print('❌ History listener error: $error');
        setState(() {
          _isLoadingHistory = false;
          _historyError = 'Failed to load activity history';
        });
      });
    } catch (e) {
      print('❌ Failed to setup history listener: $e');
      setState(() {
        _isLoadingHistory = false;
        _historyError = 'Failed to setup history listener';
      });
    }
  }

  List<ActivityLog> _convertToActivityList(DataSnapshot snapshot) {
    if (!snapshot.exists) return [];

    List<Map<String, dynamic>> events = [];
    final data = snapshot.value as Map<dynamic, dynamic>?;

    if (data != null) {
      data.forEach((key, value) {
        if (value is Map<dynamic, dynamic>) {
          events.add({
            'id': key,
            'timestamp': value['timestamp'] ?? DateTime.now().millisecondsSinceEpoch,
            'status': value['status'] ?? 'NORMAL',
          });
        }
      });
    }

    // Sort by timestamp (latest first) and keep only 5
    events.sort((a, b) => (b['timestamp'] as int).compareTo(a['timestamp'] as int));
    events = events.take(5).toList();

    return events.map((event) {
      final status = event['status'] as String;
      final timestamp = event['timestamp'] as int;
      final dateTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
      final formatter = DateFormat('MMM dd, yyyy • hh:mm a');
      final formattedTime = formatter.format(dateTime);

      String activity = _getActivityLabel(status);
      String statusLabel = _getStatusLabel(status);

      return ActivityLog(
        activity: activity,
        time: formattedTime,
        status: statusLabel,
      );
    }).toList();
  }

  String _getActivityLabel(String status) {
    switch (status.toUpperCase()) {
      case 'FALL':
        return 'Fall detected';
      case 'INACTIVITY':
        return 'Inactivity alert';
      case 'NORMAL':
        return 'Normal movement detected';
      case 'LOW_BATTERY':
        return 'Low battery warning';
      case 'CONNECTIVITY_LOST':
        return 'Connectivity lost';
      default:
        return 'Activity recorded';
    }
  }

  String _getStatusLabel(String status) {
    switch (status.toUpperCase()) {
      case 'FALL':
        return 'Danger';
      case 'INACTIVITY':
      case 'LOW_BATTERY':
      case 'CONNECTIVITY_LOST':
        return 'Warning';
      default:
        return 'Safe';
    }
  }

  void _setupFirebaseListener() {
    try {
      print('📡 [HomeScreen] Setting up Firebase listener for watch001 live data');
      
      DatabaseReference ref = FirebaseService.ref('devices/watch001/live');
      
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

    // Trigger vibration
    HapticFeedback.heavyImpact();

    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.red.withOpacity(0.3),
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          backgroundColor: Colors.white,
          elevation: 20,
          title: const Row(
            children: [
              Icon(
                Icons.warning_rounded,
                color: Colors.red,
                size: 32,
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  '⚠️ FALL DETECTED',
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.w900,
                    fontSize: 20,
                  ),
                ),
              ),
            ],
          ),
          content: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red.withOpacity(0.3)),
                  ),
                  child: const Text(
                    'A fall has been detected by the device!',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.red,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Immediate action is required. Emergency services have been notified.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF64748B),
                    height: 1.6,
                  ),
                ),
              ],
            ),
          ),
          actionsPadding: const EdgeInsets.all(16),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _isFallAlertDialogOpen = false;
              },
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'ACKNOWLEDGE',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 4,
              ),
              onPressed: () {
                Navigator.of(context).pop();
                _isFallAlertDialogOpen = false;
                _onEmergencyCall();
              },
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.phone, size: 18),
                  SizedBox(width: 8),
                  Text(
                    'CALL EMERGENCY',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSensorDataWidget() {
    bool fallDetected = _sensorData['fallDetected'] ?? false;
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.08),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Live Sensor Data',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: fallDetected ? Colors.red.withOpacity(0.1) : AppColors.safeGreen.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      fallDetected ? 'FALL ⚠️' : '✓ Normal',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: fallDetected ? Colors.red : AppColors.safeGreen,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                children: [
                  _buildSensorCard(
                    label: 'Acceleration',
                    value: _formatValue(_sensorData['acc']),
                    unit: 'm/s²',
                    icon: Icons.flash_on,
                    isAbnormal: false,
                  ),
                  _buildSensorCard(
                    label: 'Temperature',
                    value: _formatValue(_sensorData['temperature']),
                    unit: '°C',
                    icon: Icons.thermostat,
                    isAbnormal: false,
                  ),
                  _buildSensorCard(
                    label: 'X-Axis',
                    value: _formatValue(_sensorData['ax']),
                    unit: 'm/s²',
                    icon: Icons.arrow_forward,
                    isAbnormal: false,
                  ),
                  _buildSensorCard(
                    label: 'Pressure',
                    value: _formatValue(_sensorData['pressure']),
                    unit: 'hPa',
                    icon: Icons.compress,
                    isAbnormal: false,
                  ),
                  _buildSensorCard(
                    label: 'Y-Axis',
                    value: _formatValue(_sensorData['ay']),
                    unit: 'm/s²',
                    icon: Icons.arrow_upward,
                    isAbnormal: false,
                  ),
                  _buildSensorCard(
                    label: 'Z-Axis',
                    value: _formatValue(_sensorData['az']),
                    unit: 'm/s²',
                    icon: Icons.arrow_downward,
                    isAbnormal: false,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSensorCard({
    required String label,
    required String value,
    required String unit,
    required IconData icon,
    required bool isAbnormal,
  }) {
    Color accentColor = isAbnormal ? AppColors.dangerRed : AppColors.primary;
    
    return Container(
      decoration: BoxDecoration(
        color: isAbnormal
            ? AppColors.dangerRed.withOpacity(0.05)
            : AppColors.primary.withOpacity(0.05),
        border: Border.all(
          color: isAbnormal
              ? AppColors.dangerRed.withOpacity(0.2)
              : AppColors.primary.withOpacity(0.15),
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(
                icon,
                color: accentColor,
                size: 20,
              ),
              const SizedBox.shrink(),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: accentColor,
                  ),
                ),
                TextSpan(
                  text: ' $unit',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: accentColor.withOpacity(0.7),
                  ),
                ),
              ],
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

  Widget _buildDynamicStatusCard() {
    bool fallDetected = _sensorData['fallDetected'] ?? false;
    
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: fallDetected
                ? [Colors.red.withOpacity(0.1), Colors.red.withOpacity(0.05)]
                : [AppColors.safeGreen.withOpacity(0.1), AppColors.safeGreen.withOpacity(0.05)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: fallDetected ? Colors.red.withOpacity(0.3) : AppColors.safeGreen.withOpacity(0.3),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: (fallDetected ? Colors.red : AppColors.safeGreen).withOpacity(0.1),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        fallDetected ? Icons.warning_rounded : Icons.check_circle_rounded,
                        color: fallDetected ? Colors.red : AppColors.safeGreen,
                        size: 32,
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            fallDetected ? 'Danger' : 'Safe',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: fallDetected ? Colors.red : AppColors.safeGreen,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            fallDetected ? 'Fall detected' : 'Monitoring active',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF64748B),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Column(
                      children: [
                        Text(
                          'Battery',
                          style: TextStyle(
                            fontSize: 10,
                            color: Color(0xFF64748B),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          '85%',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                fallDetected
                    ? 'Fall detected! Immediate action required. Emergency contacts have been notified.'
                    : 'No unusual activity detected. Device is functioning normally.',
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF64748B),
                  height: 1.6,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(1),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: fallDetected ? Colors.red.withOpacity(0.2) : AppColors.safeGreen.withOpacity(0.2),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(7),
                  child: LinearProgressIndicator(
                    value: fallDetected ? 1.0 : 0.0,
                    minHeight: 4,
                    backgroundColor: Colors.transparent,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      fallDetected ? Colors.red : AppColors.safeGreen,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentActivitySection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Recent Activity',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 16),
          if (_isLoadingHistory)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: CircularProgressIndicator(
                  color: AppColors.primary,
                ),
              ),
            )
          else if (_historyError != null)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 48,
                      color: AppColors.dangerRed,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _historyError!,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF64748B),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
          else if (_recentActivities.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  children: [
                    Icon(
                      Icons.history,
                      size: 48,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'No activity recorded yet',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _recentActivities.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final activity = _recentActivities[index];
                Color statusColor = activity.status == 'Danger'
                    ? AppColors.dangerRed
                    : activity.status == 'Warning'
                        ? AppColors.warningOrange
                        : AppColors.safeGreen;
                IconData statusIcon = activity.status == 'Danger'
                    ? Icons.warning_rounded
                    : activity.status == 'Warning'
                        ? Icons.info_rounded
                        : Icons.check_circle_rounded;

                return Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: statusColor.withOpacity(0.2),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          statusIcon,
                          color: statusColor,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              activity.activity,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              activity.time,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF64748B),
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          activity.status,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: statusColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
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
            _buildDynamicStatusCard(),
            ActionButtonsRow(
              onEmergencyCall: _onEmergencyCall,
              onCheckVitals: _onCheckVitals,
              onNotifyRelatives: _onNotifyRelatives,
            ),
            _buildSensorDataWidget(),
            _buildRecentActivitySection(),
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
                        _buildDynamicStatusCard(),
                        ActionButtonsRow(
                          onEmergencyCall: _onEmergencyCall,
                          onCheckVitals: _onCheckVitals,
                          onNotifyRelatives: _onNotifyRelatives,
                        ),
                        _buildSensorDataWidget(),
                        _buildRecentActivitySection(),
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

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 800;

    if (isMobile) {
      return _buildMobileLayout();
    } else {
      return _buildDesktopLayout();
    }
  }
}
