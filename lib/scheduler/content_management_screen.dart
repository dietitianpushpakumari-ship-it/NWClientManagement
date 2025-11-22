import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:nutricare_client_management/scheduler/content_service.dart';
import 'package:nutricare_client_management/scheduler/dieititan_content_model.dart';

import 'disease_tag.dart';import 'package:nutricare_client_management/admin/custom_gradient_app_bar.dart';




class ContentManagementScreen extends StatefulWidget {
  final DietitianContentModel? initialContent;

  const ContentManagementScreen({super.key, this.initialContent});

  @override
  State<ContentManagementScreen> createState() => _ContentManagementScreenState();
}

class _ContentManagementScreenState extends State<ContentManagementScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  final TextEditingController _generalTagsController = TextEditingController();
  ContentType _selectedType = ContentType.healthyTip;
  List<DiseaseTag> _selectedDiseaseTags = [DiseaseTag.general];
  final ContentService _contentService = ContentService();
  bool _isSaving = false;

  bool get _isEditMode => widget.initialContent != null;

  @override
  void initState() {
    super.initState();
    if (_isEditMode) {
      final content = widget.initialContent!;
      _titleController.text = content.title;
      _contentController.text = content.content;
      _generalTagsController.text = content.generalTags.join(', ');
      _selectedType = content.postType;
      _selectedDiseaseTags = content.diseaseTags;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _generalTagsController.dispose();
    super.dispose();
  }

  Future<void> _saveContent() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDiseaseTags.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select at least one disease tag.')));
      return;
    }

    setState(() => _isSaving = true);

    try {
      final List<String> generalTags = _generalTagsController.text
          .split(',')
          .map((t) => t.trim().toLowerCase())
          .where((t) => t.isNotEmpty)
          .toList();

      final content = DietitianContentModel(
        id: widget.initialContent?.id ?? '',
        title: _titleController.text.trim(),
        postType: _selectedType,
        content: _contentController.text.trim(),
        diseaseTags: _selectedDiseaseTags,
        generalTags: generalTags,
        publishedAt: widget.initialContent?.publishedAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _contentService.saveContent(content);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${_selectedType.label} ${_isEditMode ? 'updated' : 'posted'} successfully!')),
        );
        Navigator.of(context).pop(true); // Return true on success
      }

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save content: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: CustomGradientAppBar(
        title: Text(_isEditMode ? 'Edit Content' : 'Create New Content'),
      ),
      body: SafeArea(child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Content Type Selector
              DropdownButtonFormField<ContentType>(
                decoration: const InputDecoration(labelText: 'Content Type *', border: OutlineInputBorder()),
                value: _selectedType,
                items: ContentType.values.map((type) {
                  return DropdownMenuItem<ContentType>(
                    value: type,
                    child: Text(type.label),
                  );
                }).toList(),
                onChanged: (ContentType? newValue) => setState(() => _selectedType = newValue!),
              ),
              const SizedBox(height: 20),

              // 2. Disease Tags
              const Text('Disease Tags *', style: TextStyle(fontWeight: FontWeight.bold)),
              Wrap(
                spacing: 8.0,
                children: DiseaseTag.values.map((tag) {
                  final isSelected = _selectedDiseaseTags.contains(tag);
                  return FilterChip(
                    label: Text(tag.label),
                    selected: isSelected,
                    selectedColor: tag.color.withOpacity(0.8),
                    onSelected: (bool selected) {
                      setState(() {
                        if (selected) {
                          _selectedDiseaseTags.add(tag);
                        } else {
                          // Prevent removing the last tag
                          if (_selectedDiseaseTags.length > 1) {
                            _selectedDiseaseTags.remove(tag);
                          } else if (tag != DiseaseTag.general) {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Content must have at least one tag.')));
                          }
                        }
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),

              // 3. Title Field
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Title / Headline *', border: OutlineInputBorder()),
                validator: (v) => v!.isEmpty ? 'Title is required.' : null,
              ),
              const SizedBox(height: 20),

              // 4. Content Field (Markdown Input)
              TextFormField(
                controller: _contentController,
                decoration: const InputDecoration(
                  labelText: 'Content (Use Markdown for formatting) *',
                  hintText: 'Use # for headers, * for bold, - for lists.',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                maxLines: 10,
                validator: (v) => v!.isEmpty ? 'Content is required.' : null,
              ),
              const SizedBox(height: 10),

              // 5. Formatting Guide
              Text(
                '**Formatting Guide:**\n# Header\n*bold text*\n- List item 1\n- List item 2',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontStyle: FontStyle.italic),
              ),
              const SizedBox(height: 20),


              // 6. General Tags Field
              TextFormField(
                controller: _generalTagsController,
                decoration: const InputDecoration(
                  labelText: 'General Tags (Optional)',
                  hintText: 'separate with commas: myth, weightloss, breakfast',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 40),


              // 7. Save Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isSaving ? null : _saveContent,
                  icon: _isSaving
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : Icon(_isEditMode ? Icons.edit : Icons.cloud_upload, color: Colors.white),
                  label: Text(
                    _isEditMode ? 'UPDATE CONTENT' : 'POST CONTENT',
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isEditMode ? Colors.green.shade600 : Colors.indigo,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),),
    );
  }
}