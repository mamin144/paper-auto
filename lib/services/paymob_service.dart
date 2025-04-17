import 'package:dio/dio.dart';

class PayMobService {
  final String apiKey =
      'ZXlKaGJHY2lPaUpJVXpVeE1pSXNJblI1Y0NJNklrcFhWQ0o5LmV5SmpiR0Z6Y3lJNklrMWxjbU5vWVc1MElpd2ljSEp2Wm1sc1pWOXdheUk2TVRBeE1URXlOaXdpYm1GdFpTSTZJbWx1YVhScFlXd2lmUS52Wi1WZ2dZWDJucFhrUHdtUEZjWFFqVXZwZ2V5WVR2dWl6Zy12bDVsb1ozWE1wck9MZ3N5LXZ5aUtYU3lJVE5PMDdSOFRJeE1yWDU2bUdoMVJyYy1IUQ=='; // Replace with your PayMob API key
  final String integrationId = '4896403'; // Replace with your Integration ID
  final String iframeId = '886746'; // Replace with your IFrame ID
  final Dio _dio = Dio();

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
    return 'https://accept.paymob.com/api/acceptance/iframes/886745?payment_token=$paymentKey';
  }
}
