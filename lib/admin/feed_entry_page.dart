import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:nutricare_client_management/admin/feed_content_model.dart';
import 'package:nutricare_client_management/admin/feed_service.dart';
import 'package:nutricare_client_management/admin/recipe_builder_sheet.dart';

class FeedEntryPage extends StatefulWidget {
  final FeedContentModel? itemToEdit;
  const FeedEntryPage({super.key, this.itemToEdit});
  @override
  State<FeedEntryPage> createState() => _FeedEntryPageState();
}

class _FeedEntryPageState extends State<FeedEntryPage> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _linkCtrl = TextEditingController(); // For Action URL (Read More)
  final _videoLinkCtrl = TextEditingController(); // 🎯 NEW: For Video URL
  final _ctaCtrl = TextEditingController(text: "Learn More");
  final _tagsCtrl = TextEditingController();

  FeedContentType _type = FeedContentType.imagePost;
  bool _isPublished = true;
  bool _isSaving = false;

  // Image State
  File? _imageFile;
  String? _currentImageUrl;

  // Recipe State
  Map<String, dynamic>? _recipeData;

  @override
  void initState() {
    super.initState();
    if (widget.itemToEdit != null) {
      final i = widget.itemToEdit!;
      _titleCtrl.text = i.title;
      _descCtrl.text = i.description;
      _linkCtrl.text = i.actionUrl ?? '';
      _ctaCtrl.text = i.callToAction ?? 'Learn More';
      _tagsCtrl.text = i.targetTags.join(', ');
      _type = i.type;
      _isPublished = i.isPublished;
      _recipeData = i.recipeData;

      // Handle Media
      if (_type == FeedContentType.video) {
        _videoLinkCtrl.text = i.mediaUrl ?? '';
      } else {
        _currentImageUrl = i.mediaUrl;
      }
    }
  }

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) setState(() => _imageFile = File(picked.path));
  }

  Future<void> _openRecipeBuilder() async {
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => RecipeBuilderSheet(initialData: _recipeData),
    );
    if (result != null) setState(() => _recipeData = result);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    String? finalMediaUrl;

    // 🎯 Logic: If Video, use text link. If Image, upload file.
    if (_type == FeedContentType.video) {
      finalMediaUrl = _videoLinkCtrl.text.trim();
    } else {
      // Use existing URL or Upload new
      finalMediaUrl = _currentImageUrl;
      if (_imageFile != null) {
        final ref = FirebaseStorage.instance.ref().child('feed_media/${DateTime.now().millisecondsSinceEpoch}.jpg');
        await ref.putFile(_imageFile!);
        finalMediaUrl = await ref.getDownloadURL();
      }
    }

    final item = FeedContentModel(
      id: widget.itemToEdit?.id ?? '',
      title: _titleCtrl.text.trim(),
      description: _descCtrl.text.trim(),
      type: _type,
      mediaUrl: finalMediaUrl, // 🎯 Saves Link OR Image URL
      actionUrl: _linkCtrl.text.trim().isEmpty ? null : _linkCtrl.text.trim(),
      callToAction: _ctaCtrl.text.trim(),
      recipeData: _recipeData,
      targetTags: _tagsCtrl.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
      isPublished: _isPublished,
      createdAt: widget.itemToEdit?.createdAt ?? DateTime.now(),
    );

    await FeedService().saveFeedItem(item);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      body: Stack(
        children: [
          Positioned(top: -100, right: -100, child: Container(width: 300, height: 300, decoration: BoxDecoration(shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.orange.withOpacity(0.1), blurRadius: 80, spreadRadius: 30)]))),
          SafeArea(
            child: Column(
              children: [
                _buildHeader(widget.itemToEdit == null ? "New Post" : "Edit Post", _save, _isSaving),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          // 1. Type Selector
                          _buildCard("Content Type", Icons.category, Colors.indigo,
                              DropdownButtonFormField<FeedContentType>(
                                value: _type,
                                decoration: const InputDecoration(border: InputBorder.none),
                                items: FeedContentType.values.map((t) => DropdownMenuItem(value: t, child: Text(t.name.toUpperCase()))).toList(),
                                onChanged: (v) => setState(() => _type = v!),
                              )
                          ),

                          // 2. MEDIA SECTION (Dynamic)
                          if (_type == FeedContentType.video)
                          // 🎯 SHOW VIDEO LINK INPUT
                            _buildCard("Video Source", Icons.play_circle_fill, Colors.red,
                                _buildField(_videoLinkCtrl, "YouTube / Video Link", Icons.link, hint: "https://youtube.com/...")
                            )
                          else if (_type != FeedContentType.socialPost && _type != FeedContentType.article)
                          // 🎯 SHOW IMAGE UPLOAD
                            GestureDetector(
                              onTap: _pickImage,
                              child: Container(
                                height: 180, width: double.infinity,
                                margin: const EdgeInsets.only(bottom: 20),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(20),
                                  image: _imageFile != null ? DecorationImage(image: FileImage(_imageFile!), fit: BoxFit.cover) : (_currentImageUrl != null ? DecorationImage(image: NetworkImage(_currentImageUrl!), fit: BoxFit.cover) : null),
                                  border: Border.all(color: Colors.grey.shade300, style: BorderStyle.solid),
                                ),
                                child: _imageFile == null && _currentImageUrl == null
                                    ? Column(mainAxisAlignment: MainAxisAlignment.center, children: const [Icon(Icons.add_a_photo, size: 40, color: Colors.grey), SizedBox(height: 8), Text("Upload Thumbnail/Image")])
                                    : null,
                              ),
                            ),

                          // 3. Basic Info
                          _buildCard("Details", Icons.article, Colors.teal, Column(children: [
                            _buildField(_titleCtrl, "Title / Headline", Icons.title),
                            const SizedBox(height: 12),
                            _buildField(_descCtrl, "Description / Caption", Icons.description, maxLines: 3),
                            const SizedBox(height: 12),
                            _buildField(_tagsCtrl, "Tags (comma separated)", Icons.tag),
                          ])),

                          // 4. Type Specifics
                          if (_type != FeedContentType.recipe)
                            _buildCard("Action Button", Icons.touch_app, Colors.blue, Column(children: [
                              _buildField(_linkCtrl, "External URL (Optional)", Icons.open_in_new),
                              if (_type == FeedContentType.advertisement) ...[
                                const SizedBox(height: 12),
                                _buildField(_ctaCtrl, "Button Label (e.g. Buy Now)", Icons.smart_button),
                              ]
                            ])),

                          if (_type == FeedContentType.recipe)
                            _buildCard("Recipe Details", Icons.restaurant_menu, Colors.orange,
                                InkWell(
                                  onTap: _openRecipeBuilder,
                                  child: Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(12)),
                                    child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                                      Icon(Icons.edit_note, color: Colors.orange.shade800),
                                      const SizedBox(width: 10),
                                      Text(_recipeData == null ? "Build Recipe" : "Edit Recipe Data", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange.shade900))
                                    ]),
                                  ),
                                )
                            ),

                          const SizedBox(height: 10),
                          SwitchListTile(title: const Text("Publish Immediately"), value: _isPublished, activeColor: Colors.orange, onChanged: (v) => setState(() => _isPublished = v)),
                        ],
                      ),
                    ),
                  ),
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  // Helpers
  Widget _buildHeader(String title, VoidCallback onSave, bool isLoading) {
    return Container(padding: const EdgeInsets.all(20), child: Row(children: [GestureDetector(onTap: () => Navigator.pop(context), child: const Icon(Icons.arrow_back)), const SizedBox(width: 16), Expanded(child: Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold))), IconButton(onPressed: isLoading ? null : onSave, icon: isLoading ? const CircularProgressIndicator() : const Icon(Icons.check_circle, color: Colors.orange, size: 28))]));
  }
  Widget _buildCard(String title, IconData icon, Color color, Widget child) {
    return Container(margin: const EdgeInsets.only(bottom: 20), padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: color.withOpacity(0.1))), child: Column(children: [Row(children: [Icon(icon, color: color), const SizedBox(width: 10), Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: color))]), const SizedBox(height: 16), child]));
  }
  Widget _buildField(TextEditingController c, String l, IconData i, {int maxLines = 1, String? hint}) => TextFormField(controller: c, maxLines: maxLines, decoration: InputDecoration(labelText: l, hintText: hint, prefixIcon: Icon(i, size: 18), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), filled: true, fillColor: Colors.grey.shade50), validator: (v) => (l.contains("Link") && _type == FeedContentType.video && v!.isEmpty) ? "Required" : null);
}