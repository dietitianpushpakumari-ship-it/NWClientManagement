import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../modules/package/model/package_assignment_model.dart';
import '../modules/package/model/payment_model.dart';
import '../modules/package/service/package_payment_service.dart';

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

  // --- Logic Helpers ---

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: widget.assignment.purchaseDate,
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

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
                Text('Delete payment of ${currencyFormatter.format(payment.amount)}?'),
                const SizedBox(height: 15),
                TextFormField(
                  controller: reasonController,
                  decoration: const InputDecoration(labelText: 'Reason *', border: OutlineInputBorder()),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Reason required' : null,
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(child: const Text('Cancel'), onPressed: () => Navigator.of(context).pop(false)),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
              onPressed: () {
                if (formKey.currentState!.validate()) Navigator.of(context).pop(true);
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (shouldDelete == true) {
      try {
        await paymentService.deletePayment(payment.id, deletionReason: reasonController.text.trim());
        setState(() {
          _currentTotalCollected -= payment.amount;
          _amountController.text = _pendingBalance > 0 ? _pendingBalance.toStringAsFixed(2) : '0.00';
        });
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Payment deleted.')));
        return true;
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
        return false;
      }
    }
    return false;
  }

  Future<void> _recordPayment() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Select a payment date.')));
      return;
    }

    final amount = double.tryParse(_amountController.text) ?? 0.0;
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Amount must be > 0')));
      return;
    }
    if (amount > _pendingBalance + 0.01) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Exceeds pending balance.')));
      return;
    }

    final newPayment = PaymentModel(
      id: '',
      packageAssignmentId: widget.assignment.id,
      amount: amount,
      paymentMethod: _selectedMethod,
      paymentDate: _selectedDate!,
      narration: _narrationController.text.trim(),
      receivedBy: FirebaseAuth.instance.currentUser?.email ?? 'Unknown',
    );

    try {
      await paymentService.addPayment(newPayment);
      setState(() {
        _currentTotalCollected += amount;
        _amountController.text = _pendingBalance > 0 ? _pendingBalance.toStringAsFixed(2) : '0.00';
        _narrationController.clear();
        _selectedDate = null;
      });
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Payment recorded!')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
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
            top: -100, right: -80,
            child: Container(
              width: 300, height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: Colors.green.withOpacity(0.1), blurRadius: 80, spreadRadius: 30)],
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // 2. Custom Header (Fixed Alignment)
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
                      const Text("Payment Ledger", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1A1A1A))),
                    ],
                  ),
                ),

                // 3. Main Content
                Expanded(
                  child: StreamBuilder<List<PaymentModel>>(
                    stream: paymentService.streamPaymentsForAssignment(widget.assignment.id),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                      if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));

                      final payments = snapshot.data ?? [];

                      return ListView(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
                        children: [
                          // Financial Summary
                          _buildFinancialCard(),
                          const SizedBox(height: 20),

                          // Entry Form
                          _buildPaymentForm(),
                          const SizedBox(height: 24),

                          // History Header
                          Row(
                            children: [
                              Container(width: 4, height: 18, margin: const EdgeInsets.only(right: 8), decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary, borderRadius: BorderRadius.circular(2))),
                              Text("Transaction History (${payments.length})", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF2D3142))),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // History List
                          if (payments.isEmpty)
                            const Padding(padding: EdgeInsets.all(20), child: Center(child: Text("No payments yet", style: TextStyle(color: Colors.grey))))
                          else
                            ...payments.map((p) => _buildPaymentTile(p)),
                        ],
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

  Widget _buildFinancialCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 15, offset: const Offset(0, 5))],
        border: Border.all(color: Colors.blueGrey.withOpacity(0.1)),
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
                  Text(widget.assignment.packageName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF2D3142))),
                  const SizedBox(height: 4),
                  Text(widget.clientName, style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: Colors.orange.shade50, shape: BoxShape.circle),
                child: Icon(Icons.account_balance_wallet, color: Colors.orange.shade700, size: 24),
              ),
            ],
          ),
          const Divider(height: 24),
          _buildSummaryRow("Total Cost", widget.assignment.bookedAmount, Colors.black87),
          const SizedBox(height: 8),
          _buildSummaryRow("Paid", _currentTotalCollected, Colors.green.shade700),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _isFullyPaid ? Colors.green.shade50 : Colors.red.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Pending Balance", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: _isFullyPaid ? Colors.green.shade900 : Colors.red.shade900)),
                Text(currencyFormatter.format(_pendingBalance > 0 ? _pendingBalance : 0), style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: _isFullyPaid ? Colors.green.shade900 : Colors.red.shade900)),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildPaymentForm() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Record New Payment", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),

            if (_isFullyPaid)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.green.shade200)),
                child: const Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green),
                    SizedBox(width: 8),
                    Text("Payment Complete", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                  ],
                ),
              )
            else
              Column(
                children: [
                  Row(
                    children: [
                      Expanded(child: _buildDatePicker()),
                      const SizedBox(width: 12),
                      Expanded(child: _buildDropdown()),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildTextField("Amount (₹)", _amountController, isNumber: true, validator: (v) => (double.tryParse(v ?? '') ?? 0) <= 0 ? 'Invalid' : null),
                  const SizedBox(height: 16),
                  _buildTextField("Narration / Notes", _narrationController),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: _recordPayment,
                      icon: const Icon(Icons.add_card, size: 18),
                      label: const Text("RECORD PAYMENT", style: TextStyle(fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 4,
                        shadowColor: Theme.of(context).colorScheme.primary.withOpacity(0.4),
                      ),
                    ),
                  )
                ],
              )
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentTile(PaymentModel payment) {
    return Dismissible(
      key: Key(payment.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) => _confirmAndDeletePayment(payment),
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(color: Colors.red.shade100, borderRadius: BorderRadius.circular(16)),
        alignment: Alignment.centerRight,
        child: Icon(Icons.delete_forever, color: Colors.red.shade700, size: 28),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade100),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: Colors.teal.shade50, borderRadius: BorderRadius.circular(10)),
              child: Icon(Icons.receipt, color: Colors.teal.shade700, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(currencyFormatter.format(payment.amount), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
                  const SizedBox(height: 4),
                  Text("${payment.paymentMethod} • ${DateFormat('dd MMM yyyy').format(payment.paymentDate)}", style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                  if ( payment.narration != null && payment.narration!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(payment.narration!, style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: Colors.grey)),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Helper Widgets ---

  Widget _buildSummaryRow(String label, double val, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: Colors.grey.shade700, fontWeight: FontWeight.w500)),
        Text(currencyFormatter.format(val), style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 16)),
      ],
    );
  }

  Widget _buildTextField(String label, TextEditingController ctrl, {bool isNumber = false, String? Function(String?)? validator}) {
    return TextFormField(
      controller: ctrl,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      validator: validator ?? (v) => (v == null || v.isEmpty) ? 'Required' : null,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.grey.shade50,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  Widget _buildDatePicker() {
    return InkWell(
      onTap: _isFullyPaid ? null : () => _selectDate(context),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 50,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(12)),
        child: Row(
          children: [
            Icon(Icons.calendar_today, size: 16, color: _selectedDate == null ? Colors.orange : Theme.of(context).colorScheme.primary),
            const SizedBox(width: 8),
            Text(_selectedDate == null ? "Date" : DateFormat('dd/MM').format(_selectedDate!), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdown() {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(12)),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedMethod,
          icon: const Icon(Icons.keyboard_arrow_down, size: 18),
          isExpanded: true,
          style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 13),
          items: _paymentMethods.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
          onChanged: _isFullyPaid ? null : (v) => setState(() => _selectedMethod = v!),
        ),
      ),
    );
  }
}