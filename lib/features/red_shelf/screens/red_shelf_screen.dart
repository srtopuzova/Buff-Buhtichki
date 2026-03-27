import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:medshelf/core/theme/app_colors.dart';
import 'package:medshelf/features/auth/providers/auth_provider.dart';
import 'package:medshelf/features/red_shelf/models/prescription_model.dart';
import 'package:medshelf/features/red_shelf/providers/prescription_provider.dart';
import 'package:medshelf/features/red_shelf/widgets/prescription_card.dart';
import 'package:medshelf/shared/widgets/empty_state_widget.dart';

class RedShelfScreen extends StatefulWidget {
  const RedShelfScreen({super.key});

  @override
  State<RedShelfScreen> createState() => _RedShelfScreenState();
}

class _RedShelfScreenState extends State<RedShelfScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final uid = context.read<AuthProvider>().userModel?.uid;
      if (uid != null) {
        context.read<PrescriptionProvider>().initialize(uid);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PrescriptionProvider>();
    final pending = provider.pending;
    final active = provider.active;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar(
            expandedHeight: 160,
            floating: false,
            pinned: true,
            backgroundColor: AppColors.redShelf,
            scrolledUnderElevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration:
                    BoxDecoration(gradient: AppColors.redShelfGradient),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 60),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'RedShelf',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 26,
                              fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${provider.prescriptions.length} prescription${provider.prescriptions.length == 1 ? '' : 's'}',
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 14),
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
                color: AppColors.redShelf,
                child: TabBar(
                  controller: _tabController,
                  indicatorColor: Colors.white,
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.white60,
                  labelStyle: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600),
                  tabs: [
                    Tab(text: 'Active (${active.length})'),
                    Tab(text: 'Pending (${pending.length})'),
                  ],
                ),
              ),
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabController,
          children: [
            _RxList(
              prescriptions: active,
              emptyMessage: 'No active prescriptions',
              emptySubtitle: 'Scan a prescription to get started',
              onPickedUp: null,
            ),
            _RxList(
              prescriptions: pending,
              emptyMessage: 'No pending prescriptions',
              emptySubtitle: 'All prescriptions have been picked up',
              onPickedUp: (id) =>
                  context.read<PrescriptionProvider>().markPickedUp(id),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/home/red-shelf/add'),
        backgroundColor: AppColors.redShelf,
        child: const Icon(Icons.add_rounded, color: Colors.white),
      ),
    );
  }
}

class _RxList extends StatelessWidget {
  final List<PrescriptionModel> prescriptions;
  final String emptyMessage;
  final String emptySubtitle;
  final Future<bool> Function(String id)? onPickedUp;

  const _RxList({
    required this.prescriptions,
    required this.emptyMessage,
    required this.emptySubtitle,
    required this.onPickedUp,
  });

  @override
  Widget build(BuildContext context) {
    if (prescriptions.isEmpty) {
      return EmptyStateWidget(
        icon: Icons.description_rounded,
        title: emptyMessage,
        subtitle: emptySubtitle,
        iconColor: AppColors.redShelf,
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
      itemCount: prescriptions.length,
      itemBuilder: (context, i) {
        final rx = prescriptions[i];
        return PrescriptionCard(
          prescription: rx,
          onTap: () =>
              context.push('/home/red-shelf/${rx.id}'),
          onPickedUp: onPickedUp != null
              ? () => onPickedUp!(rx.id)
              : null,
        );
      },
    );
  }
}