import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:nutricare_client_management/screens/dash/client_dashboard_screenv2.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // REQUIRED for DocumentSnapshot

// 🎯 ASSUME CORRECT PATHS FOR YOUR FILES
import 'package:nutricare_client_management/admin/meeting_service.dart';
import 'package:nutricare_client_management/admin/schedule_meeting_utils.dart'; // Contains MeetingModel & MeetingStatus
import '../modules/client/model/client_model.dart';
import '../modules/client/services/client_service.dart';
import 'package:nutricare_client_management/admin/custom_gradient_app_bar.dart';


// ----------------------------------------------------------------------------------
// WIDGET: ALL MEETINGS SCREEN
// ----------------------------------------------------------------------------------

class AllMeetingsScreen extends StatefulWidget {
  const AllMeetingsScreen({super.key});

  @override
  State<AllMeetingsScreen> createState() => _AllMeetingsScreenState();
}

class _AllMeetingsScreenState extends State<AllMeetingsScreen> {
  // 🎯 Instantiate Services
  final MeetingService _meetingService = MeetingService();
  final ClientService _clientService = ClientService();

  // PAGINATION STATE VARIABLES
  final int _pageSize = 25; // Number of items per page
  final Map<String, ClientModel> _clientCache = {}; // Cache for client models (ANR fix)
  DocumentSnapshot? _lastDocument; // The last document fetched in the previous call
  bool _isLoading = false;
  bool _hasMore = true; // Flag to indicate if there are more items to load

  // DATA LISTS
  List<MeetingModel> _allMeetings = []; // Combined list of all meetings fetched
  List<MeetingModel> upcomingMeetings = [];
  List<MeetingModel> missedMeetings = [];
  List<MeetingModel> archivedMeetings = [];

  @override
  void initState() {
    super.initState();
    _loadMeetings(isInitialLoad: true);
  }

  // ----------------------------------------------------------------------
  // 🛠️ PAGINATION & DATA FETCHING LOGIC
  // ----------------------------------------------------------------------

  Future<void> _loadMeetings({bool isInitialLoad = false}) async {
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
      if (mounted) _showSnackbar(context, 'Error loading meetings: ${e.toString()}', isError: true);
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Helper to pre-fetch client data for the newly loaded batch (ANR Fix)
  Future<void> _preFetchClients(List<MeetingModel> batch) async {
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

  // Helper to re-group the data whenever _allMeetings is updated
  void _processAndGroupMeetings() {
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

  // Helper to get client from the cache directly (non-blocking)
  ClientModel? _getClientFromCache(String clientId) {
    return _clientCache[clientId];
  }

  // =================================================================
  // UTILS (SNACKBARS, CALL LAUNCHERS)
  // =================================================================

  void _showSnackbar(BuildContext context, String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red.shade600 : Colors.green.shade600,
      ),
    );
  }

  Future<void> _launchUrl(BuildContext context, Uri url) async {
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      if (context.mounted) {
        _showSnackbar(context, 'Could not launch ${url.scheme} link.', isError: true);
      }
    }
  }

  void _makeNativeCall(BuildContext context, ClientModel client) {
    if (client.mobile.isNotEmpty) {
      final Uri url = Uri(scheme: 'tel', path: client.mobile);
      _launchUrl(context, url);
    } else {
      _showSnackbar(context, 'Client mobile number is missing.', isError: true);
    }
  }

  void _makeWhatsAppCall(BuildContext context, ClientModel client) {
    final number = client.whatsappNumber?.isNotEmpty == true ? client.whatsappNumber : client.mobile;
    if (number != null && number.isNotEmpty) {
      final Uri url = Uri.parse('https://wa.me/$number');
      _launchUrl(context, url);
    } else {
      _showSnackbar(context, 'Client WhatsApp/Mobile number is missing.', isError: true);
    }
  }

  void _launchVideoCall(BuildContext context, {String? specificLink, String? clientName}) {
    final String meetLink = specificLink?.isNotEmpty == true ? specificLink! : 'https://meet.google.com/new';
    final Uri url = Uri.parse(meetLink);
    _launchUrl(context, url);
    if (specificLink == null) {
      _showSnackbar(context, 'Launching Google Meet. Remember to share the link with ${clientName ?? 'the client'}!');
    }
  }


  // =================================================================
  // MEETING ACTION DIALOG (Update Status / Reschedule)
  // =================================================================

  Future<void> _showMeetingActionDialog(MeetingModel meeting) async {
    final TextEditingController notesController = TextEditingController(text: meeting.clinicalNotes);
    MeetingStatus currentStatus = meeting.status;
    bool isUpdating = false;

    DateTime? selectedDate = meeting.startTime;
    TimeOfDay selectedTime = TimeOfDay.fromDateTime(meeting.startTime);

    final GlobalKey<FormState> actionFormKey = GlobalKey<FormState>();
    final ClientModel? client = _getClientFromCache(meeting.clientId);

    await showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setStateInDialog) {

            // Helper functions for date/time picking
            Future<void> selectDate(BuildContext ctx) async {
              final DateTime? picked = await showDatePicker(
                context: ctx,
                initialDate: selectedDate ?? DateTime.now(),
                firstDate: DateTime.now().subtract(const Duration(days: 365)),
                lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
              );
              if (picked != null) {
                setStateInDialog(() {
                  selectedDate = picked;
                });
              }
            }

            Future<void> selectTime(BuildContext ctx) async {
              final TimeOfDay? picked = await showTimePicker(
                context: ctx,
                initialTime: selectedTime,
              );
              if (picked != null) {
                setStateInDialog(() {
                  selectedTime = picked;
                });
              }
            }

            // Function to handle the actual update/reschedule save
            void handleSave() async {
              if (actionFormKey.currentState!.validate()) {

                setStateInDialog(() => isUpdating = true);

                try {
                  final newStartTime = DateTime(
                    selectedDate!.year, selectedDate!.month, selectedDate!.day,
                    selectedTime.hour, selectedTime.minute,
                  );

                  final isTimeChanged = !newStartTime.isAtSameMomentAs(meeting.startTime);
                  final isStatusChanged = currentStatus != meeting.status;

                  if (isTimeChanged) {
                    // RESCHEDULE LOGIC
                    await _meetingService.rescheduleMeeting(
                      meetingId: meeting.id,
                      newStartTime: newStartTime,
                      notes: notesController.text.trim(),
                    );
                    _showSnackbar(context, 'Meeting rescheduled successfully!');

                  } else {
                    // STATUS/NOTE UPDATE LOGIC
                    final updatedMeeting = meeting.copyWith(
                      status: currentStatus,
                      clinicalNotes: notesController.text.trim().isNotEmpty ? notesController.text.trim() : null,
                    );
                    await _meetingService.updateMeeting(updatedMeeting);
                    _showSnackbar(context, 'Meeting status updated successfully!');
                  }

                  if (mounted) {
                    // 🎯 UPDATE: Re-process and group all data to reflect the change
                    // Instead of full refresh, we update the local list and regroup.
                    final index = _allMeetings.indexWhere((m) => m.id == meeting.id);
                    if (index != -1) {
                      _allMeetings[index] = meeting.copyWith(
                        status: currentStatus,
                        clinicalNotes: notesController.text.trim().isNotEmpty ? notesController.text.trim() : null,
                      );
                      // If rescheduled, the time will be correct in Firestore,
                      // but we need a full refresh to re-sort correctly,
                      // or just force a re-load if time changed significantly.
                      if (isTimeChanged) {
                        _refreshMeetingList();
                      } else {
                        _processAndGroupMeetings();
                      }
                    }
                    Navigator.of(context).pop();
                  }

                } catch (e) {
                  if (mounted) {
                    _showSnackbar(context, 'Update failed: ${e.toString().replaceFirst('Exception: ', '')}', isError: true);
                  }
                } finally {
                  if (mounted) {
                    setStateInDialog(() => isUpdating = false);
                  }
                }
              }
            }

            // UI of the Dialog
            return AlertDialog(
              title: Text('Action on Meeting: ${DateFormat('dd MMM').format(meeting.startTime)}'),
              content: SingleChildScrollView(
                child: Form(
                  key: actionFormKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Client Name
                      Text(
                          'Client: ${client?.name ?? 'Client ID: ${meeting.clientId}'}',
                          style: const TextStyle(fontWeight: FontWeight.bold)
                      ),
                      Text('Purpose: ${meeting.purpose}'),
                      const Divider(),

                      // 1. Date and Time Pickers (Reschedule only for non-archived)
                      if (meeting.status != MeetingStatus.completed && meeting.status != MeetingStatus.cancelled) ...[
                        const Text('Change Schedule', style: TextStyle(fontWeight: FontWeight.bold)),
                      //  Row(
                        //  children: [
                           // Expanded(
                             // child:
                              ListTile(
                                title: Text(DateFormat('dd MMM yyyy').format(selectedDate!)),
                                trailing: const Icon(Icons.calendar_today),
                                onTap: () => selectDate(context),
                              ),
                          //  ),
                          //  Expanded(
                             // child:

                              ListTile(
                                title: Text(selectedTime.format(context)),
                                trailing: const Icon(Icons.access_time),
                                onTap: () => selectTime(context),
                              ),
                          //  ),
                       //   ],
                       // ),
                        const SizedBox(height: 15),
                      ],

                      // 2. Status Dropdown
                      if (meeting.status != MeetingStatus.completed) ...[
                        DropdownButtonFormField<MeetingStatus>(
                          decoration: const InputDecoration(
                            labelText: 'Meeting Status *',
                            border: OutlineInputBorder(),
                          ),
                          value: currentStatus,
                          items: MeetingStatus.values.map((status) {
                            return DropdownMenuItem<MeetingStatus>(
                              value: status,
                              child: Text(status.name.capitalize()),
                            );
                          }).toList(),
                          onChanged: (MeetingStatus? newValue) {
                            setStateInDialog(() {
                              currentStatus = newValue!;
                            });
                          },
                          validator: (v) => v == null ? 'Status is required.' : null,
                        ),
                        const SizedBox(height: 15),
                      ],


                      // 3. Clinical Notes (Mandatory for Status/Time Change)
                      TextFormField(
                        controller: notesController,
                        decoration: InputDecoration(
                          labelText: meeting.status == MeetingStatus.completed
                              ? 'Clinical Notes (Completed Call)'
                              : 'Action Note (Mandatory for status/time change) *',
                          hintText: 'e.g., Client requested change due to doctor visit.',
                          border: const OutlineInputBorder(),
                        ),
                        maxLines: 4,
                        validator: (v) {
                          final isTimeChanged = !DateTime(selectedDate!.year, selectedDate!.month, selectedDate!.day, selectedTime.hour, selectedTime.minute).isAtSameMomentAs(meeting.startTime);
                          final isStatusChanged = currentStatus != meeting.status;

                          if ((isTimeChanged || isStatusChanged) && v!.trim().isEmpty && meeting.status != MeetingStatus.completed) {
                            return 'Note is mandatory for this action.';
                          }
                          return null;
                        },
                        readOnly: meeting.status == MeetingStatus.completed,
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('CANCEL'),
                ),
                ElevatedButton(
                  onPressed: isUpdating ? null : handleSave,
                  child: isUpdating
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('SAVE ACTION'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // =================================================================
  // UI COMPONENTS
  // =================================================================

  Widget _buildCallActionButton(BuildContext context, MeetingModel meeting, ClientModel client) {
    // Only Native Call and WhatsApp are mandatory actions. Video is optional.
    final bool hasVideoLink = meeting.meetLink?.isNotEmpty == true || meeting.meetingType.contains('Video');

    return PopupMenuButton<String>(
      // 🎯 TEAL COLOR for the Call icon and set size for compactness
      icon: const Icon(Icons.call, color: Colors.teal, size:35.0),
      tooltip: 'Call & Video Actions',
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 20, minHeight: 35),
      onSelected: (String action) {
        // Handle the selected action
        if (action == 'native') {
          _makeNativeCall(context, client);
        } else if (action == 'whatsapp') {
          _makeWhatsAppCall(context, client);
        } else if (action == 'video') {
          _launchVideoCall(context, specificLink: meeting.meetLink, clientName: client.name);
        }
      },
      itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
        // 1. Native Call
        PopupMenuItem<String>(
          value: 'native',
          child: Row(
            children: [
              Icon(Icons.phone, color: Colors.blue.shade700),
              const SizedBox(width: 8),
              const Text('Native Call'),
            ],
          ),
        ),
        // 2. WhatsApp
        PopupMenuItem<String>(
          value: 'whatsapp',
          child: Row(
            children: [
              Icon(FontAwesomeIcons.whatsapp, color: Colors.green.shade700),
              const SizedBox(width: 8),
              const Text('WhatsApp'),
            ],
          ),
        ),
        // 3. Video Call (Only show if a link is available or type is video)
        if (hasVideoLink)
          PopupMenuItem<String>(
            value: 'video',
            child: Row(
              children: [
                Icon(FontAwesomeIcons.video, color: hasVideoLink ? Colors.red.shade700 : Colors.grey),
                const SizedBox(width: 8),
                const Text('Video/Meet'),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildMeetingItem(MeetingModel meeting, ClientModel? client) {
    final bool isCompleted = meeting.status == MeetingStatus.completed;
    final String clientName = client?.name ?? 'Client ID: ${meeting.clientId}';

    Color tileColor;
    IconData icon;
    String statusText = meeting.status.name.capitalize();

    final bool isMissed = meeting.status == MeetingStatus.scheduled && meeting.startTime.isBefore(DateTime.now());

    if (isMissed) {
      tileColor = Colors.red.shade100;
      icon = Icons.warning;
      statusText = 'Missed';
    } else if (meeting.status == MeetingStatus.cancelled) {
      tileColor = Colors.grey.shade100;
      icon = Icons.cancel;
      statusText = 'Cancelled';
    } else if (meeting.status == MeetingStatus.completed) {
      tileColor = Colors.green.shade50;
      icon = Icons.check_circle_outline;
    } else {
      tileColor = Colors.blue.shade50;
      icon = Icons.schedule;
    }

    return Card(
      color: tileColor,
      margin: const EdgeInsets.only(bottom: 8.0),
      child: ListTile(
        onTap: client != null
            ? () {
          // Assuming you have a route to your client dashboard that accepts the client model
          // You may need to import the ClientDashboardScreenV2
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => ClientDashboardScreen(client: client),
            ),
          );
        }
            : null,
        leading: Icon(icon, color: isMissed ? Colors.red : Colors.indigo),
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
            ? Container(
          width: 40,
          alignment: Alignment.center,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildCallActionButton(context, meeting, client),
                const SizedBox(height: 4),
                IconButton(
                  icon: const Icon(Icons.edit_calendar,
                      color: Colors.indigo, size: 35),
                  padding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                  onPressed: () => _showMeetingActionDialog(meeting),
                ),
              ],
            ),
          ),
        )
            : null,
      ),
    );
  }

  // PAGINATION UI WIDGET
  Widget _buildLoadMoreButton() {
    if (_isLoading && _allMeetings.isNotEmpty) {
      // Only show a small indicator if more meetings are being appended
      return const Padding(
        padding: EdgeInsets.all(10.0),
        child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))),
      );
    }

    if (!_hasMore) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 20.0),
        child: Center(child: Text('You have reached the end of the meeting history.', style: TextStyle(color: Colors.grey))),
      );
    }

    // Only show button if not currently loading and there is more data
    if (_hasMore) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 10.0),
        child: Center(
          child: OutlinedButton.icon(
            icon: const Icon(Icons.history),
            label: const Text('Load More Archive History'),
            onPressed: () => _loadMeetings(isInitialLoad: false),
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }


  // Collapsible Grouping Widget
  Widget _buildMeetingGroup(BuildContext context, String title, List<MeetingModel> meetings, {bool isExpanded = true, Color color = Colors.indigo, bool showPagination = false}) {
    if (meetings.isEmpty && !showPagination) { // Only hide if empty AND no pagination button is expected
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Text('No $title found.', style: TextStyle(color: color.withOpacity(0.7))),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(top: 10.0, bottom: 10.0),
      child: ExpansionTile(
        initiallyExpanded: isExpanded,
        leading: Icon(Icons.calendar_month, color: color),
        title: Text(
          '$title (${meetings.length})',
          style: TextStyle(fontWeight: FontWeight.bold, color: color),
        ),
        children: [
          ...meetings.map((meeting) {
            final client = _getClientFromCache(meeting.clientId);
            return _buildMeetingItem(meeting, client);
          }).toList(),

          // Add the "Load More" button only to the Archive group
          if (showPagination) _buildLoadMoreButton(),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 🎯 FIX 1: Capture screen height for a dynamic safety buffer
    final double screenHeight = MediaQuery.of(context).size.height;
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: CustomGradientAppBar(
        title: const Text('All Scheduled Meetings'),

        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshMeetingList,
          ),
        ],
      ),
      // Use the main _isLoading flag only for the initial screen state
      body: SafeArea(
        child: _isLoading && _allMeetings.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
          // ❌ Removed fixed padding from here.
          child: Padding(
            padding: const EdgeInsets.all(16.0), // 🎯 FIX 2: Apply padding to the inner widget
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- Active (Upcoming) ---
                _buildMeetingGroup(
                    context,
                    'Active / Upcoming Calls',
                    upcomingMeetings,
                    color: Colors.green.shade700,
                    isExpanded: true
                ),

                const Divider(),

                // --- Missed Calls ---
                _buildMeetingGroup(
                    context,
                    'Missed Calls (Action Required)',
                    missedMeetings,
                    color: Colors.red.shade700,
                    isExpanded: missedMeetings.isNotEmpty
                ),

               const Divider(),

                // --- Archive (Completed & Cancelled) ---
                _buildMeetingGroup(
                  context,
                  'Archive (Completed & Cancelled)',
                  archivedMeetings,
                  color: Colors.orange.shade700,
                  isExpanded: false,
                  showPagination: true, // ⬅️ Enable pagination UI here
                ),

                // 🎯 FIX 3: Add dynamic safety buffer at the bottom (4% of screen height)
                SizedBox(height: screenHeight * 0.04),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ----------------------------------------------------------------------
// HELPER EXTENSION
// ----------------------------------------------------------------------

extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return "${this[0].toUpperCase()}${substring(1).toLowerCase()}";
  }
}