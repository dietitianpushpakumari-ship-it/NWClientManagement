import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// 🎯 Project Imports
import 'package:nutricare_client_management/modules/client/model/client_model.dart';
import 'package:nutricare_client_management/image_compressor.dart';
import 'package:nutricare_client_management/modules/package/model/package_assignment_model.dart';
import 'package:nutricare_client_management/admin/database_provider.dart';
import 'package:nutricare_client_management/master/model/master_constants.dart';
import 'package:nutricare_client_management/screens/dash/client-personal_info_sheet.dart';

// 🎯 PROVIDER: Fetch Active Package for Badge
final activePackageProvider = StreamProvider.family.autoDispose<PackageAssignmentModel?, String>((ref, clientId) {
  return ref.read(firestoreProvider)
      .collection(MasterCollectionMapper.getPath(TransactionEntity.entity_patientSubscription))
      .where('clientId', isEqualTo: clientId)
      .where('status', isEqualTo: 'active')
      .snapshots()
      .map((snapshot) {
    if (snapshot.docs.isEmpty) return null;
    final packages = snapshot.docs.map((d) {
      try { return PackageAssignmentModel.fromFirestore(d); } catch (e) { return null; }
    }).whereType<PackageAssignmentModel>().toList();

    final now = DateTime.now();
    final validPackages = packages.where((p) => p.expiryDate.isAfter(now)).toList();
    if (validPackages.isEmpty) return null;

    // Sort by latest expiry
    validPackages.sort((a, b) => b.expiryDate.compareTo(a.expiryDate));
    return validPackages.first;
  });
});

class ClientProfileTab extends ConsumerStatefulWidget {
  final ClientModel client;
  final VoidCallback onRefresh; // Callback to refresh parent dashboard

  const ClientProfileTab({super.key, required this.client, required this.onRefresh});

  @override
  ConsumerState<ClientProfileTab> createState() => _ClientProfileTabState();
}

class _ClientProfileTabState extends ConsumerState<ClientProfileTab> {
  bool _isUploading = false;

  // 🎯 IMAGE PICKER & UPLOAD LOGIC
  Future<void> _pickAndUploadImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final XFile? pickedFile = await picker.pickImage(source: source);

      if (pickedFile == null) return;

      setState(() => _isUploading = true);

      // 1. Compress Image
      final File originalFile = File(pickedFile.path);
      final File? compressedFile = await ImageCompressor.compressAndGetFile(originalFile);

      if (compressedFile == null) throw "Image compression failed";

      // 2. Upload to Firebase Storage
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('client_photos')
          .child('${widget.client.id}_profile.webp');

      final uploadTask = storageRef.putFile(
        compressedFile,
        SettableMetadata(contentType: 'image/webp'),
      );

      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();

      // 3. Update Firestore
      await FirebaseFirestore.instance
          .collection('clients')
          .doc(widget.client.id)
          .update({'photoUrl': downloadUrl});

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Profile photo updated!")));
        widget.onRefresh(); // Refresh parent to show new image
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Upload failed: $e")));
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  void _showImagePickerOptions() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Pick from Gallery'),
              onTap: () {
                Navigator.pop(ctx);
                _pickAndUploadImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take a Photo'),
              onTap: () {
                Navigator.pop(ctx);
                _pickAndUploadImage(ImageSource.camera);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _openPersonalInfoSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ClientPersonalInfoSheet(
        client: widget.client,
        onSave: (updated) {
          setState(() {}); // Local rebuild
          widget.onRefresh(); // Parent refresh
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Watch subscription for badge
    final packageAsync = ref.watch(activePackageProvider(widget.client.id));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // 1. IDENTITY CARD
          Stack(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [BoxShadow(color: Theme.of(context).colorScheme.primary.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, 8))],
                ),
                child: Column(
                  children: [
                    // Avatar with Upload Indicator
                    GestureDetector(
                      onTap: _showImagePickerOptions,
                      child: Stack(
                        children: [
                          CircleAvatar(
                            radius: 50,
                            backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(.1),
                            backgroundImage: widget.client.photoUrl != null ? NetworkImage(widget.client.photoUrl!) : null,
                            child: _isUploading
                                ? const CircularProgressIndicator()
                                : (widget.client.photoUrl == null ? Text(widget.client.name[0], style: const TextStyle(fontSize: 40)) : null),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: const BoxDecoration(color: Colors.blue, shape: BoxShape.circle),
                              child: const Icon(Icons.camera_alt, color: Colors.white, size: 16),
                            ),
                          )
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(widget.client.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                    Text("PID: ${widget.client.patientId ?? 'N/A'}", style: TextStyle(color: Colors.grey.shade600)),

                    const SizedBox(height: 12),

                    // 🎯 SUBSCRIPTION BADGE
                    packageAsync.when(
                      data: (pkg) {
                        if (pkg == null) return const SizedBox.shrink();

                        // Determine Color & Label
                        Color badgeColor = Colors.grey;
                        String label = "MEMBER";

                        if (pkg.colorCode != null) {
                          badgeColor = Color(int.parse(pkg.colorCode!));
                        } else {
                          final cat = (pkg.category ?? '').toLowerCase();
                          if (cat.contains('premium')) badgeColor = Colors.purple;
                          else if (cat.contains('standard')) badgeColor = Colors.teal;
                          else if (cat.contains('basic')) badgeColor = Colors.orange;
                        }

                        if (pkg.category != null && pkg.category!.isNotEmpty) {
                          label = "${pkg.category!.toUpperCase()} MEMBER";
                        }
                        if (pkg.type != null && pkg.type!.isNotEmpty) {
                          label += " • ${pkg.type!.toUpperCase()}";
                        }

                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: badgeColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: badgeColor.withOpacity(0.3)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.workspace_premium, size: 16, color: badgeColor),
                              const SizedBox(width: 6),
                              Text(label, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: badgeColor)),
                            ],
                          ),
                        );
                      },
                      loading: () => const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                      error: (_, __) => const SizedBox.shrink(),
                    ),
                  ],
                ),
              ),
              Positioned(top: 10, right: 10, child: IconButton(icon: Icon(Icons.edit, color: Theme.of(context).colorScheme.primary), onPressed: _openPersonalInfoSheet)),
            ],
          ),
          const SizedBox(height: 20),

          // 2. Personal Info
          _buildInfoCard(
            title: "Personal & Contact",
            icon: Icons.person,
            color: Colors.purple,
            children: [
              _buildInfoRow(Icons.male, "Gender", widget.client.gender),
              _buildInfoRow(Icons.cake, "DOB", widget.client.dob != null ? DateFormat('dd MMM yyyy').format(widget.client.dob) : "N/A"),
              _buildInfoRow(Icons.phone, "Mobile", widget.client.mobile),
              _buildInfoRow(FontAwesomeIcons.whatsapp, "WhatsApp", widget.client.whatsappNumber ?? "N/A"),
              _buildInfoRow(Icons.email, "Email", widget.client.email),
              _buildInfoRow(Icons.location_on, "Address", widget.client.address ?? "N/A", maxLines: 2),
            ],
            action: IconButton(icon: const Icon(Icons.edit, color: Colors.purple), onPressed: _openPersonalInfoSheet),
          ),
          const SizedBox(height: 20),

          // 3. Security
          _buildInfoCard(
            title: "Security",
            icon: Icons.lock,
            color: Colors.orange,
            children: [
              _buildInfoRow(Icons.vpn_key, "Login ID", widget.client.loginId),
              _buildInfoRow(Icons.shield, "Access", widget.client.status == 'Active' ? "Granted" : "Blocked"),
            ],
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildInfoCard({required String title, required IconData icon, required Color color, required List<Widget> children, Widget? action}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 15, offset: const Offset(0, 5))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(children: [Icon(icon, color: color, size: 20), const SizedBox(width: 10), Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87))]),
              if (action != null) action,
            ],
          ),
          const Divider(height: 24),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, {int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 24, child: Icon(icon, size: 16, color: Colors.grey.shade400)),
          const SizedBox(width: 12),
          Text("$label: ", style: TextStyle(fontSize: 13, color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87), maxLines: maxLines, overflow: TextOverflow.ellipsis)),
        ],
      ),
    );
  }
}