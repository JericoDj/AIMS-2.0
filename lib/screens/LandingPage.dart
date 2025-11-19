import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // BACKGROUND IMAGE
          Positioned.fill(
            child: Image.asset(
              "assets/App_logo.jpg",
              height: MediaQuery.sizeOf(context).height * .6,

            ),
          ),

          // FOREGROUND CONTENT
          Center(
            child: Container(
              color: Colors.black54, // semi-transparent overlay
              child: Column(
                children: [
                  

                  Container(
                    height: MediaQuery.sizeOf(context).height * 0.9,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [




                        Container(
                          height: MediaQuery.sizeOf(context).height * 0.5,
                          child: Image.asset(
                              fit: BoxFit.cover,
                              "assets/8xlogo.png"),
                        ),

                        SizedBox(height: 20),



                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          spacing: MediaQuery.sizeOf(context).width * 0.1,
                          children: [
                            GestureDetector(
                              onTap: () => context.go('/login?type=admin'),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.green,
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                padding: const EdgeInsets.all(8),
                                child: Text("Login as Admin", style: TextStyle(color: Colors.white)),
                              ),
                            ),

                            GestureDetector(
                              // onTap: () => context.go('/login?type=user'),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.green,
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                padding: const EdgeInsets.all(8),
                                child: Text("Login as User", style: TextStyle(color: Colors.white)),
                              ),
                            ),
                          ],
                        )
                      ],
                    ),
                  ),
                  Container(
                    height: MediaQuery.sizeOf(context).height * 0.1,
                    child: Center(
                      child: Text(
                        "© 2025 AIMS 2.0.1 All rights reserved.",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
