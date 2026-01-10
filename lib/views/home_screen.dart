import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../myconfig.dart';
import '../models/user.dart';
import '../models/pet.dart';
import 'new_pet_screen.dart';
import 'pet_details_screen.dart';
import 'my_drawer.dart';

class HomeScreen extends StatefulWidget {
  final User user;
  const HomeScreen({super.key, required this.user});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // List to store fetched pets from server
  List<Pet> petList = [];

  // Status message to display when list is empty or loading
  String status = "Loading...";

  // Controller for the Search Bar
  TextEditingController searchController = TextEditingController();

  // Filter Dropdown Options
  // This satisfies the "Filter by Dropdown" assignment requirement
  List<String> types = ["All", "Cat", "Dog", "Rabbit", "Other"];
  String selectedType = "All";

  @override
  void initState() {
    super.initState();
    // Load data immediately when the screen opens
    loadPets();
  }

  // API Call to Fetch Pets
  // Supports both Search (by name) and Filter (by type)
  void loadPets() {
    // Clear current list to prevent duplicates or confusion during reload
    petList.clear();

    String search = searchController.text;

    http
        .get(
          Uri.parse(
            // Passes user_id (to exclude own pets if needed logic exists)
            // Passes search keyword and selected category type
            "${MyConfig.baseUrl}/pawpal/api/load_pets.php?user_id=${widget.user.id}&search=$search&type=$selectedType",
          ),
        )
        .then((response) {
          if (response.statusCode == 200) {
            var data = jsonDecode(response.body);

            if (data['status'] == 'success') {
              setState(() {
                // Map JSON response to List<Pet> objects
                petList = (data['data'] as List)
                    .map((e) => Pet.fromJson(e))
                    .toList();
                status = ""; // Clear status message on success
              });
            } else {
              // Handle case where no pets match the criteria
              setState(() => status = "No pets found");
            }
          } else {
            setState(() => status = "Server Error");
          }
        });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],

      // Standard App Bar
      appBar: AppBar(
        title: const Text(
          "PawPal",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: Colors.blue.shade800,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),

      // Navigation Drawer
      drawer: MyDrawer(user: widget.user),

      body: Column(
        children: [
          // --- SECTION 1: SEARCH & FILTER ---
          // Using a Stack to create a floating card effect over the blue background
          Stack(
            children: [
              // Blue background extension for visual style
              Container(
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.blue.shade800,
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(30),
                  ),
                ),
              ),

              // Floating Card containing Search Bar and Filter Dropdown
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 5,
                ),
                child: Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Row(
                      children: [
                        // Search Icon
                        const Padding(
                          padding: EdgeInsets.only(left: 8.0),
                          child: Icon(Icons.search, color: Colors.grey),
                        ),
                        const SizedBox(width: 10),

                        // Search Input Field
                        Expanded(
                          child: TextField(
                            controller: searchController,
                            // Trigger reload when user presses Enter on keyboard
                            onSubmitted: (v) => loadPets(),
                            decoration: const InputDecoration(
                              hintText: "Search pets...",
                              border: InputBorder.none, // Removes underline
                            ),
                          ),
                        ),

                        // Vertical Divider to separate Search and Filter
                        Container(
                          width: 1,
                          height: 25,
                          color: Colors.grey[300],
                        ),
                        const SizedBox(width: 10),

                        // Dropdown Filter Logic
                        DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: selectedType,
                            icon: const Icon(
                              Icons.filter_list,
                              color: Colors.blue,
                            ),
                            items: types.map((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(
                                  value,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey[800],
                                  ),
                                ),
                              );
                            }).toList(),
                            onChanged: (newValue) {
                              setState(() {
                                selectedType = newValue!;
                                // Reload list immediately on filter change
                                loadPets();
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),

          // --- SECTION 2: PET LIST GRID ---
          Expanded(
            // Show status message if list is empty, otherwise show GridView
            child: petList.isEmpty
                ? Center(
                    child: Text(
                      status,
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  )
                : GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2, // 2 items per row
                          childAspectRatio:
                              0.75, // Taller cards for better layout
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                        ),
                    itemCount: petList.length,
                    itemBuilder: (context, index) {
                      // Parse the image JSON string
                      String imgPath = "na.png"; // Default image
                      try {
                        List images = jsonDecode(
                          petList[index].imagePaths.toString(),
                        );
                        if (images.isNotEmpty) imgPath = images[0];
                      } catch (e) {
                        // Keep default if error occurs
                      }

                      // Navigates to Details Screen on tap
                      return GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (c) => PetDetailsScreen(
                              user: widget.user,
                              pet: petList[index],
                            ),
                          ),
                        ),
                        child: Card(
                          elevation: 3,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Pet Image Area
                              Expanded(
                                child: ClipRRect(
                                  borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(15),
                                  ),
                                  child: Image.network(
                                    "${MyConfig.baseUrl}/pawpal/assets/pets/$imgPath",
                                    fit: BoxFit.cover,
                                    errorBuilder: (c, o, s) => Container(
                                      color: Colors.grey[200],
                                      child: const Icon(
                                        Icons.pets,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ),
                                ),
                              ),

                              // Pet Details (Name, Type, Age)
                              Padding(
                                padding: const EdgeInsets.all(10.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      petList[index].petName ?? "Unknown",
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        // Type Badge
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.blue.shade50,
                                            borderRadius: BorderRadius.circular(
                                              4,
                                            ),
                                          ),
                                          child: Text(
                                            petList[index].petType ?? "",
                                            style: TextStyle(
                                              fontSize: 10,
                                              color: Colors.blue.shade800,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        const Spacer(),
                                        // Age Text
                                        Text(
                                          "${petList[index].petAge ?? "?"} yrs",
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
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

      // Floating Action Button to Add New Pet
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          // Navigate to NewPetScreen and wait for result
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (c) => NewPetScreen(user: widget.user)),
          );
          // Refresh list when returning from Add Pet screen
          loadPets();
        },
        label: const Text("Add Pet"),
        icon: const Icon(Icons.add),
        backgroundColor: Colors.blue.shade800,
      ),
    );
  }
}
