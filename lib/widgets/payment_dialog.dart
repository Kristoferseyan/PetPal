import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:petpal/models/payment_models.dart';
import 'package:petpal/services/payment_service.dart';
import 'package:petpal/services/medical_service.dart';
import 'package:petpal/utils/colors.dart';

class PaymentDialog extends StatefulWidget {
  final String appointmentId;
  final String petOwnerId;
  final String appointmentType;
  final String petName;
  final double? customAmount;
  final VoidCallback? onPaymentCompleted;

  const PaymentDialog({
    Key? key,
    required this.appointmentId,
    required this.petOwnerId,
    required this.appointmentType,
    required this.petName,
    this.customAmount,
    this.onPaymentCompleted,
  }) : super(key: key);

  @override
  _PaymentDialogState createState() => _PaymentDialogState();
}

class _PaymentDialogState extends State<PaymentDialog> {
  final PaymentService _paymentService = PaymentService();
  final MedicalService _medicalService = MedicalService();

  PaymentMethod _selectedPaymentMethod = PaymentMethod.gcash;
  bool _isProcessing = false;
  double _amount = 0.0;
  AppointmentFee? _appointmentFee;

  @override
  void initState() {
    super.initState();
    _initializePayment();
  }

  void _initializePayment() {
    if (widget.customAmount != null) {
      _amount = widget.customAmount!;
    } else {
      _amount = AppointmentFee.getFeeForAppointmentType(widget.appointmentType);
      _appointmentFee = AppointmentFee.getStandardFees().firstWhere(
        (fee) => fee.appointmentType == widget.appointmentType,
      );
    }
  }

  Future<void> _processPayment() async {
    if (_isProcessing) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      if (_selectedPaymentMethod == PaymentMethod.cash) {
        await _processCashPayment();
      } else if (_selectedPaymentMethod == PaymentMethod.gcash) {
        await _processGCashPayment();
      }
    } catch (e) {
      _showErrorDialog('Payment Error', e.toString());
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  Future<void> _processCashPayment() async {
    try {
      await _medicalService.createPaymentRecord(
        appointmentId: widget.appointmentId,
        petOwnerId: widget.petOwnerId,
        amount: _amount,
        paymentMethod: 'cash',
        description:
            'Cash payment for ${widget.appointmentType} - ${widget.petName}',
      );

      _showSuccessDialog(
        'Payment Method Selected',
        'You have chosen to pay with cash at the clinic. Please bring the exact amount (₱${_amount.toStringAsFixed(2)}) during your appointment.',
      );
    } catch (e) {
      throw Exception('Failed to register cash payment: $e');
    }
  }

  Future<void> _processGCashPayment() async {
    try {
      final paymentSession = await _paymentService.createPaymentSession(
        amount: _amount,
        description: '${widget.appointmentType} for ${widget.petName}',
        appointmentId: widget.appointmentId,
        petOwnerId: widget.petOwnerId,
      );

      if (paymentSession == null) {
        throw Exception('Failed to create payment session');
      }

      await _medicalService.createPaymentRecord(
        appointmentId: widget.appointmentId,
        petOwnerId: widget.petOwnerId,
        amount: _amount,
        paymentMethod: 'gcash',
        description:
            'GCash payment for ${widget.appointmentType} - ${widget.petName}',
        paymentIntentId: paymentSession['payment_intent']['id'],
      );

      final checkoutUrl = paymentSession['checkout_url'];
      if (checkoutUrl != null) {
        await _launchPaymentUrl(checkoutUrl);
      } else {
        _showManualPaymentDialog(paymentSession);
      }
    } catch (e) {
      throw Exception('Failed to process GCash payment: $e');
    }
  }

  Future<void> _launchPaymentUrl(String url) async {
    try {
      final uri = Uri.parse(url);

      bool launched = false;

      try {
        if (await canLaunchUrl(uri)) {
          launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      } catch (e) {}

      if (!launched) {
        try {
          launched = await launchUrl(uri, mode: LaunchMode.platformDefault);
        } catch (e) {}
      }

      if (!launched) {
        try {
          launched = await launchUrl(uri, mode: LaunchMode.inAppWebView);
        } catch (e) {}
      }

      if (launched) {
        _showPaymentPendingDialog();
      } else {
        throw Exception('Cannot launch payment URL: All launch modes failed');
      }
    } catch (e) {
      throw Exception('Failed to open payment page: $e');
    }
  }

  void _showPaymentPendingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => AlertDialog(
            backgroundColor: const Color.fromARGB(255, 45, 55, 60),
            title: const Text(
              'Payment in Progress',
              style: TextStyle(color: Colors.white),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(color: AppColors.primary),
                const SizedBox(height: 16),
                const Text(
                  'Please complete your payment in the GCash app. Once done, come back here and tap "Check Payment Status".',
                  style: TextStyle(color: Colors.white70),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).pop();
                },
                child: const Text(
                  'Cancel',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
              ElevatedButton(
                onPressed: () async {
                  await _checkPaymentStatus();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                ),
                child: const Text(
                  'Check Payment Status',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
    );
  }

  Future<void> _checkPaymentStatus() async {
    try {
      print(
        '🔄 Checking payment status for appointment: ${widget.appointmentId}',
      );

      final payment = await _medicalService.getPaymentForAppointment(
        widget.appointmentId,
      );
      if (payment != null && payment['payment_intent_id'] != null) {
        final paymentIntentId = payment['payment_intent_id'];

        final detailedStatus = await _paymentService.getDetailedPaymentStatus(
          paymentIntentId,
        );

        if (detailedStatus != null) {
          final intentStatus = detailedStatus['intent_status'];
          print('🔍 PayMongo detailed status: $intentStatus');
          print(
            '💰 Amount: ${detailedStatus['amount']} ${detailedStatus['currency']}',
          );

          final payments = detailedStatus['payments'] as List<dynamic>? ?? [];
          bool hasSuccessfulPayment = false;

          if (payments.isNotEmpty) {
            for (var attachedPayment in payments) {
              final paymentStatus = attachedPayment['attributes']?['status'];

              if (paymentStatus == 'paid' || paymentStatus == 'succeeded') {
                hasSuccessfulPayment = true;
                break;
              }
            }
          }

          final isSuccess =
              (intentStatus == 'succeeded') || hasSuccessfulPayment;

          print(
            isSuccess
                ? '✅ Payment confirmed as successful!'
                : '⚠️ Payment still pending',
          );

          if (isSuccess) {
            await _medicalService.updatePaymentStatus(
              appointmentId: widget.appointmentId,
              status: 'succeeded',
              paidAt: DateTime.now(),
            );

            Navigator.of(context).pop();
            Navigator.of(context).pop();

            if (widget.onPaymentCompleted != null) {
              widget.onPaymentCompleted!();
            }

            _showSuccessDialog(
              'Payment Successful!',
              'Your payment of ₱${_amount.toStringAsFixed(2)} has been processed successfully.',
            );
          } else {
            _showErrorDialog(
              'Payment Pending',
              'Your payment is still being processed. Please try again in a few moments.\n\nCurrent status: $intentStatus',
            );
          }
        } else {
          _showErrorDialog(
            'Verification Error',
            'Unable to verify payment status. Please check your connection and try again.',
          );
        }
      } else {
        _showErrorDialog(
          'Payment Not Found',
          'No payment record found for this appointment.',
        );
      }
    } catch (e) {
      _showErrorDialog('Error', 'Failed to check payment status: $e');
    }
  }

  void _showSuccessDialog(String title, String message) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: const Color.fromARGB(255, 45, 55, 60),
            title: Text(title, style: const TextStyle(color: Colors.green)),
            content: Text(
              message,
              style: const TextStyle(color: Colors.white70),
            ),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  if (widget.onPaymentCompleted != null) {
                    widget.onPaymentCompleted!();
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                child: const Text('OK', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
    );
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: const Color.fromARGB(255, 45, 55, 60),
            title: Text(title, style: const TextStyle(color: Colors.red)),
            content: Text(
              message,
              style: const TextStyle(color: Colors.white70),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
    );
  }

  void _showManualPaymentDialog(Map<String, dynamic> paymentSession) {
    final checkoutUrl = paymentSession['checkout_url'];
    final paymentIntentId = paymentSession['payment_intent']['id'];

    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => AlertDialog(
            backgroundColor: const Color.fromARGB(255, 45, 55, 60),
            title: const Text(
              'Complete Payment Manually',
              style: TextStyle(color: Colors.white),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'We couldn\'t automatically open the payment page. Please follow these steps:',
                  style: TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 16),
                const Text(
                  '1. Copy the payment URL below',
                  style: TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey[800],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          checkoutUrl ?? 'URL not available',
                          style: const TextStyle(
                            color: Colors.blue,
                            fontSize: 12,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 2,
                        ),
                      ),
                      IconButton(
                        onPressed:
                            checkoutUrl != null
                                ? () async {
                                  await Clipboard.setData(
                                    ClipboardData(text: checkoutUrl),
                                  );
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Payment URL copied to clipboard',
                                        ),
                                        backgroundColor: Colors.green,
                                        duration: Duration(seconds: 2),
                                      ),
                                    );
                                  }
                                }
                                : null,
                        icon: const Icon(
                          Icons.copy,
                          color: Colors.blue,
                          size: 16,
                        ),
                        tooltip: 'Copy URL',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  '2. Open your browser and paste the URL',
                  style: TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 8),
                const Text(
                  '3. Complete payment with GCash',
                  style: TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 8),
                const Text(
                  '4. Return here and check payment status',
                  style: TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 16),
                Text(
                  'Payment ID: $paymentIntentId',
                  style: const TextStyle(color: Colors.white54, fontSize: 10),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).pop();
                },
                child: const Text(
                  'Cancel',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _showPaymentPendingDialog();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                ),
                child: const Text(
                  'I\'ll Pay Manually',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color.fromARGB(255, 45, 55, 60),
      title: Row(
        children: [
          const Icon(Icons.payment, color: AppColors.primary),
          const SizedBox(width: 8),
          const Text('Payment Options', style: TextStyle(color: Colors.white)),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.primary.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Appointment Details',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.pets, size: 16, color: Colors.white70),
                      const SizedBox(width: 8),
                      Text(
                        'Pet: ${widget.petName}',
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.medical_services,
                        size: 16,
                        color: Colors.white70,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Service: ${widget.appointmentType}',
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.attach_money,
                        size: 16,
                        color: Colors.white70,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Amount: ₱${_amount.toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            if (_appointmentFee != null) ...[
              Text(
                'Service Includes:',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              ..._appointmentFee!.includes.map(
                (include) => Padding(
                  padding: const EdgeInsets.only(left: 16, bottom: 4),
                  child: Row(
                    children: [
                      const Icon(Icons.check, size: 14, color: Colors.green),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          include,
                          style: const TextStyle(color: Colors.white70),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            const Text(
              'Choose Payment Method:',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            _buildPaymentOption(
              method: PaymentMethod.gcash,
              icon: Icons.smartphone,
              title: 'Pay with GCash',
              subtitle: 'Secure online payment',
              color: Colors.blue,
            ),

            const SizedBox(height: 8),

            _buildPaymentOption(
              method: PaymentMethod.cash,
              icon: Icons.money,
              title: 'Pay at Clinic',
              subtitle: 'Pay with cash during your visit',
              color: Colors.green,
            ),

            const SizedBox(height: 16),

            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Colors.amber, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _selectedPaymentMethod == PaymentMethod.gcash
                          ? 'You will be redirected to GCash to complete payment'
                          : 'Please bring exact amount during your appointment',
                      style: const TextStyle(color: Colors.amber, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isProcessing ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
        ),
        ElevatedButton(
          onPressed: _isProcessing ? null : _processPayment,
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
          child:
              _isProcessing
                  ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                  : Text(
                    _selectedPaymentMethod == PaymentMethod.gcash
                        ? 'Pay with GCash'
                        : 'Confirm Cash Payment',
                    style: const TextStyle(color: Colors.white),
                  ),
        ),
      ],
    );
  }

  Widget _buildPaymentOption({
    required PaymentMethod method,
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
  }) {
    final isSelected = _selectedPaymentMethod == method;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedPaymentMethod = method;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color:
              isSelected
                  ? color.withOpacity(0.2)
                  : const Color.fromARGB(255, 31, 38, 42),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? color : Colors.grey.withOpacity(0.3),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Radio<PaymentMethod>(
              value: method,
              groupValue: _selectedPaymentMethod,
              onChanged: (PaymentMethod? value) {
                setState(() {
                  _selectedPaymentMethod = value!;
                });
              },
              activeColor: color,
            ),
            Icon(icon, color: color, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
