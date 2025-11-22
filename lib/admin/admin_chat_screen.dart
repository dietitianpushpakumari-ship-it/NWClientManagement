import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:nutricare_client_management/admin/chat_audio_player.dart';
import 'package:nutricare_client_management/admin/chat_message_model.dart';
import 'package:nutricare_client_management/admin/custom_gradient_app_bar.dart';
import 'package:nutricare_client_management/admin/full_screen_image_viewer.dart';
import 'package:nutricare_client_management/image_compressor.dart';
import 'package:nutricare_client_management/pdf_compressor.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cached_network_image/cached_network_image.dart'; // 🎯 Essential for caching

// 🎯 Project Imports
import 'package:nutricare_client_management/admin/services/admin_chat_service.dart';
import 'package:nutricare_client_management/screens/vitals_entry_form_screen.dart';

class AdminChatScreen extends StatefulWidget {
  final String clientId;
  final String clientName;

  const AdminChatScreen({
    super.key,
    required this.clientId,
    required this.clientName,
  });

  @override
  State<AdminChatScreen> createState() => _AdminChatScreenState();
}

class _AdminChatScreenState extends State<AdminChatScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _textController = TextEditingController();
  final AdminChatService _service = AdminChatService();
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
    final index = _allMessages.indexWhere((m) => m.id == targetId);
    if (index != -1) {
      _scrollController.animateTo(
        index * 100.0,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOut,
      );
    }
  }

  // --- SEND MESSAGE ---
  void _sendMessage() {
    if (_textController.text.trim().isEmpty) return;
    _service.sendAdminMessage(
      clientId: widget.clientId,
      text: _textController.text.trim(),
      type: MessageType.text,
    );
    _textController.clear();
  }

  // --- FILE UPLOAD ---
  Future<void> _handleUpload(FileType type) async {
    final result = await FilePicker.platform.pickFiles(type: type);
    if (result != null && result.files.single.path != null) {
      setState(() => _isUploading = true);
      File file = File(result.files.single.path!);
      String name = result.files.single.name;
      String ext = name.split('.').last.toLowerCase();

      if (['jpg', 'jpeg', 'png'].contains(ext)) {
        File? c = await ImageCompressor.compressAndGetFile(file);
        if (c != null) {
          file = c;
          name = "${name.split('.').first}.webp";
        }
      } else if (ext == 'pdf') {
        File? c = await PdfCompressor.compress(file);
        if (c != null) file = c;
      }

      MessageType msgType = ['jpg', 'jpeg', 'png', 'webp'].contains(ext)
          ? MessageType.image
          : (['mp3', 'wav', 'm4a', 'aac'].contains(ext)
                ? MessageType.audio
                : MessageType.file);

      await _service.sendAdminMessage(
        clientId: widget.clientId,
        text: "",
        type: msgType,
        attachmentFile: file,
        attachmentName: name,
      );
      setState(() => _isUploading = false);
    }
  }

  // ===============================================================
  // 🚀 MAIN BUILD
  // ===============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEFEFEF),
      appBar: CustomGradientAppBar(
          title: const Text('Support Dashboard '),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.indigo,
          labelColor: Colors.indigo,
          tabs: const [
            Tab(text: "Tickets", icon: Icon(Icons.confirmation_number)),
            Tab(text: "Chat", icon: Icon(Icons.chat)),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: StreamBuilder<List<ChatMessageModel>>(
                stream: _service.getMessages(widget.clientId),
                builder: (context, snapshot) {
                  if (!snapshot.hasData)
                    return const Center(child: CircularProgressIndicator());
                  _allMessages = snapshot.data!;

                  return TabBarView(
                    controller: _tabController,
                    children: [
                      _buildTicketDashboard(_allMessages),
                      _buildChatStream(_allMessages),
                    ],
                  );
                },
              ),
            ),
            if (_isUploading) const LinearProgressIndicator(minHeight: 2),
            _buildInputArea(),
          ],
        ),
      ),
    );
  }

  // --- TAB 1: TICKETS ---
  Widget _buildTicketDashboard(List<ChatMessageModel> messages) {
    final active = messages
        .where(
          (m) =>
              m.type == MessageType.request &&
              m.requestStatus == RequestStatus.pending,
        )
        .toList();
    final closed = messages
        .where(
          (m) =>
              m.type == MessageType.request &&
              m.requestStatus != RequestStatus.pending,
        )
        .toList();

    if (active.isEmpty && closed.isEmpty)
      return const Center(child: Text("No tickets raised yet."));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildSection("Active Tickets", active, true, Colors.red),
          const SizedBox(height: 16),
          _buildSection("Closed History", closed, false, Colors.grey),
        ],
      ),
    );
  }

  Widget _buildSection(
    String title,
    List<ChatMessageModel> msgs,
    bool isActive,
    Color color,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        initiallyExpanded: isActive,
        leading: Icon(Icons.folder, color: color),
        title: Text(
          "$title (${msgs.length})",
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        children: msgs.isEmpty
            ? [const Padding(padding: EdgeInsets.all(16), child: Text("Empty"))]
            // 🎯 USE OPTIMIZED BUBBLE HERE
            : msgs
                  .map(
                    (m) => AdminMessageBubble(
                      key: ValueKey(m.id),
                      msg: m,
                      isDashboardView: true,
                      clientId: widget.clientId,
                      clientName: widget.clientName,
                      service: _service,
                      onReplyTap: (id) => _scrollToMessage(id),
                    ),
                  )
                  .toList(),
      ),
    );
  }

  // --- TAB 2: CHAT STREAM ---
  Widget _buildChatStream(List<ChatMessageModel> messages) {
    return ListView.builder(
      controller: _scrollController,
      reverse: true,
      // 🎯 PERFORMANCE: Pre-load items off screen
      cacheExtent: 2000,
      padding: const EdgeInsets.all(12),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final msg = messages[index];
        bool showDateHeader = false;
        if (index == messages.length - 1) {
          showDateHeader = true; // Always show header for the oldest message
        } else {
          final olderMsg = messages[index + 1];
          if (!_isSameDay(msg.timestamp, olderMsg.timestamp)) {
            showDateHeader = true;
          }
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. The Date Header (Appears ABOVE the message group visually)
            if (showDateHeader)
              _buildDateHeader(msg.timestamp),

            // 2. The Actual Message Bubble
            AdminMessageBubble(
              key: ValueKey(msg.id),
              msg: msg,
              isDashboardView: false,
              clientId: widget.clientId,
              clientName: widget.clientName,
              service: _service,
              onReplyTap: (id) => _scrollToMessage(id),
            ),
          ],
        );
      },
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(8),
      color: Colors.white,
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.image, color: Colors.blueGrey),
            onPressed: () => _handleUpload(FileType.image),
          ),
          IconButton(
            icon: const Icon(Icons.attach_file, color: Colors.blueGrey),
            onPressed: () => _handleUpload(FileType.any),
          ),
          Expanded(
            child: TextField(
              controller: _textController,
              decoration: InputDecoration(
                hintText: "Admin Reply...",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey.shade100,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.send, color: Colors.indigo),
            onPressed: _sendMessage,
          ),
        ],
      ),
    );
  }


  // 1. Logic to format the date text (Today, Yesterday, or Date)
  String _getDateLabel(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final checkDate = DateTime(date.year, date.month, date.day);

    if (checkDate == today) return "Today";
    if (checkDate == yesterday) return "Yesterday";
    return DateFormat.yMMMd().format(date); // e.g., Oct 24, 2025
  }

  // 2. Logic to compare two dates
  bool _isSameDay(DateTime d1, DateTime d2) {
    return d1.year == d2.year && d1.month == d2.month && d1.day == d2.day;
  }

  // 3. The UI Widget for the Date Header (WhatsApp Style)
  Widget _buildDateHeader(DateTime date) {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 16),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
            color: Colors.grey.shade300,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 2)
            ]
        ),
        child: Text(
          _getDateLabel(date),
          style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800
          ),
        ),
      ),
    );
  }
}

// =================================================================
// 🎯 OPTIMIZED ADMIN BUBBLE (STATEFUL + KEEPALIVE)
// =================================================================

class AdminMessageBubble extends StatefulWidget {
  final ChatMessageModel msg;
  final bool isDashboardView;
  final String clientId;
  final String clientName;
  final AdminChatService service;
  final Function(String) onReplyTap;

  const AdminMessageBubble({
    super.key,
    required this.msg,
    required this.isDashboardView,
    required this.clientId,
    required this.clientName,
    required this.service,
    required this.onReplyTap,
  });

  @override
  State<AdminMessageBubble> createState() => _AdminMessageBubbleState();
}

class _AdminMessageBubbleState extends State<AdminMessageBubble>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true; // 🎯 CRITICAL: Prevents rebuild on scroll
  AdminChatService _service = AdminChatService();

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
    final bool hasMedia =
        (msg.attachmentUrl != null) ||
        (msg.attachmentUrls != null && msg.attachmentUrls!.isNotEmpty);

    // Styles
    final Color bubbleColor = isRequest
        ? (isClosed ? Colors.grey.shade200 : Colors.orange.shade50)
        : (isMe ? Colors.indigo.shade50 : Colors.white);

    final Alignment align = widget.isDashboardView
        ? Alignment.center
        : (isMe ? Alignment.centerRight : Alignment.centerLeft);
    final double width = widget.isDashboardView
        ? double.infinity
        : MediaQuery.of(context).size.width * 0.85;

    return Align(
      alignment: align,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        constraints: BoxConstraints(maxWidth: width),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: bubbleColor,
          borderRadius: BorderRadius.circular(12),
          border: isRequest
              ? Border.all(
                  color: isClosed ? Colors.grey : Colors.orange.shade200,
                )
              : Border.all(color: Colors.grey.shade200),
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
                    border: Border(
                      left: BorderSide(
                        color: isMe ? Colors.indigo : Colors.orange,
                        width: 4,
                      ),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isMe ? "You replied to:" : "Replied to:",
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: isMe ? Colors.indigo : Colors.orange,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          if (msg.replyToMessageType == MessageType.request)
                            const Icon(
                              Icons.confirmation_number,
                              size: 12,
                              color: Colors.grey,
                            ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              msg.replyToMessageText ?? "Message",
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 11,
                                color: Colors.grey,
                              ),
                            ),
                          ),
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
                     Icon(
                        _getRequestIcon(msg.requestType),
                        size: 16,
                        color: isClosed ? Colors.grey : Colors.orange.shade900,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        isClosed
                            ? "CLOSED"
                            : msg.ticketId != null ? "${msg.ticketId}" :  "TICKET: ${msg.requestType}",
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isClosed
                              ? Colors.grey
                              : Colors.orange.shade900,
                        ),
                      ),
                    /*  if (msg.ticketId != null) ...[
                        const SizedBox(width: 6),
                        Text(
                          msg.ticketId!,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: isClosed ? Colors.grey : Colors.orange.shade900,
                          ),
                        ),*/
                     // ],
                    ],
                  ),
                  if (!isClosed) _buildStatusChip(msg.requestStatus),
                ],
              ),
              const Divider(),
            ],

            // 3. MEDIA CONTENT (Optimized)
            _buildMediaPreview(msg, isMe: isMe),

            // 4. TEXT
            if (msg.text.isNotEmpty)
              Text(
                msg.text,
                style: TextStyle(
                  fontSize: 15,
                  color: isClosed ? Colors.grey.shade600 : Colors.black87,
                ),
              ),

            if (msg.metadata != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  "📝 ${msg.metadata}",
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                ),
              ),

            // 5. ACTIONS
            if (isRequest && !isClosed && widget.isDashboardView)
              Padding(
                padding: const EdgeInsets.only(top: 12.0),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          if (msg.requestType == RequestType.labReport)
                            _navigateToVitalsEntry();
                          else if (msg.requestType == RequestType.mealQuery)
                            _showQuickReplies(msg);
                          else if (msg.requestType == RequestType.appointment)
                            _handleAppointment(msg);
                          else
                            _showQuickReplies(msg);
                        },
                        child: const Text("Respond"),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _markTicketClosed(msg),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey.shade800,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text("Close Ticket"),
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 4),
            Align(
              alignment: Alignment.bottomRight,
              child: Text(
                DateFormat('h:mm a').format(msg.timestamp),
                style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 🎯 OPTIMIZED MEDIA PREVIEW
  Widget _buildMediaPreview(ChatMessageModel msg, {required bool isMe}) {
    List<String> images = [];

    // 1. Identify Images
    if (msg.attachmentUrls != null && msg.attachmentUrls!.isNotEmpty) {
      images = msg.attachmentUrls!;
    } else if (msg.attachmentUrl != null) {
      images = [msg.attachmentUrl!];
    }

    // 2. Render Content
    if (images.isNotEmpty) {
      final first = images.first;

      // Check types
      if (!_isImageFile(first) && msg.type != MessageType.image) {
        if (_isAudioFile(msg.attachmentName) || msg.type == MessageType.audio) {
          return ChatAudioPlayer(audioUrl: msg.attachmentUrl!, isSender: isMe);
        }
        return _buildFileContent(msg);
      }

      // 🎯 IMAGE GRID (With Caching)
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Wrap(
          spacing: 4,
          runSpacing: 4,
          children: images.map((url) {
            return GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => FullScreenImageViewer(imageUrl: url),
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: images.length > 1 ? 100 : 220,
                  height: images.length > 1 ? 100 : 180,
                  child: CachedNetworkImage(
                    imageUrl: url,
                    fit: BoxFit.cover,
                    memCacheWidth: 400,
                    // 🎯 KEY PERF FIX: Decode small
                    placeholder: (_, __) => Container(color: Colors.grey[200]),
                    errorWidget: (_, __, ___) =>
                        const Icon(Icons.broken_image, color: Colors.grey),
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

  // --- HELPER METHODS ---

  Widget _buildFileContent(ChatMessageModel msg) {
    return InkWell(
      onTap: () => launchUrlString(
        msg.attachmentUrl!,
        mode: LaunchMode.externalApplication,
      ),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.05),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            const Icon(Icons.picture_as_pdf, color: Colors.red),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                msg.attachmentName ?? "View Document",
                style: const TextStyle(
                  decoration: TextDecoration.underline,
                  color: Colors.blue,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(RequestStatus status) {
    Color color = status == RequestStatus.pending
        ? Colors.orange
        : (status == RequestStatus.approved ? Colors.green : Colors.red);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        status.name.toUpperCase(),
        style: TextStyle(
          fontSize: 10,
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  IconData _getRequestIcon(RequestType t) {
    switch (t) {
      case RequestType.mealQuery:
        return Icons.restaurant;
      case RequestType.appointment:
        return Icons.calendar_today;
      case RequestType.labReport:
        return Icons.science;
      default:
        return Icons.star;
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

  // --- ACTIONS ---
  void _markTicketClosed(ChatMessageModel msg) {
    widget.service.updateRequestStatus(
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
        builder: (context) => VitalsEntryPage(
          clientId: widget.clientId,
          clientName: widget.clientName,
          onVitalsSaved: () {},
          isFirstConsultation: false,
        ),
      ),
    );
  }

  // ===============================================================
  // 🚀 TICKET ACTIONS IMPLEMENTATION
  // ===============================================================

  // 1. MEAL QUERY (Quick Chips + Comment)
  void _showQuickReplies(ChatMessageModel msg) {
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
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Respond to Query",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 12),

              // Chips
              Wrap(
                spacing: 8,
                children: replies
                    .map(
                      (reply) => ActionChip(
                        label: Text(reply),
                        backgroundColor: Colors.green.shade50,
                        onPressed: () {
                          String current = commentController.text;
                          commentController.text = current.isEmpty
                              ? reply
                              : "$current $reply";
                        },
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 12),

              // Comment Box
              TextField(
                controller: commentController,
                decoration: const InputDecoration(
                  labelText: "Your Response",
                  border: OutlineInputBorder(),
                  hintText: "Type or select chips...",
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),

              // Send Button (Updates status but keeps ticket OPEN for close/archive)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.send),
                  label: const Text("Send Response"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () {
                    if (commentController.text.isEmpty) return;
                    Navigator.pop(context);
                    _service.sendAdminMessage(
                      clientId: widget.clientId,
                      text: commentController.text,
                      type: MessageType.text,
                      replyTo: msg,
                    );
                    _service.updateRequestStatus(
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

  // 2. APPOINTMENT (Confirm / Reschedule / Reject)
  void _handleAppointment(ChatMessageModel msg) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "Appointment Action",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.check_circle, color: Colors.green),
              title: const Text("Confirm Appointment"),
              onTap: () {
                Navigator.pop(context);
                _service.updateRequestStatus(
                  widget.clientId,
                  msg.id,
                  RequestStatus.approved,
                  "Confirmed",
                );
                _service.sendAdminMessage(
                  clientId: widget.clientId,
                  text: "✅ Appointment Confirmed.",
                  type: MessageType.text,
                  replyTo: msg,
                );
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
                  // Update Status to Rejected/Rescheduled but Keep Ticket Open
                  _service.updateRequestStatus(
                    widget.clientId,
                    msg.id,
                    RequestStatus.pending,
                    "Rescheduled to $newDateStr",
                  );
                  _service.sendAdminMessage(
                    clientId: widget.clientId,
                    text: "📅 Could we reschedule to $newDateStr?",
                    type: MessageType.text,
                    replyTo: msg,
                  );
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.cancel, color: Colors.red),
              title: const Text("Reject / Cancel"),
              onTap: () {
                Navigator.pop(context);
                _showRejectionDialog(context,msg);
              },
            ),
          ],
        ),
      ),
    );
  }

// Update the arguments here:
  void _showRejectionDialog(BuildContext context, ChatMessageModel message) {
    final TextEditingController _reasonController = TextEditingController();

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
              controller: _reasonController,
              decoration: const InputDecoration(
                hintText: 'Reason (e.g., Invalid documents)',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              if (_reasonController.text.trim().isEmpty) return;

              Navigator.of(ctx).pop();

              // Pass the ID from the message object here
              // Make sure your model has an '.id' or '.requestId' property
              _service.rejectRequest(message.id, _reasonController.text.trim());
            },
            child: const Text('Reject', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

// FIX 2: Define the missing method

