import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../constants/app_colors.dart';
import '../models/event_model.dart';
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
  late DatabaseReference _historyRef;
  List<Map<String, dynamic>> _rawEvents = [];
  String? _selectedDeviceId;

  @override
  void initState() {
    super.initState();
    _selectedDeviceId = 'watch001'; // TODO: Get from user/device selection
    _historyRef =
        FirebaseDatabase.instance.ref('history/$_selectedDeviceId');
  }

  List<Map<String, dynamic>> _convertToEventList(
      DataSnapshot snapshot) {
    if (!snapshot.exists) return [];

    List<Map<String, dynamic>> events = [];
    final data = snapshot.value as Map<dynamic, dynamic>?;

    if (data != null) {
      data.forEach((key, value) {
        if (value is Map<dynamic, dynamic>) {
          events.add({
            'id': key,
            'timestamp': value['timestamp'] ?? DateTime.now().millisecondsSinceEpoch,
            'acc': value['acc'] ?? 0.0,
            'ax': value['ax'] ?? 0.0,
            'ay': value['ay'] ?? 0.0,
            'az': value['az'] ?? 0.0,
            'temperature': value['temperature'] ?? 0.0,
            'pressure': value['pressure'] ?? 0.0,
            'status': value['status'] ?? 'NORMAL',
          });
        }
      });
    }

    // Sort by timestamp (latest first)
    events.sort((a, b) => (b['timestamp'] as int).compareTo(a['timestamp'] as int));
    return events;
  }

  EventType _mapStatusToEventType(String status) {
    switch (status.toUpperCase()) {
      case 'FALL':
        return EventType.fallDetected;
      case 'INACTIVITY':
        return EventType.inactivityAlert;
      case 'LOW_BATTERY':
        return EventType.lowBattery;
      case 'CONNECTIVITY_LOST':
        return EventType.connectivityLost;
      case 'SYSTEM_CHECK':
        return EventType.systemCheck;
      default:
        return EventType.normalMovement;
    }
  }

  Severity _mapStatusToSeverity(String status) {
    switch (status.toUpperCase()) {
      case 'FALL':
        return Severity.high;
      case 'INACTIVITY':
      case 'LOW_BATTERY':
      case 'CONNECTIVITY_LOST':
        return Severity.medium;
      default:
        return Severity.low;
    }
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

  void _showEventDetails(Map<String, dynamic> eventData) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => _EventDetailsSheet(eventData: eventData),
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
              child: StreamBuilder<DataSnapshot>(
                stream: _historyRef.onValue.map((event) => event.snapshot),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                      ),
                    );
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.error_outline,
                            size: 64,
                            color: AppColors.dangerRed,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Failed to load history',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Please try again later.',
                            style: TextStyle(
                              fontSize: 14,
                              color: Color(0xFF64748B),
                            ),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: () {
                              setState(() {});
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 24, vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            icon: const Icon(Icons.refresh),
                            label: const Text('Retry'),
                          ),
                        ],
                      ),
                    );
                  }

                  final events = _convertToEventList(snapshot.data!);

                  if (events.isEmpty) {
                    return Center(
                      child: SingleChildScrollView(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.history,
                              size: 80,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 24),
                            Text(
                              'No Events Yet',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                color: Colors.grey[800],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'No incidents or alerts have been recorded.',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return SingleChildScrollView(
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
                        _EventCardsList(
                          events: events,
                          onEventTap: _showEventDetails,
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EventCardsList extends StatelessWidget {
  const _EventCardsList({
    required this.events,
    required this.onEventTap,
  });

  final List<Map<String, dynamic>> events;
  final Function(Map<String, dynamic>) onEventTap;

  Color _getEventColor(String status) {
    switch (status.toUpperCase()) {
      case 'FALL':
        return AppColors.dangerRed;
      case 'NORMAL':
        return AppColors.safeGreen;
      default:
        return AppColors.warningOrange;
    }
  }

  IconData _getEventIcon(String status) {
    switch (status.toUpperCase()) {
      case 'FALL':
        return Icons.warning_rounded;
      case 'NORMAL':
        return Icons.check_circle_rounded;
      default:
        return Icons.info_rounded;
    }
  }

  String _formatDateTime(int timestamp) {
    final dateTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final formatter = DateFormat('MMM dd, yyyy • hh:mm a');
    return formatter.format(dateTime);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Events',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 16),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: events.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final event = events[index];
            final status = event['status'] as String;
            final color = _getEventColor(status);
            final icon = _getEventIcon(status);
            final timestamp = event['timestamp'] as int;

            return Material(
              child: InkWell(
                onTap: () => onEventTap(event),
                borderRadius: BorderRadius.circular(16),
                child: Ink(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.grey[200]!,
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            icon,
                            color: color,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                status,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _formatDateTime(timestamp),
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            status,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: color,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Icon(
                          Icons.chevron_right,
                          color: Colors.grey[400],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
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

class _EventDetailsSheet extends StatelessWidget {
  const _EventDetailsSheet({
    required this.eventData,
  });

  final Map<String, dynamic> eventData;

  String _formatDateTime(int timestamp) {
    final dateTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final formatter = DateFormat('EEEE, MMMM dd, yyyy • hh:mm a');
    return formatter.format(dateTime);
  }

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'FALL':
        return AppColors.dangerRed;
      case 'NORMAL':
        return AppColors.safeGreen;
      default:
        return AppColors.warningOrange;
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = eventData['status'] as String;
    final timestamp = eventData['timestamp'] as int;
    final acc = eventData['acc'] as num;
    final ax = eventData['ax'] as num;
    final ay = eventData['ay'] as num;
    final az = eventData['az'] as num;
    final temperature = eventData['temperature'] as num;
    final pressure = eventData['pressure'] as num;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Event Details',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.close,
                        size: 20,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status Badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusColor(status).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      status,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _getStatusColor(status),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Event Type and Time
                  _DetailRow(
                    label: 'Event Type',
                    value: status,
                  ),
                  const SizedBox(height: 16),
                  _DetailRow(
                    label: 'Date & Time',
                    value: _formatDateTime(timestamp),
                  ),
                  const SizedBox(height: 24),
                  const Divider(height: 1),
                  const SizedBox(height: 24),
                  // Sensor Data Section
                  const Text(
                    'Sensor Data',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _DetailRow(
                    label: 'Total Acceleration',
                    value: '${acc.toStringAsFixed(2)} m/s²',
                  ),
                  const SizedBox(height: 12),
                  _DetailRow(
                    label: 'X-Axis',
                    value: '${ax.toStringAsFixed(2)} m/s²',
                  ),
                  const SizedBox(height: 12),
                  _DetailRow(
                    label: 'Y-Axis',
                    value: '${ay.toStringAsFixed(2)} m/s²',
                  ),
                  const SizedBox(height: 12),
                  _DetailRow(
                    label: 'Z-Axis',
                    value: '${az.toStringAsFixed(2)} m/s²',
                  ),
                  const SizedBox(height: 24),
                  const Divider(height: 1),
                  const SizedBox(height: 24),
                  // Environmental Data Section
                  const Text(
                    'Environmental Data',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _DetailRow(
                    label: 'Temperature',
                    value: '${temperature.toStringAsFixed(1)}°C',
                  ),
                  const SizedBox(height: 12),
                  _DetailRow(
                    label: 'Pressure',
                    value: '${pressure.toStringAsFixed(0)} hPa',
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: Color(0xFF64748B),
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF0F172A),
          ),
        ),
      ],
    );
  }
}