import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

// 🎯 Project Imports
import 'package:nutricare_client_management/modules/package/service/package_Service.dart';
import 'package:nutricare_client_management/modules/package/model/package_model.dart';
import 'package:nutricare_client_management/modules/package/model/package_assignment_model.dart';
import 'package:nutricare_client_management/modules/client/services/client_service.dart';

class PackageAssignmentPage extends StatefulWidget {
  final String clientId;
  final String clientName;
  final VoidCallback onPackageAssignment;

  const PackageAssignmentPage({
    super.key,
    required this.clientId,
    required this.clientName,
    required this.onPackageAssignment
  });

  @override
  State<PackageAssignmentPage> createState() => _PackageAssignmentPageState();
}

class _PackageAssignmentPageState extends State<PackageAssignmentPage> {
  final _formKey = GlobalKey<FormState>();

  PackageModel? _selectedPackage;
  DateTime _startDate = DateTime.now();
  DateTime _expiryDate = DateTime.now().add(const Duration(days: 30));

  final _diagnosisController = TextEditingController();
  final _discountController = TextEditingController(text: '0.00');

  double _bookedAmount = 0.0;
  bool _isLoading = false;
  Future<List<PackageModel>>? _packagesFuture;

  @override
  void initState() {
    super.initState();
    _calculateBookedAmount();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_packagesFuture == null) {
      final packageService = Provider.of<PackageService>(context, listen: false);
      _packagesFuture = packageService.getAllActivePackages();
    }
  }

  @override
  void dispose() {
    _diagnosisController.dispose();
    _discountController.dispose();
    super.dispose();
  }

  // --- Logic ---

  void _calculateBookedAmount() {
    if (_selectedPackage == null) {
      setState(() => _bookedAmount = 0.0);
      return;
    }
    final double price = _selectedPackage!.price;
    final double discount = double.tryParse(_discountController.text) ?? 0.0;
    setState(() => _bookedAmount = price - discount);
  }

  void _updateExpiryDate() {
    if (_selectedPackage != null) {
      setState(() {
        _expiryDate = _startDate.add(Duration(days: _selectedPackage!.durationDays));
      });
    }
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStartDate ? _startDate : _expiryDate,
      firstDate: isStartDate ? DateTime(2000) : _startDate,
      lastDate: isStartDate ? _expiryDate.subtract(const Duration(days: 1)) : DateTime(2101),
    );
    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
          _updateExpiryDate();
        } else {
          _expiryDate = picked;
        }
      });
    }
  }

  Future<void> _assignPackage() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedPackage == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a package.')));
      return;
    }

    setState(() => _isLoading = true);

    final newAssignment = PackageAssignmentModel(
        id: '',
        packageId: _selectedPackage!.id,
        packageName: _selectedPackage!.name,
        purchaseDate: _startDate,
        expiryDate: _expiryDate,
        discount: double.tryParse(_discountController.text) ?? 0.0,
        bookedAmount: _bookedAmount,
        diagnosis: _diagnosisController.text.trim(),
        isActive: true,
        category: _selectedPackage!.category.displayName,
        clientId: widget.clientId,
        isLocked: false
    );

    try {
      final clientService = Provider.of<ClientService>(context, listen: false);
      await clientService.assignPackageToClient(widget.clientId, newAssignment);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Package ${_selectedPackage!.name} assigned!')));
      }
      widget.onPackageAssignment();
      Navigator.of(context).pop();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- UI Builders ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      body: Stack(
        children: [
          // 1. Background Glow
          Positioned(
            top: -100,
            right: -80,
            child: Container(
              width: 300, height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: Colors.deepPurple.withOpacity(0.1), blurRadius: 80, spreadRadius: 30)],
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // 2. Custom Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]),
                          child: const Icon(Icons.arrow_back, size: 20, color: Colors.black87),
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Text("Assign Package", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1A1A1A))),
                    ],
                  ),
                ),

                // 3. Main Form
                Expanded(
                  child: _buildAssignmentForm(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAssignmentForm() {
    final currencyFormatter = NumberFormat.currency(locale: 'en_IN', symbol: '₹');

    return FutureBuilder<List<PackageModel>>(
      future: _packagesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));

        final packages = snapshot.data ?? [];
        if (packages.isEmpty) return const Center(child: Text('No active packages found.'));

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            child: Column(
              children: <Widget>[
                // --- CARD 1: PACKAGE DETAILS ---
                _buildPremiumCard(
                  title: "Package Details",
                  icon: Icons.inventory_2_outlined,
                  color: Colors.deepPurple,
                  child: Column(
                    children: [
                      DropdownButtonFormField<PackageModel>(
                        decoration: _inputDecoration("Select Package"),
                        value: _selectedPackage,
                        hint: const Text('Choose a service package'),
                        isExpanded: true,
                        items: packages.map((package) {
                          return DropdownMenuItem(
                            value: package,
                            child: Text('${package.name} (${package.category.displayName})', overflow: TextOverflow.ellipsis),
                          );
                        }).toList(),
                        onChanged: (PackageModel? newValue) {
                          setState(() {
                            _selectedPackage = newValue;
                            _updateExpiryDate();
                            _calculateBookedAmount();
                          });
                        },
                        validator: (value) => value == null ? 'Required' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _diagnosisController,
                        decoration: _inputDecoration("Diagnosis / Reason (Optional)"),
                        maxLines: 2,
                      ),
                    ],
                  ),
                ),

                // --- CARD 2: FINANCIALS ---
                _buildPremiumCard(
                  title: "Pricing & Discount",
                  icon: Icons.currency_rupee,
                  color: Colors.green,
                  child: Column(
                    children: [
                      if (_selectedPackage != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text("Base Price", style: TextStyle(fontSize: 14, color: Colors.grey)),
                              Text(currencyFormatter.format(_selectedPackage!.price), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      TextFormField(
                        controller: _discountController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: _inputDecoration("Discount Amount"),
                        inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))],
                        onChanged: (val) => _calculateBookedAmount(),
                        validator: (value) {
                          final amount = double.tryParse(value ?? '0.00') ?? 0.0;
                          if (amount < 0) return 'Invalid';
                          if (_selectedPackage != null && amount > _selectedPackage!.price) return 'Exceeds Price';
                          return null;
                        },
                      ),
                      const Divider(height: 30),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("Final Amount", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)),
                          Text(
                            currencyFormatter.format(_bookedAmount),
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Theme.of(context).colorScheme.primary),
                          ),
                        ],
                      )
                    ],
                  ),
                ),

                // --- CARD 3: DURATION ---
                _buildPremiumCard(
                  title: "Duration",
                  icon: Icons.calendar_month,
                  color: Colors.orange,
                  child: Column(
                    children: [
                      _buildDateTile("Start Date", _startDate, () => _selectDate(context, true)),
                      const SizedBox(height: 12),
                      _buildDateTile("Expiry Date", _expiryDate, () => _selectDate(context, false), isAlert: _expiryDate.isBefore(DateTime.now())),
                    ],
                  ),
                ),

                const SizedBox(height: 30),

                // Action Button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _assignPackage,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 4,
                      shadowColor: Theme.of(context).colorScheme.primary.withOpacity(0.4),
                    ),
                    child: _isLoading
                        ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text("CONFIRM ASSIGNMENT", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
                  ),
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        );
      },
    );
  }

  // --- Widget Helpers ---

  Widget _buildPremiumCard({required String title, required IconData icon, required Color color, required Widget child}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 15, offset: const Offset(0, 5))],
        border: Border.all(color: color.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle), child: Icon(icon, color: color, size: 20)),
            const SizedBox(width: 12),
            Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
          ]),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: Colors.grey.shade50,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide:  BorderSide(color: Theme.of(context).colorScheme.primary, width: 1.5)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }

  Widget _buildDateTile(String label, DateTime date, VoidCallback onTap, {bool isAlert = false}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isAlert ? Colors.red.shade200 : Colors.grey.shade200),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.w600)),
            Row(
              children: [
                Text(DateFormat.yMMMd().format(date), style: TextStyle(fontWeight: FontWeight.bold, color: isAlert ? Colors.red : Colors.black87)),
                const SizedBox(width: 8),
                Icon(Icons.calendar_today, size: 16, color: isAlert ? Colors.red : Theme.of(context).colorScheme.primary),
              ],
            )
          ],
        ),
      ),
    );
  }
}