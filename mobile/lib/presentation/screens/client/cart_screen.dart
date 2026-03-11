import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../data/models/cart_item.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../providers/cart_provider.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  static const Color _headerBrown = Color(0xFF2D5016);
  static const Color _bgBeige = Color(0xFFFDF6F0);
  static const Color _greenBtn = Color(0xFF2D5016);
  static const Color _priceBrown = Color(0xFF5D4E37);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final token = context.read<AuthProvider>().token;
      context.read<CartProvider>().fetchCart(token);
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final cart = context.watch<CartProvider>();
    final token = auth.token;

    return Scaffold(
      backgroundColor: _bgBeige,
      appBar: AppBar(
        backgroundColor: _headerBrown,
        foregroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.shopping_cart, size: 22),
                const SizedBox(width: 8),
                const Text('Panier', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              ],
            ),
            Text(
              '${cart.itemCount} article${cart.itemCount != 1 ? 's' : ''}',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.normal),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: _body(cart, token),
    );
  }

  Widget _body(CartProvider cart, String? token) {
    if (cart.loading && cart.items.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (token == null || token.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Text(
            'Connectez-vous pour voir votre panier.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: Colors.grey.shade700),
          ),
        ),
      );
    }
    if (cart.items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Text(
            'Votre panier est vide.',
            style: TextStyle(fontSize: 16, color: Colors.grey.shade700),
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ...cart.items.map((item) => _CartItemCard(
                item: item,
                token: token,
                onRefresh: () => cart.fetchCart(token),
              )),
          const SizedBox(height: 16),
          _SummaryCard(total: cart.total),
          const SizedBox(height: 24),
          SizedBox(
            height: 52,
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: _greenBtn,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Continuer la commande ', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  Icon(Icons.arrow_forward, size: 20),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _CartItemCard extends StatelessWidget {
  final CartItem item;
  final String? token;
  final VoidCallback onRefresh;

  const _CartItemCard({required this.item, required this.token, required this.onRefresh});

  static const Color _greenBtn = Color(0xFF2D5016);
  static const Color _priceBrown = Color(0xFF5D4E37);

  @override
  Widget build(BuildContext context) {
    final cart = context.read<CartProvider>();
    final imageUrl = ApiConstants.formatImageUrl(item.imagePrincipale);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 1,
      shadowColor: Colors.black12,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.network(
                imageUrl,
                width: 64,
                height: 64,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: 64,
                  height: 64,
                  color: Colors.grey.shade200,
                  child: const Icon(Icons.image_not_supported, color: Colors.grey),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.nom,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: Color(0xFF2C2C2C),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_formatPrice(item.prix)} MAD',
                    style: const TextStyle(color: _priceBrown, fontWeight: FontWeight.w500, fontSize: 14),
                  ),
                ],
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _QtyButton(
                  icon: Icons.remove,
                  onTap: () {
                    if (item.quantite > 1) {
                      cart.updateQuantity(token, item.produitId, item.quantite - 1);
                    }
                  },
                ),
                Container(
                  width: 40,
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Text('${item.quantite}', style: const TextStyle(fontWeight: FontWeight.w600)),
                ),
                _QtyButton(
                  icon: Icons.add,
                  onTap: () => cart.updateQuantity(token, item.produitId, item.quantite + 1),
                ),
              ],
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: Icon(Icons.delete_outline, color: _priceBrown, size: 22),
              onPressed: () => cart.removeItem(token, item.produitId),
            ),
          ],
        ),
      ),
    );
  }

  static String _formatPrice(double v) {
    final s = v.toStringAsFixed(2).replaceAll('.', ',');
    return s;
  }
}

class _QtyButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _QtyButton({required this.icon, required this.onTap});

  static const Color _greenBtn = Color(0xFF2D5016);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _greenBtn,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final double total;

  const _SummaryCard({required this.total});

  static String _formatPrice(double v) {
    return v.toStringAsFixed(2).replaceAll('.', ',');
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 1,
      shadowColor: Colors.black12,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Total', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF2C2C2C))),
            Text('${_formatPrice(total)} MAD', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF2C2C2C))),
          ],
        ),
      ),
    );
  }
}
