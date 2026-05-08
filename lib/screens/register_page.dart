import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../data/auth_repository.dart';
import '../theme/app_theme.dart';
import 'login_page.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  final AuthRepository _authRepository = AuthRepository.instance;

  bool hidePassword = true;
  bool hideConfirmPassword = true;
  bool agreeTerms = false;
  bool isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _createAccount() async {
    if (!_formKey.currentState!.validate() || isLoading) return;
    if (!agreeTerms) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please accept terms')));
      return;
    }

    setState(() => isLoading = true);

    try {
      await _authRepository.registerCustomer(
        name: _nameController.text,
        email: _emailController.text,
        phone: _phoneController.text,
        password: _passwordController.text,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Account created. Please sign in.')),
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
      );
    } on FirebaseAuthException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_firebaseRegisterMessage(error))));
    } on FirebaseException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_firebaseDataMessage(error))));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Unable to create account right now. Please try again.',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  String _firebaseRegisterMessage(FirebaseAuthException error) {
    switch (error.code) {
      case 'email-already-in-use':
        return 'This email is already registered. Please sign in.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'weak-password':
        return 'Password is too weak. Use at least 6 characters.';
      case 'operation-not-allowed':
        return 'Email/password sign-in is not enabled in Firebase Authentication.';
      default:
        return error.message ?? 'Registration failed. Please try again.';
    }
  }

  String _firebaseDataMessage(FirebaseException error) {
    switch (error.code) {
      case 'permission-denied':
        return 'Firestore blocked this write. Please update your Firebase rules.';
      case 'unavailable':
        return 'Firestore is currently unavailable. Please try again.';
      case 'not-found':
        return 'Cloud Firestore is not set up yet in your Firebase project.';
      default:
        return error.message ?? 'Unable to save user details to Firebase.';
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.cakeTheme;
    final scheme = context.colorScheme;

    return Scaffold(
      backgroundColor: palette.pageBackground,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const SizedBox(height: 20),
              _heroIcon(context),
              const SizedBox(height: 16),
              Text(
                'Join Sweet Delights',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: scheme.primary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Create your account and start ordering',
                style: TextStyle(color: palette.mutedText),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: palette.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: palette.border),
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Full Name'),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _nameController,
                        decoration: _dec('John Doe', Icons.person_outline),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty)
                            return 'Enter name';
                          if (v.trim().length < 3)
                            return 'Minimum 3 characters';
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      const Text('Email'),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _emailController,
                        decoration: _dec(
                          'you@example.com',
                          Icons.email_outlined,
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty)
                            return 'Enter email';
                          final emailRegex = RegExp(
                            r'^[\w\.-]+@([\w-]+\.)+[\w-]{2,4}$',
                          );
                          if (!emailRegex.hasMatch(v.trim())) {
                            return 'Enter valid email';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      const Text('Phone'),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: _dec('1234567890', Icons.phone_outlined),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty)
                            return 'Enter phone';
                          if (!RegExp(r'^\d{10}$').hasMatch(v.trim())) {
                            return 'Enter 10-digit phone';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      const Text('Password'),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: hidePassword,
                        decoration: _dec(
                          'Create a strong password',
                          Icons.lock_outline,
                          IconButton(
                            onPressed: () =>
                                setState(() => hidePassword = !hidePassword),
                            icon: Icon(
                              hidePassword
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                            ),
                          ),
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Enter password';
                          if (v.length < 6) return 'Minimum 6 characters';
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      const Text('Confirm Password'),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _confirmController,
                        obscureText: hideConfirmPassword,
                        decoration: _dec(
                          'Confirm your password',
                          Icons.lock_outline,
                          IconButton(
                            onPressed: () => setState(
                              () => hideConfirmPassword = !hideConfirmPassword,
                            ),
                            icon: Icon(
                              hideConfirmPassword
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                            ),
                          ),
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Confirm password';
                          if (v != _passwordController.text) {
                            return 'Passwords do not match';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Checkbox(
                            value: agreeTerms,
                            onChanged: (v) =>
                                setState(() => agreeTerms = v ?? false),
                          ),
                          const Expanded(
                            child: Text(
                              'I agree to the Terms of Service and Privacy Policy',
                              style: TextStyle(fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: palette.heroGradient,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: ElevatedButton(
                            onPressed: isLoading ? null : _createAccount,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                            ),
                            child: isLoading
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                    ),
                                  )
                                : const Text(
                                    'Create Account',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                      if (isLoading) ...[
                        const SizedBox(height: 12),
                        Center(
                          child: Text(
                            'Creating your account...',
                            style: TextStyle(color: palette.mutedText),
                          ),
                        ),
                      ],
                      const SizedBox(height: 14),
                      Center(
                        child: TextButton(
                          onPressed: () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const LoginPage(),
                              ),
                            );
                          },
                          child: Text.rich(
                            TextSpan(
                              text: 'Already have an account? ',
                              style: TextStyle(color: palette.mutedText),
                              children: [
                                TextSpan(
                                  text: 'Sign in',
                                  style: TextStyle(color: scheme.primary),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _heroIcon(BuildContext context) {
    return Container(
      width: 74,
      height: 74,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: context.cakeTheme.heroGradient,
      ),
      child: const Icon(
        Icons.shopping_bag_outlined,
        color: Colors.white,
        size: 30,
      ),
    );
  }

  InputDecoration _dec(String hint, IconData icon, [Widget? suffix]) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon),
      suffixIcon: suffix,
    );
  }
}
