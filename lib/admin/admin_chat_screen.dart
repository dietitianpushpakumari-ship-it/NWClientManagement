import 'dart:io';
import 'dart:ui';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // 🎯 Added Riverpod
import 'package:intl/intl.dart';
import 'package:nutricare_client_management/admin/chat_audio_player.dart';
import 'package:nutricare_client_management/admin/chat_message_model.dart';
import 'package:nutricare_client_management/admin/full_screen_image_viewer.dart';
// import 'package:nutricare_client_management/image_compressor.dart'; // Uncomment if you have this file
// import 'package:nutricare_client_management/pdf_compressor.dart';   // Uncomment if you have this file
import 'package:url_launcher/url_launcher_string.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'package:nutricare_client_management/admin/services/admin_chat_service.dart';
import 'package:nutricare_client_management/screens/vitals_entry_form_screen.dart';

// 1️⃣ Convert to ConsumerStatefulWidget
class AdminChatScreen extends ConsumerStatefulWidget {
  final String clientId;
  final String clientName;

  const AdminChatScreen({super.key, required this.clientId, required this.clientName});

  @override
  ConsumerState<AdminChatScreen> createState() => _AdminChatScreenState();
}

class _AdminChatScreenState extends ConsumerState<AdminChatScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _textController = TextEditingController();
  late TabController _tabController;
  final ScrollController _scrollController = ScrollController();
  List<ChatMessageModel> _allMessages = [];
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToMessage(String targetId) {
    // Scroll logic placeholder
  }

  // 2️⃣ Use the Service from the Provider
  void _sendMessage(AdminChatService service) {
    if (_textController.text.trim().isEmpty) return;
    service.sendAdminMessage(
        clientId: widget.clientId,
        text: _textController.text.trim(),
        type: MessageType.text
    );
    _textController.clear();
  }

  Future<void> _handleUpload(FileType type) async {
    // Implement your file picker logic here using _service
  }

  void _markTicketClosed(AdminChatService service, ChatMessageModel msg) {
    service.updateRequestStatus(
      widget.clientId,
      msg.id,
      RequestStatus.completed,
      "Closed",
    );
  }

  void _navigateToVitalsEntry() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VitalsEntryScreen(
          clientId: widget.clientId,
          clientName: widget.clientName,
          onVitalsSaved: () {},
          isFirstConsultation: false,
        ),
      ),
    );
  }

  // --- TICKET ACTIONS ---

  void _showQuickReplies(AdminChatService service, ChatMessageModel msg) {
    final replies = [
      "✅ Approved",
      "⚠️ Reduce Portion",
      "❌ Avoid This",
      "🥗 Add Veggies",
      "💧 Drink Water",
    ];
    final commentController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Respond to Query", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: replies.map((reply) => ActionChip(
                  label: Text(reply),
                  backgroundColor: Colors.green.shade50,
                  onPressed: () {
                    String current = commentController.text;
                    commentController.text = current.isEmpty ? reply : "$current $reply";
                  },
                )).toList(),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: commentController,
                decoration: const InputDecoration(labelText: "Your Response", border: OutlineInputBorder(), hintText: "Type or select chips..."),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.send),
                  label: const Text("Send Response"),
                  style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.primary, foregroundColor: Colors.white),
                  onPressed: () {
                    if (commentController.text.isEmpty) return;
                    Navigator.pop(context);
                    service.sendAdminMessage(
                      clientId: widget.clientId,
                      text: commentController.text,
                      type: MessageType.text,
                      replyTo: msg,
                    );
                    service.updateRequestStatus(
                      widget.clientId,
                      msg.id,
                      RequestStatus.approved,
                      commentController.text,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleAppointment(AdminChatService service, ChatMessageModel msg) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Appointment Action", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.check_circle, color: Colors.green),
              title: const Text("Confirm Appointment"),
              onTap: () {
                Navigator.pop(context);
                service.updateRequestStatus(widget.clientId, msg.id, RequestStatus.approved, "Confirmed");
                service.sendAdminMessage(clientId: widget.clientId, text: "✅ Appointment Confirmed.", type: MessageType.text, replyTo: msg);
              },
            ),
            ListTile(
              leading: const Icon(Icons.schedule, color: Colors.orange),
              title: const Text("Reschedule"),
              onTap: () async {
                Navigator.pop(context);
                DateTime? picked = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now().add(const Duration(days: 1)),
                  firstDate: DateTime.now(),
                  lastDate: DateTime(2030),
                );
                if (picked != null) {
                  String newDateStr = DateFormat.yMMMd().format(picked);
                  service.updateRequestStatus(widget.clientId, msg.id, RequestStatus.pending, "Rescheduled to $newDateStr");
                  service.sendAdminMessage(clientId: widget.clientId, text: "📅 Could we reschedule to $newDateStr?", type: MessageType.text, replyTo: msg);
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.cancel, color: Colors.red),
              title: const Text("Reject / Cancel"),
              onTap: () {
                Navigator.pop(context);
                _showRejectionDialog(context, service, msg);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showRejectionDialog(BuildContext context, AdminChatService service, ChatMessageModel message) {
    final TextEditingController reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reject Request'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Please enter a reason for rejection:'),
            const SizedBox(height: 10),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(hintText: 'Reason (e.g., Invalid documents)', border: OutlineInputBorder()),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              if (reasonController.text.trim().isEmpty) return;
              Navigator.of(ctx).pop();
              service.rejectRequest(message.id, reasonController.text.trim());
            },
            child: const Text('Reject', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 3️⃣ Get the correct service instance from Riverpod
    final service = ref.watch(adminChatServiceProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFEFEFEF),
      body: Stack(
        children: [
          Positioned(top: -100, right: -100, child: Container(width: 300, height: 300, decoration: BoxDecoration(shape: BoxShape.circle, boxShadow: [BoxShadow(color: Theme.of(context).colorScheme.primary.withOpacity(0.1), blurRadius: 80, spreadRadius: 30)]))),

          SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: StreamBuilder<List<ChatMessageModel>>(
                    stream: service.getMessages(widget.clientId), // Uses correct DB
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                      _allMessages = snapshot.data!;

                      return TabBarView(
                        controller: _tabController,
                        children: [
                          _buildTicketDashboard(_allMessages, service),
                          _buildChatStream(_allMessages, service),
                        ],
                      );
                    },
                  ),
                ),
                if (_isUploading) const LinearProgressIndicator(minHeight: 2),
                _buildInputArea(service),
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
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
                child: Row(
                  children: [
                    GestureDetector(onTap: () => Navigator.pop(context), child: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]), child: const Icon(Icons.arrow_back, size: 20))),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.clientName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1A1A1A))),
                        Text("Support & Tickets", style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                      ],
                    )
                  ],
                ),
              ),
              TabBar(
                controller: _tabController,
                indicatorColor: Theme.of(context).colorScheme.primary,
                labelColor: Theme.of(context).colorScheme.primary,
                unselectedLabelColor: Colors.grey,
                tabs: const [
                  Tab(text: "Tickets", icon: Icon(Icons.confirmation_number, size: 18)),
                  Tab(text: "Chat", icon: Icon(Icons.chat, size: 18)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTicketDashboard(List<ChatMessageModel> messages, AdminChatService service) {
    final active = messages.where((m) => m.type == MessageType.request && m.requestStatus == RequestStatus.pending).toList();
    final closed = messages.where((m) => m.type == MessageType.request && m.requestStatus != RequestStatus.pending).toList();

    if (active.isEmpty && closed.isEmpty) return const Center(child: Text("No tickets raised yet."));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildSection("Active Tickets", active, true, Colors.red, service),
          const SizedBox(height: 16),
          _buildSection("Closed History", closed, false, Colors.grey, service),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<ChatMessageModel> msgs, bool isActive, Color color, AdminChatService service) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        initiallyExpanded: isActive,
        leading: Icon(Icons.folder, color: color),
        title: Text("$title (${msgs.length})", style: const TextStyle(fontWeight: FontWeight.bold)),
        children: msgs.isEmpty
            ? [const Padding(padding: EdgeInsets.all(16), child: Text("Empty"))]
            : msgs.map((m) => AdminMessageBubble(
          key: ValueKey(m.id),
          msg: m,
          isDashboardView: true,
          clientId: widget.clientId,
          clientName: widget.clientName,
          service: service, // 🎯 Passing correct service
          onReplyTap: (id) => _scrollToMessage(id),
          parent: this,
        )).toList(),
      ),
    );
  }

  Widget _buildChatStream(List<ChatMessageModel> messages, AdminChatService service) {
    return ListView.builder(
      controller: _scrollController,
      reverse: true,
      cacheExtent: 2000,
      padding: const EdgeInsets.all(12),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final msg = messages[index];
        bool showDateHeader = false;
        if (index == messages.length - 1) {
          showDateHeader = true;
        } else {
          final olderMsg = messages[index + 1];
          if (!_isSameDay(msg.timestamp, olderMsg.timestamp)) {
            showDateHeader = true;
          }
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (showDateHeader) _buildDateHeader(msg.timestamp),
            AdminMessageBubble(
              key: ValueKey(msg.id),
              msg: msg,
              isDashboardView: false,
              clientId: widget.clientId,
              clientName: widget.clientName,
              service: service, // 🎯 Passing correct service
              onReplyTap: (id) => _scrollToMessage(id),
              parent: this,
            ),
          ],
        );
      },
    );
  }

  Widget _buildInputArea(AdminChatService service) {
    return Container(
      padding: const EdgeInsets.all(8),
      color: Colors.white,
      child: Row(
        children: [
          IconButton(icon: const Icon(Icons.image, color: Colors.blueGrey), onPressed: () => _handleUpload(FileType.image)),
          IconButton(icon: const Icon(Icons.attach_file, color: Colors.blueGrey), onPressed: () => _handleUpload(FileType.any)),
          Expanded(
            child: TextField(
              controller: _textController,
              decoration: InputDecoration(
                hintText: "Admin Reply...",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                filled: true,
                fillColor: Colors.grey.shade100,
              ),
            ),
          ),
          IconButton(
            icon: Icon(Icons.send, color: Theme.of(context).colorScheme.primary),
            onPressed: () => _sendMessage(service),
          ),
        ],
      ),
    );
  }

  String _getDateLabel(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final checkDate = DateTime(date.year, date.month, date.day);

    if (checkDate == today) return "Today";
    if (checkDate == yesterday) return "Yesterday";
    return DateFormat.yMMMd().format(date);
  }

  bool _isSameDay(DateTime d1, DateTime d2) {
    return d1.year == d2.year && d1.month == d2.month && d1.day == d2.day;
  }

  Widget _buildDateHeader(DateTime date) {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 16),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 2)]),
        child: Text(_getDateLabel(date), style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey.shade800)),
      ),
    );
  }
}

// 4️⃣ Updated Message Bubble to use the passed service
class AdminMessageBubble extends StatefulWidget {
  final ChatMessageModel msg;
  final bool isDashboardView;
  final String clientId;
  final String clientName;
  final AdminChatService service; // 🎯 Received from parent
  final Function(String) onReplyTap;
  final _AdminChatScreenState parent; // Access to parent methods

  const AdminMessageBubble({
    super.key,
    required this.msg,
    required this.isDashboardView,
    required this.clientId,
    required this.clientName,
    required this.service,
    required this.onReplyTap,
    required this.parent,
  });

  @override
  State<AdminMessageBubble> createState() => _AdminMessageBubbleState();
}

class _AdminMessageBubbleState extends State<AdminMessageBubble> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  // 🚫 REMOVED: AdminChatService _service = AdminChatService();
  // We will use widget.service instead!

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final msg = widget.msg;
    final isMe = !msg.isSenderClient;
    final isRequest = msg.type == MessageType.request;
    final isClosed = msg.requestStatus == RequestStatus.completed;
    final hasReply = msg.replyToMessageId != null;

    if (widget.isDashboardView && !isRequest) return const SizedBox.shrink();

    // Media Check
    // final bool hasMedia = (msg.attachmentUrl != null) || (msg.attachmentUrls != null && msg.attachmentUrls!.isNotEmpty);

    final Color bubbleColor = isRequest
        ? (isClosed ? Colors.grey.shade200 : Colors.orange.shade50)
        : (isMe ? Theme.of(context).colorScheme.primary.withOpacity(.1) : Colors.white);

    final Alignment align = widget.isDashboardView ? Alignment.center : (isMe ? Alignment.centerRight : Alignment.centerLeft);
    final double width = widget.isDashboardView ? double.infinity : MediaQuery.of(context).size.width * 0.85;

    return Align(
      alignment: align,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        constraints: BoxConstraints(maxWidth: width),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: bubbleColor,
          borderRadius: BorderRadius.circular(12),
          border: isRequest ? Border.all(color: isClosed ? Colors.grey : Colors.orange.shade200) : Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. REPLY PREVIEW
            if (hasReply && !widget.isDashboardView)
              GestureDetector(
                onTap: () => widget.onReplyTap(msg.replyToMessageId!),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(8),
                    border: Border(left: BorderSide(color: isMe ? Theme.of(context).colorScheme.primary : Colors.orange, width: 4)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(isMe ? "You replied to:" : "Replied to:", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isMe ? Theme.of(context).colorScheme.primary : Colors.orange)),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          if (msg.replyToMessageType == MessageType.request) const Icon(Icons.confirmation_number, size: 12, color: Colors.grey),
                          const SizedBox(width: 4),
                          Expanded(child: Text(msg.replyToMessageText ?? "Message", maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, color: Colors.grey))),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

            // 2. TICKET HEADER
            if (isRequest) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(_getRequestIcon(msg.requestType), size: 16, color: isClosed ? Colors.grey : Colors.orange.shade900),
                      const SizedBox(width: 6),
                      Text(isClosed ? "CLOSED" : msg.ticketId != null ? "${msg.ticketId}" : "TICKET: ${msg.requestType}", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: isClosed ? Colors.grey : Colors.orange.shade900)),
                    ],
                  ),
                  if (!isClosed) _buildStatusChip(msg.requestStatus),
                ],
              ),
              const Divider(),
            ],

            // 3. MEDIA CONTENT
            _buildMediaPreview(msg, isMe: isMe),

            // 4. TEXT
            if (msg.text.isNotEmpty)
              Text(msg.text, style: TextStyle(fontSize: 15, color: isClosed ? Colors.grey.shade600 : Colors.black87)),

            if (msg.metadata != null)
              Padding(padding: const EdgeInsets.only(top: 4), child: Text("📝 ${msg.metadata}", style: TextStyle(fontSize: 11, color: Colors.grey.shade600))),

            // 5. ACTIONS
            if (isRequest && !isClosed && widget.isDashboardView)
              Padding(
                padding: const EdgeInsets.only(top: 12.0),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          if (msg.requestType == RequestType.labReport) {
                            widget.parent._navigateToVitalsEntry();
                          } else if (msg.requestType == RequestType.mealQuery) {
                            widget.parent._showQuickReplies(widget.service, msg); // 🎯 Use correct service
                          } else if (msg.requestType == RequestType.appointment) {
                            widget.parent._handleAppointment(widget.service, msg); // 🎯 Use correct service
                          } else {
                            widget.parent._showQuickReplies(widget.service, msg); // 🎯 Use correct service
                          }
                        },
                        child: const Text("Respond"),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => widget.parent._markTicketClosed(widget.service, msg), // 🎯 Use correct service
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.grey.shade800, foregroundColor: Colors.white),
                        child: const Text("Close Ticket"),
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 4),
            Align(alignment: Alignment.bottomRight, child: Text(DateFormat('h:mm a').format(msg.timestamp), style: TextStyle(fontSize: 10, color: Colors.grey.shade500))),
          ],
        ),
      ),
    );
  }

  Widget _buildMediaPreview(ChatMessageModel msg, {required bool isMe}) {
    List<String> images = [];
    if (msg.attachmentUrls != null && msg.attachmentUrls!.isNotEmpty) {
      images = msg.attachmentUrls!;
    } else if (msg.attachmentUrl != null) {
      images = [msg.attachmentUrl!];
    }

    if (images.isNotEmpty) {
      final first = images.first;
      if (!_isImageFile(first) && msg.type != MessageType.image) {
        if (_isAudioFile(msg.attachmentName) || msg.type == MessageType.audio) {
          return ChatAudioPlayer(audioUrl: msg.attachmentUrl!, isSender: isMe);
        }
        return _buildFileContent(msg);
      }

      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Wrap(
          spacing: 4,
          runSpacing: 4,
          children: images.map((url) {
            return GestureDetector(
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => FullScreenImageViewer(imageUrl: url))),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: images.length > 1 ? 100 : 220,
                  height: images.length > 1 ? 100 : 180,
                  child: CachedNetworkImage(
                    imageUrl: url,
                    fit: BoxFit.cover,
                    memCacheWidth: 400,
                    placeholder: (_, __) => Container(color: Colors.grey[200]),
                    errorWidget: (_, __, ___) => const Icon(Icons.broken_image, color: Colors.grey),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildFileContent(ChatMessageModel msg) {
    return InkWell(
      onTap: () => launchUrlString(msg.attachmentUrl!, mode: LaunchMode.externalApplication),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: Colors.black.withOpacity(0.05), borderRadius: BorderRadius.circular(8)),
        child: Row(
          children: [
            const Icon(Icons.picture_as_pdf, color: Colors.red),
            const SizedBox(width: 8),
            Flexible(child: Text(msg.attachmentName ?? "View Document", style: const TextStyle(decoration: TextDecoration.underline, color: Colors.blue))),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(RequestStatus status) {
    Color color = status == RequestStatus.pending ? Colors.orange : (status == RequestStatus.approved ? Colors.green : Colors.red);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
      child: Text(status.name.toUpperCase(), style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.bold)),
    );
  }

  IconData _getRequestIcon(RequestType t) {
    switch (t) {
      case RequestType.mealQuery: return Icons.restaurant;
      case RequestType.appointment: return Icons.calendar_today;
      case RequestType.labReport: return Icons.science;
      default: return Icons.star;
    }
  }

  bool _isImageFile(String? path) {
    if (path == null) return false;
    final ext = path.split('?').first.split('.').last.toLowerCase();
    return ['jpg', 'jpeg', 'png', 'webp'].contains(ext);
  }

  bool _isAudioFile(String? path) {
    if (path == null) return false;
    final ext = path.split('?').first.split('.').last.toLowerCase();
    return ['mp3', 'wav', 'm4a'].contains(ext);
  }
}