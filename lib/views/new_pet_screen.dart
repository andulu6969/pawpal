import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart'; // Required for kIsWeb check
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import '../myconfig.dart';
import '../models/user.dart';

class NewPetScreen extends StatefulWidget {
  final User user;
  const NewPetScreen({super.key, required this.user});

  @override
  State<NewPetScreen> createState() => _NewPetScreenState();
}

class _NewPetScreenState extends State<NewPetScreen> {
  // --- CONTROLLERS ---
  // Captures text input from the user
  TextEditingController nameController = TextEditingController();
  TextEditingController ageController = TextEditingController();
  TextEditingController descController = TextEditingController();
  TextEditingController latController = TextEditingController();
  TextEditingController lngController = TextEditingController();

  // --- DROPDOWN DATA SOURCES ---
  List<String> petTypes = ['Cat', 'Dog', 'Rabbit', 'Other'];
  List<String> categories = ['Adoption', 'Donation'];

  // RUBRIC UPDATE: Added Gender and Health Lists
  List<String> genders = ['Male', 'Female'];
  List<String> healthStatus = [
    'Healthy',
    'Vaccinated',
    'Needs Treatment',
    'Recovering',
  ];

  // --- STATE VARIABLES ---
  // Default selections for dropdowns
  String selectedType = 'Cat';
  String selectedCategory = 'Adoption';
  String selectedGender = 'Male';
  String selectedHealth = 'Healthy';

  // Stores images selected from gallery
  List<XFile> imageList = [];
  final ImagePicker _picker = ImagePicker();

  // --- FUNCTION: Image Picker ---
  // Allows user to select multiple images (Max 3)
  Future<void> _selectImages() async {
    final List<XFile> selectedImages = await _picker.pickMultiImage();
    if (selectedImages.isNotEmpty) {
      if (selectedImages.length + imageList.length > 3) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Maximum 3 images allowed")),
        );
      } else {
        setState(() {
          imageList.addAll(selectedImages);
        });
      }
    }
  }

  // --- FUNCTION: Submit Data to Backend ---
  Future<void> submitPet() async {
    String name = nameController.text.trim();
    String age = ageController.text.trim();
    String desc = descController.text.trim();
    String lat = latController.text.trim();
    String lng = lngController.text.trim();

    // 1. Basic Validation
    if (name.isEmpty || age.isEmpty || desc.isEmpty || imageList.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please fill all fields and add at least 1 image"),
        ),
      );
      return;
    }

    // 2. Image Processing (File -> Bytes -> Base64)
    // We must convert images to Base64 strings to send them via JSON
    List<String> base64Images = [];
    for (var file in imageList) {
      // Read bytes safely (Works on Web & Mobile)
      List<int> imageBytes = await file.readAsBytes();
      base64Images.add(base64Encode(imageBytes));
    }
    String imagesJson = jsonEncode(base64Images);

    // 3. HTTP POST Request
    http
        .post(
          Uri.parse("${MyConfig.baseUrl}/pawpal/api/submit_pet.php"),
          body: {
            "user_id": widget.user.id,
            "pet_name": name,
            "pet_age": age,
            "pet_gender": selectedGender,
            "pet_health": selectedHealth,
            "pet_type": selectedType,
            "category": selectedCategory,
            "description": desc,
            "lat": lat,
            "lng": lng,
            "image": imagesJson, // Send the JSON string of images
          },
        )
        .then((response) {
          if (response.statusCode == 200) {
            var data = jsonDecode(response.body);
            if (data['status'] == 'success') {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Pet Submitted Successfully!")),
              );
              Navigator.pop(context); // Return to Home Screen
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("Failed: ${data['message']}")),
              );
            }
          } else {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text("Server Error")));
          }
        });
  }

  // --- FUNCTION: Geolocation ---
  // Uses the 'geolocator' package to get current GPS coordinates
  Future<void> _determinePosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }

    Position pos = await Geolocator.getCurrentPosition();
    setState(() {
      latController.text = pos.latitude.toString();
      lngController.text = pos.longitude.toString();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Submit New Pet")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // --- SECTION 1: Image Picker ---
            GestureDetector(
              onTap: _selectImages,
              child: Container(
                height: 150,
                color: Colors.grey[200],
                child: imageList.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.camera_alt,
                              size: 50,
                              color: Colors.grey,
                            ),
                            Text("Tap to add up to 3 images"),
                          ],
                        ),
                      )
                    : ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: imageList.length,
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: const EdgeInsets.all(8.0),
                            // Helper to display images on both Web and Mobile
                            child: kIsWeb
                                ? Image.network(
                                    imageList[index].path,
                                    fit: BoxFit.cover,
                                  )
                                : Image.file(
                                    File(imageList[index].path),
                                    fit: BoxFit.cover,
                                  ),
                          );
                        },
                      ),
              ),
            ),
            const SizedBox(height: 20),

            // --- SECTION 2: Form Fields ---
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: "Pet Name",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),

            // Row 1: Type & Age
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField(
                    value: selectedType,
                    decoration: const InputDecoration(
                      labelText: "Type",
                      border: OutlineInputBorder(),
                    ),
                    items: petTypes
                        .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                        .toList(),
                    onChanged: (val) => setState(() => selectedType = val!),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: ageController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: "Age (Years)",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Row 2: Gender & Health
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField(
                    value: selectedGender,
                    decoration: const InputDecoration(
                      labelText: "Gender",
                      border: OutlineInputBorder(),
                    ),
                    items: genders
                        .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                        .toList(),
                    onChanged: (val) => setState(() => selectedGender = val!),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: DropdownButtonFormField(
                    value: selectedHealth,
                    decoration: const InputDecoration(
                      labelText: "Health",
                      border: OutlineInputBorder(),
                    ),
                    items: healthStatus
                        .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                        .toList(),
                    onChanged: (val) => setState(() => selectedHealth = val!),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Category Dropdown
            DropdownButtonFormField(
              value: selectedCategory,
              decoration: const InputDecoration(
                labelText: "Category",
                border: OutlineInputBorder(),
              ),
              items: categories
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: (val) => setState(() => selectedCategory = val!),
            ),
            const SizedBox(height: 10),

            // Description Area
            TextField(
              controller: descController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: "Description / Condition",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),

            // --- SECTION 3: Location ---
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: latController,
                    decoration: const InputDecoration(
                      labelText: "Latitude",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: lngController,
                    decoration: const InputDecoration(
                      labelText: "Longitude",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                IconButton(
                  onPressed: _determinePosition,
                  icon: const Icon(Icons.location_on, color: Colors.blue),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // --- SECTION 4: Submit Button ---
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: submitPet,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
                child: const Text("Submit Pet", style: TextStyle(fontSize: 18)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
