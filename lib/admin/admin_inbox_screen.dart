import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:nutricare_client_management/admin/custom_gradient_app_bar.dart';

import 'admin_chat_screen.dart';
import 'services/admin_chat_service.dart';
import 'chat_message_model.dart';

class AdminInboxScreen extends StatefulWidget {
  const AdminInboxScreen({super.key});

  @override
  State<AdminInboxScreen> createState() => _AdminInboxScreenState();
}

class _AdminInboxScreenState extends State<AdminInboxScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final AdminChatService _chatService = AdminChatService();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";

  @override
  void initState() {
    super.initState();
    // Tab 1: Client List, Tab 2: Global Priority Tickets
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: CustomGradientAppBar(
        title: const Text("Inbox"),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.indigo,
          labelColor: Colors.indigo,
          tabs: const [
            Tab(text: "Clients", icon: Icon(Icons.people_alt)),
            Tab(text: "Global Tickets", icon: Icon(Icons.confirmation_number)),
          ],
        ),
      ),
      body: SafeArea(
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildClientListTab(),   // 🎯 Simplified List
            _buildGlobalTicketsTab(), // Keeps priority view
          ],
        ),
      ),
    );
  }

  // =================================================================
  // 🎯 TAB 1: SIMPLE CLIENT LIST (Sorted by Recency)
  // =================================================================

  Widget _buildClientListTab() {
    return Column(
      children: [
        // Search Bar
        Padding(
          padding: const EdgeInsets.all(12.0),
          child: TextField(
            controller: _searchController,
            onChanged: (val) => setState(() => _searchQuery = val.toLowerCase()),
            decoration: InputDecoration(
              hintText: "Search clients...",
              prefixIcon: const Icon(Icons.search, color: Colors.grey),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none),
              contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
            ),
          ),
        ),

        // Client Stream
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: _chatService.getAllChats(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              // 1. Get the raw list of documents
              var docs = snapshot.data?.docs ?? [];

              // 2. Client-side Search Filter
              if (_searchQuery.isNotEmpty) {
                docs = docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return (data['name'] ?? '')
                      .toString()
                      .toLowerCase()
                      .contains(_searchQuery);
                }).toList();
              }

              if (docs.isEmpty) {
                return const Center(child: Text("No clients found."));
              }

              // 3. APPLY SORTING LOGIC HERE
              // Sort by Active Tickets (High to Low) -> Then Name (A to Z)
              docs.sort((a, b) {
                final dataA = a.data() as Map<String, dynamic>;
                final dataB = b.data() as Map<String, dynamic>;

                // Fetch count, defaulting to 0.
                // If you use 'hasPendingRequest' boolean, we convert it to 1 or 0 for sorting
                int countA = dataA['activeTicketCount'] ?? (dataA['hasPendingRequest'] == true ? 1 : 0);
                int countB = dataB['activeTicketCount'] ?? (dataB['hasPendingRequest'] == true ? 1 : 0);

                // Primary Sort: Ticket Count (Descending)
                int ticketComparison = countB.compareTo(countA);
                if (ticketComparison != 0) return ticketComparison;

                // Secondary Sort: Name (Ascending)
                String nameA = (dataA['name'] ?? '').toString().toLowerCase();
                String nameB = (dataB['name'] ?? '').toString().toLowerCase();
                return nameA.compareTo(nameB);
              });

              return ListView.separated(
                itemCount: docs.length,
                separatorBuilder: (ctx, i) =>
                const Divider(height: 1, indent: 70),
                itemBuilder: (context, index) {
                  final data = docs[index].data() as Map<String, dynamic>;
                  final clientId = docs[index].id;
                  return _buildClientTile(clientId, data);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildClientTile(String clientId, Map<String, dynamic> data) {
    final clientName = data['name'] ?? 'Client';
    final lastMsg = data['lastMessage'] ?? '';
    final time = (data['lastMessageTime'] as Timestamp?)?.toDate();

    // Attempt to get the specific count, otherwise fallback to boolean check
    final int ticketCount = data['activeTicketCount'] ?? (data['hasPendingRequest'] == true ? 1 : 0);
    final bool hasRequest = ticketCount > 0;

    return ListTile(
      tileColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => AdminChatScreen(
                  clientId: clientId, clientName: clientName))),
      leading: Stack(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor:
            hasRequest ? Colors.red.shade50 : Colors.indigo.shade50,
            child: Text(
              clientName.isNotEmpty ? clientName[0].toUpperCase() : '?',
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: hasRequest ? Colors.red : Colors.indigo),
            ),
          ),
          // Small dot on avatar if they have a request
          if (hasRequest)
            const Positioned(
              right: 0,
              top: 0,
              child: CircleAvatar(
                  radius: 6,
                  backgroundColor: Colors.red,
                  child: Icon(Icons.priority_high,
                      size: 8, color: Colors.white)),
            )
        ],
      ),
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
              child: Text(clientName,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis)),
          if (time != null)
            Text(_formatTime(time),
                style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
        ],
      ),
      subtitle: Row(
        children: [
          Expanded(
            child: Text(lastMsg,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    fontWeight:
                    hasRequest ? FontWeight.bold : FontWeight.normal,
                    color: hasRequest ? Colors.black87 : Colors.grey)),
          ),
        ],
      ),
      // NEW: Visual Badge for Ticket Count
      trailing: ticketCount > 0
          ? Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.red.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.red.shade200),
        ),
        child: Text(
          '$ticketCount Active',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: Colors.red.shade900,
          ),
        ),
      )
          : const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
    );
  }

  // =================================================================
  // 🎯 TAB 2: GLOBAL TICKETS (Same as before)
  // =================================================================
  Widget _buildGlobalTicketsTab() {
    return StreamBuilder<List<ChatMessageModel>>(
      stream: _chatService.getActiveTickets(), // Only Pending Tickets
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        final tickets = snapshot.data ?? [];

        if (tickets.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.check_circle_outline, size: 60, color: Colors.green),
                SizedBox(height: 16),
                Text("All tickets resolved!", style: TextStyle(color: Colors.grey)),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: tickets.length,
          itemBuilder: (context, index) {
            final req = tickets[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: CircleAvatar(backgroundColor: Colors.orange.shade100, child: Icon(Icons.confirmation_number, color: Colors.orange.shade800)),
                title: Text(req.requestType.name.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                subtitle: Text(req.text, maxLines: 1, overflow: TextOverflow.ellipsis),
                trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AdminChatScreen(clientId: req.senderId, clientName: "Client"))),
              ),
            );
          },
        );
      },
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    if (now.difference(time).inDays == 0) return DateFormat('h:mm a').format(time);
    return DateFormat('MMM d').format(time);
  }
}