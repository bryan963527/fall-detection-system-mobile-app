import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import '../constants/app_colors.dart';
import '../services/firebase_service.dart';
import '../widgets/sidebar.dart';
import '../widgets/top_bar.dart';

// Import your screens for the navigation fix
import 'home_screen.dart';
import 'history_screen.dart';
import 'relatives_screen.dart';
import 'profile_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  int _selectedMenuIndex = 4; // Settings is at index 4

  // State variables for notifications
  bool _pushNotifications = true;
  bool _emailAlerts = false;
  bool _criticalSiren = true;

  // --- THE NAVIGATION FIX ---
  // Using MaterialPageRoute instead of named routes to prevent the crash
  void _onMenuItemSelected(int index) {
    if (index == _selectedMenuIndex) return;

    setState(() {
      _selectedMenuIndex = index;
    });

    switch (index) {
      case 0:
        Navigator.of(context).pushReplacementNamed('/');
        break;
      case 1:
        Navigator.of(context).pushReplacementNamed('/history');
        break;
      case 2:
        Navigator.of(context).pushReplacementNamed('/relatives');
        break;
      case 3:
        Navigator.of(context).pushReplacementNamed('/profile');
        break;
    }
  }

  void _showHealthModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const HealthSettingsModal(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 800;

    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      drawer: !isDesktop
          ? Drawer(
              child: Sidebar(
                selectedIndex: _selectedMenuIndex,
                onItemSelected: _onMenuItemSelected,
              ),
            )
          : null,
      body: Row(
        children: [
          if (isDesktop)
            Sidebar(
              selectedIndex: _selectedMenuIndex,
              onItemSelected: _onMenuItemSelected,
            ),
          Expanded(
            child: Column(
              children: [
                const TopBar(),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Application Settings',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textDark,
                          ),
                        ),
                        const SizedBox(height: 24),

                        // --- NEW HEALTH & FALL RISK SECTION ---
                        _buildSettingsCard(
                          title: "Health & Calibration",
                          children: [
                            ListTile(
                              leading: const Icon(
                                Icons.medical_information,
                                color: AppColors.primary,
                              ),
                              title: const Text("Update Health Information"),
                              subtitle: const Text(
                                "Modify fall risk factors for better accuracy",
                              ),
                              trailing: const Icon(Icons.chevron_right),
                              onTap: _showHealthModal, // Opens the modal
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // --- NOTIFICATION SETTINGS ---
                        _buildSettingsCard(
                          title: "Notification Settings",
                          children: [
                            _buildToggleTile(
                              "Push Notifications",
                              _pushNotifications,
                              (val) => setState(() => _pushNotifications = val),
                            ),
                            _buildToggleTile(
                              "Email Alerts",
                              _emailAlerts,
                              (val) => setState(() => _emailAlerts = val),
                            ),
                            _buildToggleTile(
                              "Critical Emergency Siren",
                              _criticalSiren,
                              (val) => setState(() => _criticalSiren = val),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // --- DEVICE CALIBRATION ---
                        _buildSettingsCard(
                          title: "Device Calibration",
                          children: [
                            ListTile(
                              title: const Text("Sensor Sensitivity"),
                              subtitle: const Text(
                                "Adjust fall detection threshold",
                              ),
                              trailing: const Icon(Icons.chevron_right),
                              onTap: () {},
                            ),
                            const Divider(height: 1, indent: 16, endIndent: 16),
                            ListTile(
                              title: const Text("Re-calibrate Gyroscope"),
                              subtitle: const Text(
                                "Last calibrated: 2 days ago",
                              ),
                              trailing: TextButton(
                                onPressed: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text("Calibration started..."),
                                    ),
                                  );
                                },
                                child: const Text("Start"),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),
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

  Widget _buildSettingsCard({
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.textMedium,
              fontSize: 13,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildToggleTile(String title, bool value, Function(bool) onChanged) {
    return SwitchListTile(
      title: Text(
        title,
        style: const TextStyle(fontSize: 14, color: AppColors.textDark),
      ),
      value: value,
      activeColor: AppColors.primary,
      onChanged: onChanged,
    );
  }
}

// ============================================================================
// THE HEALTH MODAL WIDGET (Handles Firebase Read/Write internally)
// ============================================================================
class HealthSettingsModal extends StatefulWidget {
  const HealthSettingsModal({super.key});

  @override
  State<HealthSettingsModal> createState() => _HealthSettingsModalState();
}

class _HealthSettingsModalState extends State<HealthSettingsModal> {
  bool _isLoading = true;
  bool _isSaving = false;

  bool _hasOsteoporosis = false;
  bool _hasVertigo = false;
  bool _usesMobilityAid = false;
  bool _historyOfFalls = false;

  final User? _user = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _loadHealthData();
  }

  // Fetch current settings from Firebase
  Future<void> _loadHealthData() async {
    if (_user == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      print('📖 Loading health data for user: ${_user!.uid}');
      
      final data = await FirebaseService.getWithTimeout(
        'users/${_user!.uid}/health_factors',
        timeout: const Duration(seconds: 5),
      );

      if (mounted) {
        if (data != null) {
          setState(() {
            _hasOsteoporosis = data['osteoporosis'] ?? false;
            _hasVertigo = data['vertigo'] ?? false;
            _usesMobilityAid = data['mobility_aid'] ?? false;
            _historyOfFalls = data['history_of_falls'] ?? false;
            print('✅ Health data loaded successfully');
          });
        } else {
          print('ℹ️ No health data found for user');
        }
      }
    } on TimeoutException {
      print('❌ Health data load timed out');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Connection timed out. Please check your internet.'),
            backgroundColor: AppColors.dangerRed,
          ),
        );
      }
    } on FirebaseException catch (e) {
      print('❌ Firebase error loading health data: ${e.code} - ${e.message}');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.message}'),
            backgroundColor: AppColors.dangerRed,
          ),
        );
      }
    } catch (e) {
      print('❌ Unexpected error loading health data: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading data: $e'),
            backgroundColor: AppColors.dangerRed,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // Save new settings to Firebase
  Future<void> _saveHealthData() async {
    if (_user == null) return;
    setState(() => _isSaving = true);

    try {
      print('✏️ Saving health data for user: ${_user!.uid}');
      
      await FirebaseService.writeWithTimeout(
        'users/${_user!.uid}/health_factors',
        {
          "osteoporosis": _hasOsteoporosis,
          "vertigo": _hasVertigo,
          "mobility_aid": _usesMobilityAid,
          "history_of_falls": _historyOfFalls,
        },
        timeout: const Duration(seconds: 5),
      );

      print('✅ Health data saved successfully');
      
      if (mounted) {
        Navigator.pop(context); // Close the modal
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Health information updated!"),
            backgroundColor: AppColors.safeGreen,
          ),
        );
      }
    } on TimeoutException {
      print('❌ Health data save timed out');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Connection timed out. Please check your internet.'),
            backgroundColor: AppColors.dangerRed,
          ),
        );
      }
    } on FirebaseException catch (e) {
      print('❌ Firebase error saving health data: ${e.code} - ${e.message}');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.message}'),
            backgroundColor: AppColors.dangerRed,
          ),
        );
      }
    } catch (e) {
      print('❌ Unexpected error saving health data: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error saving data: $e"),
            backgroundColor: AppColors.dangerRed,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        top: 24,
        left: 24,
        right: 24,
        bottom:
            MediaQuery.of(context).viewInsets.bottom +
            24, // Adjust for keyboard if needed
      ),
      child: _isLoading
          ? const SizedBox(
              height: 200,
              child: Center(child: CircularProgressIndicator()),
            )
          : Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  "Update Health Information",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  "Select conditions that apply. This helps calibrate fall sensitivity.",
                  style: TextStyle(color: AppColors.textMedium),
                ),
                const SizedBox(height: 16),

                CheckboxListTile(
                  title: const Text("Osteoporosis (Fragile Bones)"),
                  value: _hasOsteoporosis,
                  activeColor: AppColors.primary,
                  onChanged: (val) => setState(() => _hasOsteoporosis = val!),
                ),
                CheckboxListTile(
                  title: const Text("Vertigo / Chronic Dizziness"),
                  value: _hasVertigo,
                  activeColor: AppColors.primary,
                  onChanged: (val) => setState(() => _hasVertigo = val!),
                ),
                CheckboxListTile(
                  title: const Text("Uses a Mobility Aid (Cane, Walker)"),
                  value: _usesMobilityAid,
                  activeColor: AppColors.primary,
                  onChanged: (val) => setState(() => _usesMobilityAid = val!),
                ),
                CheckboxListTile(
                  title: const Text("Previous History of Falls"),
                  value: _historyOfFalls,
                  activeColor: AppColors.primary,
                  onChanged: (val) => setState(() => _historyOfFalls = val!),
                ),

                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _isSaving ? null : _saveHealthData,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          "Save Changes",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ],
            ),
    );
  }
}
