import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color backgroundColor;
  final Color textColor;
  final VoidCallback onPressed;

  const ActionButton({
    super.key,
    required this.icon,
    required this.label,
    required this.backgroundColor,
    required this.textColor,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onPressed,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
          margin: const EdgeInsets.symmetric(horizontal: 6),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: textColor.withOpacity(0.2), width: 1.5),
          ),
          child: Column(
            children: [
              Icon(icon, color: textColor, size: 20),
              const SizedBox(height: 6),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ActionButtonsRow extends StatelessWidget {
  final VoidCallback onEmergencyCall;
  final VoidCallback onCheckVitals;
  final VoidCallback onNotifyRelatives;

  const ActionButtonsRow({
    super.key,
    required this.onEmergencyCall,
    required this.onCheckVitals,
    required this.onNotifyRelatives,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          ActionButton(
            icon: Icons.phone,
            label: 'Emergency Call',
            backgroundColor: Color(0xFFFFF0F0),
            textColor: AppColors.dangerRed,
            onPressed: onEmergencyCall,
          ),
          ActionButton(
            icon: Icons.favorite,
            label: 'Check Vitals',
            backgroundColor: Color(0xFFF0F7FF),
            textColor: AppColors.primary,
            onPressed: onCheckVitals,
          ),
          ActionButton(
            icon: Icons.people,
            label: 'Notify Relatives',
            backgroundColor: Color(0xFFF8F0FF),
            textColor: Color(0xFF7B1FA2),
            onPressed: onNotifyRelatives,
          ),
        ],
      ),
    );
  }
}
