import 'package:flutter/material.dart';
import '../services/firebase_service.dart';
import '../widgets/responsive_scaffold.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  // Reusable PKR Currency Formatter
  String _formatPKR(double amount) {
    final formatStr = amount.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        );
    return 'Rs. $formatStr';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    final isWide = size.width >= 700;
    final firebaseService = FirebaseService();

    return ResponsiveScaffold(
      title: 'Dashboard',
      currentIndex: 0,
      body: StreamBuilder<DashboardStats>(
        stream: firebaseService.getDashboardStats(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24.0),
                child: ShimmerLoadingGrid(),
              ),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error loading dashboard: ${snapshot.error}',
                style: const TextStyle(color: Colors.red),
              ),
            );
          }

          final stats = snapshot.data ??
              DashboardStats(
                totalClients: 0,
                activeClients: 0,
                expiredClients: 0,
                totalPendingDues: 0,
              );

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Lyallpur Broadband Portal',
                  style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.tertiary,
                        fontWeight: FontWeight.w500,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Real-Time Status Console',
                  style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                ),
                const SizedBox(height: 32),

                // Responsive Stat Cards Grid
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: isWide ? 4 : 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: isWide ? 1.45 : 1.15,
                  children: [
                    _buildStatCard(
                      context: context,
                      title: 'Total Clients',
                      value: stats.totalClients.toString(),
                      icon: Icons.people,
                      iconColor: theme.colorScheme.tertiary,
                    ),
                    _buildStatCard(
                      context: context,
                      title: 'Active Clients',
                      value: stats.activeClients.toString(),
                      icon: Icons.wifi,
                      iconColor: Colors.greenAccent,
                    ),
                    _buildStatCard(
                      context: context,
                      title: 'Expired Clients',
                      value: stats.expiredClients.toString(),
                      icon: Icons.wifi_off,
                      iconColor: Colors.orangeAccent,
                    ),
                    _buildStatCard(
                      context: context,
                      title: 'Total Pending Dues',
                      value: _formatPKR(stats.totalPendingDues),
                      icon: Icons.account_balance_wallet_outlined,
                      iconColor: Colors.pinkAccent,
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatCard({
    required BuildContext context,
    required String title,
    required String value,
    required IconData icon,
    required Color iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: const Color(0xFF161B22), // Dark Card Background
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF30363D), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: iconColor, size: 24),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: -0.5,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[400],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionCard(
    BuildContext context,
    String label,
    IconData icon,
    String routeName,
  ) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: () => Navigator.pushNamed(context, routeName),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        decoration: BoxDecoration(
          color: const Color(0xFF161B22),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF30363D), width: 1),
        ),
        child: Row(
          children: [
            Icon(icon, color: theme.colorScheme.tertiary),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 12, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}

// Shimmer skeleton loading effect to replace third-party dependencies
class ShimmerLoadingGrid extends StatefulWidget {
  const ShimmerLoadingGrid({super.key});

  @override
  State<ShimmerLoadingGrid> createState() => _ShimmerLoadingGridState();
}

class _ShimmerLoadingGridState extends State<ShimmerLoadingGrid>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 700;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(
          opacity: 0.3 + (_controller.value * 0.4),
          child: child,
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(height: 20, width: 220, color: Colors.white10),
          const SizedBox(height: 12),
          Container(height: 32, width: 340, color: Colors.white10),
          const SizedBox(height: 40),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: isWide ? 4 : 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: isWide ? 1.45 : 1.15,
            children: List.generate(4, (index) => _buildShimmerCard()),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerCard() {
    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: const Color(0xFF161B22),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF30363D), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            height: 36,
            width: 36,
            decoration: BoxDecoration(
              color: Colors.white10,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          const SizedBox(height: 12),
          Container(height: 24, width: 70, color: Colors.white10),
          Container(height: 12, width: 100, color: Colors.white10),
        ],
      ),
    );
  }
}
