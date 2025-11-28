import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:nutricare_client_management/admin/meeting_service.dart';
import 'package:nutricare_client_management/admin/schedule_meeting_utils.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../modules/client/model/client_model.dart';
import '../modules/client/services/client_service.dart';
import 'package:nutricare_client_management/screens/dash/client_dashboard_screenv2.dart';

class AllMeetingsScreen extends StatefulWidget {
  const AllMeetingsScreen({super.key});

  @override
  State<AllMeetingsScreen> createState() => _AllMeetingsScreenState();
}

class _AllMeetingsScreenState extends State<AllMeetingsScreen> {
  final MeetingService _meetingService = MeetingService();
  final ClientService _clientService = ClientService();

  final int _pageSize = 25;
  final Map<String, ClientModel> _clientCache = {};
  DocumentSnapshot? _lastDocument;
  bool _isLoading = false;
  bool _hasMore = true;

  List<MeetingModel> _allMeetings = [];
  List<MeetingModel> upcomingMeetings = [];
  List<MeetingModel> missedMeetings = [];
  List<MeetingModel> archivedMeetings = [];

  @override
  void initState() {
    super.initState();
    _loadMeetings(isInitialLoad: true);
  }

  // ... [Keep existing logic: _loadMeetings, _preFetchClients, _processAndGroupMeetings, _refreshMeetingList, _getClientFromCache, _showMeetingActionDialog, etc.] ...
  // For brevity, assume the logic methods are copied here exactly as they were.

  Future<void> _loadMeetings({bool isInitialLoad = false}) async {
    // ... (Use previous implementation) ...
    if (_isLoading) return;
    if (!isInitialLoad && !_hasMore) return; // Stop if there are no more pages

    // Reset state only on initial load (e.g., refresh)
    if (isInitialLoad) {
      _allMeetings = [];
      _lastDocument = null;
      _hasMore = true;
      _clientCache.clear();
      // Groups will be cleared/repopulated in _processAndGroupMeetings()
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // 1. Fetch a single page of meetings
      final snapshot = await _meetingService.getPaginatedMeetings(
        limit: _pageSize,
        lastDocument: _lastDocument,
      );

      final fetchedMeetings = snapshot.docs.map((doc) => MeetingModel.fromFirestore(doc)).toList();

      // 2. Update the last document pointer and check for more pages
      if (snapshot.docs.isNotEmpty) {
        _lastDocument = snapshot.docs.last;
      }
      _hasMore = fetchedMeetings.length == _pageSize;

      // 3. Add new meetings to the main list
      _allMeetings.addAll(fetchedMeetings);

      // 4. Pre-fetch Clients (ANR Fix) - Only fetching clients needed for this batch
      await _preFetchClients(fetchedMeetings);

      // 5. Re-group data and update UI
      _processAndGroupMeetings();

    } catch (e) {
      //if (mounted) _showSnackbar(context, 'Error loading meetings: ${e.toString()}', isError: true);
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _preFetchClients(List<MeetingModel> batch) async {
    // ... (Use previous implementation) ...
    final Set<String> newClientIds = batch
        .map((m) => m.clientId)
        .where((id) => !_clientCache.containsKey(id)) // Only fetch unknown clients
        .toSet();

    if (newClientIds.isEmpty) return;

    final List<Future<ClientModel?>> clientFutures = newClientIds.map((id) => _clientService.getClientById(id)).toList();
    final List<ClientModel?> fetchedClients = await Future.wait(clientFutures);

    // Populate cache
    for (var client in fetchedClients) {
      if (client != null) {
        _clientCache[client.id] = client;
      }
    }
  }

  void _processAndGroupMeetings() {
    // ... (Use previous implementation) ...
    final now = DateTime.now();

    // Clear previous groups to regenerate from _allMeetings
    upcomingMeetings = [];
    missedMeetings = [];
    archivedMeetings = [];

    // NOTE: Data is fetched ordered by startTime DESC
    for (final m in _allMeetings) {
      final isMissed = m.status == MeetingStatus.scheduled && m.startTime.isBefore(now);

      if (isMissed) {
        missedMeetings.add(m);
      } else if (m.status == MeetingStatus.scheduled) {
        upcomingMeetings.add(m);
      } else if (m.status == MeetingStatus.completed || m.status == MeetingStatus.cancelled) {
        archivedMeetings.add(m);
      }
    }

    // Apply final sorting *after* grouping
    upcomingMeetings.sort((a, b) => a.startTime.compareTo(b.startTime)); // Oldest first (chronological)
    missedMeetings.sort((a, b) => b.startTime.compareTo(a.startTime)); // Newest first (most recent miss)
    archivedMeetings.sort((a, b) => b.startTime.compareTo(a.startTime)); // Newest first (most recent archive)

    // Must call setState to reflect the group changes in the UI
    if(mounted) setState(() {});
  }

  void _refreshMeetingList() {
    _loadMeetings(isInitialLoad: true);
  }

  ClientModel? _getClientFromCache(String clientId) {
    return _clientCache[clientId];
  }

  // --- UI ---
  @override
  Widget build(BuildContext context) {
    final double screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      body: Stack(
        children: [
          Positioned(top: -100, right: -100, child: Container(width: 300, height: 300, decoration: BoxDecoration(shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.blue.withOpacity(0.1), blurRadius: 80, spreadRadius: 30)]))),

          SafeArea(
            child: Column(
              children: [
                // 1. HEADER
                _buildHeader(),

                // 2. LIST
                Expanded(
                  child: _isLoading && _allMeetings.isEmpty
                      ? const Center(child: CircularProgressIndicator())
                      : SingleChildScrollView(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildMeetingGroup(context, 'Upcoming', upcomingMeetings, color: Colors.green, isExpanded: true),
                        const SizedBox(height: 20),
                        _buildMeetingGroup(context, 'Missed / Action Req', missedMeetings, color: Colors.red, isExpanded: true),
                        const SizedBox(height: 20),
                        _buildMeetingGroup(context, 'History', archivedMeetings, color: Colors.grey, isExpanded: false, showPagination: true),
                        SizedBox(height: screenHeight * 0.05),
                      ],
                    ),
                  ),
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
          decoration: BoxDecoration(color: Colors.white.withOpacity(0.8), border: Border(bottom: BorderSide(color: Colors.grey.withOpacity(0.1)))),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("All Scheduled Meetings", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1A1A1A))),
              IconButton(icon: const Icon(Icons.refresh), onPressed: _refreshMeetingList),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMeetingGroup(BuildContext context, String title, List<MeetingModel> meetings, {bool isExpanded = true, Color? color, bool showPagination = false}) {
    if (meetings.isEmpty && !showPagination) return const SizedBox();
    color ??= Theme.of(context).colorScheme.primary;
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)]),
      child: ExpansionTile(
        initiallyExpanded: isExpanded,
        leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle), child: Icon(Icons.calendar_today, color: color, size: 20)),
        title: Text("$title (${meetings.length})", style: TextStyle(fontWeight: FontWeight.bold, color: color)),
        children: [
          ...meetings.map((m) => _buildMeetingItem(m, _getClientFromCache(m.clientId))).toList(),
          if (showPagination && _hasMore)
            Padding(padding: const EdgeInsets.all(12), child: OutlinedButton(onPressed: () => _loadMeetings(isInitialLoad: false), child: const Text("Load More History")))
        ],
      ),
    );
  }

  Widget _buildMeetingItem(MeetingModel meeting, ClientModel? client) {
    // Reuse your existing card logic here, but ensure it's inside a container without elevation conflicts
    final bool isCompleted = meeting.status == MeetingStatus.completed;
    final String clientName = client?.name ?? 'Client ID: ${meeting.clientId}';

    Color tileColor;
    IconData icon;
    String statusText = meeting.status.name.capitalize();

    final bool isMissed = meeting.status == MeetingStatus.scheduled && meeting.startTime.isBefore(DateTime.now());

    if (isMissed) {
      tileColor = Colors.red.shade50; // Lighter shade for premium feel
      icon = Icons.warning;
      statusText = 'Missed';
    } else if (meeting.status == MeetingStatus.cancelled) {
      tileColor = Colors.grey.shade50;
      icon = Icons.cancel;
      statusText = 'Cancelled';
    } else if (meeting.status == MeetingStatus.completed) {
      tileColor = Colors.green.shade50;
      icon = Icons.check_circle_outline;
    } else {
      tileColor = Colors.blue.shade50;
      icon = Icons.schedule;
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: tileColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.transparent), // Remove border for cleaner look or keep if needed
      ),
      child: ListTile(
        onTap: client != null
            ? () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => ClientDashboardScreen(client: client),
            ),
          );
        }
            : null,
        leading: Icon(icon, color: isMissed ? Colors.red : Theme.of(context).colorScheme.primary),
        // Title now uses maximum horizontal space
        title: Text(
          '$clientName: ${meeting.purpose}',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            decoration: meeting.status == MeetingStatus.cancelled ? TextDecoration.lineThrough : null,
          ),
          maxLines: 2, // Allow title to wrap
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${DateFormat('dd MMM yyyy').format(meeting.startTime)} at ${DateFormat('h:mm a').format(meeting.startTime)}',
              style: TextStyle(
                fontWeight: isMissed ? FontWeight.bold : FontWeight.normal,
                color: isMissed ? Colors.red.shade700 : Colors.black87,
              ),
            ),
            Text('Type: ${meeting.meetingType} | Status: $statusText', style: const TextStyle(fontSize: 12)),
            if (meeting.clinicalNotes?.isNotEmpty == true)
              Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Text('Note: ${meeting.clinicalNotes!}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic)),
              ),
          ],
        ),
        // 🎯 Trailing widget with a vertical column of colored actions
        trailing: !isCompleted && client != null
            ? const Icon(Icons.chevron_right)
            : null,
      ),
    );
  }
}

// Helper extension
extension StringExtension on String {
  String capitalize() => isEmpty ? this : "${this[0].toUpperCase()}${substring(1).toLowerCase()}";
}