import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../models/event_model.dart';
import '../widgets/events_table.dart';
import '../widgets/sidebar.dart';
import '../widgets/weekly_activity_chart.dart';
import 'home_screen.dart';
import 'profile_screen.dart';
import 'relatives_screen.dart';
import 'settings_screen.dart';


class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  static const List<WeeklyActivityData> _weeklyData = [
    WeeklyActivityData(day: 'Mon', value: 40),
    WeeklyActivityData(day: 'Tue', value: 30),
    WeeklyActivityData(day: 'Wed', value: 20),
    WeeklyActivityData(day: 'Thu', value: 26),
    WeeklyActivityData(day: 'Fri', value: 18),
    WeeklyActivityData(day: 'Sat', value: 24),
    WeeklyActivityData(day: 'Sun', value: 33),
  ];

  int _selectedMenuIndex = 1;
  final List<Event> _events = _buildEvents();

  static List<Event> _buildEvents() {
    return [
      Event(
        id: '#001',
        type: EventType.fallDetected,
        dateTime: DateTime(2023, 11, 25, 14, 30),
        severity: Severity.high,
        status: EventStatus.resolved,
      ),
      Event(
        id: '#002',
        type: EventType.inactivityAlert,
        dateTime: DateTime(2023, 11, 24, 9, 15),
        severity: Severity.medium,
        status: EventStatus.falseAlarm,
      ),
      Event(
        id: '#003',
        type: EventType.systemCheck,
        dateTime: DateTime(2023, 11, 23, 18, 45),
        severity: Severity.low,
        status: EventStatus.completed,
      ),
      Event(
        id: '#004',
        type: EventType.lowBattery,
        dateTime: DateTime(2023, 11, 22, 11, 20),
        severity: Severity.medium,
        status: EventStatus.charged,
      ),
      Event(
        id: '#005',
        type: EventType.connectivityLost,
        dateTime: DateTime(2023, 11, 21, 16, 10),
        severity: Severity.low,
        status: EventStatus.restored,
      ),
      Event(
        id: '#006',
        type: EventType.normalMovement,
        dateTime: DateTime(2023, 11, 20, 10, 5),
        severity: Severity.low,
        status: EventStatus.completed,
      ),
      Event(
        id: '#007',
        type: EventType.fallDetected,
        dateTime: DateTime(2023, 11, 19, 12, 30),
        severity: Severity.high,
        status: EventStatus.resolved,
      ),
      Event(
        id: '#008',
        type: EventType.lowBattery,
        dateTime: DateTime(2023, 11, 18, 8, 45),
        severity: Severity.medium,
        status: EventStatus.charged,
      ),
      Event(
        id: '#009',
        type: EventType.systemCheck,
        dateTime: DateTime(2023, 11, 17, 15, 20),
        severity: Severity.low,
        status: EventStatus.completed,
      ),
      Event(
        id: '#010',
        type: EventType.inactivityAlert,
        dateTime: DateTime(2023, 11, 16, 19, 50),
        severity: Severity.medium,
        status: EventStatus.falseAlarm,
      ),
      Event(
        id: '#011',
        type: EventType.connectivityLost,
        dateTime: DateTime(2023, 11, 15, 13, 15),
        severity: Severity.low,
        status: EventStatus.restored,
      ),
      Event(
        id: '#012',
        type: EventType.normalMovement,
        dateTime: DateTime(2023, 11, 14, 11, 0),
        severity: Severity.low,
        status: EventStatus.completed,
      ),
      Event(
        id: '#013',
        type: EventType.fallDetected,
        dateTime: DateTime(2023, 11, 13, 9, 30),
        severity: Severity.high,
        status: EventStatus.resolved,
      ),
      Event(
        id: '#014',
        type: EventType.lowBattery,
        dateTime: DateTime(2023, 11, 12, 7, 10),
        severity: Severity.medium,
        status: EventStatus.charged,
      ),
      Event(
        id: '#015',
        type: EventType.systemCheck,
        dateTime: DateTime(2023, 11, 11, 17, 45),
        severity: Severity.low,
        status: EventStatus.completed,
      ),
      Event(
        id: '#016',
        type: EventType.inactivityAlert,
        dateTime: DateTime(2023, 11, 10, 14, 20),
        severity: Severity.medium,
        status: EventStatus.falseAlarm,
      ),
      Event(
        id: '#017',
        type: EventType.connectivityLost,
        dateTime: DateTime(2023, 11, 9, 10, 55),
        severity: Severity.low,
        status: EventStatus.restored,
      ),
      Event(
        id: '#018',
        type: EventType.normalMovement,
        dateTime: DateTime(2023, 11, 8, 12, 5),
        severity: Severity.low,
        status: EventStatus.completed,
      ),
      Event(
        id: '#019',
        type: EventType.fallDetected,
        dateTime: DateTime(2023, 11, 7, 16, 40),
        severity: Severity.high,
        status: EventStatus.resolved,
      ),
      Event(
        id: '#020',
        type: EventType.lowBattery,
        dateTime: DateTime(2023, 11, 6, 9, 25),
        severity: Severity.medium,
        status: EventStatus.charged,
      ),
      Event(
        id: '#021',
        type: EventType.systemCheck,
        dateTime: DateTime(2023, 11, 5, 13, 50),
        severity: Severity.low,
        status: EventStatus.completed,
      ),
      Event(
        id: '#022',
        type: EventType.inactivityAlert,
        dateTime: DateTime(2023, 11, 4, 11, 15),
        severity: Severity.medium,
        status: EventStatus.falseAlarm,
      ),
      Event(
        id: '#023',
        type: EventType.connectivityLost,
        dateTime: DateTime(2023, 11, 3, 15, 30),
        severity: Severity.low,
        status: EventStatus.restored,
      ),
      Event(
        id: '#024',
        type: EventType.normalMovement,
        dateTime: DateTime(2023, 11, 2, 10, 10),
        severity: Severity.low,
        status: EventStatus.completed,
      ),
    ];
  }

  void _onMenuItemSelected(int index) {
    setState(() => _selectedMenuIndex = index);

    switch (index) {
      case 0:
        Navigator.of(context).pushReplacementNamed('/');
        break;
      case 1:
        break;
      case 2:
        Navigator.of(context).pushReplacementNamed('/relatives');
        break;
      case 3:
        Navigator.of(context).pushReplacementNamed('/profile');
        break;
    }
  }

  void _exportCsv() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Export CSV clicked')),
    );
  }

  void _openFilter() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Filter clicked')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 1000;

    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      appBar: isDesktop
          ? null
          : AppBar(
              backgroundColor: Colors.white,
              elevation: 0,
              foregroundColor: const Color(0xFF0F172A),
              title: const Text(
                'Event History',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
      drawer: isDesktop
          ? null
          : Drawer(
              child: Sidebar(
                selectedIndex: _selectedMenuIndex,
                onItemSelected: _onMenuItemSelected,
              ),
            ),
      body: SafeArea(
        child: Row(
          children: [
            if (isDesktop)
              Sidebar(
                selectedIndex: _selectedMenuIndex,
                onItemSelected: _onMenuItemSelected,
              ),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: isDesktop ? 32 : 16,
                  vertical: isDesktop ? 24 : 16,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _PageHeader(
                      isDesktop: isDesktop,
                      onFilterTap: _openFilter,
                      onExportTap: _exportCsv,
                    ),
                    const SizedBox(height: 24),
                    WeeklyActivityChart(data: _weeklyData),
                    const SizedBox(height: 24),
                    EventsTable(events: _events),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PageHeader extends StatelessWidget {
  const _PageHeader({
    required this.isDesktop,
    required this.onFilterTap,
    required this.onExportTap,
  });

  final bool isDesktop;
  final VoidCallback onFilterTap;
  final VoidCallback onExportTap;

  @override
  Widget build(BuildContext context) {
    final titleSection = const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Event History',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Color(0xFF0F172A),
          ),
        ),
        SizedBox(height: 4),
        Text(
          'View past alerts and system logs.',
          style: TextStyle(
            fontSize: 14,
            color: Color(0xFF64748B),
          ),
        ),
      ],
    );

    final actions = Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        OutlinedButton.icon(
          onPressed: onFilterTap,
          icon: const Icon(Icons.filter_list_rounded, size: 18),
          label: const Text('Filter'),
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFF334155),
            backgroundColor: Colors.white,
            side: const BorderSide(color: Color(0xFFD7DEE8)),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
        ElevatedButton.icon(
          onPressed: onExportTap,
          icon: const Icon(Icons.download_rounded, size: 18),
          label: const Text('Export CSV'),
          style: ElevatedButton.styleFrom(
            elevation: 0,
            backgroundColor: const Color(0xFF2563EB),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
      ],
    );

    if (!isDesktop) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          titleSection,
          const SizedBox(height: 16),
          actions,
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: titleSection),
        actions,
      ],
    );
  }
}