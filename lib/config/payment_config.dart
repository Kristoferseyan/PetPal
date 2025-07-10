import 'package:flutter_dotenv/flutter_dotenv.dart';

class PaymentConfig {
  static const bool isLiveMode = false;

  static String get publicKey {
    if (isLiveMode) {
      return dotenv.env['PAYMONGO_LIVE_PUBLIC_KEY'] ?? '';
    } else {
      return dotenv.env['PAYMONGO_PUBLIC_KEY'] ?? '';
    }
  }

  static String get secretKey {
    if (isLiveMode) {
      return dotenv.env['PAYMONGO_LIVE_SECRET_KEY'] ?? '';
    } else {
      return dotenv.env['PAYMONGO_SECRET_KEY'] ?? '';
    }
  }

  static String get environment => isLiveMode ? 'LIVE' : 'TEST';

  static bool get isTestMode => !isLiveMode;

  static bool isConfigurationValid() {
    final pubKey = publicKey;
    final secKey = secretKey;

    if (pubKey.isEmpty || secKey.isEmpty) {
      return false;
    }

    if (isLiveMode) {
      return pubKey.startsWith('pk_live_') && secKey.startsWith('sk_live_');
    } else {
      return pubKey.startsWith('pk_test_') && secKey.startsWith('sk_test_');
    }
  }

  static String getConfigurationStatus() {
    if (!isConfigurationValid()) {
      return 'Invalid PayMongo API keys for $environment mode';
    }

    return '$environment mode configured correctly';
  }

  static Map<String, dynamic> get paymentFees {
    return {
      'gcash': {
        'percentage': 3.5,
        'fixed_fee': 15.0,
        'description': 'GCash payments: 3.5% + ₱15 per transaction',
      },
      'card': {
        'percentage': 3.9,
        'fixed_fee': 15.0,
        'description': 'Credit/Debit cards: 3.9% + ₱15 per transaction',
      },
      'bank_transfer': {
        'percentage': 1.5,
        'fixed_fee': 0.0,
        'description': 'Bank transfer: 1.5% per transaction',
      },
    };
  }

  static double calculateFee(double amount, String paymentMethod) {
    final fees = paymentFees[paymentMethod];
    if (fees == null) return 0.0;

    final percentage = fees['percentage'] as double;
    final fixedFee = fees['fixed_fee'] as double;

    return (amount * percentage / 100) + fixedFee;
  }

  static double getTotalWithFees(double amount, String paymentMethod) {
    return amount + calculateFee(amount, paymentMethod);
  }

  static void printDebugInfo() {}
}
