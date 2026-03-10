import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../data/models/store.dart';
import '../../../../providers/category_provider.dart';
import '../../../widgets/custom_bottom_nav_bar.dart';
import '../../../widgets/custom_header.dart';

class StoreCatalogScreen extends StatefulWidget {
  final Store store;

  const StoreCatalogScreen({super.key, required this.store});

  @override
  State<StoreCatalogScreen> createState() => _StoreCatalogScreenState();
}

class _StoreCatalogScreenState extends State<StoreCatalogScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => 
      context.read<CategoryProvider>().fetchCategories(widget.store.id)
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDF6F0), // Cream background from mockup
      body: Column(
        children: [
          CustomHeader(
            hintText: "Rechercher...",
            showBackButton: true,
            onChanged: (val) {
              // Future: Handle product search
            },
          ),
          
          Expanded(
            child: Consumer<CategoryProvider>(
              builder: (context, categoryProvider, child) {
                if (categoryProvider.isLoading) {
                  return const Center(child: CircularProgressIndicator(color: Color(0xFF2D5016)));
                }

                if (categoryProvider.categories.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.category_outlined, size: 64, color: Colors.grey.shade300),
                        const SizedBox(height: 16),
                        Text(
                          "Aucune catégorie disponible",
                          style: TextStyle(color: Colors.grey.shade400, fontSize: 16),
                        ),
                      ],
                    ),
                  );
                }

                return Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Catégories",
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF5D574E), // Slightly muted dark color from mockup
                              ),
                            ),
                            const SizedBox(height: 24),
                            GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 3, // 3 columns as per mockup
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12,
                                childAspectRatio: 0.85, // Adjust for more vertical cards
                              ),
                              itemCount: categoryProvider.categories.length,
                              itemBuilder: (context, index) {
                                final category = categoryProvider.categories[index];
                                // Matching the mockup: first one is green, others are white
                                final bool isHighlighted = index == 0;
                                
                                return _buildMockupCard(category, isHighlighted);
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    // Compact Pagination
                    if (categoryProvider.totalPages > 1)
                      Container(
                        padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildCircleButton(
                              icon: Icons.chevron_left,
                              onTap: () => categoryProvider.previousPage(widget.store.id),
                              isEnabled: categoryProvider.currentPage > 1,
                            ),
                            const SizedBox(width: 24),
                            Text(
                              "PAGE ${categoryProvider.currentPage} / ${categoryProvider.totalPages}",
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 12,
                                color: Color(0xFF5D574E),
                                letterSpacing: 1.0,
                              ),
                            ),
                            const SizedBox(width: 24),
                            _buildCircleButton(
                              icon: Icons.chevron_right,
                              onTap: () => categoryProvider.nextPage(widget.store.id),
                              isEnabled: categoryProvider.currentPage < categoryProvider.totalPages,
                            ),
                          ],
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: 1,
        onTap: (index) {
          if (index == 0) Navigator.popUntil(context, (route) => route.isFirst);
        },
      ),
    );
  }

  Widget _buildMockupCard(dynamic category, bool isHighlighted) {
    return Container(
      decoration: BoxDecoration(
        color: isHighlighted ? const Color(0xFF2D5016) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            // Future: Navigate
          },
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Spacer for where the icon would be
                const SizedBox(height: 20),
                Text(
                  category.nom,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: isHighlighted ? Colors.white : const Color(0xFF5D574E),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  "${category.productCount ?? 0} produits",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 10,
                    color: isHighlighted ? Colors.white.withOpacity(0.8) : Colors.grey.shade500,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCircleButton({required IconData icon, required VoidCallback onTap, required bool isEnabled}) {
    return GestureDetector(
      onTap: isEnabled ? onTap : null,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isEnabled ? const Color(0xFF2D5016).withOpacity(0.05) : Colors.transparent,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: isEnabled ? const Color(0xFF2D5016) : Colors.grey.shade300,
          size: 24,
        ),
      ),
    );
  }
}
