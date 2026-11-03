import 'package:flutter/material.dart';
import '../models/bus_schedule_model.dart';
import '../services/bus_schedule_service.dart';

const _green = Color(0xFF087F5B);
const _mint = Color(0xFFE7F6EF);
const _ink = Color(0xFF18231F);
const _muted = Color(0xFF7B8983);
const _line = Color(0xFFE7ECE9);
const _pageBackground = Color(0xFFF5F7F6);

enum _TimeFilter { all, morning, afternoon, evening, night }

/// Admin screen for viewing, managing, and setting daily bus schedules on web & mobile.
/// Pre-populated with the official IIT Ropar timetable w.e.f. 27-07-2026.
class BusScheduleScreen extends StatefulWidget {
  const BusScheduleScreen({
    super.key,
    this.service,
    this.initialDayId = 'monday',
  });

  final BusScheduleService? service;
  final String initialDayId;

  @override
  State<BusScheduleScreen> createState() => _BusScheduleScreenState();
}

class _BusScheduleScreenState extends State<BusScheduleScreen> {
  late final BusScheduleService _service;
  late String _selectedDayId;
  DayBusSchedule? _currentSchedule;
  bool _isLoading = true;
  bool _isPublishing = false;
  String _searchQuery = '';
  _TimeFilter _selectedTimeFilter = _TimeFilter.all;

  final TextEditingController _searchController = TextEditingController();

  final List<Map<String, String>> _availableDays = [
    {'id': 'monday', 'label': 'Monday', 'badge': '7 trips'},
    {'id': 'tuesday_thursday', 'label': 'Tue - Thu', 'badge': '6 trips'},
    {'id': 'friday', 'label': 'Friday', 'badge': '9 trips'},
    {'id': 'saturday_holidays', 'label': 'Sat & Holidays', 'badge': '7 trips'},
    {'id': 'sunday', 'label': 'Sunday', 'badge': '6 trips'},
  ];

  @override
  void initState() {
    super.initState();
    _service = widget.service ?? BusScheduleService();
    _selectedDayId = widget.initialDayId;
    _loadScheduleForDay(_selectedDayId);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadScheduleForDay(String dayId) async {
    setState(() => _isLoading = true);
    try {
      final schedule = await _service.getScheduleForDay(dayId);
      if (mounted) {
        setState(() {
          _selectedDayId = dayId;
          _currentSchedule = schedule;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showNotification('Failed to load schedule: $e', isError: true);
      }
    }
  }

  Future<void> _publishActiveSchedule() async {
    if (_currentSchedule == null) return;
    setState(() => _isPublishing = true);

    try {
      await _service.publishScheduleToLiveBuses(_currentSchedule!);
      if (mounted) {
        _showNotification(
          '${_currentSchedule!.dayTitle} schedule published successfully to live student app!',
          isError: false,
        );
      }
    } catch (e) {
      if (mounted) {
        _showNotification('Error setting live schedule: $e', isError: true);
      }
    } finally {
      if (mounted) setState(() => _isPublishing = false);
    }
  }

  Future<void> _resetToPdfDefault() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset to Official PDF Schedule?'),
        content: Text(
          'This will revert all changes for ${_currentSchedule?.dayTitle} back to the verified IIT Ropar timetable w.e.f. 27-07-2026.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: _green),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Reset'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _isLoading = true);
      try {
        final resetSchedule = await _service.resetScheduleToDefault(_selectedDayId);
        if (mounted) {
          setState(() {
            _currentSchedule = resetSchedule;
            _isLoading = false;
          });
          _showNotification('Schedule reset to official IIT Ropar PDF defaults.');
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isLoading = false);
          _showNotification('Failed to reset schedule: $e', isError: true);
        }
      }
    }
  }

  void _toggleTripActive(ScheduledTrip trip, bool isActive) {
    if (_currentSchedule == null) return;
    final updatedTrips = _currentSchedule!.trips.map((t) {
      if (t.id == trip.id) {
        return t.copyWith(isActive: isActive);
      }
      return t;
    }).toList();

    final updatedSchedule = _currentSchedule!.copyWith(trips: updatedTrips);
    setState(() => _currentSchedule = updatedSchedule);
    _service.saveSchedule(updatedSchedule);
  }

  void _deleteTrip(ScheduledTrip trip) {
    if (_currentSchedule == null) return;
    final updatedTrips =
        _currentSchedule!.trips.where((t) => t.id != trip.id).toList();
    final updatedSchedule = _currentSchedule!.copyWith(trips: updatedTrips);
    setState(() => _currentSchedule = updatedSchedule);
    _service.saveSchedule(updatedSchedule);
    _showNotification('Trip "${trip.title}" removed.');
  }

  void _pickCalendarDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(2026, 1, 1),
      lastDate: DateTime(2028, 12, 31),
    );

    if (picked != null) {
      final dayId = OfficialBusScheduleData.dayIdForDate(picked);
      _loadScheduleForDay(dayId);
    }
  }

  void _openTripEditor({ScheduledTrip? trip}) {
    showDialog<void>(
      context: context,
      builder: (context) => _TripEditorDialog(
        trip: trip,
        nextTripNumber: (_currentSchedule?.trips.length ?? 0) + 1,
        onSave: (savedTrip) {
          if (_currentSchedule == null) return;
          List<ScheduledTrip> newTrips = List.from(_currentSchedule!.trips);
          final index = newTrips.indexWhere((t) => t.id == savedTrip.id);
          if (index >= 0) {
            newTrips[index] = savedTrip;
          } else {
            newTrips.add(savedTrip);
          }
          final updated = _currentSchedule!.copyWith(trips: newTrips);
          setState(() => _currentSchedule = updated);
          _service.saveSchedule(updated);
          _showNotification(index >= 0 ? 'Trip updated.' : 'Trip added.');
        },
      ),
    );
  }

  void _showNotification(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? const Color(0xFFBA1A1A) : _green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  List<ScheduledTrip> get _filteredTrips {
    if (_currentSchedule == null) return [];
    var list = _currentSchedule!.trips;

    // Filter by search query
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list.where((t) {
        final matchesTitle = t.title.toLowerCase().contains(q);
        final matchesDeparture = t.departureTime.toLowerCase().contains(q);
        final matchesStops = t.stops.any((s) => s.stopName.toLowerCase().contains(q));
        final matchesNote = t.note?.toLowerCase().contains(q) ?? false;
        return matchesTitle || matchesDeparture || matchesStops || matchesNote;
      }).toList();
    }

    // Filter by time of day
    if (_selectedTimeFilter != _TimeFilter.all) {
      list = list.where((t) {
        final timeStr = t.departureTime.toUpperCase();
        final isAM = timeStr.contains('AM');
        final hourMatch = RegExp(r'^(\d+)').firstMatch(timeStr);
        final hour = hourMatch != null ? int.tryParse(hourMatch.group(1)!) ?? 12 : 12;

        switch (_selectedTimeFilter) {
          case _TimeFilter.morning:
            return isAM && hour < 12;
          case _TimeFilter.afternoon:
            return (!isAM && (hour == 12 || hour < 5));
          case _TimeFilter.evening:
            return (!isAM && (hour >= 5 && hour < 8));
          case _TimeFilter.night:
            return (!isAM && (hour >= 8 && hour <= 11)) || (isAM && hour == 12);
          case _TimeFilter.all:
            return true;
        }
      }).toList();
    }

    return list;
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isDesktop = screenWidth >= 1050;

    return Scaffold(
      backgroundColor: _pageBackground,
      body: Column(
        children: [
          // Top Navigation Bar
          _buildTopBar(isDesktop),

          // Main Scrollable Area
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: _green))
                : SingleChildScrollView(
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
                            // Day Selector Tab Bar & Date Picker
                            _buildDaySelector(isDesktop),
                            const SizedBox(height: 20),

                            // Schedule Header Summary & Quick Action Card
                            _buildScheduleSummaryCard(isDesktop),
                            const SizedBox(height: 20),

                            // Search & Time Filters
                            _buildFilterBar(),
                            const SizedBox(height: 18),

                            // Trips List
                            _buildTripsList(isDesktop),
                            const SizedBox(height: 32),

                            // Official Institute Rules Footer
                            _buildRulesSection(),
                            const SizedBox(height: 40),
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

  Widget _buildTopBar(bool isDesktop) {
    return Container(
      height: 72,
      padding: EdgeInsets.symmetric(horizontal: isDesktop ? 28 : 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: _line)),
      ),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Back to Dashboard',
            icon: const Icon(Icons.arrow_back_rounded, color: _ink),
            onPressed: () => Navigator.of(context).pop(),
          ),
          const SizedBox(width: 12),
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: _green,
              borderRadius: BorderRadius.circular(11),
            ),
            child: const Icon(Icons.directions_bus_rounded, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Row(
                children: [
                  Text(
                    'Bus Schedule Manager',
                    style: TextStyle(
                      color: _ink,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(width: 8),
                  Text(
                    '· Official Timetable',
                    style: TextStyle(color: _muted, fontSize: 13),
                  ),
                ],
              ),
              Text(
                'IIT Ropar Transit Control • ${_currentSchedule?.subtitle ?? 'w.e.f. 27-07-2026'}',
                style: const TextStyle(
                  color: _muted,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const Spacer(),
          if (isDesktop) ...[
            FilledButton.icon(
              onPressed: _isPublishing ? null : _publishActiveSchedule,
              icon: _isPublishing
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.cloud_upload_outlined, size: 18),
              label: Text(_isPublishing ? 'Publishing...' : 'Set Active for Today'),
              style: FilledButton.styleFrom(
                backgroundColor: _green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDaySelector(bool isDesktop) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _line),
      ),
      child: Row(
        children: [
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _availableDays.map((day) {
                  final isSelected = _selectedDayId == day['id'];
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: InkWell(
                      onTap: () => _loadScheduleForDay(day['id']!),
                      borderRadius: BorderRadius.circular(12),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: isSelected ? _green : const Color(0xFFF7FAF8),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected ? _green : _line,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.calendar_today_rounded,
                              size: 15,
                              color: isSelected ? Colors.white : _muted,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              day['label']!,
                              style: TextStyle(
                                color: isSelected ? Colors.white : _ink,
                                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? Colors.white.withValues(alpha: 0.22)
                                    : const Color(0xFFE5EBE8),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                day['badge']!,
                                style: TextStyle(
                                  color: isSelected ? Colors.white : _muted,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(width: 8),
          OutlinedButton.icon(
            onPressed: _pickCalendarDate,
            icon: const Icon(Icons.date_range_rounded, size: 16),
            label: const Text('Pick Date'),
            style: OutlinedButton.styleFrom(
              foregroundColor: _ink,
              side: const BorderSide(color: _line),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleSummaryCard(bool isDesktop) {
    final schedule = _currentSchedule;
    if (schedule == null) return const SizedBox.shrink();

    final activeCount = schedule.trips.where((t) => t.isActive).length;
    final totalCount = schedule.trips.length;
    final firstTrip = schedule.trips.isNotEmpty ? schedule.trips.first.departureTime : '--';
    final lastTrip = schedule.trips.isNotEmpty ? schedule.trips.last.arrivalTime : '--';

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _line),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: _mint,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'OFFICIAL IIT ROPAR TIMETABLE',
                            style: TextStyle(
                              color: _green,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          schedule.subtitle,
                          style: const TextStyle(color: _muted, fontSize: 12),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Bus Schedule for ${schedule.dayTitle}',
                      style: const TextStyle(
                        color: _ink,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.4,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Manage daily routes, intermediate pickup/drop-off stops, and push active schedules to the student transit app.',
                      style: TextStyle(color: _muted, fontSize: 13),
                    ),
                  ],
                ),
              ),
              if (!isDesktop) ...[
                IconButton(
                  tooltip: 'Reset to PDF Defaults',
                  icon: const Icon(Icons.restore, color: _muted),
                  onPressed: _resetToPdfDefault,
                ),
              ],
            ],
          ),
          const SizedBox(height: 18),
          const Divider(color: _line, height: 1),
          const SizedBox(height: 18),
          Wrap(
            spacing: 16,
            runSpacing: 12,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _SummaryStat(
                    label: 'TOTAL TRIPS',
                    value: '$totalCount',
                    icon: Icons.alt_route,
                  ),
                  const SizedBox(width: 24),
                  _SummaryStat(
                    label: 'ACTIVE TRIPS',
                    value: '$activeCount',
                    icon: Icons.check_circle_outline,
                    valueColor: _green,
                  ),
                  const SizedBox(width: 24),
                  _SummaryStat(
                    label: 'SERVICE HOURS',
                    value: '$firstTrip - $lastTrip',
                    icon: Icons.access_time_rounded,
                  ),
                ],
              ),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  OutlinedButton.icon(
                    onPressed: () => _openTripEditor(),
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Add Custom Trip'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _ink,
                      side: const BorderSide(color: _line),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: _resetToPdfDefault,
                    icon: const Icon(Icons.restore, size: 16),
                    label: const Text('Reset to PDF'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _muted,
                      side: const BorderSide(color: _line),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                    ),
                  ),
                  if (!isDesktop)
                    FilledButton.icon(
                      onPressed: _isPublishing ? null : _publishActiveSchedule,
                      icon: const Icon(Icons.cloud_upload_outlined, size: 16),
                      label: Text(_isPublishing ? 'Publishing...' : 'Publish to Live App'),
                      style: FilledButton.styleFrom(
                        backgroundColor: _green,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
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
            constraints: const BoxConstraints(maxWidth: 340),
            child: TextField(
              controller: _searchController,
              onChanged: (val) => setState(() => _searchQuery = val.trim()),
              decoration: InputDecoration(
                hintText: 'Search route, stop, or timing...',
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
                contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
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
                _TimeFilterChip(
                  label: 'All Times',
                  selected: _selectedTimeFilter == _TimeFilter.all,
                  onSelected: () => setState(() => _selectedTimeFilter = _TimeFilter.all),
                ),
                _TimeFilterChip(
                  label: 'Morning (Before 12 PM)',
                  selected: _selectedTimeFilter == _TimeFilter.morning,
                  onSelected: () => setState(() => _selectedTimeFilter = _TimeFilter.morning),
                ),
                _TimeFilterChip(
                  label: 'Afternoon (12 - 5 PM)',
                  selected: _selectedTimeFilter == _TimeFilter.afternoon,
                  onSelected: () => setState(() => _selectedTimeFilter = _TimeFilter.afternoon),
                ),
                _TimeFilterChip(
                  label: 'Evening (5 - 8 PM)',
                  selected: _selectedTimeFilter == _TimeFilter.evening,
                  onSelected: () => setState(() => _selectedTimeFilter = _TimeFilter.evening),
                ),
                _TimeFilterChip(
                  label: 'Night (After 8 PM)',
                  selected: _selectedTimeFilter == _TimeFilter.night,
                  onSelected: () => setState(() => _selectedTimeFilter = _TimeFilter.night),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTripsList(bool isDesktop) {
    final trips = _filteredTrips;
    if (trips.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _line),
        ),
        child: Column(
          children: [
            const Icon(Icons.search_off_rounded, size: 48, color: _muted),
            const SizedBox(height: 12),
            const Text(
              'No scheduled trips found',
              style: TextStyle(color: _ink, fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              _searchQuery.isNotEmpty
                  ? 'No trips matched your search for "$_searchQuery".'
                  : 'No trips configured for this time filter.',
              style: const TextStyle(color: _muted, fontSize: 13),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: trips.length,
      separatorBuilder: (context, index) => const SizedBox(height: 14),
      itemBuilder: (context, index) {
        final trip = trips[index];
        return _TripCard(
          trip: trip,
          onToggleActive: (val) => _toggleTripActive(trip, val),
          onEdit: () => _openTripEditor(trip: trip),
          onDelete: () => _deleteTrip(trip),
        );
      },
    );
  }

  Widget _buildRulesSection() {
    final rules = _currentSchedule?.generalRules ?? OfficialBusScheduleData.standardInstituteRules;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FBFA),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFD6E3DD)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.info_outline_rounded, color: _green, size: 20),
              SizedBox(width: 8),
              Text(
                'IIT ROPAR BUS TRANSPORTATION RULES & GUIDELINES',
                style: TextStyle(
                  color: _ink,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...rules.map((rule) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('• ', style: TextStyle(color: _green, fontWeight: FontWeight.bold)),
                    Expanded(
                      child: Text(
                        rule,
                        style: const TextStyle(color: Color(0xFF33443F), fontSize: 13, height: 1.4),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}

class _SummaryStat extends StatelessWidget {
  const _SummaryStat({
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
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _TimeFilterChip extends StatelessWidget {
  const _TimeFilterChip({
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

class _TripCard extends StatefulWidget {
  const _TripCard({
    required this.trip,
    required this.onToggleActive,
    required this.onEdit,
    required this.onDelete,
  });

  final ScheduledTrip trip;
  final ValueChanged<bool> onToggleActive;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  State<_TripCard> createState() => _TripCardState();
}

class _TripCardState extends State<_TripCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final trip = widget.trip;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: trip.isActive ? _line : const Color(0xFFF0E0E0),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x04000000),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Row
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 16, 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: trip.isActive ? _mint : const Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'TRIP ${trip.tripNumber}',
                    style: TextStyle(
                      color: trip.isActive ? _green : _muted,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        trip.title,
                        style: TextStyle(
                          color: trip.isActive ? _ink : _muted,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Icon(Icons.access_time_filled, size: 13, color: _green),
                          const SizedBox(width: 4),
                          Text(
                            '${trip.departureTime} → ${trip.arrivalTime}',
                            style: const TextStyle(
                              color: _green,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Icon(Icons.directions_bus_outlined, size: 13, color: _muted),
                          const SizedBox(width: 4),
                          Text(
                            trip.registrationNumber,
                            style: const TextStyle(color: _muted, fontSize: 12),
                          ),
                          const SizedBox(width: 12),
                          const Icon(Icons.event_seat_outlined, size: 13, color: _muted),
                          const SizedBox(width: 4),
                          Text(
                            '${trip.totalSeats} seats',
                            style: const TextStyle(color: _muted, fontSize: 12),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    Switch(
                      value: trip.isActive,
                      activeThumbColor: _green,
                      onChanged: widget.onToggleActive,
                    ),
                    IconButton(
                      tooltip: 'Edit Trip',
                      icon: const Icon(Icons.edit_outlined, size: 18, color: _muted),
                      onPressed: widget.onEdit,
                    ),
                    IconButton(
                      tooltip: 'Delete Trip',
                      icon: const Icon(Icons.delete_outline, size: 18, color: Color(0xFFBA1A1A)),
                      onPressed: widget.onDelete,
                    ),
                    IconButton(
                      tooltip: _expanded ? 'Hide stops' : 'View stops',
                      icon: Icon(_expanded ? Icons.expand_less : Icons.expand_more, color: _muted),
                      onPressed: () => setState(() => _expanded = !_expanded),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Special note if present
          if (trip.note != null && trip.note!.isNotEmpty) ...[
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF9DB),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFFFEC99)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, size: 16, color: Color(0xFFF08C00)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      trip.note!,
                      style: const TextStyle(
                        color: Color(0xFF7A4E00),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Expandable Stop-by-Stop Itinerary
          if (_expanded) ...[
            const Divider(color: _line, height: 1),
            Container(
              padding: const EdgeInsets.all(20),
              color: const Color(0xFFFAFBFB),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'STOP-BY-STOP TIMINGS & AUTHORIZED PICKUP POINTS',
                    style: TextStyle(
                      color: _muted,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.1,
                    ),
                  ),
                  const SizedBox(height: 14),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: trip.stops.length,
                    itemBuilder: (context, sIdx) {
                      final stop = trip.stops[sIdx];
                      final isFirst = sIdx == 0;
                      final isLast = sIdx == trip.stops.length - 1;

                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Timeline marker
                          Column(
                            children: [
                              Container(
                                width: 14,
                                height: 14,
                                decoration: BoxDecoration(
                                  color: isFirst || isLast ? _green : Colors.white,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: _green,
                                    width: isFirst || isLast ? 0 : 3,
                                  ),
                                ),
                              ),
                              if (!isLast)
                                Container(
                                  width: 2,
                                  height: 28,
                                  color: _line,
                                ),
                            ],
                          ),
                          const SizedBox(width: 14),
                          // Stop Details
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      stop.stopName,
                                      style: TextStyle(
                                        color: isFirst || isLast ? _ink : const Color(0xFF3B4843),
                                        fontWeight: isFirst || isLast
                                            ? FontWeight.w700
                                            : FontWeight.w500,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 9,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: _line),
                                    ),
                                    child: Text(
                                      stop.time,
                                      style: const TextStyle(
                                        color: _ink,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Dialog for adding or editing a trip and its stop timings.
class _TripEditorDialog extends StatefulWidget {
  const _TripEditorDialog({
    this.trip,
    required this.nextTripNumber,
    required this.onSave,
  });

  final ScheduledTrip? trip;
  final int nextTripNumber;
  final ValueChanged<ScheduledTrip> onSave;

  @override
  State<_TripEditorDialog> createState() => _TripEditorDialogState();
}

class _TripEditorDialogState extends State<_TripEditorDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _departureController;
  late final TextEditingController _arrivalController;
  late final TextEditingController _regController;
  late final TextEditingController _seatsController;
  late final TextEditingController _noteController;
  late List<BusStopSchedule> _stops;

  @override
  void initState() {
    super.initState();
    final t = widget.trip;
    _titleController = TextEditingController(text: t?.title ?? 'Local Round Trip');
    _departureController = TextEditingController(text: t?.departureTime ?? '08:00 AM');
    _arrivalController = TextEditingController(text: t?.arrivalTime ?? '08:45 AM');
    _regController = TextEditingController(text: t?.registrationNumber ?? 'PB-12-Bus-01');
    _seatsController = TextEditingController(text: (t?.totalSeats ?? 35).toString());
    _noteController = TextEditingController(text: t?.note ?? '');
    _stops = t != null ? List.from(t.stops) : [
      const BusStopSchedule(stopName: 'Departure from main campus', time: '08:00 AM', type: 'departure'),
      const BusStopSchedule(stopName: 'Arrival at main campus', time: '08:45 AM', type: 'arrival'),
    ];
  }

  @override
  void dispose() {
    _titleController.dispose();
    _departureController.dispose();
    _arrivalController.dispose();
    _regController.dispose();
    _seatsController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _addStop() {
    setState(() {
      _stops.add(
        const BusStopSchedule(stopName: 'New stop name', time: '08:15 AM', type: 'both'),
      );
    });
  }

  void _removeStop(int index) {
    if (_stops.length <= 2) return;
    setState(() => _stops.removeAt(index));
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final trip = ScheduledTrip(
      id: widget.trip?.id ?? 'trip_${DateTime.now().millisecondsSinceEpoch}',
      tripNumber: widget.trip?.tripNumber ?? widget.nextTripNumber,
      title: _titleController.text.trim(),
      departureTime: _departureController.text.trim(),
      arrivalTime: _arrivalController.text.trim(),
      registrationNumber: _regController.text.trim(),
      totalSeats: int.tryParse(_seatsController.text.trim()) ?? 35,
      availableSeats: int.tryParse(_seatsController.text.trim()) ?? 35,
      isActive: widget.trip?.isActive ?? true,
      note: _noteController.text.trim().isNotEmpty ? _noteController.text.trim() : null,
      stops: _stops,
    );

    widget.onSave(trip);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620, maxHeight: 720),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const Icon(Icons.directions_bus_rounded, color: _green),
                    const SizedBox(width: 10),
                    Text(
                      widget.trip == null ? 'Add Scheduled Trip' : 'Edit Scheduled Trip',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: _ink),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close, size: 20),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(color: _line, height: 1),
                const SizedBox(height: 16),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextFormField(
                          controller: _titleController,
                          decoration: const InputDecoration(
                            labelText: 'Trip Route Title',
                            hintText: 'e.g. Local Trip to Bela Chowk and back',
                          ),
                          validator: (v) => (v == null || v.isEmpty) ? 'Enter title' : null,
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _departureController,
                                decoration: const InputDecoration(labelText: 'Departure Time (e.g. 08:15 AM)'),
                                validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextFormField(
                                controller: _arrivalController,
                                decoration: const InputDecoration(labelText: 'Arrival Time (e.g. 08:50 AM)'),
                                validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _regController,
                                decoration: const InputDecoration(labelText: 'Bus Reg Number (e.g. PB-12-Bus-01)'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextFormField(
                                controller: _seatsController,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(labelText: 'Total Seats'),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _noteController,
                          decoration: const InputDecoration(
                            labelText: 'Special Note (optional)',
                            hintText: 'e.g. Pickup done 10 min after train arrival',
                          ),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'INTERMEDIATE STOPS',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: _muted),
                            ),
                            TextButton.icon(
                              onPressed: _addStop,
                              icon: const Icon(Icons.add, size: 16),
                              label: const Text('Add Stop'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ..._stops.asMap().entries.map((entry) {
                          final idx = entry.key;
                          final stop = entry.value;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              children: [
                                Expanded(
                                  flex: 3,
                                  child: TextFormField(
                                    initialValue: stop.stopName,
                                    decoration: InputDecoration(
                                      labelText: 'Stop ${idx + 1}',
                                      isDense: true,
                                    ),
                                    onChanged: (val) {
                                      _stops[idx] = stop.copyWith(stopName: val);
                                    },
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  flex: 2,
                                  child: TextFormField(
                                    initialValue: stop.time,
                                    decoration: const InputDecoration(
                                      labelText: 'Time',
                                      isDense: true,
                                    ),
                                    onChanged: (val) {
                                      _stops[idx] = stop.copyWith(time: val);
                                    },
                                  ),
                                ),
                                if (_stops.length > 2) ...[
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                                    onPressed: () => _removeStop(idx),
                                  ),
                                ],
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 12),
                    FilledButton(
                      style: FilledButton.styleFrom(backgroundColor: _green),
                      onPressed: _submit,
                      child: const Text('Save Trip'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
