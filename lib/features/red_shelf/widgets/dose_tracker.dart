import 'package:flutter/material.dart';
import 'package:medshelf/core/theme/app_colors.dart';
import 'package:medshelf/features/red_shelf/models/prescription_model.dart';

class _WeekSlot {
  final DateTime date;
  final DoseRecord? record;
  const _WeekSlot(this.date, this.record);
}

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

  // One slot per day for Mon–Sun of the current week.
  // Days without a record get a null record (shown as empty dot).
  List<_WeekSlot> _currentWeekSlots() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    // weekday: 1=Mon … 7=Sun
    final monday = today.subtract(Duration(days: today.weekday - 1));

    return List.generate(7, (i) {
      final day = monday.add(Duration(days: i));
      final dayRecords = prescription.doseRecords.where((d) =>
          d.timestamp.year == day.year &&
          d.timestamp.month == day.month &&
          d.timestamp.day == day.day);
      final record = dayRecords.isEmpty
          ? null
          : dayRecords.reduce(
              (a, b) => a.timestamp.isAfter(b.timestamp) ? a : b);
      return _WeekSlot(day, record);
    });
  }

  @override
  Widget build(BuildContext context) {
    final recorded = _hasRecordedToday;
    final taken = _takenToday;
    final weekSlots = _currentWeekSlots();

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
          // Weekly history dots — always Mon through Sun
          const SizedBox(height: 14),
          const Text('This week',
              style: TextStyle(
                  color: AppColors.textSecondary, fontSize: 12)),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: weekSlots.map((s) => _DayDot(slot: s)).toList(),
          ),
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
  final _WeekSlot slot;

  const _DayDot({required this.slot});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final isFuture = slot.date.isAfter(today);
    final record = slot.record;

    final Color bgColor;
    final Widget? dotChild;

    if (record != null) {
      bgColor = record.taken ? AppColors.success : AppColors.errorLight;
      dotChild = Icon(
        record.taken ? Icons.check_rounded : Icons.close_rounded,
        size: 16,
        color: record.taken ? Colors.white : AppColors.error,
      );
    } else {
      bgColor = AppColors.divider;
      dotChild = null;
    }

    return Opacity(
      opacity: isFuture && record == null ? 0.4 : 1.0,
      child: Column(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: bgColor,
              shape: BoxShape.circle,
            ),
            child: dotChild,
          ),
          const SizedBox(height: 4),
          Text(
            _dayLabel(slot.date),
            style: const TextStyle(
                color: AppColors.textSecondary, fontSize: 10),
          ),
        ],
      ),
    );
  }

  String _dayLabel(DateTime dt) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[dt.weekday - 1];
  }
}
