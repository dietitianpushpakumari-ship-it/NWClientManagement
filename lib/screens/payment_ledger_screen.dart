import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';

import '../modules/package/model/package_assignment_model.dart';
import '../modules/package/model/payment_model.dart';
import '../modules/package/service/package_payment_service.dart';
import 'package:nutricare_client_management/admin/custom_gradient_app_bar.dart';

class PaymentLedgerScreen extends StatefulWidget {
  final PackageAssignmentModel assignment;
  final String clientName;
  final double initialCollectedAmount;

  const PaymentLedgerScreen({
    super.key,
    required this.assignment,
    required this.clientName,
    required this.initialCollectedAmount,
  });

  @override
  State<PaymentLedgerScreen> createState() => _PaymentLedgerScreenState();
}

class _PaymentLedgerScreenState extends State<PaymentLedgerScreen> {
  // 🎯 NOTE: Ensure PackagePaymentService has a deletePayment method for this to work.
  final PackagePaymentService paymentService = PackagePaymentService();
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _narrationController = TextEditingController();

  final currencyFormatter = NumberFormat.currency(locale: 'en_IN', symbol: '₹');

  String _selectedMethod = 'Cash';
  final List<String> _paymentMethods = ['Cash', 'UPI', 'Bank Transfer', 'Card'];

  DateTime? _selectedDate;

  double _currentTotalCollected = 0.0;
  double get _pendingBalance => widget.assignment.bookedAmount - _currentTotalCollected;
  bool get _isFullyPaid => _pendingBalance <= 0.01;

  @override
  void initState() {
    super.initState();
    _currentTotalCollected = widget.initialCollectedAmount;
    _amountController.text = _pendingBalance > 0 ? _pendingBalance.toStringAsFixed(2) : '0.00';
  }

  @override
  void dispose() {
    _amountController.dispose();
    _narrationController.dispose();
    super.dispose();
  }

  // --- Date Picker ---
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: widget.assignment.purchaseDate,
      // Restrict future dates by setting the lastDate to TODAY.
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  // --- NEW: Deletion Confirmation and Logic ---
  Future<bool> _confirmAndDeletePayment(PaymentModel payment) async {
    final reasonController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final bool? shouldDelete = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Deletion', style: TextStyle(color: Colors.red)),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Are you sure you want to delete this payment of ${currencyFormatter.format(payment.amount)}?'),
                const SizedBox(height: 15),
                TextFormField(
                  controller: reasonController,
                  decoration: const InputDecoration(
                    labelText: 'Reason for Deletion *',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Reason is required to delete the payment.';
                    }
                    return null;
                  },
                  maxLines: 2,
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop(false);
              },
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  Navigator.of(context).pop(true);
                }
              },
              child: const Text('Delete', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );

    // If user confirmed AND provided a reason
    if (shouldDelete == true) {
      try {
        // 🎯 NOTE: Assumes paymentService.deletePayment exists and handles backend deletion.
        await paymentService.deletePayment(
          payment.id,
          deletionReason: reasonController.text.trim(),
        );

        // Optimistically update the collected amount and text field locally.
        setState(() {
          _currentTotalCollected -= payment.amount;
          _amountController.text = _pendingBalance > 0 ? _pendingBalance.toStringAsFixed(2) : '0.00';
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Payment of ${currencyFormatter.format(payment.amount)} deleted successfully!')),
          );
        }
        return true; // Dismiss the item
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to delete payment: $e')),
          );
        }
        return false; // Do not dismiss the item on failure
      }
    }
    return false; // Do not dismiss if cancelled
  }

  // --- Core Payment Recording Logic (unchanged) ---
  Future<void> _recordPayment() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a payment date.')));
      return;
    }

    final amountText = _amountController.text;
    final amount = double.tryParse(amountText) ?? 0.0;

    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Amount must be greater than zero.')));
      return;
    }

    // Check if the amount exceeds the pending balance
    if (amount > _pendingBalance + 0.01) { // Add a small tolerance for double precision
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Payment amount exceeds the pending balance of ${currencyFormatter.format(_pendingBalance)}.')),
      );
      return;
    }


    final newPayment = PaymentModel(
      id: '',
      packageAssignmentId: widget.assignment.id,
    // Assuming assignment models has clientId
      amount: amount,
      paymentMethod: _selectedMethod,
      paymentDate: _selectedDate!,
      narration: _narrationController.text.trim(),
      receivedBy: FirebaseAuth.instance.currentUser?.email ?? 'Unknown User',
    );

    try {
      await paymentService.addPayment(newPayment);

      setState(() {
        _currentTotalCollected += amount;
        _amountController.text = _pendingBalance > 0 ? _pendingBalance.toStringAsFixed(2) : '0.00';
        _narrationController.clear();
        _selectedDate = null;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Payment of ${currencyFormatter.format(amount)} recorded successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to record payment: $e')),
        );
      }
    }
  }

  // Helper for Summary Row
  Widget _buildSummaryRow(String label, double amount, Color color, {bool isBold = false, double size = 16}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: size,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: color,
            ),
          ),
          Text(
            currencyFormatter.format(amount),
            style: TextStyle(
              fontSize: size,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  // --- Financial Summary Card ---
  Widget _buildFinancialSummary() {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 16.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${widget.assignment.packageName} Ledger',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.indigo.shade700),
            ),
            const Divider(),

            // Original Price
            _buildSummaryRow('Package Price:', widget.assignment.bookedAmount + widget.assignment.discount ?? 0, Colors.blueGrey),

            // Discount
            if (widget.assignment.discount > 0)
              _buildSummaryRow(
                'Discount Availled:',
                widget.assignment.discount,
                Colors.red.shade700,
              ),

            // Booked Amount
            _buildSummaryRow(
              'Net Booked Amount:',
              widget.assignment.bookedAmount,
              Colors.black87,
              isBold: true,
            ),
            const Divider(height: 10),

            // Collected Amount
            _buildSummaryRow(
              'Total Collected:',
              _currentTotalCollected,
              Colors.green.shade700,
            ),

            // Pending Balance (Highlighted)
            _buildSummaryRow(
              'Pending Balance:',
              _pendingBalance > 0 ? _pendingBalance : 0.0,
              _isFullyPaid ? Colors.green.shade700 : Colors.red.shade700,
              isBold: true,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  // --- Payment Entry Form Card ---
  Widget _buildPaymentEntryForm() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Record New Payment',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blueGrey.shade700),
              ),
              const Divider(),

              // Payment Date Picker
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  _selectedDate == null
                      ? 'Select Payment Date *'
                      : 'Date: ${DateFormat.yMMMd().format(_selectedDate!)}',
                  style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: _selectedDate == null ? Colors.red.shade700 : Colors.black87
                  ),
                ),
                trailing: const Icon(Icons.calendar_today),
                onTap: _isFullyPaid ? null : () => _selectDate(context),
              ),

              // Payment Method Dropdown
              DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  labelText: 'Payment Method',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                ),
                value: _selectedMethod,
                items: _paymentMethods.map((String method) {
                  return DropdownMenuItem<String>(
                    value: method,
                    child: Text(method),
                  );
                }).toList(),
                onChanged: _isFullyPaid ? null : (String? newValue) {
                  setState(() {
                    _selectedMethod = newValue!;
                  });
                },
              ),
              const SizedBox(height: 15),

              // Amount & Send Button
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _amountController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      enabled: !_isFullyPaid,
                      decoration: InputDecoration(
                        labelText: 'Amount (₹) *',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                      ],
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) return 'Amount is mandatory.';
                        final amount = double.tryParse(val);
                        if (amount == null || amount <= 0) return 'Enter a valid amount.';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _isFullyPaid ? null : _recordPayment,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                      // Align with the input field height
                      minimumSize: const Size(0, 56),
                    ),
                    child: const Icon(Icons.send),
                  ),
                ],
              ),
              const SizedBox(height: 15),

              // Narration/Notes Input - Mandatory
              TextFormField(
                controller: _narrationController,
                enabled: !_isFullyPaid,
                decoration: InputDecoration(
                  labelText: 'Narration/Notes *',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
                maxLines: 2,
                validator: (val) => (val == null || val.trim().isEmpty) ? 'Narration is mandatory.' : null,
              ),

              if (_isFullyPaid)
                const Padding(
                  padding: EdgeInsets.only(top: 15.0),
                  child: Text(
                    'This package is fully paid. No more payments required.',
                    style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // --- BUILD METHOD ---
  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: CustomGradientAppBar(
        title: Text('${widget.clientName} - Ledger'),
      ),
      body: SafeArea(child: StreamBuilder<List<PaymentModel>>(
        stream: paymentService.streamPaymentsForAssignment(widget.assignment.id),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error loading payments: ${snapshot.error}'));
          }

          final payments = snapshot.data ?? [];

          return ListView(
            padding: const EdgeInsets.all(16.0),
            children: <Widget>[
              // 1. Financial Summary Card
              _buildFinancialSummary(),

              // 2. Payment Entry Form Card
              _buildPaymentEntryForm(),
              const SizedBox(height: 20),

              // 3. Payment History List
              Text(
                'Payment History (${payments.length} Records)',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueGrey.shade800),
              ),
              const Divider(),

              if (payments.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text('No payments recorded yet.'),
                  ),
                )
              else
              // 🎯 REPLACED map/toList with a mapped iterable of Dismissible widgets
                ...payments.map((payment) {
                  return Dismissible(
                    key: Key(payment.id), // MANDATORY: A unique key for Dismissible
                    direction: DismissDirection.endToStart,
                    background: Container(
                      color: Colors.red.shade700,
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: const Icon(Icons.delete_forever, color: Colors.white, size: 30),
                    ),
                    // IMPORTANT: This calls the dialog and deletion logic before dismissing
                    confirmDismiss: (direction) => _confirmAndDeletePayment(payment),
                    child: Card(
                      elevation: 1,
                      margin: const EdgeInsets.symmetric(vertical: 6.0),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.green.shade100,
                          child: Icon(Icons.receipt_long, color: Colors.green.shade700),
                        ),
                        title: Text(
                          currencyFormatter.format(payment.amount),
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87),
                        ),
                        subtitle: Text(
                          'Method: ${payment.paymentMethod} • Date: ${DateFormat.yMMMd().format(payment.paymentDate)}\nNarration: ${payment.narration}',
                          style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                        ),
                        isThreeLine: true,
                        trailing: Text(
                          payment.receivedBy.split('@').first,
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                        ),
                      ),
                    ),
                  );
                }).toList(),
            ],
          );
        },
      ),),
    );
  }
}