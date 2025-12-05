import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:nutricare_client_management/modules/client/model/client_model.dart';
import 'package:nutricare_client_management/screens/package_assignment_page.dart';

class ClientPackageListScreen extends StatefulWidget {
  final ClientModel client;

  const ClientPackageListScreen({super.key, required this.client});

  @override
  State<ClientPackageListScreen> createState() => _ClientPackageListScreenState();
}

class _ClientPackageListScreenState extends State<ClientPackageListScreen> {

  // --- ACTIONS ---

  Future<void> _deleteSubscription(String subId, String packageName, bool wasActive) async {
    final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text("Delete Record?"),
          content: Text("Are you sure you want to remove '$packageName'?\n\nThis action cannot be undone."),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancel")),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text("Delete Forever"),
            )
          ],
        )
    );

    if (confirm == true) {
      await FirebaseFirestore.instance.collection('subscriptions').doc(subId).delete();

      // If we deleted the active plan, clear the client profile
      if (wasActive) {
        await FirebaseFirestore.instance.collection('clients').doc(widget.client.id).update({
          'currentPlan': FieldValue.delete(),
          'planExpiry': FieldValue.delete(),
          'clientType': 'lead', // Revert to lead
          'freeSessionsRemaining': 0,
        });
      }

      if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Record deleted.")));
    }
  }

  Future<void> _editSubscription(DocumentSnapshot doc) async {
    final data = doc.data() as Map<String, dynamic>;

    // Controllers for correction
    final sessionCtrl = TextEditingController(text: (data['sessionsRemaining'] ?? 0).toString());
    final freeCtrl = TextEditingController(text: (data['freeSessionsRemaining'] ?? 0).toString());
    DateTime expiryDate = (data['endDate'] as Timestamp).toDate();

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text("Correct Record"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: sessionCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: "Sessions Remaining", border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: freeCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: "Free Sessions Remaining", border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),
                  ListTile(
                    title: const Text("Expiry Date"),
                    subtitle: Text(DateFormat('dd MMM yyyy').format(expiryDate)),
                    trailing: const Icon(Icons.edit_calendar),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: expiryDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2030),
                      );
                      if (picked != null) setState(() => expiryDate = picked);
                    },
                    tileColor: Colors.grey.shade100,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  )
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
                ElevatedButton(
                  onPressed: () async {
                    Navigator.pop(ctx);

                    final int newSessions = int.tryParse(sessionCtrl.text) ?? 0;
                    final int newFree = int.tryParse(freeCtrl.text) ?? 0;
                    final bool isActive = data['status'] == 'active';

                    // Update Subscription
                    await FirebaseFirestore.instance.collection('subscriptions').doc(doc.id).update({
                      'sessionsRemaining': newSessions,
                      'freeSessionsRemaining': newFree,
                      'endDate': Timestamp.fromDate(expiryDate),
                    });

                    // Sync Client Profile if active
                    if (isActive) {
                      await FirebaseFirestore.instance.collection('clients').doc(widget.client.id).update({
                        'planExpiry': Timestamp.fromDate(expiryDate),
                        'freeSessionsRemaining': newFree,
                      });
                    }

                    if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Record updated.")));
                  },
                  child: const Text("Save Corrections"),
                )
              ],
            );
          }
      ),
    );
  }

  // --- UI BUILDER ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Subscription History", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text(widget.client.name, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle, color: Colors.indigo),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => PackageAssignmentPage(client: widget.client))),
          )
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('subscriptions')
            .where('clientId', isEqualTo: widget.client.id)
            .orderBy('createdAt', descending: true)
            .snapshots(),
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
                  const Text("No packages assigned yet.", style: TextStyle(color: Colors.grey)),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => PackageAssignmentPage(client: widget.client))),
                    child: const Text("Assign New Package"),
                  )
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 16),
            itemBuilder: (context, index) => _buildSubscriptionCard(docs[index]),
          );
        },
      ),
    );
  }

  Widget _buildSubscriptionCard(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    // Parse Basic Data
    final String planName = data['packageName'] ?? 'Unknown Plan';
    final double price = (data['price'] as num?)?.toDouble() ?? 0.0;
    final String status = data['status'] ?? 'expired';
    final DateTime startDate = (data['startDate'] as Timestamp).toDate();
    final DateTime endDate = (data['endDate'] as Timestamp).toDate();

    // Parse Offers
    final int extraDays = data['offerExtraDays'] ?? 0;
    final int extraSessions = data['offerExtraSessions'] ?? 0;

    // Parse Usage
    final int totalSessions = data['sessionsTotal'] ?? 0;
    final int currentSessions = data['sessionsRemaining'] ?? 0;

    final int totalFree = data['freeSessionsTotal'] ?? 0;
    final int currentFree = data['freeSessionsRemaining'] ?? 0;

    final List<String> inclusions = List<String>.from(data['inclusions'] ?? []);

    // 🎯 SMART COLOR CODING
    final bool isActuallyActive = status == 'active' && endDate.isAfter(DateTime.now());
    Color statusColor;
    String statusLabel;

    if (isActuallyActive) {
      statusColor = Colors.green;
      statusLabel = "ACTIVE";
    } else if (status == 'active' && endDate.isBefore(DateTime.now())) {
      // Technically active in DB but dates passed
      statusColor = Colors.red;
      statusLabel = "EXPIRED";
    } else {
      statusColor = Colors.grey;
      statusLabel = status.toUpperCase();
    }

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
          // 1. HEADER (Title + Actions)
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
                          const SizedBox(width: 8),
                          Text("₹${price.toStringAsFixed(0)}", style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.indigo)),
                        ],
                      ),
                    ],
                  ),
                ),
                // 🎯 ACTION MENU
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, color: Colors.grey),
                  onSelected: (val) {
                    if (val == 'edit') _editSubscription(doc);
                    if (val == 'delete') _deleteSubscription(doc.id, planName, isActuallyActive);
                  },
                  itemBuilder: (ctx) => [
                    const PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit, size: 18), SizedBox(width: 8), Text("Correct Data")])),
                    const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete, size: 18, color: Colors.red), SizedBox(width: 8), Text("Delete Record", style: TextStyle(color: Colors.red))])),
                  ],
                )
              ],
            ),
          ),
          const Divider(height: 1),

          // 2. DATES & OFFERS
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildIconText(Icons.calendar_today, "${DateFormat('dd MMM').format(startDate)} - ${DateFormat('dd MMM yyyy').format(endDate)}"),
                    if (extraDays > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(4), border: Border.all(color: Colors.orange.shade100)),
                        child: Text("+ $extraDays Days Added", style: TextStyle(fontSize: 10, color: Colors.orange.shade800, fontWeight: FontWeight.bold)),
                      )
                  ],
                ),
                const SizedBox(height: 12),

                // USAGE STATS
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(8)),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStat("Consultations", "$currentSessions / $totalSessions", Colors.blue),
                      Container(width: 1, height: 20, color: Colors.grey.shade300),
                      _buildStat("Free Sessions", "$currentFree / $totalFree", Colors.green),
                      if (extraSessions > 0) ...[
                        Container(width: 1, height: 20, color: Colors.grey.shade300),
                        _buildStat("Bonus Applied", "+$extraSessions", Colors.orange),
                      ]
                    ],
                  ),
                ),
              ],
            ),
          ),

          // 3. INCLUSIONS
          if (inclusions.isNotEmpty) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Package Inclusions:", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: inclusions.map((inc) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: Colors.indigo.shade50, borderRadius: BorderRadius.circular(20)),
                      child: Text(inc, style: TextStyle(fontSize: 11, color: Colors.indigo.shade700, fontWeight: FontWeight.bold)),
                    )).toList(),
                  )
                ],
              ),
            )
          ]
        ],
      ),
    );
  }

  Widget _buildIconText(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey),
        const SizedBox(width: 8),
        Text(text, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87, fontSize: 13)),
      ],
    );
  }

  Widget _buildStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
      ],
    );
  }
}