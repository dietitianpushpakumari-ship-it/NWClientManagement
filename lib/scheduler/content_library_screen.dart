import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:nutricare_client_management/admin/labvital/global_service_provider.dart';
import 'package:nutricare_client_management/scheduler/content_service.dart';
import 'package:nutricare_client_management/scheduler/dieititan_content_model.dart';
import 'package:nutricare_client_management/scheduler/disease_tag.dart';
import 'content_management_screen.dart';
import 'content_detail_screen.dart';

class ContentLibraryScreen extends ConsumerStatefulWidget {
  const ContentLibraryScreen({super.key});
  @override
  ConsumerState<ContentLibraryScreen> createState() => _ContentLibraryScreenState();
}

class _ContentLibraryScreenState extends ConsumerState<ContentLibraryScreen> {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ContentManagementScreen())).then((_) => setState((){})),
        label: const Text('New Post', style: TextStyle(color: Colors.white)),
        icon: const Icon(Icons.add, color: Colors.white),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
      body: Stack(
        children: [
          Positioned(top: -100, right: -100, child: Container(width: 300, height: 300, decoration: BoxDecoration(shape: BoxShape.circle, boxShadow: [BoxShadow(color: Theme.of(context).colorScheme.primary.withOpacity(0.1), blurRadius: 80, spreadRadius: 30)]))),
          SafeArea(
            child: Column(
              children: [
                _buildHeader(context),
                Expanded(
                  child: StreamBuilder<List<DietitianContentModel>>(
                    stream: ref.watch(contentServiceProvider).streamAllContent(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                      final list = snapshot.data!;
                      return ListView.separated(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 80),
                        itemCount: list.length,
                        separatorBuilder: (_,__) => const SizedBox(height: 12),
                        itemBuilder: (context, index) => _buildContentCard(list[index]),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          GestureDetector(onTap: () => Navigator.pop(context), child: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]), child: const Icon(Icons.arrow_back, size: 20))),
          const SizedBox(width: 16),
          const Text("Content Library", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildContentCard(DietitianContentModel content) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)]),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary.withOpacity(.1), borderRadius: BorderRadius.circular(12)), child: Icon(content.postType.icon, color: Theme.of(context).colorScheme.primary)),
        title: Text(content.title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text("${content.postType.label} • ${DateFormat('dd MMM').format(content.publishedAt)}", style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ContentDetailScreen(content: content))),
        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
      ),
    );
  }
}