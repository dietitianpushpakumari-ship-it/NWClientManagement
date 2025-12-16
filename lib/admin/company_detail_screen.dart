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

  // 📧 FEATURE: Fetch Password & Open Email
  Future<void> _resendActivationLink() async {
    setState(() => _isLoading = true);

    try {
      // 1. Fetch stored credentials from user_directory
      final doc = await FirebaseFirestore.instance
          .collection('user_directory')
          .doc(widget.tenant.ownerEmail)
          .get();

      final data = doc.data();
      final String? storedPassword = data?['temp_password'];

      if (storedPassword == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text("⚠️ Original temp password not found. Please reset password manually in Firebase Console."),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 4),
          ));
        }
        return;
      }

      // 2. Prepare Email Content
      final String subject = Uri.encodeComponent("Login Credentials for ${widget.tenant.name}");
      final String body = Uri.encodeComponent(
          "Hello ${widget.tenant.ownerName},\n\n"
              "Here are your login details for NutriCare Wellness:\n\n"
              "--------------------------------\n"
              "Email: ${widget.tenant.ownerEmail}\n"
              "Password: $storedPassword\n"
              "--------------------------------\n\n"
              "Please log in and change your password immediately.\n\n"
              "Regards,\nNutriCare Admin Team"
      );

      // 3. Launch Gmail
      final Uri emailUri = Uri.parse("mailto:${widget.tenant.ownerEmail}?subject=$subject&body=$body");

      try {
        await launchUrl(emailUri);
      } catch (e) {
        // Fallback if mail app doesn't open
        if (mounted) _showManualCopyDialog(storedPassword);
      }

    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showManualCopyDialog(String password) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Share Credentials"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Could not open email app. Please copy manually:"),
            const SizedBox(height: 16),
            _buildInfoRow("Email", widget.tenant.ownerEmail, copyable: true),
            const SizedBox(height: 10),
            _buildInfoRow("Password", password, copyable: true),
          ],
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Close"))],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Determine status color
    Color statusColor = widget.tenant.status == TenantStatus.active ? Colors.green : Colors.orange;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text(widget.tenant.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            tooltip: "Edit Details",
            onPressed: () {
              // Navigate to Edit Screen
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
                              child: Text(widget.tenant.status.name.toUpperCase(), style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 10)),
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
                    onPressed: _isLoading ? null : _resendActivationLink,
                    icon: _isLoading ? const SizedBox(width:16, height:16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.send_rounded),
                    label: const Text("Resend Invite"),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 12)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      // Placeholder for future feature
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Suspend feature coming soon!")));
                    },
                    icon: const Icon(Icons.block),
                    label: const Text("Suspend"),
                    style: OutlinedButton.styleFrom(foregroundColor: Colors.red, side: const BorderSide(color: Colors.red), padding: const EdgeInsets.symmetric(vertical: 12)),
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
                  _buildInfoRow("Onboarded On", widget.tenant.invitedAt != null ? DateFormat.yMMMd().format(widget.tenant.invitedAt!) : "N/A"),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ⚙️ TECHNICAL CONFIG
            ExpansionTile(
              title: const Text("Technical Configuration", style: TextStyle(fontWeight: FontWeight.bold)),
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  color: Colors.white,
                  child: Column(
                    children: [
                      _buildInfoRow("Project ID", widget.tenant.projectId, copyable: true),
                      const SizedBox(height: 10),
                      _buildInfoRow("API Key", widget.tenant.apiKey, copyable: true),
                    ],
                  ),
                )
              ],
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