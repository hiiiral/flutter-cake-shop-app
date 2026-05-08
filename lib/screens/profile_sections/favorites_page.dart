part of '../profile_section_pages.dart';

class ProfileFavoritesPage extends StatelessWidget {
  const ProfileFavoritesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    return _ProfileSectionScaffold(
      title: 'Favorites',
      subtitle: 'Your saved wishlist picks, synced from Firebase.',
      icon: Icons.favorite_border_rounded,
      child: currentUser == null
          ? const _SignInPromptCard()
          : StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(currentUser.uid)
                  .snapshots(),
              builder: (context, snapshot) {
                final wishlistItems = UserShopData.fromUserDocument(
                  snapshot.data?.data(),
                ).wishlistItems;

                if (snapshot.connectionState == ConnectionState.waiting &&
                    !snapshot.hasData) {
                  return const Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                return Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: _cardDecoration(
                        context,
                        color: context.cakeTheme.softSurface,
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.favorite_rounded,
                            color: ProfilePalette.primaryPink,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              wishlistItems.isEmpty
                                  ? 'Save cakes from the shop tab and they will appear here automatically.'
                                  : 'Your synced wishlist is ready for the next celebration.',
                              style: TextStyle(
                                color: context.cakeTheme.mutedText,
                                height: 1.45,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (wishlistItems.isEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: _cardDecoration(context),
                        child: Column(
                          children: [
                            Icon(
                              Icons.favorite_border_rounded,
                              size: 44,
                              color: context.colorScheme.primary,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'No favorites saved yet',
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Tap the heart on any cake to keep it in your synced wishlist.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: context.cakeTheme.mutedText,
                                height: 1.45,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ...wishlistItems.asMap().entries.map((entry) {
                      final index = entry.key;
                      final product = entry.value;
                      final category = product.category.trim();
                      final optionCount = product.weightOptions.length;
                      final subtitle = [
                        if (category.isNotEmpty) category,
                        '$optionCount size option${optionCount == 1 ? '' : 's'}',
                      ].join(' • ');

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: _FavoriteCard(
                          item: _FavoritePreview(
                            title: product.name,
                            subtitle: subtitle,
                            price:
                                '\u20B9${product.basePrice.toStringAsFixed(2)}',
                            accent: _favoriteAccent(index, context),
                          ),
                        ),
                      );
                    }),
                  ],
                );
              },
            ),
    );
  }
}

Color _favoriteAccent(int index, BuildContext context) {
  final accents = [
    context.cakeTheme.softSurface,
    const Color(0xFFFFF5F2),
    const Color(0xFFF5F8FF),
  ];

  return accents[index % accents.length];
}
