
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class StudentManagementScreen extends StatefulWidget {
  const StudentManagementScreen({super.key});

  @override
  State<StudentManagementScreen> createState() =>
      _StudentManagementScreenState();
}

class _StudentManagementScreenState
    extends State<StudentManagementScreen> {
  final TextEditingController _searchController =
      TextEditingController();

  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Management'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Registered Students',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            const Text(
              'View student profiles registered in SARTHI.',
            ),
            const SizedBox(height: 20),

            TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                labelText: 'Search by name or email',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.trim().toLowerCase();
                });
              },
            ),

            const SizedBox(height: 20),

            Expanded(
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .where('role', isEqualTo: 'student')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return const Center(
                      child: Text(
                        'Could not load students. '
                        'Check Firestore permissions.',
                        textAlign: TextAlign.center,
                      ),
                    );
                  }

                  if (snapshot.connectionState ==
                      ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }

                  final students = snapshot.data?.docs ?? [];

                  final filteredStudents = students.where((doc) {
                    final data = doc.data();

                    final name =
                        (data['username'] ?? '')
                            .toString()
                            .toLowerCase();

                    final email =
                        (data['email'] ?? '')
                            .toString()
                            .toLowerCase();

                    return name.contains(_searchQuery) ||
                        email.contains(_searchQuery);
                  }).toList();

                  if (filteredStudents.isEmpty) {
                    return const Center(
                      child: Text('No students found.'),
                    );
                  }

                  return ListView.separated(
                    itemCount: filteredStudents.length,
                    separatorBuilder: (_, __) =>
                        const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final doc = filteredStudents[index];
                      final data = doc.data();

                      final username =
                          (data['username'] ?? 'Unknown')
                              .toString();

                      final email =
                          (data['email'] ?? 'No email')
                              .toString();

                      final hostel =
                          (data['hostel'] ?? 'Not provided')
                              .toString();

                      final phone =
                          (data['phone'] ?? 'Not provided')
                              .toString();

                      final photoUrl =
                          (data['photoUrl'] ?? '').toString();

                      final isComplete =
                          data['isProfileComplete'] == true;

                      return ListTile(
                        contentPadding:
                            const EdgeInsets.symmetric(
                          vertical: 8,
                          horizontal: 4,
                        ),
                        leading: CircleAvatar(
                          backgroundImage: photoUrl.isNotEmpty
                              ? NetworkImage(photoUrl)
                              : null,
                          child: photoUrl.isEmpty
                              ? const Icon(Icons.person)
                              : null,
                        ),
                        title: Text(
                          username,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            '$email\n'
                            'Hostel: $hostel\n'
                            'Phone: $phone',
                          ),
                        ),
                        isThreeLine: true,
                        trailing: Chip(
                          label: Text(
                            isComplete ? 'Complete' : 'Incomplete',
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
