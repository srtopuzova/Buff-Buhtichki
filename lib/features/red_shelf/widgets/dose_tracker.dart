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

  bool get _hasRecordedToday {
    final today = DateTime.now();
    return prescription.doseRecords.any((d) =>
        d.timestamp.year == today.year &&
        d.timestamp.month == today.month &&
        d.timestamp.day == today.day);
  }

  bool get _takenToday {
    final today = DateTime.now();
    return prescription.doseRecords.any((d) =>
        d.taken &&
        d.timestamp.year == today.year &&
        d.timestamp.month == today.month &&
        d.timestamp.day == today.day);
  }

  // One entry per day for the last 7 days (most recent record wins)
  List<DoseRecord> _lastSevenDays() {
    final now = DateTime.now();
    final result = <DoseRecord>[];
    for (int i = 6; i >= 0; i--) {
      final day = DateTime(now.year, now.month, now.day - i);
      final dayRecords = prescription.doseRecords.where((d) =>
          d.timestamp.year == day.year &&
          d.timestamp.month == day.month &&
          d.timestamp.day == day.day);
      if (dayRecords.isNotEmpty) {
        // Last record of the day wins
        result.add(dayRecords.reduce(
            (a, b) => a.timestamp.isAfter(b.timestamp) ? a : b));
      }
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final recorded = _hasRecordedToday;
    final taken = _takenToday;
    final weekDots = _lastSevenDays();

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
              if (recorded)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: taken
                        ? AppColors.success.withValues(alpha: 0.1)
                        : AppColors.errorLight,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        taken ? Icons.check_rounded : Icons.close_rounded,
                        size: 12,
                        color: taken ? AppColors.success : AppColors.error,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        taken ? 'Taken today' : 'Skipped today',
                        style: TextStyle(
                            color:
                                taken ? AppColors.success : AppColors.error,
                            fontSize: 12,
                            fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          // Weekly history dots
          if (weekDots.isNotEmpty) ...[
            const SizedBox(height: 14),
            const Text('Last 7 days',
                style: TextStyle(
                    color: AppColors.textSecondary, fontSize: 12)),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: weekDots.map((d) => _DayDot(record: d)).toList(),
            ),
          ],
          // Action buttons — only if not yet recorded today
          if (prescription.isActive && !recorded) ...[
            const SizedBox(height: 14),
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
}

class _DayDot extends StatelessWidget {
  final DoseRecord record;

  const _DayDot({required this.record});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: record.taken ? AppColors.success : AppColors.errorLight,
            shape: BoxShape.circle,
          ),
          child: Icon(
            record.taken ? Icons.check_rounded : Icons.close_rounded,
            size: 16,
            color: record.taken ? Colors.white : AppColors.error,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          _dayLabel(record.timestamp),
          style: const TextStyle(
              color: AppColors.textSecondary, fontSize: 10),
        ),
      ],
    );
  }

  String _dayLabel(DateTime dt) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[dt.weekday - 1];
  }
}
