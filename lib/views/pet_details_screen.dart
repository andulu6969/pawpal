import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../myconfig.dart';
import '../models/user.dart';
import '../models/pet.dart';
import 'donation_screen.dart';

class PetDetailsScreen extends StatefulWidget {
  final User user;
  final Pet pet;
  const PetDetailsScreen({super.key, required this.user, required this.pet});

  @override
  State<PetDetailsScreen> createState() => _PetDetailsScreenState();
}

class _PetDetailsScreenState extends State<PetDetailsScreen> {
  // Tracks current image for the PageView slider
  int _currentImageIndex = 0;

  // --- UI: Show Adoption Request Dialog ---
  // Opens a pop-up form for users to enter their motivation message
  void showAdoptionForm() {
    TextEditingController msgCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: Row(children: [const Text("Adopt Me")]),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Motivational Quote Box
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade100),
              ),
              child: const Text(
                "\"Adopting a pet saves a life. Please give this little one a forever home!\"",
                style: TextStyle(
                  fontStyle: FontStyle.italic,
                  color: Colors.blue,
                  fontSize: 13,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 15),

            // Input Field
            const Text(
              "Tell us your reason for adoption:",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: msgCtrl,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: "Enter your reason here...",
                hintStyle: TextStyle(color: Colors.grey.shade400),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.all(12),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              if (msgCtrl.text.isNotEmpty) {
                _submitAdoption(msgCtrl.text);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Please write a message")),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade800,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text("Submit Request"),
          ),
        ],
      ),
    );
  }

  // --- API: Submit Adoption Request ---
  void _submitAdoption(String message) {
    http
        .post(
          Uri.parse("${MyConfig.baseUrl}/pawpal/api/insert_adoption.php"),
          body: {
            "user_id": widget.user.id,
            "pet_id": widget.pet.petId,
            "message": message,
          },
        )
        .then((response) {
          if (response.statusCode == 200) {
            var data = jsonDecode(response.body);
            if (data['status'] == 'success') {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Adoption Request Sent Successfully!"),
                ),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text("Failed: ${data['message'] ?? 'Error'}"),
                ),
              );
            }
          }
        });
  }

  // --- NAV: Go to Donation Screen ---
  void goToDonation() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (c) => DonationScreen(
          user: widget.user,
          // Pass both User ID (Owner) and Pet ID to link the donation correctly
          petOwnerId: widget.pet.userId,
          petId: widget.pet.petId,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 1. Ownership Check
    // Prevents users from adopting/donating to their own pets
    bool isOwner = widget.user.id == widget.pet.userId;

    // Decode image paths from JSON string
    List images = [];
    try {
      images = jsonDecode(widget.pet.imagePaths!);
    } catch (e) {}

    // Determine Mode: Adoption or Donation
    bool isAdoption = widget.pet.category == "Adoption";

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // --- Section 1: Image Slider ---
          SliverAppBar(
            expandedHeight: 350.0,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: images.isEmpty
                  ? Container(
                      color: Colors.grey[300],
                      child: const Center(child: Icon(Icons.image, size: 50)),
                    )
                  : Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        PageView.builder(
                          onPageChanged: (i) =>
                              setState(() => _currentImageIndex = i),
                          itemCount: images.length,
                          itemBuilder: (c, i) => Image.network(
                            "${MyConfig.baseUrl}/pawpal/assets/pets/${images[i]}",
                            fit: BoxFit.cover,
                            errorBuilder: (c, o, s) =>
                                const Icon(Icons.broken_image),
                          ),
                        ),
                        // Image Counter Indicator (e.g., 1/3)
                        if (images.length > 1)
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black54,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                "${_currentImageIndex + 1} / ${images.length}",
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                          ),
                      ],
                    ),
            ),
          ),

          // --- Section 2: Pet Details ---
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          widget.pet.petName ?? "Unknown Name",
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      // Category Badge
                      Chip(
                        label: Text(
                          widget.pet.category ?? "General",
                          style: TextStyle(
                            color: isAdoption
                                ? Colors.orange[900]
                                : Colors.blue[900],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        backgroundColor: isAdoption
                            ? Colors.orange[100]
                            : Colors.blue[100],
                      ),
                    ],
                  ),
                  Text(
                    "Posted by: ${widget.pet.ownerName ?? 'Unknown User'}",
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Info Cards (Type, Gender, Age, Health)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      children: [
                        _buildDetailRow(Icons.pets, "Type", widget.pet.petType),
                        const Divider(),
                        _buildDetailRow(
                          Icons.male,
                          "Gender",
                          widget.pet.petGender ?? "NA",
                        ),
                        const Divider(),
                        _buildDetailRow(
                          Icons.cake,
                          "Age",
                          "${widget.pet.petAge} Years",
                        ),
                        const Divider(),
                        _buildDetailRow(
                          Icons.local_hospital,
                          "Health",
                          widget.pet.petHealth ?? "NA",
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 25),

                  // Description Text
                  const Text(
                    "About Me",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.pet.description ?? "No description provided.",
                    style: const TextStyle(
                      fontSize: 16,
                      height: 1.5,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),

      // --- Section 3: Action Button ---
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SizedBox(
          height: 50,
          child: ElevatedButton(
            onPressed: () {
              // 2. BLOCK OWNER ACTIONS
              if (isOwner) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      "You cannot adopt or donate to your own pet.",
                    ),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              // Dynamic Action: Adopt or Donate
              if (isAdoption) {
                showAdoptionForm();
              } else {
                goToDonation();
              }
            },
            style: ElevatedButton.styleFrom(
              // Change color based on status (Grey if Owner)
              backgroundColor: isOwner
                  ? Colors.grey
                  : (isAdoption ? Colors.orange : Colors.blue),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              elevation: 2,
            ),
            child: Text(
              // Change text based on status
              isOwner
                  ? "Owner (Restricted)"
                  : (isAdoption ? "Request to Adopt" : "Donate Now"),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Helper Widget for Detail Rows
  Widget _buildDetailRow(IconData icon, String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, color: Colors.blueGrey, size: 20),
          const SizedBox(width: 12),
          SizedBox(
            width: 80,
            child: Text(
              "$label:",
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value ?? "-",
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}
