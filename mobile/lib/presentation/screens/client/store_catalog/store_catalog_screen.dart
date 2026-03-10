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
    final List<Color> palette = [
      const Color(0xFFA75F37), // Copper
      const Color(0xFFCA8E82), // Pink
      const Color(0xFFD9B99F), // Tan
      const Color(0xFF7A958F), // Green
      const Color(0xFFBAE0DA), // Mint
      const Color(0xFF292421), // Black/Dark Brown
    ];

    return Scaffold(
      backgroundColor: Colors.white, // Pure white for a cleaner look
      body: Column(
        children: [
          CustomHeader(
            hintText: "Rechercher dans ce catalogue...",
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
                        Icon(Icons.shopping_bag_outlined, size: 72, color: Colors.grey.shade200),
                        const SizedBox(height: 16),
                        Text(
                          "Aucune catégorie ici",
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
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    "Catégories",
                                    style: TextStyle(
                                      fontSize: 32,
                                      fontWeight: FontWeight.w900,
                                      color: Color(0xFF2D1A0E),
                                      fontFamily: 'serif',
                                      letterSpacing: -1.0,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Container(
                                    height: 4,
                                    width: 40,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF2D5016),
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 32),
                            GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12,
                                childAspectRatio: 1.1,
                              ),
                              itemCount: categoryProvider.categories.length,
                              itemBuilder: (context, index) {
                                final category = categoryProvider.categories[index];
                                final cardColor = palette[index % palette.length];
                                
                                return _buildMinimalCard(category, cardColor);
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    // Compact Pagination
                    if (categoryProvider.totalPages > 1)
                      Container(
                        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.03),
                              blurRadius: 10,
                              offset: const Offset(0, -5),
                            ),
                          ],
                        ),
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
                                fontSize: 13,
                                color: Color(0xFF2D1A0E),
                                letterSpacing: 1.2,
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

  Widget _buildMinimalCard(dynamic category, Color accentColor) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade100, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Accent Top Bar
              Container(
                height: 8,
                decoration: BoxDecoration(
                  color: accentColor,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        category.nom.toUpperCase(),
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                          color: accentColor == const Color(0xFF292421) ? accentColor : accentColor.withOpacity(0.9),
                          letterSpacing: 0.5,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              "${category.productCount ?? 0} ITEMS",
                              style: const TextStyle(
                                fontSize: 10,
                                color: Colors.grey,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const Spacer(),
                          Icon(Icons.arrow_forward, size: 16, color: accentColor.withOpacity(0.3)),
                        ],
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
