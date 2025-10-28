import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:nutricare_client_management/admin/meeting_service.dart';
import 'package:nutricare_client_management/admin/schedule_meeting_utils.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';

// 🎯 ASSUME THIS IS THE CORRECT PATH FOR YOUR CLIENT MODEL
import 'package:nutricare_client_management/modules/client/model/client_model.dart';


class ClientMeetingScheduleTab extends StatefulWidget {
  final ClientModel client;

  const ClientMeetingScheduleTab({
    super.key,
    required this.client,
  });

  @override
  State<ClientMeetingScheduleTab> createState() => _ClientMeetingScheduleTabState();
}

class _ClientMeetingScheduleTabState extends State<ClientMeetingScheduleTab> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final MeetingService _meetingService = MeetingService();

  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  String? _selectedMeetingType = 'Video Call';
  final TextEditingController _purposeController = TextEditingController();
  final TextEditingController _meetLinkController = TextEditingController();

  bool _isScheduling = false;
  bool _isArchiveExpanded = false;
  final List<String> _meetingTypes = ['Video Call', 'Voice Call', 'In-Person'];

  late Future<List<MeetingModel>> _meetingsFuture;

  @override
  void initState() {
    super.initState();
    _meetingsFuture = _fetchMeetings();
  }

  @override
  void dispose() {
    _purposeController.dispose();
    _meetLinkController.dispose();
    super.dispose();
  }

  // =================================================================
  // CORE MEETING LOGIC & UTILS
  // =================================================================

  Future<List<MeetingModel>> _fetchMeetings() {
    return _meetingService.getClientMeetings(widget.client.id);
  }

  void _refreshMeetingList() {
    setState(() {
      _meetingsFuture = _fetchMeetings();
    });
  }

  void _scheduleMeeting() async {
    if (!_formKey.currentState!.validate() || _selectedDate == null || _selectedTime == null) {
      _showSnackbar(context, 'Please fill all required fields.', isError: true);
      return;
    }

    setState(() => _isScheduling = true);

    try {
      final DateTime finalStartTime = DateTime(
        _selectedDate!.year,
        _selectedDate!.month,
        _selectedDate!.day,
        _selectedTime!.hour,
        _selectedTime!.minute,
      );

      await _meetingService.scheduleMeeting(
        clientId: widget.client.id,
        startTime: finalStartTime,
        meetingType: _selectedMeetingType!,
        purpose: _purposeController.text.trim(),
        meetLink: _selectedMeetingType == 'Video Call' ? _meetLinkController.text.trim() : null,
      );

      if (mounted) {
        _showSnackbar(context, 'Meeting scheduled successfully for ${widget.client.name}!');
        _formKey.currentState!.reset();
        _purposeController.clear();
        _meetLinkController.clear();
        setState(() {
          _selectedDate = null;
          _selectedTime = null;
          _selectedMeetingType = 'Video Call';
        });
        _refreshMeetingList();
      }

    } catch (e) {
      if (mounted) {
        _showSnackbar(context, 'Failed to schedule meeting: ${e.toString().replaceFirst('Exception: ', '')}', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _isScheduling = false);
      }
    }
  }

  // --- Helper Functions (Launchers) ---

  Future<void> _launchUrl(BuildContext context, Uri url) async {
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      if (context.mounted) {
        _showSnackbar(context, 'Could not launch ${url.scheme} link.', isError: true);
      }
    }
  }

  void _makeNativeCall(BuildContext context) {
    if (widget.client.mobile.isNotEmpty) {
      final Uri url = Uri(scheme: 'tel', path: widget.client.mobile);
      _launchUrl(context, url);
    } else {
      _showSnackbar(context, 'Client mobile number is missing.', isError: true);
    }
  }

  void _makeWhatsAppCall(BuildContext context) {
    final number = widget.client.whatsappNumber?.isNotEmpty == true ? widget.client.whatsappNumber : widget.client.mobile;
    if (number != null && number.isNotEmpty) {
      final Uri url = Uri.parse('https://wa.me/$number');
      _launchUrl(context, url);
    } else {
      _showSnackbar(context, 'Client WhatsApp/Mobile number is missing.', isError: true);
    }
  }

  void _launchVideoCall(BuildContext context, {String? specificLink}) {
    final String meetLink = specificLink?.isNotEmpty == true ? specificLink! : 'https://meet.google.com/new';
    final Uri url = Uri.parse(meetLink);
    _launchUrl(context, url);
    if (specificLink == null) {
      _showSnackbar(context, 'Launching Google Meet. Remember to share the link with ${widget.client.name}!');
    }
  }

  void _showSnackbar(BuildContext context, String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red.shade600 : Colors.green.shade600,
      ),
    );
  }

  // --- Date/Time Pickers (Omitted for brevity) ---
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }


  // =================================================================
  // MEETING UPDATE DIALOG (Unchanged)
  // =================================================================

  Future<void> _showMeetingUpdateDialog(MeetingModel meeting) async {
    final TextEditingController notesController = TextEditingController(text: meeting.clinicalNotes);
    MeetingStatus currentStatus = meeting.status;
    bool isUpdating = false;

    final GlobalKey<FormState> updateFormKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setStateInDialog) {
            return AlertDialog(
              title: Text('Update Meeting: ${DateFormat('dd MMM').format(meeting.startTime)}'),
              content: SingleChildScrollView(
                child: Form(
                  key: updateFormKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Purpose: ${meeting.purpose}', style: const TextStyle(fontWeight: FontWeight.bold)),
                      Text('Type: ${meeting.meetingType}'),
                      if(meeting.meetLink?.isNotEmpty == true)
                        Text('Link: ${meeting.meetLink!}', style: const TextStyle(fontSize: 12, color: Colors.blue)),
                      const Divider(),

                      // 1. Status Dropdown
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

                      // 2. Clinical Notes
                      TextFormField(
                        controller: notesController,
                        decoration: const InputDecoration(
                          labelText: 'Clinical/Call Notes',
                          hintText: 'e.g., Blood pressure was high. Advised to reduce salt.',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 4,
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
                  onPressed: isUpdating ? null : () async {
                    if (updateFormKey.currentState!.validate()) {
                      final bool? confirmed = await showConfirmationDialog(dialogContext);

                      if (confirmed == true) {
                        setStateInDialog(() => isUpdating = true);
                        try {
                          final updatedMeeting = meeting.copyWith(
                            status: currentStatus,
                            clinicalNotes: notesController.text.trim().isNotEmpty ? notesController.text.trim() : null,
                          );

                          await _meetingService.updateMeeting(updatedMeeting);

                          if (mounted) {
                            _showSnackbar(context, 'Meeting status and notes updated successfully!');
                            _refreshMeetingList();
                            Navigator.of(context).pop();
                          }

                        } catch (e) {
                          if (mounted) {
                            _showSnackbar(context, 'Update failed: ${e.toString().replaceFirst('Exception: ', '')}', isError: true);
                          }
                        } finally {
                          setStateInDialog(() => isUpdating = false);
                        }
                      }
                    }
                  },
                  child: isUpdating
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('SAVE UPDATE'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<bool?> showConfirmationDialog(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Status Change'),
          content: const Text('Are you sure you want to save the new status and clinical notes? This action updates the call history.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('NO'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('YES, UPDATE'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        );
      },
    );
  }


  // =================================================================
  // UI BUILDERS
  // =================================================================

  // 🎯 NEW: Collapsible Contact Info Section
  Widget _buildContactTile(BuildContext context) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        initiallyExpanded: true, // Initially open
        tilePadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
        leading: Icon(Icons.person, color: Colors.indigo.shade700),
        title: Text(
          'Contact Information',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: Colors.indigo.shade700,
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 16.0, top: 8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoRow(
                  icon: Icons.person_outline,
                  label: 'Client Name',
                  value: widget.client.name,
                  color: Colors.black54,
                ),
                _buildInfoRow(
                  icon: Icons.phone_android,
                  label: 'Primary Mobile',
                  value: widget.client.mobile,
                  color: Colors.indigo,
                ),
                _buildInfoRow(
                  icon: FontAwesomeIcons.whatsapp,
                  label: 'WhatsApp Number',
                  value: widget.client.whatsappNumber ?? widget.client.mobile,
                  color: Colors.green,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 🎯 NEW: Collapsible Quick Actions Section
  Widget _buildQuickActionTile(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        initiallyExpanded: true, // Initially open
        tilePadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
        leading: Icon(Icons.speed, color: Colors.indigo.shade700),
        title: Text(
          'Quick Call Actions',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: Colors.indigo.shade700,
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildActionButton(
                      context: context,
                      label: 'Native Call',
                      icon: Icons.phone,
                      color: Colors.blue.shade700,
                      onPressed: () => _makeNativeCall(context),
                    ),
                    _buildActionButton(
                      context: context,
                      label: 'WhatsApp',
                      icon: FontAwesomeIcons.whatsapp,
                      color: Colors.green.shade700,
                      onPressed: () => _makeWhatsAppCall(context),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _buildActionButton(
                      context: context,
                      label: 'Google Meet',
                      icon: FontAwesomeIcons.video,
                      color: Colors.red.shade700,
                      onPressed: () => _launchVideoCall(context),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.black54,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required BuildContext context,
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 5.0),
        child: ElevatedButton.icon(
          onPressed: onPressed,
          icon: Icon(icon),
          label: Text(label),
          style: ElevatedButton.styleFrom(
            backgroundColor: color.withOpacity(0.1),
            foregroundColor: color,
            padding: const EdgeInsets.symmetric(vertical: 15),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
              side: BorderSide(color: color, width: 1),
            ),
            textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
        ),
      ),
    );
  }

  Widget _buildCallActionRow(MeetingModel meeting) {
    final bool isVideoCall = meeting.meetingType.contains('Video');

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 1. Native Call
        IconButton(
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
          icon: Icon(Icons.phone, color: Colors.blue.shade700, size: 20),
          tooltip: 'Native Call',
          onPressed: () => _makeNativeCall(context),
        ),
        const SizedBox(width: 8),

        // 2. WhatsApp Call
        IconButton(
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
          icon: Icon(FontAwesomeIcons.whatsapp, color: Colors.green.shade700, size: 20),
          tooltip: 'WhatsApp Call',
          onPressed: () => _makeWhatsAppCall(context),
        ),
        const SizedBox(width: 8),

        // 3. Video Call (Only show if meeting is scheduled as a Video Call)
        if (isVideoCall)
          IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            icon: Icon(FontAwesomeIcons.video, color: meeting.meetLink?.isNotEmpty == true ? Colors.red.shade700 : Colors.grey, size: 20),
            tooltip: meeting.meetLink?.isNotEmpty == true ? 'Launch Scheduled Meet Link' : 'Launch New Google Meet',
            onPressed: () => _launchVideoCall(context, specificLink: meeting.meetLink),
          ),
      ],
    );
  }

  Widget _buildMeetingItem(MeetingModel meeting) {
    final bool isUpcoming = (meeting.status == MeetingStatus.scheduled ||  meeting.status == MeetingStatus.rescheduled);
    final bool isMissed = isUpcoming && meeting.startTime.isBefore(DateTime.now());
    final bool isCancelled = meeting.status == MeetingStatus.cancelled;

    final bool showQuickActions = isUpcoming && !isMissed;

    Color tileColor;
    IconData icon;
    String statusText;

    if (isMissed) {
      tileColor = Colors.red.shade50;
      icon = Icons.error_outline;
      statusText = 'Missed';
    } else if (isCancelled) {
      tileColor = Colors.grey.shade100;
      icon = Icons.cancel;
      statusText = 'Cancelled';
    } else if (meeting.status == MeetingStatus.completed) {
      tileColor = Colors.green.shade50;
      icon = Icons.check_circle_outline;
      statusText = 'Completed';
    } else { // Upcoming/Scheduled
      tileColor = Colors.blue.shade50;
      icon = Icons.schedule;
      statusText = 'Scheduled';
    }

    return Card(
      color: tileColor,
      margin: const EdgeInsets.only(bottom: 8.0),
      child: ListTile(
        onTap: () => _showMeetingUpdateDialog(meeting),
        leading: Icon(icon, color: isMissed ? Colors.red : isCancelled ? Colors.grey : Colors.indigo),
        title: Text(
          meeting.purpose,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            decoration: isCancelled ? TextDecoration.lineThrough : null,
          ),
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
                child: Text('Notes: ${meeting.clinicalNotes!}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic)),
              ),
          ],
        ),
        trailing: showQuickActions
            ? _buildCallActionRow(meeting)
            : null,
      ),
    );
  }

  Widget _buildSchedulingForm(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Schedule Future Meeting',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold, color: Colors.indigo),
              ),
              const Divider(height: 20),

              // --- 1. Date and Time Pickers ---
              Row(
                children: [
                  Expanded(
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        _selectedDate == null
                            ? 'Select Date *'
                            : DateFormat('dd MMM yyyy').format(_selectedDate!),
                        style: TextStyle(color: _selectedDate == null ? Colors.red : null),
                      ),
                      trailing: const Icon(Icons.calendar_today, color: Colors.grey),
                      onTap: () => _selectDate(context),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        _selectedTime == null
                            ? 'Select Time *'
                            : _selectedTime!.format(context),
                        style: TextStyle(color: _selectedTime == null ? Colors.red : null),
                      ),
                      trailing: const Icon(Icons.access_time, color: Colors.grey),
                      onTap: () => _selectTime(context),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),

              // --- 2. Meeting Type Dropdown ---
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Meeting Type *',
                  prefixIcon: Icon(Icons.people_alt),
                  border: OutlineInputBorder(),
                ),
                value: _selectedMeetingType,
                items: _meetingTypes.map((type) {
                  return DropdownMenuItem<String>(
                    value: type,
                    child: Text(type),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedMeetingType = newValue;
                  });
                },
                validator: (v) => v == null ? 'Meeting type is required.' : null,
              ),
              const SizedBox(height: 15),

              // --- 3. Purpose Text Field ---
              TextFormField(
                controller: _purposeController,
                decoration: const InputDecoration(
                  labelText: 'Purpose/Agenda *',
                  hintText: 'e.g., Follow-up on Diet Plan 2',
                  prefixIcon: Icon(Icons.assignment),
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v!.isEmpty ? 'Purpose is required.' : null,
              ),
              const SizedBox(height: 15),

              // --- 4. Meet Link Field (Conditional) ---
              if (_selectedMeetingType == 'Video Call')
                TextFormField(
                  controller: _meetLinkController,
                  decoration: const InputDecoration(
                    labelText: 'Video Call Link (e.g., Google Meet URL)',
                    hintText: 'https://meet.google.com/...',
                    prefixIcon: Icon(Icons.link),
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) => v!.isEmpty ? 'Video link is required for Video Call.' : null,
                ),
              const SizedBox(height: 20),

              // --- 5. Schedule Button ---
              ElevatedButton.icon(
                onPressed: _isScheduling ? null : _scheduleMeeting,
                icon: _isScheduling
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.event_available),
                label: Text(_isScheduling ? 'SCHEDULING...' : 'SCHEDULE MEETING'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  backgroundColor: Colors.indigo,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMeetingHistory() {
    return FutureBuilder<List<MeetingModel>>(
      future: _meetingsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: Padding(
            padding: EdgeInsets.all(20.0),
            child: CircularProgressIndicator(),
          ));
        }

        if (snapshot.hasError) {
          return Center(child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Text('Error loading meetings: ${snapshot.error}'),
          ));
        }

        final List<MeetingModel> allMeetings = snapshot.data ?? [];

        final List<MeetingModel> upcomingMeetings = allMeetings
            .where((m) => m.status == MeetingStatus.scheduled || m.status == MeetingStatus.missed)
            .toList();

        final List<MeetingModel> archivedMeetings = allMeetings
            .where((m) => m.status == MeetingStatus.completed || m.status == MeetingStatus.cancelled)
            .toList();

        upcomingMeetings.sort((a, b) => a.startTime.compareTo(b.startTime));
        archivedMeetings.sort((a, b) => b.startTime.compareTo(a.startTime));

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Upcoming Calls & Pending Actions',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.indigo),
            ),
            const Divider(height: 10),
            upcomingMeetings.isEmpty
                ? const Padding(
              padding: EdgeInsets.symmetric(vertical: 16.0),
              child: Text('No upcoming calls scheduled.'),
            )
                : Column(children: upcomingMeetings.map(_buildMeetingItem).toList()),

            const SizedBox(height: 20),

            ExpansionTile(
              initiallyExpanded: _isArchiveExpanded,
              onExpansionChanged: (expanded) {
                setState(() {
                  _isArchiveExpanded = expanded;
                });
              },
              leading: const Icon(Icons.archive, color: Colors.orange),
              title: Text(
                'Archived Call History (${archivedMeetings.length})',
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange.shade700),
              ),
              children: archivedMeetings.isEmpty
                  ? [const Padding(padding: EdgeInsets.all(16.0), child: Text('No completed or cancelled calls in archive.'))]
                  : archivedMeetings.map(_buildMeetingItem).toList(),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          // 1. Collapsible Client Contact Info
          _buildContactTile(context),

          // 2. Collapsible Quick Call Actions
          _buildQuickActionTile(context),

          const SizedBox(height: 10),

          // 3. Scheduling Form
          _buildSchedulingForm(context),

          const SizedBox(height: 30),

          // 4. Call History
          _buildMeetingHistory(),
        ],
      ),
    );
  }
}

// ----------------------------------------------------------------------
// EXTENSIONS AND HELPERS
// ----------------------------------------------------------------------

extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return "${this[0].toUpperCase()}${substring(1).toLowerCase()}";
  }
}