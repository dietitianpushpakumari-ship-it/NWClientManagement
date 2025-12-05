import 'package:flutter/material.dart';
import 'package:nutricare_client_management/admin/appointment_model.dart';

// TODO: Import your existing model files
// import 'package:your_project/models/appointment_model.dart';
// import 'package:your_project/models/dietitian_model.dart';

// --- WRAPPER MODEL ---
class Dietitian {
  final String id;
  final String name;
  final String imageUrl;
  final String specialization;
  final List<AppointmentModel> appointments;

  Dietitian({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.specialization,
    required this.appointments,
  });
}

class AdminBookSessionScreen extends StatefulWidget {
  final List<Dietitian> allDietitians;

  const AdminBookSessionScreen({
    Key? key,
    required this.allDietitians,
  }) : super(key: key);

  @override
  State<AdminBookSessionScreen> createState() => _AdminBookSessionScreenState();
}

class _AdminBookSessionScreenState extends State<AdminBookSessionScreen> {
  // --- Controllers ---
  final ScrollController _headerScrollController = ScrollController();
  final ScrollController _bodyScrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  // --- State ---
  List<Dietitian> _filteredDietitians = [];
  final Set<AppointmentStatus> _selectedStatusFilters = {};
  String _searchQuery = "";

  // --- Layout Constants ---
  final double _sidebarWidth = 180.0;
  final double _hourWidth = 100.0;
  final double _rowHeight = 90.0; // Slightly taller for status text
  final int _startHour = 8;
  final int _endHour = 20;

  @override
  void initState() {
    super.initState();
    _filteredDietitians = widget.allDietitians;

    // Sync Horizontal Scrolling
    _bodyScrollController.addListener(() {
      if (_headerScrollController.hasClients) {
        _headerScrollController.jumpTo(_bodyScrollController.offset);
      }
    });
  }

  @override
  void didUpdateWidget(covariant AdminBookSessionScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    _applyFilters();
  }

  @override
  void dispose() {
    _headerScrollController.dispose();
    _bodyScrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // --- FILTER LOGIC ---
  void _applyFilters() {
    setState(() {
      _filteredDietitians = widget.allDietitians.where((dietitian) {
        // 1. Text Search
        final matchesName = dietitian.name.toLowerCase().contains(_searchQuery) ||
            dietitian.specialization.toLowerCase().contains(_searchQuery);

        if (!matchesName) return false;

        // 2. Status Filter
        if (_selectedStatusFilters.isEmpty) return true;

        final hasMatchingAppointment = dietitian.appointments.any(
                (apt) => _selectedStatusFilters.contains(apt.status));

        return hasMatchingAppointment;
      }).toList();
    });
  }

  void _onSearchChanged(String query) {
    _searchQuery = query.toLowerCase();
    _applyFilters();
  }

  void _toggleStatusFilter(AppointmentStatus status) {
    setState(() {
      if (_selectedStatusFilters.contains(status)) {
        _selectedStatusFilters.remove(status);
      } else {
        _selectedStatusFilters.add(status);
      }
      _applyFilters();
    });
  }

  // --- UI BUILDERS ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Session Manager",
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Column(
        children: [
          _buildControlPanel(),
          const Divider(height: 1),
          _buildTimeHeader(),
          Expanded(
            child: _filteredDietitians.isEmpty
                ? const Center(child: Text("No dietitians match filters"))
                : _buildSyncedList(),
          ),
        ],
      ),
    );
  }

  Widget _buildControlPanel() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: "Search Dietitian...",
              prefixIcon: const Icon(Icons.search),
              isDense: true,
              border:
              OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              contentPadding:
              const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
            ),
            onChanged: _onSearchChanged,
          ),
          const SizedBox(height: 12),

          // Scrollable Filter Chips (Since you have many statuses now)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                const Text("Filter: ", style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(width: 8),

                // Active/Booked Group
                _buildFilterChip("Scheduled", AppointmentStatus.scheduled, Colors.blue),
                const SizedBox(width: 6),
                _buildFilterChip("Confirmed", AppointmentStatus.confirmed, Colors.indigo),

                const SizedBox(width: 12), // Spacer group

                // Pending Group
                _buildFilterChip("Pending", AppointmentStatus.pending, Colors.orange),
                const SizedBox(width: 6),
                _buildFilterChip("Payment", AppointmentStatus.payment_pending, Colors.deepOrange),
                const SizedBox(width: 6),
                _buildFilterChip("Verify", AppointmentStatus.verification_pending, Colors.amber),

                const SizedBox(width: 12), // Spacer group

                // Done/Cancelled Group
                _buildFilterChip("Completed", AppointmentStatus.completed, Colors.green),
                const SizedBox(width: 6),
                _buildFilterChip("Cancelled", AppointmentStatus.cancelled, Colors.grey),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, AppointmentStatus status, Color color) {
    final isSelected = _selectedStatusFilters.contains(status);
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => _toggleStatusFilter(status),
      selectedColor: color.withOpacity(0.2),
      checkmarkColor: color,
      labelStyle: TextStyle(
          color: isSelected ? color : Colors.black87,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          fontSize: 12),
      backgroundColor: Colors.grey.shade100,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      visualDensity: VisualDensity.compact,
      side: BorderSide(color: isSelected ? color : Colors.grey.shade300),
    );
  }

  Widget _buildTimeHeader() {
    return SizedBox(
      height: 45,
      child: Row(
        children: [
          // Sidebar Header
          SizedBox(
            width: _sidebarWidth,
            child: Container(
              alignment: Alignment.center,
              decoration: BoxDecoration(
                border:
                Border(right: BorderSide(color: Colors.grey.shade300)),
                color: Colors.grey.shade50,
              ),
              child: const Text("Dietitian",
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
          // Timeline Header
          Expanded(
            child: SingleChildScrollView(
              controller: _headerScrollController,
              scrollDirection: Axis.horizontal,
              physics: const NeverScrollableScrollPhysics(),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: List.generate((_endHour - _startHour), (index) {
                  return Container(
                    width: _hourWidth,
                    alignment: Alignment.centerLeft,
                    padding: const EdgeInsets.only(left: 8),
                    decoration: BoxDecoration(
                      border: Border(
                          left: BorderSide(color: Colors.grey.shade300)),
                    ),
                    child: Text(
                      "${(_startHour + index).toString().padLeft(2, '0')}:00",
                      style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                          fontWeight: FontWeight.bold),
                    ),
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSyncedList() {
    return Row(
      children: [
        // Sidebar List
        SizedBox(
          width: _sidebarWidth,
          child: ListView.builder(
            itemCount: _filteredDietitians.length,
            physics: const ClampingScrollPhysics(),
            itemBuilder: (context, index) {
              return _buildSidebarItem(_filteredDietitians[index]);
            },
          ),
        ),
        // Timeline List
        Expanded(
          child: SingleChildScrollView(
            controller: _bodyScrollController,
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: (_endHour - _startHour) * _hourWidth,
              child: ListView.builder(
                itemCount: _filteredDietitians.length,
                physics: const ClampingScrollPhysics(),
                itemBuilder: (context, index) {
                  return _buildTimelineRow(_filteredDietitians[index]);
                },
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSidebarItem(Dietitian d) {
    return Container(
      height: _rowHeight,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade200),
          right: BorderSide(color: Colors.grey.shade300),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: Colors.blue.shade50,
            backgroundImage: NetworkImage(d.imageUrl),
            onBackgroundImageError: (_, __) => const Icon(Icons.person),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(d.name,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 13),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                Text(d.specialization,
                    style:
                    TextStyle(color: Colors.grey.shade500, fontSize: 11),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineRow(Dietitian d) {
    return Container(
      height: _rowHeight,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Stack(
        children: [
          // Background Grid
          Row(
            children: List.generate((_endHour - _startHour), (index) {
              return Container(
                width: _hourWidth,
                decoration: BoxDecoration(
                  border:
                  Border(right: BorderSide(color: Colors.grey.shade100)),
                ),
              );
            }),
          ),
          // Appointment Blocks
          ...d.appointments.map((apt) {
            final double startOffset =
                (apt.startTime.hour - _startHour) * _hourWidth +
                    (apt.startTime.minute / 60) * _hourWidth;

            final double durationHours =
                apt.endTime.difference(apt.startTime).inMinutes / 60.0;
            final double width = durationHours * _hourWidth;

            if (startOffset < 0) return const SizedBox();

            return Positioned(
              left: startOffset,
              top: 5,
              height: _rowHeight - 10,
              width: width,
              child: Container(
                margin: const EdgeInsets.only(right: 2),
                decoration: BoxDecoration(
                  color: apt.uiColor, // Using updated extension
                  border: Border(
                      left: BorderSide(color: apt.uiBorderColor, width: 3)),
                  borderRadius: BorderRadius.circular(4),
                ),
                padding: const EdgeInsets.all(5),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      apt.clientName ?? "Unknown",
                      style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      apt.statusText, // Using extension helper
                      style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          color: apt.uiBorderColor),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      "${apt.startTime.hour}:${apt.startTime.minute.toString().padLeft(2, '0')}",
                      style: const TextStyle(
                          fontSize: 9, color: Colors.black54),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }
}

// --- EXTENSION: Map your Enum to UI Colors & Strings ---

extension AppointmentUIHelpers on AppointmentModel {

  Color get uiColor {
    switch (status) {
      case AppointmentStatus.scheduled:
        return Colors.blue.shade50;
      case AppointmentStatus.confirmed:
        return Colors.indigo.shade50;
      case AppointmentStatus.pending:
        return Colors.orange.shade50;
      case AppointmentStatus.payment_pending:
        return Colors.deepOrange.shade50;
      case AppointmentStatus.verification_pending:
        return Colors.amber.shade50;
      case AppointmentStatus.completed:
        return Colors.green.shade50;
      case AppointmentStatus.cancelled:
        return Colors.grey.shade200;
      default:
        return Colors.grey.shade50;
    }
  }

  Color get uiBorderColor {
    switch (status) {
      case AppointmentStatus.scheduled:
        return Colors.blue;
      case AppointmentStatus.confirmed:
        return Colors.indigo;
      case AppointmentStatus.pending:
        return Colors.orange;
      case AppointmentStatus.payment_pending:
        return Colors.deepOrange;
      case AppointmentStatus.verification_pending:
        return Colors.amber;
      case AppointmentStatus.completed:
        return Colors.green;
      case AppointmentStatus.cancelled:
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  String get statusText {
    // Formats "payment_pending" to "Payment Pending"
    switch (status) {
      case AppointmentStatus.payment_pending: return "Payment Pending";
      case AppointmentStatus.verification_pending: return "Verify Pending";
      default: return status.name[0].toUpperCase() + status.name.substring(1);
    }
  }
}