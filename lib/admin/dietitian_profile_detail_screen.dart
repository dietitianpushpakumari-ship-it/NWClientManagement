import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:nutricare_client_management/admin/admin_profile_model.dart';
import 'package:url_launcher/url_launcher.dart';

class DietitianProfileDetailScreen extends StatelessWidget {
  final AdminProfileModel profile;

  const DietitianProfileDetailScreen({super.key, required this.profile});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      body: Stack(
        children: [
          // 1. Ambient Background
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.teal.withOpacity(0.1),
                    blurRadius: 100,
                    spreadRadius: 40,
                  )
                ],
              ),
            ),
          ),

          CustomScrollView(
            slivers: [
              // 2. Hero Header (Cover Image + Avatar)
              SliverAppBar(
                expandedHeight: 320,
                backgroundColor: Colors.white,
                elevation: 0,
                pinned: true,
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Gradient Cover
                      Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xFF1A237E), Color(0xFF3949AB)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                      ),
                      // Decorative Circles
                      Positioned(
                        top: -50,
                        right: -50,
                        child: Container(
                          width: 200,
                          height: 200,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.05),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),

                      // Avatar Centered
                      Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(height: 40), // Push down from status bar
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                shape: BoxShape.circle,
                              ),
                              child: CircleAvatar(
                                radius: 60,
                                backgroundColor: Colors.white,
                                backgroundImage: profile.photoUrl.isNotEmpty
                                    ? NetworkImage(profile.photoUrl)
                                    : null,
                                child: profile.photoUrl.isEmpty
                                    ? Text(
                                  profile.firstName.isNotEmpty ? profile.firstName[0] : 'D',
                                  style: const TextStyle(
                                    fontSize: 50,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF3949AB),
                                  ),
                                )
                                    : null,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              "${profile.firstName} ${profile.lastName}",
                              style: const TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              profile.designation,
                              style: const TextStyle(
                                fontSize: 15,
                                color: Colors.white70,
                                fontWeight: FontWeight.w500,
                              ),
                            ),

                            // Quick Stats Row
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                if (profile.experienceYears > 0)
                                  _buildHeaderBadge(Icons.workspace_premium, "${profile.experienceYears}+ Yrs Exp"),
                                // Fallback if languages list is empty/null or just want to show something
                                // if (profile.languages.isNotEmpty) ...
                                //   _buildHeaderBadge(Icons.translate, profile.languages.take(2).join("/")),
                              ],
                            )
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 3. Content
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // A. About Me
                      if (profile.bio.isNotEmpty) ...[
                        _buildSectionTitle("About Me"),
                        _buildCard(
                          child: Text(
                            profile.bio,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade700,
                              height: 1.5,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],

                      // B. Credentials (Education & Certs)
                      if (profile.qualifications.isNotEmpty) ...[
                        _buildSectionTitle("Credentials"),
                        _buildCard(
                          child: Column(
                            children: [
                              ...profile.qualifications.map((edu) => _buildCredentialRow(Icons.school, edu)),
                              // If you have certifications field in model, map it here too
                              // ...profile.certifications.map((cert) => _buildCredentialRow(Icons.verified, cert, color: Colors.orange)),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],

                      // C. Expertise
                      _buildSectionTitle("Areas of Expertise"),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.03),
                              blurRadius: 10,
                            )
                          ],
                        ),
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: (profile.specializations.isNotEmpty
                              ? profile.specializations
                              : ["General Wellness"])
                              .map((spec) => Chip(
                            label: Text(
                              spec,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.indigo,
                                fontSize: 12,
                              ),
                            ),
                            backgroundColor: Colors.indigo.shade50,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                              side: BorderSide.none,
                            ),
                          ))
                              .toList(),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // D. Contact Info
                      _buildSectionTitle("Contact Information"),
                      _buildCard(
                        child: Column(
                          children: [
                            if (profile.companyName.isNotEmpty)
                              _buildContactRow(Icons.business, "Clinic", profile.companyName),
                            _buildContactRow(
                              Icons.email,
                              "Email",
                              profile.companyEmail.isNotEmpty ? profile.companyEmail : profile.email,
                              onTap: () => _launch("mailto:${profile.email}"),
                            ),
                            _buildContactRow(
                              Icons.phone,
                              "Phone",
                              profile.mobile,
                              onTap: () => _launch("tel:${profile.mobile}"),
                            ),
                            if (profile.website.isNotEmpty)
                              _buildContactRow(
                                Icons.language,
                                "Website",
                                profile.website,
                                onTap: () => _launch(profile.website),
                              ),
                            if (profile.address!.isNotEmpty)
                              _buildContactRow(Icons.location_on, "Address", profile.address!),
                          ],
                        ),
                      ),

                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              )
            ],
          )
        ],
      ),
    );
  }

  // --- WIDGET HELPERS ---

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Color(0xFF1A1A1A),
        ),
      ),
    );
  }

  Widget _buildCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
          )
        ],
      ),
      child: child,
    );
  }

  Widget _buildHeaderBadge(IconData icon, String text) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 14),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCredentialRow(IconData icon, String text, {Color color = Colors.indigo}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
        ),
      ]),
    );
  }

  Widget _buildContactRow(IconData icon, String label, String value, {VoidCallback? onTap}) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.indigo.shade50,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.indigo, size: 18),
      ),
      title: Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      subtitle: Text(
        value,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87),
      ),
      trailing: onTap != null
          ? const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey)
          : null,
      onTap: onTap,
      dense: true,
    );
  }

  Future<void> _launch(String url) async {
    final uri = Uri.parse(url);
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {}
  }
}