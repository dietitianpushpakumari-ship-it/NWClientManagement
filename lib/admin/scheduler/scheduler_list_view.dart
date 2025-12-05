import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:nutricare_client_management/admin/admin_appointment_detail_screen.dart';
import 'package:nutricare_client_management/admin/appointment_model.dart';
import 'package:nutricare_client_management/admin/client_consultation_checlist_screen.dart';
import 'package:nutricare_client_management/modules/client/services/client_service.dart';
import 'package:nutricare_client_management/screens/dash/client_dashboard_screenv2.dart';
import 'package:url_launcher/url_launcher.dart';

class SchedulerListView extends StatefulWidget {
  const SchedulerListView({super.key});

  @override
  State<SchedulerListView> createState() => _SchedulerListViewState();
}

class _SchedulerListViewState extends State<SchedulerListView> with SingleTickerProviderStateMixin {
  late TabController _listTabController;
  final ClientService _clientService = ClientService();

  // 🎯 NEW: Smart Filters State
  final Set<String> _historyStatusFilters = {};
  DateTimeRange? _historyDateRange; // Stores selected start & end date

  @override
  void initState() {
    super.initState();
    _listTabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _listTabController.dispose();
    super.dispose();
  }

  // --- ACTIONS ---

  Future<void> _pickDateRange() async {
    final DateTime now = DateTime.now();
    final DateTimeRange? picked = await showDateRangePicker(
        context: context,
        firstDate: DateTime(2020),
        lastDate: DateTime(2030),
        initialDateRange: _historyDateRange ?? DateTimeRange(start: now.subtract(const Duration(days: 7)), end: now),
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: ColorScheme.light(primary: Colors.indigo),
            ),
            child: child!,
          );
        }
    );

    if (picked != null) {
      setState(() => _historyDateRange = picked);
    }
  }

  Future<void> _handleStartConsultation(AppointmentModel appt) async {
    if (appt.clientId == null) return;
    try {
      final client = await _clientService.getClientById(appt.clientId!);
      if (!mounted) return;

      if (client.clientType == 'new' || client.clientType == 'pending') {
        Navigator.push(context, MaterialPageRoute(builder: (_) => ClientConsultationChecklistScreen(initialProfile: client)));
      } else {
        Navigator.push(context, MaterialPageRoute(builder: (_) => ClientDashboardScreen(client: client)));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error loading client: $e")));
    }
  }

  Future<void> _launchCall(String? phone) async {
    if (phone == null) return;
    final uri = Uri.parse("tel:$phone");
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  void _openAppointmentDetails(AppointmentModel appointment) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => AdminAppointmentDetailsScreen(appointment: appointment)));
  }

  // --- MAIN BUILDER ---

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // TAB BAR
        Container(
          height: 50,
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(25), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)]),
          child: TabBar(
            controller: _listTabController,
            indicator: BoxDecoration(color: Colors.indigo, borderRadius: BorderRadius.circular(25)),
            labelColor: Colors.white,
            unselectedLabelColor: Colors.grey,
            tabs: const [Tab(text: "Upcoming"), Tab(text: "Requests"), Tab(text: "History")],
          ),
        ),

        // CONTENT VIEW
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('appointments').snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

              final docs = snapshot.data!.docs.map((d) => AppointmentModel.fromFirestore(d)).toList();

              // 1. UPCOMING
              final upcoming = docs.where((a) => a.status == AppointmentStatus.confirmed).toList()
                ..sort((a, b) => a.startTime.compareTo(b.startTime));

              // 2. REQUESTS
              final requests = docs.where((a) =>
              a.status == AppointmentStatus.scheduled ||
                  a.status == AppointmentStatus.pending ||
                  a.status == AppointmentStatus.payment_pending ||
                  a.status == AppointmentStatus.verification_pending
              ).toList()
                ..sort((a, b) => a.startTime.compareTo(b.startTime));

              // 3. HISTORY (Master List)
              final allHistory = List<AppointmentModel>.from(docs)
                ..sort((a, b) => b.startTime.compareTo(a.startTime)); // Newest first

              return TabBarView(
                controller: _listTabController,
                children: [
                  _buildGroupedList(upcoming, isUpcoming: true),
                  _buildGroupedList(requests, isRequest: true),
                  _buildHistoryTab(allHistory), // 🎯 Updated History Tab
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  // 🎯 UPDATED HISTORY TAB BUILDER
  Widget _buildHistoryTab(List<AppointmentModel> allItems) {
    // FILTER LOGIC
    final filtered = allItems.where((appt) {
      // 1. Status Filter
      if (_historyStatusFilters.isNotEmpty) {
        String category = _getCategory(appt.status);
        if (!_historyStatusFilters.contains(category)) return false;
      }

      // 2. Date Range Filter
      if (_historyDateRange != null) {
        // Normalize to start of day for comparison
        final start = DateTime(_historyDateRange!.start.year, _historyDateRange!.start.month, _historyDateRange!.start.day);
        final end = DateTime(_historyDateRange!.end.year, _historyDateRange!.end.month, _historyDateRange!.end.day, 23, 59, 59);

        if (appt.startTime.isBefore(start) || appt.startTime.isAfter(end)) return false;
      }

      return true;
    }).toList();

    return Column(
      children: [
        // FILTER BAR
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              // 🎯 DATE FILTER CHIP
              ActionChip(
                avatar: Icon(Icons.date_range, size: 16, color: _historyDateRange != null ? Colors.white : Colors.indigo),
                label: Text(
                    _historyDateRange == null
                        ? "Date Range"
                        : "${DateFormat('MM/dd').format(_historyDateRange!.start)} - ${DateFormat('MM/dd').format(_historyDateRange!.end)}",
                    style: TextStyle(
                        color: _historyDateRange != null ? Colors.white : Colors.black87,
                        fontWeight: FontWeight.bold,
                        fontSize: 12
                    )
                ),
                backgroundColor: _historyDateRange != null ? Colors.indigo : Colors.white,
                side: BorderSide(color: Colors.indigo.withOpacity(0.3)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                onPressed: _pickDateRange,
              ),
              if (_historyDateRange != null) ...[
                const SizedBox(width: 8),
                InkWell(
                  onTap: () => setState(() => _historyDateRange = null),
                  child: const CircleAvatar(radius: 12, backgroundColor: Colors.grey, child: Icon(Icons.close, size: 14, color: Colors.white)),
                )
              ],

              const SizedBox(width: 12),
              Container(width: 1, height: 20, color: Colors.grey.shade300), // Separator
              const SizedBox(width: 12),

              // STATUS CHIPS
              _buildFilterChip("Confirmed", _historyStatusFilters.contains("Confirmed"), () => _toggleFilter("Confirmed"), Colors.green),
              const SizedBox(width: 8),
              _buildFilterChip("Completed", _historyStatusFilters.contains("Completed"), () => _toggleFilter("Completed"), Colors.blue),
              const SizedBox(width: 8),
              _buildFilterChip("Pending", _historyStatusFilters.contains("Pending"), () => _toggleFilter("Pending"), Colors.orange),
              const SizedBox(width: 8),
              _buildFilterChip("Cancelled", _historyStatusFilters.contains("Cancelled"), () => _toggleFilter("Cancelled"), Colors.red),
            ],
          ),
        ),

        // LIST
        Expanded(
          child: filtered.isEmpty
              ? Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.filter_list_off, size: 48, color: Colors.grey.shade300),
              const SizedBox(height: 16),
              Text("No history matches.", style: TextStyle(color: Colors.grey.shade500)),
            ],
          )
              : _buildList(filtered, isHistory: true),
        ),
      ],
    );
  }

  // --- GROUPED & GENERIC LISTS (Unchanged Logic) ---
  // (Keeping existing methods for brevity: _buildGroupedList, _buildUpcomingCard, _buildRequestCard, _buildList, _getDateKey, _buildListStatusChip)

  // ... [Previous implementation of _buildGroupedList, etc. goes here] ...
  // ... (Ensuring _buildList is used by _buildHistoryTab above)

  Widget _buildGroupedList(List<AppointmentModel> items, {bool isUpcoming = false, bool isRequest = false}) {
    if (items.isEmpty) {
      return Center(child: Text("No ${isUpcoming ? 'upcoming' : 'pending'} sessions.", style: const TextStyle(color: Colors.grey)));
    }

    final Map<String, List<AppointmentModel>> grouped = {};
    for (var item in items) {
      final key = _getDateKey(item.startTime);
      if (!grouped.containsKey(key)) grouped[key] = [];
      grouped[key]!.add(item);
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
      itemCount: grouped.length,
      itemBuilder: (context, index) {
        final dateKey = grouped.keys.elementAt(index);
        final dateItems = grouped[dateKey]!;
        final bool isOverdueHeader = dateKey.contains("Elapsed") || dateKey.contains("Past");

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
              child: Row(
                children: [
                  Icon(Icons.calendar_today, size: 14, color: isOverdueHeader ? Colors.red : Colors.grey),
                  const SizedBox(width: 8),
                  Text(dateKey, style: TextStyle(fontWeight: FontWeight.bold, color: isOverdueHeader ? Colors.red : Colors.grey, fontSize: 13)),
                  const SizedBox(width: 8),
                  Expanded(child: Divider(color: isOverdueHeader ? Colors.red.shade100 : Colors.grey.shade300, thickness: 1)),
                ],
              ),
            ),
            ...dateItems.map((item) => isUpcoming
                ? _buildUpcomingCard(item)
                : _buildRequestCard(item)
            ).toList(),
          ],
        );
      },
    );
  }

  Widget _buildUpcomingCard(AppointmentModel item) {
    final bool isOverdue = item.startTime.isBefore(DateTime.now());

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isOverdue ? Colors.red.shade50 : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 3))],
        border: isOverdue ? Border.all(color: Colors.red.shade200) : Border.all(color: Colors.green.withOpacity(0.3)),
      ),
      child: ListTile(
        onTap: () => _openAppointmentDetails(item),
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isOverdue ? Colors.red.shade100 : Colors.indigo.shade50,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(DateFormat('HH:mm').format(item.startTime), style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: isOverdue ? Colors.red.shade900 : Colors.indigo)),
            ],
          ),
        ),
        title: Row(
          children: [
            Expanded(child: Text(item.clientName, style: const TextStyle(fontWeight: FontWeight.bold))),
            if (isOverdue)
              Container(
                margin: const EdgeInsets.only(left: 8),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(4)),
                child: const Text("ACTION REQ", style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
              )
          ],
        ),
        subtitle: Text("${item.topic} • ${item.type.name.toUpperCase()}", style: TextStyle(color: Colors.grey.shade700, fontSize: 12)),
        trailing: ElevatedButton(
          onPressed: () => _handleStartConsultation(item),
          style: ElevatedButton.styleFrom(
              backgroundColor: isOverdue ? Colors.red : Colors.indigo,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              minimumSize: const Size(70, 32),
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))
          ),
          child: const Text("Start", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }

  Widget _buildRequestCard(AppointmentModel item) {
    final bool isElapsed = item.startTime.isBefore(DateTime.now());
    final bool isPaymentPending = item.status == AppointmentStatus.payment_pending;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isElapsed ? Colors.red.shade50 : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 3))],
        border: isElapsed ? Border.all(color: Colors.red.shade200) : null,
      ),
      child: ListTile(
        onTap: () => _openAppointmentDetails(item),
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isElapsed ? Colors.red.shade100 : (isPaymentPending ? Colors.orange.shade50 : Colors.indigo.shade50),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(DateFormat('HH:mm').format(item.startTime), style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: isElapsed ? Colors.red.shade900 : Colors.indigo)),
            ],
          ),
        ),
        title: Row(
          children: [
            Expanded(child: Text(item.clientName, style: const TextStyle(fontWeight: FontWeight.bold))),
            if (isElapsed)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(4)),
                child: const Text("OVERDUE", style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
              )
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(item.topic, style: TextStyle(color: Colors.grey.shade700, fontSize: 13)),
            const SizedBox(height: 4),
            if (isPaymentPending)
              const Text("⚠️ Payment Verification Pending", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.deepOrange))
            else
              _buildListStatusChip(item.status),
          ],
        ),
        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
      ),
    );
  }

  Widget _buildList(List<AppointmentModel> items, {bool isUpcoming = false, bool isHistory = false}) {
    if (items.isEmpty) return const Center(child: Text("No appointments found.", style: TextStyle(color: Colors.grey)));

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final item = items[index];
        return Container(
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 3))]),
          child: ListTile(
            onTap: () => _openAppointmentDetails(item),
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: isHistory ? Colors.grey.shade100 : Colors.indigo.shade50, borderRadius: BorderRadius.circular(12)),
              child: Text(DateFormat('d\nMMM').format(item.startTime), textAlign: TextAlign.center, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isHistory ? Colors.grey : Colors.indigo)),
            ),
            title: Text(item.clientName, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text("${DateFormat.jm().format(item.startTime)} • ${item.topic}", style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
            trailing: isUpcoming
                ? ElevatedButton(
              onPressed: () => _handleStartConsultation(item),
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  minimumSize: const Size(60, 32),
                  elevation: 0
              ),
              child: const Text("Start", style: TextStyle(fontSize: 12)),
            )
                : _buildListStatusChip(item.status),
          ),
        );
      },
    );
  }

  String _getDateKey(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final check = DateTime(date.year, date.month, date.day);

    if (check == today) return "Today";
    if (check == tomorrow) return "Tomorrow";
    if (check.isBefore(today)) return "Elapsed / Past Due";
    return DateFormat('EEEE, d MMM').format(date);
  }

  Widget _buildListStatusChip(AppointmentStatus status) {
    Color color = status == AppointmentStatus.confirmed ? Colors.green : (status == AppointmentStatus.cancelled ? Colors.red : Colors.orange);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
      child: Text(status.name.toUpperCase(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color)),
    );
  }

  Widget _buildFilterChip(String label, bool isSelected, VoidCallback onTap, [Color? activeColor]) {
    final color = activeColor ?? Colors.indigo;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onTap(),
      backgroundColor: Colors.white,
      selectedColor: color.withOpacity(0.15),
      labelStyle: TextStyle(color: isSelected ? color : Colors.grey.shade700, fontWeight: FontWeight.bold, fontSize: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: isSelected ? color : Colors.grey.shade300)),
      showCheckmark: false,
    );
  }

  void _toggleFilter(String category) {
    setState(() {
      if (_historyStatusFilters.contains(category)) {
        _historyStatusFilters.remove(category);
      } else {
        _historyStatusFilters.add(category);
      }
    });
  }

  String _getCategory(AppointmentStatus status) {
    switch (status) {
      case AppointmentStatus.confirmed: return "Confirmed";
      case AppointmentStatus.completed: return "Completed";
      case AppointmentStatus.cancelled: return "Cancelled";
      default: return "Pending";
    }
  }
}