
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final adminEmail =
        FirebaseAuth.instance.currentUser?.email ?? 'Admin';

    return Scaffold(
      appBar: AppBar(
        title: const Text('SARTHI Admin'),
        actions: [
          IconButton(
            tooltip: 'Sign out',
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();

              if (!context.mounted) return;

              Navigator.of(context).popUntil(
                (route) => route.isFirst,
              );
            },
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Dashboard',
                  style: Theme.of(context)
                      .textTheme
                      .headlineMedium,
                ),
                const SizedBox(height: 8),
                Text('Welcome, $adminEmail'),
                const SizedBox(height: 28),

                LayoutBuilder(
                  builder: (context, constraints) {
                    final columns =
                        constraints.maxWidth >= 800 ? 3 : 1;

                    return GridView.count(
                      crossAxisCount: columns,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      shrinkWrap: true,
                      physics:
                          const NeverScrollableScrollPhysics(),
                      childAspectRatio:
                          columns == 1 ? 2.5 : 1.6,
                      children: const [
                        _DashboardCard(
                          icon: Icons.people_outline,
                          title: 'Students',
                          subtitle: 'Student management',
                        ),
                        _DashboardCard(
                          icon: Icons.electric_car_outlined,
                          title: 'EV Carts',
                          subtitle: 'Fleet management',
                        ),
                        _DashboardCard(
                          icon: Icons.directions_bus_outlined,
                          title: 'Buses',
                          subtitle: 'Bus and route management',
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DashboardCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _DashboardCard({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 36),
            const SizedBox(height: 12),
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
