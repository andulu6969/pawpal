import 'dart:convert';
import 'dart:typed_data';
import 'dart:math'; // Required for Random/Timestamp (Cache busting)
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import '../models/user.dart';
import '../myconfig.dart';
import 'my_drawer.dart';

class ProfileScreen extends StatefulWidget {
  final User user;
  const ProfileScreen({super.key, required this.user});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // Input Controllers
  late TextEditingController nameCtrl;
  late TextEditingController phoneCtrl;
  late TextEditingController passCtrl;

  // State Variable to toggle View/Edit mode
  bool isEditing = false;

  // --- IMAGE HANDLING ---
  // We use Uint8List to store image bytes because it works on both
  // Mobile (IO) and Web, making the app cross-platform compatible.
  Uint8List? _imageBytes;
  final ImagePicker _picker = ImagePicker();

  // --- CACHE BUSTER ---
  // When a user updates their profile picture, the URL remains the same.
  // Browsers/Flutter cache images by URL. This random number is appended
  // to the URL (?v=123) to force the app to fetch the *new* image.
  int val = 0;

  @override
  void initState() {
    super.initState();
    // Initialize controllers with current user data
    nameCtrl = TextEditingController(text: widget.user.name);
    phoneCtrl = TextEditingController(text: widget.user.phone);
    passCtrl = TextEditingController();
  }

  // --- FUNCTION: Pick Image ---
  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
    );
    if (pickedFile != null) {
      // Convert file to bytes immediately
      final bytes = await pickedFile.readAsBytes();
      setState(() {
        _imageBytes = bytes;
      });
    }
  }

  // --- FUNCTION: Update Profile API ---
  void updateProfile() {
    String newName = nameCtrl.text.trim();
    String newPhone = phoneCtrl.text.trim();
    String newPass = passCtrl.text.trim();
    String base64Image = "NA"; // Default flag if no image selected

    // 1. Encode Image if a new one was picked
    if (_imageBytes != null) {
      base64Image = base64Encode(_imageBytes!);
    }

    // 2. Validate Inputs
    if (newName.isEmpty || newPhone.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Name and Phone required")));
      return;
    }

    // 3. Send Data to Server
    http
        .post(
          Uri.parse("${MyConfig.baseUrl}/pawpal/api/update_profile.php"),
          body: {
            "user_id": widget.user.id,
            "name": newName,
            "phone": newPhone,
            // Send "NA" if password field is empty (backend ignores it)
            "password": newPass.isEmpty ? "NA" : newPass,
            "image": base64Image,
          },
        )
        .then((response) {
          if (response.statusCode == 200) {
            var data = jsonDecode(response.body);
            if (data['status'] == 'success') {
              setState(() {
                // Update local user object to reflect changes immediately
                widget.user.name = newName;
                widget.user.phone = newPhone;
                isEditing = false;
                passCtrl.clear();
                _imageBytes = null; // Clear picked image to show network image

                // Generate new random number to refresh the profile picture
                val = Random().nextInt(1000);
              });

              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text("Profile Updated!")));

              // Clear global image cache to ensure sidebar drawer also updates
              PaintingBinding.instance.imageCache.clear();
            } else {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text("Update Failed")));
            }
          }
        });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text("My Profile", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.blue.shade800,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      drawer: MyDrawer(user: widget.user),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // --- HEADER SECTION (Blue Background + Avatar) ---
            Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                // Blue Curve Background
                Container(
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.blue.shade800,
                    borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(50),
                    ),
                  ),
                ),
                // Profile Picture (Floating)
                Positioned(
                  top: 50,
                  child: GestureDetector(
                    // Only allow tapping image to change if in Edit Mode
                    onTap: isEditing ? _pickImage : null,
                    child: Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                          ),
                          child: CircleAvatar(
                            radius: 65,
                            backgroundColor: Colors.grey[200],
                            // LOGIC: Show picked image preview OR Network image
                            backgroundImage: _imageBytes != null
                                ? MemoryImage(_imageBytes!) as ImageProvider
                                : NetworkImage(
                                    // Append random 'val' to force refresh
                                    "${MyConfig.baseUrl}/pawpal/assets/profile/${widget.user.id}.jpg?v=$val",
                                  ),
                            onBackgroundImageError: (e, s) => const Icon(
                              Icons.person,
                              size: 60,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                        // Camera Icon overlay (Visible only in Edit Mode)
                        if (isEditing)
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade800,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: const Icon(
                              Icons.camera_alt,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 70), // Spacer for floating avatar
            // --- FORM SECTION ---
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Static Name/Email Display
                  Text(
                    widget.user.name ?? "User",
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    widget.user.email ?? "email@example.com",
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 30),

                  // Name Field
                  TextField(
                    controller: nameCtrl,
                    enabled: isEditing, // Disabled unless editing
                    decoration: const InputDecoration(
                      labelText: "Full Name",
                      prefixIcon: Icon(Icons.person),
                    ),
                  ),
                  const SizedBox(height: 15),

                  // Phone Field
                  TextField(
                    controller: phoneCtrl,
                    enabled: isEditing,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: "Phone",
                      prefixIcon: Icon(Icons.phone),
                    ),
                  ),
                  const SizedBox(height: 15),

                  // Password Field (Only visible when editing)
                  if (isEditing)
                    TextField(
                      controller: passCtrl,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: "New Password",
                        prefixIcon: Icon(Icons.lock),
                      ),
                    ),
                  const SizedBox(height: 30),

                  // Action Button (Edit / Save)
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: () {
                        if (isEditing) {
                          updateProfile(); // Save
                        } else {
                          setState(() => isEditing = true); // Enable Edit Mode
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isEditing
                            ? Colors.green
                            : Colors.blue.shade800,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      child: Text(
                        isEditing ? "Save Changes" : "Edit Profile",
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                  // Cancel Button (Only visible when editing)
                  if (isEditing)
                    TextButton(
                      onPressed: () => setState(() {
                        isEditing = false;
                        _imageBytes = null; // Discard selected image
                      }),
                      child: const Text(
                        "Cancel",
                        style: TextStyle(color: Colors.red),
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
