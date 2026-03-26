import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
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
                  // Status card
                  _StatusCard(
                    med: med,
                    statusColor: statusColor,
                    daysLeft: daysLeft,
                  ),
                  const SizedBox(height: 16),
                  // Quantity card
                  _QuantityCard(
                    medication: med,
                    onChanged: (q) => context
                        .read<MedicationProvider>()
                        .updateQuantity(med.id, q),
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
}

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
                  'Expiry: ${DateHelpers.formatDisplay(med.expiryDate)}',
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

class _QuantityCard extends StatefulWidget {
  final MedicationModel medication;
  final ValueChanged<int> onChanged;

  const _QuantityCard({required this.medication, required this.onChanged});

  @override
  State<_QuantityCard> createState() => _QuantityCardState();
}

class _QuantityCardState extends State<_QuantityCard> {
  late int _quantity;

  @override
  void initState() {
    super.initState();
    _quantity = widget.medication.quantity;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          const Icon(Icons.inventory_2_rounded,
              color: AppColors.medShelf, size: 22),
          const SizedBox(width: 12),
          const Expanded(
            child: Text('Quantity',
                style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w600)),
          ),
          _CounterButton(
            icon: Icons.remove_rounded,
            onTap: _quantity > 0
                ? () {
                    setState(() => _quantity--);
                    widget.onChanged(_quantity);
                  }
                : null,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              '$_quantity',
              style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w700),
            ),
          ),
          _CounterButton(
            icon: Icons.add_rounded,
            onTap: () {
              setState(() => _quantity++);
              widget.onChanged(_quantity);
            },
          ),
        ],
      ),
    );
  }
}

class _CounterButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _CounterButton({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: onTap != null ? AppColors.medShelfLight : AppColors.divider,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          size: 18,
          color: onTap != null ? AppColors.medShelf : AppColors.textDisabled,
        ),
      ),
    );
  }
}

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
