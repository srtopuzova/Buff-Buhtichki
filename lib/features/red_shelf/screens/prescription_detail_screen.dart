import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:medshelf/core/theme/app_colors.dart';
import 'package:medshelf/core/utils/date_helpers.dart';
import 'package:medshelf/features/red_shelf/models/prescription_model.dart';
import 'package:medshelf/features/red_shelf/providers/prescription_provider.dart';
import 'package:medshelf/features/red_shelf/widgets/dose_tracker.dart';

class PrescriptionDetailScreen extends StatelessWidget {
  final String prescriptionId;

  const PrescriptionDetailScreen({super.key, required this.prescriptionId});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PrescriptionProvider>();
    final rx = provider.prescriptions.cast<PrescriptionModel?>().firstWhere(
          (p) => p?.id == prescriptionId,
          orElse: () => null,
        );

    if (rx == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Prescription')),
        body: const Center(child: Text('Prescription not found')),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: AppColors.redShelf,
            foregroundColor: Colors.white,
            actions: [
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded,
                    color: Colors.white),
                onPressed: () => _confirmDelete(context, rx),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration:
                    BoxDecoration(gradient: AppColors.redShelfGradient),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 56, 20, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        _StatusPill(status: rx.status),
                        const SizedBox(height: 8),
                        Text(
                          rx.items.length == 1
                              ? rx.items[0].name
                              : '${rx.items.length} medications',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (rx.doctorName != null)
                          Text('Dr. ${rx.doctorName}',
                              style: const TextStyle(
                                  color: Colors.white70, fontSize: 14)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Pending pickup banner
                  if (rx.isPending) ...[
                    _PendingBanner(
                      onPickedUp: () async {
                        final success = await provider.markPickedUp(rx.id);
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(success
                                ? 'Marked as picked up!'
                                : provider.errorMessage ?? 'Failed to update'),
                            backgroundColor: success
                                ? AppColors.success
                                : AppColors.error,
                          ),
                        );
                        if (success) provider.clearError();
                      },
                    ),
                    const SizedBox(height: 16),
                  ],
                  // Dose tracker (only when active)
                  if (rx.isActive) ...[
                    DoseTracker(
                      prescription: rx,
                      onTaken: () => provider.recordDose(rx.id, true),
                      onSkipped: () => provider.recordDose(rx.id, false),
                    ),
                    const SizedBox(height: 16),
                  ],
                  // All medications list
                  _MedicationsList(items: rx.items),
                  const SizedBox(height: 16),
                  // Prescription info card
                  _InfoCard(rx: rx),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(
      BuildContext context, PrescriptionModel rx) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Prescription'),
        content: Text(
            'Remove "${rx.title}" prescription? This cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await context.read<PrescriptionProvider>().deletePrescription(rx.id);
      if (context.mounted) context.pop();
    }
  }
}

class _StatusPill extends StatelessWidget {
  final PrescriptionStatus status;
  const _StatusPill({required this.status});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.label,
        style: const TextStyle(color: Colors.white, fontSize: 12),
      ),
    );
  }
}

class _PendingBanner extends StatelessWidget {
  final VoidCallback onPickedUp;
  const _PendingBanner({required this.onPickedUp});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.warningLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.local_pharmacy_rounded,
                  color: AppColors.warning, size: 20),
              SizedBox(width: 8),
              Text('Pending Pharmacy Pickup',
                  style: TextStyle(
                      color: AppColors.warning,
                      fontWeight: FontWeight.w700,
                      fontSize: 14)),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Confirm when you have picked up this prescription.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onPickedUp,
              icon: const Icon(Icons.check_circle_outline_rounded, size: 16),
              label: const Text('Confirm Pickup'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MedicationsList extends StatelessWidget {
  final List<PrescribedItem> items;
  const _MedicationsList({required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.medication_rounded,
                  color: AppColors.redShelf, size: 18),
              const SizedBox(width: 8),
              Text(
                'Medications (${items.length})',
                style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 12),
          for (int i = 0; i < items.length; i++) ...[
            if (i > 0)
              const Divider(height: 20),
            _MedItemRow(index: i, item: items[i]),
          ],
        ],
      ),
    );
  }
}

class _MedItemRow extends StatelessWidget {
  final int index;
  final PrescribedItem item;
  const _MedItemRow({required this.index, required this.item});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 22,
              height: 22,
              decoration: const BoxDecoration(
                color: AppColors.redShelfLight,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  '${index + 1}',
                  style: const TextStyle(
                      color: AppColors.redShelf,
                      fontSize: 11,
                      fontWeight: FontWeight.w700),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                item.name,
                style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        if (item.dosage != null || item.frequency != null) ...[
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.only(left: 30),
            child: Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                if (item.dosage != null)
                  _Chip(Icons.scale_rounded, item.dosage!),
                if (item.frequency != null)
                  _Chip(Icons.access_time_rounded, item.frequency!),
                if (item.duration != null)
                  _Chip(Icons.calendar_today_rounded, item.duration!),
              ],
            ),
          ),
        ],
        if (item.instructions != null) ...[
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(left: 30),
            child: Text(
              item.instructions!,
              style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  fontStyle: FontStyle.italic),
            ),
          ),
        ],
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _Chip(this.icon, this.label);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.redShelfLight,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: AppColors.redShelf),
          const SizedBox(width: 4),
          Text(label,
              style: const TextStyle(
                  color: AppColors.redShelf,
                  fontSize: 11,
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final PrescriptionModel rx;
  const _InfoCard({required this.rx});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Prescription Info',
              style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          if (rx.doctorName != null)
            _Row('Doctor', 'Dr. ${rx.doctorName}'),
          if (rx.patientName != null)
            _Row('Patient', rx.patientName!),
          if (rx.reminderHour != null)
            _Row('Daily Reminder',
                '${rx.reminderHour!.toString().padLeft(2, '0')}:${rx.reminderMinute!.toString().padLeft(2, '0')}'),
          _Row('Added', DateHelpers.formatDisplay(rx.createdAt)),
          if (rx.pickedUpAt != null)
            _Row('Picked Up', DateHelpers.formatDisplay(rx.pickedUpAt!)),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final String label;
  final String value;
  const _Row(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(label,
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 13)),
          ),
          Expanded(
            child: Text(value,
                style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }
}
