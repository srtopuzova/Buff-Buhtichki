import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:medshelf/core/theme/app_colors.dart';
import 'package:medshelf/features/pharmacy/providers/pharmacy_provider.dart';
import 'package:medshelf/features/pharmacy/widgets/pharmacy_card.dart';
import 'package:medshelf/shared/widgets/empty_state_widget.dart';

class PharmacyScreen extends StatefulWidget {
  const PharmacyScreen({super.key});

  @override
  State<PharmacyScreen> createState() => _PharmacyScreenState();
}

class _PharmacyScreenState extends State<PharmacyScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PharmacyProvider>().loadNearbyPharmacies();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PharmacyProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar(
            expandedHeight: 160,
            floating: false,
            pinned: true,
            backgroundColor: AppColors.pharmacy,
            scrolledUnderElevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(gradient: AppColors.pharmacyGradient),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Nearby Pharmacies',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 26,
                              fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          provider.hasLocation
                              ? '10 nearest pharmacies'
                              : 'Enable location for distance info',
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 14),
                        ),
                        const Spacer(),
                        Row(
                          children: [
                            const Icon(Icons.location_on_rounded,
                                color: Colors.white70, size: 14),
                            const SizedBox(width: 4),
                            Text(
                              provider.hasLocation
                                  ? 'Sorted by distance'
                                  : 'Location unavailable',
                              style: const TextStyle(
                                  color: Colors.white70, fontSize: 12),
                            ),
                            const Spacer(),
                            GestureDetector(
                              onTap: provider.isLoading
                                  ? null
                                  : () => provider.loadNearbyPharmacies(),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.refresh_rounded,
                                        color: Colors.white, size: 14),
                                    const SizedBox(width: 4),
                                    const Text('Refresh',
                                        style: TextStyle(
                                            color: Colors.white, fontSize: 12)),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
        body: _buildBody(provider),
      ),
    );
  }

  Widget _buildBody(PharmacyProvider provider) {
    if (provider.isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.pharmacy),
        ),
      );
    }

    if (provider.errorMessage != null) {
      return EmptyStateWidget(
        icon: Icons.error_outline_rounded,
        title: 'Could not load pharmacies',
        subtitle: provider.errorMessage,
        actionLabel: 'Try Again',
        onAction: () => provider.loadNearbyPharmacies(),
        iconColor: AppColors.error,
      );
    }

    if (provider.pharmacies.isEmpty) {
      return EmptyStateWidget(
        icon: Icons.local_pharmacy_rounded,
        title: 'No pharmacies found',
        subtitle: 'Enable location permissions and try again',
        actionLabel: 'Refresh',
        onAction: () => provider.loadNearbyPharmacies(),
        iconColor: AppColors.pharmacy,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      itemCount: provider.pharmacies.length,
      itemBuilder: (context, i) => PharmacyCard(
        pharmacy: provider.pharmacies[i],
        index: i,
      ),
    );
  }
}
