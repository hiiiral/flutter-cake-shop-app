part of '../profile_section_pages.dart';

class ProfileAddressesPage extends StatefulWidget {
  const ProfileAddressesPage({super.key});

  @override
  State<ProfileAddressesPage> createState() => _ProfileAddressesPageState();
}

class _ProfileAddressesPageState extends State<ProfileAddressesPage> {
  static const int _maxAddresses = 2;

  bool _isLoading = true;
  bool _isSaving = false;
  String _savedName = '';
  String _savedPhone = '';
  List<_UserAddress> _addresses = [];

  User? get _currentUser => FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _loadAddresses();
  }

  Future<void> _loadAddresses() async {
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

      final data = snapshot.data() ?? <String, dynamic>{};
      final items = (data['addresses'] as List<dynamic>? ?? [])
          .whereType<Map>()
          .map((item) => _UserAddress.fromMap(Map<String, dynamic>.from(item)))
          .toList();

      if (!mounted) return;
      setState(() {
        _savedName =
            (data['name'] as String?)?.trim() ?? user.displayName?.trim() ?? '';
        _savedPhone = (data['phone'] as String?)?.trim() ?? '';
        _addresses = _normalizeAddresses(items);
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showMessage('Could not load your addresses.');
    }
  }

  List<_UserAddress> _normalizeAddresses(List<_UserAddress> items) {
    if (items.isEmpty) return [];

    final orderedItems = List<_UserAddress>.generate(
      items.length,
      (index) => items[index].copyWith(label: 'Address ${index + 1}'),
    );

    final hasDefault = orderedItems.any((item) => item.isDefault);
    if (hasDefault) {
      var foundDefault = false;
      return orderedItems.map((item) {
        if (!item.isDefault) return item;
        if (!foundDefault) {
          foundDefault = true;
          return item;
        }
        return item.copyWith(isDefault: false);
      }).toList();
    }

    return [
      orderedItems.first.copyWith(isDefault: true),
      ...orderedItems.skip(1),
    ];
  }

  Future<bool> _saveAddresses(List<_UserAddress> items) async {
    final user = _currentUser;
    if (user == null || _isSaving) return false;

    setState(() => _isSaving = true);

    try {
      final safeItems = _normalizeAddresses(items);

      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'uid': user.uid,
        'addresses': safeItems.map((item) => item.toMap()).toList(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (!mounted) return false;
      setState(() => _addresses = safeItems);
      return true;
    } on FirebaseException catch (error) {
      if (!mounted) return false;
      _showMessage(error.message ?? 'Could not save your addresses.');
    } catch (_) {
      if (!mounted) return false;
      _showMessage('Something went wrong while saving addresses.');
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }

    return false;
  }

  Future<void> _addAddress() async {
    if (_addresses.length >= _maxAddresses) {
      _showMessage('You can save only 2 addresses.');
      return;
    }

    final address = await showDialog<_UserAddress>(
      context: context,
      builder: (_) => _AddressFormDialog(
        initialName: _savedName,
        initialPhone: _savedPhone,
        makeDefault: _addresses.isEmpty,
      ),
    );

    if (address == null) return;

    final items = [..._addresses];
    final newAddress = address.copyWith(label: 'Address ${items.length + 1}');

    if (newAddress.isDefault) {
      for (var i = 0; i < items.length; i++) {
        items[i] = items[i].copyWith(isDefault: false);
      }
    }

    final isSaved = await _saveAddresses([...items, newAddress]);

    if (!mounted || !isSaved) return;
    _showMessage('Address added successfully.');
  }

  Future<void> _editAddress(int index) async {
    final address = await showDialog<_UserAddress>(
      context: context,
      builder: (_) => _AddressFormDialog(
        address: _addresses[index],
        initialName: _savedName,
        initialPhone: _savedPhone,
        makeDefault: _addresses[index].isDefault,
      ),
    );

    if (address == null) return;

    final items = [..._addresses];
    items[index] = address.copyWith(label: items[index].label);

    if (address.isDefault) {
      for (var i = 0; i < items.length; i++) {
        if (i != index) {
          items[i] = items[i].copyWith(isDefault: false);
        }
      }
    }

    final isSaved = await _saveAddresses(items);

    if (!mounted || !isSaved) return;
    _showMessage('Address updated successfully.');
  }

  Future<void> _deleteAddress(int index) async {
    final shouldDelete =
        await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Delete address?'),
            content: const Text('This saved address will be removed.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Delete'),
              ),
            ],
          ),
        ) ??
        false;

    if (!shouldDelete) return;

    final items = [..._addresses]..removeAt(index);
    final isSaved = await _saveAddresses(items);

    if (!mounted || !isSaved) return;
    _showMessage('Address deleted successfully.');
  }

  Future<void> _setDefaultAddress(int index) async {
    final items = List<_UserAddress>.generate(
      _addresses.length,
      (itemIndex) =>
          _addresses[itemIndex].copyWith(isDefault: itemIndex == index),
    );

    final isSaved = await _saveAddresses(items);

    if (!mounted || !isSaved) return;
    _showMessage('Default address updated.');
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final user = _currentUser;

    if (user == null) {
      return const _ProfileSectionScaffold(
        title: 'Addresses',
        subtitle: 'Sign in to manage your saved delivery addresses.',
        icon: Icons.location_on_outlined,
        child: _SignInPromptCard(),
      );
    }

    return _ProfileSectionScaffold(
      title: 'Addresses',
      subtitle: 'Add, edit and choose the address you use most.',
      icon: Icons.location_on_outlined,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: _cardDecoration(context),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SectionTitle(
                      title: 'Delivery Addresses',
                      subtitle:
                          'You can save up to $_maxAddresses addresses.',
                    ),
                    const SizedBox(height: 12),
                    _StatusChip(
                      label: '${_addresses.length}/$_maxAddresses Saved',
                      color: ProfilePalette.primaryPink,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: _isLoading || _isSaving ? null : _addAddress,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: context.cakeTheme.softSurface,
                      foregroundColor: ProfilePalette.primaryPink,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    icon: const Icon(Icons.add_location_alt_outlined),
                    label: const Text(
                      'Add Address',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                if (_isLoading)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: CircularProgressIndicator(),
                    ),
                  )
                else if (_addresses.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: context.cakeTheme.softSurface,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: context.cakeTheme.border),
                    ),
                    child: Text(
                      'No address saved yet. Add your home or work address to make delivery faster.',
                      style: TextStyle(
                        color: context.cakeTheme.mutedText,
                        height: 1.5,
                      ),
                    ),
                  )
                else
                  ...List.generate(
                    _addresses.length,
                    (index) => Padding(
                      padding: EdgeInsets.only(
                        bottom: index == _addresses.length - 1 ? 0 : 14,
                      ),
                      child: _SavedAddressCard(
                        item: _addresses[index],
                        isSaving: _isSaving,
                        onEdit: () => _editAddress(index),
                        onDelete: () => _deleteAddress(index),
                        onSetDefault: () => _setDefaultAddress(index),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SavedAddressCard extends StatelessWidget {
  const _SavedAddressCard({
    required this.item,
    required this.onEdit,
    required this.onDelete,
    required this.onSetDefault,
    required this.isSaving,
  });

  final _UserAddress item;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onSetDefault;
  final bool isSaving;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.cakeTheme.softSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: context.cakeTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  item.label,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: context.colorScheme.onSurface,
                  ),
                ),
              ),
              if (item.isDefault)
                _StatusChip(label: 'Default', color: context.cakeTheme.success),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            item.name,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: context.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(item.phone, style: TextStyle(color: context.cakeTheme.mutedText)),
          const SizedBox(height: 8),
          Text(
            item.address,
            style: TextStyle(
              color: context.cakeTheme.mutedText,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                TextButton.icon(
                  onPressed: isSaving ? null : onEdit,
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: const Text('Edit'),
                ),
                TextButton.icon(
                  onPressed: isSaving ? null : onDelete,
                  icon: const Icon(Icons.delete_outline_rounded, size: 18),
                  label: const Text('Delete'),
                ),
                if (!item.isDefault)
                  TextButton(
                    onPressed: isSaving ? null : onSetDefault,
                    child: const Text('Set Default'),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AddressFormDialog extends StatefulWidget {
  const _AddressFormDialog({
    this.address,
    required this.initialName,
    required this.initialPhone,
    required this.makeDefault,
  });

  final _UserAddress? address;
  final String initialName;
  final String initialPhone;
  final bool makeDefault;

  @override
  State<_AddressFormDialog> createState() => _AddressFormDialogState();
}

class _AddressFormDialogState extends State<_AddressFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _addressController;
  late bool _isDefault;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.address?.name ?? widget.initialName,
    );
    _phoneController = TextEditingController(
      text: widget.address?.phone ?? widget.initialPhone,
    );
    _addressController = TextEditingController(
      text: widget.address?.address ?? '',
    );
    _isDefault = widget.address?.isDefault ?? widget.makeDefault;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    Navigator.pop(
      context,
      _UserAddress(
        label: widget.address?.label ?? '',
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        address: _addressController.text.trim(),
        isDefault: _isDefault,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.address != null;

    return AlertDialog(
      title: Text(isEdit ? 'Edit Address' : 'Add Address'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _ProfileField(
                label: 'Full Name',
                controller: _nameController,
                hintText: 'Enter your full name',
                prefixIcon: Icons.person_outline_rounded,
                textInputAction: TextInputAction.next,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter your name';
                  }
                  return null;
                },
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
                label: 'Full Address',
                controller: _addressController,
                hintText: 'House no, street, city, state, pincode',
                prefixIcon: Icons.location_on_outlined,
                minLines: 3,
                maxLines: 4,
                textInputAction: TextInputAction.newline,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter your address';
                  }
                  if (value.trim().length < 10) {
                    return 'Address must be at least 10 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 8),
              CheckboxListTile(
                value: _isDefault,
                contentPadding: EdgeInsets.zero,
                activeColor: ProfilePalette.primaryPink,
                title: const Text('Set as default address'),
                controlAffinity: ListTileControlAffinity.leading,
                onChanged: (value) {
                  setState(() => _isDefault = value ?? false);
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _submit,
          style: FilledButton.styleFrom(
            backgroundColor: ProfilePalette.primaryPink,
          ),
          child: Text(isEdit ? 'Update' : 'Save'),
        ),
      ],
    );
  }
}

class _UserAddress {
  const _UserAddress({
    required this.label,
    required this.name,
    required this.phone,
    required this.address,
    required this.isDefault,
  });

  final String label;
  final String name;
  final String phone;
  final String address;
  final bool isDefault;

  factory _UserAddress.fromMap(Map<String, dynamic> map) {
    return _UserAddress(
      label: (map['label'] as String?)?.trim().isNotEmpty == true
          ? (map['label'] as String).trim()
          : 'Address',
      name: (map['name'] as String?)?.trim() ?? '',
      phone: (map['phone'] as String?)?.trim() ?? '',
      address: (map['address'] as String?)?.trim() ?? '',
      isDefault: map['isDefault'] == true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'label': label,
      'name': name,
      'phone': phone,
      'address': address,
      'isDefault': isDefault,
    };
  }

  _UserAddress copyWith({
    String? label,
    String? name,
    String? phone,
    String? address,
    bool? isDefault,
  }) {
    return _UserAddress(
      label: label ?? this.label,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      isDefault: isDefault ?? this.isDefault,
    );
  }
}
