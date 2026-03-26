import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:medshelf/core/theme/app_colors.dart';
import 'package:medshelf/features/pharmacy/models/pharmacy_model.dart';
import 'package:medshelf/shared/services/location_service.dart';

class PharmacyCard extends StatelessWidget {
  final PharmacyModel pharmacy;
  final int index;

  const PharmacyCard({
    super.key,
    required this.pharmacy,
    required this.index,
  });

  Future<void> _call() async {
    final uri = Uri(scheme: 'tel', path: pharmacy.phone);
    try {
      await launchUrl(uri);
    } catch (_) {}
  }

  Future<void> _openMaps() async {
    final uri = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=${pharmacy.latitude},${pharmacy.longitude}');
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final distLabel = pharmacy.distanceMeters != null
        ? LocationService().formatDistance(pharmacy.distanceMeters!)
        : null;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
              color: AppColors.shadow, blurRadius: 12, offset: Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          Container(
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.pharmacy,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Rank circle
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.pharmacyLight,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '${index + 1}',
                          style: const TextStyle(
                            color: AppColors.pharmacy,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            pharmacy.name,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            pharmacy.address,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    if (distLabel != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.pharmacyLight,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          distLabel,
                          style: const TextStyle(
                            color: AppColors.pharmacy,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                const Divider(height: 1),
                const SizedBox(height: 10),
                Row(
                  children: [
                    // Hours
                    const Icon(Icons.access_time_rounded,
                        size: 14, color: AppColors.textSecondary),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        pharmacy.isOpen24h
                            ? 'Open 24 hours'
                            : pharmacy.openHours ?? 'Hours not available',
                        style: TextStyle(
                          color: pharmacy.isOpen24h
                              ? AppColors.success
                              : AppColors.textSecondary,
                          fontSize: 12,
                          fontWeight: pharmacy.isOpen24h
                              ? FontWeight.w600
                              : FontWeight.w400,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Call button
                    _ActionButton(
                      icon: Icons.phone_rounded,
                      label: 'Call',
                      color: AppColors.success,
                      onTap: _call,
                    ),
                    const SizedBox(width: 8),
                    // Maps button
                    _ActionButton(
                      icon: Icons.directions_rounded,
                      label: 'Directions',
                      color: AppColors.pharmacy,
                      onTap: _openMaps,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(label,
                style: TextStyle(
                    color: color, fontSize: 12, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}
