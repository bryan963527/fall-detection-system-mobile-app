import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import '../constants/app_colors.dart';
import 'home_screen.dart';

class HealthSetupScreen extends StatefulWidget {
  const HealthSetupScreen({super.key});

  @override
  State<HealthSetupScreen> createState() => _HealthSetupScreenState();
}

class _HealthSetupScreenState extends State<HealthSetupScreen> {
  bool _isLoading = false;

  // Health factors
  bool _hasOsteoporosis = false;
  bool _hasVertigo = false;
  bool _hasArthritis = false;
  bool _usesMobilityAid = false;
  bool _historyOfFalls = false;
  bool _visionImpairment = false;

  Future<void> _saveAndContinue() async {
    setState(() => _isLoading = true);

    try {
      // 1. Get current user ID
      final User? user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception("No user logged in!");

      // 2. Save to Firebase under the user's specific node
      DatabaseReference healthRef = FirebaseDatabase.instance.ref(
        "users/${user.uid}/health_factors",
      );
      await healthRef.set({
        "osteoporosis": _hasOsteoporosis,
        "vertigo": _hasVertigo,
        "arthritis": _hasArthritis,
        "mobility_aid": _usesMobilityAid,
        "history_of_falls": _historyOfFalls,
        "vision_impairment": _visionImpairment,
      });

      // 3. Navigate to Dashboard
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const HomeScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error saving health data: $e"),
          backgroundColor: AppColors.dangerRed,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      appBar: AppBar(
        title: const Text(
          'Health Profile',
          style: TextStyle(
            color: AppColors.textDark,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 500),
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
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(
                  Icons.medical_information,
                  size: 64,
                  color: AppColors.primary,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Fall Risk Factors',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Select any conditions that apply to you. This helps GyroStep calibrate its fall detection sensitivity.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textMedium),
                ),
                const SizedBox(height: 32),

                _buildCheckbox(
                  'Osteoporosis (Fragile Bones)',
                  _hasOsteoporosis,
                  (val) => setState(() => _hasOsteoporosis = val!),
                ),
                _buildCheckbox(
                  'Vertigo / Dizziness',
                  _hasVertigo,
                  (val) => setState(() => _hasVertigo = val!),
                ),
                _buildCheckbox(
                  'Arthritis / Joint Pain',
                  _hasArthritis,
                  (val) => setState(() => _hasArthritis = val!),
                ),
                _buildCheckbox(
                  'Uses a Mobility Aid (Cane, Walker)',
                  _usesMobilityAid,
                  (val) => setState(() => _usesMobilityAid = val!),
                ),
                _buildCheckbox(
                  'History of Previous Falls',
                  _historyOfFalls,
                  (val) => setState(() => _historyOfFalls = val!),
                ),
                _buildCheckbox(
                  'Vision Impairment',
                  _visionImpairment,
                  (val) => setState(() => _visionImpairment = val!),
                ),

                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: _isLoading ? null : _saveAndContinue,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.safeGreen,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Save & Continue',
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
    );
  }

  Widget _buildCheckbox(String title, bool value, Function(bool?) onChanged) {
    return CheckboxListTile(
      title: Text(
        title,
        style: const TextStyle(fontSize: 15, color: AppColors.textDark),
      ),
      value: value,
      onChanged: onChanged,
      activeColor: AppColors.primary,
      controlAffinity: ListTileControlAffinity.leading,
      contentPadding: EdgeInsets.zero,
    );
  }
}
