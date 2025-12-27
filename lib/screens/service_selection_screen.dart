import 'package:flutter/material.dart';
import 'package:nutricare_client_management/config/nutricare_services.dart';
import 'package:nutricare_client_management/modules/appointment/screens/booking/calendar_slot_screen.dart'; // Import Module Screen

class ServiceSelectionScreen extends StatelessWidget {
  const ServiceSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Select Service")),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: NutricareServices.all.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final service = NutricareServices.all[index];

          return Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () {
                // 🚀 NAVIGATE TO MODULE
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CalendarSlotScreen(service: service),
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    // Icon Box
                    Container(
                      width: 50, height: 50,
                      decoration: BoxDecoration(
                        color: Colors.indigo.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          "${service.durationMins}",
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo, fontSize: 18),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(service.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          const SizedBox(height: 4),
                          Text("Duration: ${service.durationMins} mins • Cost: ${service.creditCost} Credit(s)", style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}