part of '../profile_section_pages.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({
    super.key,
    required this.initialName,
    required this.initialEmail,
    required this.initialPhone,
  });

  final String initialName;
  final String initialEmail;
  final String initialPhone;

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _favoriteFlavorController =
      TextEditingController();
  // final TextEditingController _bioController = TextEditingController();

  bool _isFetching = true;
  bool _isSaving = false;

  User? get _currentUser => FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
    _emailController = TextEditingController(text: widget.initialEmail);
    _phoneController = TextEditingController(text: widget.initialPhone);
    _loadProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _cityController.dispose();
    _favoriteFlavorController.dispose();
    // _bioController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    final user = _currentUser;
    if (user == null) {
      setState(() => _isFetching = false);
      return;
    }

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      final data = snapshot.data();

      if (!mounted) return;
      _nameController.text =
          ((data?['name'] as String?)?.trim().isNotEmpty == true)
          ? (data!['name'] as String).trim()
          : widget.initialName;
      _emailController.text =
          ((data?['email'] as String?)?.trim().isNotEmpty == true)
          ? (data!['email'] as String).trim()
          : (user.email?.trim().isNotEmpty == true
                ? user.email!.trim()
                : widget.initialEmail);
      _phoneController.text =
          ((data?['phone'] as String?)?.trim().isNotEmpty == true)
          ? (data!['phone'] as String).trim()
          : widget.initialPhone;
      _cityController.text = (data?['city'] as String?)?.trim() ?? '';
      _favoriteFlavorController.text =
          (data?['favoriteFlavor'] as String?)?.trim() ?? '';
      // _bioController.text = (data?['bio'] as String?)?.trim() ?? '';
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Could not load profile details. Showing saved values.',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isFetching = false);
      }
    }
  }

  Future<void> _saveProfile() async {
    final user = _currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in to edit your profile.')),
      );
      return;
    }

    if (!_formKey.currentState!.validate() || _isSaving) return;

    setState(() => _isSaving = true);

    try {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'uid': user.uid,
        'name': _nameController.text.trim(),
        'email': user.email?.trim() ?? _emailController.text.trim(),
        'phone': _phoneController.text.trim(),
        'city': _cityController.text.trim(),
        'favoriteFlavor': _favoriteFlavorController.text.trim(),
        // 'bio': _bioController.text.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if ((user.displayName ?? '').trim() != _nameController.text.trim()) {
        await user.updateDisplayName(_nameController.text.trim());
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully.')),
      );
      Navigator.pop(context);
    } on FirebaseException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error.message ?? 'Unable to save profile. Please try again.',
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Something went wrong while saving your profile.'),
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
    final initials = _nameController.text.trim().isEmpty
        ? 'SU'
        : _nameController.text
              .trim()
              .split(RegExp(r'\s+'))
              .where((value) => value.isNotEmpty)
              .take(2)
              .map((value) => value[0].toUpperCase())
              .join();

    if (user == null) {
      return const _ProfileSectionScaffold(
        title: 'Edit Profile',
        subtitle: 'Sign in to update your cake shop profile details.',
        icon: Icons.person_outline_rounded,
        child: _SignInPromptCard(),
      );
    }

    return _ProfileSectionScaffold(
      title: 'Edit Profile',
      subtitle: 'Keep your profile fresh so checkout and support stay smooth.',
      icon: Icons.drive_file_rename_outline_rounded,
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: _cardDecoration(context),
              child: Row(
                children: [
                  Container(
                    width: 68,
                    height: 68,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          ProfilePalette.primaryPink,
                          ProfilePalette.primaryPurple,
                        ],
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      initials.isEmpty ? 'SU' : initials,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _nameController.text.trim().isEmpty
                              ? 'Sweet Customer'
                              : _nameController.text.trim(),
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: context.colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _emailController.text.trim(),
                          style: TextStyle(color: context.cakeTheme.mutedText),
                        ),
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            // color: const Color(0xFFFFF2FB),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          // child: const Text(
                          //   'Profile synced with Firebase',
                          //   style: TextStyle(
                          //     color: ProfilePalette.primaryPink,
                          //     fontWeight: FontWeight.w600,
                          //     fontSize: 12,
                          //   ),
                          // ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: _cardDecoration(context),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _SectionTitle(
                    title: 'Personal Details',
                    subtitle: 'Update the essentials your account depends on.',
                  ),
                  const SizedBox(height: 16),
                  _ProfileField(
                    label: 'Full Name',
                    controller: _nameController,
                    hintText: 'Enter your full name',
                    prefixIcon: Icons.person_outline_rounded,
                    textInputAction: TextInputAction.next,
                    onChanged: (_) => setState(() {}),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter your name';
                      }
                      if (value.trim().length < 3) {
                        return 'Name must be at least 3 characters';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),
                  _ProfileField(
                    label: 'Email Address',
                    controller: _emailController,
                    hintText: 'Email linked with your sign in',
                    prefixIcon: Icons.email_outlined,
                    enabled: false,
                    helperText:
                        'Sign-in email is shown here and kept in sync with your account.',
                  ),
                  const SizedBox(height: 14),
                  _ProfileField(
                    label: 'Phone Number',
                    controller: _phoneController,
                    hintText: '9876543210',
                    prefixIcon: Icons.call_outlined,
                    keyboardType: TextInputType.phone,
                    textInputAction: TextInputAction.next,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter your phone number';
                      }
                      if (!RegExp(r'^\d{10}$').hasMatch(value.trim())) {
                        return 'Please enter a valid 10-digit phone';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),
                  _ProfileField(
                    label: 'City',
                    controller: _cityController,
                    hintText: 'Kolkata',
                    prefixIcon: Icons.location_city_outlined,
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 14),
                  _ProfileField(
                    label: 'Favorite Flavor',
                    controller: _favoriteFlavorController,
                    hintText: 'Chocolate Truffle',
                    prefixIcon: Icons.icecream_outlined,
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 14),
                  // _ProfileField(
                  //   label: 'Bio',
                  //   controller: _bioController,
                  //   hintText: 'Tell us about your cake style and celebrations',
                  //   prefixIcon: Icons.edit_note_rounded,
                  //   minLines: 3,
                  //   maxLines: 5,
                  //   textInputAction: TextInputAction.newline,
                  // ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: _cardDecoration(
                context,
                color: context.cakeTheme.softSurface,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.tips_and_updates_outlined,
                    color: ProfilePalette.primaryPink,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Your profile card on the main profile tab reads these saved values directly from Firebase, so updates appear there automatically after save.',
                      style: TextStyle(
                        color: context.cakeTheme.mutedText,
                        height: 1.45,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      ProfilePalette.primaryPink,
                      ProfilePalette.primaryPurple,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ElevatedButton(
                  onPressed: _isFetching || _isSaving ? null : _saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _isFetching || _isSaving
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
                          'Save Changes',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
