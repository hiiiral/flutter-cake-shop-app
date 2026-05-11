import 'package:flutter/material.dart';

import '../../data/review_repository.dart';
import '../../shop_models.dart';
import '../admin_theme.dart';
import '../widgets/admin_widgets.dart';

class AdminReviewsPage extends StatefulWidget {
  const AdminReviewsPage({super.key});

  @override
  State<AdminReviewsPage> createState() => _AdminReviewsPageState();
}

class _AdminReviewsPageState extends State<AdminReviewsPage> {
  final ReviewRepository _repository = ReviewRepository();
  final TextEditingController _searchController = TextEditingController();

  bool _isSaving = false;
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
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

  Future<void> _approveReview(ProductReview review) async {
    await _runMutation(
      () => _repository.approveReview(review),
      successMessage: 'Review approved successfully.',
    );
  }

  Future<void> _deleteReview(ProductReview review) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete review?'),
          content: Text(
            'This will remove the review from ${review.productName.isEmpty ? 'the product' : review.productName}.',
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
      () => _repository.deleteReview(review),
      successMessage: 'Review deleted successfully.',
    );
  }

  bool _matchesSearch(ProductReview review) {
    if (_searchQuery.isEmpty) return true;

    final text = [
      review.productName,
      review.authorLabel,
      review.userEmail,
      review.review,
      review.rating.toString(),
      'pending',
    ].join(' ').toLowerCase();

    return text.contains(_searchQuery);
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<ProductReview>>(
      stream: _repository.watchPendingReviews(),
      builder: (context, snapshot) {
        final reviews = snapshot.data ?? const <ProductReview>[];
        final filteredReviews = reviews.where(_matchesSearch).toList();

        return Column(
          children: [
            AdminCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AdminSectionTitle(
                    title: 'Review Approval',
                    subtitle: reviews.isEmpty
                        ? 'New customer reviews will appear here before they go live in the shop.'
                        : '${reviews.length} review${reviews.length == 1 ? '' : 's'} waiting for approval.',
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      _ReviewCountPill(
                        title: 'Pending',
                        value: '${reviews.length}',
                        color: AdminTheme.pink,
                      ),
                      _ReviewCountPill(
                        title: 'Showing',
                        value: '${filteredReviews.length}',
                        color: AdminTheme.purple,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  AdminSearchField(
                    controller: _searchController,
                    hintText: 'Search by product, customer, rating or review',
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value.trim().toLowerCase();
                      });
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
                    title: 'Pending Reviews',
                    subtitle:
                        'Search updates while you type, so it is easy to find the right review quickly.',
                  ),
                  const SizedBox(height: 16),
                  if (snapshot.hasError)
                    _ReviewMessage(
                      icon: Icons.cloud_off_outlined,
                      title: 'Firebase error',
                      subtitle: '${snapshot.error}',
                    )
                  else if (snapshot.connectionState ==
                          ConnectionState.waiting &&
                      reviews.isEmpty)
                    const Center(child: CircularProgressIndicator())
                  else if (reviews.isEmpty)
                    const _ReviewMessage(
                      icon: Icons.rate_review_outlined,
                      title: 'No pending reviews',
                      subtitle:
                          'Approved product reviews will show in the shop automatically.',
                    )
                  else if (filteredReviews.isEmpty)
                    const _ReviewMessage(
                      icon: Icons.search_off_outlined,
                      title: 'No reviews match your search',
                      subtitle:
                          'Try another product name, customer name, rating, or keyword.',
                    )
                  else
                    Column(
                      children: filteredReviews.map((review) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _PendingReviewTile(
                            review: review,
                            onApprove: _isSaving
                                ? null
                                : () => _approveReview(review),
                            onDelete: _isSaving
                                ? null
                                : () => _deleteReview(review),
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
  }
}

class _PendingReviewTile extends StatelessWidget {
  const _PendingReviewTile({
    required this.review,
    required this.onApprove,
    required this.onDelete,
  });

  final ProductReview review;
  final VoidCallback? onApprove;
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFEFF7),
                  borderRadius: BorderRadius.circular(18),
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.rate_review_outlined,
                  color: AdminTheme.pink,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review.productName.isEmpty
                          ? 'Product review'
                          : review.productName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AdminTheme.text,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${review.authorLabel} • ${_reviewDate(review.createdAt)}',
                      style: const TextStyle(color: AdminTheme.muted),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        AdminBadge(
                          label: '${review.rating}/5 stars',
                          color: const Color(0xFFD59B00),
                        ),
                        const AdminBadge(
                          label: 'Pending',
                          color: AdminTheme.purple,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (review.review.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              review.review,
              style: const TextStyle(color: AdminTheme.muted, height: 1.4),
            ),
          ],
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              FilledButton.icon(
                onPressed: onApprove,
                icon: const Icon(Icons.check_circle_outline),
                label: const Text('Approve'),
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

class _ReviewCountPill extends StatelessWidget {
  const _ReviewCountPill({
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

class _ReviewMessage extends StatelessWidget {
  const _ReviewMessage({
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

String _reviewDate(DateTime? value) {
  if (value == null) return 'Just now';
  return '${value.day}/${value.month}/${value.year}';
}
