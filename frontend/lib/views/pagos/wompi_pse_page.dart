import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;

class WompiPSEPage extends StatefulWidget {
  const WompiPSEPage({
    super.key,
    required this.montoCOP,
    required this.referencia,
    this.redirectUrl,
    this.descripcion,
  });

  final int montoCOP; // en pesos colombianos (COP)
  final String referencia; // referencia única por transacción
  final String? redirectUrl; // opcional: si no se pasa, se usa una por defecto
  final String? descripcion; // opcional

  @override
  State<WompiPSEPage> createState() => _WompiPSEPageState();
}

class _WompiPSEPageState extends State<WompiPSEPage> {
  late final WebViewController _controller;
  bool _loading = true;
  String? _error;
  Uri? _lastCheckoutUri;
  bool _fallingBack = false;
  bool _isSandbox = true;

  @override
  void initState() {
    super.initState();
    _initWebView();
  }

  Future<void> _initWebView() async {
    final publicKey = dotenv.env['WOMPI_PUBLIC_KEY'];
    if (publicKey == null || publicKey.isEmpty) {
      setState(() => _error = 'Falta WOMPI_PUBLIC_KEY en .env');
      return;
    }
    // Define el entorno (sandbox vs producción) a partir de la public key
    _isSandbox = publicKey.startsWith('pub_test_');
    // Firma de integridad (requerida por Wompi)
    final integritySecret = dotenv.env['WOMPI_INTEGRITY_SECRET'];
    if (integritySecret == null || integritySecret.isEmpty) {
      setState(
        () => _error = 'Falta WOMPI_INTEGRITY_SECRET en .env (Sandbox).',
      );
      return;
    }
    String redirectUrl = widget.redirectUrl ??
        dotenv.env['WOMPI_REDIRECT_URL'] ??
        'https://transaction-redirect.wompi.co/check';
    // Evita usar una URL de checkout como redirect (causa errores). Usa el redirect oficial de Wompi si es el caso.
    try {
      final r = Uri.parse(redirectUrl);
      if (r.host.contains('checkout.wompi.co')) {
        redirectUrl = 'https://transaction-redirect.wompi.co/check';
      }
    } catch (_) {}

    // Cálculo de signature: sha256(reference + amountInCents + currency + integritySecret)
    final amountInCents = (widget.montoCOP * 100).toString().trim();
    final currency = 'COP';
    final reference = widget.referencia.trim();
    final secret = integritySecret.trim();
    final toSign = '$reference$amountInCents$currency$secret';
    final signature = sha256.convert(utf8.encode(toSign)).toString();
    // Debug seguro (no imprime el secreto):
    // ignore: avoid_print
    print(
      '[Wompi] firma -> ref="$reference" amount="$amountInCents" currency="$currency" secretLen=${secret.length} hash=${signature.substring(0, 6)}...',
    );

    final params = <String, String>{
      'public-key': publicKey,
      'currency': currency,
      'amount-in-cents': amountInCents,
      'reference': reference,
      'redirect-url': redirectUrl,

      // Enviar la firma en forma anidada, no como JSON:
      'signature:integrity': signature,
      // Algunas integraciones aceptan también esta forma:
      'signature[integrity]': signature,

      'country': 'CO',
      // (Opcional) Restringe solo a PSE si quieres evitar otros métodos:
      'payment-methods-allowed': 'PSE',
    };

    final uri = Uri.https('checkout.wompi.co', '/p/', params);
    // Debug visible en logs
    // ignore: avoid_print
    print('Wompi URL: $uri');
    _lastCheckoutUri = uri;

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (url) {
            setState(() => _loading = true);
          },
          onPageFinished: (url) {
            setState(() => _loading = false);
          },
          onNavigationRequest: (request) {
            // Intercepta cuando Wompi redirige a la redirect-url
            if (request.url.startsWith(redirectUrl)) {
              final uri = Uri.parse(request.url);
              final transactionId = uri.queryParameters['id'];
              if (transactionId != null && transactionId.isNotEmpty) {
                setState(() => _loading = true);
                _checkStatusAndClose(transactionId); // hace polling y cierra
              } else {
                Navigator.of(context).pop({
                  'approved': false,
                  'pending': true,
                  'status': 'PENDING',
                  'transactionId': null,
                });
              }
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
          onWebResourceError: (error) async {
            final isCsp = error.description.contains('ERR_BLOCKED_BY_CSP') ||
                error.errorCode == -1;
            if (isCsp && !_fallingBack && _lastCheckoutUri != null) {
              _fallingBack = true;
              // Intenta abrir en navegador externo (soluciona CSP del WebView)
              if (await canLaunchUrl(_lastCheckoutUri!)) {
                await launchUrl(
                  _lastCheckoutUri!,
                  mode: LaunchMode.externalApplication,
                );
                if (mounted) {
                  setState(() {
                    _error =
                        'Se abrió Wompi en el navegador externo debido a restricciones CSP del WebView.';
                  });
                }
                return;
              }
            }
            if (mounted) {
              setState(
                () => _error =
                    'No se pudo cargar el checkout: ${error.errorCode} - ${error.description}.\nVerifica tu WOMPI_PUBLIC_KEY y conexión a Internet.',
              );
            }
          },
        ),
      )
      ..loadRequest(uri);
  }

  Future<void> _checkStatusAndClose(String transactionId) async {
    final host = _isSandbox ? 'sandbox.wompi.co' : 'production.wompi.co';
    String status = 'PENDING';
    Map<String, dynamic>? wompiData;

    for (var i = 0; i < 12; i++) {
      // ~60s
      try {
        final url = Uri.https(host, '/v1/transactions/$transactionId');
        final res = await http.get(url).timeout(const Duration(seconds: 8));
        if (res.statusCode == 200) {
          final map = jsonDecode(res.body) as Map<String, dynamic>;
          wompiData = map['data'] as Map<String, dynamic>?;
          status = (wompiData?['status'] ?? 'PENDING').toString();
          if (status != 'PENDING') {
            if (!mounted) return;
            Navigator.of(context).pop({
              'approved': status == 'APPROVED',
              'pending': false,
              'status': status,
              'transactionId': transactionId,
              'wompi': wompiData,
            });
            return;
          }
        }
      } catch (_) {
        // reintenta
      }
      await Future.delayed(const Duration(seconds: 5));
    }

    if (!mounted) return;
    Navigator.of(context).pop({
      'approved': false,
      'pending': true,
      'status': status, // probablemente PENDING
      'transactionId': transactionId,
      'wompi': wompiData,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pago PSE (Wompi Sandbox)')),
      body: _error != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Error: $_error',
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : Stack(
              children: [
                WebViewWidget(controller: _controller),
                if (_loading) const LinearProgressIndicator(minHeight: 3),
              ],
            ),
    );
  }
}
