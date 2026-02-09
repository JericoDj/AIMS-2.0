import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class PasswordConfirmationDialog extends StatefulWidget {
  final String title;
  final String message;
  final String confirmLabel;
  final Color confirmColor;

  const PasswordConfirmationDialog({
    super.key,
    this.title = "Confirm Action",
    this.message = "Please enter your password to confirm this action.",
    this.confirmLabel = "Confirm",
    this.confirmColor = Colors.red,
  });

  @override
  State<PasswordConfirmationDialog> createState() =>
      _PasswordConfirmationDialogState();
}

class _PasswordConfirmationDialogState
    extends State<PasswordConfirmationDialog> {
  final TextEditingController _passwordCtrl = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _isObscure = true;
  bool _isLoading = false;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _passwordCtrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final password = _passwordCtrl.text;
    if (password.isEmpty) return;

    setState(() {
      _isLoading = true;
      _errorText = null;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null || user.email == null) {
        throw Exception("No authenticated user found.");
      }

      // Re-authenticate to verify password
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: password,
      );

      await user.reauthenticateWithCredential(credential);

      if (mounted) {
        Navigator.pop(context, true); // ✅ Success
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        _errorText = e.message ?? "Incorrect password";
      });
    } catch (e) {
      setState(() {
        _errorText = "An error occurred. Please try again.";
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(
        widget.title,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.message),
          const SizedBox(height: 16),
          TextField(
            controller: _passwordCtrl,
            focusNode: _focusNode,
            obscureText: _isObscure,
            decoration: InputDecoration(
              labelText: "Password",
              errorText: _errorText,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              suffixIcon: IconButton(
                icon: Icon(
                  _isObscure ? Icons.visibility : Icons.visibility_off,
                ),
                onPressed: () {
                  setState(() {
                    _isObscure = !_isObscure;
                  });
                },
              ),
            ),
            onSubmitted: (_) => _submit(),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context, false),
          child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: widget.confirmColor,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child:
              _isLoading
                  ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                  : Text(widget.confirmLabel),
        ),
      ],
    );
  }
}
