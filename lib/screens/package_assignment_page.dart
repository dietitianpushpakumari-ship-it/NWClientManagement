import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:nutricare_client_management/admin/database_provider.dart';
import 'package:nutricare_client_management/admin/labvital/global_service_provider.dart';
import 'package:nutricare_client_management/master/model/master_constants.dart';
import 'package:nutricare_client_management/modules/client/model/client_model.dart';
import 'package:nutricare_client_management/modules/package/model/package_model.dart';
import 'package:nutricare_client_management/modules/package/service/package_Service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PackageAssignmentPage extends ConsumerStatefulWidget {
  final ClientModel client;
  final String? sessionId;

  const PackageAssignmentPage({super.key, required this.client, this.sessionId});

  @override
  ConsumerState<PackageAssignmentPage> createState() => _PackageAssignmentPageState();
}

class _PackageAssignmentPageState extends ConsumerState<PackageAssignmentPage> {
  PackageModel? _selectedPackage;
  DateTime _startDate = DateTime.now();
  bool _isLoading = false;

  // 🎯 FILTERS
  String _selectedTypeFilter = 'All';
  String _selectedCategoryFilter = 'All';

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

  void _updateExtraDays(int newValue) {
    if (newValue < 0) return;
    setState(() {
      _offerExtraDays = newValue;
      _extraDaysCtrl.text = newValue.toString();
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
// ... imports ...

// ... imports ...

  Future<void> _assignPackage() async {
    if (_selectedPackage == null) return;
    setState(() => _isLoading = true);

    try {
      final firestore = ref.read(firestoreProvider);

      // 1. Calculate Data
      final finalDuration = _selectedPackage!.durationDays + _offerExtraDays;
      final finalFreeSessions = _selectedPackage!.freeSessions + _offerExtraSessions;
      final endDate = _startDate.add(Duration(days: finalDuration));

      // 2. Prepare Subscription Data
      final subscriptionData = {
        'clientId': widget.client.id,
        'clientName': widget.client.name,
        'packageId': _selectedPackage!.id,
        'packageName': _selectedPackage!.name,
        'startDate': Timestamp.fromDate(_startDate),
        'endDate': Timestamp.fromDate(endDate),
        'status': 'active',

        // Counts for Calculation
        'sessionsTotal': _selectedPackage!.consultationCount,
        'freeSessionsTotal': finalFreeSessions,

        // Metadata
        'category': _selectedPackage!.category.name,
        'type': _selectedPackage!.packageType,
        'price': _selectedPackage!.price,
        'sessionId': widget.sessionId,
        'createdAt': FieldValue.serverTimestamp(),
      };

      WriteBatch batch = firestore.batch();

      // A. Create Subscription (This is the "Income" for the calculator)
      DocumentReference subRef = firestore.collection(MasterCollectionMapper.getPath(TransactionEntity.entity_patientSubscription)).doc();
      batch.set(subRef, subscriptionData);

      // B. Update Client Metadata (Only plan info, NO WALLET BALANCE)
      DocumentReference clientRef = firestore.collection('clients').doc(widget.client.id);
      batch.update(clientRef, {
        'currentPlan': _selectedPackage!.name,
        'planExpiry': Timestamp.fromDate(endDate),
        'onboarding_step_subscription': true,
        // ❌ REMOVED: 'wallet.available': FieldValue.increment(...)
        // ❌ REMOVED: 'wallet.batches': ...
      });

      // C. Ledger (Audit Only)
      DocumentReference ledgerRef = firestore.collection('wallet_ledger').doc();
      batch.set(ledgerRef, {
        'clientId': widget.client.id,
        'type': 'credit',
        'category': 'package_purchase',
        'amount': (_selectedPackage!.consultationCount + finalFreeSessions),
        'description': 'Assigned Package: ${_selectedPackage!.name}',
        'referenceId': subRef.id,
        'timestamp': FieldValue.serverTimestamp(),
      });

      // D. Session Update
      if (widget.sessionId != null) {
        batch.update(firestore.collection('consultation_sessions').doc(widget.sessionId), {
          'steps.subscription': true,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Package Assigned! Balance will update automatically."), backgroundColor: Colors.green));
        Navigator.pop(context);
      }
    } catch (e) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if(mounted) setState(() => _isLoading = false);
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
            const SizedBox(height: 12),

            StreamBuilder<List<PackageModel>>(
              stream: packageService.streamPackages(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const LinearProgressIndicator();

                final allPackages = snapshot.data!.where((p) => p.isFinalized).toList();

                if (allPackages.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(12.0),
                    child: Text("No finalized packages available. Go to Package Master to finalize a draft.", style: TextStyle(color: Colors.red)),
                  );
                }

                // 🎯 1. COLLECT UNIQUE VALUES
                final Set<String> types = {'All'};
                final Set<String> categories = {'All'};

                for (var p in allPackages) {
                  if(p.packageType.isNotEmpty) types.add(p.packageType);
                  categories.add(p.category.displayName);
                }

                // Sorted Lists
                final sortedTypes = ['All', ...types.where((t) => t != 'All').toList()..sort()];
                final sortedCategories = ['All', ...categories.where((c) => c != 'All').toList()];
                // Note: Categories usually follow Enum order, or we can sort them. Let's keep Enum order logic if possible, or just insert.
                // For simplicity here, sticking to insertion order or basic sort.

                // 🎯 2. APPLY DUAL FILTERS
                final filteredPackages = allPackages.where((p) {
                  final matchType = _selectedTypeFilter == 'All' || p.packageType == _selectedTypeFilter;
                  final matchCategory = _selectedCategoryFilter == 'All' || p.category.displayName == _selectedCategoryFilter;
                  return matchType && matchCategory;
                }).toList();

                // 🎯 3. VALIDATE SELECTION
                final bool isValueInList = _selectedPackage != null && filteredPackages.any((p) => p.id == _selectedPackage!.id);

                if (_selectedPackage != null && !isValueInList) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) {
                      setState(() {
                        _selectedPackage = null;
                        _updateExtraDays(0);
                        _updateExtraSessions(0);
                      });
                    }
                  });
                } else if (_selectedPackage != null && isValueInList) {
                  try {
                    _selectedPackage = filteredPackages.firstWhere((p) => p.id == _selectedPackage!.id);
                  } catch (_) {}
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 🎯 FILTER 1: BY TYPE (LARGE LIST -> DROPDOWN)
                    if (sortedTypes.length > 2) ...[
                      const Text("Filter by Type:", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: sortedTypes.contains(_selectedTypeFilter) ? _selectedTypeFilter : 'All',
                            isExpanded: true,
                            icon: const Icon(Icons.category, size: 20, color: Colors.indigo),
                            items: sortedTypes.map((type) => DropdownMenuItem(
                              value: type,
                              child: Text(type, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.black87)),
                            )).toList(),
                            onChanged: (val) {
                              if (val != null) setState(() => _selectedTypeFilter = val);
                            },
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: 12),

                    // 🎯 FILTER 2: BY TIER/CATEGORY (SMALL LIST -> CHIPS)
                    if (sortedCategories.length > 2) ...[
                      const Text("Filter by Tier:", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
                      const SizedBox(height: 4),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: sortedCategories.map((cat) {
                            final isSelected = _selectedCategoryFilter == cat;
                            return Padding(
                              padding: const EdgeInsets.only(right: 8.0, bottom: 8.0),
                              child: ChoiceChip(
                                label: Text(cat),
                                selected: isSelected,
                                selectedColor: Colors.purple.shade100,
                                labelStyle: TextStyle(
                                    color: isSelected ? Colors.purple : Colors.black87,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal
                                ),
                                onSelected: (selected) {
                                  if (selected) setState(() => _selectedCategoryFilter = cat);
                                },
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),

                    // 🎯 PACKAGE SELECTION DROPDOWN
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade300)),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: isValueInList ? _selectedPackage?.id : null,
                          hint: Text(
                              filteredPackages.isEmpty ? "No packages match filters" : "Select from ${filteredPackages.length} plans...",
                              style: TextStyle(color: filteredPackages.isEmpty ? Colors.red : Colors.grey.shade600)
                          ),
                          isExpanded: true,
                          itemHeight: 60,
                          items: filteredPackages.map((pkg) => DropdownMenuItem(
                            value: pkg.id,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Row(
                                  children: [
                                    if(pkg.colorCode != null)
                                      Container(width: 8, height: 8, margin: const EdgeInsets.only(right: 8), decoration: BoxDecoration(color: Color(int.parse(pkg.colorCode!)), shape: BoxShape.circle)),
                                    Expanded(child: Text(pkg.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, overflow: TextOverflow.ellipsis))),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                    "${pkg.category.displayName} • ${pkg.packageType}",
                                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600, overflow: TextOverflow.ellipsis)
                                ),
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
              _buildCounterBtn(Icons.remove, () => _updateExtraDays(_offerExtraDays - 1)),
              const SizedBox(width: 8),
              _buildNumberInput(_extraDaysCtrl, (v) => _updateExtraDays(v)),
              const SizedBox(width: 8),
              _buildCounterBtn(Icons.add, () => _updateExtraDays(_offerExtraDays + 1)),
            ],
          ),
          const Divider(height: 24),

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

  Widget _buildNumberInput(TextEditingController ctrl, Function(int) onChanged) {
    return Container(
      width: 50, height: 36,
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey.shade300)),
      child: TextField(
        controller: ctrl,
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        decoration: const InputDecoration(border: InputBorder.none, contentPadding: EdgeInsets.only(bottom: 12)),
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
      child: Container(width: 36, height: 36, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey.shade300)), child: Icon(icon, size: 16, color: Colors.black87)),
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

          // 🎯 KEY FEATURES
          if (pkg.programFeatureIds.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Text("Key Features:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8, runSpacing: 8,
              children: pkg.programFeatureIds.map((feat) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(6), border: Border.all(color: Colors.blue.shade100)),
                child: Text(feat, style: TextStyle(fontSize: 11, color: Colors.blue.shade800)),
              )).toList(),
            ),
          ],

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