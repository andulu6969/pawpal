import 'package:flutter/material.dart';
import '../models/user.dart';
import '../myconfig.dart';
import 'home_screen.dart';
import 'donation_screen.dart';
import 'profile_screen.dart';
import 'login_screen.dart';
import 'my_pet_listings_screen.dart';

class MyDrawer extends StatelessWidget {
  final User user;
  const MyDrawer({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          // Expanded ListView takes up all available space above the footer
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                // 1. Header Section with User Info
                UserAccountsDrawerHeader(
                  accountName: Text(user.name ?? "User"),
                  accountEmail: Text(user.email ?? "Email"),

                  // Dynamic Profile Image
                  // We append a timestamp (?v=time) to the URL to force Flutter
                  // to reload the image from the server instead of using the cache.
                  // This ensures the user sees their new photo immediately after updating it.
                  currentAccountPicture: CircleAvatar(
                    backgroundColor: Colors.white,
                    backgroundImage: NetworkImage(
                      "${MyConfig.baseUrl}/pawpal/assets/profile/${user.id}.jpg?v=${DateTime.now().millisecondsSinceEpoch}",
                    ),
                    // Fail gracefully if image doesn't exist
                    onBackgroundImageError: (exception, stackTrace) {},
                  ),
                  decoration: BoxDecoration(color: Colors.blue.shade800),
                ),

                // 2. Navigation Menu Items
                ListTile(
                  leading: const Icon(Icons.pets),
                  title: const Text("Home"),
                  onTap: () {
                    Navigator.pop(context); // Close the drawer first
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (c) => HomeScreen(user: user)),
                    );
                  },
                ),

                ListTile(
                  leading: const Icon(Icons.list_alt),
                  title: const Text("My Listings"),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (c) => MyPetListingsScreen(user: user),
                      ),
                    );
                  },
                ),

                ListTile(
                  leading: const Icon(Icons.volunteer_activism),
                  title: const Text("Donations"),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (c) => DonationScreen(user: user),
                      ),
                    );
                  },
                ),

                ListTile(
                  leading: const Icon(Icons.person),
                  title: const Text("Profile"),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (c) => ProfileScreen(user: user),
                      ),
                    );
                  },
                ),

                const Divider(),

                // 3. Logout Option
                ListTile(
                  leading: const Icon(Icons.exit_to_app),
                  title: const Text("Logout"),
                  onTap: () {
                    // Remove all previous routes and return to Login
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (c) => const LoginScreen()),
                      (r) => false,
                    );
                  },
                ),
              ],
            ),
          ),

          // 4. Footer Section (Version Info)
          Container(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              "PawPal Version 1.0",
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
