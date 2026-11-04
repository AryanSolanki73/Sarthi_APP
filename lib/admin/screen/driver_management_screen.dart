import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import '../models/driver_model.dart';

const _green = Color(0xFF087F5B);
const _mint = Color(0xFFE7F6EF);
const _ink = Color(0xFF18231F);
const _muted = Color(0xFF7B8983);
const _line = Color(0xFFE7ECE9);
const _pageBackground = Color(0xFFF5F7F6);

enum _DriverFilter { all, active, inactive, evCart, bus }

/// Screen for administrators to view, add, edit, and delete transit driver records.
class DriverManagementScreen extends StatefulWidget {
  const DriverManagementScreen({super.key, this.firestore});

  final FirebaseFirestore? firestore;

  @override
  State<DriverManagementScreen> createState() => _DriverManagementScreenState();
}

class _DriverManagementScreenState extends State<DriverManagementScreen> {
  late final FirebaseFirestore? _firestore;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  _DriverFilter _selectedFilter = _DriverFilter.all;

  @override
  void initState() {
    super.initState();
    _firestore = widget.firestore ??
        (Firebase.apps.isNotEmpty ? FirebaseFirestore.instance : null);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Stream<List<DriverModel>> _driverStream() {
    final firestore = _firestore;
    if (firestore == null) {
      return Stream.value(<DriverModel>[]);
    }
    return firestore
        .collection('drivers')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => DriverModel.fromDoc(doc))
            .toList());
  }

  Future<void> _addOrEditDriver({DriverModel? existingDriver}) async {
    final isEditing = existingDriver != null;
    final formKey = GlobalKey<FormState>();

    final nameController =
        TextEditingController(text: existingDriver?.name ?? '');
    final phoneController =
        TextEditingController(text: existingDriver?.phone ?? '');
    final licenseController =
        TextEditingController(text: existingDriver?.licenseNumber ?? '');
    final vehicleNumberController =
        TextEditingController(text: existingDriver?.vehicleNumber ?? '');

    String vehicleType = existingDriver?.vehicleType ?? 'EV Cart';
    String status = existingDriver?.status ?? 'active';

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: _mint,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.badge_outlined, color: _green, size: 22),
              ),
              const SizedBox(width: 12),
              Text(
                isEditing ? 'Edit Driver Info' : 'Add New Driver',
                style: const TextStyle(
                  color: _ink,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Driver Full Name *',
                        hintText: 'e.g. Ramesh Kumar',
                        prefixIcon: Icon(Icons.person_outline, size: 20),
                        isDense: true,
                        filled: true,
                        fillColor: Color(0xFFF7FAF8),
                      ),
                      validator: (value) {
                        final v = value?.trim() ?? '';
                        if (v.length < 2) return 'Enter full driver name';
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Phone Number *',
                        hintText: 'e.g. +91 98765 43210',
                        prefixIcon: Icon(Icons.phone_outlined, size: 20),
                        isDense: true,
                        filled: true,
                        fillColor: Color(0xFFF7FAF8),
                      ),
                      validator: (value) {
                        final v = value?.trim() ?? '';
                        if (v.length < 8) return 'Enter a valid phone number';
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: licenseController,
                      decoration: const InputDecoration(
                        labelText: 'Driving License Number *',
                        hintText: 'e.g. PB-12-2019-00451',
                        prefixIcon: Icon(Icons.card_membership_outlined, size: 20),
                        isDense: true,
                        filled: true,
                        fillColor: Color(0xFFF7FAF8),
                      ),
                      validator: (value) {
                        final v = value?.trim() ?? '';
                        if (v.isEmpty) return 'Enter license number';
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<String>(
                      initialValue: vehicleType,
                      decoration: const InputDecoration(
                        labelText: 'Assigned Vehicle Type',
                        prefixIcon: Icon(Icons.directions_bus_outlined, size: 20),
                        isDense: true,
                        filled: true,
                        fillColor: Color(0xFFF7FAF8),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'EV Cart', child: Text('EV Cart')),
                        DropdownMenuItem(value: 'Bus', child: Text('Campus Bus / Shuttle')),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setDialogState(() => vehicleType = val);
                        }
                      },
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: vehicleNumberController,
                      decoration: InputDecoration(
                        labelText: 'Assigned Vehicle Number',
                        hintText: vehicleType == 'EV Cart'
                            ? 'e.g. PB-12-EV-01'
                            : 'e.g. PB-12-Bus-02',
                        prefixIcon: const Icon(Icons.pin_outlined, size: 20),
                        isDense: true,
                        filled: true,
                        fillColor: const Color(0xFFF7FAF8),
                      ),
                    ),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<String>(
                      initialValue: status,
                      decoration: const InputDecoration(
                        labelText: 'Duty Status',
                        prefixIcon: Icon(Icons.toggle_on_outlined, size: 20),
                        isDense: true,
                        filled: true,
                        fillColor: Color(0xFFF7FAF8),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'active', child: Text('Active / On Duty')),
                        DropdownMenuItem(value: 'inactive', child: Text('Inactive / Off Duty')),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setDialogState(() => status = val);
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: _green),
              onPressed: () {
                if (formKey.currentState?.validate() ?? false) {
                  Navigator.of(context).pop(true);
                }
              },
              child: Text(isEditing ? 'Save Changes' : 'Add Driver'),
            ),
          ],
        ),
      ),
    );

    final firestore = _firestore;
    if (result == true && firestore != null) {
      final name = nameController.text.trim();
      final phone = phoneController.text.trim();
      final license = licenseController.text.trim();
      final vehicleNumber = vehicleNumberController.text.trim();

      try {
        if (isEditing) {
          await firestore.collection('drivers').doc(existingDriver.id).update({
            'name': name,
            'phone': phone,
            'licenseNumber': license,
            'vehicleType': vehicleType,
            'vehicleNumber': vehicleNumber,
            'status': status,
          });
          _showToast('Driver "$name" updated successfully.');
        } else {
          await firestore.collection('drivers').add({
            'name': name,
            'phone': phone,
            'licenseNumber': license,
            'vehicleType': vehicleType,
            'vehicleNumber': vehicleNumber,
            'status': status,
            'createdAt': FieldValue.serverTimestamp(),
          });
          _showToast('Driver "$name" added successfully.');
        }
      } catch (e) {
        _showToast('Error saving driver: $e', isError: true);
      }
    }
  }

  Future<void> _confirmDeleteDriver(DriverModel driver) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Color(0xFFBA1A1A)),
            SizedBox(width: 10),
            Text('Delete Driver?'),
          ],
        ),
        content: Text(
          'Are you sure you want to delete "${driver.name}" (${driver.licenseNumber})?\nThis action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFBA1A1A)),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    final firestore = _firestore;
    if (confirmed == true && firestore != null) {
      try {
        await firestore.collection('drivers').doc(driver.id).delete();
        _showToast('Driver "${driver.name}" deleted successfully.');
      } catch (e) {
        _showToast('Failed to delete driver: $e', isError: true);
      }
    }
  }

  void _showToast(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? const Color(0xFFBA1A1A) : _green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  List<DriverModel> _filterDrivers(List<DriverModel> list) {
    var result = list;

    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      result = result.where((d) {
        return d.name.toLowerCase().contains(q) ||
            d.phone.toLowerCase().contains(q) ||
            d.licenseNumber.toLowerCase().contains(q) ||
            d.vehicleNumber.toLowerCase().contains(q);
      }).toList();
    }

    switch (_selectedFilter) {
      case _DriverFilter.active:
        result = result.where((d) => d.isActive).toList();
        break;
      case _DriverFilter.inactive:
        result = result.where((d) => !d.isActive).toList();
        break;
      case _DriverFilter.evCart:
        result = result
            .where((d) => d.vehicleType.toLowerCase().contains('cart'))
            .toList();
        break;
      case _DriverFilter.bus:
        result = result
            .where((d) => d.vehicleType.toLowerCase().contains('bus'))
            .toList();
        break;
      case _DriverFilter.all:
        break;
    }

    return result;
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isDesktop = width >= 900;

    return Scaffold(
      backgroundColor: _pageBackground,
      body: Column(
        children: [
          // Top Navigation Bar
          Container(
            height: 70,
            padding: EdgeInsets.symmetric(horizontal: isDesktop ? 28 : 16),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: _line)),
            ),
            child: Row(
              children: [
                IconButton(
                  tooltip: 'Back to Dashboard',
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.arrow_back, color: _ink),
                ),
                const SizedBox(width: 8),
                const Text(
                  'Workspace  /  ',
                  style: TextStyle(color: _muted, fontSize: 13),
                ),
                const Expanded(
                  child: Text(
                    'Drivers',
                    style: TextStyle(
                      color: _ink,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                FilledButton.icon(
                  onPressed: () => _addOrEditDriver(),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add Driver'),
                  style: FilledButton.styleFrom(
                    backgroundColor: _green,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                  ),
                ),
              ],
            ),
          ),

          // Main Content
          Expanded(
            child: StreamBuilder<List<DriverModel>>(
              stream: _driverStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting &&
                    !snapshot.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(color: _green),
                  );
                }

                final allDrivers = snapshot.data ?? [];
                final filtered = _filterDrivers(allDrivers);

                final totalCount = allDrivers.length;
                final activeCount = allDrivers.where((d) => d.isActive).length;
                final evCount = allDrivers
                    .where((d) => d.vehicleType.toLowerCase().contains('cart'))
                    .length;
                final busCount = allDrivers
                    .where((d) => d.vehicleType.toLowerCase().contains('bus'))
                    .length;

                return SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: isDesktop ? 32 : 16,
                    vertical: 24,
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1380),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Header Statistics Bar
                          _buildStatsOverview(
                            totalCount: totalCount,
                            activeCount: activeCount,
                            evCount: evCount,
                            busCount: busCount,
                          ),
                          const SizedBox(height: 20),

                          // Search & Filters Row
                          _buildSearchAndFilters(),
                          const SizedBox(height: 18),

                          // Driver List or Empty State
                          if (filtered.isEmpty)
                            _buildEmptyState(allDrivers.isEmpty)
                          else
                            ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: filtered.length,
                              separatorBuilder: (context, index) =>
                                  const SizedBox(height: 12),
                              itemBuilder: (context, index) {
                                final driver = filtered[index];
                                return _DriverCard(
                                  driver: driver,
                                  onEdit: () =>
                                      _addOrEditDriver(existingDriver: driver),
                                  onDelete: () => _confirmDeleteDriver(driver),
                                );
                              },
                            ),
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsOverview({
    required int totalCount,
    required int activeCount,
    required int evCount,
    required int busCount,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _line),
      ),
      child: Wrap(
        spacing: 24,
        runSpacing: 14,
        children: [
          _StatItem(
            label: 'TOTAL DRIVERS',
            value: '$totalCount',
            icon: Icons.people_outline,
          ),
          _StatItem(
            label: 'ON DUTY / ACTIVE',
            value: '$activeCount',
            icon: Icons.check_circle_outline,
            valueColor: _green,
          ),
          _StatItem(
            label: 'EV CART OPERATORS',
            value: '$evCount',
            icon: Icons.electric_car_outlined,
          ),
          _StatItem(
            label: 'BUS DRIVERS',
            value: '$busCount',
            icon: Icons.directions_bus_outlined,
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilters() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _line),
      ),
      child: Wrap(
        spacing: 14,
        runSpacing: 10,
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 360),
            child: TextField(
              controller: _searchController,
              onChanged: (val) => setState(() => _searchQuery = val.trim()),
              decoration: InputDecoration(
                hintText: 'Search by name, phone, license, vehicle...',
                hintStyle: const TextStyle(color: _muted, fontSize: 13),
                prefixIcon: const Icon(Icons.search, size: 18, color: _muted),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close, size: 16),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                filled: true,
                fillColor: const Color(0xFFF7FAF8),
                isDense: true,
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: _line),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: _line),
                ),
              ),
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _FilterChipButton(
                  label: 'All Drivers',
                  selected: _selectedFilter == _DriverFilter.all,
                  onSelected: () =>
                      setState(() => _selectedFilter = _DriverFilter.all),
                ),
                _FilterChipButton(
                  label: 'Active',
                  selected: _selectedFilter == _DriverFilter.active,
                  onSelected: () =>
                      setState(() => _selectedFilter = _DriverFilter.active),
                ),
                _FilterChipButton(
                  label: 'Inactive',
                  selected: _selectedFilter == _DriverFilter.inactive,
                  onSelected: () =>
                      setState(() => _selectedFilter = _DriverFilter.inactive),
                ),
                _FilterChipButton(
                  label: 'EV Carts',
                  selected: _selectedFilter == _DriverFilter.evCart,
                  onSelected: () =>
                      setState(() => _selectedFilter = _DriverFilter.evCart),
                ),
                _FilterChipButton(
                  label: 'Buses',
                  selected: _selectedFilter == _DriverFilter.bus,
                  onSelected: () =>
                      setState(() => _selectedFilter = _DriverFilter.bus),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool noDriversAtAll) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 54, horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _line),
      ),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: _mint,
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(Icons.badge_outlined, color: _green, size: 34),
          ),
          const SizedBox(height: 16),
          Text(
            noDriversAtAll ? 'No drivers added yet' : 'No matching drivers found',
            style: const TextStyle(
              color: _ink,
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            noDriversAtAll
                ? 'Add campus transit drivers to manage vehicle assignments and operational contacts.'
                : 'Try adjusting your search query or filter criteria.',
            style: const TextStyle(color: _muted, fontSize: 13),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          if (noDriversAtAll)
            FilledButton.icon(
              onPressed: () => _addOrEditDriver(),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add First Driver'),
              style: FilledButton.styleFrom(
                backgroundColor: _green,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              ),
            ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({
    required this.label,
    required this.value,
    required this.icon,
    this.valueColor,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: const Color(0xFFF3F6F4),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: _green),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: _muted,
                fontSize: 9,
                fontWeight: FontWeight.w800,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: TextStyle(
                color: valueColor ?? _ink,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _FilterChipButton extends StatelessWidget {
  const _FilterChipButton({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onSelected(),
        selectedColor: _mint,
        backgroundColor: Colors.transparent,
        labelStyle: TextStyle(
          color: selected ? _green : _muted,
          fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
          fontSize: 12,
        ),
        side: BorderSide(color: selected ? _green : _line),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}

class _DriverCard extends StatelessWidget {
  const _DriverCard({
    required this.driver,
    required this.onEdit,
    required this.onDelete,
  });

  final DriverModel driver;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final isBus = driver.vehicleType.toLowerCase().contains('bus');

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _line),
        boxShadow: const [
          BoxShadow(
            color: Color(0x04000000),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Driver Avatar
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: isBus ? const Color(0xFFEDF4FF) : _mint,
              shape: BoxShape.circle,
            ),
            child: Icon(
              isBus ? Icons.directions_bus_outlined : Icons.electric_car_outlined,
              color: isBus ? const Color(0xFF2B6CB0) : _green,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),

          // Details Column
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      driver.name,
                      style: const TextStyle(
                        color: _ink,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: driver.isActive
                            ? _mint
                            : const Color(0xFFF3F4F3),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        driver.isActive ? 'Active' : 'Inactive',
                        style: TextStyle(
                          color: driver.isActive
                              ? _green
                              : _muted,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Wrap(
                  spacing: 16,
                  runSpacing: 4,
                  children: [
                    if (driver.phone.isNotEmpty)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.phone_outlined, size: 14, color: _muted),
                          const SizedBox(width: 4),
                          Text(
                            driver.phone,
                            style: const TextStyle(color: _muted, fontSize: 13),
                          ),
                        ],
                      ),
                    if (driver.licenseNumber.isNotEmpty)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.badge_outlined, size: 14, color: _muted),
                          const SizedBox(width: 4),
                          Text(
                            'DL: ${driver.licenseNumber}',
                            style: const TextStyle(color: _muted, fontSize: 13),
                          ),
                        ],
                      ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isBus
                              ? Icons.directions_bus_outlined
                              : Icons.electric_car_outlined,
                          size: 14,
                          color: _muted,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          driver.vehicleNumber.isNotEmpty
                              ? '${driver.vehicleType} · ${driver.vehicleNumber}'
                              : driver.vehicleType,
                          style: const TextStyle(
                            color: Color(0xFF33443F),
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Actions Row
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                tooltip: 'Edit Driver',
                icon: const Icon(Icons.edit_outlined, size: 18, color: _muted),
                onPressed: onEdit,
              ),
              IconButton(
                tooltip: 'Delete Driver',
                icon: const Icon(Icons.delete_outline,
                    size: 18, color: Color(0xFFBA1A1A)),
                onPressed: onDelete,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
