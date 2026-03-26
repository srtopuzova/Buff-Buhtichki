import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:medshelf/core/theme/app_colors.dart';
import 'package:medshelf/core/utils/date_helpers.dart';
import 'package:medshelf/features/med_shelf/models/medication_model.dart';
import 'package:medshelf/features/med_shelf/providers/medication_provider.dart';

class MedicationDetailScreen extends StatelessWidget {
  final String medicationId;

  const MedicationDetailScreen({super.key, required this.medicationId});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MedicationProvider>();
    final med = provider.medications.cast<MedicationModel?>().firstWhere(
          (m) => m?.id == medicationId,
          orElse: () => null,
        );

    if (med == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Medication')),
        body: const Center(child: Text('Medication not found')),
      );
    }

    final daysLeft = med.daysUntilExpiry;
    final statusColor = med.isExpired
        ? AppColors.error
        : daysLeft <= 7
            ? AppColors.error
            : daysLeft <= 30
                ? AppColors.warning
                : AppColors.success;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            backgroundColor: AppColors.medShelf,
            foregroundColor: Colors.white,
            actions: [
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded,
                    color: Colors.white),
                onPressed: () => _confirmDelete(context, med),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(gradient: AppColors.medShelfGradient),
                child: Stack(
                  children: [
                    if (med.imageUrl != null)
                      Positioned.fill(
                        child: Opacity(
                          opacity: 0.25,
                          child: Image.network(
                            med.imageUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const SizedBox(),
                          ),
                        ),
                      ),
                    SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 56, 20, 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                med.category.label,
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 12),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              med.name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            if (med.dosage != null)
                              Text(
                                med.dosage!,
                                style: const TextStyle(
                                    color: Colors.white70, fontSize: 14),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Overall status (earliest expiry)
                  _StatusCard(
                    med: med,
                    statusColor: statusColor,
                    daysLeft: daysLeft,
                  ),
                  const SizedBox(height: 16),
                  // All boxes
                  _BatchesCard(
                    med: med,
                    onAddBatch: () => _showAddBatchSheet(context, med),
                    onRemoveBatch: (batchId) =>
                        _confirmRemoveBatch(context, med, batchId),
                  ),
                  const SizedBox(height: 16),
                  // Details
                  _DetailCard(med: med),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, MedicationModel med) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Medication'),
        content: Text(
            'Remove "${med.name}" from your shelf? This cannot be undone.'),
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
      await context.read<MedicationProvider>().deleteMedication(med.id);
      if (context.mounted) context.pop();
    }
  }

  Future<void> _showAddBatchSheet(
      BuildContext context, MedicationModel med) async {
    final batch = await showModalBottomSheet<MedicationBatch>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _AddBatchSheet(),
    );
    if (batch == null || !context.mounted) return;

    final success = await context.read<MedicationProvider>().addBatch(
          medicationId: med.id,
          batch: batch,
          medicationName: med.name,
        );
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(success ? 'Box added!' : 'Failed to add box'),
      backgroundColor: success ? AppColors.success : AppColors.error,
    ));
  }

  Future<void> _confirmRemoveBatch(
      BuildContext context, MedicationModel med, String batchId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove Box'),
        content: const Text('Remove this box? Its notifications will be cancelled.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await context.read<MedicationProvider>().removeBatch(
            medicationId: med.id,
            batchId: batchId,
            currentBatches: med.batches,
          );
    }
  }
}

// ─── Status card ─────────────────────────────────────────────────────────────

class _StatusCard extends StatelessWidget {
  final MedicationModel med;
  final Color statusColor;
  final int daysLeft;

  const _StatusCard({
    required this.med,
    required this.statusColor,
    required this.daysLeft,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: statusColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              med.isExpired ? Icons.warning_rounded : Icons.schedule_rounded,
              color: statusColor,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  med.isExpired
                      ? 'Expired'
                      : DateHelpers.expiryLabel(med.expiryDate),
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  med.batches.length == 1
                      ? 'Expiry: ${DateHelpers.formatDisplay(med.expiryDate)}'
                      : 'Earliest expiry: ${DateHelpers.formatDisplay(med.expiryDate)}',
                  style: TextStyle(
                    color: statusColor.withValues(alpha: 0.8),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Batches card ────────────────────────────────────────────────────────────

class _BatchesCard extends StatelessWidget {
  final MedicationModel med;
  final VoidCallback onAddBatch;
  final void Function(String batchId) onRemoveBatch;

  const _BatchesCard({
    required this.med,
    required this.onAddBatch,
    required this.onRemoveBatch,
  });

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
              const Icon(Icons.inventory_2_rounded,
                  color: AppColors.medShelf, size: 18),
              const SizedBox(width: 8),
              Text(
                'Boxes (${med.batches.length})  •  Total qty: ${med.quantity}',
                style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w700),
              ),
              const Spacer(),
              GestureDetector(
                onTap: onAddBatch,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.medShelfLight,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add_rounded,
                          size: 14, color: AppColors.medShelf),
                      SizedBox(width: 4),
                      Text('Add box',
                          style: TextStyle(
                              color: AppColors.medShelf,
                              fontSize: 12,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          for (int i = 0; i < med.batches.length; i++) ...[
            if (i > 0) const Divider(height: 16),
            _BatchRow(
              index: i,
              batch: med.batches[i],
              canRemove: med.batches.length > 1,
              onRemove: () => onRemoveBatch(med.batches[i].id),
            ),
          ],
        ],
      ),
    );
  }
}

class _BatchRow extends StatelessWidget {
  final int index;
  final MedicationBatch batch;
  final bool canRemove;
  final VoidCallback onRemove;

  const _BatchRow({
    required this.index,
    required this.batch,
    required this.canRemove,
    required this.onRemove,
  });

  Color get _color {
    final days = batch.daysUntilExpiry;
    if (days < 0) return AppColors.error;
    if (days <= 7) return AppColors.error;
    if (days <= 30) return AppColors.warning;
    return AppColors.success;
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: _color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Box ${index + 1}',
                style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 2),
              Text(
                'Exp: ${DateHelpers.formatDisplay(batch.expiryDate)}  •  Qty: ${batch.quantity}',
                style: TextStyle(color: _color, fontSize: 12),
              ),
            ],
          ),
        ),
        if (canRemove)
          GestureDetector(
            onTap: onRemove,
            child: Padding(
              padding: const EdgeInsets.only(left: 8),
              child: Icon(Icons.close_rounded,
                  size: 18, color: AppColors.textSecondary),
            ),
          ),
      ],
    );
  }
}

// ─── Add batch bottom sheet ───────────────────────────────────────────────────

class _AddBatchSheet extends StatefulWidget {
  const _AddBatchSheet();

  @override
  State<_AddBatchSheet> createState() => _AddBatchSheetState();
}

class _AddBatchSheetState extends State<_AddBatchSheet> {
  DateTime? _expiry;
  final _qtyCtrl = TextEditingController(text: '1');

  @override
  void dispose() {
    _qtyCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _expiry ?? DateTime(now.year + 1, now.month),
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 20),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(context)
              .colorScheme
              .copyWith(primary: AppColors.medShelf),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _expiry = picked);
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('Add Another Box',
                  style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 17,
                      fontWeight: FontWeight.w700)),
              const Spacer(),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: const Icon(Icons.close_rounded,
                    color: AppColors.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Text('Expiry Date *',
              style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: _pickDate,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today_rounded,
                      color: AppColors.medShelf, size: 18),
                  const SizedBox(width: 10),
                  Text(
                    _expiry != null
                        ? DateFormat('dd MMMM yyyy').format(_expiry!)
                        : 'Select expiry date',
                    style: TextStyle(
                      color: _expiry != null
                          ? AppColors.textPrimary
                          : AppColors.textDisabled,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text('Quantity',
              style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          TextFormField(
            controller: _qtyCtrl,
            keyboardType: TextInputType.number,
            style: const TextStyle(color: AppColors.textPrimary),
            decoration: const InputDecoration(hintText: 'e.g. 30'),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _expiry == null
                  ? null
                  : () {
                      final batch = MedicationBatch(
                        id: const Uuid().v4(),
                        expiryDate: _expiry!,
                        quantity: int.tryParse(_qtyCtrl.text.trim()) ?? 1,
                      );
                      Navigator.pop(context, batch);
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.medShelf,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Add Box',
                  style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Detail card ──────────────────────────────────────────────────────────────

class _DetailCard extends StatelessWidget {
  final MedicationModel med;

  const _DetailCard({required this.med});

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
          const Text('Details',
              style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          if (med.activeSubstance != null)
            _Row('Active Substance', med.activeSubstance!),
          if (med.manufacturer != null) _Row('Manufacturer', med.manufacturer!),
          _Row('Category', med.category.label),
          _Row('Added', DateHelpers.formatDisplay(med.createdAt)),
          if (med.notes != null) ...[
            const Divider(height: 20),
            const Text('Notes',
                style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(med.notes!,
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
            width: 140,
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
