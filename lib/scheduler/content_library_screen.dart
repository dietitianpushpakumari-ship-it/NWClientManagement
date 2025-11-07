import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:nutricare_client_management/scheduler/content_service.dart';
import 'package:nutricare_client_management/scheduler/dieititan_content_model.dart';
import 'package:nutricare_client_management/scheduler/disease_tag.dart';


import 'content_management_screen.dart';
import 'content_detail_screen.dart';


class ContentLibraryScreen extends StatefulWidget {
  const ContentLibraryScreen({super.key});

  @override
  State<ContentLibraryScreen> createState() => _ContentLibraryScreenState();
}

class _ContentLibraryScreenState extends State<ContentLibraryScreen> {
  final ContentService _contentService = ContentService();

  void _navigateAndRefresh(Widget page) async {
    // Await the result to know if content was saved/deleted, then force refresh
    final bool? result = await Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => page),
    );
    if (result == true) {
      setState(() {});
    }
  }

  Future<void> _confirmDelete(DietitianContentModel content) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Confirm Deletion'),
          content: Text('Are you sure you want to delete "${content.title}"? This action cannot be undone.'),
          actions: <Widget>[
            TextButton(child: const Text('CANCEL'), onPressed: () => Navigator.of(dialogContext).pop(false)),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('DELETE', style: TextStyle(color: Colors.white)),
              onPressed: () => Navigator.of(dialogContext).pop(true),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      try {
        await _contentService.deleteContent(content.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Content deleted successfully!')));
          setState(() {}); // Refresh list
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to delete: ${e.toString()}')));
        }
      }
    }
  }

  Widget _buildContentTile(DietitianContentModel content) {
    final ContentType type = content.postType;
    return Card(
      margin: const EdgeInsets.only(bottom: 8.0),
      child: ListTile(
        leading: Icon(type.icon, color: Colors.indigo),
        title: Text(content.title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Type: ${type.label} | Tags: ${content.diseaseTags.map((t) => t.label).join(', ')}',
                style: const TextStyle(fontSize: 12)),
            Text('Published: ${DateFormat('dd MMM yyyy').format(content.publishedAt)}',
                style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic)),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (String action) {
            if (action == 'view') {
              _navigateAndRefresh(ContentDetailScreen(content: content));
            } else if (action == 'edit') {
              _navigateAndRefresh(ContentManagementScreen(initialContent: content));
            } else if (action == 'delete') {
              _confirmDelete(content);
            }
          },
          itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
            const PopupMenuItem<String>(value: 'view', child: ListTile(leading: Icon(Icons.visibility), title: Text('View Content'))),
            const PopupMenuItem<String>(value: 'edit', child: ListTile(leading: Icon(Icons.edit), title: Text('Edit Content'))),
            const PopupMenuItem<String>(value: 'delete', child: ListTile(leading: Icon(Icons.delete, color: Colors.red), title: Text('Delete Content'))),
          ],
        ),
        onTap: () => _navigateAndRefresh(ContentDetailScreen(content: content)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Content Library'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<List<DietitianContentModel>>(
        stream: _contentService.streamAllContent(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error loading content: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No content posts found. Tap + to create one.'));
          }

          final contentList = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: contentList.length,
            itemBuilder: (context, index) {
              return _buildContentTile(contentList[index]);
            },
          );
        },
      ),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateAndRefresh(const ContentManagementScreen()),
        label: const Text('New Post'),
        icon: const Icon(Icons.add),
        backgroundColor: Colors.indigo,
      ),
    );
  }
}