import 'package:flutter/material.dart';
import 'package:medshelf/core/theme/app_colors.dart';
import 'package:medshelf/core/utils/date_helpers.dart';
import 'package:medshelf/features/med_shelf/models/medication_model.dart';

class MedicationCard extends StatelessWidget {
  final MedicationModel medication;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const MedicationCard({
    super.key,
    required this.medication,
    this.onTap,
    this.onDelete,
  });

  Color get _statusColor {
    if (medication.isExpired) return AppColors.error;
    if (medication.daysUntilExpiry <= 7) return AppColors.error;
    if (medication.daysUntilExpiry <= 30) return AppColors.warning;
    return AppColors.success;
  }

  Color get _statusBg {
    if (medication.isExpired) return AppColors.errorLight;
    if (medication.daysUntilExpiry <= 7) return AppColors.errorLight;
    if (medication.daysUntilExpiry <= 30) return AppColors.warningLight;
    return AppColors.successLight;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: AppColors.shadow,
              blurRadius: 12,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            // Status bar at top
            Container(
              height: 4,
              decoration: BoxDecoration(
                color: _statusColor,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(16)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  // Icon
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: AppColors.medShelfLight,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: medication.imageUrl != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              medication.imageUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const Icon(
                                Icons.medication_rounded,
                                color: AppColors.medShelf,
                                size: 26,
                              ),
                            ),
                          )
                        : const Icon(
                            Icons.medication_rounded,
                            color: AppColors.medShelf,
                            size: 26,
                          ),
                  ),
                  const SizedBox(width: 12),
                  // Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          medication.name,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (medication.dosage != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            medication.dosage!,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            _ExpiryChip(
                              label: DateHelpers.expiryLabel(
                                  medication.expiryDate),
                              color: _statusColor,
                              background: _statusBg,
                            ),
                            const SizedBox(width: 8),
                            _QuantityChip(quantity: medication.quantity),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Arrow
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.textSecondary,
                    size: 20,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExpiryChip extends StatelessWidget {
  final String label;
  final Color color;
  final Color background;

  const _ExpiryChip({
    required this.label,
    required this.color,
    required this.background,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.schedule_rounded, size: 11, color: color),
          const SizedBox(width: 3),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuantityChip extends StatelessWidget {
  final int quantity;

  const _QuantityChip({required this.quantity});

  @override
  Widget build(BuildContext context) {
    final lowStock = quantity <= 5;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: lowStock ? AppColors.warningLight : AppColors.medShelfLight,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.inventory_2_outlined,
            size: 11,
            color: lowStock ? AppColors.warning : AppColors.medShelf,
          ),
          const SizedBox(width: 3),
          Text(
            'Qty: $quantity',
            style: TextStyle(
              color: lowStock ? AppColors.warning : AppColors.medShelf,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
