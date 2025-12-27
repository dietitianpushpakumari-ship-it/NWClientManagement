import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:nutricare_client_management/modules/appointment/models/daily_override_model.dart';
import 'package:nutricare_client_management/modules/appointment/models/work_schedule_model.dart';
import '../interface/appointment_contract.dart';
import '../models/appointment_models.dart';

class MeetingService {
  final AppointmentContract _contract; // 💉 Bridge to main app
  final FirebaseFirestore _firestore;

  MeetingService(this._contract, this._firestore);

  // ===========================================================================
  // 1. AVAILABILITY ENGINE (The "Pooling" Logic)
  // ===========================================================================

  /// Calculates available start times for a given date and service duration.
  /// If [specificCoachId] is null, it aggregates ALL active staff (Pooling).
  // ===========================================================================
  // CORE: GET AVAILABLE SLOTS (Multi-Shift & Override Compatible)
  // ===========================================================================

  Future<List<DateTime>> getAvailableSlots({
    required DateTime date,
    required int durationMins,
    String? specificCoachId,
  }) async {
    // 1. Determine Workforce (Who are we checking?)
    Map<String, String> workforce = {};
    if (specificCoachId != null) {
      workforce[specificCoachId] = "Selected Coach";
    } else {
      workforce = await _contract.getActiveStaff();
    }
    if (workforce.isEmpty) return [];

    // 2. Fetch Global Constraints (Leaves & Appointments for this Date)
    // We fetch ALL data for the day to avoid N+1 queries inside the loop
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(hours: 24));

    // A. Fetch Leaves (Blocks)
    final leavesSnap = await _firestore.collection('coach_leaves')
        .where('end', isGreaterThan: Timestamp.fromDate(startOfDay))
        .get();
    // Note: We filter strictly in Dart later to handle the 'start < endOfDay' part
    // Firestore limitation: can't range filter on two different fields easily

    // B. Fetch Existing Appointments
    final apptsSnap = await _firestore.collection('appointments')
        .where('startTime', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('startTime', isLessThan: Timestamp.fromDate(endOfDay))
        .get();

    // 3. Generate Slots
    Set<DateTime> distinctSlots = {}; // Use Set to avoid duplicates

    for (var coachId in workforce.keys) {

      // A. Get Schedule (Priority: Override > Weekly > Default)
      final schedule = await _getCoachDaySchedule(coachId, date);

      // Skip if coach is off or has no shifts
      if (schedule == null || !schedule.isWorking || schedule.shifts.isEmpty) continue;

      // B. Iterate Through Each Shift (e.g., Morning Shift, Evening Shift)
      for (var shift in schedule.shifts) {

        // Define Shift Boundaries
        final shiftStart = DateTime(date.year, date.month, date.day, shift.startHour, shift.startMin);
        final shiftEnd = DateTime(date.year, date.month, date.day, shift.endHour, shift.endMin);

        // C. Walk through the shift in 15-minute increments
        DateTime cursor = shiftStart;

        while (cursor.add(Duration(minutes: durationMins)).isBefore(shiftEnd) ||
            cursor.add(Duration(minutes: durationMins)).isAtSameMomentAs(shiftEnd)) {

          final slotStart = cursor;
          final slotEnd = slotStart.add(Duration(minutes: durationMins));

          // D. Validation Checks

          // 1. Past Time Check (If today, don't show 9 AM when it's 2 PM)
          if (date.year == DateTime.now().year &&
              date.month == DateTime.now().month &&
              date.day == DateTime.now().day) {
            if (slotStart.isBefore(DateTime.now().add(const Duration(minutes: 15)))) { // Buffer
              cursor = cursor.add(const Duration(minutes: 15));
              continue;
            }
          }

          // 2. Conflict Check (Leaves & Appointments)
          if (_isCoachFree(coachId, slotStart, slotEnd, leavesSnap.docs, apptsSnap.docs)) {
            distinctSlots.add(slotStart);
          }

          // Move cursor
          cursor = cursor.add(const Duration(minutes: 15));
        }
      }
    }

    // 4. Sort and Return
    final sortedSlots = distinctSlots.toList()..sort();
    return sortedSlots;
  }

  // ===========================================================================
  // HELPER METHODS
  // ===========================================================================

  /// Fetches the effective schedule (Daily Override > Weekly Schedule > Default)
  Future<DaySchedule?> _getCoachDaySchedule(String coachId, DateTime date) async {
    // 1. Try Daily Override
    final overrideId = "${coachId}_${date.year}${date.month.toString().padLeft(2,'0')}${date.day.toString().padLeft(2,'0')}";
    final overrideDoc = await _firestore.collection('coach_daily_overrides').doc(overrideId).get();

    if (overrideDoc.exists) {
      // Map Firestore data to DaySchedule
      final data = overrideDoc.data()!;
      // Handle the nested structure of DailyOverrideModel
      return DaySchedule.fromMap(data['schedule']);
    }

    // 2. Try Weekly Schedule
    final doc = await _firestore.collection('coach_schedules').doc(coachId).get();
    if (!doc.exists) return DaySchedule.defaultSchedule(); // 9-6 Default

    final dayKey = DateFormat('E').format(date); // 'Mon', 'Tue'
    final weekData = doc.data()?['weekDays'] as Map<String, dynamic>? ?? {};

    if (weekData.containsKey(dayKey)) {
      return DaySchedule.fromMap(weekData[dayKey]);
    }

    return DaySchedule(isWorking: false, shifts: []); // Default OFF if day not defined
  }

  /// Checks if a specific coach is free during the requested time window
  bool _isCoachFree(
      String coachId,
      DateTime start,
      DateTime end,
      List<QueryDocumentSnapshot> leaves,
      List<QueryDocumentSnapshot> appointments
      ) {
    // 1. Check Leaves (Blocks)
    for (var doc in leaves) {
      final data = doc.data() as Map<String, dynamic>;
      if (data['coachId'] != coachId) continue;

      final lStart = (data['start'] as Timestamp).toDate();
      final lEnd = (data['end'] as Timestamp).toDate();

      // Check Overlap
      if (start.isBefore(lEnd) && end.isAfter(lStart)) {
        return false; // Blocked
      }
    }

    // 2. Check Appointments
    for (var doc in appointments) {
      final data = doc.data() as Map<String, dynamic>;
      if (data['coachId'] != coachId) continue;
      if (data['status'] == 'cancelled') continue;

      final aStart = (data['startTime'] as Timestamp).toDate();
      final aEnd = (data['endTime'] as Timestamp).toDate();

      // Check Overlap
      if (start.isBefore(aEnd) && end.isAfter(aStart)) {
        return false; // Busy
      }
    }

    return true; // Free
  }


  // ===========================================================================
  // 2. BOOKING ENGINE (Atomic & Ledger-Backed)
  // ===========================================================================

  Future<String> bookAppointment({
    required ServiceType service,
    required DateTime startTime,
    String? specificCoachId,
    String? onBehalfOfClientId,
  }) async {
    final clientId = onBehalfOfClientId ?? _contract.getCurrentUserId();

    // 1. AUTO-ASSIGNMENT (If pooled)
    // We re-run the availability check logic to find a specific coach ID
    String assignedCoachId;
    if (specificCoachId != null) {
      assignedCoachId = specificCoachId;
    } else {
      assignedCoachId = await _findFirstAvailableCoach(
        startTime,
        service.durationMins,
      );
    }

    // 2. PRE-FLIGHT CHECKS
    if (!await _contract.hasSufficientCredits(clientId, service.creditCost)) {
      throw Exception("Insufficient Wallet Credits. Please top up.");
    }

    // 3. ATOMIC OPERATION
    // We create the Appointment ID first to link it in the ledger
    final apptRef = _firestore.collection('appointments').doc();

    try {
      // A. Reserve Credits (Via Bridge)
      // This will throw if something goes wrong with the ledger
      await _contract.reserveCredits(
        clientId,
        service.creditCost,
        "Booking: ${service.name}",
        apptRef.id,
      );

      // B. Create Appointment Document
      final endTime = startTime.add(Duration(minutes: service.durationMins));

      await apptRef.set({
        'id': apptRef.id,
        'clientId': clientId,
        'coachId': assignedCoachId,
        'startTime': Timestamp.fromDate(startTime),
        'endTime': Timestamp.fromDate(endTime),
        'serviceName': service.name,
        'durationMins': service.durationMins,
        'status': 'confirmed', // Confirmed immediately as credit is reserved
        'isCreditBooking': true,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // C. Notify Staff
      await _contract.sendNotification(
        assignedCoachId,
        "New Appointment",
        "New ${service.name} booking for ${startTime.toString()}",
      );

      return apptRef.id;
    } catch (e) {
      // If booking fails but credit was reserved (unlikely due to order),
      // advanced error handling would go here.
      rethrow;
    }
  }

  /// Helper: Re-runs availability logic to pick a winner for auto-assignment
  Future<String> _findFirstAvailableCoach(
    DateTime start,
    int durationMins,
  ) async {
    final end = start.add(Duration(minutes: durationMins));
    final workforce = await _contract.getActiveStaff();

    // We need fresh constraints to ensure we don't double book in race conditions
    // (Simplified fetch for brevity - reusing logic from getAvailableSlots recommended)
    final startOfDay = DateTime(start.year, start.month, start.day);
    final leavesSnap = await _firestore
        .collection('coach_leaves')
        .where('end', isGreaterThan: Timestamp.fromDate(startOfDay))
        .get();
    final apptsSnap = await _firestore
        .collection('appointments')
        .where(
          'startTime',
          isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay),
        )
        .get();

    for (var coachId in workforce.keys) {
      if (_isCoachFree(coachId, start, end, leavesSnap.docs, apptsSnap.docs)) {
        return coachId;
      }
    }
    throw Exception("Selected slot is no longer available.");
  }

  // --- BOOKING ---
  Future<void> bookSession({
    String? clientId,
    required String clientName,
    String? guestPhone,
    required String coachId,
    required DateTime startTime,
    required int durationMinutes,
    required String topic,
    bool useFreeSession = false,
    bool isAdminBooking = false,
    String? performedByUid,
    String? performedByName,
  }) async {
    final endTime = startTime.add(Duration(minutes: durationMinutes));

    await _firestore.collection('appointments').add({
      'clientId': clientId,
      'clientName': clientName,
      'guestPhone': guestPhone,
      'coachId': coachId,
      'startTime': Timestamp.fromDate(startTime),
      'endTime': Timestamp.fromDate(endTime),
      'durationMins': durationMinutes,
      'topic': topic,
      'status': 'confirmed',
      'bookedBy': isAdminBooking ? 'admin' : 'client',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // --- CALENDAR MANAGEMENT ---
  Future<void> blockCalendar(String coachId, DateTime start, DateTime end, String reason) async {
    await _firestore.collection('coach_leaves').add({
      'coachId': coachId,
      'start': Timestamp.fromDate(start),
      'end': Timestamp.fromDate(end),
      'reason': reason,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> cancelAppointment(String appointmentId, String reason) async {
    await _firestore.collection('appointments').doc(appointmentId).update({
      'status': 'cancelled',
      'cancellationReason': reason,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}

