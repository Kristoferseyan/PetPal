import 'package:flutter/material.dart';
import 'package:petpal/services/appointment_service.dart';
import 'package:petpal/services/auth_service.dart';
import 'package:petpal/utils/colors.dart';
import 'package:intl/intl.dart';

class StaffAppointmentPage extends StatefulWidget {
  const StaffAppointmentPage({super.key});

  @override
  _StaffAppointmentPageState createState() => _StaffAppointmentPageState();
}

class _StaffAppointmentPageState extends State<StaffAppointmentPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> _appointments = [];
  List<Map<String, dynamic>> _pendingAppointments = [];
  List<Map<String, dynamic>> _ongoingAppointments = [];
  List<Map<String, dynamic>> _toPayAppointments = [];
  bool _isLoading = true;

  final AppointmentService _appointmentService = AppointmentService();
  final AuthService _authService = AuthService();

  Future<void> _loadAppointments() async {
    setState(() => _isLoading = true);

    try {
      final userDetails = await _authService.getUserDetails();
      if (userDetails != null) {
        final appointmentsForThisWeek =
            await _appointmentService.getAppointmentsForThisWeek();

        final pendingAppointments =
            await _appointmentService.getAllPendingAppointments();

        final ongoingAppointments =
            await _appointmentService.getOngoingAppointments();

        final toPayAppointments =
            await _appointmentService.getToPayAppointments();

        if (mounted) {
          setState(() {
            _appointments = appointmentsForThisWeek;
            _pendingAppointments = pendingAppointments;
            _ongoingAppointments = ongoingAppointments;
            _toPayAppointments = toPayAppointments;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading appointments: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _updateAppointmentStatus(
    String appointmentId,
    String newStatus,
  ) async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Updating appointment status...'),
          duration: Duration(milliseconds: 800),
        ),
      );

      await _appointmentService.updateAppointmentStatus(
        appointmentId,
        newStatus,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Appointment ${newStatus.toLowerCase()} successfully',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }

      _loadAppointments();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update status: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadAppointments();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 37, 45, 50),
      appBar: AppBar(
        iconTheme: IconThemeData(color: Colors.white),
        backgroundColor: Color.fromARGB(255, 44, 59, 70),
        title: const Text(
          'Appointments',
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          indicatorColor: AppColors.primary,
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(icon: Icon(Icons.pending_actions), text: 'Pending'),
            Tab(icon: Icon(Icons.event), text: 'This Week'),
            Tab(icon: Icon(Icons.play_circle_fill), text: 'Ongoing'),
            Tab(icon: Icon(Icons.payment), text: 'To Pay'),
          ],
        ),
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : TabBarView(
                controller: _tabController,
                children: [
                  _buildPendingAppointmentsTab(),

                  _buildWeeklyAppointmentsTab(),

                  _buildOngoingAppointmentsTab(),

                  _buildToPayAppointmentsTab(),
                ],
              ),
      floatingActionButton: FloatingActionButton(
        onPressed: _loadAppointments,
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.refresh),
        tooltip: 'Refresh appointments',
      ),
    );
  }

  Widget _buildPendingAppointmentsTab() {
    if (_pendingAppointments.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline, size: 64, color: Colors.grey[600]),
            const SizedBox(height: 16),
            Text(
              "No pending appointment requests",
              style: TextStyle(fontSize: 16, color: Colors.grey[400]),
            ),
            const SizedBox(height: 8),
            Text(
              "You're all caught up!",
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _pendingAppointments.length,
      itemBuilder: (context, index) {
        final appointment = _pendingAppointments[index];

        final String appointmentType =
            appointment['appointmentType'] ?? 'Check-up';
        final String operationType = appointment['operationType'] ?? '';

        return Card(
          color: const Color.fromARGB(255, 31, 38, 42),
          elevation: 4,
          margin: const EdgeInsets.only(bottom: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: const Color.fromARGB(255, 45, 55, 60),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.pets, size: 20, color: Colors.grey[400]),
                        const SizedBox(width: 8),
                        Text(
                          appointment['petName'],
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: _getAppointmentTypeColor(appointmentType),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        appointmentType,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (appointment['petImageUrl'] != null)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              appointment['petImageUrl'],
                              width: 80,
                              height: 80,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  width: 80,
                                  height: 80,
                                  color: Colors.grey[800],
                                  child: const Icon(
                                    Icons.pets,
                                    color: Colors.grey,
                                  ),
                                );
                              },
                            ),
                          ),
                        const SizedBox(width: 12),

                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Species: ${appointment['species']}",
                                style: TextStyle(color: Colors.grey[300]),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "Breed: ${appointment['breed']}",
                                style: TextStyle(color: Colors.grey[300]),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "Age: ${appointment['age']} ",
                                style: TextStyle(color: Colors.grey[300]),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),
                    const Divider(color: Color.fromARGB(255, 70, 80, 85)),
                    const SizedBox(height: 8),

                    Row(
                      children: [
                        Icon(Icons.person, size: 16, color: Colors.grey[400]),
                        const SizedBox(width: 8),
                        Text(
                          "Owner: ${appointment['ownerName']}",
                          style: TextStyle(color: Colors.grey[300]),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: 16,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(width: 8),
                        Text(
                          "Date: ${appointment['appointmentDate']}",
                          style: TextStyle(color: Colors.grey[300]),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 16,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(width: 8),
                        Text(
                          "Time: ${appointment['appointmentTime']}",
                          style: TextStyle(color: Colors.grey[300]),
                        ),
                      ],
                    ),

                    if (operationType.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(
                            Icons.medical_services,
                            size: 16,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(width: 8),
                          Text(
                            "Operation: $operationType",
                            style: TextStyle(
                              color: Colors.grey[300],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],

                    if (appointment['purpose']?.isNotEmpty ?? false) ...[
                      const SizedBox(height: 16),
                      Text(
                        "Additional Notes:",
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color.fromARGB(255, 45, 55, 60),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          appointment['purpose'],
                          style: TextStyle(
                            color: Colors.grey[300],
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: 20),

                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              _updateAppointmentStatus(
                                appointment['id'],
                                'approved',
                              );
                            },
                            icon: const Icon(Icons.check),
                            label: const Text('Approve'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              _updateAppointmentStatus(
                                appointment['id'],
                                'rejected',
                              );
                            },
                            icon: const Icon(Icons.close),
                            label: const Text('Reject'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.red,
                              side: const BorderSide(color: Colors.red),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildOngoingAppointmentsTab() {
    if (_ongoingAppointments.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.pending_actions, size: 64, color: Colors.grey[600]),
            const SizedBox(height: 16),
            Text(
              "No ongoing appointments",
              style: TextStyle(fontSize: 16, color: Colors.grey[400]),
            ),
            const SizedBox(height: 8),
            Text(
              "Ongoing appointments will appear here",
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _ongoingAppointments.length,
      itemBuilder: (context, index) {
        final appointment = _ongoingAppointments[index];

        final String appointmentType =
            appointment['appointmentType'] ?? 'Check-up';
        final String operationType = appointment['operationType'] ?? '';

        return Card(
          color: const Color(0xFF1F2323),
          elevation: 4,
          margin: const EdgeInsets.only(bottom: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.blue.withOpacity(0.5), width: 1.5),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.15),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.play_circle_fill,
                            color: Colors.blue,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          "IN PROGRESS",
                          style: TextStyle(
                            color: Colors.blue,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _getAppointmentTypeColor(appointmentType),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        appointmentType,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 70,
                          height: 70,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child:
                                appointment['petImageUrl'] != null
                                    ? Image.network(
                                      appointment['petImageUrl'],
                                      fit: BoxFit.cover,
                                      errorBuilder: (
                                        context,
                                        error,
                                        stackTrace,
                                      ) {
                                        return Container(
                                          color: const Color(0xFF2C3B46),
                                          child: const Icon(
                                            Icons.pets,
                                            color: Colors.white54,
                                            size: 30,
                                          ),
                                        );
                                      },
                                    )
                                    : Container(
                                      color: const Color(0xFF2C3B46),
                                      child: const Icon(
                                        Icons.pets,
                                        color: Colors.white54,
                                        size: 30,
                                      ),
                                    ),
                          ),
                        ),
                        const SizedBox(width: 16),

                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.pets,
                                    size: 16,
                                    color: Colors.grey[400],
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    appointment['petName'] ?? 'Unknown Pet',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),

                              Text(
                                "${appointment['species'] ?? 'Unknown'} ${appointment['breed'] != null ? '· ${appointment['breed']}' : ''}",
                                style: TextStyle(color: Colors.grey[300]),
                              ),
                              const SizedBox(height: 6),

                              Row(
                                children: [
                                  Icon(
                                    Icons.person,
                                    size: 14,
                                    color: Colors.grey[400],
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    "Owner: ${appointment['ownerName'] ?? 'Unknown Owner'}",
                                    style: TextStyle(color: Colors.grey[300]),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),

                              Row(
                                children: [
                                  Icon(
                                    Icons.calendar_today,
                                    size: 14,
                                    color: Colors.grey[400],
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    "${appointment['appointmentDate']} at ${appointment['appointmentTime']}",
                                    style: TextStyle(color: Colors.grey[300]),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    if (operationType.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.red.withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.medical_services,
                              size: 18,
                              color: Colors.redAccent,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                "Operation: $operationType",
                                style: const TextStyle(
                                  color: Colors.redAccent,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    if (appointment['purpose']?.isNotEmpty ?? false) ...[
                      const SizedBox(height: 16),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Notes:",
                              style: TextStyle(
                                color: Colors.white70,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              appointment['purpose'],
                              style: const TextStyle(
                                color: Colors.white70,
                                fontStyle: FontStyle.italic,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 16),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          _updateAppointmentStatus(appointment['id'], 'to pay');
                        },
                        icon: const Icon(Icons.check_circle, size: 20),
                        label: const Text(
                          'Complete Appointment',
                          style: TextStyle(fontSize: 16),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildWeeklyAppointmentsTab() {
    if (_appointments.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_busy, size: 64, color: Colors.grey[600]),
            const SizedBox(height: 16),
            Text(
              "No appointments scheduled for this week",
              style: TextStyle(fontSize: 16, color: Colors.grey[400]),
            ),
          ],
        ),
      );
    }

    Map<String, List<Map<String, dynamic>>> groupedAppointments = {};

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    for (var appointment in _appointments) {
      final date = appointment['appointmentDate'];

      final appointmentDate = DateFormat('yyyy-MM-dd').parse(date);
      if (appointmentDate.isBefore(today)) {
        continue;
      }

      if (appointment['appointmentTime'] != null) {
        try {
          final timeObj = DateFormat(
            'HH:mm',
          ).parse(appointment['appointmentTime']);
          appointment['formattedTime'] = DateFormat('h:mm a').format(timeObj);
        } catch (e) {
          appointment['formattedTime'] = appointment['appointmentTime'];
        }
      } else {
        appointment['formattedTime'] = 'Not specified';
      }

      if (!groupedAppointments.containsKey(date)) {
        groupedAppointments[date] = [];
      }
      groupedAppointments[date]?.add(appointment);
    }

    if (groupedAppointments.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_busy, size: 64, color: Colors.grey[600]),
            const SizedBox(height: 16),
            Text(
              "No upcoming appointments scheduled",
              style: TextStyle(fontSize: 16, color: Colors.grey[400]),
            ),
            const SizedBox(height: 8),
            Text(
              "All scheduled appointments are in the past",
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    final sortedEntries =
        groupedAppointments.entries.toList()..sort((a, b) {
          final dateA = DateFormat('yyyy-MM-dd').parse(a.key);
          final dateB = DateFormat('yyyy-MM-dd').parse(b.key);
          return dateA.compareTo(dateB);
        });

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: sortedEntries.length,
      itemBuilder: (context, index) {
        final entry = sortedEntries[index];
        final dateStr = entry.key;
        final appointments = entry.value;

        final date = DateFormat('yyyy-MM-dd').parse(dateStr);
        final formattedDate = DateFormat('EEEE, MMMM d').format(date);

        final isToday =
            date.year == now.year &&
            date.month == now.month &&
            date.day == now.day;

        final difference = date.difference(today).inDays;
        String dayIndicator = '';

        if (isToday) {
          dayIndicator = 'TODAY';
        } else if (difference == 1) {
          dayIndicator = 'TOMORROW';
        } else if (difference < 7) {
          dayIndicator = 'IN $difference DAYS';
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color:
                          isToday ? AppColors.primary : const Color(0xFF2C3B46),
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      formattedDate,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (dayIndicator.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: isToday ? Colors.green : Colors.amber,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        dayIndicator,
                        style: TextStyle(
                          color: isToday ? Colors.white : Colors.black87,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            ...appointments.map((appointment) {
              final String appointmentType =
                  appointment['appointmentType'] ?? 'Check-up';
              final String operationType = appointment['operationType'] ?? '';

              return Card(
                color: const Color(0xFF1F2323),
                elevation: 3,
                margin: const EdgeInsets.only(bottom: 16, left: 8, right: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: _getAppointmentTypeColor(
                      appointmentType,
                    ).withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF252D32),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(16),
                          topRight: Radius.circular(16),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: _getAppointmentTypeColor(
                                    appointmentType,
                                  ).withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  _getAppointmentTypeIcon(appointmentType),
                                  size: 18,
                                  color: _getAppointmentTypeColor(
                                    appointmentType,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                appointment['formattedTime'],
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: _getAppointmentTypeColor(appointmentType),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              appointmentType,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 70,
                                height: 70,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child:
                                      appointment['petImageUrl'] != null
                                          ? Image.network(
                                            appointment['petImageUrl'],
                                            fit: BoxFit.cover,
                                            errorBuilder: (
                                              context,
                                              error,
                                              stackTrace,
                                            ) {
                                              return Container(
                                                color: const Color(0xFF2C3B46),
                                                child: const Icon(
                                                  Icons.pets,
                                                  color: Colors.white54,
                                                  size: 30,
                                                ),
                                              );
                                            },
                                          )
                                          : Container(
                                            color: const Color(0xFF2C3B46),
                                            child: const Icon(
                                              Icons.pets,
                                              color: Colors.white54,
                                              size: 30,
                                            ),
                                          ),
                                ),
                              ),
                              const SizedBox(width: 16),

                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      appointment['petName'] ?? 'Unknown Pet',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    RichText(
                                      text: TextSpan(
                                        style: const TextStyle(
                                          color: Colors.white70,
                                        ),
                                        children: [
                                          TextSpan(
                                            text:
                                                appointment['species'] ??
                                                'Unknown',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          if (appointment['breed'] != null &&
                                              appointment['breed']
                                                  .toString()
                                                  .isNotEmpty)
                                            TextSpan(
                                              text:
                                                  ' · ${appointment['breed']}',
                                            ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.person,
                                          size: 14,
                                          color: Colors.white54,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          appointment['ownerName'] ??
                                              'Unknown Owner',
                                          style: const TextStyle(
                                            color: Colors.white70,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),

                          if (operationType.isNotEmpty) ...[
                            const SizedBox(height: 16),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.red.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.red.withOpacity(0.3),
                                ),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.medical_services,
                                    size: 18,
                                    color: Colors.redAccent,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      "Operation: $operationType",
                                      style: const TextStyle(
                                        color: Colors.redAccent,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],

                          if (appointment['purpose']?.isNotEmpty ?? false) ...[
                            const SizedBox(height: 16),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.05),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    "Notes:",
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    appointment['purpose'],
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontStyle: FontStyle.italic,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],

                          const SizedBox(height: 16),

                          _buildAppointmentStatusActions(appointment),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),

            const SizedBox(height: 24),
          ],
        );
      },
    );
  }

  Widget _buildToPayAppointmentsTab() {
    if (_toPayAppointments.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.payment, size: 64, color: Colors.grey[600]),
            const SizedBox(height: 16),
            Text(
              "No payments pending",
              style: TextStyle(fontSize: 16, color: Colors.grey[400]),
            ),
            const SizedBox(height: 8),
            Text(
              "Completed appointments awaiting payment will appear here",
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _toPayAppointments.length,
      itemBuilder: (context, index) {
        final appointment = _toPayAppointments[index];

        final String appointmentType =
            appointment['appointmentType'] ?? 'Check-up';
        final String operationType = appointment['operationType'] ?? '';

        return Card(
          color: const Color(0xFF1F2323),
          elevation: 4,
          margin: const EdgeInsets.only(bottom: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.amber.withOpacity(0.5), width: 1.5),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.15),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.amber.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.payment,
                            color: Colors.amber,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          "AWAITING PAYMENT",
                          style: TextStyle(
                            color: Colors.amber,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _getAppointmentTypeColor(appointmentType),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        appointmentType,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 70,
                          height: 70,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child:
                                appointment['petImageUrl'] != null
                                    ? Image.network(
                                      appointment['petImageUrl'],
                                      fit: BoxFit.cover,
                                      errorBuilder: (
                                        context,
                                        error,
                                        stackTrace,
                                      ) {
                                        return Container(
                                          color: Colors.grey[800],
                                          child: const Icon(
                                            Icons.pets,
                                            color: Colors.grey,
                                          ),
                                        );
                                      },
                                    )
                                    : Container(
                                      color: Colors.grey[800],
                                      child: const Icon(
                                        Icons.pets,
                                        color: Colors.grey,
                                      ),
                                    ),
                          ),
                        ),
                        const SizedBox(width: 16),

                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                appointment['petName'] ?? 'Unknown Pet',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "${appointment['species'] ?? 'Unknown'} ${appointment['breed'] != null ? '· ${appointment['breed']}' : ''}",
                                style: TextStyle(color: Colors.grey[300]),
                              ),
                              const SizedBox(height: 6),

                              Row(
                                children: [
                                  Icon(
                                    Icons.person,
                                    size: 14,
                                    color: Colors.grey[400],
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    "Owner: ${appointment['ownerName'] ?? 'Unknown Owner'}",
                                    style: TextStyle(color: Colors.grey[300]),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),

                              Row(
                                children: [
                                  Icon(
                                    Icons.calendar_today,
                                    size: 14,
                                    color: Colors.grey[400],
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    "${appointment['appointmentDate']} at ${appointment['appointmentTime']}",
                                    style: TextStyle(color: Colors.grey[300]),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    if (operationType.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.red.withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.medical_services,
                              size: 18,
                              color: Colors.redAccent,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                "Operation: $operationType",
                                style: const TextStyle(
                                  color: Colors.redAccent,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    if (appointment['purpose']?.isNotEmpty ?? false) ...[
                      const SizedBox(height: 16),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Notes:",
                              style: TextStyle(
                                color: Colors.white70,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              appointment['purpose'],
                              style: const TextStyle(
                                color: Colors.white70,
                                fontStyle: FontStyle.italic,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 16),

                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Colors.amber.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: Colors.amber.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.payment, color: Colors.amber, size: 18),
                          SizedBox(width: 8),
                          Text(
                            'Awaiting Payment',
                            style: TextStyle(
                              color: Colors.amber,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Color _getAppointmentTypeColor(String type) {
    switch (type) {
      case 'Check-up':
        return Colors.teal;
      case 'Vaccination':
        return Colors.blueAccent;
      case 'Operation':
        return Colors.redAccent;
      case 'Grooming':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  Widget _buildAppointmentStatusActions(Map<String, dynamic> appointment) {
    final String status = appointment['status'] ?? 'pending';

    switch (status) {
      case 'approved':
        return ElevatedButton.icon(
          onPressed: () {
            _updateAppointmentStatus(appointment['id'], 'on-going');
          },
          icon: const Icon(Icons.play_circle_outline, size: 18),
          label: const Text('Start Session'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2196F3),
            foregroundColor: Colors.white,
            elevation: 2,
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );

      case 'on-going':
        return ElevatedButton.icon(
          onPressed: () {
            _updateAppointmentStatus(appointment['id'], 'to pay');
          },
          icon: const Icon(Icons.check_circle_outline, size: 18),
          label: const Text('Mark as To Pay'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
            elevation: 2,
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );

      case 'to pay':
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 12),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.amber.withOpacity(0.2),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.amber.withOpacity(0.3)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.payment, color: Colors.amber, size: 18),
              SizedBox(width: 8),
              Text(
                'Awaiting Payment',
                style: TextStyle(
                  color: Colors.amber,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        );

      case 'completed':
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 12),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.green.withOpacity(0.2),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.green.withOpacity(0.3)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.check_circle, color: Colors.green, size: 18),
              SizedBox(width: 8),
              Text(
                'Completed',
                style: TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        );

      default:
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 12),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.orange.withOpacity(0.2),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.orange.withOpacity(0.3)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.access_time, color: Colors.orange, size: 18),
              SizedBox(width: 8),
              Text(
                'Pending',
                style: TextStyle(
                  color: Colors.orange,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        );
    }
  }

  IconData _getAppointmentTypeIcon(String type) {
    switch (type) {
      case 'Check-up':
        return Icons.health_and_safety;
      case 'Vaccination':
        return Icons.vaccines;
      case 'Operation':
        return Icons.medical_services;
      case 'Grooming':
        return Icons.spa;
      default:
        return Icons.pets;
    }
  }
}
