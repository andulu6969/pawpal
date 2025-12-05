import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../myconfig.dart';
import '../models/user.dart';
import 'login_screen.dart';
import 'new_pet_screen.dart';

class HomeScreen extends StatefulWidget {
  final User user;
  const HomeScreen({super.key, required this.user});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // MyFuwu Style Variables
  List petList = [];
  String status = "Loading...";
  late double screenWidth, screenHeight;

  @override
  void initState() {
    super.initState();
    loadPets();
  }

  @override
  Widget build(BuildContext context) {
    // MyFuwu Responsive Logic
    screenWidth = MediaQuery.of(context).size.width;
    screenHeight = MediaQuery.of(context).size.height;
    if (screenWidth > 600) {
      screenWidth = 600;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("My Submissions"),
        actions: [
          IconButton(
            onPressed: () {
              loadPets();
            },
            icon: const Icon(Icons.refresh),
          ),
          IconButton(
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
              );
            },
            icon: const Icon(Icons.exit_to_app), // Changed login to exit/logout
          ),
        ],
      ),
      body: Center(
        child: SizedBox(
          width: screenWidth,
          child: Column(
            children: [
              petList.isEmpty
                  ? Expanded(
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.find_in_page_outlined, size: 64),
                            const SizedBox(height: 12),
                            Text(
                              status,
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 18),
                            ),
                          ],
                        ),
                      ),
                    )
                  : Expanded(
                      child: ListView.builder(
                        itemCount: petList.length,
                        itemBuilder: (BuildContext context, int index) {
                          // Extract Data
                          var pet = petList[index];

                          // Handle Image JSON logic inside builder
                          List images = [];
                          try {
                            images = jsonDecode(pet['image_paths']);
                          } catch (e) {
                            images = [];
                          }
                          String firstImage = images.isNotEmpty
                              ? images[0]
                              : "";

                          return Card(
                            elevation: 4, // MyFuwu style
                            margin: const EdgeInsets.symmetric(
                              vertical: 6,
                              horizontal: 8,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(10),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // IMAGE (MyFuwu Style ClipRRect)
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Container(
                                      width: screenWidth * 0.28,
                                      height: screenWidth * 0.22,
                                      color: Colors.grey[200],
                                      child: firstImage.isNotEmpty
                                          ? Image.network(
                                              "${MyConfig.baseUrl}/pawpal/assets/pets/$firstImage",
                                              fit: BoxFit.cover,
                                              errorBuilder:
                                                  (context, error, stackTrace) {
                                                    return const Icon(
                                                      Icons.broken_image,
                                                      size: 60,
                                                      color: Colors.grey,
                                                    );
                                                  },
                                            )
                                          : const Icon(
                                              Icons.pets,
                                              size: 60,
                                              color: Colors.grey,
                                            ),
                                    ),
                                  ),

                                  const SizedBox(width: 12),

                                  // TEXT AREA
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        // TITLE (Pet Name)
                                        Text(
                                          pet['pet_name'].toString(),
                                          style: const TextStyle(
                                            fontSize: 17,
                                            fontWeight: FontWeight.w600,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),

                                        const SizedBox(height: 4),

                                        // DESCRIPTION
                                        Text(
                                          pet['description'].toString(),
                                          style: const TextStyle(
                                            fontSize: 14,
                                            color: Colors.black87,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),

                                        const SizedBox(height: 6),

                                        // TAG (Type/Category) - MyFuwu BlueGrey Tag
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.blueGrey.withOpacity(
                                              0.15,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          child: Text(
                                            "${pet['pet_type']} - ${pet['category']}",
                                            style: const TextStyle(
                                              fontSize: 13,
                                              color: Colors.blueGrey,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  // ARROW BUTTON (MyFuwu Style)
                                  IconButton(
                                    onPressed: () {
                                      // Optional: showDetailsDialog(index);
                                    },
                                    icon: const Icon(
                                      Icons.arrow_forward_ios,
                                      size: 18,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => NewPetScreen(user: widget.user),
            ),
          );
          loadPets();
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  // MyFuwu Style Load Function
  void loadPets() {
    petList.clear();
    setState(() {
      status = "Loading...";
    });

    http
        .get(
          Uri.parse(
            "${MyConfig.baseUrl}/pawpal/api/load_pets.php?user_id=${widget.user.id}",
          ),
        )
        .then((response) {
          if (response.statusCode == 200) {
            var jsonResponse = jsonDecode(response.body);

            // MyFuwu Logic Check
            if (jsonResponse['status'] == 'success' &&
                jsonResponse['data'] != null) {
              // Check if data is not empty list
              if (jsonResponse['data'].isNotEmpty) {
                setState(() {
                  petList = jsonResponse['data'];
                  status = ""; // Clear status on success
                });
              } else {
                setState(() {
                  status = "No submissions yet"; // "Not Available" equivalent
                });
              }
            } else {
              setState(() {
                petList.clear();
                status = "No submissions yet";
              });
            }
          } else {
            setState(() {
              petList.clear();
              status = "Failed to load data";
            });
          }
        });
  }
}
