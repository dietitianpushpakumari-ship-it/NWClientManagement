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

// 🎯 ENHANCED: Holds Package Name & Status
class ClientSubscriptionInfo {
  final String? packageName;
  final String status; // 'Active', 'Expired', 'None'
  final int interval;
  final DateTime? expiryDate;

  ClientSubscriptionInfo({
    this.packageName,
    required this.status,
    required this.interval,
    this.expiryDate
  });
}

// StreamProvider for Real-Time Updates
final clientSubscriptionInfoStreamProvider = StreamProvider.family<ClientSubscriptionInfo, String>((ref, clientId) {
  final firestore = ref.watch(firestoreProvider);

  String collectionPath = 'patient_subscription';
  try {
    collectionPath = MasterCollectionMapper.getPath(TransactionEntity.entity_patientSubscription);
  } catch (_) {}

  return firestore.collection(collectionPath)
      .where('clientId', isEqualTo: clientId)
      .snapshots()
      .asyncMap((snapshot) async {

    if (snapshot.docs.isEmpty) {
      return ClientSubscriptionInfo(status: 'None', interval: 7);
    }

    final docs = snapshot.docs;

    // Sort by End Date Descending (Latest first)
    docs.sort((a, b) {
      DateTime? dateA = _parseDate(a.data()['endDate']);
      DateTime? dateB = _parseDate(b.data()['endDate']);
      if (dateA == null) return 1;
      if (dateB == null) return -1;
      return dateB.compareTo(dateA);
    });

    // Find the first "Relevant" subscription (Active or Latest Expired)
    QueryDocumentSnapshot? bestSub;
    if (docs.isNotEmpty) bestSub = docs.first;

    try {
      final activeSub = docs.firstWhere((doc) {
        final d = doc.data() as Map<String, dynamic>;
        final DateTime? end = _parseDate(d['endDate']);
        return end != null && end.isAfter(DateTime.now().subtract(const Duration(days: 1)));
      });
      bestSub = activeSub;
    } catch (_) {}

    if (bestSub == null) {
      return ClientSubscriptionInfo(status: 'None', interval: 7);
    }

    final subData = bestSub.data() as Map<String, dynamic>;

    final DateTime? expiryDate = _parseDate(subData['endDate']);
    final String? packageId = subData['packageId'];
    final String? packageName = subData['packageName'];

    String status = 'Expired';
    if (expiryDate != null && expiryDate.isAfter(DateTime.now().subtract(const Duration(days: 1)))) {
      status = 'Active';
    }

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

    return ClientSubscriptionInfo(
        packageName: packageName,
        status: status,
        interval: interval,
        expiryDate: expiryDate
    );
  });
});

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
    final subInfoAsync = ref.watch(clientSubscriptionInfoStreamProvider(client.id));

    return Column(
      children: [
        // 🎯 REMOVED: "Start New Consultation" Button (Clean History View)
        const SizedBox(height: 16),

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

              final allSessions = snapshot.data ?? [];

              if (allSessions.isEmpty) {
                return _buildEmptyState();
              }

              // HIERARCHY LOGIC
              final Map<String, List<ConsultationSessionModel>> childrenMap = {};
              final List<ConsultationSessionModel> roots = [];
              final Set<String> allIds = allSessions.map((e) => e.id).toSet();

              for (var session in allSessions) {
                if (session.parentId != null && allIds.contains(session.parentId)) {
                  childrenMap.putIfAbsent(session.parentId!, () => []).add(session);
                } else {
                  roots.add(session);
                }
              }

              roots.sort((a, b) => b.sessionDate.compareTo(a.sessionDate));

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: roots.length,
                itemBuilder: (context, index) {
                  final root = roots[index];
                  final children = childrenMap[root.id] ?? [];
                  children.sort((a, b) => b.sessionDate.compareTo(a.sessionDate));

                  return _buildConsultationThread(context, root, children, subInfoAsync.valueOrNull);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  // 🎯 THREAD BUILDER
  Widget _buildConsultationThread(
      BuildContext context,
      ConsultationSessionModel root,
      List<ConsultationSessionModel> children,
      ClientSubscriptionInfo? subInfo
      ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSessionNode(context, root, subInfo, isChild: false),

        if (children.isNotEmpty)
          Stack(
            children: [
              Positioned(
                  left: 20, top: 0, bottom: 20,
                  child: Container(width: 2, color: Colors.grey.shade300)
              ),
              Padding(
                padding: const EdgeInsets.only(left: 0),
                child: Column(
                  children: children.map((child) =>
                      Padding(
                        padding: const EdgeInsets.only(left: 32, top: 12),
                        child: _buildSessionNode(context, child, subInfo, isChild: true),
                      )
                  ).toList(),
                ),
              )
            ],
          ),

        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildSessionNode(
      BuildContext context,
      ConsultationSessionModel session,
      ClientSubscriptionInfo? subInfo,
      {required bool isChild}
      ) {
    final bool isComplete = session.status.toLowerCase() == 'complete' || session.status.toLowerCase() == 'closed';
    final bool isParentNode = !isChild && session.consultationType != 'Followup';
    final bool isEligibleForFollowUp = isComplete && isParentNode;

    return _buildSessionCard(
        context,
        session,
        isEligibleForFollowUp,
        subInfo,
        isChild: isChild
    );
  }

  Widget _buildSessionCard(
      BuildContext context,
      ConsultationSessionModel session,
      bool isEligible,
      ClientSubscriptionInfo? subInfo,
      {required bool isChild}
      ) {
    final dateStr = DateFormat('dd MMM yyyy').format(session.sessionDate.toDate());
    final isComplete = session.status.toLowerCase() == 'complete' || session.status.toLowerCase() == 'closed';

    Color statusColor = isComplete ? Colors.green : Colors.orange;
    IconData statusIcon = isComplete ? Icons.check_circle : Icons.sync;
    String statusText = session.status.toUpperCase();

    String titleText = (session.consultationType == 'Followup' || isChild)
        ? "Follow-up Visit"
        : "Initial Consultation";

    String? packageText;
    Color packageColor = Colors.grey;

    if (isEligible && subInfo != null && subInfo.packageName != null) {
      if (subInfo.status == 'Active') {
        packageText = "${subInfo.packageName} • Active";
        packageColor = Colors.green.shade700;
      } else {
        packageText = "${subInfo.packageName} • Expired";
        packageColor = Colors.red.shade700;
      }
    }

    int interval = subInfo?.interval ?? 7;
    int daysSince = 0;
    if (isEligible) {
      final lastDate = session.endTime?.toDate() ?? session.sessionDate.toDate();
      daysSince = DateTime.now().difference(lastDate).inDays;
    }
    bool isDue = daysSince >= (interval - 2);
    int daysRemaining = interval - daysSince;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color: isChild ? Colors.grey.shade200 : (isEligible && isDue ? Colors.orange.shade300 : Colors.indigo.shade100),
                width: isChild ? 1 : 1.5
            ),
            boxShadow: isChild ? [] : [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))],
          ),
          child: InkWell(
            onTap: () => _viewSessionDetails(context, session),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                            color: isChild ? Colors.purple.shade50 : Colors.indigo.shade50,
                            shape: BoxShape.circle
                        ),
                        child: Icon(
                            isChild ? Icons.loop : Icons.flag_rounded,
                            color: isChild ? Colors.purple : Colors.indigo,
                            size: 18
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(titleText, style: TextStyle(fontWeight: FontWeight.bold, fontSize: isChild ? 14 : 16)),
                            const SizedBox(height: 4),
                            Text(dateStr, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                          ],
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
                    ],
                  ),

                  if (!isChild) ...[
                    const SizedBox(height: 8),
                    const Divider(height: 1, thickness: 0.5),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(statusIcon, size: 12, color: statusColor),
                        const SizedBox(width: 4),
                        Text(statusText, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: statusColor)),

                        const Spacer(),

                        if (packageText != null)
                          Container(
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                                color: packageColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6)
                            ),
                            child: Text(
                                packageText,
                                style: TextStyle(color: packageColor, fontWeight: FontWeight.bold, fontSize: 10)
                            ),
                          ),

                        if (isEligible)
                          Text(
                              isDue ? "Due Now" : "$daysRemaining days left",
                              style: TextStyle(color: isDue ? Colors.orange : Colors.grey, fontWeight: FontWeight.bold, fontSize: 11)
                          ),
                      ],
                    ),
                  ]
                ],
              ),
            ),
          ),
        ),

        if (isEligible && isDue && !isChild)
          Positioned(
            top: -8, right: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.orange,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 2)],
              ),
              child: const Text("DUE", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 9)),
            ),
          ),
      ],
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