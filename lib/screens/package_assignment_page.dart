import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nutricare_client_management/models/assigned_package_data.dart';
import 'package:nutricare_client_management/modules/package/service/package_Service.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../modules/package/model/package_model.dart';
import '../modules/package/model/package_assignment_model.dart';
import '../modules/package/service/package_payment_service.dart';
import '../modules/client/services/client_service.dart';
import 'payment_ledger_screen.dart'; // Import the Ledger Screen
import 'package:nutricare_client_management/admin/custom_gradient_app_bar.dart';


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
    // No need to initialize _packagesFuture here, using didChangeDependencies
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

  // --- Helper methods (_calculateBookedAmount, _updateExpiryDate, _selectDate are unchanged) ---
  void _calculateBookedAmount() {
    // ... (Existing logic for calculation)
    if (_selectedPackage == null) {
      setState(() {
        _bookedAmount = 0.0;
      });
      return;
    }
    final double price = _selectedPackage!.price;
    final double discount = double.tryParse(_discountController.text) ?? 0.0;

    setState(() {
      _bookedAmount = price - discount;
    });
  }

  void _updateExpiryDate() {
    // ... (Existing logic for updating expiry date)
    if (_selectedPackage != null) {
      setState(() {
        _expiryDate = _startDate.add(Duration(days: _selectedPackage!.durationDays));
      });
    }
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    // ... (Existing logic for selecting date)
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

  // --- Assignment Logic (unchanged for this task) ---
  Future<void> _assignPackage() async {
    // ... (Existing assignment logic)
    if (!_formKey.currentState!.validate()) return;
    if (_selectedPackage == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a package.')));
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final newAssignment = PackageAssignmentModel(
      id: '', // Firestore will assign an ID
      packageId: _selectedPackage!.id,
      packageName: _selectedPackage!.name,
      purchaseDate: _startDate,
      expiryDate: _expiryDate,
      discount: double.tryParse(_discountController.text) ?? 0.0,
      bookedAmount: _bookedAmount,
      diagnosis: _diagnosisController.text.trim(),
      isActive: true,
      category: _selectedPackage!.category.displayName,
        clientId: widget.clientId, isLocked: false

    );

    try {
      final clientService = Provider.of<ClientService>(context, listen: false);
      await clientService.assignPackageToClient( widget.clientId, newAssignment);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Package ${_selectedPackage!.name} assigned successfully!')),
        );
        _formKey.currentState?.reset();
        _discountController.text = '0.00';
        _diagnosisController.text = '';
        setState(() {
          _selectedPackage = null;
          _bookedAmount = 0.0;
          _startDate = DateTime.now();
          _expiryDate = DateTime.now().add(const Duration(days: 30));
        });
      }

      widget.onPackageAssignment();
      Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to assign package: $e')),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }



  // Helper to navigate to the Ledger screen
  void _navigateToLedger(AssignedPackageData data) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => PaymentLedgerScreen(
          assignment: data.assignment,
          clientName: widget.clientName,
          initialCollectedAmount: data.collectedAmount,
        ),
      ),
    );
  }

  // --- NEW: UI for List Item with payment details ---
  Widget _buildAssignmentCard(AssignedPackageData data) {
    final currencyFormatter = NumberFormat.currency(locale: 'en_IN', symbol: '₹');
    final isFullyPaid = data.status == 'fullyPaid';

    Color getStatusColor(dynamic status) {
      if (status == 'fullyPaid') return Colors.green.shade700;
      if (status == 'partiallyPaid') return Colors.orange.shade700;
      return Colors.red.shade700;
    }

    String getStatusText(dynamic status) {
      if (status == 'fullyPaid') return 'Fully Paid';
      if (status == 'partiallyPaid') return 'Partially Paid';
      return 'Not Paid';
    }

    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 12.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: getStatusColor(data.status), width: 1.5), // Status color border
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16.0),
        leading: Icon(
          Icons.work_history,
          color: getStatusColor(data.status),
          size: 30,
        ),
        title: Text(
          data.assignment.packageName ,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              'Assigned: ${DateFormat.yMMMd().format(data.assignment.purchaseDate)}',
              style: TextStyle(color: Colors.grey.shade700),
            ),
            Text(
              'Expires: ${DateFormat.yMMMd().format(data.assignment.expiryDate)}',
              style: TextStyle(
                color: data.assignment.expiryDate.isBefore(DateTime.now()) ? Colors.red : Colors.grey.shade700,
                fontWeight: data.assignment.expiryDate.isBefore(DateTime.now()) ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            const Divider(height: 12),
            // PAYMENT DETAILS
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Status: ${getStatusText(data.status)}',
                      style: TextStyle(fontWeight: FontWeight.bold, color: getStatusColor(data.status)),
                    ),
                    if (data.discountAmount > 0)
                      Text(
                        'Discount: ${currencyFormatter.format(data.discountAmount)}',
                        style: TextStyle(color: Colors.purple.shade700, fontSize: 13),
                      ),
                  ],
                ),
                if (!isFullyPaid)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Unpaid:',
                        style: TextStyle(color: Colors.red.shade700, fontSize: 13),
                      ),
                      Text(
                        currencyFormatter.format(data.pendingAmount),
                        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red.shade700, fontSize: 16),
                      ),
                    ],
                  ),
                if (isFullyPaid)
                  Text(
                    'Paid: ${currencyFormatter.format(data.collectedAmount)}',
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green.shade700, fontSize: 16),
                  ),
              ],
            ),
          ],
        ),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: () => _navigateToLedger(data),
      ),
    );
  }

  // --- BUILD METHOD ---
  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: CustomGradientAppBar(
          title: Text('Packages for ${widget.clientName}'),
        ),
        body: SafeArea(child: _buildAssignmentForm())
      ),
    );
  }
  Widget _buildAssignmentForm() {
    final currencyFormatter = NumberFormat.currency(locale: 'en_IN', symbol: '₹');

    return FutureBuilder<List<PackageModel>>(
      future: _packagesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final packages = snapshot.data ?? [];
        if (packages.isEmpty) {
          return const Center(child: Text('No active packages found.'));
        }

        // --- Form Layout ---
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                // Package Selection Dropdown
                DropdownButtonFormField<PackageModel>(
                  decoration: InputDecoration(
                    labelText: 'Select Package *',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                  ),
                  value: _selectedPackage,
                  hint: const Text('Choose a service package'),
                  isExpanded: true,
                  items: packages.map((package) {
                    return DropdownMenuItem(
                      value: package,
                      child: Text('${package.name} (${currencyFormatter.format(package.price)}) - ${package.category.displayName}'),
                    );
                  }).toList(),
                  onChanged: (PackageModel? newValue) {
                    setState(() {
                      _selectedPackage = newValue;
                      _updateExpiryDate();
                      _calculateBookedAmount();
                    });
                  },
                  validator: (value) => value == null ? 'Package selection is required' : null,
                ),
                const SizedBox(height: 20),

                // Diagnosis Input
                TextFormField(
                  controller: _diagnosisController,
                  decoration: InputDecoration(
                    labelText: 'Client Diagnosis / Condition (Optional)',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 20),

                // Discount Input
                TextFormField(
                  controller: _discountController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'Discount Amount (₹)',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    prefixIcon: const Icon(Icons.money_off),
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                  ],
                  onChanged: (value) {
                    _calculateBookedAmount();
                  },
                  validator: (value) {
                    final amount = double.tryParse(value ?? '0.00') ?? 0.0;
                    if (amount < 0) return 'Discount cannot be negative';
                    if (_selectedPackage != null && amount > _selectedPackage!.price) {
                      return 'Discount cannot exceed package price';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 30),

                // --- Summary Card --


                // --- Dates Section ---
                Text(
                  'Assignment Duration',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.blueGrey.shade700),
                ),
                const SizedBox(height: 10),

                // Start Date Picker
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    'Start Date: ${DateFormat.yMMMd().format(_startDate)}',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () => _selectDate(context, true),
                ),

                // Expiry Date Picker
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    'Expiry Date: ${DateFormat.yMMMd().format(_expiryDate)}',
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: _expiryDate.isBefore(DateTime.now()) ? Colors.red : Colors.black,
                    ),
                  ),
                  trailing: const Icon(Icons.edit_calendar),
                  onTap: () => _selectDate(context, false),
                ),

                const SizedBox(height: 40),

                // Save button
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _assignPackage,
                  icon: const Icon(Icons.link),
                  label: const Text('Assign Package'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                    backgroundColor: Colors.green.shade600,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}