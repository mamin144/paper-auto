import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class PayMobService {
  late final String apiKey;
  late final String integrationId;
  late final String iframeId;
  final Dio _dio = Dio();

  PayMobService() {
    // Ensure environment variables are loaded
    if (!dotenv.isInitialized) {
      throw Exception('Environment variables not loaded. Call await dotenv.load() before creating PayMobService.');
    }
    apiKey = dotenv.env['PAYMOB_API_KEY'] ?? '';
    integrationId = dotenv.env['PAYMOB_INTEGRATION_ID'] ?? '';
    iframeId = dotenv.env['PAYMOB_IFRAME_ID'] ?? '';
  }

  // Step 1: Authentication request to get auth token
  Future<String> getAuthToken() async {
    try {
      final response = await _dio.post(
        'https://accept.paymob.com/api/auth/tokens',
        data: {'api_key': apiKey},
      );
      return response.data['token'];
    } catch (e) {
      throw Exception('Failed to authenticate with PayMob: $e');
    }
  }

  // Step 2: Order registration
  Future<String> registerOrder(
    String authToken,
    double amount,
    String currency,
  ) async {
    try {
      final response = await _dio.post(
        'https://accept.paymob.com/api/ecommerce/orders',
        data: {
          'auth_token': authToken,
          'delivery_needed': false,
          'amount_cents': (amount * 100).toInt(), // Convert to cents
          'currency': currency,
        },
      );
      return response.data['id'].toString();
    } catch (e) {
      throw Exception('Failed to register order: $e');
    }
  }

  // Step 3: Payment key request
  Future<String> getPaymentKey({
    required String authToken,
    required String orderId,
    required double amount,
    required String currency,
    required String firstName,
    required String lastName,
    required String email,
    required String phone,
  }) async {
    try {
      final response = await _dio.post(
        'https://accept.paymob.com/api/acceptance/payment_keys',
        data: {
          'auth_token': authToken,
          'amount_cents': (amount * 100).toInt(),
          'expiration': 3600,
          'order_id': orderId,
          'billing_data': {
            'first_name': firstName,
            'last_name': lastName,
            'email': email,
            'phone_number': phone,
            'apartment': 'NA',
            'floor': 'NA',
            'street': 'NA',
            'building': 'NA',
            'shipping_method': 'NA',
            'postal_code': 'NA',
            'city': 'NA',
            'country': 'NA',
            'state': 'NA',
          },
          'currency': currency,
          'integration_id': integrationId,
        },
      );
      return response.data['token'];
    } catch (e) {
      throw Exception('Failed to get payment key: $e');
    }
  }

  // Get final payment URL
  String getFinalPaymentUrl(String paymentKey) {
    return 'https://accept.paymob.com/api/acceptance/iframes/$iframeId?payment_token=$paymentKey';
  }
}
