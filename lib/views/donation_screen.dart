import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // REQUIRED for Input Validation
import 'package:http/http.dart' as http;
import '../myconfig.dart';
import '../models/user.dart';
import 'payment_screen.dart';
import 'my_drawer.dart';

class DonationScreen extends StatefulWidget {
  final User user;
  final String? prefilledDescription;

  // These IDs help us link the donation to a pet
  // and prevent the owner from donating to themselves.
  final String? petOwnerId;
  final String? petId;

  const DonationScreen({
    super.key,
    required this.user,
    this.prefilledDescription,
    this.petOwnerId,
    this.petId,
  });

  @override
  State<DonationScreen> createState() => _DonationScreenState();
}

class _DonationScreenState extends State<DonationScreen> {
  String selectedType = "Money";
  TextEditingController amountCtrl = TextEditingController();
  TextEditingController descCtrl = TextEditingController();
  List history = [];
  bool isLoading = true;

  @override
  void initState() {
    if (widget.prefilledDescription != null) {
      descCtrl.text = widget.prefilledDescription!;
    }
    super.initState();
    loadHistory();
  }

  // --- 1. Fetch History from Server ---
  void loadHistory() {
    http
        .get(
          Uri.parse(
            "${MyConfig.baseUrl}/pawpal/api/load_donations.php?user_id=${widget.user.id}",
          ),
        )
        .then((response) {
          if (response.statusCode == 200) {
            var data = jsonDecode(response.body);
            if (mounted) {
              setState(() {
                history = data['data'] ?? [];
                isLoading = false;
              });
            }
          }
        });
  }

  // --- 2. Submit Logic with Strict Validation ---
  void submitDonation() {
    // A. Validation for Money Donations
    if (selectedType == "Money") {
      String rawAmount = amountCtrl.text.trim();

      // Check 1: Is it empty?
      if (rawAmount.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Please enter an amount"),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Check 2: Is it a valid number? (Prevents hidden characters)
      double? value = double.tryParse(rawAmount);
      if (value == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Invalid number format"),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Check 3: Is it positive? (Prevents negative numbers or 0)
      if (value <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Amount must be greater than RM 0.00"),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    // B. Validation for Item Donations
    if (selectedType != "Money" && descCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please describe the item"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // C. Send Data to Server
    http
        .post(
          Uri.parse("${MyConfig.baseUrl}/pawpal/api/insert_donation.php"),
          body: {
            "user_id": widget.user.id,
            "pet_id":
                widget.petId ??
                "0", // Links donation to specific pet (or 0 if general)
            "type": selectedType,
            "amount": selectedType == "Money" ? amountCtrl.text : "0",
            "description": descCtrl.text,
          },
        )
        .then((response) {
          if (response.statusCode == 200) {
            var data = jsonDecode(response.body);
            if (data['status'] == 'success') {
              if (selectedType == "Money") {
                // Navigate to Payment Gateway
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (c) => PaymentScreen(
                      user: widget.user,
                      amount: double.parse(amountCtrl.text),
                      orderId: data['id'].toString(),
                    ),
                  ),
                ).then(
                  (_) => loadHistory(),
                ); // Refresh history when they return
              } else {
                // Direct Success for Food/Medical
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Pledge Recorded Successfully!"),
                    backgroundColor: Colors.green,
                  ),
                );
                loadHistory();
                descCtrl.clear();
              }
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Server Error"),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        });
  }

  @override
  Widget build(BuildContext context) {
    // Only show the donation form if a specific pet was selected
    bool canDonate = widget.petId != null;

    // RESTRICTION: Block owner from donating to their own pet
    if (canDonate && widget.petOwnerId == widget.user.id) {
      return Scaffold(
        appBar: AppBar(title: const Text("Donation Restricted")),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(30.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.block, size: 80, color: Colors.grey),
                const SizedBox(height: 20),
                const Text(
                  "You cannot donate to your own pet.",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 30),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Go Back"),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[100],
      drawer: MyDrawer(user: widget.user),
      appBar: AppBar(
        title: const Text(
          "Donation Hub",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.blue.shade800,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- SECTION 1: DONATION FORM ---
            if (canDonate)
              Container(
                padding: const EdgeInsets.all(20),
                color: Colors.white,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "I want to donate:",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 15),
                    Row(
                      children: [
                        _buildTypeCard(
                          "Money",
                          Icons.attach_money,
                          Colors.green,
                        ),
                        const SizedBox(width: 10),
                        _buildTypeCard("Food", Icons.fastfood, Colors.orange),
                        const SizedBox(width: 10),
                        _buildTypeCard(
                          "Medical",
                          Icons.local_hospital,
                          Colors.red,
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // --- INPUT FIELD WITH VALIDATION ---
                    if (selectedType == "Money")
                      TextField(
                        controller: amountCtrl,
                        // 1. Force Numeric Keyboard
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        // 2. Strict Input Formatting (Digits and Dots only)
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                            RegExp(r'^\d+\.?\d{0,2}'),
                          ),
                        ],
                        decoration: InputDecoration(
                          labelText: "Amount (RM)",
                          prefixText: "RM ",
                          hintText: "e.g. 10.00",
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          filled: true,
                          fillColor: Colors.grey[50],
                        ),
                      )
                    else
                      TextField(
                        controller: descCtrl,
                        decoration: InputDecoration(
                          labelText: selectedType == "Food"
                              ? "Item Description"
                              : "Medicine Name",
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          filled: true,
                          fillColor: Colors.grey[50],
                        ),
                      ),

                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: submitDonation,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue[800],
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: Text(
                          "Proceed with $selectedType",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // --- SECTION 2: DONATION HISTORY ---
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 25, 20, 10),
              child: Row(
                children: [
                  const Text(
                    "My Donation History",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  if (!canDonate) ...[
                    const Spacer(),
                    Text(
                      "(Select a pet to donate)",
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ],
              ),
            ),

            isLoading
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: CircularProgressIndicator(),
                    ),
                  )
                : history.isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(30),
                      child: Text("No donations yet."),
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: history.length,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemBuilder: (context, index) {
                      var item = history[index];
                      bool isMoney = item['donation_type'] == "Money";
                      String status = item['payment_status'] ?? "Pending";
                      String petName = item['pet_name'] ?? "Unknown Pet";

                      return Card(
                        elevation: 2,
                        margin: const EdgeInsets.only(bottom: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: isMoney
                                ? Colors.green.shade100
                                : Colors.orange.shade100,
                            child: Icon(
                              isMoney ? Icons.attach_money : Icons.inventory,
                              color: isMoney ? Colors.green : Colors.orange,
                            ),
                          ),
                          title: Text(
                            isMoney
                                ? "RM ${item['amount']}"
                                : item['donation_type'],
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            "To: $petName\n${isMoney ? "Payment ID: ${item['donation_id']}" : item['description']}",
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                item['donation_date'].toString().substring(
                                  0,
                                  10,
                                ),
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: status == "Success"
                                      ? Colors.green
                                      : Colors.grey,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  status,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
            const SizedBox(height: 50),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeCard(String type, IconData icon, Color color) {
    bool isSelected = selectedType == type;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => selectedType = type),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 80,
          decoration: BoxDecoration(
            color: isSelected ? color.withOpacity(0.1) : Colors.white,
            border: Border.all(
              color: isSelected ? color : Colors.grey.shade300,
              width: 2,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: isSelected ? color : Colors.grey, size: 28),
              const SizedBox(height: 5),
              Text(
                type,
                style: TextStyle(
                  color: isSelected ? color : Colors.grey,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
