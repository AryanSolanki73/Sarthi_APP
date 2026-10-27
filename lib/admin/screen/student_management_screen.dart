import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

const _green = Color(0xFF087F5B);
const _mint = Color(0xFFE7F6EF);
const _ink = Color(0xFF18231F);
const _muted = Color(0xFF7B8983);
const _line = Color(0xFFE7ECE9);
const _pageBackground = Color(0xFFF5F7F6);

enum _ProfileFilter { all, complete, incomplete }

class StudentManagementScreen extends StatefulWidget {
  const StudentManagementScreen({super.key});

  @override
  State<StudentManagementScreen> createState() =>
      _StudentManagementScreenState();
}

class _StudentManagementScreenState extends State<StudentManagementScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  _ProfileFilter _selectedFilter = _ProfileFilter.all;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showStudentDetails(Map<String, dynamic> data, String docId) {
    final name = (data['username'] ?? data['name'] ?? 'Unknown').toString();
    final email = (data['email'] ?? 'No email provided').toString();
    final hostel = (data['hostel'] ?? 'Not provided').toString();
    final phone = (data['phone'] ?? 'Not provided').toString();
    final photoUrl = (data['photoUrl'] ?? '').toString();
    final isComplete = data['isProfileComplete'] == true;
    final rollNo = (data['rollNumber'] ?? data['rollNo'] ?? 'Not provided').toString();

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
              color: Color(0x1A203B2B),
              blurRadius: 30,
              offset: Offset(0, -6),
            ),
          ],
        ),
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: _line,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                _StudentAvatar(photoUrl: photoUrl, name: name, size: 54),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          color: _ink,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        email,
                        style: const TextStyle(color: _muted, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                _StatusBadge(isComplete: isComplete),
              ],
            ),
            const SizedBox(height: 22),
            const Divider(color: _line, height: 1),
            const SizedBox(height: 18),
            const Text(
              'PROFILE DETAILS',
              style: TextStyle(
                color: _muted,
                fontSize: 10,
                letterSpacing: 1.2,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 12),
            _DetailTile(icon: Icons.badge_outlined, label: 'Roll Number', value: rollNo),
            _DetailTile(icon: Icons.apartment_outlined, label: 'Campus Hostel', value: hostel),
            _DetailTile(icon: Icons.phone_outlined, label: 'Phone Number', value: phone),
            _DetailTile(icon: Icons.fingerprint_outlined, label: 'User ID', value: docId),
            const SizedBox(height: 24),
            SizedBox(
              height: 46,
              child: FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                style: FilledButton.styleFrom(
                  backgroundColor: _green,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Close',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _pageBackground,
      body: Column(
        children: [
          // Top bar matching Admin Dashboard TopBar
          Container(
            height: 70,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: _line)),
            ),
            child: Row(
              children: [
                IconButton(
                  tooltip: 'Back to Dashboard',
                  onPressed: () => Navigator.of(context).maybePop(),
                  icon: const Icon(Icons.arrow_back, color: _ink),
                ),
                const SizedBox(width: 8),
                const Text(
                  'Workspace  /  ',
                  style: TextStyle(color: _muted, fontSize: 13),
                ),
                const Text(
                  'Students',
                  style: TextStyle(
                    color: _ink,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: _mint,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.shield_outlined, size: 14, color: _green),
                      SizedBox(width: 6),
                      Text(
                        'Admin Access',
                        style: TextStyle(
                          color: _green,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Main Scrollable Area
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 36),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1420),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Section matching Campus Operations format
                      const Text(
                        'CAMPUS DIRECTORY',
                        style: TextStyle(
                          color: _green,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.4,
                          fontSize: 10,
                        ),
                      ),
                      const SizedBox(height: 7),
                      const Text(
                        'Student management',
                        style: TextStyle(
                          color: _ink,
                          fontSize: 27,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.6,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Search and view all registered student profiles in the SARTHI transit system.',
                        style: TextStyle(color: _muted, fontSize: 12),
                      ),

                      const SizedBox(height: 22),

                      // Search & Filter Toolbar
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: _line),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x06203B2B),
                              blurRadius: 18,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Search field
                            TextField(
                              controller: _searchController,
                              style: const TextStyle(
                                color: _ink,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                              decoration: InputDecoration(
                                hintText: 'Search by student name, college email, or hostel...',
                                hintStyle: TextStyle(
                                  color: _muted.withOpacity(0.7),
                                  fontSize: 13,
                                ),
                                prefixIcon: const Icon(
                                  Icons.search,
                                  color: _muted,
                                  size: 20,
                                ),
                                suffixIcon: _searchQuery.isNotEmpty
                                    ? IconButton(
                                        tooltip: 'Clear search',
                                        onPressed: () {
                                          _searchController.clear();
                                          setState(() => _searchQuery = '');
                                        },
                                        icon: const Icon(
                                          Icons.close,
                                          color: _muted,
                                          size: 18,
                                        ),
                                      )
                                    : null,
                                filled: true,
                                fillColor: const Color(0xFFFAFCFA),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 12,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: _line),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: _line),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: _green,
                                    width: 1.8,
                                  ),
                                ),
                              ),
                              onChanged: (value) {
                                setState(() {
                                  _searchQuery = value.trim().toLowerCase();
                                });
                              },
                            ),

                            const SizedBox(height: 12),

                            // Filter Chips Row
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                const Text(
                                  'FILTER BY:',
                                  style: TextStyle(
                                    color: _muted,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 1,
                                  ),
                                ),
                                _FilterChip(
                                  label: 'All Students',
                                  selected: _selectedFilter == _ProfileFilter.all,
                                  onSelected: () {
                                    setState(() => _selectedFilter = _ProfileFilter.all);
                                  },
                                ),
                                _FilterChip(
                                  label: 'Complete Profile',
                                  selected: _selectedFilter == _ProfileFilter.complete,
                                  onSelected: () {
                                    setState(() => _selectedFilter = _ProfileFilter.complete);
                                  },
                                ),
                                _FilterChip(
                                  label: 'Incomplete Profile',
                                  selected: _selectedFilter == _ProfileFilter.incomplete,
                                  onSelected: () {
                                    setState(() => _selectedFilter = _ProfileFilter.incomplete);
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Students List StreamBuilder
                      StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                        stream: FirebaseFirestore.instance
                            .collection('users')
                            .where('role', isEqualTo: 'student')
                            .snapshots(),
                        builder: (context, snapshot) {
                          if (snapshot.hasError) {
                            return _PanelMessageCard(
                              icon: Icons.error_outline,
                              title: 'Failed to load students',
                              message: 'Could not access student records. Verify Firestore permissions.',
                            );
                          }

                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const SizedBox(
                              height: 180,
                              child: Center(
                                child: CircularProgressIndicator(
                                  color: _green,
                                  strokeWidth: 2.2,
                                ),
                              ),
                            );
                          }

                          final students = snapshot.data?.docs ?? [];

                          final filteredStudents = students.where((doc) {
                            final data = doc.data();
                            final name = (data['username'] ?? data['name'] ?? '').toString().toLowerCase();
                            final email = (data['email'] ?? '').toString().toLowerCase();
                            final hostel = (data['hostel'] ?? '').toString().toLowerCase();
                            final isComplete = data['isProfileComplete'] == true;

                            final matchesQuery = _searchQuery.isEmpty ||
                                name.contains(_searchQuery) ||
                                email.contains(_searchQuery) ||
                                hostel.contains(_searchQuery);

                            final matchesFilter = switch (_selectedFilter) {
                              _ProfileFilter.all => true,
                              _ProfileFilter.complete => isComplete,
                              _ProfileFilter.incomplete => !isComplete,
                            };

                            return matchesQuery && matchesFilter;
                          }).toList();

                          if (filteredStudents.isEmpty) {
                            return _PanelMessageCard(
                              icon: Icons.search_off_rounded,
                              title: 'No matching students found',
                              message: _searchQuery.isNotEmpty
                                  ? 'No registered students match "$_searchQuery".'
                                  : 'No student profiles match the active filter.',
                            );
                          }

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(left: 4, bottom: 12),
                                child: Text(
                                  'Showing ${filteredStudents.length} of ${students.length} student${students.length == 1 ? '' : 's'}',
                                  style: const TextStyle(
                                    color: _muted,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: filteredStudents.length,
                                separatorBuilder: (_, __) => const SizedBox(height: 10),
                                itemBuilder: (context, index) {
                                  final doc = filteredStudents[index];
                                  final data = doc.data();

                                  final username = (data['username'] ?? data['name'] ?? 'Unknown').toString();
                                  final email = (data['email'] ?? 'No email').toString();
                                  final hostel = (data['hostel'] ?? 'Not provided').toString();
                                  final phone = (data['phone'] ?? 'Not provided').toString();
                                  final photoUrl = (data['photoUrl'] ?? '').toString();
                                  final isComplete = data['isProfileComplete'] == true;

                                  return _StudentCard(
                                    username: username,
                                    email: email,
                                    hostel: hostel,
                                    phone: phone,
                                    photoUrl: photoUrl,
                                    isComplete: isComplete,
                                    onTap: () => _showStudentDetails(data, doc.id),
                                  );
                                },
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
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? _mint : Colors.transparent,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onSelected,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            border: Border.all(color: selected ? _green : _line),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? _green : _ink,
              fontSize: 11,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

class _StudentCard extends StatelessWidget {
  const _StudentCard({
    required this.username,
    required this.email,
    required this.hostel,
    required this.phone,
    required this.photoUrl,
    required this.isComplete,
    required this.onTap,
  });

  final String username;
  final String email;
  final String hostel;
  final String phone;
  final String photoUrl;
  final bool isComplete;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: _line),
            borderRadius: BorderRadius.circular(14),
            boxShadow: const [
              BoxShadow(
                color: Color(0x06203B2B),
                blurRadius: 16,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _StudentAvatar(photoUrl: photoUrl, name: username, size: 44),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            username,
                            style: const TextStyle(
                              color: _ink,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        _StatusBadge(isComplete: isComplete),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      email,
                      style: const TextStyle(
                        color: _muted,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 12,
                      runSpacing: 4,
                      children: [
                        _MetaBadge(icon: Icons.apartment_outlined, text: 'Hostel: $hostel'),
                        _MetaBadge(icon: Icons.phone_outlined, text: 'Phone: $phone'),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right, color: _muted, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _StudentAvatar extends StatelessWidget {
  const _StudentAvatar({
    required this.photoUrl,
    required this.name,
    this.size = 40,
  });

  final String photoUrl;
  final String name;
  final double size;

  @override
  Widget build(BuildContext context) {
    if (photoUrl.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(size / 2),
        child: Image.network(
          photoUrl,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _initialsAvatar(),
        ),
      );
    }
    return _initialsAvatar();
  }

  Widget _initialsAvatar() {
    final initial = name.isNotEmpty ? name[0].toUpperCase() : 'S';
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: _mint,
        borderRadius: BorderRadius.circular(size / 2),
        border: Border.all(color: _line),
      ),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: TextStyle(
          color: _green,
          fontWeight: FontWeight.w800,
          fontSize: size * 0.38,
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.isComplete});

  final bool isComplete;

  @override
  Widget build(BuildContext context) {
    final color = isComplete ? _green : const Color(0xFFA96508);
    final background = isComplete ? _mint : const Color(0xFFFFF5DF);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isComplete ? Icons.check_circle_outline : Icons.pending_outlined,
            size: 11,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            isComplete ? 'Complete' : 'Incomplete',
            style: TextStyle(
              color: color,
              fontSize: 9,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetaBadge extends StatelessWidget {
  const _MetaBadge({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: _muted),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(color: _muted, fontSize: 10),
        ),
      ],
    );
  }
}

class _DetailTile extends StatelessWidget {
  const _DetailTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: const Color(0xFFF7FAF8),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: _line),
            ),
            child: Icon(icon, size: 16, color: _green),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(color: _muted, fontSize: 10),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  color: _ink,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PanelMessageCard extends StatelessWidget {
  const _PanelMessageCard({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _line),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: _muted, size: 36),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              color: _ink,
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: _muted, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

