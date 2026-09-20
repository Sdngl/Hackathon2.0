import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../service/esewa_payment_service.dart';

class EsewaPaymentPage extends StatefulWidget {
  final int amount;
  final String planTitle;

  const EsewaPaymentPage({
    super.key,
    required this.amount,
    required this.planTitle,
  });

  @override
  State<EsewaPaymentPage> createState() =>
      _EsewaPaymentPageState();
}

class _EsewaPaymentPageState
    extends State<EsewaPaymentPage> {
  late final WebViewController _controller;

  late final String _transactionUuid;

  bool _isLoading = true;
  bool _paymentFinished = false;

  static const String _successUrl =
      'https://seva.app/payment/success';

  static const String _failureUrl =
      'https://seva.app/payment/failure';

  @override
  void initState() {
    super.initState();

    _transactionUuid =
        EsewaPaymentService.createTransactionUuid();

    _setupWebView();
  }

  void _setupWebView() {
    final html =
    EsewaPaymentService.createHtmlForm(
      amount: widget.amount,
      transactionUuid: _transactionUuid,
      successUrl: _successUrl,
      failureUrl: _failureUrl,
    );

    _controller = WebViewController()
      ..setJavaScriptMode(
        JavaScriptMode.unrestricted,
      )
      ..setBackgroundColor(
        Colors.white,
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (url) {
            if (!mounted) return;

            setState(() {
              _isLoading = true;
            });
          },
          onPageFinished: (url) {
            if (!mounted) return;

            setState(() {
              _isLoading = false;
            });
          },
          onNavigationRequest: (request) {
            final url = request.url;

            if (url.startsWith(_successUrl)) {
              _handleSuccess();
              return NavigationDecision.prevent;
            }

            if (url.startsWith(_failureUrl)) {
              _handleFailure();
              return NavigationDecision.prevent;
            }

            return NavigationDecision.navigate;
          },
          onWebResourceError: (error) {
            debugPrint(
              'eSewa WebView error: '
                  '${error.description}',
            );
          },
        ),
      )
      ..loadHtmlString(
        html,
        baseUrl: 'https://seva.app',
      );
  }

  void _handleSuccess() {
    if (_paymentFinished) {
      return;
    }

    _paymentFinished = true;

    Navigator.of(context).pop(true);
  }

  void _handleFailure() {
    if (_paymentFinished) {
      return;
    }

    _paymentFinished = true;

    Navigator.of(context).pop(false);
  }

  Future<bool> _confirmExit() async {
    if (_paymentFinished) {
      return true;
    }

    final shouldExit =
    await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            'Cancel payment?',
          ),
          content: const Text(
            'Your subscription will not be activated '
                'if you leave before completing the payment.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  context,
                  false,
                );
              },
              child: const Text(
                'Continue payment',
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(
                  context,
                  true,
                );
              },
              child: const Text(
                'Cancel payment',
              ),
            ),
          ],
        );
      },
    );

    return shouldExit ?? false;
  }

  Future<void> _closePayment() async {
    final shouldExit =
    await _confirmExit();

    if (!shouldExit || !mounted) {
      return;
    }

    _paymentFinished = true;

    Navigator.of(context).pop(false);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (
          didPop,
          result,
          ) async {
        if (didPop) {
          return;
        }

        await _closePayment();
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            onPressed: _closePayment,
            icon: const Icon(
              Icons.close_rounded,
            ),
          ),
          titleSpacing: 4,
          title: Column(
            crossAxisAlignment:
            CrossAxisAlignment.start,
            children: [
              const Text(
                'Pay with eSewa',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                '${widget.planTitle} · '
                    'Rs. ${widget.amount}',
                style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFF667085),
                ),
              ),
            ],
          ),
        ),
        body: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 10,
              ),
              color: const Color(
                0xFFF2FAF0,
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.shield_outlined,
                    size: 18,
                    color: Color(
                      0xFF60BB46,
                    ),
                  ),
                  SizedBox(
                    width: 8,
                  ),
                  Expanded(
                    child: Text(
                      'eSewa test payment mode',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight:
                        FontWeight.w600,
                        color: Color(
                          0xFF3F7E32,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: Stack(
                children: [
                  WebViewWidget(
                    controller: _controller,
                  ),

                  if (_isLoading)
                    const Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      child: LinearProgressIndicator(
                        minHeight: 2,
                        color: Color(
                          0xFF60BB46,
                        ),
                      ),
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