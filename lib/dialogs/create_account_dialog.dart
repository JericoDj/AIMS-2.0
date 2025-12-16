import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/accounts_provider.dart';
import '../utils/enums/role_enum.dart';

class CreateAccountDialog extends StatefulWidget {
  const CreateAccountDialog({super.key});

  @override
  State<CreateAccountDialog> createState() => _CreateAccountDialogState();
}
class _CreateAccountDialogState extends State<CreateAccountDialog> {
  final _formKey = GlobalKey<FormState>();

  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  UserRole _selectedRole = UserRole.user;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.6,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "Create Account",
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),

                /// FULL NAME
                TextFormField(
                  controller: _fullNameController,
                  decoration: const InputDecoration(labelText: "Full Name"),
                  validator: (v) =>
                  v == null || v.isEmpty ? "Full name required" : null,
                ),

                const SizedBox(height: 12),

                /// EMAIL
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(labelText: "Email"),
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) =>
                  v == null || !v.contains('@') ? "Valid email required" : null,
                ),

                const SizedBox(height: 12),

                /// PASSWORD
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: "Password",
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                      onPressed: () {
                        setState(() => _obscurePassword = !_obscurePassword);
                      },
                    ),
                  ),
                  validator: (v) =>
                  v != null && v.length < 6
                      ? "Min 6 characters"
                      : null,
                ),

                const SizedBox(height: 12),

                /// CONFIRM PASSWORD
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: _obscurePassword,
                  decoration:
                  const InputDecoration(labelText: "Confirm Password"),
                  validator: (v) =>
                  v != _passwordController.text
                      ? "Passwords do not match"
                      : null,
                ),

                const SizedBox(height: 15),

                /// ROLE
                DropdownButtonFormField<UserRole>(
                  value: _selectedRole,
                  items: const [
                    DropdownMenuItem(
                      value: UserRole.user,
                      child: Text("User"),
                    ),
                    DropdownMenuItem(
                      value: UserRole.admin,
                      child: Text("Admin"),
                    ),
                  ],
                  onChanged: (value) =>
                      setState(() => _selectedRole = value!),
                  decoration: const InputDecoration(labelText: "Role"),
                ),

                const SizedBox(height: 25),

                /// ACTIONS
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text("Cancel"),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: () {
                        if (!_formKey.currentState!.validate()) return;

                        context.read<AccountsProvider>().createAccount(
                          fullName: _fullNameController.text.trim(),
                          email: _emailController.text.trim(),
                          role: _selectedRole,
                          password: _passwordController.text,
                        );

                        Navigator.pop(context);
                      },
                      child: const Text("Create"),
                    ),
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
