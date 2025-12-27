import 'package:flutter/material.dart';

enum AppRole {
  clinicAdmin(
    id: 'clinicAdmin',
    label: 'Clinic Admin',
    description: 'Full access to clinic operations and settings.',
    icon: Icons.admin_panel_settings,
  ),
  dietitian(
    id: 'dietitian',
    label: 'Dietitian / Nutritionist',
    description: 'Manages diet plans, patients, and content.',
    icon: Icons.local_hospital,
  ),
  frontDesk(
    id: 'frontDesk',
    label: 'Front Desk / Reception',
    description: 'Manages appointments, billing, and patient onboarding.',
    icon: Icons.support_agent,
  ),
  nurse(
    id: 'nurse',
    label: 'Nurse / Assistant',
    description: 'Tracks vitals and basic patient logs.',
    icon: Icons.medical_services,
  );

  final String id;
  final String label;
  final String description;
  final IconData icon;

  const AppRole({
    required this.id,
    required this.label,
    required this.description,
    required this.icon,
  });

  // Helper to get from string ID
  static AppRole? fromId(String id) {
    try {
      return AppRole.values.firstWhere((e) => e.id == id);
    } catch (_) {
      return null;
    }
  }
}