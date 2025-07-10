import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:petpal/services/medical_service.dart';
import 'package:petpal/utils/colors.dart';

class PaymentStatusWidget extends StatefulWidget {
  final String appointmentId;
  final VoidCallback? onPaymentStatusChanged;

  const PaymentStatusWidget({
    Key? key,
    required this.appointmentId,
    this.onPaymentStatusChanged,
  }) : super(key: key);

  @override
  _PaymentStatusWidgetState createState() => _PaymentStatusWidgetState();
}

class _PaymentStatusWidgetState extends State<PaymentStatusWidget> {
  final MedicalService _medicalService = MedicalService();
  Map<String, dynamic>? _paymentData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPaymentStatus();
  }

  Future<void> refreshPaymentStatus() async {
    await _loadPaymentStatus();
  }

  Future<void> _loadPaymentStatus() async {
    setState(() {
      _isLoading = true;
    });

    try {
      print(
        '🔄 Loading payment status for appointment: ${widget.appointmentId}',
      );

      final payment = await _medicalService.getPaymentForAppointment(
        widget.appointmentId,
      );

      if (payment != null) {
      } else {}

      setState(() {
        _paymentData = payment;
        _isLoading = false;
      });

      if (widget.onPaymentStatusChanged != null) {
        widget.onPaymentStatusChanged!();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'succeeded':
      case 'paid':
        return Colors.green;
      case 'pending':
        return Colors.amber;
      case 'processing':
        return Colors.blue;
      case 'failed':
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'succeeded':
      case 'paid':
        return Icons.check_circle;
      case 'pending':
        return Icons.access_time;
      case 'processing':
        return Icons.sync;
      case 'failed':
      case 'cancelled':
        return Icons.error;
      default:
        return Icons.help_outline;
    }
  }

  String _getStatusDisplayName(String status) {
    switch (status.toLowerCase()) {
      case 'succeeded':
        return 'Paid';
      case 'pending':
        return 'Pending Payment';
      case 'processing':
        return 'Processing';
      case 'failed':
        return 'Payment Failed';
      case 'cancelled':
        return 'Cancelled';
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        padding: const EdgeInsets.all(16),
        child: const Center(
          child: CircularProgressIndicator(
            color: AppColors.primary,
            strokeWidth: 2,
          ),
        ),
      );
    }

    if (_paymentData == null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Icon(Icons.payment_outlined, color: Colors.grey[400], size: 20),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'No payment information available',
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
            ),
          ],
        ),
      );
    }

    final status = _paymentData!['status'] ?? 'unknown';
    final amount = (_paymentData!['amount'] as num?)?.toDouble() ?? 0.0;
    final paymentMethod = _paymentData!['payment_method'] ?? 'unknown';
    final createdAt =
        _paymentData!['created_at'] != null
            ? DateTime.parse(_paymentData!['created_at'])
            : null;
    final paidAt =
        _paymentData!['paid_at'] != null
            ? DateTime.parse(_paymentData!['paid_at'])
            : null;

    final statusColor = _getStatusColor(status);
    final statusIcon = _getStatusIcon(status);
    final statusDisplayName = _getStatusDisplayName(status);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: statusColor.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(statusIcon, color: statusColor, size: 20),
              const SizedBox(width: 8),
              Text(
                'Payment Status',
                style: TextStyle(
                  color: statusColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  statusDisplayName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.attach_money,
                          size: 16,
                          color: Colors.white70,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Amount: ₱${amount.toStringAsFixed(2)}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          paymentMethod == 'gcash'
                              ? Icons.smartphone
                              : paymentMethod == 'cash'
                              ? Icons.money
                              : Icons.payment,
                          size: 16,
                          color: Colors.white70,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Method: ${paymentMethod.toUpperCase()}',
                          style: const TextStyle(color: Colors.white70),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          if (createdAt != null || paidAt != null) ...[
            const SizedBox(height: 8),
            const Divider(color: Colors.white24),
            const SizedBox(height: 8),
            if (createdAt != null)
              Row(
                children: [
                  const Icon(Icons.schedule, size: 14, color: Colors.white70),
                  const SizedBox(width: 4),
                  Text(
                    'Created: ${DateFormat('MMM dd, yyyy HH:mm').format(createdAt)}',
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            if (paidAt != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(
                    Icons.check_circle_outline,
                    size: 14,
                    color: Colors.green,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Paid: ${DateFormat('MMM dd, yyyy HH:mm').format(paidAt)}',
                    style: const TextStyle(
                      color: Colors.green,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ],

          if (status.toLowerCase() == 'pending' &&
              paymentMethod == 'gcash') ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextButton.icon(
                    onPressed: _isLoading ? null : _loadPaymentStatus,
                    icon:
                        _isLoading
                            ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  AppColors.primary,
                                ),
                              ),
                            )
                            : const Icon(Icons.refresh, size: 16),
                    label: Text(_isLoading ? 'Checking...' : 'Refresh Status'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
              ],
            ),
          ],

          if (status.toLowerCase() == 'pending' && paymentMethod == 'cash') ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.2),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Colors.amber, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Please bring ₱${amount.toStringAsFixed(2)} in cash during your appointment',
                      style: const TextStyle(color: Colors.amber, fontSize: 12),
                    ),
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
