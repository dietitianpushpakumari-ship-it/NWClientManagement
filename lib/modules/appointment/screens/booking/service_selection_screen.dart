import 'package:flutter/material.dart';
import '../../models/appointment_models.dart';
import 'calendar_slot_screen.dart';

class ServiceSelectionScreen extends StatelessWidget {
   ServiceSelectionScreen({super.key});

  // Mock Config - In real app, fetch from DB
  final List<ServiceType> services = [
    ServiceType(id: '1', name: 'Quick Check-in', durationMins: 15, creditCost: 1),
    ServiceType(id: '2', name: 'Standard Consult', durationMins: 30, creditCost: 1),
    ServiceType(id: '3', name: 'Detailed Assessment', durationMins: 60, creditCost: 2),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Select Service")),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: services.length,
        itemBuilder: (ctx, i) {
          final s = services[i];
          return Card(
            child: ListTile(
              leading: CircleAvatar(child: Text("${s.durationMins}")),
              title: Text(s.name, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text("${s.durationMins} mins • ${s.creditCost} Credit(s)"),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => CalendarSlotScreen(service: s))
                );
              },
            ),
          );
        },
      ),
    );
  }
}