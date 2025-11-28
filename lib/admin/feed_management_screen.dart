import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:nutricare_client_management/admin/feed_content_model.dart';
import 'package:nutricare_client_management/admin/feed_entry_page.dart';
import 'package:nutricare_client_management/admin/feed_service.dart';


class FeedManagementScreen extends StatelessWidget {
  const FeedManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final FeedService service = FeedService();

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      body: Stack(
        children: [
          // Glow
          Positioned(top: -100, right: -100, child: Container(width: 300, height: 300, decoration: BoxDecoration(shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.orange.withOpacity(0.1), blurRadius: 80, spreadRadius: 30)]))),

          SafeArea(
            child: Column(
              children: [
                _buildHeader(context),
                Expanded(
                  child: StreamBuilder<List<FeedContentModel>>(
                    stream: service.streamAllFeeds(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                      final items = snapshot.data ?? [];

                      if (items.isEmpty) return const Center(child: Text("No feed items yet."));

                      return ListView.separated(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 80),
                        itemCount: items.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 16),
                        itemBuilder: (context, index) => _buildFeedCard(context, items[index], service),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FeedEntryPage())),
        backgroundColor: Colors.orange.shade800,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text("Create Post", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: Colors.white.withOpacity(0.8), border: Border(bottom: BorderSide(color: Colors.grey.withOpacity(0.1)))),
          child: Row(
            children: [
              GestureDetector(onTap: () => Navigator.pop(context), child: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]), child: const Icon(Icons.arrow_back, size: 20))),
              const SizedBox(width: 16),
              const Text("Content Studio", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1A1A1A))),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeedCard(BuildContext context, FeedContentModel item, FeedService service) {
    IconData icon;
    Color color;

    switch (item.type) {
      case FeedContentType.video: icon = Icons.play_circle_fill; color = Colors.red; break; // 🎯 Updated Icon
      case FeedContentType.recipe: icon = Icons.restaurant_menu; color = Colors.orange; break;
      case FeedContentType.advertisement: icon = Icons.campaign; color = Colors.purple; break;
      case FeedContentType.socialPost: icon = Icons.share; color = Colors.blue; break;
      default: icon = Icons.article; color = Colors.teal;
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 15, offset: const Offset(0, 5))],
      ),
      child: Column(
        children: [
          ListTile(
            contentPadding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            leading: Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: color)),
            title: Text(item.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            subtitle: Text(item.type == FeedContentType.video ? "Video Link" : DateFormat('dd MMM').format(item.createdAt), style: const TextStyle(fontSize: 12, color: Colors.grey)),
            trailing: PopupMenuButton(
              onSelected: (v) {
                if (v == 'edit') Navigator.push(context, MaterialPageRoute(builder: (_) => FeedEntryPage(itemToEdit: item)));
                if (v == 'delete') service.deleteFeedItem(item.id);
              },
              itemBuilder: (c) => [
                const PopupMenuItem(value: 'edit', child: Text("Edit")),
                const PopupMenuItem(value: 'delete', child: Text("Delete", style: TextStyle(color: Colors.red))),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                _buildStatBadge(Icons.visibility, "${item.views}"),
                const SizedBox(width: 12),
                _buildStatBadge(Icons.share, "${item.shares}"),
                const Spacer(),
                if (!item.isPublished)
                  Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(6)), child: const Text("DRAFT", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey))),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildStatBadge(IconData icon, String label) {
    return Row(children: [Icon(icon, size: 14, color: Colors.grey), const SizedBox(width: 4), Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey))]);
  }
}