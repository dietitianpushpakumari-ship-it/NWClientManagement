import 'package:flutter/material.dart';

enum AppModule {
  dietPlanning(
    id: 'diet_planning',
    label: 'Diet Planning',
    description: 'Create and assign diet plans to patients.',
    icon: Icons.restaurant_menu,
  ),
  workoutPlanning(
    id: 'workout_planning',
    label: 'Workout Planning',
    description: 'Assign exercise routines and track progress.',
    icon: Icons.fitness_center,
  ),
  labVitals(
    id: 'lab_vitals',
    label: 'Lab & Vitals',
    description: 'Track pathology reports and vital signs.',
    icon: Icons.monitor_heart,
  ),
  appointments(
    id: 'appointments',
    label: 'Appointment Scheduler',
    description: 'Manage booking slots and consultations.',
    icon: Icons.calendar_month,
  ),
  chat(
    id: 'chat',
    label: 'In-App Chat',
    description: 'Real-time messaging between dietitians and clients.',
    icon: Icons.chat_bubble_outline,
  ),
  billing(
    id: 'billing',
    label: 'Billing & Ledger',
    description: 'Manage packages, payments, and invoices.',
    icon: Icons.receipt_long,
  ),
  aiAssistant(
    id: 'ai_assistant',
    label: 'AI Assistant',
    description: 'Enable AI-powered suggestions and translation.',
    icon: Icons.auto_awesome,
  );

  final String id;
  final String label;
  final String description;
  final IconData icon;

  const AppModule({
    required this.id,
    required this.label,
    required this.description,
    required this.icon,
  });

  // Helper to find enum by ID string from Firestore
  static AppModule? fromId(String id) {
    try {
      return AppModule.values.firstWhere((e) => e.id == id);
    } catch (_) {
      return null;
    }
  }
}