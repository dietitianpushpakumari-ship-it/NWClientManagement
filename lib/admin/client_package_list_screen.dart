import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:nutricare_client_management/admin/consultation_session_model.dart';
import 'package:nutricare_client_management/admin/consultation_session_service.dart';
import 'package:nutricare_client_management/admin/database_provider.dart';
import 'package:nutricare_client_management/admin/labvital/global_service_provider.dart';
import 'package:nutricare_client_management/admin/package_details_screen.dart';
import 'package:nutricare_client_management/master/model/master_constants.dart';
import 'package:nutricare_client_management/modules/client/model/client_model.dart';
import 'package:nutricare_client_management/modules/package/model/package_assignment_model.dart';
import 'package:nutricare_client_management/modules/package/model/package_model.dart';
import 'package:nutricare_client_management/screens/package_assignment_page.dart';
import 'package:nutricare_client_management/screens/payment_ledger_screen.dart';
import 'package:nutricare_client_management/modules/package/service/package_payment_service.dart';

class ClientPackageListScreen extends ConsumerStatefulWidget {
  final ClientModel client;
  final String? sessionId;
  final bool isReadOnly;
  const ClientPackageListScreen({super.key, required this.client, this.sessionId, this.isReadOnly = false});

  @override
  ConsumerState<ClientPackageListScreen> createState() => _ClientPackageListScreenState();
}

class _ClientPackageListScreenState extends ConsumerState<ClientPackageListScreen> {

  // --- ACTIONS ---

  Future<void> _markStepComplete() async {
    setState(() {});

    try {
      final batch = ref.read(firestoreProvider).batch();

      if (widget.sessionId != null) {
        final sessionRef = ref.read(firestoreProvider).collection('consultation_sessions').doc(widget.sessionId);
        batch.update(sessionRef, {
          'steps.subscription': true,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      final clientRef = ref.read(firestoreProvider).collection('clients').doc(widget.client.id);
      batch.update(clientRef, {
        'onboarding_step_subscription': true,
      });

      await batch.commit();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Subscription Step Marked Complete! ✅"),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 1),
            )
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  // --- UI BUILDER ---

  @override
  Widget build(BuildContext context) {
    return _buildScaffold(context);
  }

  Widget _buildScaffold(BuildContext context) {
    final subscriptionStream = ref.watch(firestoreProvider)
        .collection(MasterCollectionMapper.getPath(TransactionEntity.entity_patientSubscription))
        .where('clientId', isEqualTo: widget.client.id)
        .orderBy('createdAt', descending: true)
        .snapshots();

    final sessionStream = ref.watch(consultationServiceProvider).streamSessionHistory(widget.client.id);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Package & Payment History", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text(widget.client.name, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: widget.isReadOnly ? [] : [
          IconButton(
            icon: const Icon(Icons.add_circle, color: Colors.indigo),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => PackageAssignmentPage(client: widget.client, sessionId: widget.sessionId))),
          )
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: subscriptionStream,
        builder: (context, subSnapshot) {
          if (!subSnapshot.hasData) return const Center(child: CircularProgressIndicator());

          return StreamBuilder<List<ConsultationSessionModel>>(
            stream: sessionStream,
            builder: (context, sessionSnapshot) {
              if (sessionSnapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());

              final allSubscriptions = subSnapshot.data!.docs;
              final allSessions = sessionSnapshot.data ?? [];

              // 1. Identify Direct Bookings (No Session ID)
              final directBookings = allSubscriptions.where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final sid = data['sessionId'];
                return sid == null || (sid is String && sid.isEmpty);
              }).toList();

              // 2. Map Subscriptions to Session IDs
              final Map<String, DocumentSnapshot> sessionToSubMap = {};
              for (var doc in allSubscriptions) {
                final data = doc.data() as Map<String, dynamic>;
                final sid = data['sessionId'];
                if (sid != null && sid is String && sid.isNotEmpty) {
                  sessionToSubMap[sid] = doc;
                }
              }

              // 3. Build Hierarchy for Sessions
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

              if (allSubscriptions.isEmpty && allSessions.isEmpty) {
                return _buildEmptyState();
              }

              return CustomScrollView(
                slivers: [
                  const SliverToBoxAdapter(child: SizedBox(height: 20)),

                  // --- DIRECT BOOKINGS ---
                  if (directBookings.isNotEmpty) ...[
                    _buildSectionHeader("DIRECT BOOKINGS (NO SESSION)", Icons.touch_app_outlined, Colors.orange),
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                            (context, index) => _buildSubscriptionCard(directBookings[index], isConsultation: false),
                        childCount: directBookings.length,
                      ),
                    ),
                    const SliverToBoxAdapter(child: SizedBox(height: 24)),
                  ],

                  // --- CONSULTATION HISTORY (Threaded) ---
                  if (roots.isNotEmpty) ...[
                    _buildSectionHeader("CONSULTATION HISTORY", Icons.history_edu, Colors.blue),
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                            (context, index) {
                          final root = roots[index];
                          final children = childrenMap[root.id] ?? [];
                          children.sort((a, b) => b.sessionDate.compareTo(a.sessionDate));

                          return _buildConsultationThread(root, children, sessionToSubMap);
                        },
                        childCount: roots.length,
                      ),
                    ),
                  ],

                  const SliverToBoxAdapter(child: SizedBox(height: 80)),
                ],
              );
            },
          );
        },
      ),
      bottomNavigationBar: widget.sessionId != null
          ? widget.isReadOnly ? null : Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))],
        ),
        child: SafeArea(
          child: ElevatedButton.icon(
            onPressed: _markStepComplete,
            icon: const Icon(Icons.check_circle_outline, size: 24),
            label: const Text("MARK STEP COMPLETE", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
      )
          : null,
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, Color color) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Row(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 8),
            Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 13, letterSpacing: 0.5)),
            const Expanded(child: Divider(indent: 10)),
          ],
        ),
      ),
    );
  }

  // 🎯 THREAD BUILDER
  Widget _buildConsultationThread(
      ConsultationSessionModel root,
      List<ConsultationSessionModel> children,
      Map<String, DocumentSnapshot> sessionToSubMap
      ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Parent Node
        _buildSessionNode(root, sessionToSubMap[root.id], isChild: false),

        // Children Nodes (Tree)
        if (children.isNotEmpty)
          Stack(
            children: [
              Positioned(
                  left: 30, top: 0, bottom: 20,
                  child: Container(width: 2, color: Colors.grey.shade300)
              ),
              Padding(
                padding: const EdgeInsets.only(left: 32),
                child: Column(
                  children: children.map((child) =>
                      _buildSessionNode(child, sessionToSubMap[child.id], isChild: true)
                  ).toList(),
                ),
              )
            ],
          ),

        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildSessionNode(ConsultationSessionModel session, DocumentSnapshot? linkedSub, {required bool isChild}) {
    return _buildSessionHistoryCard(session, linkedSub, isChild: isChild);
  }

  Widget _buildSessionHistoryCard(ConsultationSessionModel session, DocumentSnapshot? linkedSub, {required bool isChild}) {
    final dateStr = DateFormat('dd MMM yyyy, hh:mm a').format(session.sessionDate.toDate());
    final type = session.consultationType == 'Followup' || isChild ? "Follow-up" : "Initial Consultation";

    return Container(
      margin: EdgeInsets.fromLTRB(isChild ? 0 : 20, 0, 20, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                      color: isChild ? Colors.purple.shade50 : Colors.indigo.shade50,
                      shape: BoxShape.circle
                  ),
                  child: Icon(
                      isChild ? Icons.loop : Icons.flag_rounded,
                      color: isChild ? Colors.purple.shade300 : Colors.indigo.shade300,
                      size: 18
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(type, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      const SizedBox(height: 2),
                      Text(dateStr, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1, indent: 50),

          // Package Status Area
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(50, 12, 12, 12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
            ),
            child: linkedSub != null
                ? _buildLinkedPackageInfo(linkedSub)
                : _buildBookNowButton(session.id),
          ),
        ],
      ),
    );
  }

  // 🎯 UPDATED: Shows Payment Status
  Widget _buildLinkedPackageInfo(DocumentSnapshot subDoc) {
    final data = subDoc.data() as Map<String, dynamic>;
    final name = data['packageName'] ?? 'Unknown Package';
    final status = data['status'] ?? 'expired';
    final isActive = status == 'active';
    final double bookedAmount = (data['bookedAmount'] as num?)?.toDouble() ?? (data['price'] as num?)?.toDouble() ?? 0.0;

    return FutureBuilder<double>(
        future: ref.read(packagePaymentServiceProvider).getCollectedAmountForAssignment(subDoc.id),
        builder: (context, snapshot) {
          final collected = snapshot.data ?? 0.0;
          final pending = bookedAmount - collected;

          // Determine Payment Status Badge
          String payLabel;
          Color payColor;

          if (pending <= 1.0) {
            payLabel = "Fully Paid";
            payColor = Colors.green;
          } else if (collected > 0) {
            payLabel = "Partial (Due: ₹${pending.toInt()})";
            payColor = Colors.orange;
          } else {
            payLabel = "Unpaid (Due: ₹${bookedAmount.toInt()})";
            payColor = Colors.red;
          }

          return Row(
            children: [
              Icon(Icons.check_circle, size: 16, color: isActive ? Colors.green : Colors.grey),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Text(isActive ? "Active" : "Inactive", style: TextStyle(fontSize: 11, color: isActive ? Colors.green : Colors.grey)),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(
                              color: payColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: payColor.withOpacity(0.3))
                          ),
                          child: Text(
                              payLabel,
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: payColor)
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: () => _showPackageDetailModal(subDoc),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text("Details", style: TextStyle(fontSize: 12)),
              )
            ],
          );
        }
    );
  }

  Widget _buildBookNowButton(String sessionId) {
    if (widget.isReadOnly) return const Text("No Package Linked", style: TextStyle(fontSize: 12, color: Colors.grey));
    return Row(
      children: [
        const Icon(Icons.info_outline, size: 16, color: Colors.orange),
        const SizedBox(width: 8),
        const Text("No Package Linked", style: TextStyle(fontSize: 12, color: Colors.grey)),
        const Spacer(),
        SizedBox(
          height: 30,
          child: ElevatedButton(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => PackageAssignmentPage(client: widget.client, sessionId: sessionId))),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.indigo,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              textStyle: const TextStyle(fontSize: 12),
            ),
            child: const Text("Book Now"),
          ),
        )
      ],
    );
  }

  void _showPackageDetailModal(DocumentSnapshot subDoc) {
    showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => Container(
          padding: const EdgeInsets.only(top: 20),
          decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20))
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Package Details", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                    IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context))
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: _buildSubscriptionCard(subDoc, isConsultation: true),
              ),
              const SizedBox(height: 20),
            ],
          ),
        )
    );
  }

  Widget _buildSubscriptionCard(DocumentSnapshot doc, {required bool isConsultation, bool isChild = false}) {
    final data = doc.data() as Map<String, dynamic>;
    final String packageId = data['packageId'] ?? '';
    final String planName = data['packageName'] ?? 'Unknown Plan';
    final double bookedAmount = (data['bookedAmount'] as num?)?.toDouble() ?? (data['price'] as num?)?.toDouble() ?? 0.0;

    final String status = data['status'] ?? 'expired';
    final DateTime startDate = (data['startDate'] as Timestamp).toDate();
    final DateTime endDate = (data['endDate'] as Timestamp).toDate();
    final int extraDays = data['offerExtraDays'] ?? 0;
    final int totalSessions = data['sessionsTotal'] ?? 0;
    final int currentSessions = data['sessionsRemaining'] ?? 0;

    final bool isActuallyActive = status == 'active' && endDate.isAfter(DateTime.now());
    Color statusColor = isActuallyActive ? Colors.green : (status == 'active' ? Colors.red : Colors.grey);
    String statusLabel = isActuallyActive ? "ACTIVE" : (status == 'active' ? "EXPIRED" : status.toUpperCase());

    return Container(
      margin: EdgeInsets.fromLTRB(isChild ? 0 : 20, 0, 20, 16),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
          border: Border(left: BorderSide(color: statusColor, width: 4))
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 4, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(planName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                            child: Text("● $statusLabel", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: statusColor)),
                          ),
                          if (extraDays > 0)
                            Text("+ $extraDays Days", style: TextStyle(fontSize: 11, color: Colors.orange.shade800, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.info_outline, color: Colors.indigo),
                  onPressed: () => _viewPackageDetails(packageId, data),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, color: Colors.grey),
                  onSelected: (val) {
                    if (val == 'edit') _editSubscription(doc);
                    if (val == 'delete') _deleteSubscription(doc.id, planName, isActuallyActive);
                  },
                  itemBuilder: (ctx) =>  widget.isReadOnly ? [] : [
                    const PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit, size: 18), SizedBox(width: 8), Text("Correct Data")])),
                    const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete, size: 18, color: Colors.red), SizedBox(width: 8), Text("Delete Record", style: TextStyle(color: Colors.red))])),
                  ],
                )
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Expanded(child: _buildIconText(Icons.calendar_today, "${DateFormat('dd MMM').format(startDate)} - ${DateFormat('dd MMM yyyy').format(endDate)}")),
                const SizedBox(width: 10),
                Text("$currentSessions / $totalSessions Sessions", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: Colors.blueGrey.withOpacity(0.03),
            child: FutureBuilder<double>(
              future: ref.read(packagePaymentServiceProvider).getCollectedAmountForAssignment(doc.id),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: SizedBox(width: 15, height: 15, child: CircularProgressIndicator(strokeWidth: 2)));
                final collected = snapshot.data!;
                final pending = bookedAmount - collected;
                final progress = bookedAmount > 0 ? (collected / bookedAmount).clamp(0.0, 1.0) : 0.0;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildMoneyColumn("Total", bookedAmount, Colors.black87),
                        _buildMoneyColumn("Paid", collected, Colors.green),
                        _buildMoneyColumn("Balance", pending > 0 ? pending : 0.0, pending > 0 ? Colors.red : Colors.grey),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(borderRadius: BorderRadius.circular(4), child: LinearProgressIndicator(value: progress, backgroundColor: Colors.grey.shade200, color: pending <= 0.01 ? Colors.green : Colors.orange, minHeight: 4))
                  ],
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: SizedBox(
              width: double.infinity,
              child: widget.isReadOnly ? null : ElevatedButton.icon(
                onPressed: () async {
                  await _openPaymentLedger(doc, data, planName, startDate, endDate, isActuallyActive, bookedAmount);
                  setState(() {});
                },
                icon: const Icon(Icons.account_balance_wallet, size: 18),
                label: const Text("Manage Payments & History"),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 12), elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
              ),
            ),
          )
        ],
      ),
    );
  }

  // ... [Keep Helper Methods: _viewPackageDetails, _openFallbackPackageDetails, _deleteSubscription, _editSubscription, _openPaymentLedger, _buildMoneyColumn, _buildIconText, _buildEmptyState as they were] ...
  Future<void> _viewPackageDetails(String packageId, Map<String, dynamic> subscriptionData) async {
    showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator()));
    try {
      final collectionPath = MasterCollectionMapper.getPath(MasterEntity.entity_packages);
      final doc = await ref.read(firestoreProvider).collection(collectionPath).doc(packageId).get();
      Navigator.pop(context);
      if (doc.exists) {
        final package = PackageModel.fromFirestore(doc);
        Navigator.push(context, MaterialPageRoute(builder: (_) => PackageDetailScreen(package: package)));
      } else {
        _openFallbackPackageDetails(packageId, subscriptionData);
      }
    } catch (e) {
      Navigator.pop(context);
      _openFallbackPackageDetails(packageId, subscriptionData);
    }
  }

  void _openFallbackPackageDetails(String packageId, Map<String, dynamic> subData) {
    final startDate = (subData['startDate'] as Timestamp).toDate();
    final endDate = (subData['endDate'] as Timestamp).toDate();
    final duration = endDate.difference(startDate).inDays;
    final fallbackPackage = PackageModel(
      id: packageId,
      name: subData['packageName'] ?? 'Archived Package',
      description: "⚠️ Original package definition was deleted. Showing archived subscription details.",
      price: (subData['price'] as num?)?.toDouble() ?? 0.0,
      durationDays: duration,
      consultationCount: subData['sessionsTotal'] ?? 0,
      freeSessions: subData['freeSessionsTotal'] ?? 0,
      inclusions: List<String>.from(subData['inclusions'] ?? []),
      isFinalized: true,
      isActive: false,
      colorCode: null, packageType: subData['type'] ?? '',
    );
    Navigator.push(context, MaterialPageRoute(builder: (_) => PackageDetailScreen(package: fallbackPackage)));
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Original plan deleted. Showing archived details."), backgroundColor: Colors.orange));
  }

  Future<void> _deleteSubscription(String subId, String packageName, bool wasActive) async {
    final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
            title: const Text("Delete Record & Revoke Credits?"),
            content: Text("Are you sure you want to remove '$packageName'?\n\n⚠️ This will remove any remaining credits associated with this package from the client's wallet.\n\nThis action cannot be undone."),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancel")),
              ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text("Delete & Revoke")
              )
            ]
        )
    );

    if (confirm != true) return;

    try {
      final firestore = ref.read(firestoreProvider);
      final clientRef = firestore.collection('clients').doc(widget.client.id);
      final subRef = firestore.collection(MasterCollectionMapper.getPath(TransactionEntity.entity_patientSubscription)).doc(subId);
      final ledgerRef = firestore.collection('wallet_ledger').doc();

      await firestore.runTransaction((t) async {
        final clientSnap = await t.get(clientRef);
        if (!clientSnap.exists) throw Exception("Client not found");

        final wallet = clientSnap.data()!['wallet'] as Map<String, dynamic>? ?? {};
        final batches = wallet['batches'] as Map<String, dynamic>? ?? {};

        int creditsToRevoke = 0;
        if (batches.containsKey(subId)) {
          final batchData = batches[subId] as Map<String, dynamic>;
          creditsToRevoke = (batchData['balance'] as num?)?.toInt() ?? 0;
        }

        t.delete(subRef);

        Map<String, dynamic> clientUpdates = {};
        if (wasActive) {
          clientUpdates['currentPlan'] = FieldValue.delete();
          clientUpdates['planExpiry'] = FieldValue.delete();
        }
        if (creditsToRevoke > 0) {
          clientUpdates['wallet.available'] = FieldValue.increment(-creditsToRevoke);
        }
        clientUpdates['wallet.batches.$subId'] = FieldValue.delete();

        t.update(clientRef, clientUpdates);

        if (creditsToRevoke > 0) {
          t.set(ledgerRef, {
            'clientId': widget.client.id,
            'type': 'debit',
            'category': 'package_deletion',
            'amount': -creditsToRevoke,
            'description': 'Revoked credits due to deletion of: $packageName',
            'referenceId': subId,
            'timestamp': FieldValue.serverTimestamp(),
            'performedBy': 'Admin',
          });
        }
      });

      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Record deleted and credits revoked.")));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red));
    }
  }

  Future<void> _editSubscription(DocumentSnapshot doc) async {
    final data = doc.data() as Map<String, dynamic>;
    final sessionCtrl = TextEditingController(text: (data['sessionsRemaining'] ?? 0).toString());
    final freeCtrl = TextEditingController(text: (data['freeSessionsRemaining'] ?? 0).toString());
    DateTime expiryDate = (data['endDate'] as Timestamp).toDate();
    await showDialog(context: context, builder: (ctx) => StatefulBuilder(builder: (context, setState) { return AlertDialog(title: const Text("Correct Record"), content: Column(mainAxisSize: MainAxisSize.min, children: [TextField(controller: sessionCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Sessions Remaining")), const SizedBox(height: 12), TextField(controller: freeCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Free Sessions Remaining")), const SizedBox(height: 12), ListTile(title: const Text("Expiry Date"), subtitle: Text(DateFormat('dd MMM yyyy').format(expiryDate)), trailing: const Icon(Icons.edit_calendar), onTap: () async { final picked = await showDatePicker(context: context, initialDate: expiryDate, firstDate: DateTime(2020), lastDate: DateTime(2030)); if (picked != null) setState(() => expiryDate = picked); })]), actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")), ElevatedButton(onPressed: () async { Navigator.pop(ctx); final int newSessions = int.tryParse(sessionCtrl.text) ?? 0; final int newFree = int.tryParse(freeCtrl.text) ?? 0; final bool isActive = data['status'] == 'active'; await ref.read(firestoreProvider).collection(MasterCollectionMapper.getPath(TransactionEntity.entity_patientSubscription)).doc(doc.id).update({'sessionsRemaining': newSessions, 'freeSessionsRemaining': newFree, 'endDate': Timestamp.fromDate(expiryDate)}); if (isActive) { await ref.read(firestoreProvider).collection('clients').doc(widget.client.id).update({'planExpiry': Timestamp.fromDate(expiryDate), 'freeSessionsRemaining': newFree}); } if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Record updated."))); }, child: const Text("Save"))]); }));
  }

  Future<void> _openPaymentLedger(DocumentSnapshot doc, Map<String, dynamic> data, String planName, DateTime startDate, DateTime endDate, bool isActive, double bookedAmount) async {
    final assignmentModel = PackageAssignmentModel(
      id: doc.id,
      packageId: data['packageId'] ?? '',
      packageName: planName,
      purchaseDate: startDate,
      expiryDate: endDate,
      isActive: isActive,
      clientId: widget.client.id,
      bookedAmount: bookedAmount,
      category: 'Standard',
      isLocked: false,
      discount: 0.0,
    );
    await Navigator.push(context, MaterialPageRoute(builder: (_) => PaymentLedgerScreen(assignment: assignmentModel, clientName: widget.client.name, initialCollectedAmount: 0.0)));
  }

  Widget _buildMoneyColumn(String label, double amount, Color color) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.w600)), Text("₹${amount.toStringAsFixed(0)}", style: TextStyle(fontSize: 13, color: color, fontWeight: FontWeight.bold))]);
  }
  Widget _buildIconText(IconData icon, String text) {
    return Row(children: [Icon(icon, size: 14, color: Colors.grey), const SizedBox(width: 6), Flexible(child: Text(text, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87, fontSize: 12)))]);
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          const Text("No subscription history found.", style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 16),
          if (!widget.isReadOnly)
            ElevatedButton(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => PackageAssignmentPage(client: widget.client, sessionId: widget.sessionId))),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text("Assign Package Now"),
            )
        ],
      ),
    );
  }
}