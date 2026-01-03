import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:nutricare_client_management/admin/client_consultation_checlist_screen.dart';
import 'package:nutricare_client_management/admin/consultation_session_model.dart';
import 'package:nutricare_client_management/admin/consultation_session_service.dart';
import 'package:nutricare_client_management/modules/client/model/client_model.dart';

class ConsultationGatewayScreen extends ConsumerWidget {
  final ClientModel client;

  const ConsultationGatewayScreen({super.key, required this.client});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionService = ref.watch(consultationServiceProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      appBar: AppBar(
        title: const Text("Select Consultation Type", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Column(
        children: [
          // 🎯 1. HEADER: Patient Info & Fresh Start
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Column(
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    radius: 24,
                    backgroundImage: client.photoUrl != null ? NetworkImage(client.photoUrl!) : null,
                    child: client.photoUrl == null ? Text(client.name.isNotEmpty ? client.name[0] : 'C') : null,
                  ),
                  title: Text(client.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  subtitle: Text("ID: ${client.patientId}", style: const TextStyle(color: Colors.grey)),
                ),
                const SizedBox(height: 20),

                // "Start Fresh" Button
                InkWell(
                  onTap: () => _startFreshConsultation(context),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.teal.shade50,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.teal.shade200),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: const BoxDecoration(color: Colors.teal, shape: BoxShape.circle),
                          child: const Icon(Icons.add, color: Colors.white),
                        ),
                        const SizedBox(width: 16),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Start New Consultation", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.teal)),
                              Text("For a new medical complaint or issue", style: TextStyle(color: Colors.black54, fontSize: 12)),
                            ],
                          ),
                        ),
                        const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.teal),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 🎯 2. THREADED HISTORY LIST
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(20, 24, 20, 12),
                  child: Text("CONSULTATION HISTORY (THREADED)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey, letterSpacing: 1.0)),
                ),
                Expanded(
                  child: StreamBuilder<List<ConsultationSessionModel>>(
                    stream: sessionService.streamSessionHistory(client.id),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());

                      // 1. Get all Completed Sessions
                      final allSessions = (snapshot.data ?? []).where((s) => s.status == 'complete').toList();

                      if (allSessions.isEmpty) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(40),
                            child: Text("No past history found.\nPlease start a new consultation.",
                                textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade400)),
                          ),
                        );
                      }

                      // 2. Build Robust Threaded View
                      return _buildThreadedList(context, allSessions);
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 🎯 ROBUST HIERARCHY BUILDER
  Widget _buildThreadedList(BuildContext context, List<ConsultationSessionModel> allSessions) {
    // A. Index sessions for quick lookup
    final Set<String> allIds = allSessions.map((e) => e.id).toSet();

    // B. Identify Roots (Parents) and Children
    // A Root is any session that:
    // 1. Is 'Initial' type
    // 2. OR has a null parentId
    // 3. OR has a parentId that does NOT exist in the current list (Orphan)
    final List<ConsultationSessionModel> roots = [];
    final Map<String, List<ConsultationSessionModel>> childrenMap = {};

    for (var session in allSessions) {
      if (session.parentId != null && allIds.contains(session.parentId)) {
        // It is a valid child
        childrenMap.putIfAbsent(session.parentId!, () => []).add(session);
      } else {
        // It is a root (Initial or Orphan)
        roots.add(session);
      }
    }

    // C. Sort Roots by Date (Newest First)
    roots.sort((a, b) => b.sessionDate.compareTo(a.sessionDate));

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 40),
      itemCount: roots.length,
      itemBuilder: (context, index) {
        final root = roots[index];

        // Get children for this root
        final children = childrenMap[root.id] ?? [];
        // Sort Children: Newest First
        children.sort((a, b) => b.sessionDate.compareTo(a.sessionDate));

        return _buildConsultationThread(context, root, children);
      },
    );
  }

  Widget _buildConsultationThread(BuildContext context, ConsultationSessionModel parent, List<ConsultationSessionModel> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 🔹 PARENT CARD
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: _buildSessionCard(context, parent, isParent: true),
        ),

        // 🔹 CHILDREN CHAIN (Follow-ups)
        if (children.isNotEmpty)
          Stack(
            children: [
              // Visual Line
              Positioned(
                  left: 40,
                  top: 0,
                  bottom: 20,
                  child: Container(width: 2, color: Colors.grey.shade300)
              ),

              // List of Children
              Padding(
                padding: const EdgeInsets.only(left: 20, right: 20),
                child: Column(
                  children: children.map((child) => Padding(
                    padding: const EdgeInsets.only(top: 8, left: 24), // Indentation
                    child: _buildSessionCard(context, child, isParent: false),
                  )).toList(),
                ),
              ),
            ],
          ),

        const SizedBox(height: 12), // Spacing between threads
      ],
    );
  }

  Widget _buildSessionCard(BuildContext context, ConsultationSessionModel session, {required bool isParent}) {
    final date = session.sessionDate.toDate();
    final dateStr = DateFormat('dd MMM yyyy, hh:mm a').format(date);

    // Logic: Treat session as "Initial" if it is the root of the thread, even if data says 'Followup' (Orphan case)
    // But purely for UI, we trust the model's type.
    final bool isRealInitial = session.consultationType == 'Initial';
    final bool showFollowUpBtn = isParent && isRealInitial;

    // Calculate Expiry (Example: 15 days validity)
    final int daysLeft = showFollowUpBtn ? 15 - DateTime.now().difference(date).inDays : 0;
    final bool isExpired = daysLeft < 0;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: showFollowUpBtn ? Colors.indigo.shade100 : Colors.grey.shade200, width: showFollowUpBtn ? 1.5 : 1),
        boxShadow: showFollowUpBtn ? [BoxShadow(color: Colors.indigo.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))] : [],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isRealInitial ? Colors.indigo.shade50 : Colors.purple.shade50,
            shape: BoxShape.circle,
          ),
          child: Icon(
            isRealInitial ? Icons.flag_rounded : Icons.loop,
            color: isRealInitial ? Colors.indigo : Colors.purple,
            size: 18,
          ),
        ),
        title: Text(
            isRealInitial ? "Initial Consultation" : "Follow-up Visit",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: showFollowUpBtn ? 15 : 14)
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(dateStr, style: const TextStyle(fontSize: 12, color: Colors.black87)),

            // 🎯 Show Validity only on Parent Card
            if (showFollowUpBtn) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(isExpired ? Icons.cancel : Icons.check_circle, size: 12, color: isExpired ? Colors.red : Colors.green),
                  const SizedBox(width: 4),
                  Text(
                    isExpired ? "Expired" : "$daysLeft days valid",
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: isExpired ? Colors.red : Colors.green),
                  ),
                ],
              ),
            ]
          ],
        ),
        // 🎯 Logic: Follow-up button ONLY on Real Initials
        trailing: showFollowUpBtn
            ? ElevatedButton(
          onPressed: () => _startFollowUp(context, session),
          style: ElevatedButton.styleFrom(
            backgroundColor: isExpired ? Colors.grey : Colors.indigo,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            elevation: 0,
          ),
          child: const Text("Follow Up", style: TextStyle(fontSize: 11, color: Colors.white)),
        )
            : null,
      ),
    );
  }

  // --- ACTIONS ---

  void _startFreshConsultation(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ClientConsultationChecklistScreen(
          client: client,
          forceNew: true,
          isFollowup: false,
          parentSessionId: null,
        ),
      ),
    );
  }

  void _startFollowUp(BuildContext context, ConsultationSessionModel parentSession) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ClientConsultationChecklistScreen(
          client: client,
          forceNew: true,
          isFollowup: true,
          parentSessionId: parentSession.id, // 🎯 Links child to this parent
        ),
      ),
    );
  }
}