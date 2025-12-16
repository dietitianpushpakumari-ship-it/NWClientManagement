import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // 🎯 Added Riverpod
import 'package:intl/intl.dart';
import 'admin_chat_screen.dart';
import 'services/admin_chat_service.dart';
import 'chat_message_model.dart';

class AdminInboxScreen extends ConsumerStatefulWidget {
  const AdminInboxScreen({super.key});

  @override
  ConsumerState<AdminInboxScreen> createState() => _AdminInboxScreenState();
}

class _AdminInboxScreenState extends ConsumerState<AdminInboxScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";

  @override
  void initState() {
    super.initState();
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
    // 🎯 CRITICAL FIX: Get the service instance that is connected to the Tenant DB
    final chatService = ref.watch(adminChatServiceProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      body: Stack(
        children: [
          // Ambient Glow
          Positioned(
              top: -100, right: -100,
              child: Container(width: 300, height: 300, decoration: BoxDecoration(shape: BoxShape.circle, boxShadow: [BoxShadow(color: Theme.of(context).colorScheme.primary.withOpacity(0.1), blurRadius: 80, spreadRadius: 30)]))),

          SafeArea(
            child: Column(
              children: [
                // 1. Custom Glass Header with Tabs
                _buildHeader(),

                // 2. Tab Views
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      // Pass the correct service to the tabs
                      _buildClientListTab(chatService),
                      _buildGlobalTicketsTab(chatService),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(color: Colors.white.withOpacity(0.8), border: Border(bottom: BorderSide(color: Colors.grey.withOpacity(0.1)))),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
                child: Row(
                  children: [
                    GestureDetector(onTap: () => Navigator.pop(context), child: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]), child: const Icon(Icons.arrow_back, size: 20))),
                    const SizedBox(width: 16),
                    const Text("Inbox", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1A1A1A))),
                  ],
                ),
              ),
              TabBar(
                controller: _tabController,
                indicatorColor: Theme.of(context).colorScheme.primary,
                labelColor: Theme.of(context).colorScheme.primary,
                unselectedLabelColor: Colors.grey,
                tabs: const [
                  Tab(text: "Clients", icon: Icon(Icons.people_alt)),
                  Tab(text: "Global Tickets", icon: Icon(Icons.confirmation_number)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 🎯 Updated to accept AdminChatService
  Widget _buildClientListTab(AdminChatService chatService) {
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
            stream: chatService.getAllChats(), // 🎯 Uses correct DB
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              var docs = snapshot.data?.docs ?? [];

              // Search Filter
              if (_searchQuery.isNotEmpty) {
                docs = docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return (data['name'] ?? '').toString().toLowerCase().contains(_searchQuery);
                }).toList();
              }

              if (docs.isEmpty) return const Center(child: Text("No clients found."));

              // Sorting: Tickets First, then Alphabetical
              docs.sort((a, b) {
                final dataA = a.data() as Map<String, dynamic>;
                final dataB = b.data() as Map<String, dynamic>;
                int countA = dataA['activeTicketCount'] ?? (dataA['hasPendingRequest'] == true ? 1 : 0);
                int countB = dataB['activeTicketCount'] ?? (dataB['hasPendingRequest'] == true ? 1 : 0);
                int ticketComparison = countB.compareTo(countA);
                if (ticketComparison != 0) return ticketComparison;
                String nameA = (dataA['name'] ?? '').toString().toLowerCase();
                String nameB = (dataB['name'] ?? '').toString().toLowerCase();
                return nameA.compareTo(nameB);
              });

              return ListView.separated(
                itemCount: docs.length,
                separatorBuilder: (ctx, i) => const Divider(height: 1, indent: 70),
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
    final int ticketCount = data['activeTicketCount'] ?? (data['hasPendingRequest'] == true ? 1 : 0);

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AdminChatScreen(clientId: clientId, clientName: clientName))),
      leading: CircleAvatar(
        radius: 24,
        backgroundColor: ticketCount > 0 ? Colors.red.shade50 : Theme.of(context).colorScheme.primary.withOpacity(.1),
        child: Text(clientName.isNotEmpty ? clientName[0].toUpperCase() : '?', style: TextStyle(fontWeight: FontWeight.bold, color: ticketCount > 0 ? Colors.red : Theme.of(context).colorScheme.primary)),
      ),
      title: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Expanded(child: Text(clientName, style: const TextStyle(fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis)),
        if (time != null) Text(_formatTime(time), style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
      ]),
      subtitle: Text(lastMsg, maxLines: 1, overflow: TextOverflow.ellipsis),
      trailing: ticketCount > 0 ? Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: Colors.red.shade100, borderRadius: BorderRadius.circular(12)), child: Text('$ticketCount Active', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.red.shade900))) : null,
    );
  }

  // 🎯 Updated to accept AdminChatService
  Widget _buildGlobalTicketsTab(AdminChatService chatService) {
    return StreamBuilder<List<ChatMessageModel>>(
      stream: chatService.getActiveTickets(), // 🎯 Uses correct DB
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        final tickets = snapshot.data ?? [];

        if (tickets.isEmpty) {
          return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: const [Icon(Icons.check_circle_outline, size: 60, color: Colors.green), SizedBox(height: 16), Text("All tickets resolved!", style: TextStyle(color: Colors.grey))]));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: tickets.length,
          itemBuilder: (context, index) {
            final req = tickets[index];
            return Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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