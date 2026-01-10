import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:pawpal/models/user.dart';
import 'package:pawpal/myconfig.dart';
import 'package:pawpal/views/home_screen.dart';
import 'package:pawpal/views/register_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // Controllers to capture user input
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();

  // Form key for validation
  final formKey = GlobalKey<FormState>();

  late double height, width;
  bool visible = true; // Toggle password visibility
  bool isChecked = false; // "Remember Me" checkbox state

  @override
  void initState() {
    super.initState();
    // Load saved credentials if "Remember Me" was previously checked
    loadPreferences();
  }

  @override
  Widget build(BuildContext context) {
    // Responsive screen dimensions
    height = MediaQuery.of(context).size.height;
    width = MediaQuery.of(context).size.width;

    // Constrain width for larger screens (tablets/web)
    if (width > 400) {
      width = 400;
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Login Page')),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
            child: SizedBox(
              width: width,
              child: Form(
                key: formKey,
                child: Column(
                  children: [
                    // Logo Asset
                    const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Icon(Icons.pets, size: 100, color: Colors.blue),
                    ),
                    const SizedBox(height: 5),

                    // Email Input Field
                    TextFormField(
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                      validator: (val) {
                        if (val!.isEmpty) return "Enter email";
                        if (!val.contains("@")) return "Invalid email";
                        return null;
                      },
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.email),
                      ),
                    ),
                    const SizedBox(height: 5),

                    // Password Input Field
                    TextFormField(
                      controller: passwordController,
                      obscureText: visible,
                      validator: (val) =>
                          val!.isEmpty ? "Enter password" : null,
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
                    const SizedBox(height: 5),

                    // "Remember Me" Checkbox
                    Padding(
                      padding: const EdgeInsets.fromLTRB(8, 0, 8, 0),
                      child: Row(
                        children: [
                          const Text('Remember Me'),
                          Checkbox(
                            value: isChecked,
                            onChanged: (value) {
                              setState(() {
                                isChecked = value!;
                              });
                            },
                          ),
                        ],
                      ),
                    ),

                    // Login Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: loginUser,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 15),
                        ),
                        child: const Text('Login'),
                      ),
                    ),
                    const SizedBox(height: 5),

                    // Navigation to Registration
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const RegisterScreen(),
                          ),
                        );
                      },
                      child: const Text(
                        "Don't have an account? Register here.",
                      ),
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

  // --- Backend Logic ---

  void loginUser() {
    // 1. Validate Form Inputs
    if (!formKey.currentState!.validate()) {
      return;
    }

    String email = emailController.text.trim();
    String password = passwordController.text.trim();

    // 2. Show Progress Indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    // 3. Send POST Request to PHP Backend
    http
        .post(
          Uri.parse('${MyConfig.baseUrl}/pawpal/api/login_user.php'),
          body: {'email': email, 'password': password},
        )
        .then((response) {
          Navigator.pop(context); // Dismiss loading dialog

          if (response.statusCode == 200) {
            var jsonResponse = response.body;
            var resarray = jsonDecode(jsonResponse);

            if (resarray['status'] == 'success') {
              // 4. Parse User Data
              User user = User.fromJson(resarray['data'][0]);

              // 5. Handle "Remember Me" Persistence
              savePreferences(isChecked);

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Login successful"),
                  backgroundColor: Colors.green,
                ),
              );

              // 6. Navigate to Home Screen
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => HomeScreen(user: user)),
              );
            } else {
              // Handle Login Failure (Wrong password/User not found)
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(resarray['message']),
                  backgroundColor: Colors.red,
                ),
              );
            }
          } else {
            // Handle Server Errors (500, 404, etc.)
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Server Error"),
                backgroundColor: Colors.red,
              ),
            );
          }
        })
        .catchError((e) {
          // Handle Network Errors (No internet, timeout)
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
          );
        });
  }

  // --- SharedPreferences Logic ---

  // Saves email/password locally if "Remember Me" is checked
  void savePreferences(bool value) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    if (value) {
      await prefs.setString('email', emailController.text);
      await prefs.setString('password', passwordController.text);
      await prefs.setBool('rememberMe', value);
    } else {
      // Clear data if user unchecks the box
      await prefs.remove('email');
      await prefs.remove('password');
      await prefs.remove('rememberMe');
    }
  }

  // Loads saved credentials on app startup
  void loadPreferences() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool rememberMe = prefs.getBool('rememberMe') ?? false;
    if (rememberMe) {
      setState(() {
        emailController.text = prefs.getString('email') ?? '';
        passwordController.text = prefs.getString('password') ?? '';
        isChecked = true;
      });
    }
  }
}
