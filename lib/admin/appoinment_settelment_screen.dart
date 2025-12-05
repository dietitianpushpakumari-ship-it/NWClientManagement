import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // For receivedBy
import 'package:intl/intl.dart';
import 'package:nutricare_client_management/admin/appointment_model.dart';
import 'package:nutricare_client_management/modules/package/service/package_payment_service.dart';

class AppointmentSettlementScreen extends StatefulWidget {
  const AppointmentSettlementScreen({super.key});

  @override
  State<AppointmentSettlementScreen> createState() => _AppointmentSettlementScreenState();
}

class _AppointmentSettlementScreenState extends State<AppointmentSettlementScreen> {
  final PackagePaymentService _service = PackagePaymentService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      appBar: AppBar(
        title: const Text("Payment Reconciliation"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: StreamBuilder<List<AppointmentModel>>(
        stream: _service.streamUnsettledAppointments(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }

          final list = snapshot.data ?? [];

          if (list.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle_outline, size: 64, color: Colors.green.shade200),
                  const SizedBox(height: 16),
                  const Text("All payments settled!", style: TextStyle(fontSize: 16, color: Colors.grey, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  const Text("No pending confirmations found.", style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: list.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              return _buildSettlementCard(list[index]);
            },
          );
        },
      ),
    );
  }

  Widget _buildSettlementCard(AppointmentModel appt) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
        border: Border(left: BorderSide(color: Colors.orange.shade400, width: 4)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(DateFormat('dd MMM yyyy, h:mm a').format(appt.startTime), style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(8)),
                  child: const Text("Action Required", style: TextStyle(fontSize: 10, color: Colors.orange, fontWeight: FontWeight.bold)),
                )
              ],
            ),
            const SizedBox(height: 12),

            // Client & Amount
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.indigo.shade50,
                  child: Text(appt.clientName.isNotEmpty ? appt.clientName[0] : '?', style: const TextStyle(color: Colors.indigo, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(appt.clientName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      Text(appt.topic, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text("₹${appt.amountPaid?.toStringAsFixed(0) ?? '0'}", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green)),
                    Text(appt.paymentMethod ?? "Unknown", style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                )
              ],
            ),
            const Divider(height: 24),

            // Actions
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _showVerificationDialog(appt),
                icon: const Icon(Icons.price_check),
                label: const Text("VERIFY & POST TO LEDGER"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  void _showVerificationDialog(AppointmentModel appt) {
    final amountCtrl = TextEditingController(text: appt.amountPaid?.toString() ?? "0");
    final refCtrl = TextEditingController(text: appt.paymentReferenceId ?? "");
    final noteCtrl = TextEditingController();

    // We use StatefulBuilder to manage the checkbox state inside the dialog
    bool isVerified = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text("Confirm Receipt"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(8)),
                  child: const Text("Ensure you have physically received the cash or verified the bank transaction before posting.", style: TextStyle(fontSize: 12, color: Colors.blue)),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: amountCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: "Final Amount Received (₹)", border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: refCtrl,
                  decoration: const InputDecoration(labelText: "Payment Ref / Transaction ID", border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: noteCtrl,
                  decoration: const InputDecoration(labelText: "Notes (Optional)", border: OutlineInputBorder()),
                ),
                const SizedBox(height: 16),
                CheckboxListTile(
                  value: isVerified,
                  onChanged: (v) => setDialogState(() => isVerified = v!),
                  title: const Text("I verify that funds are received.", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  activeColor: Colors.green,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
            ElevatedButton(
              onPressed: isVerified ? () async {
                Navigator.pop(ctx);
                try {
                  await _service.postSettlement(
                    appointment: appt,
                    finalAmount: double.tryParse(amountCtrl.text) ?? 0,
                    paymentMode: appt.paymentMethod ?? 'Cash',
                    paymentRef: refCtrl.text,
                    narration: noteCtrl.text,
                  );
                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Posted to Ledger!"), backgroundColor: Colors.green));
                } catch (e) {
                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red));
                }
              } : null,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
              child: const Text("POST"),
            )
          ],
        ),
      ),
    );
  }
}