import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:nutricare_client_management/admin/add_company_screen.dart';
import 'package:nutricare_client_management/admin/tenant_model.dart';
import 'package:url_launcher/url_launcher.dart';

class CompanyDetailScreen extends StatefulWidget {
  final TenantModel tenant;
  const CompanyDetailScreen({super.key, required this.tenant});

  @override
  State<CompanyDetailScreen> createState() => _CompanyDetailScreenState();
}

class _CompanyDetailScreenState extends State<CompanyDetailScreen> {
  bool _isLoading = false;

  // 📧 FEATURE: Send Welcome Email (Invite to Sign Up)
// 📧 FEATURE: Send Welcome Email (With Password Fetch)
  Future<void> _sendWelcomeEmail() async {
    setState(() => _isLoading = true);

    try {
      // 1. 🔍 Fetch the stored temp_password from user_directory
      final doc = await FirebaseFirestore.instance
          .collection('user_directory')
          .doc(widget.tenant.ownerEmail)
          .get();

      String passwordLine = "4. Please use 'Forgot Password' to set your initial password.\n";

      // 2. Check if temp_password exists
      if (doc.exists) {
        final data = doc.data();
        if (data != null && data.containsKey('temp_password')) {
          final tempPass = data['temp_password'];
          // Only show if it's not null/empty
          if (tempPass != null && tempPass.toString().isNotEmpty) {
            passwordLine = "4. Temporary Password: $tempPass\n   (You will be asked to change this upon login)\n";
          }
        }
      }

      // 3. Compose Email
      final String subject = Uri.encodeComponent("Welcome to NutriCare Wellness - Your Clinic is Ready!");
      final String body = Uri.encodeComponent(
          "Hello ${widget.tenant.ownerName},\n\n"
              "Your clinic '${widget.tenant.name}' has been successfully onboarded to the NutriCare platform.\n\n"
              "You can now access your dashboard.\n"
              "--------------------------------\n"
              "1. Download the Admin App.\n"
              "2. Click 'Login'.\n"
              "3. Email: ${widget.tenant.ownerEmail}\n"
              "$passwordLine"
              "--------------------------------\n\n"
              "Regards,\nNutriCare Admin Team"
      );

      // 4. Launch Email App
      final Uri emailUri = Uri.parse("mailto:${widget.tenant.ownerEmail}?subject=$subject&body=$body");

      try {
        await launchUrl(emailUri);
      } catch (e) {
        if (mounted) {
          // Fallback if no mail app is found
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Could not open email app.")));
        }
      }

    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error fetching credentials: $e")));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // 🔴 FEATURE: Suspend Tenant
  Future<void> _toggleSuspendStatus() async {
    final bool isCurrentlyActive = widget.tenant.status == 'active';
    final String newStatus = isCurrentlyActive ? 'suspended' : 'active';

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isCurrentlyActive ? "Suspend Clinic?" : "Activate Clinic?"),
        content: Text(isCurrentlyActive
            ? "This will prevent ${widget.tenant.name} staff from logging in."
            : "Access will be restored for ${widget.tenant.name}."
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: isCurrentlyActive ? Colors.red : Colors.green),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(isCurrentlyActive ? "Suspend" : "Activate"),
          )
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);
    try {
      await FirebaseFirestore.instance.collection('tenants').doc(widget.tenant.id).update({
        'status': newStatus,
      });
      if (mounted) {
        Navigator.pop(context); // Close screen to refresh list
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text("Clinic marked as $newStatus"),
            backgroundColor: isCurrentlyActive ? Colors.orange : Colors.green
        ));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // 🎨 Determine status color (Handle String status)
    final bool isActive = widget.tenant.status == 'active';
    final Color statusColor = isActive ? Colors.green : Colors.red;
    final String statusLabel = isActive ? "ACTIVE" : "SUSPENDED";

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text(widget.tenant.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            tooltip: "Edit Details",
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(
                builder: (_) => AddCompanyScreen(draftTenant: widget.tenant),
              ));
            },
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🏷️ HEADER CARD
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
              child: Row(
                children: [
                  Container(
                    width: 60, height: 60,
                    decoration: BoxDecoration(color: Colors.indigo.shade50, borderRadius: BorderRadius.circular(12)),
                    child: const Icon(Icons.business, color: Colors.indigo, size: 30),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.tenant.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                              child: Text(statusLabel, style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 10)),
                            ),
                            const SizedBox(width: 8),
                            Text("ID: ${widget.tenant.id}", style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ⚡ QUICK ACTIONS
            const Text("Quick Actions", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey)),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _sendWelcomeEmail,
                    icon: _isLoading
                        ? const SizedBox(width:16, height:16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.email_rounded),
                    label: const Text("Send Invite"),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 12)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isLoading ? null : _toggleSuspendStatus,
                    icon: Icon(isActive ? Icons.block : Icons.check_circle_outline),
                    label: Text(isActive ? "Suspend" : "Activate"),
                    style: OutlinedButton.styleFrom(
                        foregroundColor: isActive ? Colors.red : Colors.green,
                        side: BorderSide(color: isActive ? Colors.red : Colors.green),
                        padding: const EdgeInsets.symmetric(vertical: 12)
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // 📋 DETAILS SECTION
            const Text("Company Profile", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
              child: Column(
                children: [
                  _buildInfoRow("Owner Name", widget.tenant.ownerName),
                  const Divider(),
                  _buildInfoRow("Owner Email", widget.tenant.ownerEmail, copyable: true),
                  const Divider(),
                  _buildInfoRow("Phone", widget.tenant.ownerPhone),
                  const Divider(),
                  _buildInfoRow("Created On",
                      widget.tenant.createdAt != null // Handle Timestamp correctly
                          ? DateFormat.yMMMd().format(widget.tenant.createdAt!)
                          : "N/A"
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool copyable = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 120, child: Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13))),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14))),
          if (copyable)
            GestureDetector(
              onTap: () {
                Clipboard.setData(ClipboardData(text: value));
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Copied!"), duration: Duration(milliseconds: 600)));
              },
              child: const Icon(Icons.copy, size: 16, color: Colors.blue),
            )
        ],
      ),
    );
  }
}