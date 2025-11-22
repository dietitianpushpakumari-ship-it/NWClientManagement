import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/assigned_package_data.dart';
import '../../modules/client/model/client_model.dart';
import '../../modules/package/model/package_assignment_model.dart';
import '../../screens/payment_ledger_screen.dart';
import '../../modules/package/service/package_payment_service.dart';

import 'package:nutricare_client_management/admin/custom_gradient_app_bar.dart';


// Helper class and Enum (Ensure these are at the top level of the file)
enum PaymentFilter { all, fullyPaid, pending, partiallyPaid, notPaid }



class ClientLedgerOverviewScreen extends StatefulWidget {
  const ClientLedgerOverviewScreen({super.key});

  @override
  State<ClientLedgerOverviewScreen> createState() => _ClientLedgerOverviewScreenState();
}

class _ClientLedgerOverviewScreenState extends State<ClientLedgerOverviewScreen> {
  // Service setup
  final PackagePaymentService _paymentService = PackagePaymentService();
  late Future<List<AssignedPackageData>> _ledgerDataFuture;

  final Map<String, double> _collectedAmountCache = {};

  PaymentFilter _currentFilter = PaymentFilter.all;

  // 🎯 NEW STATE: Variables to store the overall totals
  double _totalBooked = 0.0;
  double _totalDiscount = 0.0;
  double _totalCollected = 0.0;
  double _totalDue = 0.0;

  // 🎯 NEW STATE: Controls the visibility of the header card
  bool _isHeaderVisible = true;

  @override
  void initState() {
    super.initState();
    // Initialize the data fetching future
    _ledgerDataFuture = _paymentService.getAllAssignmentsWithCollectedAmounts();
  }

  // 🎯 NEW METHOD: Calculates the four header totals
  void _calculateTotals(List<AssignedPackageData> data) {
    double booked = 0.0;
    double discount = 0.0;
    double collected = 0.0;

    for (var item in data) {
      booked += item.assignment.bookedAmount;
      discount += item.assignment.discount;
      collected += item.collectedAmount;
    }

    // Only update state if values have changed to minimize rebuilds
    if (_totalBooked != booked || _totalCollected != collected) {
      setState(() {
        _totalBooked = booked;
        _totalDiscount = discount;
        _totalCollected = collected;
        _totalDue = booked - collected;
      });
    }
  }

  // 🎯 NEW WIDGET: Builds the header card showing totals
  Widget _buildSummaryHeader() {
    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      elevation: 4,
      color: Colors.blue.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Overall Financial Summary', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const Divider(height: 16, thickness: 1.5),
            _buildSummaryRow('Total Booked Amount', _totalBooked, Colors.blue.shade700),
            _buildSummaryRow('Total Discount Offered', _totalDiscount, Colors.red.shade700),
            const Divider(height: 16),
            _buildSummaryRow('Total Collected', _totalCollected, Colors.green.shade700),
            _buildSummaryRow('Total Due', _totalDue, _totalDue > 0 ? Colors.orange.shade700 : Colors.green.shade700),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, double amount, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 14)),
          Text(
            '₹${amount.toStringAsFixed(0)}',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: color),
          ),
        ],
      ),
    );
  }

  // --- Existing _buildAssignmentCard and Filter Logic (omitted for brevity) ---
  // ... (Assuming the existing methods are here) ...
  Widget _buildAssignmentCard(AssignedPackageData data, int index) {
    // Your existing _buildAssignmentCard implementation
    final isFullyPaid = data.status == PaymentFilter.fullyPaid;
    final cardColor = isFullyPaid ? Colors.green.shade50 : Colors.white;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      elevation: 2,
      color: cardColor,
      child: InkWell(
        onTap: () {
          // Navigate to payment ledger screen
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => PaymentLedgerScreen(
                assignment: data.assignment,
                clientName: data.clientName,
                initialCollectedAmount: data.collectedAmount,
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Client Name and Status
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${index + 1}. ${data.clientName}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  Text(
                    isFullyPaid ? 'PAID' : 'PENDING',
                    style: TextStyle(
                      color: isFullyPaid ? Colors.green : Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const Divider(height: 12),

              // Package Details
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Package: ${data.assignment.packageName}',
                    style: TextStyle(color: Colors.grey.shade700),
                  ),
                  // Display Discount
                  Text(
                    'Discount: ₹${data.assignment.discount.toStringAsFixed(0)}',
                    style: TextStyle(color: Colors.red.shade400, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              const Divider(height: 12),

              // Financial Breakdown
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildDetailColumn('Booked', data.assignment.bookedAmount, Colors.blue),
                  _buildDetailColumn('Collected', data.collectedAmount, Colors.green),
                  _buildDetailColumn('Pending', data.pendingAmount, Colors.red),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailColumn(String label, double amount, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
        Text(
          '₹${amount.toStringAsFixed(0)}',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16, color: color),
        ),
      ],
    );
  }
  // --- End of existing methods ---

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: CustomGradientAppBar(
        title: const Text('Ledger Overview'),
        // 🎯 NEW: Toggle button for the header card
        actions: [
          IconButton(
            icon: Icon(_isHeaderVisible ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down),
            onPressed: () {
              setState(() {
                _isHeaderVisible = !_isHeaderVisible;
              });
            },
            tooltip: _isHeaderVisible ? 'Hide Summary' : 'Show Summary',
          ),
        ],
      ),
      body: SafeArea(child: FutureBuilder<List<AssignedPackageData>>(
        future: _ledgerDataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error loading data: ${snapshot.error}'));
          }

          final allData = snapshot.data ?? [];

          // 🎯 CRITICAL: Calculate totals upon successful load.
          // We use addPostFrameCallback to safely call setState() after the widget tree is built.
          if (snapshot.connectionState == ConnectionState.done && allData.isNotEmpty) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _calculateTotals(allData);
            });
          }

          // Filter the data based on the current selection (assuming you have this filter logic)
          // 🎯 THE FILTER FIX IS HERE
          final filteredData = allData.where((data) {
            if (_currentFilter == PaymentFilter.all) return true;

            // 🎯 FIX 1: Pending means anything that is NOT fully paid.
            if (_currentFilter == PaymentFilter.pending) {
              return data.status != PaymentFilter.fullyPaid;
            }

            // 🎯 FIX 2: Partially Paid and Not Paid should also fall under Pending.
            // If the user selects a specific status, return it.
            return data.status == _currentFilter;

          }).toList();



          return Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              children: [
                // 1. HEADER SUMMARY CARD
                Visibility(
                  visible: _isHeaderVisible,
                  child: _buildSummaryHeader(),
                ),

                // 2. FILTER/SORT BAR (Filter UI assumed here)
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Row(
                    children: PaymentFilter.values.map((filter) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: ChoiceChip(
                          label: Text(filter.name.toUpperCase()),
                          selected: _currentFilter == filter,
                          onSelected: (selected) {
                            if (selected) {
                              setState(() {
                                _currentFilter = filter;
                              });
                            }
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),


                // 3. LIST OF ASSIGNMENTS
                Expanded(
                  child: filteredData.isEmpty
                      ? const Center(child: Text('No assignments matching the filter criteria.'))
                      : ListView.builder(
                    shrinkWrap: true,
                    // CRITICAL: Prevents the inner ListView from fighting for scroll with the outer SingleChildScrollView
                    physics: const ScrollPhysics(),
                    itemCount: filteredData.length,
                    itemBuilder: (context, index) {
                      return _buildAssignmentCard(filteredData[index], index);
                    },
                  ),
                ),
                // Show a message if list is empty after the fixed headers
                if (filteredData.isEmpty)
                   const Center(child: Padding(
                     padding: EdgeInsets.only(top: 24.0),
                     child: Text('No assignments matching the filter criteria.'),
                   )),
              ],
            ),
          );
        },
      ),),
    );
  }
}