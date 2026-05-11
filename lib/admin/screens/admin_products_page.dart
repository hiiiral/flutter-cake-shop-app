import 'package:flutter/material.dart';

import '../../data/admin_repository.dart';
import '../../data/review_repository.dart';
import '../../shop_models.dart';
import '../admin_theme.dart';
import '../widgets/admin_widgets.dart';

enum _ProductStatusFilter { all, active, inactive }

class AdminProductsPage extends StatefulWidget {
  const AdminProductsPage({super.key});

  @override
  State<AdminProductsPage> createState() => _AdminProductsPageState();
}

class _AdminProductsPageState extends State<AdminProductsPage> {
  final AdminRepository _repository = AdminRepository();
  final ReviewRepository _reviewRepository = ReviewRepository();
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _categorySearchController =
      TextEditingController();

  _ProductStatusFilter _filter = _ProductStatusFilter.all;
  bool _isSaving = false;
  String _searchQuery = '';
  String _categorySearchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    _categorySearchController.dispose();
    super.dispose();
  }

  Future<void> _runMutation(
    Future<void> Function() action, {
    required String successMessage,
  }) async {
    if (_isSaving) return;

    setState(() => _isSaving = true);
    try {
      await action();
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(successMessage)));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Unable to save changes: $error')));
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _openCategoryForm([Category? category]) async {
    final result = await showDialog<_CategoryFormResult>(
      context: context,
      builder: (context) => _CategoryFormDialog(category: category),
    );

    if (result == null) return;

    await _runMutation(
      () => _repository.saveCategory(
        id: category?.id,
        name: result.name,
        description: result.description,
      ),
      successMessage: category == null
          ? 'Category added successfully.'
          : 'Category updated successfully.',
    );
  }

  Future<void> _confirmDeleteCategory(Category category) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete category?'),
          content: Text(
            '${category.name} will be removed and linked products will move to Uncategorized.',
          ),
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
        );
      },
    );

    if (confirmed != true) return;

    await _runMutation(
      () => _repository.deleteCategory(category),
      successMessage: 'Category deleted successfully.',
    );
  }

  Future<void> _openProductForm({
    required List<Category> categories,
    Product? product,
  }) async {
    if (categories.isEmpty && product == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Add a category first so products can be assigned.'),
        ),
      );
      return;
    }

    final result = await showModalBottomSheet<Product>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) =>
          _ProductFormSheet(categories: categories, product: product),
    );

    if (result == null) return;

    await _runMutation(
      () async {
        await _repository.saveProduct(result);
        await _reviewRepository.syncProductData(result);
      },
      successMessage: product == null
          ? 'Product added successfully.'
          : 'Product updated successfully.',
    );
  }

  Future<void> _confirmDeleteProduct(Product product) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete product?'),
          content: Text('${product.name} will be permanently removed.'),
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
        );
      },
    );

    if (confirmed != true) return;

    await _runMutation(() async {
      await _repository.deleteProduct(product.id);
      await _reviewRepository.deleteReviewsForProduct(product.id);
    }, successMessage: 'Product deleted successfully.');
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Category>>(
      stream: _repository.watchCategories(),
      builder: (context, categorySnapshot) {
        final categories = categorySnapshot.data ?? const <Category>[];

        return StreamBuilder<List<Product>>(
          stream: _repository.watchProducts(),
          builder: (context, productSnapshot) {
            final allProducts = productSnapshot.data ?? const <Product>[];
            final products = allProducts.where((product) {
              switch (_filter) {
                case _ProductStatusFilter.active:
                  return product.isActive;
                case _ProductStatusFilter.inactive:
                  return !product.isActive;
                case _ProductStatusFilter.all:
                  return true;
              }
            }).toList();
            final filteredProducts = products.where(_matchesSearch).toList();

            return Column(
              children: [
                AdminCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const AdminSectionTitle(
                        title: 'Catalog Manager',
                        subtitle:
                            'Create categories, maintain product details, and control product visibility from one place.',
                      ),
                      const SizedBox(height: 18),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          _SummaryPill(
                            title: 'Categories',
                            value: '${categories.length}',
                            color: AdminTheme.pink,
                          ),
                          _SummaryPill(
                            title: 'Visible',
                            value:
                                '${allProducts.where((item) => item.isActive).length}',
                            color: const Color(0xFF2AA876),
                          ),
                          _SummaryPill(
                            title: 'Hidden',
                            value:
                                '${allProducts.where((item) => !item.isActive).length}',
                            color: const Color(0xFFB86238),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          FilledButton.icon(
                            onPressed: _isSaving
                                ? null
                                : () => _openCategoryForm(),
                            icon: const Icon(Icons.category_outlined),
                            label: const Text('Add Category'),
                          ),
                          OutlinedButton.icon(
                            onPressed: _isSaving
                                ? null
                                : () =>
                                      _openProductForm(categories: categories),
                            icon: const Icon(Icons.cake_outlined),
                            label: const Text('Add Product'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                AdminCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const AdminSectionTitle(
                        title: 'Categories',
                        subtitle:
                            'Use categories to organize products and keep the storefront filters clean.',
                      ),
                      const SizedBox(height: 16),
                      AdminSearchField(
                        controller: _categorySearchController,
                        hintText: 'Search categories by name or description',
                        onChanged: (value) {
                          setState(() {
                            _categorySearchQuery = value.trim().toLowerCase();
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      if (categorySnapshot.hasError)
                        _AdminErrorState(message: '${categorySnapshot.error}')
                      else if (categorySnapshot.connectionState ==
                              ConnectionState.waiting &&
                          categories.isEmpty)
                        const Center(child: CircularProgressIndicator())
                      else if (categories.isEmpty)
                        const _EmptyAdminState(
                          icon: Icons.category_outlined,
                          title: 'No categories yet',
                          subtitle:
                              'Create your first category before adding new products.',
                        )
                      else
                        Builder(
                          builder: (context) {
                            final filteredCategories = categories
                                .where(_matchesCategorySearch)
                                .toList();
                            return filteredCategories.isEmpty
                                ? _EmptyAdminState(
                                    icon: Icons.search_off_outlined,
                                    title: _categorySearchQuery.isEmpty
                                        ? 'No categories in this view'
                                        : 'No categories match your search',
                                    subtitle: _categorySearchQuery.isEmpty
                                        ? 'Add a category to get started.'
                                        : 'Try a different category name or description.',
                                  )
                                : Wrap(
                                    spacing: 12,
                                    runSpacing: 12,
                                    children: filteredCategories.map((
                                      category,
                                    ) {
                                      final linkedCount = allProducts
                                          .where(
                                            (product) =>
                                                product.categoryId ==
                                                category.id,
                                          )
                                          .length;

                                      return SizedBox(
                                        width: 280,
                                        child: _CategoryCard(
                                          category: category,
                                          linkedCount: linkedCount,
                                          onEdit: _isSaving
                                              ? null
                                              : () =>
                                                    _openCategoryForm(category),
                                          onDelete: _isSaving
                                              ? null
                                              : () => _confirmDeleteCategory(
                                                  category,
                                                ),
                                        ),
                                      );
                                    }).toList(),
                                  );
                          },
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                AdminCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const AdminSectionTitle(
                        title: 'Products',
                        subtitle:
                            'Edit pricing, stock, and publish status without leaving the dashboard.',
                      ),
                      const SizedBox(height: 16),
                      AdminSearchField(
                        controller: _searchController,
                        hintText:
                            'Search by product name, category, description or price',
                        onChanged: (value) {
                          setState(() {
                            _searchQuery = value.trim().toLowerCase();
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _ProductStatusFilter.values.map((filter) {
                          final selected = _filter == filter;
                          return ChoiceChip(
                            label: Text(_filterLabel(filter)),
                            selected: selected,
                            onSelected: (_) => setState(() => _filter = filter),
                            selectedColor: const Color(0xFFFFE5F1),
                            labelStyle: TextStyle(
                              color: selected
                                  ? AdminTheme.pink
                                  : AdminTheme.text,
                              fontWeight: FontWeight.w600,
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),
                      if (productSnapshot.hasError)
                        _AdminErrorState(message: '${productSnapshot.error}')
                      else if (productSnapshot.connectionState ==
                              ConnectionState.waiting &&
                          filteredProducts.isEmpty)
                        const Center(child: CircularProgressIndicator())
                      else if (filteredProducts.isEmpty)
                        _EmptyAdminState(
                          icon: Icons.search_off_outlined,
                          title: _searchQuery.isEmpty
                              ? 'No products in this view'
                              : 'No products match your search',
                          subtitle: _searchQuery.isEmpty
                              ? 'Add a product or switch filters to see active and inactive items.'
                              : 'Try a different product name, category, description, or price.',
                        )
                      else
                        Column(
                          children: filteredProducts.map((product) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _ProductListTile(
                                product: product,
                                onEdit: _isSaving
                                    ? null
                                    : () => _openProductForm(
                                        categories: categories,
                                        product: product,
                                      ),
                                onDelete: _isSaving
                                    ? null
                                    : () => _confirmDeleteProduct(product),
                                onStatusChanged: _isSaving
                                    ? null
                                    : (value) => _runMutation(
                                        () => _repository.updateProductStatus(
                                          productId: product.id,
                                          isActive: value,
                                        ),
                                        successMessage: value
                                            ? '${product.name} is now active.'
                                            : '${product.name} moved to inactive.',
                                      ),
                              ),
                            );
                          }).toList(),
                        ),
                    ],
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  String _filterLabel(_ProductStatusFilter filter) {
    switch (filter) {
      case _ProductStatusFilter.all:
        return 'All';
      case _ProductStatusFilter.active:
        return 'Active';
      case _ProductStatusFilter.inactive:
        return 'Inactive';
    }
  }

  bool _matchesSearch(Product product) {
    if (_searchQuery.isEmpty) return true;

    final searchableText = [
      product.name,
      product.category,
      product.description,
      product.basePrice.toStringAsFixed(2),
      product.rating.toStringAsFixed(1),
      product.reviews.toString(),
      product.stockQuantity.toString(),
      product.isActive ? 'active' : 'inactive',
    ].join(' ').toLowerCase();

    return searchableText.contains(_searchQuery);
  }

  bool _matchesCategorySearch(Category category) {
    if (_categorySearchQuery.isEmpty) return true;

    final searchableText = [
      category.name,
      category.description,
    ].join(' ').toLowerCase();

    return searchableText.contains(_categorySearchQuery);
  }
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({
    required this.category,
    required this.linkedCount,
    required this.onEdit,
    required this.onDelete,
  });

  final Category category;
  final int linkedCount;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFBFBFD),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFECEAF3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const CircleAvatar(
                radius: 20,
                backgroundColor: Color(0xFFFFEEF5),
                child: Icon(Icons.category_outlined, color: AdminTheme.pink),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  category.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AdminTheme.text,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            category.description.isEmpty
                ? 'No description added yet.'
                : category.description,
            style: const TextStyle(color: AdminTheme.muted, height: 1.4),
          ),
          const SizedBox(height: 14),
          AdminBadge(
            label: '$linkedCount linked products',
            color: AdminTheme.purple,
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Edit'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextButton.icon(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Delete'),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFFC94949),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProductListTile extends StatelessWidget {
  const _ProductListTile({
    required this.product,
    required this.onEdit,
    required this.onDelete,
    required this.onStatusChanged,
  });

  final Product product;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final ValueChanged<bool>? onStatusChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFBFBFD),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFECEAF3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFEFF7),
                  borderRadius: BorderRadius.circular(18),
                ),
                alignment: Alignment.center,
                child: const Icon(Icons.cake_outlined, color: AdminTheme.pink),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AdminTheme.text,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      product.category.isEmpty
                          ? 'Uncategorized'
                          : product.category,
                      style: const TextStyle(color: AdminTheme.muted),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        AdminBadge(
                          label: product.isActive ? 'Active' : 'Inactive',
                          color: product.isActive
                              ? const Color(0xFF2AA876)
                              : const Color(0xFFB86238),
                        ),
                        AdminBadge(
                          label: 'Stock ${product.stockQuantity}',
                          color: AdminTheme.purple,
                        ),
                        AdminBadge(
                          label:
                              '${product.rating.toStringAsFixed(1)} star (${product.reviews})',
                          color: const Color(0xFFD59B00),
                        ),
                        AdminBadge(
                          label:
                              'From ₹${product.basePrice.toStringAsFixed(2)}',
                          color: AdminTheme.pink,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (product.description.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              product.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: AdminTheme.muted, height: 1.4),
            ),
          ],
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SizedBox(
                width: 190,
                child: SwitchListTile(
                  value: product.isActive,
                  dense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                  title: const Text('Visible in store'),
                  activeThumbColor: AdminTheme.pink,
                  onChanged: onStatusChanged,
                ),
              ),
              OutlinedButton.icon(
                onPressed: onEdit,
                icon: const Icon(Icons.edit_outlined),
                label: const Text('Edit'),
              ),
              TextButton.icon(
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline),
                label: const Text('Delete'),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFFC94949),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryPill extends StatelessWidget {
  const _SummaryPill({
    required this.title,
    required this.value,
    required this.color,
  });

  final String title;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 22,
            ),
          ),
          const SizedBox(height: 4),
          Text(title, style: const TextStyle(color: AdminTheme.muted)),
        ],
      ),
    );
  }
}

class _EmptyAdminState extends StatelessWidget {
  const _EmptyAdminState({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 22),
      child: Column(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: const Color(0xFFFFEEF5),
            child: Icon(icon, color: AdminTheme.pink),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: AdminTheme.text,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AdminTheme.muted, height: 1.4),
          ),
        ],
      ),
    );
  }
}

class _AdminErrorState extends StatelessWidget {
  const _AdminErrorState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        children: [
          const CircleAvatar(
            radius: 28,
            backgroundColor: Color(0xFFFFEEF5),
            child: Icon(Icons.cloud_off_outlined, color: AdminTheme.pink),
          ),
          const SizedBox(height: 14),
          const Text(
            'Firebase error',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: AdminTheme.text,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AdminTheme.muted, height: 1.4),
          ),
        ],
      ),
    );
  }
}

class _CategoryFormResult {
  const _CategoryFormResult({required this.name, required this.description});

  final String name;
  final String description;
}

class _CategoryFormDialog extends StatefulWidget {
  const _CategoryFormDialog({this.category});

  final Category? category;

  @override
  State<_CategoryFormDialog> createState() => _CategoryFormDialogState();
}

class _CategoryFormDialogState extends State<_CategoryFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.category?.name ?? '');
    _descriptionController = TextEditingController(
      text: widget.category?.description ?? '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    Navigator.pop(
      context,
      _CategoryFormResult(
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.category != null;

    return AlertDialog(
      title: Text(editing ? 'Edit Category' : 'Add Category'),
      content: Form(
        key: _formKey,
        child: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Category name'),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Enter a category name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _descriptionController,
                minLines: 3,
                maxLines: 4,
                decoration: const InputDecoration(labelText: 'Description'),
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
          child: Text(editing ? 'Save' : 'Create'),
        ),
      ],
    );
  }
}

class _ProductFormSheet extends StatefulWidget {
  const _ProductFormSheet({required this.categories, this.product});

  final List<Category> categories;
  final Product? product;

  @override
  State<_ProductFormSheet> createState() => _ProductFormSheetState();
}

class _ProductFormSheetState extends State<_ProductFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _basePriceController;
  late final TextEditingController _imagePathController;

  late final TextEditingController _descriptionController;
  late final TextEditingController _stockController;

  late String _selectedCategoryId;
  late bool _isActive;
  late List<_WeightOptionDraft> _weightOptions;
  bool _isSubmitting = false;
  String? _formErrorMessage;

  @override
  void initState() {
    super.initState();
    final product = widget.product;

    _nameController = TextEditingController(text: product?.name ?? '');
    _basePriceController = TextEditingController(
      text: product == null ? '' : product.basePrice.toStringAsFixed(2),
    );
    _imagePathController = TextEditingController(text: product?.image ?? '');
    _descriptionController = TextEditingController(
      text: product?.description ?? '',
    );
    _stockController = TextEditingController(
      text: product == null ? '0' : product.stockQuantity.toString(),
    );
    _selectedCategoryId = product?.categoryId ?? '';
    _isActive = product?.isActive ?? true;
    _weightOptions = (product?.weightOptions ?? const <ProductWeightOption>[])
        .map(
          (item) => _WeightOptionDraft(
            id: item.id,
            labelController: TextEditingController(text: item.label),
            priceController: TextEditingController(
              text: item.price.toStringAsFixed(2),
            ),
          ),
        )
        .toList();

    if (_weightOptions.isEmpty) {
      _weightOptions = [_WeightOptionDraft.empty()];
    }
  }

  void _showFormError(String message) {
    if (!mounted) return;
    setState(() => _formErrorMessage = message);
  }

  void _clearFormError() {
    if (!mounted || _formErrorMessage == null) return;
    setState(() => _formErrorMessage = null);
  }

  bool _isNetworkImage(String imagePath) {
    return imagePath.startsWith('http://') || imagePath.startsWith('https://');
  }

  bool _isAssetImage(String imagePath) {
    return imagePath.startsWith('assets/');
  }

  Widget _buildImagePreview() {
    final currentImage = _imagePathController.text.trim();

    if (currentImage.isEmpty) {
      return Container(
        height: 120,
        decoration: BoxDecoration(
          color: const Color(0xFFFFEEF5),
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.center,
        child: const Icon(Icons.cake_outlined, color: AdminTheme.pink),
      );
    }

    if (_isNetworkImage(currentImage)) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(
          currentImage,
          height: 120,
          width: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => Container(
            height: 120,
            color: const Color(0xFFF2F2F2),
            alignment: Alignment.center,
            child: const Icon(Icons.broken_image_outlined),
          ),
        ),
      );
    }

    if (_isAssetImage(currentImage)) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.asset(
          currentImage,
          height: 120,
          width: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => Container(
            height: 120,
            color: const Color(0xFFF2F2F2),
            alignment: Alignment.center,
            child: const Icon(Icons.broken_image_outlined),
          ),
        ),
      );
    }

    return Container(
      height: 120,
      decoration: BoxDecoration(
        color: const Color(0xFFF2F2F2),
        borderRadius: BorderRadius.circular(12),
      ),
      alignment: Alignment.center,
      child: const Icon(Icons.broken_image_outlined),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _basePriceController.dispose();
    _imagePathController.dispose();
    _descriptionController.dispose();
    _stockController.dispose();
    for (final option in _weightOptions) {
      option.dispose();
    }
    super.dispose();
  }

  void _addWeightOption() {
    setState(() => _weightOptions.add(_WeightOptionDraft.empty()));
  }

  void _removeWeightOption(_WeightOptionDraft option) {
    if (_weightOptions.length == 1) return;

    setState(() {
      option.dispose();
      _weightOptions.remove(option);
    });
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;
    if (!_formKey.currentState!.validate()) return;
    _clearFormError();

    if (widget.categories.isNotEmpty && _selectedCategoryId.isEmpty) {
      _showFormError('Select a category for this product.');
      return;
    }

    final category = widget.categories.cast<Category?>().firstWhere(
      (item) => item?.id == _selectedCategoryId,
      orElse: () => null,
    );

    final weightOptions = <ProductWeightOption>[];
    for (final option in _weightOptions) {
      final label = option.labelController.text.trim();
      final price = double.tryParse(option.priceController.text.trim());

      if (label.isEmpty || price == null) {
        _showFormError('Each weight option needs a label and a valid price.');
        return;
      }

      weightOptions.add(
        ProductWeightOption(
          id: option.id.isEmpty ? slugifyValue(label) : option.id,
          label: label,
          price: price,
        ),
      );
    }

    setState(() => _isSubmitting = true);

    try {
      final imagePath = _imagePathController.text.trim();
      final previousImagePath = widget.product?.image ?? '';
      final imageStoragePath = imagePath == previousImagePath
          ? widget.product?.imageStoragePath ?? ''
          : '';

      if (imagePath.isEmpty) {
        _showFormError('Enter an image path for this product.');
        return;
      }

      if (!_isAssetImage(imagePath) && !_isNetworkImage(imagePath)) {
        _showFormError(
          'Use an asset path like assets/image.jpg or a full image URL.',
        );
        return;
      }

      if (!mounted) return;

      Navigator.pop(
        context,
        Product(
          id: widget.product?.id ?? '',
          name: _nameController.text.trim(),
          basePrice: double.parse(_basePriceController.text.trim()),
          category: category?.name ?? widget.product?.category ?? '',
          categoryId: category?.id ?? widget.product?.categoryId ?? '',
          image: imagePath,
          imageStoragePath: imageStoragePath,
          description: _descriptionController.text.trim(),
          isActive: _isActive,
          stockQuantity: int.parse(_stockController.text.trim()),
          weightOptions: weightOptions,
          rating: widget.product?.rating ?? 0,
          reviews: widget.product?.reviews ?? 0,
        ),
      );
    } catch (error) {
      _showFormError('Unable to save product: $error');
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.of(context).viewInsets.bottom;
    final editing = widget.product != null;
    final selectedCategoryValue =
        widget.categories.any((category) => category.id == _selectedCategoryId)
        ? _selectedCategoryId
        : null;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, 16, 16, viewInsets + 16),
        child: Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          editing ? 'Edit Product' : 'Add Product',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: AdminTheme.text,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  if (_formErrorMessage != null) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF1F1),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFFFCACA)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(top: 1),
                            child: Icon(
                              Icons.error_outline,
                              color: Color(0xFFC53D3D),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _formErrorMessage!,
                              style: const TextStyle(
                                color: Color(0xFF8C2424),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Product name',
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Enter the product name';
                      }
                      return null;
                    },
                    onChanged: (_) => _clearFormError(),
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<String>(
                    initialValue: selectedCategoryValue,
                    items: widget.categories.map((category) {
                      return DropdownMenuItem<String>(
                        value: category.id,
                        child: Text(category.name),
                      );
                    }).toList(),
                    onChanged: widget.categories.isEmpty
                        ? null
                        : (value) {
                            setState(() {
                              _selectedCategoryId = value ?? '';
                              _formErrorMessage = null;
                            });
                          },
                    decoration: const InputDecoration(labelText: 'Category'),
                  ),
                  const SizedBox(height: 14),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final compact = constraints.maxWidth < 540;
                      final fields = [
                        _NumberField(
                          controller: _basePriceController,
                          label: 'Base price',
                          allowDecimal: true,
                          validatorText: 'Enter a valid base price',
                        ),
                        _NumberField(
                          controller: _stockController,
                          label: 'Stock quantity',
                          validatorText: 'Enter stock quantity',
                        ),
                      ];

                      if (compact) {
                        return Column(
                          children: fields
                              .map(
                                (field) => Padding(
                                  padding: const EdgeInsets.only(bottom: 14),
                                  child: field,
                                ),
                              )
                              .toList(),
                        );
                      }

                      return Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: fields
                            .map(
                              (field) => SizedBox(
                                width: (constraints.maxWidth - 12) / 2,
                                child: field,
                              ),
                            )
                            .toList(),
                      );
                    },
                  ),
                  const SizedBox(height: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Product Image',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 10),
                      _buildImagePreview(),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _imagePathController,
                        decoration: const InputDecoration(
                          labelText: 'Image path',
                          hintText: 'assets/image.jpg',
                        ),
                        validator: (value) {
                          final imagePath = value?.trim() ?? '';
                          if (imagePath.isEmpty) {
                            return 'Enter an image path';
                          }
                          if (!_isAssetImage(imagePath) &&
                              !_isNetworkImage(imagePath)) {
                            return 'Use assets/... or a full image URL';
                          }
                          return null;
                        },
                        onChanged: (_) {
                          setState(() {
                            _formErrorMessage = null;
                          });
                        },
                      ),

                      const SizedBox(height: 8),
                      const Text(
                        'Use an asset path like assets/image.jpg to show a bundled image.',
                        style: TextStyle(color: Colors.black54, fontSize: 12),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _descriptionController,
                    minLines: 3,
                    maxLines: 5,
                    decoration: const InputDecoration(labelText: 'Description'),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Enter a short description';
                      }
                      return null;
                    },
                    onChanged: (_) => _clearFormError(),
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    value: _isActive,
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Product is active'),
                    subtitle: const Text(
                      'Inactive products stay in admin but are hidden from customers.',
                    ),
                    activeThumbColor: AdminTheme.pink,
                    onChanged: (value) => setState(() => _isActive = value),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Weight options',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: AdminTheme.text,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      TextButton.icon(
                        onPressed: _addWeightOption,
                        icon: const Icon(Icons.add),
                        label: const Text('Add option'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ..._weightOptions.map((option) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFBFBFD),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: const Color(0xFFECEAF3)),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: option.labelController,
                                decoration: const InputDecoration(
                                  labelText: 'Label',
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextFormField(
                                controller: option.priceController,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                decoration: const InputDecoration(
                                  labelText: 'Price',
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed: () => _removeWeightOption(option),
                              icon: const Icon(Icons.delete_outline),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _isSubmitting ? null : _submit,
                      child: Text(
                        _isSubmitting
                            ? (editing ? 'Saving...' : 'Creating...')
                            : (editing ? 'Save Product' : 'Create Product'),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NumberField extends StatelessWidget {
  const _NumberField({
    required this.controller,
    required this.label,
    required this.validatorText,
    this.allowDecimal = false,
  });

  final TextEditingController controller;
  final String label;
  final String validatorText;
  final bool allowDecimal;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.numberWithOptions(decimal: allowDecimal),
      decoration: InputDecoration(labelText: label),
      validator: (value) {
        final parsed = allowDecimal
            ? double.tryParse(value ?? '')
            : int.tryParse(value ?? '');
        if (parsed == null) {
          return validatorText;
        }
        return null;
      },
    );
  }
}

class _WeightOptionDraft {
  _WeightOptionDraft({
    required this.id,
    required this.labelController,
    required this.priceController,
  });

  factory _WeightOptionDraft.empty() {
    return _WeightOptionDraft(
      id: '',
      labelController: TextEditingController(),
      priceController: TextEditingController(),
    );
  }

  final String id;
  final TextEditingController labelController;
  final TextEditingController priceController;

  void dispose() {
    labelController.dispose();
    priceController.dispose();
  }
}
