import 'package:aims2frontend/screens/landing/widgets/landing_widgets.dart';
import 'package:flutter/material.dart';

class LandingPage extends StatelessWidget {
  const LandingPage({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);

    return Scaffold(
      body: Stack(
        children: [
          /// BACKGROUND IMAGE
          Positioned.fill(
            child: Image.asset(
              "assets/App_logo.jpg",
              fit: BoxFit.cover,
            ),
          ),

          /// DARK OVERLAY
          Positioned.fill(
            child: Container(color: Colors.black54),
          ),

          /// CONTENT
          SafeArea(

              child: SingleChildScrollView(
                child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    /// MAIN CONTENT
                    SizedBox(
                      height: size.height * 0.85,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset(
                            "assets/8xlogo.png",
                            height: size.height * 0.4,
                            fit: BoxFit.contain,
                          ),

                          const SizedBox(height: 24),

                          const LandingActions(),
                        ],
                      ),
                    ),

                    /// FOOTER
                    const Padding(
                      padding: EdgeInsets.only(bottom: 12),
                      child: Text(
                        "© 2025 AIMS 2.0.1 All rights reserved.",
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
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
