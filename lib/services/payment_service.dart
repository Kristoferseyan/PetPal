import 'dart:convert';
import 'dart:math';
import 'package:dio/dio.dart';
import 'package:petpal/config/payment_config.dart';

class PaymentService {
  static const String _baseUrl = 'https://api.paymongo.com/v1';

  late final String _secretKey;
  late final String _publicKey;

  final Dio _dio = Dio();
  PaymentService() {
    PaymentConfig.printDebugInfo();

    // Load API keys from configuration
    _secretKey = PaymentConfig.secretKey;
    _publicKey = PaymentConfig.publicKey;

    print('Loading PayMongo API keys...');
    print('Environment: ${PaymentConfig.environment}');
    print('Secret key loaded: ${_secretKey.isNotEmpty}');
    print('Public key loaded: ${_publicKey.isNotEmpty}');
    print('Configuration valid: ${PaymentConfig.isConfigurationValid()}');

    if (!PaymentConfig.isConfigurationValid()) {
      throw Exception(
        'Invalid PayMongo configuration: ${PaymentConfig.getConfigurationStatus()}',
      );
    }

    _dio.options.baseUrl = _baseUrl;
    _dio.options.headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Basic ${base64Encode(utf8.encode('$_secretKey:'))}',
    };

    print('PaymentService initialized successfully with base URL: $_baseUrl');
    print('Environment: ${PaymentConfig.environment} mode');
  }

  // Create a payment intent for GCash
  Future<Map<String, dynamic>?> createPaymentIntent({
    required double amount,
    required String currency,
    required String description,
    required Map<String, dynamic> metadata,
  }) async {
    try {
      print('Creating payment intent with amount: $amount');
      print('Secret key starts with: ${_secretKey.substring(0, 10)}...');

      // Ensure amount is properly formatted (in centavos for PHP)
      final amountInCentavos = (amount * 100).round();

      // Validate amount (minimum 20 PHP = 2000 centavos for PayMongo)
      if (amountInCentavos < 2000) {
        throw Exception('Amount must be at least 20.00 PHP');
      }

      final requestData = {
        'data': {
          'attributes': {
            'amount': amountInCentavos,
            'payment_method_allowed': ['gcash'],
            'currency': currency.toUpperCase(),
            'capture_type': 'automatic',
            'description': description,
            'statement_descriptor': 'PetPal Payment',
            'metadata': metadata,
          },
        },
      };

      print('Request data: ${jsonEncode(requestData)}');

      final response = await _dio.post('/payment_intents', data: requestData);

      print('Payment intent created successfully: ${response.statusCode}');
      return response.data['data'];
    } catch (e) {
      print('Error creating payment intent: $e');
      if (e is DioException) {
        print('Response data: ${e.response?.data}');
        print('Status code: ${e.response?.statusCode}');
        print('Request data: ${e.requestOptions.data}');
      }
      throw Exception('Failed to create payment intent: $e');
    }
  }

  // Create payment method for GCash
  Future<Map<String, dynamic>?> createGCashPaymentMethod() async {
    try {
      print('Creating GCash payment method...');

      final response = await _dio.post(
        '/payment_methods',
        data: {
          'data': {
            'attributes': {'type': 'gcash'},
          },
        },
      );

      print('Payment method created successfully: ${response.statusCode}');
      return response.data['data'];
    } catch (e) {
      print('Error creating payment method: $e');
      if (e is DioException) {
        print('Response data: ${e.response?.data}');
        print('Status code: ${e.response?.statusCode}');
      }
      throw Exception('Failed to create payment method: $e');
    }
  }

  // Attach payment method to payment intent
  Future<Map<String, dynamic>?> attachPaymentMethod({
    required String paymentIntentId,
    required String paymentMethodId,
    String? clientKey,
    String? returnUrl,
  }) async {
    try {
      print('Attaching payment method to intent...');

      final requestData = {
        'data': {
          'attributes': {
            'payment_method': paymentMethodId,
            'client_key': clientKey,
            if (returnUrl != null) 'return_url': returnUrl,
          },
        },
      };

      final response = await _dio.post(
        '/payment_intents/$paymentIntentId/attach',
        data: requestData,
      );

      print('Payment method attached successfully: ${response.statusCode}');
      return response.data['data'];
    } catch (e) {
      print('Error attaching payment method: $e');
      if (e is DioException) {
        print('Response data: ${e.response?.data}');
        print('Status code: ${e.response?.statusCode}');
      }
      throw Exception('Failed to attach payment method: $e');
    }
  }

  // Get payment intent status
  Future<Map<String, dynamic>?> getPaymentIntent(String paymentIntentId) async {
    try {
      final response = await _dio.get('/payment_intents/$paymentIntentId');
      return response.data['data'];
    } catch (e) {
      print('Error getting payment intent: $e');
      return null;
    }
  }

  // Create a payment session for easier handling
  Future<Map<String, dynamic>?> createPaymentSession({
    required double amount,
    required String description,
    required String appointmentId,
    required String petOwnerId,
    String currency = 'PHP',
  }) async {
    try {
      print('=== Creating Payment Session ===');
      print('Amount: $amount $currency');
      print('Description: $description');
      print('Appointment ID: $appointmentId');

      final metadata = {
        'appointment_id': appointmentId,
        'pet_owner_id': petOwnerId,
        'payment_type': 'appointment_fee',
      };

      // Step 1: Create payment intent
      print('Step 1: Creating payment intent...');
      final paymentIntent = await createPaymentIntent(
        amount: amount,
        currency: currency,
        description: description,
        metadata: metadata,
      );

      if (paymentIntent == null) {
        throw Exception('Failed to create payment intent');
      }
      print('✅ Payment intent created: ${paymentIntent['id']}');

      // Step 2: Create GCash payment method
      print('Step 2: Creating GCash payment method...');
      final paymentMethod = await createGCashPaymentMethod();
      if (paymentMethod == null) {
        throw Exception('Failed to create payment method');
      }
      print('✅ Payment method created: ${paymentMethod['id']}');

      // Step 3: Attach payment method to intent
      print('Step 3: Attaching payment method to intent...');
      final attachedPayment = await attachPaymentMethod(
        paymentIntentId: paymentIntent['id'],
        paymentMethodId: paymentMethod['id'],
        clientKey: paymentIntent['attributes']['client_key'],
        returnUrl: 'https://petpal.app/payment-return',
      );

      if (attachedPayment == null) {
        throw Exception('Failed to attach payment method');
      }
      print('✅ Payment method attached successfully');

      final checkoutUrl =
          attachedPayment['attributes']?['next_action']?['redirect']?['url'];
      print('Checkout URL: $checkoutUrl');

      final result = {
        'payment_intent': paymentIntent,
        'payment_method': paymentMethod,
        'attached_payment': attachedPayment,
        'checkout_url': checkoutUrl,
      };

      print('=== Payment Session Created Successfully ===');
      return result;
    } catch (e) {
      print('❌ Error creating payment session: $e');
      if (e is DioException) {
        print('Response data: ${e.response?.data}');
        print('Status code: ${e.response?.statusCode}');
      }
      rethrow; // Re-throw the exception so calling code can handle it
    }
  }

  // Verify payment status with enhanced debugging
  Future<bool> verifyPayment(String paymentIntentId) async {
    try {
      print('🔍 Verifying payment status for intent: $paymentIntentId');

      final paymentIntent = await getPaymentIntent(paymentIntentId);

      if (paymentIntent == null) {
        print('❌ Payment intent not found');
        return false;
      }

      final status = paymentIntent['attributes']?['status'];
      final currency = paymentIntent['attributes']?['currency'];
      final amount = paymentIntent['attributes']?['amount'];

      print('💰 Payment Intent Details:');
      print('  - Status: $status');
      print('  - Currency: $currency');
      print('  - Amount: $amount');
      print('  - Created: ${paymentIntent['attributes']?['created_at']}');
      print('  - Updated: ${paymentIntent['attributes']?['updated_at']}');

      // Check for payments array (attached payments)
      final payments = paymentIntent['attributes']?['payments'];
      if (payments != null && payments.isNotEmpty) {
        print('📋 Found ${payments.length} attached payment(s):');
        for (var payment in payments) {
          final paymentStatus = payment['attributes']?['status'];
          final paymentType = payment['attributes']?['type'];
          print('  - Payment Type: $paymentType, Status: $paymentStatus');
        }
      }

      final isSucceeded = status == 'succeeded';
      print(
        isSucceeded
            ? '✅ Payment verification: SUCCESS'
            : '⚠️ Payment verification: PENDING ($status)',
      );

      return isSucceeded;
    } catch (e) {
      print('❌ Error verifying payment: $e');
      if (e is DioException) {
        print('Response data: ${e.response?.data}');
        print('Status code: ${e.response?.statusCode}');
      }
      return false;
    }
  }

  // Get detailed payment status including attached payments
  Future<Map<String, dynamic>?> getDetailedPaymentStatus(
    String paymentIntentId,
  ) async {
    try {
      final paymentIntent = await getPaymentIntent(paymentIntentId);

      if (paymentIntent == null) {
        return null;
      }

      return {
        'intent_status': paymentIntent['attributes']?['status'],
        'intent_id': paymentIntent['id'],
        'currency': paymentIntent['attributes']?['currency'],
        'amount': paymentIntent['attributes']?['amount'],
        'created_at': paymentIntent['attributes']?['created_at'],
        'updated_at': paymentIntent['attributes']?['updated_at'],
        'payments': paymentIntent['attributes']?['payments'] ?? [],
      };
    } catch (e) {
      print('Error getting detailed payment status: $e');
      return null;
    }
  }

  // Generate a unique payment reference
  String generatePaymentReference() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = Random().nextInt(9999);
    return 'PP${timestamp.toString().substring(7)}$random';
  }

  Future<bool> testConnection() async {
    try {
      final requestData = {
        'data': {
          'attributes': {
            'amount': 10000, // 100 PHP in centavos
            'payment_method_allowed': ['gcash'],
            'currency': 'PHP',
            'capture_type': 'automatic',
            'description': 'Test payment connection',
          },
        },
      };

      print('Test request data: ${jsonEncode(requestData)}');

      final response = await _dio.post('/payment_intents', data: requestData);

      print('API connection test successful: ${response.statusCode}');

      // Clean up test payment intent
      if (response.data != null && response.data['data'] != null) {
        final testPaymentId = response.data['data']['id'];
        print('Test payment intent created with ID: $testPaymentId');
        // Note: PayMongo doesn't have a delete endpoint, so we leave it as is
      }

      return true;
    } catch (e) {
      print('API connection test failed: $e');
      if (e is DioException) {
        print('Response data: ${e.response?.data}');
        print('Status code: ${e.response?.statusCode}');
        print('Request headers: ${e.requestOptions.headers}');
      }
      return false;
    }
  }
}
