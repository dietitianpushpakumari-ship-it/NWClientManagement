import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:nutricare_client_management/admin/client_log_model.dart';

class ClientLogReviewTab extends StatefulWidget {
  final String clientId;
  final String clientName;

  const ClientLogReviewTab({
    Key? key,
    required this.clientId,
    required this.clientName
  }) : super(key: key);

  @override
  State<ClientLogReviewTab> createState() => _ClientLogReviewTabState();
}

class _ClientLogReviewTabState extends State<ClientLogReviewTab> {
  DateTime _selectedDate = DateTime.now();

  // 1. Debugging: Print this ID to your console to check if it matches Firestore
  String get _formattedDateId {
    final id = DateFormat('yyyy-MM-dd').format(_selectedDate);
    // debugPrint("Looking for Log ID: ${widget.clientId}_$id");
    return id;
  }

  // --- ACTIONS: Review & Flag ---
  Future<void> _updateLogStatus(String docId, LogStatus status, String msg) async {
    try {
      await FirebaseFirestore.instance.collection('client_logs').doc(docId).set({
        'logStatus': status.name,
        'adminReplied': true,
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(msg), backgroundColor: status == LogStatus.deviated ? Colors.red : Colors.green
        ));
      }
    } catch (e) {
      debugPrint("Error updating status: $e");
    }
  }

  Future<void> _sendComment(String docId, String comment) async {
    if (comment.isEmpty) return;
    await FirebaseFirestore.instance.collection('client_logs').doc(docId).set({
      'adminComment': comment,
      'adminReplied': true,
    }, SetOptions(merge: true));
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Feedback Sent')));
  }

  @override
  Widget build(BuildContext context) {
    String docId = '${widget.clientId}_$_formattedDateId';

    return Column(
      children: [
        _buildDateHeader(),

        Expanded(
          child: StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance
                .collection('client_logs')
                .doc(docId)
                .snapshots(),
            builder: (context, snapshot) {
              // 1. STOP LOADING if error
              if (snapshot.hasError) {
                return Center(child: Text("Error: ${snapshot.error}"));
              }

              // 2. STOP LOADING if connection is active but no data yet
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              }

              // 3. CHECK EXISTENCE explicitly
              if (!snapshot.hasData || !snapshot.data!.exists) {
                return _buildEmptyState();
              }

              // 4. PARSE DATA safely
              ClientLogModel log;
              try {
                log = ClientLogModel.fromMap(
                    snapshot.data!.data() as Map<String, dynamic>, snapshot.data!.id);
              } catch (e) {
                return Center(child: Text("Data Corrupt: $e"));
              }

              // 5. SHOW CONTENT
              return ListView(
                padding: EdgeInsets.all(16),
                children: [
                  // --- A. ACTIONS SECTION ---
                  _buildActionHeader(log, docId),
                  SizedBox(height: 16),

                  // --- B. COMPARATIVE STUDY (Targets vs Actuals) ---
                  _buildComparativeAnalysis(log),
                  SizedBox(height: 16),

                  // --- C. DETAILS (Photos & Feedback) ---
                  _buildMealPhotos(log),
                  SizedBox(height: 16),
                  _buildFeedbackSection(log, docId),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // 📊 COMPARATIVE STUDY WIDGET (Target vs Actual)
  // ===========================================================================
  Widget _buildComparativeAnalysis(ClientLogModel log) {
    // Defines standard goals (You can fetch these from ClientModel later if dynamic)
    const double goalWater = 2.5; // Liters
    const double goalSleep = 7.0; // Hours
    const int goalSteps = 8000;

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("📊 Comparative Analysis (Goal vs Actual)",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            Divider(height: 24),

            _buildProgressRow(
              icon: Icons.water_drop,
              color: Colors.blue,
              label: "Hydration",
              value: log.hydrationLiters ?? 0,
              target: goalWater,
              unit: "L",
            ),
            SizedBox(height: 16),
            _buildProgressRow(
              icon: Icons.bed,
              color: Colors.deepPurple,
              label: "Sleep",
              value: log.totalSleepDurationHours ?? 0,
              target: goalSleep,
              unit: "hrs",
            ),
            SizedBox(height: 16),
            _buildProgressRow(
              icon: Icons.directions_walk,
              color: Colors.orange,
              label: "Activity",
              value: (log.stepCount ?? 0).toDouble(),
              target: goalSteps.toDouble(),
              unit: "steps",
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressRow({
    required IconData icon,
    required Color color,
    required String label,
    required double value,
    required double target,
    required String unit
  }) {
    double progress = (value / target).clamp(0.0, 1.0);
    bool isMet = value >= target;

    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
          child: Icon(icon, color: color, size: 20),
        ),
        SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(label, style: TextStyle(fontWeight: FontWeight.w600)),
                  Text(
                    "${value.toStringAsFixed(1)} / ${target.toStringAsFixed(1)} $unit",
                    style: TextStyle(
                        color: isMet ? Colors.green : Colors.grey[600],
                        fontWeight: isMet ? FontWeight.bold : FontWeight.normal
                    ),
                  ),
                ],
              ),
              SizedBox(height: 6),
              LinearProgressIndicator(
                value: progress,
                backgroundColor: Colors.grey[200],
                color: isMet ? Colors.green : color,
                minHeight: 6,
                borderRadius: BorderRadius.circular(4),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // ⚡ ACTION HEADER (Approve / Flag)
  // ===========================================================================
  Widget _buildActionHeader(ClientLogModel log, String docId) {
    bool isReviewed = log.logStatus == LogStatus.reviewed || log.logStatus == LogStatus.followed;

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Review Actions", style: TextStyle(color: Colors.grey)),
              // Status Badge
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isReviewed ? Colors.green[50] : Colors.orange[50],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  log.logStatus.name.toUpperCase(),
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: isReviewed ? Colors.green : Colors.orange
                  ),
                ),
              )
            ],
          ),
          SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  icon: Icon(Icons.check, size: 18),
                  label: Text("Approve"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    elevation: 0,
                  ),
                  onPressed: () => _updateLogStatus(docId, LogStatus.reviewed, "Log Marked as Reviewed"),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  icon: Icon(Icons.flag, size: 18),
                  label: Text("Flag Deviation"),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: BorderSide(color: Colors.red),
                  ),
                  onPressed: () => _updateLogStatus(docId, LogStatus.deviated, "Log Flagged as Deviation"),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // 📝 FEEDBACK & PHOTOS
  // ===========================================================================
  Widget _buildMealPhotos(ClientLogModel log) {
    if (log.mealPhotoUrls.isEmpty) return SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Meal Photos", style: TextStyle(fontWeight: FontWeight.bold)),
        SizedBox(height: 8),
        SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: log.mealPhotoUrls.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(log.mealPhotoUrls[index], width: 100, height: 100, fit: BoxFit.cover),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFeedbackSection(ClientLogModel log, String docId) {
    TextEditingController _controller = TextEditingController(text: log.adminComment);

    return Card(
      color: Colors.blue[50],
      elevation: 0,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.blue.shade100)
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Dietitian Comments", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue[900])),
            SizedBox(height: 8),
            TextField(
              controller: _controller,
              maxLines: 2,
              decoration: InputDecoration(
                hintText: "Add advice or encouragement...",
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                contentPadding: EdgeInsets.all(12),
              ),
            ),
            SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: SizedBox(
                height: 36,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue[700]),
                  onPressed: () => _sendComment(docId, _controller.text),
                  child: Text("Send Feedback", style: TextStyle(color: Colors.white)),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // 📅 HELPERS
  // ===========================================================================
  Widget _buildDateHeader() {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
              icon: Icon(Icons.chevron_left),
              onPressed: () => setState(() => _selectedDate = _selectedDate.subtract(Duration(days: 1)))
          ),
          Column(
            children: [
              Text(DateFormat('EEE, dd MMM').format(_selectedDate),
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              if (DateFormat('yyyy-MM-dd').format(_selectedDate) == DateFormat('yyyy-MM-dd').format(DateTime.now()))
                Text("Today", style: TextStyle(fontSize: 10, color: Colors.blue, fontWeight: FontWeight.bold))
            ],
          ),
          IconButton(
              icon: Icon(Icons.chevron_right),
              onPressed: () => setState(() => _selectedDate = _selectedDate.add(Duration(days: 1)))
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history_toggle_off, size: 40, color: Colors.grey[300]),
          SizedBox(height: 10),
          Text("No logs found for this date", style: TextStyle(color: Colors.grey)),
          SizedBox(height: 20),
          // Optional: Button to manually create a blank log if needed
          TextButton(
            onPressed: () => _createEmptyLog(),
            child: Text("Initialize Log for Today"),
          )
        ],
      ),
    );
  }

  // Quick helper to force create a doc if it's missing, so the UI can load
  Future<void> _createEmptyLog() async {
    String docId = '${widget.clientId}_$_formattedDateId';
    await FirebaseFirestore.instance.collection('client_logs').doc(docId).set({
      'clientId': widget.clientId,
      'date': _formattedDateId,
      'logStatus': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}