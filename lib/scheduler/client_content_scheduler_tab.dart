import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:nutricare_client_management/modules/client/model/client_model.dart';
import 'package:nutricare_client_management/scheduler/content_scheduler_model.dart';
import 'package:nutricare_client_management/scheduler/content_scheduler_service.dart';
import 'package:nutricare_client_management/scheduler/disease_tag.dart';

// Assuming this path

class ClientContentSchedulerTab extends StatefulWidget {
  final ClientModel client;

  const ClientContentSchedulerTab({super.key, required this.client});

  @override
  State<ClientContentSchedulerTab> createState() => _ClientContentSchedulerTabState();
}

class _ClientContentSchedulerTabState extends State<ClientContentSchedulerTab> {
  final ContentSchedulerService _schedulerService = ContentSchedulerService();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // Form State
  DiseaseTag _selectedTag = DiseaseTag.general;
  ContentFrequency _selectedFrequency = ContentFrequency.weekly;
  DateTime? _startDate;
  DateTime? _endDate;
  bool _isSaving = false;

  // --- Date Picker Helpers ---
  Future<void> _selectDate(BuildContext context, bool isStart) async {
    final DateTime now = DateTime.now();
    final DateTime initialDate = isStart ? (_startDate ?? now) : (_endDate ?? (_startDate ?? now).add(const Duration(days: 30)));
    final DateTime firstDate = now.subtract(const Duration(days: 365));
    final DateTime lastDate = now.add(const Duration(days: 365 * 5));

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
    );

    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  // --- Scheduler CRUD ---
  Future<void> _saveSchedule() async {
    if (!_formKey.currentState!.validate()) return;
    if (_startDate == null || _endDate == null || _endDate!.isBefore(_startDate!)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select valid Start and End dates.')));
      return;
    }

    setState(() => _isSaving = true);

    try {
      final newScheduler = ContentSchedulerModel(
        id: '', // Will be assigned by Firestore
        clientId: widget.client.id,
        diseaseTag: _selectedTag,
        frequency: _selectedFrequency,
        startDate: _startDate!,
        endDate: _endDate!,
        lastSentDate: DateTime.now().subtract(const Duration(days: 365)), // Set far in the past to ensure first send is on time
      );

      await _schedulerService.saveScheduler(newScheduler);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Content Schedule created successfully!')));
        // Reset form after successful save
        setState(() {
          _selectedTag = DiseaseTag.general;
          _selectedFrequency = ContentFrequency.weekly;
          _startDate = null;
          _endDate = null;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to save schedule: ${e.toString()}')));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _deleteSchedule(String id) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Schedule'),
        content: const Text('Are you sure you want to delete this schedule?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _schedulerService.deleteScheduler(id);
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Schedule deleted!')));
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error deleting schedule: $e')));
      }
    }
  }

  // --- UI Builders ---
  Widget _buildSchedulerForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Create New Content Schedule', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const Divider(),

          // 1. Disease Tag Selector
          DropdownButtonFormField<DiseaseTag>(
            decoration: const InputDecoration(labelText: 'Content Disease Tag *', border: OutlineInputBorder()),
            value: _selectedTag,
            items: DiseaseTag.values.map((tag) => DropdownMenuItem(value: tag, child: Text(tag.label))).toList(),
            onChanged: (tag) => setState(() => _selectedTag = tag!),
          ),
          const SizedBox(height: 15),

          // 2. Frequency Selector
          DropdownButtonFormField<ContentFrequency>(
            decoration: const InputDecoration(labelText: 'Frequency *', border: OutlineInputBorder()),
            value: _selectedFrequency,
            items: ContentFrequency.values.map((freq) => DropdownMenuItem(value: freq, child: Text(freq.label))).toList(),
            onChanged: (freq) => setState(() => _selectedFrequency = freq!),
          ),
          const SizedBox(height: 15),

          // 3. Start Date
          ListTile(
            leading: const Icon(Icons.event_available),
            title: Text(_startDate == null ? 'Select Start Date *' : 'Start Date: ${DateFormat('dd MMM yyyy').format(_startDate!)}'),
            trailing: const Icon(Icons.calendar_month),
            onTap: () => _selectDate(context, true),
          ),
          const Divider(height: 0),

          // 4. End Date
          ListTile(
            leading: const Icon(Icons.event_busy),
            title: Text(_endDate == null ? 'Select End Date *' : 'End Date: ${DateFormat('dd MMM yyyy').format(_endDate!)}'),
            trailing: const Icon(Icons.calendar_month),
            onTap: () => _selectDate(context, false),
          ),
          const Divider(height: 0),
          const SizedBox(height: 20),

          // 5. Save Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isSaving ? null : _saveSchedule,
              icon: _isSaving ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.add_task, color: Colors.white),
              label: Text('SCHEDULE CONTENT', style: const TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.primary),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildActiveSchedules() {
    return StreamBuilder<List<ContentSchedulerModel>>(
      stream: _schedulerService.streamClientSchedulers(widget.client.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error loading schedules: ${snapshot.error}'));
        }
        final schedules = snapshot.data ?? [];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Active Schedules (${schedules.length})', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const Divider(),
            if (schedules.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20.0),
                child: Text('No active content schedules for this client.', style: TextStyle(fontStyle: FontStyle.italic)),
              ),
            ...schedules.map((schedule) {
              final isActive = schedule.endDate.isAfter(DateTime.now());
              return Card(
                color: isActive ? Colors.green.shade50 : Colors.grey.shade100,
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: Icon(isActive ? Icons.schedule : Icons.task_alt, color: isActive ? Colors.green : Colors.grey),
                  title: Text('${schedule.diseaseTag.label} Tips', style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('Frequency: ${schedule.frequency.label}\nFrom: ${DateFormat('dd MMM yy').format(schedule.startDate)} to ${DateFormat('dd MMM yy').format(schedule.endDate)}'),
                  isThreeLine: true,
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _deleteSchedule(schedule.id),
                  ),
                ),
              );
            }).toList(),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildSchedulerForm(),
            _buildActiveSchedules(),
          ],
        ),
      ),
    );
  }
}