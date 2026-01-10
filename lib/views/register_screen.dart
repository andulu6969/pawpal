import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:pawpal/myconfig.dart';
import 'package:pawpal/views/login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  // Input Controllers to capture text
  TextEditingController nameController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController phoneController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  TextEditingController confirmPasswordController = TextEditingController();

  late double height, width;
  bool visible = true; // For password visibility toggle

  // GlobalKey allows us to trigger validation on all Form fields at once
  final formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    // Responsive Layout Logic
    height = MediaQuery.of(context).size.height;
    width = MediaQuery.of(context).size.width;

    // Web/Tablet constraint: Keep form centered and manageable size
    if (width > 400) {
      width = 400;
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Register Page')),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
            child: SizedBox(
              width: width,
              // --- FORM WIDGET ---
              // Wraps all text fields to enable centralized validation
              child: Form(
                key: formKey,
                child: Column(
                  children: [
                    const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Icon(Icons.pets, size: 100, color: Colors.blue),
                    ),
                    const SizedBox(height: 5),

                    // --- INPUT FIELDS ---

                    // Name Field
                    TextFormField(
                      controller: nameController,
                      validator: (val) =>
                          val!.isEmpty ? "Please enter name" : null,
                      decoration: const InputDecoration(
                        labelText: 'Name',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Email Field
                    TextFormField(
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                      validator: (val) {
                        if (val!.isEmpty ||
                            !val.contains("@") ||
                            !val.contains(".")) {
                          return "Please enter a valid email";
                        }
                        return null;
                      },
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.email),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Phone Field
                    TextFormField(
                      controller: phoneController,
                      keyboardType: TextInputType.phone,
                      validator: (val) =>
                          val!.length < 10 ? "Invalid phone number" : null,
                      decoration: const InputDecoration(
                        labelText: 'Phone',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.phone),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Password Field
                    TextFormField(
                      controller: passwordController,
                      obscureText: visible,
                      validator: (val) =>
                          val!.length < 6 ? "Password too short (min 6)" : null,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.lock),
                        suffixIcon: IconButton(
                          onPressed: () {
                            setState(() {
                              visible = !visible;
                            });
                          },
                          icon: Icon(
                            visible ? Icons.visibility : Icons.visibility_off,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Confirm Password Field
                    TextFormField(
                      controller: confirmPasswordController,
                      obscureText: visible,
                      validator: (val) {
                        if (val!.isEmpty) return "Please confirm password";
                        if (val != passwordController.text) {
                          return "Passwords do not match";
                        }
                        return null;
                      },
                      decoration: const InputDecoration(
                        labelText: 'Confirm Password',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.lock),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // --- BUTTONS ---

                    // Register Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: registerDialog,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 15),
                        ),
                        child: const Text('Register'),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Navigation to Login
                    TextButton(
                      onPressed: () {
                        // Pop removes the register screen from stack
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const LoginScreen(),
                          ),
                        );
                      },
                      child: const Text('Already have an account? Login here'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // --- LOGIC 1: CONFIRMATION DIALOG ---
  // Validates the form and asks for user confirmation before sending data
  void registerDialog() {
    // Check all validators in the Form widget
    if (!formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fix the errors in red")),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Register Account'),
        content: const Text('Are you sure you want to register?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              registerUser(); // Proceed to backend
            },
            child: const Text('Yes'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('No'),
          ),
        ],
      ),
    );
  }

  // --- LOGIC 2: BACKEND INTEGRATION ---
  void registerUser() async {
    // 1. Show Loading UI
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 20),
            Text('Registering...'),
          ],
        ),
      ),
    );

    // 2. Prepare Data
    String name = nameController.text;
    String email = emailController.text;
    String phone = phoneController.text;
    String password = passwordController.text;

    try {
      // 3. Send HTTP Request
      final response = await http.post(
        Uri.parse("${MyConfig.baseUrl}/pawpal/api/register_user.php"),
        body: {
          "name": name,
          "email": email,
          "phone": phone,
          "password": password,
        },
      );

      // Check if widget is still on screen (Async Gap safety)
      if (!mounted) return;

      // 4. Close Loading Dialog
      Navigator.pop(context);

      // 5. Handle Response
      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);

        if (data['status'] == "success") {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Registration Success"),
              backgroundColor: Colors.green,
            ),
          );
          // Navigate to Login (PushReplacement prevents going back to Register)
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (content) => const LoginScreen()),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Failed: ${data['message']}"),
              backgroundColor: Colors.red,
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Server Error"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      // 6. Error Handling (Network issues, etc.)
      if (mounted) {
        if (Navigator.canPop(context)) {
          Navigator.pop(context); // Ensure loading dialog closes on error
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }
}
