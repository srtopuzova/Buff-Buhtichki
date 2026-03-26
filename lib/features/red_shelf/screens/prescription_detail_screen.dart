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
                          rx.medicationName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (rx.dosage != null)
                          Text(rx.dosage!,
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
                        await provider.markPickedUp(rx.id);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Marked as picked up!'),
                              backgroundColor: AppColors.success,
                            ),
                          );
                        }
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
                  // Details card
                  _DetailsCard(rx: rx),
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
            'Remove "${rx.medicationName}" prescription? This cannot be undone.'),
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
              icon: const Icon(Icons.check_circle_outline_rounded,
                  size: 16),
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

class _DetailsCard extends StatelessWidget {
  final PrescriptionModel rx;
  const _DetailsCard({required this.rx});

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
          const Text('Prescription Details',
              style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          if (rx.frequency != null)
            _Row('Frequency', rx.frequency!),
          if (rx.duration != null)
            _Row('Duration', rx.duration!),
          if (rx.doctorName != null)
            _Row('Doctor', 'Dr. ${rx.doctorName}'),
          if (rx.patientName != null)
            _Row('Patient', rx.patientName!),
          if (rx.reminderHour != null)
            _Row('Daily Reminder',
                '${rx.reminderHour!.toString().padLeft(2, '0')}:${rx.reminderMinute!.toString().padLeft(2, '0')}'),
          _Row('Added', DateHelpers.formatDisplay(rx.createdAt)),
          if (rx.pickedUpAt != null)
            _Row('Picked Up',
                DateHelpers.formatDisplay(rx.pickedUpAt!)),
          if (rx.instructions != null) ...[
            const Divider(height: 20),
            const Text('Instructions',
                style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(rx.instructions!,
                style: const TextStyle(
                    color: AppColors.textPrimary, fontSize: 14)),
          ],
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