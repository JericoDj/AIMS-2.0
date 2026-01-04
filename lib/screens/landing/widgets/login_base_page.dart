import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'forgot_password_dialog.dart';

class LoginBasePage extends StatefulWidget {
  final String title;
  final Future<void> Function(String email, String password) onLogin;

  const LoginBasePage({
    super.key,
    required this.title,
    required this.onLogin,
  });

  @override
  State<LoginBasePage> createState() => _LoginBasePageState();
}

class _LoginBasePageState extends State<LoginBasePage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool isLoading = false;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);

    /// Detect current login route
    final currentPath = GoRouterState.of(context).uri.path;
    final bool isAdminRoute = currentPath == '/login/admin';

    return Scaffold(
      backgroundColor: Colors.grey[900],
      body: Stack(
        children: [
          /// BACKGROUND
          Positioned.fill(
            child: Opacity(
              opacity: 0.12,
              child: Image.asset(
                "assets/App_Logo.jpg",
                fit: BoxFit.cover,
              ),
            ),
          ),

          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Column(
                  children: [
                    SizedBox(
                      height: size.height * 0.85,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          /// LEFT BRAND
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Image.asset(
                                "assets/8xLogo.png",
                                height: 180,
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                "AIMS 2.0",
                                style: TextStyle(
                                  color: Colors.green,
                                  fontSize: 36,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),

                          SizedBox(width: size.width * 0.1),

                          /// RIGHT FORM
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                widget.title,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 24),

                              _input(
                                controller: emailController,
                                hint: "Enter Email",
                                obscure: false,
                              ),
                              const SizedBox(height: 20),

                              _input(
                                controller: passwordController,
                                hint: "Enter Password",
                                obscure: true,
                              ),

                              const SizedBox(height: 8),

                              /// FORGOT PASSWORD
                              SizedBox(
                                width: 300,
                                child: Align(
                                  alignment: Alignment.centerRight,
                                  child: GestureDetector(
                                    onTap: () {
                                      showDialog(
                                        context: context,
                                        barrierDismissible: true,
                                        builder: (_) => ForgotPasswordDialog(
                                          prefilledEmail: emailController.text.trim(),
                                        ),
                                      );
                                    },
                                    child: const Text(
                                      "Forgot Password?",
                                      style: TextStyle(
                                        color: Colors.white,
                                        decoration: TextDecoration.underline,
                                      ),
                                    ),
                                  ),
                                ),
                              ),

                              const SizedBox(height: 20),

                              /// LOGIN BUTTON
                              SizedBox(
                                width: 300,
                                child: ElevatedButton(
                                  onPressed: isLoading
                                      ? null
                                      : () async {
                                    setState(() => isLoading = true);
                                    try {
                                      await widget.onLogin(
                                        emailController.text.trim(),
                                        passwordController.text.trim(),
                                      );
                                    } finally {
                                      if (mounted) {
                                        setState(() => isLoading = false);
                                      }
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.lightGreen,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(24),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 14,
                                    ),
                                  ),
                                  child: isLoading
                                      ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                      : const Text(
                                    "Login",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                    ),
                                  ),
                                ),
                              ),

                              const SizedBox(height: 24),

                              /// SWITCH LOGIN TYPE
                              SizedBox(
                                width: 300,
                                child: isAdminRoute
                                    ? _SwitchLoginButton(
                                  label: "Login as User",
                                  onTap: () =>
                                      context.go('/login/user'),
                                )
                                    : _SwitchLoginButton(
                                  label: "Login as Admin",
                                  onTap: () =>
                                      context.go('/login/admin'),
                                ),
                              ),

                              const SizedBox(height: 14),

                              /// OFFLINE MODE
                              SizedBox(
                                width: 300,
                                child: _OfflineModeButton(
                                  onTap: () =>
                                      context.go('/offline'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const Text(
                      "Version 2.0.1",
                      style: TextStyle(color: Colors.white54),
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

  Widget _input({
    required TextEditingController controller,
    required String hint,
    required bool obscure,
  }) {
    return SizedBox(
      width: 300,
      child: TextField(
        controller: controller,
        obscureText: obscure,
        decoration: InputDecoration(
          filled: true,
          fillColor: Colors.white.withOpacity(0.9),
          hintText: hint,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }
}

/// SWITCH BUTTON
class _SwitchLoginButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _SwitchLoginButton({
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.white54),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white70),
        ),
      ),
    );
  }
}

/// OFFLINE BUTTON
class _OfflineModeButton extends StatelessWidget {
  final VoidCallback onTap;

  const _OfflineModeButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: Colors.red.shade700,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Text(
          "Offline Mode",
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }
}
