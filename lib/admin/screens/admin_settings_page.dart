import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../admin_theme.dart';
import '../widgets/admin_widgets.dart';

class AdminSettingsPage extends StatefulWidget {
  const AdminSettingsPage({super.key});

  @override
  State<AdminSettingsPage> createState() => _AdminSettingsPageState();
}

class _AdminSettingsPageState extends State<AdminSettingsPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;

  User? get _currentUser => FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _loadAdminDetails();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _loadAdminDetails() async {
    final user = _currentUser;
    if (user == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      final data = snapshot.data();

      _nameController.text =
          (data?['name'] as String?)?.trim().isNotEmpty == true
          ? (data?['name'] as String).trim()
          : (user.displayName?.trim() ?? '');
      _emailController.text = user.email?.trim() ?? '';
      _phoneController.text = (data?['phone'] as String?)?.trim() ?? '';
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not load admin details right now.'),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _saveAdminDetails() async {
    final user = _currentUser;
    if (user == null || _isSaving) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final name = _nameController.text.trim();
      final phone = _phoneController.text.trim();

      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'uid': user.uid,
        'name': name,
        'email': user.email?.trim() ?? '',
        'phone': phone,
        'role': 'admin',
        'isAdmin': true,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if ((user.displayName ?? '').trim() != name) {
        await user.updateDisplayName(name);
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Admin details updated successfully.')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to update admin details right now.'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _currentUser;

    if (user == null) {
      return const AdminCard(
        child: Text(
          'Please sign in again to manage admin details.',
          textAlign: TextAlign.center,
          style: TextStyle(color: AdminTheme.muted),
        ),
      );
    }

    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 48),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    return Column(
      children: [
        AdminCard(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const AdminSectionTitle(
                  title: 'Admin Details',
                  subtitle:
                      'Keep the main admin account details updated in Firestore.',
                ),
                const SizedBox(height: 18),
                _AdminField(
                  label: 'Full Name',
                  controller: _nameController,
                  hintText: 'Enter admin name',
                  enabled: !_isSaving,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a name';
                    }
                    if (value.trim().length < 3) {
                      return 'Name must be at least 3 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                _AdminField(
                  label: 'Email',
                  controller: _emailController,
                  hintText: 'Admin sign-in email',
                  enabled: false,
                ),
                const SizedBox(height: 12),
                _AdminField(
                  label: 'Phone',
                  controller: _phoneController,
                  hintText: '9876543210',
                  enabled: !_isSaving,
                  keyboardType: TextInputType.phone,
                  validator: (value) {
                    final text = (value ?? '').trim();
                    if (text.isEmpty) return 'Please enter a phone number';
                    if (!RegExp(r'^\d{10}$').hasMatch(text)) {
                      return 'Please enter a valid 10-digit phone';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: FilledButton(
                    onPressed: _isSaving ? null : _saveAdminDetails,
                    style: FilledButton.styleFrom(
                      backgroundColor: AdminTheme.pink,
                    ),
                    child: Text(_isSaving ? 'Saving...' : 'Save Details'),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        const AdminCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AdminSectionTitle(
                title: 'Account Info',
                subtitle:
                    'A short summary of the admin account used in this dashboard.',
              ),
              SizedBox(height: 16),
              _InfoRow(label: 'Role', value: 'Admin'),
              SizedBox(height: 10),
              _InfoRow(
                label: 'Data Source',
                value: 'Firebase Authentication + Firestore',
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AdminField extends StatelessWidget {
  const _AdminField({
    required this.label,
    required this.controller,
    required this.hintText,
    required this.enabled,
    this.keyboardType,
    this.validator,
  });

  final String label;
  final TextEditingController controller;
  final String hintText;
  final bool enabled;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            color: AdminTheme.text,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          enabled: enabled,
          keyboardType: keyboardType,
          validator: validator,
          decoration: InputDecoration(
            hintText: hintText,
            filled: true,
            fillColor: enabled
                ? const Color(0xFFFBFBFD)
                : const Color(0xFFF4F2F8),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: const BorderSide(color: Color(0xFFECEAF3)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: const BorderSide(color: Color(0xFFECEAF3)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: const BorderSide(color: AdminTheme.pink, width: 1.4),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: const BorderSide(color: Color(0xFFECEAF3)),
            ),
          ),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 92,
          child: Text(
            label,
            style: const TextStyle(
              color: AdminTheme.muted,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color: AdminTheme.text,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
