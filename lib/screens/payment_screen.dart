import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../services/paymob_service.dart';

class PaymentScreen extends StatefulWidget {
  final double amount;
  final String currency;
  final String firstName;
  final String lastName;
  final String email;
  final String phone;

  const PaymentScreen({
    Key? key,
    required this.amount,
    required this.currency,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phone,
  }) : super(key: key);

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final PayMobService _payMobService = PayMobService();
  late WebViewController _controller;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initializePayment();
  }

  Future<void> _initializePayment() async {
    try {
      // Step 1: Get authentication token
      final authToken = await _payMobService.getAuthToken();

      // Step 2: Register order
      final orderId = await _payMobService.registerOrder(
        authToken,
        widget.amount,
        widget.currency,
      );

      // Step 3: Get payment key
      final paymentKey = await _payMobService.getPaymentKey(
        authToken: authToken,
        orderId: orderId,
        amount: widget.amount,
        currency: widget.currency,
        firstName: widget.firstName,
        lastName: widget.lastName,
        email: widget.email,
        phone: widget.phone,
      );

      // Step 4: Get final payment URL
      final paymentUrl = _payMobService.getFinalPaymentUrl(paymentKey);

      // Initialize WebView with payment URL
      _controller =
          WebViewController()
            ..setJavaScriptMode(JavaScriptMode.unrestricted)
            ..setNavigationDelegate(
              NavigationDelegate(
                onPageFinished: (String url) {
                  setState(() {
                    _isLoading = false;
                  });
                },
                onNavigationRequest: (NavigationRequest request) {
                  // Handle success/failure URLs here
                  if (request.url.contains('success=true')) {
                    Navigator.pop(context, true); // Payment successful
                    return NavigationDecision.prevent;
                  } else if (request.url.contains('success=false')) {
                    Navigator.pop(context, false); // Payment failed
                    return NavigationDecision.prevent;
                  }
                  return NavigationDecision.navigate;
                },
              ),
            )
            ..loadRequest(Uri.parse(paymentUrl));
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Payment')),
        body: Center(
          child: Text(
            'Error: $_error',
            style: const TextStyle(color: Colors.red),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Payment')),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading) const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }
}
