import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nutricare_client_management/admin/labvital/global_service_provider.dart';
import 'package:nutricare_client_management/master/model/disease_master_model.dart';
import 'package:nutricare_client_management/master/service/disease_master_service.dart';

class DiseaseMasterEntryScreen extends ConsumerStatefulWidget {
final DiseaseMasterModel? diseaseToEdit;
const DiseaseMasterEntryScreen({super.key, this.diseaseToEdit});
@override
ConsumerState<DiseaseMasterEntryScreen> createState() => _DiseaseMasterEntryScreenState();
}

class _DiseaseMasterEntryScreenState extends ConsumerState<DiseaseMasterEntryScreen> {
final _formKey = GlobalKey<FormState>();
final _enNameController = TextEditingController();
bool _isLoading = false;

@override
void initState() {
super.initState();
if (widget.diseaseToEdit != null) _enNameController.text = widget.diseaseToEdit!.enName;
}

Future<void> _save() async {
if (!_formKey.currentState!.validate()) return;
setState(() => _isLoading = true);
final disease = DiseaseMasterModel(
id: widget.diseaseToEdit?.id ?? '',
enName: _enNameController.text.trim(),
);

final _service = ref.watch(diseaseMasterServiceProvider);
if (widget.diseaseToEdit == null) await _service.addDisease(disease);
else await _service.updateDisease(disease);

if (mounted) Navigator.pop(context);
}

@override
Widget build(BuildContext context) {
return Scaffold(
backgroundColor: const Color(0xFFF8F9FE),
body: Stack(
children: [
Positioned(top: -100, right: -100, child: Container(width: 300, height: 300, decoration: BoxDecoration(shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.deepOrange.withOpacity(0.1), blurRadius: 80, spreadRadius: 30)]))),
Column(
children: [
_buildHeader(widget.diseaseToEdit == null ? "New Disease" : "Edit Disease", onSave: _save, isLoading: _isLoading),
Expanded(
child: SingleChildScrollView(
padding: const EdgeInsets.all(20),
child: Form(
key: _formKey,
child: _buildCard("Disease Details", Icons.coronavirus, Colors.deepOrange, _buildField(_enNameController, "Disease Name", Icons.edit)),
),
),
)
],
)
],
),
);
}

// --- HELPERS (Reuse) ---
Widget _buildHeader(String title, {required VoidCallback onSave, required bool isLoading}) {
return ClipRRect(
child: BackdropFilter(
filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
child: Container(
padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 10, 20, 16),
decoration: BoxDecoration(color: Colors.white.withOpacity(0.8), border: Border(bottom: BorderSide(color: Colors.grey.withOpacity(0.1)))),
child: Row(children: [
GestureDetector(onTap: () => Navigator.pop(context), child: const Icon(Icons.arrow_back)),
const SizedBox(width: 16),
Expanded(child: Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold))),
IconButton(onPressed: isLoading ? null : onSave, icon: isLoading ? const CircularProgressIndicator() : const Icon(Icons.check_circle, color: Colors.deepOrange, size: 28))
]),
),
),
);
}
Widget _buildCard(String title, IconData icon, Color color, Widget child) {
return Container(margin: const EdgeInsets.only(bottom: 20), padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: color.withOpacity(0.1))), child: Column(children: [Row(children: [Icon(icon, color: color), const SizedBox(width: 10), Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: color))]), const SizedBox(height: 16), child]));
}
Widget _buildField(TextEditingController c, String l, IconData i) => TextFormField(controller: c, decoration: InputDecoration(labelText: l, prefixIcon: Icon(i, size: 18), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), filled: true, fillColor: Colors.grey.shade50), validator: (v) => v!.isEmpty ? "Required" : null);
}