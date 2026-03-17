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

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

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
    }
  }

  void _onEmergencyCall() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Emergency call initiated')),
    );
  }

  void _onCheckVitals() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Checking vitals...')),
    );
  }

  void _onNotifyRelatives() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Notifying relatives...')),
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
