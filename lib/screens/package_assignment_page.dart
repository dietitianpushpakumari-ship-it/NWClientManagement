import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:nutricare_client_management/admin/database_provider.dart';
import 'package:nutricare_client_management/admin/labvital/global_service_provider.dart';
import 'package:provider/provider.dart';
import 'package:nutricare_client_management/modules/client/model/client_model.dart';
import 'package:nutricare_client_management/modules/package/model/package_model.dart';
import 'package:nutricare_client_management/modules/package/service/package_Service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PackageAssignmentPage extends ConsumerStatefulWidget {
  final ClientModel client;

  const PackageAssignmentPage({super.key, required this.client});

  @override
  ConsumerState<PackageAssignmentPage> createState() => _PackageAssignmentPageState();
}

class _PackageAssignmentPageState extends ConsumerState<PackageAssignmentPage> {
  PackageModel? _selectedPackage;
  DateTime _startDate = DateTime.now();
  bool _isLoading = false;

  // Filter State
  String _selectedConditionFilter = 'All';

  // 🎯 Offer State & Controllers
  int _offerExtraDays = 0;
  int _offerExtraSessions = 0;
  late TextEditingController _extraDaysCtrl;
  late TextEditingController _extraSessionsCtrl;

  @override
  void initState() {
    super.initState();
    _extraDaysCtrl = TextEditingController(text: '0');
    _extraSessionsCtrl = TextEditingController(text: '0');
  }

  @override
  void dispose() {
    _extraDaysCtrl.dispose();
    _extraSessionsCtrl.dispose();
    super.dispose();
  }

  // --- ACTIONS ---

  void _updateExtraDays(int newValue) {
    if (newValue < 0) return;
    setState(() {
      _offerExtraDays = newValue;
      _extraDaysCtrl.text = newValue.toString();
      // Ensure cursor stays at end if typing (optional but nice)
      _extraDaysCtrl.selection = TextSelection.fromPosition(TextPosition(offset: _extraDaysCtrl.text.length));
    });
  }

  void _updateExtraSessions(int newValue) {
    if (newValue < 0) return;
    setState(() {
      _offerExtraSessions = newValue;
      _extraSessionsCtrl.text = newValue.toString();
      _extraSessionsCtrl.selection = TextSelection.fromPosition(TextPosition(offset: _extraSessionsCtrl.text.length));
    });
  }

  Future<void> _assignPackage() async {
    if (_selectedPackage == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please select a package")));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final finalDuration = _selectedPackage!.durationDays + _offerExtraDays;
      final finalFreeSessions = _selectedPackage!.freeSessions + _offerExtraSessions;

      final endDate = _startDate.add(Duration(days: finalDuration));

      final subscriptionData = {
        'clientId': widget.client.id,
        'clientName': widget.client.name,
        'packageId': _selectedPackage!.id,
        'packageName': _selectedPackage!.name,
        'startDate': Timestamp.fromDate(_startDate),
        'endDate': Timestamp.fromDate(endDate),
        'price': _selectedPackage!.price,
        'status': 'active',

        'sessionsTotal': _selectedPackage!.consultationCount,
        'sessionsRemaining': _selectedPackage!.consultationCount,

        // 🎯 Save Offer Data
        'offerExtraDays': _offerExtraDays,
        'offerExtraSessions': _offerExtraSessions,

        'freeSessionsTotal': finalFreeSessions,
        'freeSessionsRemaining': finalFreeSessions,

        'inclusions': _selectedPackage!.inclusions,
        'createdAt': FieldValue.serverTimestamp(),
      };

      await ref.read(firestoreProvider).collection('subscriptions').add(subscriptionData);

      await ref.read(firestoreProvider).collection('clients').doc(widget.client.id).update({
        'currentPlan': _selectedPackage!.name,
        'planExpiry': Timestamp.fromDate(endDate),
        'clientType': 'active',
        'freeSessionsRemaining': finalFreeSessions,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Package Assigned Successfully!")));
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _startDate = picked);
  }

  // --- UI BUILDER ---

  @override
  Widget build(BuildContext context) {
    final packageService = ref.watch(packageServiceProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      appBar: AppBar(title: const Text("Assign Package"), backgroundColor: Colors.white, foregroundColor: Colors.black, elevation: 0),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildClientSummary(),
            const SizedBox(height: 20),

            const Text("Select Package", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
            const SizedBox(height: 8),

            StreamBuilder<List<PackageModel>>(
              stream: packageService.streamPackages(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const LinearProgressIndicator();

                final allPackages = snapshot.data!.where((p) => p.isActive).toList();

                final Set<String> conditions = {'All'};
                for (var p in allPackages) {
                  conditions.addAll(p.targetConditions);
                }

                final filteredPackages = _selectedConditionFilter == 'All'
                    ? allPackages
                    : allPackages.where((p) => p.targetConditions.contains(_selectedConditionFilter)).toList();

                if (_selectedPackage != null && !filteredPackages.any((p) => p.id == _selectedPackage!.id)) {
                  WidgetsBinding.instance.addPostFrameCallback((_) => setState(() {
                    _selectedPackage = null;
                    _updateExtraDays(0);
                    _updateExtraSessions(0);
                  }));
                } else if (_selectedPackage != null) {
                  try {
                    _selectedPackage = filteredPackages.firstWhere((p) => p.id == _selectedPackage!.id);
                  } catch (_) {}
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: conditions.map((cond) {
                          final isSelected = _selectedConditionFilter == cond;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8.0, bottom: 8.0),
                            child: ChoiceChip(
                              label: Text(cond),
                              selected: isSelected,
                              selectedColor: Colors.indigo.shade100,
                              labelStyle: TextStyle(
                                  color: isSelected ? Colors.indigo : Colors.black87,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal
                              ),
                              onSelected: (selected) {
                                if (selected) setState(() => _selectedConditionFilter = cond);
                              },
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 8),

                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade300)),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedPackage?.id,
                          hint: Text("Select from ${filteredPackages.length} active plans..."),
                          isExpanded: true,
                          items: filteredPackages.map((pkg) => DropdownMenuItem(
                            value: pkg.id,
                            child: Row(
                              children: [
                                if(pkg.colorCode != null)
                                  Container(width: 8, height: 8, margin: const EdgeInsets.only(right: 8), decoration: BoxDecoration(color: Color(int.parse(pkg.colorCode!)), shape: BoxShape.circle)),
                                Text(pkg.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                              ],
                            ),
                          )).toList(),
                          onChanged: (val) {
                            setState(() {
                              _selectedPackage = filteredPackages.firstWhere((p) => p.id == val);
                              _updateExtraDays(0);
                              _updateExtraSessions(0);
                            });
                          },
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),

            if (_selectedPackage != null) ...[
              _buildPackagePreview(_selectedPackage!),
              const SizedBox(height: 20),
              _buildOfferSection(_selectedPackage!),
            ],

            const SizedBox(height: 20),

            const Text("Start Date", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
            const SizedBox(height: 8),
            InkWell(
              onTap: _pickDate,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade300)),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today, color: Colors.indigo, size: 20),
                    const SizedBox(width: 12),
                    Text(DateFormat('dd MMM yyyy').format(_startDate), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const Spacer(),
                    const Text("Change", style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(20),
        color: Colors.white,
        child: ElevatedButton(
          onPressed: _isLoading ? null : _assignPackage,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.indigo, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: _isLoading
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : const Text("CONFIRM ASSIGNMENT", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }

  // 🎯 UPDATED OFFER SECTION WITH TEXT BOXES
  Widget _buildOfferSection(PackageModel pkg) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: Colors.orange.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.orange.withOpacity(0.3))
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.local_offer, color: Colors.orange, size: 20),
              const SizedBox(width: 8),
              const Text("Apply Custom Offers", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.deepOrange)),
            ],
          ),
          const SizedBox(height: 16),

          // 1. Extra Days Row
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Validity Extension", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text("+ $_offerExtraDays Days", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _offerExtraDays > 0 ? Colors.green : Colors.grey)),
                  ],
                ),
              ),
              // Counter with Text Field
              _buildCounterBtn(Icons.remove, () => _updateExtraDays(_offerExtraDays - 1)),
              const SizedBox(width: 8),
              _buildNumberInput(_extraDaysCtrl, (v) => _updateExtraDays(v)),
              const SizedBox(width: 8),
              _buildCounterBtn(Icons.add, () => _updateExtraDays(_offerExtraDays + 1)),
            ],
          ),
          const Divider(height: 24),

          // 2. Extra Sessions Row
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Bonus Sessions", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text("+ $_offerExtraSessions Sessions", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _offerExtraSessions > 0 ? Colors.green : Colors.grey)),
                  ],
                ),
              ),
              // Counter with Text Field
              _buildCounterBtn(Icons.remove, () => _updateExtraSessions(_offerExtraSessions - 1)),
              const SizedBox(width: 8),
              _buildNumberInput(_extraSessionsCtrl, (v) => _updateExtraSessions(v)),
              const SizedBox(width: 8),
              _buildCounterBtn(Icons.add, () => _updateExtraSessions(_offerExtraSessions + 1)),
            ],
          ),
        ],
      ),
    );
  }

  // Helper for Text Box between buttons
  Widget _buildNumberInput(TextEditingController ctrl, Function(int) onChanged) {
    return Container(
      width: 50,
      height: 36,
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade300)
      ),
      child: TextField(
        controller: ctrl,
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        decoration: const InputDecoration(
          border: InputBorder.none,
          contentPadding: EdgeInsets.only(bottom: 12), // Center vertically
        ),
        onChanged: (val) {
          final v = int.tryParse(val);
          if (v != null) onChanged(v);
        },
      ),
    );
  }

  Widget _buildCounterBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey.shade300)),
        child: Icon(icon, size: 16, color: Colors.black87),
      ),
    );
  }

  Widget _buildClientSummary() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.indigo.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.indigo.withOpacity(0.1))),
      child: Row(
        children: [
          CircleAvatar(backgroundColor: Colors.indigo, child: Text(widget.client.name[0], style: const TextStyle(color: Colors.white))),
          const SizedBox(width: 12),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(widget.client.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            Text("Assigning New Plan", style: TextStyle(color: Colors.indigo.shade700, fontSize: 12)),
          ])
        ],
      ),
    );
  }

  Widget _buildPackagePreview(PackageModel pkg) {
    Color themeColor = Colors.indigo;
    if (pkg.colorCode != null) themeColor = Color(int.parse(pkg.colorCode!));

    final totalDays = pkg.durationDays + _offerExtraDays;
    final totalFree = pkg.freeSessions + _offerExtraSessions;

    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
          border: Border(left: BorderSide(color: themeColor, width: 4))
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Package Details", style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.bold, fontSize: 12)),
                  if (pkg.targetConditions.isNotEmpty)
                    Text(pkg.targetConditions.join(" • "), style: TextStyle(color: themeColor, fontSize: 11, fontWeight: FontWeight.bold)),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (pkg.originalPrice != null && pkg.originalPrice! > pkg.price)
                    Text("₹${pkg.originalPrice!.toStringAsFixed(0)}", style: const TextStyle(decoration: TextDecoration.lineThrough, color: Colors.grey, fontSize: 12)),
                  Text("₹${pkg.price.toStringAsFixed(0)}", style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 18)),
                  if (!pkg.isTaxInclusive)
                    const Text("+ GST", style: TextStyle(fontSize: 10, color: Colors.grey)),
                ],
              )
            ],
          ),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildDetailItem(Icons.timer, "$totalDays Days", "Total Validity"),
              _buildDetailItem(Icons.video_call, "${pkg.consultationCount} Calls", "Consultations"),
              _buildDetailItem(Icons.card_giftcard, "$totalFree Free", "Total Bonus"),
            ],
          ),
          const SizedBox(height: 16),
          const Text("Inclusions:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(height: 8),
          if (pkg.inclusions.isEmpty)
            const Text("No specific inclusions listed.", style: TextStyle(color: Colors.grey, fontSize: 12))
          else
            Wrap(
              spacing: 8, runSpacing: 8,
              children: pkg.inclusions.map((inc) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(6), border: Border.all(color: Colors.grey.shade300)),
                child: Text(inc, style: TextStyle(fontSize: 11, color: Colors.grey.shade800)),
              )).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildDetailItem(IconData icon, String val, String label) {
    return Column(children: [Icon(icon, size: 20, color: Colors.indigo), const SizedBox(height: 4), Text(val, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)), Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey))]);
  }
}