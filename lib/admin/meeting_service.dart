import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart'; // For TimeOfDay
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:logger/logger.dart';
import 'package:nutricare_client_management/admin/appointment_model.dart';
import 'package:nutricare_client_management/admin/schedule_meeting_utils.dart';

import 'database_provider.dart';

final Logger _logger = Logger();

class MeetingService {

  final Ref _ref; // Store Ref to access dynamic providers

  MeetingService(this._ref);
  FirebaseFirestore get _firestore => _ref.read(firestoreProvider);

  final String _scheduleCollection = 'schedules';
  final String _appointmentsCollection = 'appointments';
  final String _locksCollection = 'availability_locks';
  final String _configCollection = 'configurations';
  final String _meetingsCollectionName = 'client_meetings';

  CollectionReference<Map<String, dynamic>> get _meetingsCollection =>
      _firestore.collection(_meetingsCollectionName);

  // 💰 Pricing Configuration
  static const Map<int, double> sessionPrices = {
    15: 299.0,
    30: 499.0,
    60: 899.0,
  };

  // ===========================================================================
  // 📅 1. SCHEDULE MANAGEMENT
  // ===========================================================================

  Future<void> generateDaySchedule({
    required String coachId,
    required DateTime date,
    required TimeOfDay start,
    required TimeOfDay end,
  }) async {
    if (coachId.isEmpty) throw Exception("Cannot generate schedule: Coach ID is missing.");

    final DateTime normalizedDate = DateTime(date.year, date.month, date.day);
    final String docId = "${DateFormat('yyyy-MM-dd').format(normalizedDate)}_$coachId";
    final docRef = _firestore.collection(_scheduleCollection).doc(docId);

    // 🎯 FIX: Use Transaction to ensure atomic read-check-write
    await _firestore.runTransaction((transaction) async {
      final docSnap = await transaction.get(docRef);

      List<AppointmentSlot> existingSlots = [];

      // 1. Load Existing Slots (if any)
      if (docSnap.exists) {
        final schedule = DailyScheduleModel.fromFirestore(docSnap);
        existingSlots = List.from(schedule.slots);
      }

      // 2. Generate Requested Slots
      List<AppointmentSlot> newSlots = [];
      DateTime current = DateTime(normalizedDate.year, normalizedDate.month, normalizedDate.day, start.hour, start.minute);
      DateTime endTime = DateTime(normalizedDate.year, normalizedDate.month, normalizedDate.day, end.hour, end.minute);

      // Validate Time Range
      if (current.isAfter(endTime) || current.isAtSameMomentAs(endTime)) {
        throw Exception("Start time must be before End time.");
      }

      while (current.isBefore(endTime)) {
        final slotEnd = current.add(const Duration(minutes: 15));

        // 🎯 FIX: Overlap Validation
        // Check if this specific 15-min block already exists
        final isOverlapping = existingSlots.any((s) =>
        s.startTime.isAtSameMomentAs(current) &&
            s.status != SlotStatus.available // Optional: strictly prevent double booking active slots
        );

        // Or strictly prevent ANY duplicate time block:
        final isDuplicate = existingSlots.any((s) => s.startTime.isAtSameMomentAs(current));

        if (isDuplicate) {
          throw Exception("Time slot ${DateFormat('HH:mm').format(current)} overlaps with an existing slot.");
        }

        newSlots.add(AppointmentSlot(
            id: DateFormat('HH:mm').format(current), // Simple ID based on time
            startTime: current,
            endTime: slotEnd,
            status: SlotStatus.available,
            coachId: coachId
        ));
        current = slotEnd;
      }

      // 3. Merge & Sort
      existingSlots.addAll(newSlots);
      existingSlots.sort((a, b) => a.startTime.compareTo(b.startTime));

      // 4. Save
      final schedule = DailyScheduleModel(
        docId: docId,
        coachId: coachId,
        date: normalizedDate,
        slots: existingSlots,
        hasAvailableSlots: existingSlots.any((s) => s.status == SlotStatus.available),
      );

      transaction.set(docRef, schedule.toMap());
    });
  }
  Stream<List<AppointmentSlot>> streamMasterSchedule(DateTime date, List<String> activeCoachIds) {
    final DateTime queryDate = DateTime(date.year, date.month, date.day);

    return _firestore.collection(_scheduleCollection)
        .where('date', isEqualTo: Timestamp.fromDate(queryDate))
        .snapshots()
        .map((snapshot) {
      List<AppointmentSlot> allSlots = [];
      for (var doc in snapshot.docs) {
        final schedule = DailyScheduleModel.fromFirestore(doc);
        if (activeCoachIds.contains(schedule.coachId)) {
          allSlots.addAll(schedule.slots.map((s) => s.copyWith(coachId: schedule.coachId)));
        }
      }
      allSlots.sort((a, b) => a.startTime.compareTo(b.startTime));
      return allSlots;
    });
  }

  Future<void> deleteSlot({required String coachId, required DateTime date, required String slotId}) async {
    final DateTime normalizedDate = DateTime(date.year, date.month, date.day);
    final String docId = "${DateFormat('yyyy-MM-dd').format(normalizedDate)}_$coachId";
    final docRef = _firestore.collection(_scheduleCollection).doc(docId);

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(docRef);
      if (!snapshot.exists) return;

      final schedule = DailyScheduleModel.fromFirestore(snapshot);
      List<AppointmentSlot> updatedSlots = List.from(schedule.slots);
      updatedSlots.removeWhere((s) => s.id == slotId);

      transaction.update(docRef, {
        'slots': updatedSlots.map((e) => e.toJson()).toList(),
        'hasAvailableSlots': updatedSlots.any((s) => s.status == SlotStatus.available),
      });
    });
  }

  Future<void> toggleSlotLock(String coachId, DateTime date, String slotId, bool isLocked) async {
    final DateTime normalizedDate = DateTime(date.year, date.month, date.day);
    final String docId = "${DateFormat('yyyy-MM-dd').format(normalizedDate)}_$coachId";
    final docRef = _firestore.collection(_scheduleCollection).doc(docId);

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(docRef);
      if (!snapshot.exists) return;

      final schedule = DailyScheduleModel.fromFirestore(snapshot);
      final slots = schedule.slots;
      final index = slots.indexWhere((s) => s.id == slotId);

      if (index != -1) {
        if (slots[index].status == SlotStatus.booked || slots[index].status == SlotStatus.pending_payment) {
          throw Exception("Cannot block a booked slot.");
        }

        slots[index] = slots[index].copyWith(
          status: isLocked ? SlotStatus.locked : SlotStatus.available,
          guestName: isLocked ? "Blocked" : null,
        );

        transaction.update(docRef, {
          'slots': slots.map((e) => e.toJson()).toList(),
          'hasAvailableSlots': slots.any((s) => s.status == SlotStatus.available),
        });
      }
    });
  }

  // ===========================================================================
  // 📝 2. APPOINTMENT BOOKING
  // ===========================================================================

  Future<String> bookSession({
    required String? clientId,
    required String clientName,
    String? guestPhone,
    required String coachId,
    required DateTime startTime,
    required int durationMinutes,
    required String topic,
    required bool useFreeSession,
    AppointmentType type = AppointmentType.online,
    String? paymentRef,

    // 🎯 NEW: Audit Fields
    required String performedByUid,
    required String performedByName,

    bool isAdminBooking = false,
  }) async {
    if (coachId.isEmpty) throw Exception("Booking Error: Coach ID is missing.");

    // 🎯 ID VALIDATION & GENERATION
    // Ensure we have a valid ID string for the document ID construction
    String effectiveClientId;
    if (clientId != null && clientId.isNotEmpty) {
      effectiveClientId = clientId;
    } else {
      // Generate fallback guest ID if not provided
      // Safe cleaning of phone number or use timestamp fallback
      String phonePart = (guestPhone?.replaceAll(RegExp(r'[^0-9]'), '') ?? '');
      if (phonePart.isEmpty) phonePart = DateTime.now().millisecondsSinceEpoch.toString();
      effectiveClientId = "guest_$phonePart";
    }

    final DateTime date = DateTime(startTime.year, startTime.month, startTime.day);
    final String scheduleDocId = "${DateFormat('yyyy-MM-dd').format(date)}_$coachId";
    final docRef = _firestore.collection(_scheduleCollection).doc(scheduleDocId);

    double cost = 0.0;
    if (!useFreeSession) {
      final prices = await getSessionPricing();
      cost = (prices[durationMinutes.toString()] ?? (durationMinutes == 60 ? 899.0 : (durationMinutes == 30 ? 499.0 : 299.0))).toDouble();
    }

    List<DateTime> blockStartTimes = [];
    DateTime current = startTime;
    int blocks = (durationMinutes / 15).ceil();

    for(int i=0; i<blocks; i++) {
      blockStartTimes.add(current);
      current = current.add(const Duration(minutes: 15));
    }

    return await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(docRef);
      if (!snapshot.exists) throw Exception("Schedule not found for this day ($date).");

      final schedule = DailyScheduleModel.fromFirestore(snapshot);
      List<AppointmentSlot> updatedSlots = List.from(schedule.slots);
      bool modified = false;

      // 🎯 STATUS LOGIC
      SlotStatus targetSlotStatus;
      AppointmentStatus targetApptStatus;

      if (useFreeSession) {
        targetSlotStatus = SlotStatus.booked;
        targetApptStatus = AppointmentStatus.confirmed;
      } else if (paymentRef != null) {
        targetSlotStatus = SlotStatus.booked;
        targetApptStatus = AppointmentStatus.verification_pending;
      } else {
        // Default: Pending Payment (Even for Admins, requires confirmation step)
        targetSlotStatus = SlotStatus.pending_payment;
        targetApptStatus = AppointmentStatus.payment_pending;
      }

      // Mark slots
      for (var time in blockStartTimes) {
        final index = updatedSlots.indexWhere((s) => s.startTime.isAtSameMomentAs(time));

        if (index == -1) throw Exception("Slot at ${DateFormat.jm().format(time)} not found.");
        if (updatedSlots[index].status != SlotStatus.available) throw Exception("Slot at ${DateFormat.jm().format(time)} is already taken.");

        updatedSlots[index] = updatedSlots[index].copyWith(
          status: targetSlotStatus,
          clientId: effectiveClientId,
          guestName: clientName,
        );
        modified = true;
      }

      if (!modified) throw Exception("No slots updated.");

      // 1. Update Schedule Grid
      transaction.update(docRef, {
        'slots': updatedSlots.map((e) => e.toJson()).toList(),
        'hasAvailableSlots': updatedSlots.any((s) => s.status == SlotStatus.available),
      });

      // 2. Decrement Free Session
      if (useFreeSession && clientId != null) {
        final clientRef = _firestore.collection('clients').doc(clientId);
        transaction.update(clientRef, {'freeSessionsRemaining': FieldValue.increment(-1)});
      }

      // 3. Create Appointment Doc
      // 🎯 FIX: Explicit Document ID Construction
      final String apptDocId = "appt_${DateTime.now().millisecondsSinceEpoch}_${coachId}_$effectiveClientId";
      final apptRef = _firestore.collection(_appointmentsCollection).doc(apptDocId);

      transaction.set(apptRef, {
        'clientId': effectiveClientId,
        'clientName': clientName,
        'guestPhone': guestPhone,
        'coachId': coachId,
        'startTime': Timestamp.fromDate(startTime),
        'endTime': Timestamp.fromDate(startTime.add(Duration(minutes: durationMinutes))),
        'topic': topic,
        'status': targetApptStatus.name,
        'amount': cost,
        'paymentRef': paymentRef,
        'isFreeSession': useFreeSession,
        'type': type.name,
        'createdAt': FieldValue.serverTimestamp(),

        // 🎯 Audit Trail: Who created this?
        'createdByUid': performedByUid,
        'createdByName': performedByName,
      });

      return apptDocId;
    });
  }

  Future<void> confirmBooking(String coachId, DateTime date, List<String> slotIds, String appointmentId) async {
    final DateTime normalizedDate = DateTime(date.year, date.month, date.day);
    final String docId = "${DateFormat('yyyy-MM-dd').format(normalizedDate)}_$coachId";
    final docRef = _firestore.collection(_scheduleCollection).doc(docId);

    // If appointmentId is just placeholder, we rely on slot updates.
    // Ideally appointmentId should be passed correctly.
    final apptRef = _firestore.collection(_appointmentsCollection).doc(appointmentId);

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(docRef);
      if (!snapshot.exists) return;

      final schedule = DailyScheduleModel.fromFirestore(snapshot);
      List<AppointmentSlot> updatedSlots = List.from(schedule.slots);

      for (var slotId in slotIds) {
        final index = updatedSlots.indexWhere((s) => s.id == slotId);
        if (index != -1) {
          updatedSlots[index] = updatedSlots[index].copyWith(status: SlotStatus.booked);
        }
      }

      transaction.update(docRef, {
        'slots': updatedSlots.map((e) => e.toJson()).toList(),
      });

      try {
        // Only attempt update if it looks like a valid ID (not placeholder)
        if(appointmentId != "placeholder_id") {
          transaction.update(apptRef, {
            'status': AppointmentStatus.confirmed.name,
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
      } catch (_) {}
    });
  }

  Future<void> updateAppointmentNote(String id, String note) async {
    await _firestore.collection(_appointmentsCollection).doc(id).update({
      'adminNote': note,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<Map<String, int>> getSessionPricing() async {
    try {
      final doc = await _firestore.collection(_configCollection).doc('session_pricing').get();
      if (doc.exists && doc.data() != null) return Map<String, int>.from(doc.data()!);
    } catch (_) {}
    return {'15': 299, '30': 499, '60': 899};
  }

  Stream<List<AppointmentSlot>> streamAvailableSlots({String? coachId}) {
    return const Stream.empty();
  }

  Future<List<MeetingModel>> getClientMeetings(String clientId) async {
    try {
      final snap = await _firestore.collection(_appointmentsCollection)
          .where('clientId', isEqualTo: clientId)
          .orderBy('startTime', descending: true)
          .get();

      return snap.docs.map((doc) {
        final d = doc.data();
        return MeetingModel(
            id: doc.id,
            clientId: d['clientId'] ?? '',
            startTime: (d['startTime'] as Timestamp).toDate(),
            meetingType: d['type'] ?? 'Video Call',
            purpose: d['topic'] ?? 'Consultation',
            status: stringToMeetingStatus(d['status'] ?? 'scheduled'),
            clinicalNotes: d['adminNote'],
            createdAt: d['createdAt'] ?? Timestamp.now(),
            updatedAt: d['createdAt'] ?? Timestamp.now()
        );
      }).toList();
    } catch (e) { return []; }
  }
  Future<void> scheduleMeeting({
    required String clientId,
    required DateTime startTime,
    required String meetingType,
    required String purpose,
    String? meetLink,
    String? clinicalNotes
  }) async {
    // 1. Get Current User (Coach)
    final user = FirebaseAuth.instance.currentUser;
    final String coachId = user?.uid ?? 'system_admin';
    final String adminName = user?.displayName ?? user?.email ?? 'Admin';

    // 2. Fetch Client Name (Optional, for display in slot)
    String clientName = 'Client';
    try {
      final clientDoc = await _firestore.collection('clients').doc(clientId).get();
      if (clientDoc.exists) {
        clientName = clientDoc.data()?['name'] ?? 'Client';
      }
    } catch (_) {}

    // 3. Call Booking Logic
    final apptId = await bookSession(
      clientId: clientId,
      clientName: clientName,
      coachId: coachId,
      startTime: startTime,
      durationMinutes: 30, // Default duration for manual schedule tab
      topic: purpose,
      useFreeSession: false,
      isAdminBooking: true,
      performedByUid: coachId,
      performedByName: adminName,
    );

    // 4. Update Extra Fields (Meet Link, etc.)
    if (meetLink != null || clinicalNotes != null) {
      await _firestore.collection(_appointmentsCollection).doc(apptId).update({
        if (meetLink != null) 'meetLink': meetLink,
        if (clinicalNotes != null) 'adminNote': clinicalNotes,
      });
    }
  }

  // ... inside MeetingService class ...

  // 🎯 NEW: Delete Free Slots (Range or Full Day)
  Future<void> deleteFreeSlots({
    required String coachId,
    required DateTime date,
    TimeOfDay? startTime,
    TimeOfDay? endTime,
  }) async {
    final DateTime normalizedDate = DateTime(date.year, date.month, date.day);
    final String docId = "${DateFormat('yyyy-MM-dd').format(normalizedDate)}_$coachId";
    final docRef = _firestore.collection(_scheduleCollection).doc(docId);

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(docRef);
      if (!snapshot.exists) return;

      final schedule = DailyScheduleModel.fromFirestore(snapshot);
      List<AppointmentSlot> updatedSlots = List.from(schedule.slots);

      // Define the removal condition
      bool shouldDelete(AppointmentSlot slot) {
        // 1. SAFETY CHECK: Only delete 'available' slots
        if (slot.status != SlotStatus.available) return false;

        // 2. If a specific range is provided, check times
        if (startTime != null && endTime != null) {
          final slotStart = TimeOfDay.fromDateTime(slot.startTime);

          // Convert to minutes for accurate comparison
          final int startMin = startTime.hour * 60 + startTime.minute;
          final int endMin = endTime.hour * 60 + endTime.minute;
          final int slotStartMin = slotStart.hour * 60 + slotStart.minute;

          // Delete if the slot starts within the range [Start, End)
          return slotStartMin >= startMin && slotStartMin < endMin;
        }

        // 3. If no range is provided, delete ALL free slots for the day
        return true;
      }

      // Perform removal
      updatedSlots.removeWhere(shouldDelete);

      transaction.update(docRef, {
        'slots': updatedSlots.map((e) => e.toJson()).toList(),
        'hasAvailableSlots': updatedSlots.any((s) => s.status == SlotStatus.available),
      });
    });
  }
// ... inside MeetingService class ...

  // 🎯 NEW: Reassign Appointment to a different Coach
  Future<void> reassignSession({
    required String oldCoachId,
    required String newCoachId,
    required DateTime date,
    required DateTime startTime,
    required DateTime endTime, // Used to find all slots in the block
  }) async {
    if (oldCoachId == newCoachId) return; // No change needed

    final DateTime normalizedDate = DateTime(date.year, date.month, date.day);
    final String oldDocId = "${DateFormat('yyyy-MM-dd').format(normalizedDate)}_$oldCoachId";
    final String newDocId = "${DateFormat('yyyy-MM-dd').format(normalizedDate)}_$newCoachId";

    final oldScheduleRef = _firestore.collection(_scheduleCollection).doc(oldDocId);
    final newScheduleRef = _firestore.collection(_scheduleCollection).doc(newDocId);

    // Find the appointment document to update
    final apptQuery = await _firestore.collection(_appointmentsCollection)
        .where('coachId', isEqualTo: oldCoachId)
        .where('startTime', isEqualTo: Timestamp.fromDate(startTime))
        .limit(1)
        .get();

    if (apptQuery.docs.isEmpty) {
      throw Exception("Appointment record not found for reassignment.");
    }
    final apptDocRef = apptQuery.docs.first.reference;

    await _firestore.runTransaction((transaction) async {
      final oldSnap = await transaction.get(oldScheduleRef);
      final newSnap = await transaction.get(newScheduleRef);

      if (!oldSnap.exists) throw Exception("Source schedule not found.");

      // If new coach schedule doesn't exist, we can't move it (simplification)
      // Ideally, you'd generate it, but for now, require it to exist.
      if (!newSnap.exists) throw Exception("Target coach has no schedule generated for this day.");

      final oldSchedule = DailyScheduleModel.fromFirestore(oldSnap);
      final newSchedule = DailyScheduleModel.fromFirestore(newSnap);

      List<AppointmentSlot> oldSlots = List.from(oldSchedule.slots);
      List<AppointmentSlot> newSlots = List.from(newSchedule.slots);

      // Identify the slots to move based on Start Time matching
      // We look for the specific start time of the block
      // Note: A block might cover multiple 15-min slots. We need to move ALL of them.
      // We'll filter slots that fall within [startTime, endTime)

      final slotsToMove = oldSlots.where((s) =>
      (s.startTime.isAtSameMomentAs(startTime) || s.startTime.isAfter(startTime)) &&
          s.startTime.isBefore(endTime)
      ).toList();

      if (slotsToMove.isEmpty) throw Exception("No slots found to move.");

      // Grab guest details from the first slot
      final String? guestName = slotsToMove.first.bookedByGuestName;
      final String? clientId = slotsToMove.first.bookedByClientId;
      final SlotStatus status = slotsToMove.first.status;

      for (var sourceSlot in slotsToMove) {
        // 1. Clear Old Coach Slot
        final oldIndex = oldSlots.indexWhere((s) => s.id == sourceSlot.id);
        if (oldIndex != -1) {
          oldSlots[oldIndex] = oldSlots[oldIndex].copyWith(
              status: SlotStatus.available,
              guestName: null,
              clientId: null
          );
        }

        // 2. Book New Coach Slot
        final newIndex = newSlots.indexWhere((s) => s.startTime.isAtSameMomentAs(sourceSlot.startTime));
        if (newIndex == -1) {
          throw Exception("Target coach does not have a slot at ${DateFormat.jm().format(sourceSlot.startTime)}.");
        }
        if (newSlots[newIndex].status != SlotStatus.available) {
          throw Exception("Target coach is already booked at ${DateFormat.jm().format(sourceSlot.startTime)}.");
        }

        newSlots[newIndex] = newSlots[newIndex].copyWith(
          status: status, // Preserve status (booked/pending)
          guestName: guestName,
          clientId: clientId,
          coachId: newCoachId,
        );
      }

      // 3. Commit Updates
      transaction.update(oldScheduleRef, {
        'slots': oldSlots.map((e) => e.toJson()).toList(),
      });

      transaction.update(newScheduleRef, {
        'slots': newSlots.map((e) => e.toJson()).toList(),
      });

      // 4. Update Appointment Document
      transaction.update(apptDocRef, {
        'coachId': newCoachId,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }
  Future<void> updateAppointmentStatus(String appointmentId, AppointmentStatus status) async {
    await _firestore.collection(_appointmentsCollection).doc(appointmentId).update({
      'status': status.name,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
  // ... inside MeetingService class ...

  // 🎯 SAFE RESCHEDULE (Transactional Move)
  Future<void> rescheduleSession({
    required String coachId,
    required DateTime oldStartTime,
    required DateTime newStartTime,
    required int durationMinutes,
  }) async {
    // 1. Prepare Document IDs
    final DateTime oldDate = DateTime(oldStartTime.year, oldStartTime.month, oldStartTime.day);
    final DateTime newDate = DateTime(newStartTime.year, newStartTime.month, newStartTime.day);

    final String oldDocId = "${DateFormat('yyyy-MM-dd').format(oldDate)}_$coachId";
    final String newDocId = "${DateFormat('yyyy-MM-dd').format(newDate)}_$coachId";

    final oldScheduleRef = _firestore.collection(_scheduleCollection).doc(oldDocId);
    final newScheduleRef = _firestore.collection(_scheduleCollection).doc(newDocId);

    // 2. Find the Appointment Document (Pre-Transaction)
    // We match by Coach + StartTime to ensure we get the right booking
    final apptQuery = await _firestore.collection(_appointmentsCollection)
        .where('coachId', isEqualTo: coachId)
        .where('startTime', isEqualTo: Timestamp.fromDate(oldStartTime))
        .limit(1)
        .get();

    if (apptQuery.docs.isEmpty) {
      throw Exception("Original appointment record not found. Cannot reschedule.");
    }
    final apptDocRef = apptQuery.docs.first.reference;

    // 3. RUN TRANSACTION
    await _firestore.runTransaction((transaction) async {
      final oldSnap = await transaction.get(oldScheduleRef);
      // Ensure target schedule exists (You might need a check to auto-create,
      // but for safety we usually require the schedule to be generated first)
      final newSnap = await transaction.get(newScheduleRef);

      if (!oldSnap.exists) throw Exception("Source schedule data missing.");
      if (!newSnap.exists) throw Exception("Target day schedule not generated yet. Please generate slots for the target day first.");

      final oldSchedule = DailyScheduleModel.fromFirestore(oldSnap);
      final newSchedule = DailyScheduleModel.fromFirestore(newSnap);

      List<AppointmentSlot> oldSlots = List.from(oldSchedule.slots);
      List<AppointmentSlot> newSlots = List.from(newSchedule.slots);

      // --- A. VALIDATE NEW SLOTS ---
      // We need to check if enough consecutive slots are available at newStartTime
      DateTime checkTime = newStartTime;
      final int slotsNeeded = (durationMinutes / 15).ceil();
      final List<int> newSlotIndices = [];

      for (int i = 0; i < slotsNeeded; i++) {
        final index = newSlots.indexWhere((s) => s.startTime.isAtSameMomentAs(checkTime));

        if (index == -1) throw Exception("Target time ${DateFormat.jm().format(checkTime)} does not exist in schedule.");
        if (newSlots[index].status != SlotStatus.available) throw Exception("Target slot ${DateFormat.jm().format(checkTime)} is already booked.");

        newSlotIndices.add(index);
        checkTime = checkTime.add(const Duration(minutes: 15));
      }

      // --- B. PREPARE DATA TO MOVE ---
      // Find the old slots to clear
      final DateTime oldEndTime = oldStartTime.add(Duration(minutes: durationMinutes));
      final slotsToClear = oldSlots.where((s) =>
      (s.startTime.isAtSameMomentAs(oldStartTime) || s.startTime.isAfter(oldStartTime)) &&
          s.startTime.isBefore(oldEndTime)
      ).toList();

      if (slotsToClear.isEmpty) throw Exception("Original slots not found in schedule grid.");

      // Grab Booking Info (Client Name, ID, Status) from the first slot
      final infoSlot = slotsToClear.first;
      final String? clientId = infoSlot.bookedByClientId;
      final String? guestName = infoSlot.bookedByGuestName;
      final SlotStatus status = infoSlot.status;

      // --- C. EXECUTE SWAP ---

      // 1. Clear Old Slots
      for (var slot in slotsToClear) {
        final idx = oldSlots.indexWhere((s) => s.id == slot.id);
        if (idx != -1) {
          oldSlots[idx] = oldSlots[idx].copyWith(
              status: SlotStatus.available,
              clientId: null,
              guestName: null
          );
        }
      }

      // 2. Book New Slots
      for (var idx in newSlotIndices) {
        newSlots[idx] = newSlots[idx].copyWith(
            status: status, // Preserve original status (e.g. booked vs pending)
            clientId: clientId,
            guestName: guestName
        );
      }

      // --- D. COMMIT UPDATES ---

      // Update Schedule Docs
      transaction.update(oldScheduleRef, {
        'slots': oldSlots.map((e) => e.toJson()).toList(),
        'hasAvailableSlots': oldSlots.any((s) => s.status == SlotStatus.available),
      });

      // If moving within same day, reuse the modified list
      if (oldDocId == newDocId) {
        // Logic handled by List reference modification above if doc is same?
        // No, simpler to just write 'newSlots' if docIds match, but
        // logic differs slightly. For safety in Firestore transactions,
        // we should just write to the references.
        // IF SAME DOC: oldSlots and newSlots were derived from same snapshot.
        // Since we modified lists independently, we must be careful.
        // Let's handle same-day logic specifically to avoid overwriting.
      } else {
        transaction.update(newScheduleRef, {
          'slots': newSlots.map((e) => e.toJson()).toList(),
          'hasAvailableSlots': newSlots.any((s) => s.status == SlotStatus.available),
        });
      }

      // *Correction for Same Day Move*:
      if (oldDocId == newDocId) {
        // Re-merge changes if it's the same day
        // We cleared indices in 'oldSlots'. We booked indices in 'newSlots'.
        // Actually, if doc is same, oldSlots == newSlots (data-wise) but different list instances.
        // Best way: Apply BOTH changes to one list.

        final combinedSlots = List<AppointmentSlot>.from(oldSchedule.slots);

        // Apply Clears
        for (var slot in slotsToClear) {
          final idx = combinedSlots.indexWhere((s) => s.id == slot.id);
          if(idx!=-1) combinedSlots[idx] = combinedSlots[idx].copyWith(status: SlotStatus.available, clientId: null, guestName: null);
        }
        // Apply Books
        for (int i = 0; i < slotsNeeded; i++) {
          // Recalculate time/index because we are reusing source list
          DateTime t = newStartTime.add(Duration(minutes: 15 * i));
          final idx = combinedSlots.indexWhere((s) => s.startTime.isAtSameMomentAs(t));
          if(idx!=-1) combinedSlots[idx] = combinedSlots[idx].copyWith(status: status, clientId: clientId, guestName: guestName);
        }

        transaction.update(oldScheduleRef, {
          'slots': combinedSlots.map((e) => e.toJson()).toList(),
        });
      }

      // Update Appointment Doc
      transaction.update(apptDocRef, {
        'startTime': Timestamp.fromDate(newStartTime),
        'endTime': Timestamp.fromDate(newStartTime.add(Duration(minutes: durationMinutes))),
        'updatedAt': FieldValue.serverTimestamp(),
        // Status remains 'confirmed' or 'pending' - we don't cancel it!
      });
    });
  }

  // 🎯 NEW: Stream for Dashboard Reminders (Next 24 Hours)
  Stream<List<AppointmentModel>> streamUpcomingReminders(String coachId) {
    final now = DateTime.now();
    final next24h = now.add(const Duration(hours: 24));

    return _firestore.collection(_appointmentsCollection)
        .where('coachId', isEqualTo: coachId)
        .where('status', isEqualTo: AppointmentStatus.confirmed.name)
        .where('startTime', isGreaterThan: Timestamp.fromDate(now))
        .where('startTime', isLessThan: Timestamp.fromDate(next24h))
        .orderBy('startTime') // Ascending (Next one first)
        .limit(10)
        .snapshots()
        .map((snap) => snap.docs.map((d) => AppointmentModel.fromFirestore(d)).toList());
  }

  // ... inside MeetingService class ...

  // 🎯 NEW: Stream for Nudge Bar (Merges Upcoming & Recent Pending/Overdue)
  // Fetches everything from 3 days ago to 7 days in future to catch overdue & upcoming
  Stream<List<AppointmentModel>> streamNudgeAppointments(String coachId) {
    final start = DateTime.now().subtract(const Duration(days: 3)); // Catch recent overdue
    final end = DateTime.now().add(const Duration(days: 7));       // Look ahead 1 week

    return _firestore.collection(_appointmentsCollection)
        .where('coachId', isEqualTo: coachId)
        .where('startTime', isGreaterThan: Timestamp.fromDate(start))
        .where('startTime', isLessThan: Timestamp.fromDate(end))
    // Note: We filter status in Dart because Firestore 'whereIn' combined with range filter is limited
        .snapshots()
        .map((snap) {
      final list = snap.docs.map((d) => AppointmentModel.fromFirestore(d)).toList();
      // Filter out Cancelled/Completed locally
      return list.where((a) =>
      a.status != AppointmentStatus.cancelled &&
          a.status != AppointmentStatus.completed
      ).toList();
    });
  }
}
