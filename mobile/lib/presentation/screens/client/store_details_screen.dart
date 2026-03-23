import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/store_provider.dart';
import '../../../core/constants/api_constants.dart';
import '../../../data/services/api_service.dart';
import '../../widgets/rate_store_sheet.dart';
import './store_catalog/store_catalog_screen.dart';

class StoreAvisItem {
  final int id;
  final int note;
  final String commentaire;
  final String clientNom;
  final String? dateAvis;

  StoreAvisItem({
    required this.id,
    required this.note,
    required this.commentaire,
    required this.clientNom,
    this.dateAvis,
  });

  static StoreAvisItem fromJson(Map<String, dynamic> json) {
    return StoreAvisItem(
      id: json['id'] as int? ?? 0,
      note: (json['note'] is int) ? json['note'] as int : int.tryParse(json['note']?.toString() ?? '0') ?? 0,
      commentaire: json['commentaire']?.toString() ?? '',
      clientNom: json['client_nom']?.toString() ?? 'Client',
      dateAvis: json['date_avis']?.toString(),
    );
  }
}

class StoreDetailsScreen extends StatefulWidget {
  final int storeId;

  const StoreDetailsScreen({super.key, required this.storeId});

  @override
  State<StoreDetailsScreen> createState() => _StoreDetailsScreenState();
}

class _StoreDetailsScreenState extends State<StoreDetailsScreen> {
  final ApiService _api = ApiService();
  double? _avisNoteMoyenne;
  List<StoreAvisItem> _avisList = [];
  bool _avisLoading = true;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      context.read<StoreProvider>().fetchStoreDetails(widget.storeId);
      _loadAvis();
    });
  }

  Future<void> _loadAvis() async {
    setState(() => _avisLoading = true);
    try {
      final res = await _api.get('/stores/${widget.storeId}/avis');
      if (!mounted) return;
      final data = res is Map ? res as Map<String, dynamic> : <String, dynamic>{};
      final note = data['note_moyenne'];
      _avisNoteMoyenne = note != null ? double.tryParse(note.toString()) : null;
      final list = data['avis'];
      if (list is List) {
        _avisList = list
            .where((e) => e is Map)
            .map((e) => StoreAvisItem.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();
      } else {
        _avisList = [];
      }
    } catch (_) {
      if (mounted) {
        _avisList = [];
        _avisNoteMoyenne = null;
      }
    }
    if (mounted) setState(() => _avisLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDF6F0),
      body: Consumer<StoreProvider>(
        builder: (context, storeProvider, child) {
          final store = storeProvider.selectedStore;

          if (storeProvider.isLoading || store == null) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF2D5016)));
          }

          return CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 250,
                pinned: true,
                leading: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: CircleAvatar(
                    backgroundColor: Colors.black.withOpacity(0.3),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      store.imageUrl != null && store.imageUrl!.trim().isNotEmpty
                          ? Image.network(
                              ApiConstants.formatImageUrl(store.imageUrl),
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => Container(
                                color: Colors.grey.shade300,
                                child: const Icon(Icons.store, size: 50, color: Colors.grey),
                              ),
                            )
                          : Container(
                              color: Colors.grey.shade300,
                              child: const Center(
                                child: Icon(Icons.store, size: 64, color: Colors.grey),
                              ),
                            ),
                      const DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Colors.transparent, Colors.black54],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                backgroundColor: const Color(0xFF2D5016),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                store.nomBoutique,
                                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF2D1A0E)),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "Par ${store.ownerName ?? 'Propriétaire'}",
                                style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5)],
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.star, color: Colors.amber, size: 20),
                                const SizedBox(width: 4),
                                Text(
                                  store.rating.toString(),
                                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      _buildInfoSection(Icons.location_on, "Adresse", store.adresse),
                      const SizedBox(height: 16),
                      if (store.telephone != null)
                        _buildInfoSection(Icons.phone, "Téléphone", store.telephone!),
                      const SizedBox(height: 24),
                      const Text(
                        "À propos",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2D1A0E)),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        store.description ?? "Aucune description fournie.",
                        style: TextStyle(color: Colors.grey.shade700, fontSize: 15, height: 1.5),
                      ),
                      const SizedBox(height: 32),
                      const Text(
                        "Horaires d'ouverture",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2D1A0E)),
                      ),
                      const SizedBox(height: 12),
                      if (store.disponibilites != null)
                        ...store.disponibilites!.map((d) => _buildScheduleRow(d.jour, d.heureDebut, d.heureFin))
                      else
                        const Text("Horaires non disponibles."),
                      const SizedBox(height: 32),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "Avis des clients",
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2D1A0E)),
                          ),
                          TextButton.icon(
                            onPressed: () {
                              showModalBottomSheet(
                                context: context,
                                isScrollControlled: true,
                                backgroundColor: Colors.transparent,
                                builder: (context) => RateStoreSheet(
                                  epicierId: store.id,
                                  nomBoutique: store.nomBoutique.isNotEmpty ? store.nomBoutique : 'Épicerie',
                                  onSubmitted: () {
                                    _loadAvis();
                                    context.read<StoreProvider>().fetchStoreDetails(widget.storeId);
                                  },
                                ),
                              );
                            },
                            icon: const Icon(Icons.rate_review_outlined, size: 18),
                            label: const Text('Laisser un avis'),
                            style: TextButton.styleFrom(
                              foregroundColor: const Color(0xFF2D5016),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (_avisLoading)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Center(child: SizedBox(
                            height: 28,
                            width: 28,
                            child: CircularProgressIndicator(color: Color(0xFF2D5016), strokeWidth: 2),
                          )),
                        )
                      else ...[
                        if (_avisList.isEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            child: Text(
                              "Aucun avis pour le moment.",
                              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                            ),
                          )
                        else ...[
                          Row(
                            children: [
                              const Icon(Icons.star_rounded, color: Color(0xFFE8B923), size: 22),
                              const SizedBox(width: 6),
                              Text(
                                (_avisNoteMoyenne ?? store.rating).toStringAsFixed(1),
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2D1A0E)),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                "(${_avisList.length} avis)",
                                style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          ..._avisList.map((a) => _buildAvisCard(a)),
                        ],
                      ],
                      const SizedBox(height: 40),
                      SizedBox(
                        width: double.infinity,
                        height: 55,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => StoreCatalogScreen(store: store),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2D5016),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          child: const Text("Voir les produits", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        ),
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

  Widget _buildInfoSection(IconData icon, String title, String value) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: const Color(0xFF2D5016).withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: const Color(0xFF2D5016), size: 20),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
            Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          ],
        ),
      ],
    );
  }

  Widget _buildScheduleRow(String jour, String debut, String fin) {
    // Format "08:00:00" to "08:00"
    String formatTime(String time) => time.split(':').take(2).join(':');

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            jour[0].toUpperCase() + jour.substring(1),
            style: const TextStyle(fontSize: 14),
          ),
          Text(
            "${formatTime(debut)} - ${formatTime(fin)}",
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildAvisCard(StoreAvisItem a) {
    String dateStr = '';
    if (a.dateAvis != null && a.dateAvis!.isNotEmpty) {
      try {
        final d = DateTime.parse(a.dateAvis!);
        dateStr = '${d.day}/${d.month}/${d.year}';
      } catch (_) {}
    }
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: const Color(0xFF2D5016).withOpacity(0.15),
                child: Text(
                  (a.clientNom.isNotEmpty ? a.clientNom[0] : '?').toUpperCase(),
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2D5016), fontSize: 16),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      a.clientNom.isNotEmpty ? a.clientNom : 'Client',
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: Color(0xFF2D1A0E)),
                    ),
                    if (dateStr.isNotEmpty)
                      Text(dateStr, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(5, (i) => Icon(
                  i < a.note ? Icons.star_rounded : Icons.star_outline_rounded,
                  size: 18,
                  color: const Color(0xFFE8B923),
                )),
              ),
            ],
          ),
          if (a.commentaire.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              a.commentaire,
              style: TextStyle(fontSize: 14, height: 1.4, color: Colors.grey.shade800),
            ),
          ],
        ],
      ),
    );
  }
}
