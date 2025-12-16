// lib/screens/history_sections.dart

import 'package:flutter/material.dart';

// --- UI Layout Helpers ---

Widget buildCustomHeader(BuildContext context) {
  return Padding(
    padding: EdgeInsets.only(
      top: MediaQuery.of(context).padding.top + 10,
      left: 16,
      right: 16,
      bottom: 16,
    ),
    child: Row(
      children: [
        IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        const SizedBox(width: 10),
        const Text(
          'Medical & Lifestyle History',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1A1A1A)),
        ),
      ],
    ),
  );
}

Widget buildCard({required String title, required IconData icon, required Color color, required Widget child}) {
  return Container(
    margin: const EdgeInsets.only(bottom: 20),
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 10),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        const Divider(height: 25),
        child,
      ],
    ),
  );
}