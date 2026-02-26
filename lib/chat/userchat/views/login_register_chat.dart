import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:flutter_application_1/chat/userchat/views/chat_user_list_screen.dart';

const Color _namPrimary = Color(0xFF5CD9FF);
const Color _namPrimaryDark = Color(0xFF4489D7);
const Color _namBackground = Color(0xFFEFFBFF);

class AuthCheck extends StatelessWidget {
  final Widget Function(String userId)? onAuthenticated;

  const AuthCheck({super.key, this.onAuthenticated});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasData) {
          final userId = snapshot.data!.uid;
          if (onAuthenticated != null) {
            return onAuthenticated!(userId);
          }
          return UserListScreen(currentUserId: userId);
        }

        return LoginChatScreen(onAuthenticated: onAuthenticated);
      },
    );
  }
}

class LoginChatScreen extends StatefulWidget {
  final Widget Function(String userId)? onAuthenticated;

  const LoginChatScreen({super.key, this.onAuthenticated});

  @override
  State<LoginChatScreen> createState() => _LoginChatScreenState();
}

class _LoginChatScreenState extends State<LoginChatScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _imageUrlController = TextEditingController();

  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  void _goAfterAuth(String userId) {
    final target = widget.onAuthenticated?.call(userId) ??
        UserListScreen(currentUserId: userId);
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => target),
    );
  }

  Future<void> _login() async {
    setState(() => _isLoading = true);
    try {
      final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (!mounted) {
        return;
      }
      _goAfterAuth(credential.user!.uid);
    } on FirebaseAuthException catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? 'Login failed')),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _register() async {
    setState(() => _isLoading = true);
    try {
      final credential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      await FirebaseFirestore.instance
          .collection('Users')
          .doc(credential.user!.uid)
          .set({
        'username': _nameController.text.trim().isEmpty
            ? _emailController.text.trim().split('@').first
            : _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'img': _imageUrlController.text.trim(),
      }, SetOptions(merge: true));

      if (!mounted) {
        return;
      }
      _goAfterAuth(credential.user!.uid);
    } on FirebaseAuthException catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? 'Register failed')),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _namBackground,
      appBar: AppBar(
        title: const Text('เข้าสู่ระบบแชท'),
        centerTitle: true,
        backgroundColor: _namPrimary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: _namPrimaryDark.withValues(alpha: 0.12),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                children: [
                  _NamInput(
                    controller: _nameController,
                    label: 'ชื่อที่แสดง (ตอนสมัคร)',
                    icon: Icons.person_outline,
                  ),
                  const SizedBox(height: 12),
                  _NamInput(
                    controller: _imageUrlController,
                    label: 'Image URL (optional)',
                    icon: Icons.image_outlined,
                  ),
                  const SizedBox(height: 12),
                  _NamInput(
                    controller: _emailController,
                    label: 'Email',
                    icon: Icons.alternate_email,
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 12),
                  _NamInput(
                    controller: _passwordController,
                    label: 'Password',
                    icon: Icons.lock_outline,
                    obscureText: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            if (_isLoading)
              const CircularProgressIndicator(color: _namPrimaryDark)
            else
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _login,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _namPrimary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text('Login'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _register,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _namPrimaryDark,
                        side: const BorderSide(color: _namPrimary),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text('Register'),
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 12),
            const Text(
              'NAM Chat',
              style: TextStyle(
                color: _namPrimaryDark,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NamInput extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool obscureText;
  final TextInputType? keyboardType;

  const _NamInput({
    required this.controller,
    required this.label,
    required this.icon,
    this.obscureText = false,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: _namPrimaryDark),
        filled: true,
        fillColor: _namBackground,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
