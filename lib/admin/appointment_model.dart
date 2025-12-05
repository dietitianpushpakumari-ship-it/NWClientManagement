import 'package:cloud_firestore/cloud_firestore.dart';

enum AppointmentStatus { scheduled, pending, confirmed, cancelled, completed, payment_pending, verification_pending }
enum SlotStatus { available, booked, locked, pending_payment }
enum AppointmentType { online, physical }

// 1. AppointmentModel (Booking)
class AppointmentModel {
  final String id;
  final String? clientId;
  final String clientName;
  final String? guestPhone;
  final String coachId;
  final DateTime startTime;
  final DateTime endTime;
  final String topic;
  final AppointmentStatus status;
  final AppointmentType type;
  final String? paymentReferenceId;
  final double? amountPaid;
  final String? adminNote;
  final DateTime? paymentDate; // 🎯 NEW
  final String? paymentMethod; // 🎯 NEW (e.g., UPI, Cash)

  // 📸 Media & Links
  final List<String> sessionPhotos; // 🎯 NEW
  final String? meetLink;

  AppointmentModel({
    required this.id,
    this.clientId,
    required this.clientName,
    this.guestPhone,
    required this.coachId,
    required this.startTime,
    required this.endTime,
    required this.topic,
    this.status = AppointmentStatus.scheduled,
    this.type = AppointmentType.online,
    this.paymentReferenceId,
    this.amountPaid,
    this.adminNote,
    this.meetLink,
    this.paymentDate,
    this.paymentMethod,
    this.sessionPhotos = const [],
  });

  factory AppointmentModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AppointmentModel(
      id: doc.id,
      clientId: data['clientId'],
      clientName: data['clientName'] ?? 'Unknown',
      guestPhone: data['guestPhone'],
      coachId: data['coachId'] ?? '',
      startTime: (data['startTime'] as Timestamp).toDate(),
      endTime: (data['endTime'] as Timestamp).toDate(),
      topic: data['topic'] ?? '',
      status: AppointmentStatus.values.firstWhere((e) => e.name == (data['status'] ?? 'scheduled'), orElse: () => AppointmentStatus.scheduled),
      type: AppointmentType.values.firstWhere((e) => e.name == (data['type'] ?? 'online'), orElse: () => AppointmentType.online),
      paymentReferenceId: data['paymentRef'],
      amountPaid: (data['amount'] as num?)?.toDouble(),
      adminNote: data['adminNote'],
      paymentDate: (data['paymentDate'] as Timestamp?)?.toDate(),
      paymentMethod: data['paymentMethod'],

      sessionPhotos: List<String>.from(data['sessionPhotos'] ?? []),
      meetLink: data['meetLink'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'clientId': clientId,
      'clientName': clientName,
      'guestPhone': guestPhone,
      'coachId': coachId,
      'startTime': Timestamp.fromDate(startTime),
      'endTime': Timestamp.fromDate(endTime),
      'topic': topic,
      'status': status.name,
      'type': type.name,
      'paymentRef': paymentReferenceId,
      'amount': amountPaid,
      'adminNote': adminNote,
      'createdAt': FieldValue.serverTimestamp(),
      'paymentDate': paymentDate != null ? Timestamp.fromDate(paymentDate!) : null,
      'paymentMethod': paymentMethod,

      'sessionPhotos': sessionPhotos,
      'meetLink': meetLink,
    };
  }
}

// 2. AppointmentSlot (Availability)
class AppointmentSlot {
  final String id;
  final DateTime startTime;
  final DateTime endTime;
  final SlotStatus status;
  final String? bookedByClientId;
  final String? bookedByGuestName;

  // 🎯 NEW: Helper field to track which coach owns this slot
  final String? coachId;

  AppointmentSlot({
    required this.id,
    required this.startTime,
    required this.endTime,
    this.status = SlotStatus.available,
    this.bookedByClientId,
    this.bookedByGuestName,
    this.coachId, // 🎯 Added
  });

  factory AppointmentSlot.fromJson(Map<String, dynamic> json) {
    return AppointmentSlot(
      id: json['id'],
      startTime: (json['startTime'] as Timestamp).toDate(),
      endTime: (json['endTime'] as Timestamp).toDate(),
      status: SlotStatus.values.firstWhere((e) => e.name == (json['status'] ?? 'available')),
      bookedByClientId: json['bookedByClientId'],
      bookedByGuestName: json['bookedByGuestName'],
      coachId: json['coachId'], // Load if saved
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'startTime': Timestamp.fromDate(startTime),
      'endTime': Timestamp.fromDate(endTime),
      'status': status.name,
      'bookedByClientId': bookedByClientId,
      'bookedByGuestName': bookedByGuestName,
      'coachId': coachId, // Save it
    };
  }

  AppointmentSlot copyWith({SlotStatus? status, String? clientId, String? guestName, String? coachId}) {
    return AppointmentSlot(
      id: id, startTime: startTime, endTime: endTime,
      status: status ?? this.status,
      bookedByClientId: clientId ?? bookedByClientId,
      bookedByGuestName: guestName ?? bookedByGuestName,
      coachId: coachId ?? this.coachId, // 🎯 Added
    );
  }
}

// 3. DailyScheduleModel (Container)
class DailyScheduleModel {
  final String docId;
  final String coachId;
  final DateTime date;
  final List<AppointmentSlot> slots;
  final bool hasAvailableSlots;

  DailyScheduleModel({
    required this.docId,
    required this.coachId,
    required this.date,
    required this.slots,
    this.hasAvailableSlots = true,
  });

  factory DailyScheduleModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return DailyScheduleModel(
      docId: doc.id,
      coachId: data['coachId'],
      date: (data['date'] as Timestamp).toDate(),
      hasAvailableSlots: data['hasAvailableSlots'] ?? false,
      slots: (data['slots'] as List<dynamic>).map((e) => AppointmentSlot.fromJson(e)).toList(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'coachId': coachId,
      'date': Timestamp.fromDate(date),
      'hasAvailableSlots': slots.any((s) => s.status == SlotStatus.available),
      'slots': slots.map((e) => e.toJson()).toList(),
    };
  }
}