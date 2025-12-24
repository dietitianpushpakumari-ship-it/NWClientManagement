import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
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
    // 🎯 Logic: Directly query subscriptions. No need to fetch session first.
    return _buildScaffold(context);
  }

  Widget _buildScaffold(BuildContext context) {
    Stream<QuerySnapshot> getStream() {
      final collection = ref.watch(firestoreProvider)
          .collection(MasterCollectionMapper.getPath(TransactionEntity.entity_patientSubscription));

      // 🎯 Case 1: Session Mode (Checklist)
      // Show ONLY packages created during this specific session
      if (widget.sessionId != null && widget.sessionId!.isNotEmpty) {
        return collection
            .where('sessionId', isEqualTo: widget.sessionId)
            .orderBy('createdAt', descending: true)
            .snapshots();
      }

      // 🎯 Case 2: History Mode (Client Profile)
      // Show ALL packages for this client
      return collection
          .where('clientId', isEqualTo: widget.client.id)
          .orderBy('createdAt', descending: true)
          .snapshots();
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
                widget.sessionId != null ? "Session Packages" : "Subscription History",
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)
            ),
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
        stream: getStream(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final docs = snapshot.data!.docs;

          if (docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  Text(
                      widget.sessionId != null
                          ? "No packages booked in this session."
                          : "No subscription history found.",
                      style: const TextStyle(color: Colors.grey)
                  ),
                  const SizedBox(height: 16),

                  // Show Assign Button if not read-only
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
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 80),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 16),
            itemBuilder: (context, index) => _buildSubscriptionCard(docs[index]),
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

  Widget _buildSubscriptionCard(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final String packageId = data['packageId'] ?? '';
    final String planName = data['packageName'] ?? 'Unknown Plan';
    final double price = (data['price'] as num?)?.toDouble() ?? 0.0;
    final double bookedAmount = (data['bookedAmount'] as num?)?.toDouble() ?? price;
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
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                            child: Text("● $statusLabel", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: statusColor)),
                          ),
                          if (extraDays > 0) ...[
                            const SizedBox(width: 8),
                            Text("+ $extraDays Days", style: TextStyle(fontSize: 11, color: Colors.orange.shade800, fontWeight: FontWeight.bold)),
                          ]
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.info_outline, color: Colors.indigo),
                  tooltip: "View Package Details",
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
                final isPaid = pending <= 0.01;
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
                    ClipRRect(borderRadius: BorderRadius.circular(4), child: LinearProgressIndicator(value: progress, backgroundColor: Colors.grey.shade200, color: isPaid ? Colors.green : Colors.orange, minHeight: 4))
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
      colorCode: null,
    );
    Navigator.push(context, MaterialPageRoute(builder: (_) => PackageDetailScreen(package: fallbackPackage)));
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Original plan deleted. Showing archived details."), backgroundColor: Colors.orange));
  }

  Future<void> _deleteSubscription(String subId, String packageName, bool wasActive) async {
    final confirm = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(title: const Text("Delete Record?"), content: Text("Are you sure you want to remove '$packageName'?\n\nThis action cannot be undone."), actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancel")), ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white), onPressed: () => Navigator.pop(ctx, true), child: const Text("Delete Forever"))]));
    if (confirm == true) {
      await ref.read(firestoreProvider).collection(MasterCollectionMapper.getPath(TransactionEntity.entity_patientSubscription)).doc(subId).delete();
      if (wasActive) {
        await ref.read(firestoreProvider).collection('clients').doc(widget.client.id).update({'currentPlan': FieldValue.delete(), 'planExpiry': FieldValue.delete(), 'clientType': 'lead', 'freeSessionsRemaining': 0});
      }
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Record deleted.")));
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
}