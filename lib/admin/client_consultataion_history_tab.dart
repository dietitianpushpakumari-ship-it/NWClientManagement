import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:nutricare_client_management/admin/client_consultation_checlist_screen.dart';
import 'package:nutricare_client_management/admin/consultation_session_model.dart';
import 'package:nutricare_client_management/admin/consultation_session_service.dart';
import 'package:nutricare_client_management/admin/database_provider.dart';
import 'package:nutricare_client_management/master/model/master_constants.dart';
import 'package:nutricare_client_management/modules/client/model/client_model.dart';

// Helper class for subscription details
class ClientSubscriptionInfo {
  final int interval;
  final DateTime? expiryDate;

  ClientSubscriptionInfo({required this.interval, this.expiryDate});
}

// 🎯 FIX: Changed to StreamProvider for Real-Time Updates
final clientSubscriptionInfoStreamProvider = StreamProvider.family<ClientSubscriptionInfo, String>((ref, clientId) {
  final firestore = ref.watch(firestoreProvider);

  String collectionPath = 'patient_subscription';
  try {
    collectionPath = MasterCollectionMapper.getPath(TransactionEntity.entity_patientSubscription);
  } catch (_) {}

  // 1. Listen to ALL subscriptions for this client (Sort in Dart to avoid index errors)
  return firestore.collection(collectionPath)
      .where('clientId', isEqualTo: clientId)
      .snapshots()
      .asyncMap((snapshot) async { // Use asyncMap to allow fetching package details if needed

    if (snapshot.docs.isEmpty) {
      debugPrint("🔍 No subscriptions found for client: $clientId");
      return ClientSubscriptionInfo(interval: 7, expiryDate: null);
    }

    final docs = snapshot.docs;

    // 2. Sort by End Date Descending (Latest first)
    docs.sort((a, b) {
      DateTime? dateA = _parseDate(a.data()['endDate']);
      DateTime? dateB = _parseDate(b.data()['endDate']);
      if (dateA == null) return 1;
      if (dateB == null) return -1;
      return dateB.compareTo(dateA);
    });

    // 3. Find the first "Valid" subscription (EndDate > Now)
    // We prioritize 'active' status, but fallback to just date validity if status is missing/wrong
    QueryDocumentSnapshot? bestSub;

    try {
      bestSub = docs.firstWhere((doc) {
        final d = doc.data() as Map<String, dynamic>;
        final DateTime? end = _parseDate(d['endDate']);
        final String status = (d['status'] ?? '').toString().toLowerCase();

        // Logic: Must have a future date AND (status is active OR just created)
        return end != null && end.isAfter(DateTime.now().subtract(const Duration(days: 1)));
      });
    } catch (_) {
      // If no valid sub found, bestSub remains null
    }

    if (bestSub == null) {
      debugPrint("⚠️ Found subscriptions, but none are currently valid.");
      return ClientSubscriptionInfo(interval: 7, expiryDate: null);
    }

    final subData = bestSub.data() as Map<String, dynamic>;
    final DateTime? expiryDate = _parseDate(subData['endDate']);
    final String? packageId = subData['packageId'];

    // 4. Fetch Interval from Master Package (if available)
    int interval = 7;
    if (packageId != null) {
      try {
        String pkgCollectionPath = MasterCollectionMapper.getPath(MasterEntity.entity_packages);
        final pkgDoc = await firestore.collection(pkgCollectionPath).doc(packageId).get();
        if (pkgDoc.exists) {
          interval = pkgDoc.data()?['followUpIntervalDays'] ?? 7;
        }
      } catch (e) {
        debugPrint("Error fetching package interval: $e");
      }
    }

    return ClientSubscriptionInfo(interval: interval, expiryDate: expiryDate);
  });
});

// Helper to safely parse dates
DateTime? _parseDate(dynamic raw) {
  if (raw == null) return null;
  if (raw is Timestamp) return raw.toDate();
  if (raw is String) return DateTime.tryParse(raw);
  return null;
}

class ClientConsultationHistoryTab extends ConsumerWidget {
  final ClientModel client;

  const ClientConsultationHistoryTab({super.key, required this.client});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionService = ref.watch(consultationServiceProvider);

    // 🎯 FIX: Watch the StreamProvider
    final subInfoAsync = ref.watch(clientSubscriptionInfoStreamProvider(client.id));

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _startNewConsultation(context),
              icon: const Icon(Icons.add_circle_outline),
              label: const Text("Start New Consultation"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 2,
              ),
            ),
          ),
        ),

        Expanded(
          child: StreamBuilder<List<ConsultationSessionModel>>(
            stream: sessionService.streamSessionHistory(client.id),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(child: Text("Error: ${snapshot.error}", style: const TextStyle(color: Colors.red)));
              }

              final sessions = snapshot.data ?? [];

              if (sessions.isEmpty) {
                return _buildEmptyState();
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: sessions.length,
                itemBuilder: (context, index) {
                  final session = sessions[index];

                  final bool isComplete = session.status.toLowerCase() == 'complete' || session.status.toLowerCase() == 'closed';

                  // Only Parent (Initial) sessions can have follow-ups added
                  final bool isParentSession = session.consultationType != 'Followup';

                  bool isEligibleForFollowUp = isComplete && isParentSession;

                  // Get Info from Provider
                  final info = subInfoAsync.value;
                  int interval = info?.interval ?? 7;
                  DateTime? subExpiry = info?.expiryDate;

                  int daysSince = 0;
                  if (isEligibleForFollowUp) {
                    final lastDate = session.endTime?.toDate() ?? session.sessionDate.toDate();
                    daysSince = DateTime.now().difference(lastDate).inDays;
                  }

                  return _buildSessionCard(context, session, isEligibleForFollowUp, daysSince, interval, subExpiry);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSessionCard(
      BuildContext context,
      ConsultationSessionModel session,
      bool isEligible,
      int daysSince,
      int interval,
      DateTime? subExpiry
      ) {
    final dateStr = DateFormat('dd MMM yyyy').format(session.sessionDate.toDate());
    final isComplete = session.status.toLowerCase() == 'complete' || session.status.toLowerCase() == 'closed';

    Color statusColor = isComplete ? Colors.green : Colors.orange;
    IconData statusIcon = isComplete ? Icons.check_circle : Icons.sync;
    String statusText = session.status.toUpperCase();

    // Dynamic Title
    String titleText = (session.consultationType == 'Followup')
        ? "Follow-up Consultation"
        : "New Consultation";

    bool isDue = daysSince >= (interval - 2);

    // LOGIC: Subscription Status Message
    String? expiryMsg;
    Color? expiryColor;

    if (isEligible) {
      if (subExpiry != null) {
        final daysLeftInSub = subExpiry.difference(DateTime.now()).inDays;

        if (daysLeftInSub < 0) {
          expiryMsg = "Subscription Expired";
          expiryColor = Colors.red;
        } else if (daysLeftInSub <= 3) {
          expiryMsg = "Plan ends in $daysLeftInSub days";
          expiryColor = Colors.red;
        } else if (daysLeftInSub <= 7) {
          expiryMsg = "Plan valid: $daysLeftInSub days left";
          expiryColor = Colors.orange.shade900;
        } else {
          expiryMsg = "Plan Active ($daysLeftInSub days)";
          expiryColor = Colors.green.shade700;
        }
      } else {
        expiryMsg = "No Active Subscription";
        expiryColor = Colors.grey;
      }
    }

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Card(
          margin: const EdgeInsets.only(bottom: 16),
          elevation: isEligible ? 4 : 2,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: (isEligible && isDue) ? const BorderSide(color: Colors.orange, width: 1.5) : BorderSide.none
          ),
          clipBehavior: Clip.hardEdge,
          child: InkWell(
            onTap: () => _viewSessionDetails(context, session),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(color: statusColor.withOpacity(0.1), shape: BoxShape.circle),
                        child: Icon(Icons.medical_services_outlined, color: statusColor, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(titleText, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            const SizedBox(height: 4),
                            Text(dateStr, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                          ],
                        ),
                      ),

                      if (isEligible)
                        ElevatedButton(
                          onPressed: () => _startFollowUp(context, session.id),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.indigo,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            elevation: 2,
                          ),
                          child: const Text("Start Follow-up"),
                        )
                      else
                        const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                    ],
                  ),

                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(statusIcon, size: 14, color: statusColor),
                      const SizedBox(width: 6),
                      Text(statusText, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: statusColor)),

                      if (isEligible) ...[
                        const Spacer(),
                        if (expiryMsg != null)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                                color: expiryColor!.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4)
                            ),
                            child: Text(
                                expiryMsg,
                                style: TextStyle(color: expiryColor, fontWeight: FontWeight.bold, fontSize: 11)
                            ),
                          )
                        else
                          Text(
                              isDue
                                  ? "Due Now"
                                  : "Next in ${(interval - daysSince)} days",
                              style: TextStyle(color: isDue ? Colors.orange : Colors.grey, fontWeight: FontWeight.bold, fontSize: 12)
                          ),
                      ]
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),

        if (isEligible && isDue)
          Positioned(
            top: -10,
            right: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.orange,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4, offset: const Offset(0, 2))],
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.notifications_active, size: 12, color: Colors.white),
                  SizedBox(width: 6),
                  Text("Follow-up Due", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10)),
                ],
              ),
            ),
          ),
      ],
    );
  }

  void _startFollowUp(BuildContext context, String parentSessionId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ClientConsultationChecklistScreen(
          client: client,
          isFollowup: true,
          parentSessionId: parentSessionId,
        ),
      ),
    );
  }

  void _startNewConsultation(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ClientConsultationChecklistScreen(
          client: client,
          isFollowup: false,
          forceNew: true,
        ),
      ),
    );
  }

  void _viewSessionDetails(BuildContext context, ConsultationSessionModel session) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ClientConsultationChecklistScreen(
          client: client,
          viewSessionId: session.id,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history, size: 60, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          Text("No consultation history yet.", style: TextStyle(color: Colors.grey.shade500)),
        ],
      ),
    );
  }
}