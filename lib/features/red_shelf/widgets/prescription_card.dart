import 'package:flutter/material.dart';
import 'package:medshelf/core/theme/app_colors.dart';
import 'package:medshelf/features/red_shelf/models/prescription_model.dart';

class PrescriptionCard extends StatelessWidget {
  final PrescriptionModel prescription;
  final VoidCallback? onTap;
  final VoidCallback? onPickedUp;

  const PrescriptionCard({
    super.key,
    required this.prescription,
    this.onTap,
    this.onPickedUp,
  });

  Color get _statusColor {
    switch (prescription.status) {
      case PrescriptionStatus.pending:
        return AppColors.warning;
      case PrescriptionStatus.active:
        return AppColors.redShelf;
      case PrescriptionStatus.completed:
        return AppColors.success;
      case PrescriptionStatus.cancelled:
        return AppColors.textSecondary;
    }
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
                offset: Offset(0, 4)),
          ],
        ),
        child: Column(
          children: [
            Container(
              height: 4,
              decoration: BoxDecoration(
                color: _statusColor,
                borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: AppColors.redShelfLight,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.description_rounded,
                            color: AppColors.redShelf, size: 24),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              prescription.medicationName,
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (prescription.dosage != null) ...[
                              const SizedBox(height: 2),
                              Text(prescription.dosage!,
                                  style: const TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 12)),
                            ],
                          ],
                        ),
                      ),
                      _StatusBadge(
                          label: prescription.status.label,
                          color: _statusColor),
                    ],
                  ),
                  if (prescription.frequency != null ||
                      prescription.doctorName != null) ...[
                    const SizedBox(height: 10),
                    const Divider(height: 1),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        if (prescription.frequency != null) ...[
                          const Icon(Icons.access_time_rounded,
                              size: 13, color: AppColors.textSecondary),
                          const SizedBox(width: 4),
                          Text(prescription.frequency!,
                              style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 12)),
                          const SizedBox(width: 12),
                        ],
                        if (prescription.doctorName != null) ...[
                          const Icon(Icons.person_outline_rounded,
                              size: 13, color: AppColors.textSecondary),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              'Dr. ${prescription.doctorName}',
                              style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 12),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                  if (prescription.isPending && onPickedUp != null) ...[
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: onPickedUp,
                        icon: const Icon(Icons.check_circle_outline_rounded,
                            size: 16),
                        label: const Text('Mark as Picked Up'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.success,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
            color: color, fontSize: 11, fontWeight: FontWeight.w600),
      ),
    );
  }
}