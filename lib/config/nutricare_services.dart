import 'package:nutricare_client_management/modules/appointment/models/appointment_models.dart';
class NutricareServices {
  static final List<ServiceType> all = [
    ServiceType(
      id: 'consult_15',
      name: 'Quick Check-in',
      durationMins: 15,
      creditCost: 1, // Costs 1 Credit
    ),
    ServiceType(
      id: 'consult_30',
      name: 'Standard Consultation',
      durationMins: 30,
      creditCost: 2, // Costs 2 Credits
    ),
    ServiceType(
      id: 'consult_60',
      name: 'Deep Dive / Initial Assessment',
      durationMins: 60,
      creditCost: 3, // Costs 3 Credits
    ),
  ];
}