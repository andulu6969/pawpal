import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/user.dart';
import '../models/pet.dart';
import '../myconfig.dart';
import 'my_drawer.dart';

class MyPetListingsScreen extends StatefulWidget {
  final User user;
  const MyPetListingsScreen({super.key, required this.user});

  @override
  State<MyPetListingsScreen> createState() => _MyPetListingsScreenState();
}

class _MyPetListingsScreenState extends State<MyPetListingsScreen> {
  // Store the user's own pets
  List<Pet> myPets = [];

  // UI State variables
  bool isLoading = true;
  String status = "Loading...";

  @override
  void initState() {
    super.initState();
    loadMyPets();
  }

  // API Call: Fetch only pets belonging to this user
  void loadMyPets() {
    http
        .get(
          Uri.parse(
            "${MyConfig.baseUrl}/pawpal/api/load_my_pets.php?user_id=${widget.user.id}",
          ),
        )
        .then((response) {
          if (response.statusCode == 200) {
            var data = jsonDecode(response.body);
            setState(() {
              isLoading = false;
              if (data['status'] == 'success') {
                // Convert JSON array to List of Pet objects
                myPets = (data['data'] as List)
                    .map((e) => Pet.fromJson(e))
                    .toList();
                status = "";
              } else {
                myPets = [];
                status = "You haven't posted any pets yet.";
              }
            });
          }
        });
  }

  // 1. Show Confirmation Dialog before Deletion
  void deletePet(String petId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Listing"),
        content: const Text(
          "Are you sure? This will remove the pet from the public list permanently.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              _performDelete(petId); // Proceed to delete
            },
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  // 2. Execute API Call to Delete Pet
  void _performDelete(String petId) {
    http
        .post(
          Uri.parse("${MyConfig.baseUrl}/pawpal/api/delete_pet.php"),
          body: {"pet_id": petId},
        )
        .then((response) {
          if (response.statusCode == 200) {
            var data = jsonDecode(response.body);
            if (data['status'] == 'success') {
              // Refresh the list to remove the deleted item from UI
              loadMyPets();
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text("Listing Deleted")));
            } else {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text("Failed to delete")));
            }
          }
        });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("My Listed Pets"),
        backgroundColor: Colors.blue.shade800,
        foregroundColor: Colors.white,
      ),
      drawer: MyDrawer(user: widget.user),

      // Show Loading, Empty State, or List of Pets
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : myPets.isEmpty
          ? Center(
              child: Text(status, style: TextStyle(color: Colors.grey[600])),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(10),
              itemCount: myPets.length,
              itemBuilder: (context, index) {
                Pet pet = myPets[index];

                // Extract first image from JSON array
                String imgPath = "na.png";
                try {
                  List images = jsonDecode(pet.imagePaths.toString());
                  if (images.isNotEmpty) imgPath = images[0];
                } catch (e) {}

                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  elevation: 3,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(10),
                    // Thumbnail Image
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        "${MyConfig.baseUrl}/pawpal/assets/pets/$imgPath",
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                        errorBuilder: (c, o, s) => Container(
                          width: 60,
                          height: 60,
                          color: Colors.grey[300],
                          child: const Icon(Icons.pets),
                        ),
                      ),
                    ),
                    // Pet Name
                    title: Text(
                      pet.petName ?? "Unknown",
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    // Category and Description
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("${pet.category} • ${pet.petType}"),
                        const SizedBox(height: 4),
                        Text(
                          pet.description ?? "",
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    // Delete Button Icon
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => deletePet(pet.petId!),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
