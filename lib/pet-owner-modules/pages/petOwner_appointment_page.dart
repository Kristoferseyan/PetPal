import 'package:flutter/material.dart';
import 'package:petpal/pet-owner-modules/appointment-components/create_appointment_dialog.dart';
import 'package:petpal/services/appointment_service.dart';
import 'package:petpal/services/auth_service.dart';
import 'package:petpal/services/medical_service.dart';
import 'package:petpal/utils/colors.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:petpal/widgets/payment_status_widget.dart';
import 'package:petpal/widgets/payment_dialog.dart';
import 'dart:convert';

class PetOwnerAppointmentsPage extends StatefulWidget {
  const PetOwnerAppointmentsPage({super.key});

  @override
  State<PetOwnerAppointmentsPage> createState() =>
      _PetOwnerAppointmentsPageState();
}

class _PetOwnerAppointmentsPageState extends State<PetOwnerAppointmentsPage>
    with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  bool _hasError = false;
  String? _errorMessage;
  List<Map<String, dynamic>> _appointments = [];

  late TabController _tabController;

  final AuthService _authService = AuthService();
  final AppointmentService _appointmentService = AppointmentService();
  final MedicalService _medicalService = MedicalService();
  String? _ownerId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _initialize();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _initialize() async {
    try {
      setState(() {
        _isLoading = true;
        _hasError = false;
      });

      final userDetails = await _authService.getUserDetails();
      if (userDetails != null) {
        _ownerId = userDetails['id'];
        await _loadAppointments();
      }
    } catch (e) {
      setState(() {
        _hasError = true;
        _errorMessage = "Failed to initialize app data";
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadAppointments() async {
    if (_ownerId == null) {
      return;
    }

    try {
      final appointments = await _appointmentService.getAppointments(_ownerId!);

      if (mounted) {
        setState(() {
          _appointments = List<Map<String, dynamic>>.from(appointments)
            ..sort((a, b) {
              String? aTimestamp = a['updated_at'] ?? a['rawDate'];
              String? bTimestamp = b['updated_at'] ?? b['rawDate'];

              if (aTimestamp == null && bTimestamp == null) return 0;
              if (aTimestamp == null) return 1;
              if (bTimestamp == null) return -1;

              try {
                final aUpdated = DateTime.parse(aTimestamp);
                final bUpdated = DateTime.parse(bTimestamp);
                return bUpdated.compareTo(aUpdated);
              } catch (e) {
                return 0;
              }
            });
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = "Failed to load appointments: $e";
        });
      }
    }
  }

  void _showCreateAppointmentDialog() {
    showDialog(
      context: context,
      builder:
          (context) => CreateAppointmentDialog(
            ownerId: _ownerId!,
            onAppointmentCreated: () {
              _loadAppointments();
            },
          ),
    );
  }

  void _showCancelDialog(String appointmentId) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: const Color.fromARGB(255, 45, 55, 60),
            title: const Text(
              'Cancel Appointment',
              style: TextStyle(color: Colors.white),
            ),
            content: const Text(
              'Are you sure you want to cancel this appointment? This action cannot be undone.',
              style: TextStyle(color: Colors.white70),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text(
                  'No, Keep It',
                  style: TextStyle(color: Colors.white70),
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _cancelAppointment(appointmentId);
                },
                child: const Text(
                  'Yes, Cancel',
                  style: TextStyle(color: Colors.redAccent),
                ),
              ),
            ],
          ),
    );
  }

  Future<void> _cancelAppointment(String appointmentId) async {
    try {
      await _appointmentService.cancelAppointment(appointmentId, context);
      _loadAppointments();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to cancel appointment: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _archiveAppointment(String appointmentId) async {
    try {
      await _appointmentService.updateAppointmentStatus(
        appointmentId,
        'archived',
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Appointment archived successfully'),
          backgroundColor: Colors.green,
        ),
      );

      _loadAppointments();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error archiving appointment: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _unarchiveAppointment(String appointmentId) async {
    try {
      await _appointmentService.updateAppointmentStatus(
        appointmentId,
        'completed',
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Appointment restored successfully'),
          backgroundColor: Colors.green,
        ),
      );

      _loadAppointments();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error restoring appointment: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showArchiveDialog(Map<String, dynamic> appointment) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: const Color.fromARGB(255, 45, 55, 60),
            title: const Text(
              'Archive Appointment',
              style: TextStyle(color: Colors.white),
            ),
            content: Text(
              'Are you sure you want to archive this appointment?\n\n'
              'Pet: ${appointment['petName'] ?? 'Unknown'}\n'
              'Purpose: ${appointment['purpose'] ?? 'N/A'}\n'
              'Date: ${appointment['appointmentDate']}',
              style: const TextStyle(color: Colors.white70),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text(
                  'Cancel',
                  style: TextStyle(color: Colors.white70),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _archiveAppointment(appointment['id']);
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                child: const Text('Archive'),
              ),
            ],
          ),
    );
  }

  bool _isUpcoming(String? rawDate) {
    if (rawDate == null) return false;
    try {
      final appointmentDate = DateTime.parse(rawDate);
      final now = DateTime.now();
      return appointmentDate.isAfter(now);
    } catch (e) {
      return false;
    }
  }

  String _getDisplayStatus(Map<String, dynamic> appointment) {
    if (_normalizeStatus(appointment['status']) == 'Approved' &&
        !_isUpcoming(appointment['rawDate'])) {
      return 'Missed';
    }
    return _normalizeStatus(appointment['status']);
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Approved':
        return Colors.green;
      case 'On-Going':
        return Colors.blue;
      case 'To Pay':
        return Colors.amber;
      case 'Completed':
        return Colors.green;
      case 'Missed':
        return Colors.orange;
      case 'Pending':
        return Colors.amber;
      case 'Rejected':
        return Colors.red;
      case 'Cancelled':
        return Colors.grey;
      default:
        return Colors.grey;
    }
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

  Future<void> _showPaymentDialog(Map<String, dynamic> appointment) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => PaymentDialog(
            appointmentId: appointment['id'],
            petOwnerId: _ownerId!,
            appointmentType:
                appointment['details']?['appointment_type'] ?? 'Check-up',
            petName: appointment['petName'] ?? 'Unknown Pet',
            onPaymentCompleted: () async {
              final mainContext = this.context;

              Navigator.of(context).pop();

              try {
                await _appointmentService.updateAppointmentStatus(
                  appointment['id'],
                  'completed',
                );
              } catch (e) {}

              if (mounted && mainContext.mounted) {
                ScaffoldMessenger.of(mainContext).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Payment completed successfully! Redirecting to home...',
                    ),
                    backgroundColor: Colors.green,
                    duration: Duration(seconds: 2),
                  ),
                );

                Future.delayed(const Duration(milliseconds: 500), () {
                  if (mainContext.mounted) {
                    Navigator.of(mainContext).pushNamedAndRemoveUntil(
                      '/pet-owner-home',
                      (route) => false,
                    );
                  }
                });
              }
            },
          ),
    );
  }

  Future<bool> _hasPaymentRecord(String appointmentId) async {
    try {
      final payment = await _medicalService.getPaymentForAppointment(
        appointmentId,
      );
      return payment != null;
    } catch (e) {
      return false;
    }
  }

  String _formatTimeWithAMPM(String? time) {
    if (time == null || time.isEmpty) return 'No time specified';

    try {
      final parts = time.split(':');
      if (parts.length != 2) return time;

      int hour = int.parse(parts[0]);
      int minute = int.parse(parts[1]);

      String period = hour >= 12 ? 'PM' : 'AM';

      if (hour > 12) {
        hour -= 12;
      } else if (hour == 0) {
        hour = 12;
      }

      return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')} $period';
    } catch (e) {
      return time;
    }
  }

  String _generateAppointmentQRData(Map<String, dynamic> appointment) {
    final qrData = {
      'type': 'appointment',
      'appointmentId': appointment['id'],
      'petName': appointment['petName'],
      'ownerId': _ownerId,
      'appointmentDate': appointment['appointmentDate'],
      'appointmentTime': appointment['appointmentTime'],
      'appointmentType':
          appointment['details']?['appointment_type'] ?? 'Check-up',
      'status': appointment['status'],
    };

    return jsonEncode(qrData);
  }

  void _showQRCodeDialog(
    BuildContext context,
    Map<String, dynamic> appointment,
  ) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: const Color.fromARGB(255, 45, 55, 60),
            title: const Text(
              'Appointment QR Code',
              style: TextStyle(color: Colors.white),
            ),
            content: Container(
              width: 250,
              height: 250,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: QrImageView(
                data: _generateAppointmentQRData(appointment),
                version: QrVersions.auto,
                backgroundColor: Colors.white,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text(
                  'Close',
                  style: TextStyle(color: Colors.white70),
                ),
              ),
            ],
          ),
    );
  }

  Widget _buildActiveAppointmentsTab() {
    final activeAppointments =
        _appointments.where((appointment) {
          final status = _normalizeStatus(appointment['status']);
          return status == 'Pending' ||
              status == 'Approved' ||
              status == 'On-Going' ||
              status == 'To Pay';
        }).toList();

    if (activeAppointments.isEmpty) {
      return _buildEmptyState(
        icon: Icons.event_available,
        title: "No Active Appointments",
        subtitle: "You don't have any pending or upcoming appointments",
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: activeAppointments.length,
      itemBuilder: (context, index) {
        return _buildAppointmentCard(activeAppointments[index]);
      },
    );
  }

  Widget _buildPaymentTab() {
    final paymentAppointments =
        _appointments.where((appointment) {
          final status = _normalizeStatus(appointment['status']);
          return status == 'To Pay';
        }).toList();

    if (paymentAppointments.isEmpty) {
      return _buildEmptyState(
        icon: Icons.payment,
        title: "No Pending Payments",
        subtitle: "Appointments that require payment will appear here",
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: paymentAppointments.length,
      itemBuilder: (context, index) {
        return _buildPaymentAppointmentCard(paymentAppointments[index]);
      },
    );
  }

  Widget _buildCompletedTab() {
    final completedAppointments =
        _appointments.where((appointment) {
          final status = _normalizeStatus(appointment['status']);
          return status == 'Completed';
        }).toList();

    if (completedAppointments.isEmpty) {
      return _buildEmptyState(
        icon: Icons.check_circle,
        title: "No Completed Appointments",
        subtitle: "Completed and paid appointments will appear here",
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: completedAppointments.length,
      itemBuilder: (context, index) {
        return _buildCompletedAppointmentCard(completedAppointments[index]);
      },
    );
  }

  Widget _buildHistoryTab() {
    final historyAppointments =
        _appointments.where((appointment) {
          final status = _normalizeStatus(appointment['status']);
          return status == 'Rejected' ||
              status == 'Cancelled' ||
              _getDisplayStatus(appointment) == 'Missed';
        }).toList();

    if (historyAppointments.isEmpty) {
      return _buildEmptyState(
        icon: Icons.history,
        title: "No History",
        subtitle: "Past appointments and cancellations will appear here",
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: historyAppointments.length,
      itemBuilder: (context, index) {
        return _buildCompactAppointmentCard(historyAppointments[index]);
      },
    );
  }

  Widget _buildArchivedTab() {
    final archivedAppointments =
        _appointments
            .where(
              (appointment) =>
                  _normalizeStatus(appointment['status']) == 'Archived',
            )
            .toList();

    if (archivedAppointments.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.archive_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No archived appointments',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            SizedBox(height: 8),
            Text(
              'Completed appointments can be archived for better organization',
              style: TextStyle(fontSize: 14, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: archivedAppointments.length,
      itemBuilder: (context, index) {
        final appointment = archivedAppointments[index];
        return _buildArchivedAppointmentCard(appointment);
      },
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 80, color: Colors.grey[600]),
            const SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppointmentCard(Map<String, dynamic> appointment) {
    final String appointmentType =
        appointment['details']?['appointment_type'] ?? 'Check-up';
    final String operationType =
        appointmentType == 'Operation'
            ? (appointment['details']?['operation_type'] ?? '')
            : '';
    final String status = appointment['status'];

    return Card(
      color: const Color.fromARGB(255, 31, 38, 42),
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: _getStatusColor(status).withOpacity(0.5),
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              color: _getStatusColor(status).withOpacity(0.2),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                _getStatusIcon(status),
                const SizedBox(width: 8),
                Text(
                  status,
                  style: TextStyle(
                    color: _getStatusColor(status),
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
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
                      fontSize: 11,
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
                  children: [
                    Icon(Icons.pets, size: 20, color: Colors.grey[400]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        appointment['petName'] ?? 'Unknown Pet',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                Row(
                  children: [
                    Icon(Icons.schedule, size: 16, color: Colors.grey[400]),
                    const SizedBox(width: 8),
                    Text(
                      "${appointment['appointmentDate']} at ${_formatTimeWithAMPM(appointment['appointmentTime'])}",
                      style: TextStyle(color: Colors.grey[300], fontSize: 14),
                    ),
                  ],
                ),

                if (operationType.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.medical_services,
                        size: 16,
                        color: Colors.redAccent,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "Operation: $operationType",
                        style: const TextStyle(
                          color: Colors.redAccent,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ],

                if (appointment['purpose']?.isNotEmpty ?? false) ...[
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.note, size: 16, color: Colors.grey[400]),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          appointment['purpose'],
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontStyle: FontStyle.italic,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],

                _buildActionButtons(appointment),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentAppointmentCard(Map<String, dynamic> appointment) {
    final String appointmentType =
        appointment['details']?['appointment_type'] ?? 'Check-up';
    final String status = appointment['status'];

    return Card(
      color: const Color.fromARGB(255, 31, 38, 42),
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.pets, size: 18, color: Colors.grey[400]),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    appointment['petName'] ?? 'Unknown Pet',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.amber,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    status,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            Text(
              "${appointment['appointmentDate']} • $appointmentType",
              style: TextStyle(color: Colors.grey[400], fontSize: 14),
            ),

            const SizedBox(height: 12),

            FutureBuilder<bool>(
              future: _hasPaymentRecord(appointment['id']),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  );
                }

                final hasPayment = snapshot.data ?? false;
                if (!hasPayment) {
                  return SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _showPaymentDialog(appointment),
                      icon: const Icon(Icons.payment, size: 18),
                      label: const Text('Pay Now'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  );
                } else {
                  return Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.amber.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.amber.withOpacity(0.5)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.pending, color: Colors.amber, size: 16),
                        const SizedBox(width: 8),
                        Text(
                          'Payment Processing',
                          style: TextStyle(color: Colors.amber, fontSize: 12),
                        ),
                      ],
                    ),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompletedAppointmentCard(Map<String, dynamic> appointment) {
    final String appointmentType =
        appointment['details']?['appointment_type'] ?? 'Check-up';
    final String operationType =
        appointmentType == 'Operation'
            ? (appointment['details']?['operation_type'] ?? '')
            : '';

    return Card(
      color: const Color.fromARGB(255, 31, 38, 42),
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.green.withOpacity(0.5), width: 1.5),
      ),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.2),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: 16),
                const SizedBox(width: 8),
                Text(
                  'Completed & Paid',
                  style: TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const Spacer(),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'archive') {
                      _showArchiveDialog(appointment);
                    }
                  },
                  itemBuilder:
                      (context) => [
                        const PopupMenuItem(
                          value: 'archive',
                          child: Row(
                            children: [
                              Icon(
                                Icons.archive,
                                size: 16,
                                color: Colors.orange,
                              ),
                              SizedBox(width: 8),
                              Text('Archive'),
                            ],
                          ),
                        ),
                      ],
                  child: const Icon(Icons.more_vert, color: Colors.white70),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
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
                      fontSize: 11,
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
                  children: [
                    Icon(Icons.pets, size: 20, color: Colors.grey[400]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        appointment['petName'] ?? 'Unknown Pet',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                Row(
                  children: [
                    Icon(Icons.schedule, size: 16, color: Colors.grey[400]),
                    const SizedBox(width: 8),
                    Text(
                      "${appointment['appointmentDate']} at ${_formatTimeWithAMPM(appointment['appointmentTime'])}",
                      style: TextStyle(color: Colors.grey[300], fontSize: 14),
                    ),
                  ],
                ),

                if (operationType.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.medical_services,
                        size: 16,
                        color: Colors.redAccent,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "Operation: $operationType",
                        style: const TextStyle(
                          color: Colors.redAccent,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ],

                if (appointment['purpose']?.isNotEmpty ?? false) ...[
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.note, size: 16, color: Colors.grey[400]),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          appointment['purpose'],
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontStyle: FontStyle.italic,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],

                const SizedBox(height: 16),
                const Divider(color: Colors.grey),
                const SizedBox(height: 8),
                PaymentStatusWidget(appointmentId: appointment['id']),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactAppointmentCard(Map<String, dynamic> appointment) {
    final String appointmentType =
        appointment['details']?['appointment_type'] ?? 'Check-up';
    final String displayStatus = _getDisplayStatus(appointment);

    return Card(
      color: const Color.fromARGB(255, 31, 38, 42),
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 8,
              height: 40,
              decoration: BoxDecoration(
                color: _getStatusColor(displayStatus).withOpacity(0.7),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    appointment['petName'] ?? 'Unknown Pet',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    "${appointment['appointmentDate']} • $appointmentType",
                    style: TextStyle(color: Colors.grey[400], fontSize: 12),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _getStatusColor(displayStatus).withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                displayStatus,
                style: TextStyle(
                  color: _getStatusColor(displayStatus),
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildArchivedAppointmentCard(Map<String, dynamic> appointment) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: const Color.fromARGB(255, 31, 38, 42),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'ARCHIVED',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.black54,
                    ),
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => _unarchiveAppointment(appointment['id']),
                  icon: const Icon(Icons.unarchive, color: Colors.blue),
                  tooltip: 'Restore appointment',
                ),
              ],
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                const Icon(Icons.pets, color: Colors.grey),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    appointment['petName'] ?? 'Unknown Pet',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            Row(
              children: [
                const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Text(
                  appointment['appointmentDate'] ?? 'No date',
                  style: const TextStyle(color: Colors.grey),
                ),
                const SizedBox(width: 16),
                const Icon(Icons.access_time, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Text(
                  _formatTimeWithAMPM(appointment['appointmentTime']),
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),

            if (appointment['purpose']?.isNotEmpty ?? false) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(
                    Icons.medical_services,
                    size: 16,
                    color: Colors.grey,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      appointment['purpose'],
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 12),
            PaymentStatusWidget(appointmentId: appointment['id']),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(Map<String, dynamic> appointment) {
    final String status = appointment['status'];

    if (status == 'Pending' ||
        (status == 'Approved' && _isUpcoming(appointment['rawDate']))) {
      return Column(
        children: [
          const SizedBox(height: 16),
          const Divider(color: Colors.grey),
          const SizedBox(height: 8),
          Row(
            children: [
              if (status == 'Approved') ...[
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showQRCodeDialog(context, appointment),
                    icon: const Icon(Icons.qr_code, size: 16),
                    label: const Text('QR Code'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white70,
                      side: BorderSide(color: Colors.grey[600]!),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _showCancelDialog(appointment['id']),
                  icon: const Icon(Icons.cancel, size: 16),
                  label: const Text('Cancel'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.redAccent,
                    side: const BorderSide(color: Colors.redAccent),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      );
    }

    return const SizedBox.shrink();
  }

  Widget _getStatusIcon(String status) {
    switch (status) {
      case 'Pending':
        return Icon(
          Icons.hourglass_empty,
          color: _getStatusColor(status),
          size: 16,
        );
      case 'Approved':
        return Icon(
          Icons.check_circle,
          color: _getStatusColor(status),
          size: 16,
        );
      case 'On-Going':
        return Icon(
          Icons.play_circle_fill,
          color: _getStatusColor(status),
          size: 16,
        );
      case 'To Pay':
        return Icon(Icons.payment, color: _getStatusColor(status), size: 16);
      default:
        return Icon(Icons.info, color: _getStatusColor(status), size: 16);
    }
  }

  String _normalizeStatus(String? status) {
    if (status == null) return '';

    final lowercased = status.toLowerCase();

    switch (lowercased) {
      case 'pending':
        return 'Pending';
      case 'approved':
        return 'Approved';
      case 'on-going':
      case 'ongoing':
      case 'on going':
        return 'On-Going';
      case 'to pay':
      case 'to_pay':
        return 'To Pay';
      case 'completed':
        return 'Completed';
      case 'rejected':
        return 'Rejected';
      case 'cancelled':
        return 'Cancelled';
      case 'archived':
        return 'Archived';
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 37, 45, 50),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        iconTheme: IconThemeData(color: Colors.white),
        title: const Text(
          'My Appointments',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Color.fromARGB(255, 44, 59, 70),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: Colors.grey,
          padding: EdgeInsets.zero,
          tabAlignment: TabAlignment.start,
          tabs: const [
            Tab(icon: Icon(Icons.event_available), text: 'Active'),
            Tab(icon: Icon(Icons.payment), text: 'Payment'),
            Tab(icon: Icon(Icons.check_circle), text: 'Completed'),
            Tab(icon: Icon(Icons.history), text: 'History'),
            Tab(icon: Icon(Icons.archive), text: 'Archive'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white),
            onPressed: _ownerId != null ? _showCreateAppointmentDialog : null,
            tooltip: 'Create New Appointment',
          ),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _hasError
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _errorMessage ?? 'An error occurred',
                      style: TextStyle(color: Colors.grey[400], fontSize: 16),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _initialize,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              )
              : TabBarView(
                controller: _tabController,
                children: [
                  _buildActiveAppointmentsTab(),
                  _buildPaymentTab(),
                  _buildCompletedTab(),
                  _buildHistoryTab(),
                  _buildArchivedTab(),
                ],
              ),
    );
  }
}
