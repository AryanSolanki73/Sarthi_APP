import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../auth/admin_auth_service.dart';
import 'student_management_screen.dart';

const _green = Color(0xFF087F5B);
const _mint = Color(0xFFE7F6EF);
const _ink = Color(0xFF18231F);
const _muted = Color(0xFF7B8983);
const _line = Color(0xFFE7ECE9);
const _pageBackground = Color(0xFFF5F7F6);

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final _firestore = FirebaseFirestore.instance;
  late Future<_DashboardMetrics> _metrics;

  String get _adminEmail =>
      FirebaseAuth.instance.currentUser?.email ?? 'Admin';

  @override
  void initState() {
    super.initState();
    _metrics = _loadMetrics();
  }

  Future<int?> _safeCount(Query<Map<String, dynamic>> query) async {
    try {
      final result = await query.count().get();
      return result.count;
    } catch (_) {
      return null;
    }
  }

  Future<_DashboardMetrics> _loadMetrics() async {
    final counts = await Future.wait<int?>([
      _safeCount(
        _firestore.collection('users').where('role', isEqualTo: 'student'),
      ),
      _safeCount(
        _firestore.collection('buses').where('isActive', isEqualTo: true),
      ),
      _safeCount(
        _firestore.collection('rides').where(
          'status',
          whereIn: const ['pending', 'accepted', 'in_progress'],
        ),
      ),
      _safeCount(_firestore.collection('locations')),
    ]);

    return _DashboardMetrics(
      students: counts[0],
      activeBuses: counts[1],
      activeRides: counts[2],
      locationRecords: counts[3],
    );
  }

  Future<void> _signOut() async {
    await AdminAuthService().signOut();
    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
  }

  void _openStudents() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const StudentManagementScreen(),
      ),
    );
  }

  void _refresh() {
    setState(() => _metrics = _loadMetrics());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _pageBackground,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final showSidebar = constraints.maxWidth >= 1000;
          return Row(
            children: [
              if (showSidebar)
                _DashboardSidebar(
                  adminEmail: _adminEmail,
                  onOpenStudents: _openStudents,
                ),
              Expanded(
                child: Column(
                  children: [
                    _DashboardTopBar(
                      adminEmail: _adminEmail,
                      onSignOut: _signOut,
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(24, 28, 24, 36),
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 1420),
                            child: _DashboardContent(
                              adminEmail: _adminEmail,
                              metrics: _metrics,
                              onRefresh: _refresh,
                              onOpenStudents: _openStudents,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _DashboardMetrics {
  const _DashboardMetrics({
    required this.students,
    required this.activeBuses,
    required this.activeRides,
    required this.locationRecords,
  });

  final int? students;
  final int? activeBuses;
  final int? activeRides;
  final int? locationRecords;
}

class _DashboardSidebar extends StatelessWidget {
  const _DashboardSidebar({
    required this.adminEmail,
    required this.onOpenStudents,
  });

  final String adminEmail;
  final VoidCallback onOpenStudents;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 238,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(right: BorderSide(color: _line)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 25, 16, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _green,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const Icon(Icons.alt_route, color: Colors.white),
              ),
              const SizedBox(width: 11),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'SARTHI',
                    style: TextStyle(
                      color: _ink,
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    'TRANSIT CONTROL',
                    style: TextStyle(
                      color: _muted,
                      fontSize: 9,
                      letterSpacing: 1.2,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 34),
          const Padding(
            padding: EdgeInsets.only(left: 12, bottom: 10),
            child: Text(
              'WORKSPACE',
              style: TextStyle(
                color: _muted,
                fontSize: 10,
                letterSpacing: 1.3,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const _SidebarItem(
            icon: Icons.grid_view_rounded,
            label: 'Overview',
            selected: true,
          ),
          _SidebarItem(
            icon: Icons.people_outline,
            label: 'Students',
            onTap: onOpenStudents,
          ),
          const _SidebarItem(
            icon: Icons.electric_car_outlined,
            label: 'EV Cart Fleet',
            unavailable: true,
          ),
          const _SidebarItem(
            icon: Icons.directions_bus_outlined,
            label: 'Bus Schedules',
            unavailable: true,
          ),
          const _SidebarItem(
            icon: Icons.confirmation_number_outlined,
            label: 'Rides & Bookings',
            unavailable: true,
          ),
          const _SidebarItem(
            icon: Icons.badge_outlined,
            label: 'Drivers',
            unavailable: true,
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF7FAF8),
              border: Border.all(color: _line),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'OPERATING AREA',
                  style: TextStyle(
                    color: _muted,
                    fontSize: 9,
                    letterSpacing: 1,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 7),
                Text(
                  'IIT Ropar Campus',
                  style: TextStyle(
                    color: _ink,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Campus mobility services',
                  style: TextStyle(color: _muted, fontSize: 10),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Divider(color: _line),
          const SizedBox(height: 10),
          Row(
            children: [
              _AdminAvatar(email: adminEmail, size: 36),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  adminEmail,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _ink,
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  const _SidebarItem({
    required this.icon,
    required this.label,
    this.selected = false,
    this.unavailable = false,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final bool unavailable;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? _green : (unavailable ? _muted : _ink);
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Material(
        color: selected ? _mint : Colors.transparent,
        borderRadius: BorderRadius.circular(11),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(11),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Row(
              children: [
                Icon(icon, size: 18, color: color),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: color,
                      fontSize: 12,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ),
                if (unavailable)
                  const Text(
                    'Soon',
                    style: TextStyle(color: _muted, fontSize: 9),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DashboardTopBar extends StatelessWidget {
  const _DashboardTopBar({
    required this.adminEmail,
    required this.onSignOut,
  });

  final String adminEmail;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 70,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: _line)),
      ),
      child: Row(
        children: [
          const Text('Workspace  /  ', style: TextStyle(color: _muted)),
          const Text(
            'Overview',
            style: TextStyle(color: _ink, fontWeight: FontWeight.w700),
          ),
          const Spacer(),
          if (MediaQuery.sizeOf(context).width >= 620) ...[
            _AdminAvatar(email: adminEmail, size: 34),
            const SizedBox(width: 9),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 220),
              child: Text(
                adminEmail,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: _ink, fontSize: 12),
              ),
            ),
            const SizedBox(width: 12),
          ],
          IconButton(
            tooltip: 'Sign out',
            onPressed: onSignOut,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
    );
  }
}

class _DashboardContent extends StatelessWidget {
  const _DashboardContent({
    required this.adminEmail,
    required this.metrics,
    required this.onRefresh,
    required this.onOpenStudents,
  });

  final String adminEmail;
  final Future<_DashboardMetrics> metrics;
  final VoidCallback onRefresh;
  final VoidCallback onOpenStudents;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'CAMPUS OPERATIONS',
                    style: TextStyle(
                      color: _green,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.4,
                      fontSize: 10,
                    ),
                  ),
                  const SizedBox(height: 7),
                  const Text(
                    'Admin dashboard',
                    style: TextStyle(
                      color: _ink,
                      fontSize: 27,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.6,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Welcome, $adminEmail. Here is the current service overview.',
                    style: const TextStyle(color: _muted, fontSize: 12),
                  ),
                ],
              ),
            ),
            IconButton.filledTonal(
              tooltip: 'Refresh summary',
              onPressed: onRefresh,
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
        const SizedBox(height: 23),
        FutureBuilder<_DashboardMetrics>(
          future: metrics,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting &&
                !snapshot.hasData) {
              return const _MetricsLoading();
            }
            final data = snapshot.data;
            return _MetricsGrid(
              values: [
                _MetricValue(
                  label: 'Student accounts',
                  value: data?.students,
                  hint: 'users with student role',
                  icon: Icons.people_outline,
                ),
                _MetricValue(
                  label: 'Active bus records',
                  value: data?.activeBuses,
                  hint: 'buses marked active',
                  icon: Icons.directions_bus_outlined,
                  tint: const Color(0xFFEDF4FF),
                  iconColor: const Color(0xFF3266BB),
                ),
                _MetricValue(
                  label: 'Active ride requests',
                  value: data?.activeRides,
                  hint: 'pending, accepted, or in progress',
                  icon: Icons.route_outlined,
                  tint: const Color(0xFFFFF5DF),
                  iconColor: const Color(0xFFA96508),
                ),
                _MetricValue(
                  label: 'Location records',
                  value: data?.locationRecords,
                  hint: 'not a verified fleet count',
                  icon: Icons.location_on_outlined,
                  tint: const Color(0xFFF2EDFF),
                  iconColor: const Color(0xFF7C57BD),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 18),
        const _OperationsPanels(),
        const SizedBox(height: 22),
        _ManagementSection(onOpenStudents: onOpenStudents),
      ],
    );
  }
}

class _MetricValue {
  const _MetricValue({
    required this.label,
    required this.value,
    required this.hint,
    required this.icon,
    this.tint = _mint,
    this.iconColor = _green,
  });

  final String label;
  final int? value;
  final String hint;
  final IconData icon;
  final Color tint;
  final Color iconColor;
}

class _MetricsGrid extends StatelessWidget {
  const _MetricsGrid({required this.values});

  final List<_MetricValue> values;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 1050
            ? 4
            : constraints.maxWidth >= 560
                ? 2
                : 1;
        const gap = 13.0;
        final width = (constraints.maxWidth - gap * (columns - 1)) / columns;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: values
              .map((value) => SizedBox(
                    width: width,
                    child: _MetricCard(value: value),
                  ))
              .toList(),
        );
      },
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.value});

  final _MetricValue value;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 142),
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _line),
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Color(0x0B203B2B), blurRadius: 22, offset: Offset(0, 5)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  value.label,
                  style: const TextStyle(
                    color: _muted,
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                  ),
                ),
              ),
              Container(
                width: 35,
                height: 35,
                decoration: BoxDecoration(
                  color: value.tint,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(value.icon, color: value.iconColor, size: 18),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value.value?.toString() ?? 'Unavailable',
            style: TextStyle(
              color: value.value == null ? _muted : _ink,
              fontSize: value.value == null ? 17 : 26,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            value.value == null ? 'Could not load this count' : value.hint,
            style: const TextStyle(color: _muted, fontSize: 10),
          ),
        ],
      ),
    );
  }
}

class _MetricsLoading extends StatelessWidget {
  const _MetricsLoading();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 142,
      child: Center(child: CircularProgressIndicator(color: _green)),
    );
  }
}

class _OperationsPanels extends StatelessWidget {
  const _OperationsPanels();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final rides = const _RecentRidesPanel();
        final locations = const _LocationRecordsPanel();
        if (constraints.maxWidth < 850) {
          return Column(
            children: [rides, const SizedBox(height: 14), locations],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 3, child: rides),
            const SizedBox(width: 15),
            Expanded(flex: 2, child: locations),
          ],
        );
      },
    );
  }
}

class _DashboardPanel extends StatelessWidget {
  const _DashboardPanel({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _line),
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Color(0x08203B2B), blurRadius: 22, offset: Offset(0, 5)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(19, 17, 19, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: _ink,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  subtitle,
                  style: const TextStyle(color: _muted, fontSize: 10),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: _line),
          child,
        ],
      ),
    );
  }
}

class _RecentRidesPanel extends StatelessWidget {
  const _RecentRidesPanel();

  @override
  Widget build(BuildContext context) {
    final rides = FirebaseFirestore.instance
        .collection('rides')
        .orderBy('createdAt', descending: true)
        .limit(5)
        .snapshots();

    return _DashboardPanel(
      title: 'Recent ride requests',
      subtitle: 'Latest records from the rides collection',
      child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: rides,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const _PanelMessage(
              icon: Icons.info_outline,
              message: 'Recent ride activity is unavailable.',
            );
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const _PanelLoading();
          }
          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return const _PanelMessage(
              icon: Icons.inbox_outlined,
              message: 'No ride requests found.',
            );
          }
          return Column(
            children: docs.map((doc) {
              final data = doc.data();
              final pickup = (data['pickup'] ?? '').toString();
              final drop = (data['drop'] ?? '').toString();
              final name = (data['userName'] ?? 'Student').toString();
              final status = (data['status'] ?? 'unknown').toString();
              return ListTile(
                dense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 18),
                leading: const CircleAvatar(
                  radius: 17,
                  backgroundColor: _mint,
                  child: Icon(Icons.route, color: _green, size: 17),
                ),
                title: Text(
                  '$pickup  →  $drop',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _ink,
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                  ),
                ),
                subtitle: Text(
                  '$name · ${_formatTimestamp(data['createdAt'])}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: _muted, fontSize: 10),
                ),
                trailing: _StatusTag(label: status),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}

class _LocationRecordsPanel extends StatelessWidget {
  const _LocationRecordsPanel();

  @override
  Widget build(BuildContext context) {
    final locations = FirebaseFirestore.instance
        .collection('locations')
        .limit(5)
        .snapshots();

    return _DashboardPanel(
      title: 'Cart location records',
      subtitle: 'Stored timestamps shown; freshness is not validated',
      child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: locations,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const _PanelMessage(
              icon: Icons.location_off_outlined,
              message: 'Location records are unavailable.',
            );
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const _PanelLoading();
          }
          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return const _PanelMessage(
              icon: Icons.location_searching,
              message: 'No location records found.',
            );
          }
          return Column(
            children: docs.map((doc) {
              final data = doc.data();
              final name = (data['name'] ?? doc.id).toString();
              final status = (data['status'] ?? 'status unavailable').toString();
              final updated = _formatTimestamp(data['updatedAt']);
              return ListTile(
                dense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 18),
                leading: const CircleAvatar(
                  radius: 17,
                  backgroundColor: _mint,
                  child: Icon(Icons.electric_car_outlined, color: _green, size: 17),
                ),
                title: Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _ink,
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                  ),
                ),
                subtitle: Text(
                  'Status: $status · Updated: $updated',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: _muted, fontSize: 9),
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}

class _PanelLoading extends StatelessWidget {
  const _PanelLoading();

  @override
  Widget build(BuildContext context) => const SizedBox(
        height: 120,
        child: Center(
          child: CircularProgressIndicator(color: _green, strokeWidth: 2),
        ),
      );
}

class _PanelMessage extends StatelessWidget {
  const _PanelMessage({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) => SizedBox(
        height: 120,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: _muted, size: 21),
                const SizedBox(height: 8),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: _muted, fontSize: 11),
                ),
              ],
            ),
          ),
        ),
      );
}

class _StatusTag extends StatelessWidget {
  const _StatusTag({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final normalized = label.toLowerCase();
    final color = normalized == 'completed'
        ? _green
        : normalized == 'cancelled'
            ? const Color(0xFFC13C3C)
            : const Color(0xFFA96508);
    final background = normalized == 'completed'
        ? _mint
        : normalized == 'cancelled'
            ? const Color(0xFFFFF0EF)
            : const Color(0xFFFFF5DF);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _ManagementSection extends StatelessWidget {
  const _ManagementSection({required this.onOpenStudents});

  final VoidCallback onOpenStudents;

  @override
  Widget build(BuildContext context) {
    final items = [
      _ManagementItem(
        title: 'Students',
        subtitle: 'View registered student profiles',
        icon: Icons.people_outline,
        available: true,
        onTap: onOpenStudents,
      ),
      const _ManagementItem(
        title: 'EV Cart Fleet',
        subtitle: 'Fleet administration is not available yet',
        icon: Icons.electric_car_outlined,
      ),
      const _ManagementItem(
        title: 'Buses & Routes',
        subtitle: 'Schedule management is not available yet',
        icon: Icons.directions_bus_outlined,
      ),
      const _ManagementItem(
        title: 'Drivers',
        subtitle: 'Driver management is not available yet',
        icon: Icons.badge_outlined,
      ),
      const _ManagementItem(
        title: 'Rides & Bookings',
        subtitle: 'Booking management is not available yet',
        icon: Icons.confirmation_number_outlined,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Management',
          style: TextStyle(color: _ink, fontSize: 16, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 5),
        const Text(
          'Open an available admin module or see what is planned.',
          style: TextStyle(color: _muted, fontSize: 11),
        ),
        const SizedBox(height: 13),
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth >= 1050
                ? 3
                : constraints.maxWidth >= 650
                    ? 2
                    : 1;
            const gap = 12.0;
            final width =
                (constraints.maxWidth - gap * (columns - 1)) / columns;
            return Wrap(
              spacing: gap,
              runSpacing: gap,
              children: items
                  .map((item) => SizedBox(
                        width: width,
                        child: _ManagementCard(item: item),
                      ))
                  .toList(),
            );
          },
        ),
      ],
    );
  }
}

class _ManagementItem {
  const _ManagementItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    this.available = false,
    this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final bool available;
  final VoidCallback? onTap;
}

class _ManagementCard extends StatelessWidget {
  const _ManagementCard({required this.item});

  final _ManagementItem item;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: item.onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          constraints: const BoxConstraints(minHeight: 116),
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            border: Border.all(color: _line),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: item.available ? _mint : const Color(0xFFF3F5F4),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  item.icon,
                  color: item.available ? _green : _muted,
                  size: 18,
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: const TextStyle(
                        color: _ink,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      item.subtitle,
                      style: const TextStyle(color: _muted, fontSize: 10),
                    ),
                    if (!item.available) ...[
                      const SizedBox(height: 8),
                      const Text(
                        'Not available yet',
                        style: TextStyle(
                          color: _muted,
                          fontWeight: FontWeight.w700,
                          fontSize: 9,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (item.available)
                const Icon(Icons.arrow_forward, color: _green, size: 17),
            ],
          ),
        ),
      ),
    );
  }
}

class _AdminAvatar extends StatelessWidget {
  const _AdminAvatar({required this.email, required this.size});

  final String email;
  final double size;

  @override
  Widget build(BuildContext context) {
    final initial = email.isNotEmpty ? email[0].toUpperCase() : 'A';
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: const BoxDecoration(color: _mint, shape: BoxShape.circle),
      child: Text(
        initial,
        style: const TextStyle(
          color: _green,
          fontWeight: FontWeight.w800,
          fontSize: 12,
        ),
      ),
    );
  }
}

String _formatTimestamp(Object? value) {
  DateTime? date;
  if (value is Timestamp) {
    date = value.toDate();
  } else if (value is String) {
    date = DateTime.tryParse(value);
  }
  if (date == null) return 'timestamp unavailable';

  final local = date.toLocal();
  final now = DateTime.now();
  final difference = now.difference(local);
  if (difference.inMinutes < 1) return 'just now';
  if (difference.inHours < 1) return '${difference.inMinutes}m ago';
  if (difference.inHours < 24) return '${difference.inHours}h ago';
  return '${local.day}/${local.month}/${local.year}';
}
