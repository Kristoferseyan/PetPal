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
    _tabController = TabController(length: 3, vsync: this);
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
    if (_ownerId == null) return;

    try {
      final appointments = await _appointmentService.getAppointments(_ownerId!);
      if (mounted) {
        setState(() {
          _appointments = appointments;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = "Failed to load appointments";
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
    if (appointment['status'] == 'Approved' &&
        !_isUpcoming(appointment['rawDate'])) {
      return 'Missed';
    }
    return appointment['status'];
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
              Navigator.of(context).pop();

              try {
                await _appointmentService.updateAppointmentStatus(
                  appointment['id'],
                  'Completed',
                );
              } catch (e) {}

              await _loadAppointments();

              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Payment completed successfully!'),
                    backgroundColor: Colors.green,
                  ),
                );
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
          final status = appointment['status'];
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
          final status = appointment['status'];
          return status == 'To Pay' || status == 'Completed';
        }).toList();

    if (paymentAppointments.isEmpty) {
      return _buildEmptyState(
        icon: Icons.payment,
        title: "No Payment Records",
        subtitle:
            "Completed appointments with payment information will appear here",
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

  Widget _buildHistoryTab() {
    final historyAppointments =
        _appointments.where((appointment) {
          final status = appointment['status'];
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
                    color: status == 'Completed' ? Colors.green : Colors.amber,
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

            if (status == 'To Pay') ...[
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
                        border: Border.all(
                          color: Colors.amber.withOpacity(0.5),
                        ),
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
            ] else if (status == 'Completed') ...[
              PaymentStatusWidget(appointmentId: appointment['id']),
            ],
          ],
        ),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 22, 28, 32),
      appBar: AppBar(
        title: const Text(
          'My Appointments',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color.fromARGB(255, 22, 28, 32),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(icon: Icon(Icons.event_available), text: 'Active'),
            Tab(icon: Icon(Icons.payment), text: 'Payment'),
            Tab(icon: Icon(Icons.history), text: 'History'),
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
                  _buildHistoryTab(),
                ],
              ),
    );
  }
}
