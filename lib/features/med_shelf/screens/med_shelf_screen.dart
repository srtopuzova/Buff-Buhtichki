import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:medshelf/core/theme/app_colors.dart';
import 'package:medshelf/features/auth/providers/auth_provider.dart';
import 'package:medshelf/features/med_shelf/models/medication_model.dart';
import 'package:medshelf/features/med_shelf/providers/medication_provider.dart';
import 'package:medshelf/features/med_shelf/widgets/medication_card.dart';
import 'package:medshelf/shared/widgets/empty_state_widget.dart';

class MedShelfScreen extends StatefulWidget {
  const MedShelfScreen({super.key});

  @override
  State<MedShelfScreen> createState() => _MedShelfScreenState();
}

class _MedShelfScreenState extends State<MedShelfScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final uid = context.read<AuthProvider>().userModel?.uid;
      if (uid != null) {
        context.read<MedicationProvider>().initialize(uid);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<MedicationModel> _filter(List<MedicationModel> list) {
    if (_searchQuery.isEmpty) return list;
    final q = _searchQuery.toLowerCase();
    return list
        .where((m) =>
            m.name.toLowerCase().contains(q) ||
            (m.activeSubstance?.toLowerCase().contains(q) ?? false) ||
            (m.manufacturer?.toLowerCase().contains(q) ?? false))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MedicationProvider>();
    final all = _filter(provider.medications);
    final expiringSoon = _filter(provider.expiringSoon);
    final expired = _filter(provider.expired);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar(
            expandedHeight: 160,
            floating: false,
            pinned: true,
            backgroundColor: AppColors.medShelf,
            scrolledUnderElevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(gradient: AppColors.medShelfGradient),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 60),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'MedShelf',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${provider.medications.length} medication${provider.medications.length == 1 ? '' : 's'}',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(48),
              child: ColoredBox(
                color: AppColors.medShelf,
                child: TabBar(
                  controller: _tabController,
                  indicatorColor: Colors.white,
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.white60,
                  labelStyle: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600),
                  tabs: [
                    Tab(text: 'All (${all.length})'),
                    Tab(text: 'Soon (${expiringSoon.length})'),
                    Tab(text: 'Expired (${expired.length})'),
                  ],
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
              child: TextField(
                onChanged: (v) => setState(() => _searchQuery = v),
                decoration: InputDecoration(
                  hintText: 'Search medications...',
                  prefixIcon: const Icon(Icons.search_rounded,
                      color: AppColors.textSecondary, size: 20),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded,
                              color: AppColors.textSecondary, size: 18),
                          onPressed: () => setState(() => _searchQuery = ''),
                        )
                      : null,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabController,
          children: [
            _MedList(medications: all),
            _MedList(
                medications: expiringSoon,
                emptyMessage: 'No medications expiring soon'),
            _MedList(
                medications: expired, emptyMessage: 'No expired medications'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/home/med-shelf/add'),
        backgroundColor: AppColors.medShelf,
        child: const Icon(Icons.add_rounded, color: Colors.white),
      ),
    );
  }
}

class _MedList extends StatelessWidget {
  final List<MedicationModel> medications;
  final String emptyMessage;

  const _MedList({
    required this.medications,
    this.emptyMessage = 'No medications yet',
  });

  @override
  Widget build(BuildContext context) {
    if (medications.isEmpty) {
      return EmptyStateWidget(
        icon: Icons.medication_rounded,
        title: emptyMessage,
        subtitle: 'Tap the + button to add a medication',
        iconColor: AppColors.medShelf,
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      itemCount: medications.length,
      itemBuilder: (context, i) {
        final med = medications[i];
        return MedicationCard(
          medication: med,
          onTap: () => context.push('/home/med-shelf/${med.id}'),
        );
      },
    );
  }
}
