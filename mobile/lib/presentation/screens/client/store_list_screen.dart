import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/store_provider.dart';
import '../../widgets/store_card.dart';
import 'store_details_screen.dart';

class StoreListScreen extends StatefulWidget {
  const StoreListScreen({super.key});

  @override
  State<StoreListScreen> createState() => _StoreListScreenState();
}

class _StoreListScreenState extends State<StoreListScreen> {
  String _searchQuery = "";
  double _minRating = 0.0;
  bool _onlyOpen = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => 
      context.read<StoreProvider>().fetchStores()
    );
  }

  void _showRatingFilter() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Filtrer par note minimale',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF2D1A0E),
                      fontFamily: 'Georgia',
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildRatingOption(0.0, 'Toutes les épiceries', setModalState),
                  _buildRatingOption(3.0, '3.0 étoiles et plus', setModalState),
                  _buildRatingOption(3.5, '3.5 étoiles et plus', setModalState),
                  _buildRatingOption(4.0, '4.0 étoiles et plus', setModalState),
                  const SizedBox(height: 20),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildRatingOption(double rating, String label, StateSetter setModalState) {
    bool isSelected = _minRating == rating;
    return InkWell(
      onTap: () {
        setState(() => _minRating = rating);
        setModalState(() {});
        Navigator.pop(context);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          children: [
            Icon(
              rating == 0.0 ? Icons.all_inclusive : Icons.star_border_rounded,
              color: isSelected ? const Color(0xFFD97E4A) : Colors.black87,
              size: 24,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? const Color(0xFFD97E4A) : Colors.black87,
                ),
              ),
            ),
            if (isSelected)
              const Icon(Icons.check, color: Color(0xFFD97E4A), size: 20),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2EBE3), // Beige background from mockups
      body: Consumer<StoreProvider>(
        builder: (context, storeProvider, child) {
          if (storeProvider.isLoading) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF4C6444)));
          }

          final filteredStores = storeProvider.stores.where((s) {
            final matchesSearch = s.nomBoutique.toLowerCase().contains(_searchQuery.toLowerCase());
            final matchesRating = s.rating >= _minRating;
            return matchesSearch && matchesRating;
          }).toList();

          return CustomScrollView(
            slivers: [
              // Search Header
              SliverToBoxAdapter(
                child: Container(
                  padding: const EdgeInsets.fromLTRB(20, 60, 20, 24),
                  decoration: const BoxDecoration(
                    color: Color(0xFF4C6444), // Green header
                  ),
                  child: Column(
                    children: [
                      // Logo and App Name
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.storefront_rounded, color: Colors.white, size: 28),
                          const SizedBox(width: 10),
                          const Text(
                            'MyHanut',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      // Search Bar
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: TextField(
                          onChanged: (val) => setState(() => _searchQuery = val),
                          decoration: const InputDecoration(
                            hintText: 'Rechercher une épicerie...',
                            hintStyle: TextStyle(color: Colors.grey),
                            border: InputBorder.none,
                            icon: Icon(Icons.search, color: Colors.black54),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Filter Chips
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          // Open Now Filter
                          _buildFilterChip(
                            label: 'Ouvert maintenant',
                            isSelected: _onlyOpen,
                            onTap: () => setState(() => _onlyOpen = !_onlyOpen),
                            icon: Icons.circle,
                            iconSize: 8,
                          ),
                          const SizedBox(width: 12),
                          // Rating Filter
                          _buildFilterChip(
                            label: _minRating == 0.0 ? 'Note' : '≥ ${_minRating}',
                            isSelected: _minRating > 0.0,
                            onTap: _showRatingFilter,
                            icon: Icons.star_rounded,
                            hasArrow: true,
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          const Icon(Icons.store, size: 18, color: Color(0xFF7A5C44)),
                          const SizedBox(width: 8),
                          Text(
                            '${filteredStores.length} épiceries trouvées',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF7B5B44),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // List of Stores
              if (filteredStores.isEmpty)
                const SliverFillRemaining(
                  child: Center(child: Text('Aucun épicier trouvé.')),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final store = filteredStores[index];
                        return StoreCard(
                          store: store,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => StoreDetailsScreen(storeId: store.id),
                              ),
                            );
                          },
                        );
                      },
                      childCount: filteredStores.length,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    IconData? icon,
    double iconSize = 16,
    bool hasArrow = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF4C6444) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? Colors.transparent : Colors.grey.shade300,
          ),
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: const Color(0xFF4C6444).withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: iconSize,
                color: isSelected ? Colors.white : (icon == Icons.circle ? const Color(0xFF4C8451) : const Color(0xFFD97E4A)),
              ),
              const SizedBox(width: 8),
            ],
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : const Color(0xFF2D1A0E),
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (hasArrow) ...[
              const SizedBox(width: 4),
              Icon(
                Icons.keyboard_arrow_down,
                size: 18,
                color: isSelected ? Colors.white : Colors.black54,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
