import 'package:flutter/material.dart';
import 'package:scp_mobile_shared/config/app_theme_supplier.dart';
import 'package:scp_mobile_shared/models/complaint_model.dart';
import 'package:scp_mobile_shared/services/complaint_service.dart';

/// Screen for logging a new complaint
class ComplaintLogScreen extends StatefulWidget {
  final String consumerName;
  final String? orderId;
  final String? orderNumber;
  final String conversationId;

  const ComplaintLogScreen({
    super.key,
    required this.consumerName,
    this.orderId,
    this.orderNumber,
    required this.conversationId,
  });

  @override
  State<ComplaintLogScreen> createState() => _ComplaintLogScreenState();
}

class _ComplaintLogScreenState extends State<ComplaintLogScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _complaintService = ComplaintService();
  ComplaintPriority _selectedPriority = ComplaintPriority.medium;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (_formKey.currentState!.validate() && !_isSubmitting) {
      setState(() => _isSubmitting = true);
      
      try {
        await _complaintService.logComplaint(
          conversationId: widget.conversationId,
          consumerId: widget.orderId ?? '', // Will be set from conversation context
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          priority: _selectedPriority,
          orderId: widget.orderId,
        );
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Complaint logged successfully')),
          );
          Navigator.pop(context, true);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to log complaint: $e')),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isSubmitting = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Log Complaint'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Consumer Info
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Consumer Information',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text('Consumer: ${widget.consumerName}'),
                    if (widget.orderNumber != null)
                      Text('Order: ${widget.orderNumber}'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            // Title
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Complaint Title *',
                hintText: 'Brief summary of the issue',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Title is required';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            
            // Description
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description *',
                hintText: 'Detailed description of the complaint',
                border: OutlineInputBorder(),
              ),
              maxLines: 5,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Description is required';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            
            // Priority
            Text(
              'Priority Level',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: ComplaintPriority.values.map((priority) {
                return ChoiceChip(
                  label: Text(priority.name.toUpperCase()),
                  selected: _selectedPriority == priority,
                  onSelected: (selected) {
                    setState(() {
                      _selectedPriority = priority;
                    });
                  },
                  selectedColor: _getPriorityColor(priority).withValues(alpha: 0.2),
                  labelStyle: TextStyle(
                    color: _selectedPriority == priority
                        ? _getPriorityColor(priority)
                        : null,
                    fontWeight: _selectedPriority == priority
                        ? FontWeight.bold
                        : null,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            
            // Escalate checkbox
            CheckboxListTile(
              title: const Text('Escalate to Manager'),
              subtitle: const Text('Immediately forward to manager'),
              value: false,
              onChanged: (value) {
                // Handle escalate toggle
              },
            ),
            const SizedBox(height: 32),
            
            // Submit button
            SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _handleSubmit,
                child: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Log Complaint'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getPriorityColor(ComplaintPriority priority) {
    switch (priority) {
      case ComplaintPriority.low:
        return AppThemeSupplier.priorityLow;
      case ComplaintPriority.medium:
        return AppThemeSupplier.priorityMedium;
      case ComplaintPriority.high:
        return AppThemeSupplier.priorityHigh;
      case ComplaintPriority.urgent:
        return AppThemeSupplier.priorityUrgent;
    }
  }
}

