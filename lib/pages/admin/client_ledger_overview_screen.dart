import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:nutricare_client_management/admin/labvital/global_service_provider.dart';

// 🎯 Project Imports
import '../../models/assigned_package_data.dart';
import '../../modules/package/model/package_assignment_model.dart';
import '../../screens/payment_ledger_screen.dart';
import '../../modules/package/service/package_payment_service.dart';

// Helper Enum
enum PaymentFilter { all, fullyPaid, pending }

class ClientLedgerOverviewScreen extends ConsumerStatefulWidget {
  const ClientLedgerOverviewScreen({super.key});

  @override
  ConsumerState<ClientLedgerOverviewScreen> createState() => _ClientLedgerOverviewScreenState();
}

class _ClientLedgerOverviewScreenState extends ConsumerState<ClientLedgerOverviewScreen> {
  late Future<List<AssignedPackageData>> _ledgerDataFuture;

  PaymentFilter _currentFilter = PaymentFilter.all;

  // Totals
  double _totalBooked = 0.0;
  double _totalDiscount = 0.0;
  double _totalCollected = 0.0;
  double _totalDue = 0.0;

  bool _isHeaderVisible = true;

  @override
  void initState() {
    super.initState();
    // 🎯 FIX: Changed ref.watch to ref.read here
    _ledgerDataFuture = ref.read(packagePaymentServiceProvider).getAllAssignmentsWithCollectedAmounts();
  }

  void _calculateTotals(List<AssignedPackageData> data) {
    double booked = 0.0;
    double discount = 0.0;
    double collected = 0.0;

    for (var item in data) {
      booked += item.assignment.bookedAmount;
      discount += item.assignment.discount;
      collected += item.collectedAmount;
    }

    // Update state only if changed
    if (_totalBooked != booked || _totalCollected != collected) {
      // Use post frame callback to avoid build conflicts during init
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _totalBooked = booked;
            _totalDiscount = discount;
            _totalCollected = collected;
            _totalDue = booked - collected;
          });
        }
      });
    }
  }

  // --- UI BUILDERS ---

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      body: Stack(
        children: [
          // 1. Ambient Glow
          Positioned(
            top: -100, right: -100,
            child: Container(
              width: 300, height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: Colors.blue.withOpacity(0.1), blurRadius: 80, spreadRadius: 30)],
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // 2. Custom Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
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
                          const Text("Financial Ledger", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1A1A1A))),
                        ],
                      ),
                      IconButton(
                        icon: Icon(_isHeaderVisible ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: Theme.of(context).colorScheme.primary),
                        onPressed: () => setState(() => _isHeaderVisible = !_isHeaderVisible),
                        tooltip: "Toggle Summary",
                      )
                    ],
                  ),
                ),

                // 3. Main Content
                Expanded(
                  child: FutureBuilder<List<AssignedPackageData>>(
                    future: _ledgerDataFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                      if (snapshot.hasError) return Center(child: Text("Error: ${snapshot.error}"));

                      final allData = snapshot.data ?? [];
                      // Calculate totals immediately
                      if (snapshot.connectionState == ConnectionState.done) _calculateTotals(allData);

                      // Filter Logic
                      final filteredData = allData.where((data) {
                        if (_currentFilter == PaymentFilter.all) return true;
                        if (_currentFilter == PaymentFilter.pending) return data.status != 'fullyPaid';
                        if (_currentFilter == PaymentFilter.fullyPaid) return data.status == 'fullyPaid';
                        return true;
                      }).toList();

                      return Column(
                        children: [
                          // 4. Financial Dashboard Card
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            height: _isHeaderVisible ? null : 0,
                            padding: _isHeaderVisible ? const EdgeInsets.symmetric(horizontal: 20) : EdgeInsets.zero,
                            child: _isHeaderVisible
                                ? _buildFinancialSummaryCard(currencyFormatter)
                                : const SizedBox(),
                          ),

                          // 5. Filter Bar
                          Padding(
                            padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
                            child: _buildFilterBar(),
                          ),

                          // 6. Transaction List
                          Expanded(
                            child: filteredData.isEmpty
                                ? _buildEmptyState()
                                : ListView.builder(
                              padding: const EdgeInsets.fromLTRB(20, 0, 20, 80),
                              itemCount: filteredData.length,
                              itemBuilder: (context, index) => _buildPremiumLedgerCard(filteredData[index], currencyFormatter),
                            ),
                          ),
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

  // --- WIDGETS ---

  Widget _buildFinancialSummaryCard(NumberFormat formatter) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [Theme.of(context).colorScheme.primary, Theme.of(context).colorScheme.primary.withOpacity(.7)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Theme.of(context).colorScheme.primary.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10))],
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
                  Text("Total Revenue", style: TextStyle(color: Theme.of(context).colorScheme.primary.withOpacity(.15), fontSize: 14, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 4),
                  Text(formatter.format(_totalBooked), style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.analytics_outlined, color: Colors.white, size: 24),
              )
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Collected", style: TextStyle(color: Colors.green.shade100, fontSize: 12)),
                    const SizedBox(height: 4),
                    Text(formatter.format(_totalCollected), style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              Container(width: 1, height: 30, color: Colors.white.withOpacity(0.2)),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Outstanding", style: TextStyle(color: Colors.orange.shade100, fontSize: 12)),
                    const SizedBox(height: 4),
                    Text(formatter.format(_totalDue), style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    return Container(
      height: 45,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)],
      ),
      child: Row(
        children: [
          _buildFilterTab("All", PaymentFilter.all),
          _buildFilterTab("Pending", PaymentFilter.pending),
          _buildFilterTab("Completed", PaymentFilter.fullyPaid),
        ],
      ),
    );
  }

  Widget _buildFilterTab(String label, PaymentFilter filter) {
    final isSelected = _currentFilter == filter;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _currentFilter = filter),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? Theme.of(context).colorScheme.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: isSelected ? Colors.white : Colors.grey.shade600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPremiumLedgerCard(AssignedPackageData data, NumberFormat formatter) {
    final isPaid = data.status == 'fullyPaid';
    final progress = data.assignment.bookedAmount > 0
        ? (data.collectedAmount / data.assignment.bookedAmount).clamp(0.0, 1.0)
        : 0.0;

    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(
          builder: (_) => PaymentLedgerScreen(
              assignment: data.assignment,
              clientName: data.clientName,
              initialCollectedAmount: data.collectedAmount
          )
      )),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
          border: isPaid ? Border.all(color: Colors.transparent) : Border.all(color: Colors.red.withOpacity(0.1), width: 1.5),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(data.clientName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF2D3142))),
                      Text(data.assignment.packageName, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: isPaid ? Colors.green.shade50 : Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    isPaid ? "PAID" : "PENDING",
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: isPaid ? Colors.green.shade700 : Colors.red.shade700),
                  ),
                )
              ],
            ),
            const SizedBox(height: 16),

            // Progress Bar
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: Colors.grey.shade100,
                color: isPaid ? Colors.green : Colors.orange,
                minHeight: 6,
              ),
            ),
            const SizedBox(height: 12),

            // Stats Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Collected", style: TextStyle(fontSize: 11, color: Colors.grey)),
                    Text(formatter.format(data.collectedAmount), style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green.shade700)),
                  ],
                ),
                if (!isPaid)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text("Due", style: TextStyle(fontSize: 11, color: Colors.grey)),
                      Text(formatter.format(data.pendingAmount), style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red.shade700)),
                    ],
                  ),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.filter_list_off, size: 48, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text("No records found", style: TextStyle(fontSize: 16, color: Colors.grey.shade500)),
        ],
      ),
    );
  }
}