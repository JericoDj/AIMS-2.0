import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class LoginPage extends StatefulWidget {
  final String type; // "admin" or "user"

  const LoginPage({super.key, required this.type});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  bool rememberMe = false;

  @override
  Widget build(BuildContext context) {
    final isAdmin = widget.type == 'admin';
    final loginTitle = isAdmin ? "Admin Login" : "User Login";

    return Scaffold(
      backgroundColor: Colors.grey[900],
      body: Stack(
        children: [
          Positioned.fill(
            child: Opacity(
              opacity: 0.12,
              child: Image.asset(
                "assets/App_Logo.jpg", // your big faded seal background
                fit: BoxFit.fill,
              ),
            ),
          ),

          Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Column(
                  children: [


                    Container(
                      height: MediaQuery.sizeOf(context).height * 0.9,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [

                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [Image.asset(
                              "assets/8xLogo.png",
                              height: 180,
                            ),
                              const SizedBox(height: 10),

                              Text(
                                "AIMS 2.0",
                                style: TextStyle(
                                  color: Colors.green,
                                  fontSize: 36,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),

                              const SizedBox(height: 40),

                            ],
                          ),

                          SizedBox(width: MediaQuery.sizeOf(context).width * 0.1,),
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [


                              // LOGO

                              // EMAIL FIELD
                              Container(
                                width: 300,
                                child: TextField(
                                  controller: emailController,
                                  style: TextStyle(color: Colors.white),
                                  decoration: InputDecoration(
                                    filled: true,
                                    fillColor: Colors.white.withOpacity(0.85),
                                    hintText: "Enter Email",
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(6),
                                      borderSide: BorderSide.none,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),

                              // PASSWORD FIELD
                              Container(
                                width: 300,
                                child: TextField(
                                  controller: passwordController,
                                  obscureText: true,
                                  style: TextStyle(color: Colors.white),
                                  decoration: InputDecoration(
                                    filled: true,
                                    fillColor: Colors.white.withOpacity(0.85),
                                    hintText: "Enter Password",
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(6),
                                      borderSide: BorderSide.none,
                                    ),
                                  ),
                                ),
                              ),

                              const SizedBox(height: 10),

                              // Forgot password
                              Container(
                                width: 300,
                                alignment: Alignment.centerLeft,
                                child: GestureDetector(
                                  onTap: () {
                                    // forgot password action
                                  },
                                  child: Text(
                                    "Forgot Password",
                                    style: TextStyle(
                                      color: Colors.white,
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                ),
                              ),

                              const SizedBox(height: 20),

                              // LOGIN BUTTON
                              Container(
                                width: 300,
                                child: ElevatedButton(
                                  onPressed: () {
                                    // login logic with type
                                    if (isAdmin) {
                                      context.go('/admin');
                                    } else {
                                      context.go('/user');
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.lightGreen,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(24),
                                    ),
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                  ),
                                  child: Text(
                                    "Login",
                                    style: TextStyle(color: Colors.white, fontSize: 18),
                                  ),
                                ),
                              ),

                              const SizedBox(height: 10),

                              // REMEMBER ME
                              Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Checkbox(
                                    value: rememberMe,
                                    activeColor: Colors.green,
                            autofocus: true,
                            checkColor: Colors.green,
                            fillColor: WidgetStatePropertyAll( Colors.white ),
                                    onChanged: (v) {
                                      setState(() => rememberMe = v!);
                                    },
                                  ),
                                  Text("Remember Me", style: TextStyle(color: Colors.white)),
                                ],
                              ),

                              const SizedBox(height: 30),


                            ],
                          ),
                        ],
                      ),
                    ),
                    Container(
                      height: MediaQuery.sizeOf(context).height * 0.1,
                      child: Text("Version 2.0.1",
                          style: TextStyle(color: Colors.white54)),
                    ),
                  ],

                ),
              ),

            ),

          ),
        ],
      ),
    );
  }
}
