import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/user.dart';
import '../myconfig.dart';

class PaymentScreen extends StatefulWidget {
  final User user;
  final double amount;
  final String orderId;

  const PaymentScreen({
    super.key,
    required this.user,
    required this.amount,
    required this.orderId,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  @override
  void initState() {
    super.initState();
    // Automatically trigger the payment gateway when the screen loads
    _launchPaymentUrl();
  }

  // --- FUNCTION: Launch External Payment Gateway ---
  // We use the 'url_launcher' package to open the system browser.
  // This avoids issues with in-app WebViews blocking secure payment redirects.
  Future<void> _launchPaymentUrl() async {
    // 1. Construct the API URL with query parameters
    final String url =
        '${MyConfig.baseUrl}/pawpal/api/payment.php?email=${widget.user.email}&mobile=${widget.user.phone}&name=${widget.user.name}&amount=${widget.amount}&orderid=${widget.orderId}';

    final Uri uri = Uri.parse(url);

    // 2. Launch the URL in an external application (Chrome/Safari)
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Could not launch payment page")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Payment")),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // --- UI: Status Indicator ---
            const Icon(Icons.receipt_long, size: 80, color: Colors.blue),
            const SizedBox(height: 20),

            const Text(
              "Payment in Progress",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),

            const Text(
              "We have opened the payment gateway in your browser.\n\nPlease complete the transaction there, then return here to confirm.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),

            const SizedBox(height: 40),

            // --- BUTTON 1: Completion ---
            // When pressed, we simply close this screen.
            // The previous screen (DonationScreen) listens for this .pop()
            // and automatically refreshes the history list to show the new status.
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  "I Have Completed Payment",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // --- BUTTON 2: Retry Mechanism ---
            // In case pop-up blockers prevented the first launch
            TextButton.icon(
              onPressed: _launchPaymentUrl,
              icon: const Icon(Icons.open_in_browser),
              label: const Text("Browser didn't open? Tap to retry"),
            ),
          ],
        ),
      ),
    );
  }
}
