import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';

class PaymentService {
  // Your backend API URL
  static const String _backendUrl = 'https://serverar-production.up.railway.app'; // 👈 Replace with your backend URL

  // Create a payment intent
  static Future<Map<String, dynamic>> createPaymentIntent({
    required int amount,
    required String currency,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_backendUrl/create-payment-intent'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'amount': amount,
          'currency': currency,
        }),
      );

      final jsonResponse = jsonDecode(response.body);
      if (jsonResponse['error'] != null) {
        throw jsonResponse['error'];
      }

      return jsonResponse;
    } catch (e) {
      rethrow;
    }
  }

  // Initialize the payment sheet
  static Future<void> initPaymentSheet({
    required String paymentIntentClientSecret,
    required String merchantDisplayName,
  }) async {
    try {
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: paymentIntentClientSecret,
          merchantDisplayName: merchantDisplayName,
          style: ThemeMode.system,
        ),
      );
    } catch (e) {
      rethrow;
    }
  }

  // Present the payment sheet
  static Future<void> presentPaymentSheet() async {
    try {
      await Stripe.instance.presentPaymentSheet();
    } catch (e) {
      rethrow;
    }
  }

  // Complete payment flow
  static Future<bool> makePayment({
    required int amount,
    required String currency,
    required String merchantName,
  }) async {
    try {
      // 1. Create payment intent
      final paymentIntent = await createPaymentIntent(
        amount: amount,
        currency: currency,
      );

      // 2. Initialize payment sheet
      await initPaymentSheet(
        paymentIntentClientSecret: paymentIntent['clientSecret'],
        merchantDisplayName: merchantName,
      );

      // 3. Present payment sheet
      await presentPaymentSheet();

      // If we get here, payment was successful
      return true;
    } catch (e) {
      print('Payment error: $e');
      return false;
    }
  }
}
