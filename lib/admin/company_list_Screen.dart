import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:nutricare_client_management/admin/add_company_screen.dart';
import 'package:nutricare_client_management/admin/company_detail_screen.dart';
import 'package:nutricare_client_management/admin/tenant_model.dart';
import 'package:nutricare_client_management/admin/tenant_service.dart';

class CompanyListScreen extends StatefulWidget {
  const CompanyListScreen({super.key});

  @override
  State<CompanyListScreen> createState() => _CompanyListScreenState();
}

class _CompanyListScreenState extends State<CompanyListScreen> {
  final TenantOnboardingService _service = TenantOnboardingService();
  String _searchQuery = "";
  String? _filterStatus; // 'active', 'suspended', or null (All)

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      appBar: AppBar(
        title: const Text("Managed Clinics", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_business_rounded, color: Colors.indigo),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddCompanyScreen())),
            tooltip: "Onboard New",
          )
        ],
      ),
      body: Column(
        children: [
          // 🔍 SEARCH & FILTER BAR
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Column(
              children: [
                TextField(
                  decoration: InputDecoration(
                    hintText: "Search by Name, ID, or Owner...",
                    prefixIcon: const Icon(Icons.search, color: Colors.grey),
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 20),
                  ),
                  onChanged: (val) => setState(() => _searchQuery = val.toLowerCase()),
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip("All", null),
                      _buildFilterChip("Active", "active"),
                      _buildFilterChip("Suspended", "suspended"),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // 📋 LIST
          Expanded(
            child: StreamBuilder<List<TenantModel>>(
              stream: _service.streamAllTenants(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());

                final allTenants = snapshot.data ?? [];

                // 🌪️ FILTER LOGIC
                final filtered = allTenants.where((t) {
                  // Status Filter
                  if (_filterStatus != null && t.status != _filterStatus) return false;
                  // Search Filter
                  if (_searchQuery.isNotEmpty) {
                    final matches = t.name.toLowerCase().contains(_searchQuery) ||
                        t.id.contains(_searchQuery) ||
                        t.ownerName.toLowerCase().contains(_searchQuery);
                    if (!matches) return false;
                  }
                  return true;
                }).toList();

                if (filtered.isEmpty) return _buildEmptyState();

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) => _buildCompanyCard(filtered[index]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompanyCard(TenantModel tenant) {
    final bool isActive = tenant.status == 'active';
    final Color statusColor = isActive ? Colors.green : Colors.red;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.grey.shade200)),
      child: InkWell(
        onTap: () {
          // Always go to Detail Screen
          Navigator.push(context, MaterialPageRoute(
            builder: (_) => CompanyDetailScreen(tenant: tenant),
          ));
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(color: Colors.indigo.shade50, borderRadius: BorderRadius.circular(12)),
                        child: const Icon(Icons.business, color: Colors.indigo, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(tenant.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          Text("ID: ${tenant.id}", style: TextStyle(color: Colors.grey.shade500, fontSize: 11)),
                        ],
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                    child: Text(tenant.status.toUpperCase(), style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 10)),
                  ),
                ],
              ),
              const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider(height: 1)),
              Row(
                children: [
                  _buildInfo(Icons.person, tenant.ownerName),
                  const SizedBox(width: 16),
                  _buildInfo(Icons.calendar_today, tenant.invitedAt != null
                      ? DateFormat('MMM d, y').format(tenant.invitedAt!)
                      : "Unknown"),
                  const Spacer(),
                  const Icon(Icons.chevron_right, size: 18, color: Colors.grey)
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfo(IconData icon, String text) {
    return Row(children: [Icon(icon, size: 14, color: Colors.grey), const SizedBox(width: 4), Text(text, style: TextStyle(fontSize: 12, color: Colors.grey.shade700))]);
  }

  Widget _buildFilterChip(String label, String? status) {
    final isSelected = _filterStatus == status;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (val) => setState(() => _filterStatus = status),
        selectedColor: Colors.indigo,
        labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black87, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal),
        backgroundColor: Colors.white,
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 60, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          const Text("No clinics found matching criteria.", style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}