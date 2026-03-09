import 'package:flutter/material.dart';
import '../../data/models/store.dart';

class StoreCard extends StatelessWidget {
  final Store store;
  final VoidCallback onTap;

  const StoreCard({
    super.key,
    required this.store,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Section with Badges
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  child: Image.network(
                    store.imageUrl ?? 'https://via.placeholder.com/500x200',
                    height: 180,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      height: 180,
                      color: const Color(0xFFE5DED4),
                      child: const Icon(Icons.storefront, size: 50, color: Color(0xFF7A5C44)),
                    ),
                  ),
                ),
                // Status Badge (Ouvert)
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4C8451), // Green from mockup
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Text(
                          'Ouvert',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Distance Badge
                Positioned(
                  bottom: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF5D4837), // Brownish from mockup
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.location_on, color: Color(0xFFFF6D61), size: 14),
                        const SizedBox(width: 4),
                        Text(
                          store.distance ?? "350 m",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title and Rating line
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          store.nomBoutique,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF2D1A0E),
                            fontFamily: 'Georgia',
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          ...List.generate(5, (index) => Icon(
                            Icons.star,
                            size: 16,
                            color: index < store.rating.floor() 
                                ? const Color(0xFFD97E4A) 
                                : const Color(0xFFE5DED4),
                          )),
                          const SizedBox(width: 4),
                          Text(
                            store.rating.toString(),
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 14,
                              color: Color(0xFF2D1A0E),
                            ),
                          ),
                          Text(
                            " (203)", // Dummy count for mockup
                            style: TextStyle(
                              color: Colors.grey.shade400,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  
                  // Address line
                  Row(
                    children: [
                      const Icon(Icons.location_pin, color: Color(0xFF7A5C44), size: 16),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          store.adresse,
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  
                  // Tags
                  Row(
                    children: store.tags.map((tag) => Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFE5DED4), width: 1.5),
                      ),
                      child: Text(
                        tag,
                        style: const TextStyle(
                          color: Color(0xFF7A5C44),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    )).toList(),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Action Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: onTap,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4C6444), // Main green from mockup
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text(
                        'Voir le catalogue',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
