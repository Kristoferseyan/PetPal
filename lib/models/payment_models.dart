class PaymentData {
  final String id;
  final String appointmentId;
  final String petOwnerId;
  final double amount;
  final String currency;
  final String description;
  final PaymentStatus status;
  final PaymentMethod paymentMethod;
  final String? transactionId;
  final String? paymentIntentId;
  final DateTime createdAt;
  final DateTime? paidAt;

  PaymentData({
    required this.id,
    required this.appointmentId,
    required this.petOwnerId,
    required this.amount,
    required this.currency,
    required this.description,
    required this.status,
    required this.paymentMethod,
    this.transactionId,
    this.paymentIntentId,
    required this.createdAt,
    this.paidAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'appointment_id': appointmentId,
      'pet_owner_id': petOwnerId,
      'amount': amount,
      'currency': currency,
      'description': description,
      'status': status.name,
      'payment_method': paymentMethod.name,
      'transaction_id': transactionId,
      'payment_intent_id': paymentIntentId,
      'created_at': createdAt.toIso8601String(),
      'paid_at': paidAt?.toIso8601String(),
    };
  }

  factory PaymentData.fromJson(Map<String, dynamic> json) {
    return PaymentData(
      id: json['id'],
      appointmentId: json['appointment_id'],
      petOwnerId: json['pet_owner_id'],
      amount: (json['amount'] as num).toDouble(),
      currency: json['currency'],
      description: json['description'],
      status: PaymentStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => PaymentStatus.pending,
      ),
      paymentMethod: PaymentMethod.values.firstWhere(
        (e) => e.name == json['payment_method'],
        orElse: () => PaymentMethod.gcash,
      ),
      transactionId: json['transaction_id'],
      paymentIntentId: json['payment_intent_id'],
      createdAt: DateTime.parse(json['created_at']),
      paidAt: json['paid_at'] != null ? DateTime.parse(json['paid_at']) : null,
    );
  }
}

enum PaymentStatus {
  pending,
  processing,
  succeeded,
  failed,
  cancelled,
  refunded,
}

enum PaymentMethod { gcash, cash, card }

extension PaymentStatusExtension on PaymentStatus {
  String get displayName {
    switch (this) {
      case PaymentStatus.pending:
        return 'Pending';
      case PaymentStatus.processing:
        return 'Processing';
      case PaymentStatus.succeeded:
        return 'Paid';
      case PaymentStatus.failed:
        return 'Failed';
      case PaymentStatus.cancelled:
        return 'Cancelled';
      case PaymentStatus.refunded:
        return 'Refunded';
    }
  }

  String get description {
    switch (this) {
      case PaymentStatus.pending:
        return 'Payment is waiting to be processed';
      case PaymentStatus.processing:
        return 'Payment is being processed';
      case PaymentStatus.succeeded:
        return 'Payment completed successfully';
      case PaymentStatus.failed:
        return 'Payment failed';
      case PaymentStatus.cancelled:
        return 'Payment was cancelled';
      case PaymentStatus.refunded:
        return 'Payment was refunded';
    }
  }
}

extension PaymentMethodExtension on PaymentMethod {
  String get displayName {
    switch (this) {
      case PaymentMethod.gcash:
        return 'GCash';
      case PaymentMethod.cash:
        return 'Cash (Pay at Clinic)';
      case PaymentMethod.card:
        return 'Credit/Debit Card';
    }
  }
}

class AppointmentFee {
  final String appointmentType;
  final double basePrice;
  final String description;
  final List<String> includes;

  AppointmentFee({
    required this.appointmentType,
    required this.basePrice,
    required this.description,
    required this.includes,
  });

  static List<AppointmentFee> getStandardFees() {
    return [
      AppointmentFee(
        appointmentType: 'Check-up',
        basePrice: 500.0,
        description: 'Basic veterinary examination',
        includes: [
          'Physical examination',
          'Basic health assessment',
          'Consultation',
        ],
      ),
      AppointmentFee(
        appointmentType: 'Vaccination',
        basePrice: 800.0,
        description: 'Vaccination services',
        includes: [
          'Vaccine administration',
          'Health check',
          'Vaccination record',
        ],
      ),
      AppointmentFee(
        appointmentType: 'Operation',
        basePrice: 3000.0,
        description: 'Surgical procedures',
        includes: [
          'Pre-surgery consultation',
          'Surgery',
          'Post-surgery care instructions',
        ],
      ),
      AppointmentFee(
        appointmentType: 'Grooming',
        basePrice: 600.0,
        description: 'Pet grooming services',
        includes: ['Bath', 'Nail trimming', 'Hair cut', 'Basic health check'],
      ),
      AppointmentFee(
        appointmentType: 'Other',
        basePrice: 400.0,
        description: 'Other veterinary services',
        includes: ['Consultation', 'Basic examination'],
      ),
    ];
  }

  static double getFeeForAppointmentType(String appointmentType) {
    final fees = getStandardFees();
    final fee = fees.firstWhere(
      (f) => f.appointmentType == appointmentType,
      orElse: () => fees.last,
    );
    return fee.basePrice;
  }
}
