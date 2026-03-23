import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import '../../../providers/store_provider.dart';
import '../../widgets/store_card.dart';
import '../../widgets/custom_header.dart';
import 'store_details_screen.dart';

class StoreListScreen extends StatefulWidget {
  const StoreListScreen({super.key});

  @override
  State<StoreListScreen> createState() => _StoreListScreenState();
}

class _StoreListScreenState extends State<StoreListScreen> {
  String _searchQuery = "";

  @override
  void initState() {
    super.initState();
    Future.microtask(() => _initLocationAndFetch());
  }

  Future<void> _initLocationAndFetch() async {
    final storeProvider = context.read<StoreProvider>();
    // L'écran HomeMapTab (qui est initialisé en même temps) gère déjà 
    // la demande de permission de localisation.
    // On charge les magasins ici seulement si ce n'est pas déjà fait.
    if (storeProvider.stores.isEmpty && !storeProvider.isLoading) {
      storeProvider.fetchStores();
    }
  }

  void _showRatingFilter() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        final storeProvider = context.read<StoreProvider>();
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Note de l\'épicerie',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFF2D1A0E)),
              ),
              const SizedBox(height: 16),
              _buildRatingOption(null, 'Toutes les notes', storeProvider),
              _buildRatingOption(0.0, 'Entre 0 et 1 ★', storeProvider),
              _buildRatingOption(1.0, 'Entre 1 et 2 ★', storeProvider),
              _buildRatingOption(2.0, 'Entre 2 et 3 ★', storeProvider),
              _buildRatingOption(3.0, 'Entre 3 et 4 ★', storeProvider),
              _buildRatingOption(4.0, 'Entre 4 et 5 ★', storeProvider),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  void _showStatusFilter() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        final storeProvider = context.read<StoreProvider>();
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Horaires (aujourd\'hui)',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFF2D1A0E)),
              ),
              const SizedBox(height: 8),
              Text(
                'Selon les créneaux renseignés par l\'épicerie, pas le statut d\'inscription.',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 16),
              _buildStatusOption(null, 'Tous', storeProvider),
              _buildStatusOption(true, 'Ouvert seulement', storeProvider),
              _buildStatusOption(false, 'Fermé seulement', storeProvider),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRatingOption(double? range, String label, StoreProvider provider) {
    bool isSelected = provider.ratingRange == range;
    return InkWell(
      onTap: () {
        provider.updateFilters(ratingRange: range, clearRating: range == null);
        Navigator.pop(context);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Icon(
              range == null ? Icons.all_inclusive : Icons.star_rounded,
              color: isSelected ? const Color(0xFFD97E4A) : Colors.black54,
            ),
            const SizedBox(width: 16),
            Text(label, style: TextStyle(
              fontSize: 16, 
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? const Color(0xFFD97E4A) : Colors.black87,
            )),
            const Spacer(),
            if (isSelected) const Icon(Icons.check, color: Color(0xFFD97E4A)),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusOption(bool? status, String label, StoreProvider provider) {
    bool isSelected = provider.statusFilter == status;
    return InkWell(
      onTap: () {
        provider.updateFilters(status: status, clearStatus: status == null);
        Navigator.pop(context);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Icon(
              status == null ? Icons.dashboard_outlined : (status ? Icons.circle : Icons.circle_outlined),
              size: status == null ? 24 : 12,
              color: isSelected ? const Color(0xFF4C6444) : Colors.black54,
            ),
            const SizedBox(width: 16),
            Text(label, style: TextStyle(
              fontSize: 16, 
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? const Color(0xFF4C6444) : Colors.black87,
            )),
            const Spacer(),
            if (isSelected) const Icon(Icons.check, color: Color(0xFF4C6444)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2EBE3),
      body: Consumer<StoreProvider>(
        builder: (context, storeProvider, child) {
          if (storeProvider.isLoading) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF4C6444)));
          }

          final storesToDisplay = storeProvider.paginatedStores;
          final totalFiltered = storeProvider.filteredStores.length;

          return CustomScrollView(
            slivers: [
              // Search Header
              SliverToBoxAdapter(
                child: CustomHeader(
                  hintText: 'Rechercher une épicerie...',
                  onChanged: (val) {
                    setState(() => _searchQuery = val);
                    storeProvider.updateFilters(search: val);
                  },
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
                          _buildFilterChip(
                            label: storeProvider.statusFilter == null
                                ? 'Horaires'
                                : (storeProvider.statusFilter! ? 'Ouvert' : 'Fermé'),
                            isSelected: storeProvider.statusFilter != null,
                            onTap: _showStatusFilter,
                            icon: Icons.circle,
                            iconSize: 8,
                            hasArrow: true,
                          ),
                          const SizedBox(width: 12),
                          _buildFilterChip(
                            label: storeProvider.ratingRange == null 
                                ? 'Note' 
                                : '[${storeProvider.ratingRange!.toInt()}-${(storeProvider.ratingRange! + 1).toInt()}]',
                            isSelected: storeProvider.ratingRange != null,
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
                            '$totalFiltered épiceries trouvées',
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
              if (storesToDisplay.isEmpty)
                const SliverFillRemaining(
                  child: Center(child: Text('Aucun épicier trouvé.')),
                )
              else 
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final store = storesToDisplay[index];
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
                      childCount: storesToDisplay.length,
                    ),
                  ),
                ),

              // Pagination Controls (Only if list not empty)
              if (storesToDisplay.isNotEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 10, 20, 40),
                    child: Column(
                      children: [
                        Text(
                          "Page ${storeProvider.currentPage} sur ${storeProvider.totalPages}",
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            TextButton(
                              onPressed: storeProvider.currentPage > 1 
                                ? () => storeProvider.previousPage() 
                                : null,
                              child: Text(
                                '‹ Précédent',
                                style: TextStyle(
                                  color: storeProvider.currentPage > 1 ? const Color(0xFF4C6444) : Colors.grey.shade400,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Row(
                              children: List.generate(storeProvider.totalPages, (index) {
                                bool isActive = index + 1 == storeProvider.currentPage;
                                return Container(
                                  margin: const EdgeInsets.symmetric(horizontal: 4),
                                  width: isActive ? 24 : 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: isActive ? const Color(0xFF4C6444) : const Color(0xFFD4C9BD),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                );
                              }),
                            ),
                            TextButton(
                              onPressed: storeProvider.currentPage < storeProvider.totalPages 
                                ? () => storeProvider.nextPage() 
                                : null,
                              child: Text(
                                'Suivant ›',
                                style: TextStyle(
                                  color: storeProvider.currentPage < storeProvider.totalPages ? const Color(0xFF4C6444) : Colors.grey.shade400,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
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
