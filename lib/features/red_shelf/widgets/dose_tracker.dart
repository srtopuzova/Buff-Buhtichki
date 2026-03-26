import 'package:flutter/material.dart';
import 'package:medshelf/core/theme/app_colors.dart';
import 'package:medshelf/features/red_shelf/models/prescription_model.dart';

class DoseTracker extends StatelessWidget {
  final PrescriptionModel prescription;
  final VoidCallback onTaken;
  final VoidCallback onSkipped;

  const DoseTracker({
    super.key,
    required this.prescription,
    required this.onTaken,
    required this.onSkipped,
  });

  @override
  Widget build(BuildContext context) {
    final todayDoses = prescription.dosesToday;
    final recentDoses = _recentDoses(7);

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
              const Icon(Icons.medication_liquid_rounded,
                  color: AppColors.redShelf, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Dose Tracker',
                style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w700),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.redShelfLight,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$todayDoses dose${todayDoses == 1 ? '' : 's'} today',
                  style: const TextStyle(
                      color: AppColors.redShelf,
                      fontSize: 12,
                      fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Weekly history
          if (recentDoses.isNotEmpty) ...[
            const Text('Last 7 days',
                style: TextStyle(
                    color: AppColors.textSecondary, fontSize: 12)),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: recentDoses
                  .map((d) => _DayDot(record: d))
                  .toList(),
            ),
            const SizedBox(height: 14),
          ],
          // Action buttons
          if (prescription.isActive) ...[
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onTaken,
                    icon: const Icon(Icons.check_rounded, size: 16),
                    label: const Text('Taken'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onSkipped,
                    icon: const Icon(Icons.close_rounded, size: 16),
                    label: const Text('Skipped'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textSecondary,
                      side: const BorderSide(color: AppColors.border),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  List<DoseRecord> _recentDoses(int days) {
    final cutoff =
        DateTime.now().subtract(Duration(days: days));
    return prescription.doseRecords
        .where((d) => d.timestamp.isAfter(cutoff))
        .toList()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
  }
}

class _DayDot extends StatelessWidget {
  final DoseRecord record;

  const _DayDot({required this.record});

  @override
  Widget build(BuildContext context) {
    final dayLabel = _dayLabel(record.timestamp);
    return Column(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: record.taken
                ? AppColors.success
                : AppColors.errorLight,
            shape: BoxShape.circle,
          ),
          child: Icon(
            record.taken ? Icons.check_rounded : Icons.close_rounded,
            size: 16,
            color: record.taken ? Colors.white : AppColors.error,
          ),
        ),
        const SizedBox(height: 4),
        Text(dayLabel,
            style: const TextStyle(
                color: AppColors.textSecondary, fontSize: 10)),
      ],
    );
  }

  String _dayLabel(DateTime dt) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[dt.weekday - 1];
  }
}