import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:nutricare_client_management/scheduler/content_service.dart';
import 'package:nutricare_client_management/scheduler/dieititan_content_model.dart';
import 'package:nutricare_client_management/scheduler/disease_tag.dart';

class ContentManagementScreen extends StatefulWidget {
  final DietitianContentModel? initialContent;
  const ContentManagementScreen({super.key, this.initialContent});

  @override
  State<ContentManagementScreen> createState() => _ContentManagementScreenState();
}

class _ContentManagementScreenState extends State<ContentManagementScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _contentCtrl = TextEditingController();
  final _tagsCtrl = TextEditingController();
  ContentType _type = ContentType.healthyTip;
  List<DiseaseTag> _diseaseTags = [DiseaseTag.general];
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialContent != null) {
      _titleCtrl.text = widget.initialContent!.title;
      _contentCtrl.text = widget.initialContent!.content;
      _type = widget.initialContent!.postType;
      _diseaseTags = List.from(widget.initialContent!.diseaseTags);
      _tagsCtrl.text = widget.initialContent!.generalTags.join(', ');
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    final content = DietitianContentModel(
      id: widget.initialContent?.id ?? '',
      title: _titleCtrl.text.trim(),
      postType: _type,
      content: _contentCtrl.text,
      diseaseTags: _diseaseTags,
      generalTags: _tagsCtrl.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
      publishedAt: widget.initialContent?.publishedAt ?? DateTime.now(),
    );

    await ContentService().saveContent(content);
    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(widget.initialContent == null ? "New Post" : "Edit Post", onSave: _save, isLoading: _isSaving),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      _buildCard("Type & Tags", Icons.category, Theme.of(context).colorScheme.primary, Column(children: [
                        DropdownButtonFormField<ContentType>(
                          value: _type,
                          decoration: const InputDecoration(border: OutlineInputBorder(), labelText: "Post Type"),
                          items: ContentType.values.map((t) => DropdownMenuItem(value: t, child: Text(t.label))).toList(),
                          onChanged: (v) => setState(() => _type = v!),
                        ),
                        const SizedBox(height: 12),
                        Wrap(spacing: 8, children: DiseaseTag.values.map((t) => FilterChip(label: Text(t.label), selected: _diseaseTags.contains(t), onSelected: (s) => setState(() => s ? _diseaseTags.add(t) : _diseaseTags.remove(t)))).toList())
                      ])),
                      _buildCard("Content", Icons.article, Colors.teal, Column(children: [
                        TextFormField(controller: _titleCtrl, decoration: const InputDecoration(labelText: "Title", border: OutlineInputBorder()), validator: (v) => v!.isEmpty ? "Req" : null),
                        const SizedBox(height: 12),
                        TextFormField(controller: _contentCtrl, maxLines: 10, decoration: const InputDecoration(labelText: "Body (Markdown)", border: OutlineInputBorder(), alignLabelWithHint: true), validator: (v) => v!.isEmpty ? "Req" : null),
                        const SizedBox(height: 12),
                        TextFormField(controller: _tagsCtrl, decoration: const InputDecoration(labelText: "Keywords (comma separated)", border: OutlineInputBorder())),
                      ]))
                    ],
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(String title, {required VoidCallback onSave, required bool isLoading}) {
    return Container(
      padding: const EdgeInsets.all(20),
      color: Colors.white.withOpacity(0.8),
      child: Row(children: [
        GestureDetector(onTap: () => Navigator.pop(context), child: const Icon(Icons.arrow_back)),
        const SizedBox(width: 16),
        Expanded(child: Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold))),
        IconButton(onPressed: isLoading ? null : onSave, icon: isLoading ? const CircularProgressIndicator() :  Icon(Icons.check_circle, color: Theme.of(context).colorScheme.primary, size: 28))
      ]),
    );
  }
  Widget _buildCard(String title, IconData icon, Color color, Widget child) {
    return Container(margin: const EdgeInsets.only(bottom: 20), padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: color.withOpacity(0.1))), child: Column(children: [Row(children: [Icon(icon, color: color), const SizedBox(width: 10), Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: color))]), const SizedBox(height: 16), child]));
  }
}