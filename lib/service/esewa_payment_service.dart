import 'dart:convert';

import 'package:crypto/crypto.dart';

class EsewaPaymentService {
  EsewaPaymentService._();

  static const String productCode = 'EPAYTEST';

  // eSewa UAT/test secret key.
  // TEST MODE ONLY.
  static const String _secretKey = '8gBm/:&EnhH.1/q';

  static const String paymentUrl =
      'https://rc-epay.esewa.com.np/api/epay/main/v2/form';

  /// Creates a unique transaction id for every payment attempt.
  static String createTransactionUuid() {
    final now = DateTime.now();

    return 'SEVA-${now.millisecondsSinceEpoch}';
  }

  /// eSewa V2 requires:
  ///
  /// total_amount=...,transaction_uuid=...,product_code=...
  ///
  /// signed using HMAC SHA256 and encoded as Base64.
  static String generateSignature({
    required String totalAmount,
    required String transactionUuid,
  }) {
    final message =
        'total_amount=$totalAmount,'
        'transaction_uuid=$transactionUuid,'
        'product_code=$productCode';

    final key = utf8.encode(_secretKey);
    final bytes = utf8.encode(message);

    final hmacSha256 = Hmac(
      sha256,
      key,
    );

    final digest = hmacSha256.convert(bytes);

    return base64Encode(digest.bytes);
  }

  static Map<String, String> createPaymentData({
    required int amount,
    required String transactionUuid,
    required String successUrl,
    required String failureUrl,
  }) {
    final totalAmount = amount.toString();

    final signature = generateSignature(
      totalAmount: totalAmount,
      transactionUuid: transactionUuid,
    );

    return {
      'amount': totalAmount,

      'tax_amount': '0',

      'total_amount': totalAmount,

      'transaction_uuid': transactionUuid,

      'product_code': productCode,

      'product_service_charge': '0',

      'product_delivery_charge': '0',

      'success_url': successUrl,

      'failure_url': failureUrl,

      'signed_field_names':
      'total_amount,transaction_uuid,product_code',

      'signature': signature,
    };
  }

  static String createHtmlForm({
    required int amount,
    required String transactionUuid,
    required String successUrl,
    required String failureUrl,
  }) {
    final data = createPaymentData(
      amount: amount,
      transactionUuid: transactionUuid,
      successUrl: successUrl,
      failureUrl: failureUrl,
    );

    final inputs = data.entries.map(
          (entry) {
        return '''
<input
  type="hidden"
  name="${_escape(entry.key)}"
  value="${_escape(entry.value)}"
/>
''';
      },
    ).join();

    return '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <meta
    name="viewport"
    content="width=device-width, initial-scale=1.0"
  />

  <style>
    body {
      margin: 0;
      padding: 0;
      background: #ffffff;
      font-family: Arial, sans-serif;
    }

    .loader {
      height: 100vh;
      display: flex;
      flex-direction: column;
      align-items: center;
      justify-content: center;
    }

    .spinner {
      width: 42px;
      height: 42px;
      border: 4px solid #e8ecea;
      border-top-color: #60bb46;
      border-radius: 50%;
      animation: spin 0.8s linear infinite;
    }

    .text {
      margin-top: 16px;
      color: #475467;
      font-size: 14px;
    }

    @keyframes spin {
      to {
        transform: rotate(360deg);
      }
    }
  </style>
</head>

<body>

  <div class="loader">
    <div class="spinner"></div>

    <div class="text">
      Opening eSewa test payment...
    </div>
  </div>

  <form
    id="esewaPaymentForm"
    action="$paymentUrl"
    method="POST"
  >
    $inputs
  </form>

  <script>
    window.onload = function() {
      document
        .getElementById('esewaPaymentForm')
        .submit();
    };
  </script>

</body>
</html>
''';
  }

  static String _escape(
      String value,
      ) {
    return const HtmlEscape(
      HtmlEscapeMode.attribute,
    ).convert(value);
  }
}