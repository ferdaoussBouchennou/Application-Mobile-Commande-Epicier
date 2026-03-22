import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../data/models/cart_item.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../providers/cart_provider.dart';
import 'package:intl/intl.dart';

class CartScreen extends StatefulWidget {
  final VoidCallback? onOrderConfirmed;

  const CartScreen({super.key, this.onOrderConfirmed});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  static const Color _headerBrown = Color(0xFF2D5016);
  static const Color _bgBeige = Color(0xFFFDF6F0);
  static const Color _greenBtn = Color(0xFF2D5016);
  static const Color _priceBrown = Color(0xFF5D4E37);

  void _openConfirmOrderSheet(BuildContext context, CartProvider cart, String token) {
    int? firstEpicierId;
    for (final i in cart.items) {
      if (i.epicierId != null) { firstEpicierId = i.epicierId; break; }
    }
    if (firstEpicierId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Impossible de déterminer l\'épicerie.')));
      return;
    }
    final epicierId = firstEpicierId;
    final itemsForStore = cart.items.where((e) => e.epicierId == epicierId).toList();
    final totalForStore = itemsForStore.fold<double>(0, (s, i) => s + i.lineTotal);
    final articleCount = itemsForStore.fold<int>(0, (s, i) => s + i.quantite);

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _ConfirmOrderSheet(
        epicierId: epicierId,
        articleCount: articleCount,
        totalForStore: totalForStore,
        token: token,
        onSuccess: () {
          Navigator.of(ctx).pop();
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Commande confirmée.')));
          cart.fetchCart(token);
          widget.onOrderConfirmed?.call();
        },
        onError: (msg) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg))),
      ),
    );
  }

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
              onPressed: () => _openConfirmOrderSheet(context, cart, token!),
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

// ——— Confirm order bottom sheet (recap + time slots, no note) ———



class _ConfirmOrderSheet extends StatefulWidget {
  final int epicierId;
  final int articleCount;
  final double totalForStore;
  final String token;
  final VoidCallback onSuccess;
  final void Function(String message) onError;

  const _ConfirmOrderSheet({
    required this.epicierId,
    required this.articleCount,
    required this.totalForStore,
    required this.token,
    required this.onSuccess,
    required this.onError,
  });

  @override
  State<_ConfirmOrderSheet> createState() => _ConfirmOrderSheetState();
}

class _ConfirmOrderSheetState extends State<_ConfirmOrderSheet> {
  static const Color _bgBeige = Color(0xFFFDF6F0);
  static const Color _cardGray = Color(0xFFF0EDE8);
  static const Color _tealSelected = Color(0xFF1A7F6E);
  static const Color _confirmBtn = Color(0xFFB85C38);
  static const Color _primary = Color(0xFF2D5016);

  List<Map<String, String>> _creneaux = [];
  String _storeName = '';
  bool _loading = true;
  int _selectedIndex = 0;
  bool _confirming = false;
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    final cart = context.read<CartProvider>();
    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
    final res = await cart.fetchCreneaux(widget.token, widget.epicierId, date: dateStr);
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (res != null) {
        _storeName = res['nom_boutique']?.toString() ?? 'Épicerie';
        final list = res['creneaux'] as List?;
        _creneaux = list?.map((e) => Map<String, String>.from(Map.from(e as Map))).toList() ?? [];
        if (_creneaux.isNotEmpty) {
          _selectedIndex = 0;
        } else {
          _selectedIndex = -1;
        }
      }
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 14)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: _primary,
              onPrimary: Colors.white,
              onSurface: Color(0xFF2C2C2C),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
      _loadData();
    }
  }

  Future<void> _confirm() async {
    if (_creneaux.isEmpty || _selectedIndex < 0 || _selectedIndex >= _creneaux.length) {
      widget.onError('Veuillez choisir un créneau horaire.');
      return;
    }
    setState(() => _confirming = true);
    try {
      await context.read<CartProvider>().confirmOrder(
            widget.token,
            widget.epicierId,
            _creneaux[_selectedIndex]['value']!,
          );
      if (mounted) widget.onSuccess();
    } catch (e) {
      if (mounted) widget.onError(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _confirming = false);
    }
  }

  static String _formatPrice(double v) => v.toStringAsFixed(2).replaceAll('.', ',');

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: _bgBeige,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.fromLTRB(20, 16, 20, 16 + MediaQuery.of(context).padding.bottom),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            // HEADER RÉCAP
            Card(
              color: _cardGray,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.store, size: 18, color: _primary),
                        const SizedBox(width: 8),
                        Expanded(child: Text(_storeName, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF2C2C2C)))),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('${widget.articleCount} article${widget.articleCount > 1 ? 's' : ''}', style: TextStyle(fontSize: 14, color: Colors.grey.shade700)),
                        Text('${_formatPrice(widget.totalForStore)} MAD', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF2C2C2C))),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // DATE PICKER
            const Text('CHOIX DU JOUR', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF7A5C44), letterSpacing: 0.5)),
            const SizedBox(height: 8),
            InkWell(
              onTap: _pickDate,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_month, color: _primary, size: 22),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        DateFormat('EEEE d MMMM yyyy', 'fr_FR').format(_selectedDate),
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF2D1A0E)),
                      ),
                    ),
                    const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            // CRENEAUX
            const Text('CRÉNEAU HORAIRE', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF7A5C44), letterSpacing: 0.5)),
            const SizedBox(height: 8),
            if (_loading)
              const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator(color: _primary)))
            else if (_creneaux.isEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(12)),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.orange.shade800, size: 20),
                    const SizedBox(width: 12),
                    const Expanded(child: Text('Aucun créneau disponible pour ce jour.', style: TextStyle(color: Color(0xFF7A5C44), fontSize: 13))),
                  ],
                ),
              )
            else
              ConstrainedBox(
                constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.3),
                child: ListView.builder(
                  shrinkWrap: true,
                  padding: EdgeInsets.zero,
                  itemCount: _creneaux.length,
                  itemBuilder: (ctx, i) {
                    final selected = i == _selectedIndex;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: InkWell(
                        onTap: () => setState(() => _selectedIndex = i),
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                          decoration: BoxDecoration(
                            color: selected ? _tealSelected : Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: selected ? _tealSelected : Colors.grey.shade200),
                          ),
                          child: Row(
                            children: [
                              Icon(selected ? Icons.check_circle : Icons.circle_outlined, size: 20, color: selected ? Colors.white : Colors.grey.shade400),
                              const SizedBox(width: 12),
                              Text(_creneaux[i]['label'] ?? '', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: selected ? Colors.white : const Color(0xFF2C2C2C))),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            const SizedBox(height: 24),
            SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: (_confirming || _selectedIndex < 0) ? null : _confirm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _confirmBtn,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: _confirming
                    ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Confirmer la commande', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
