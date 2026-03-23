import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../data/services/api_service.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../providers/auth_provider.dart';
import '../grocer_theme.dart';
import 'grocer_profile_screen.dart';
import 'grocer_avis_details_screen.dart';
import 'widgets/avis_signal_sheet.dart';

class GrocerProfileViewScreen extends StatefulWidget {
  const GrocerProfileViewScreen({super.key, this.scrollToAvisTrigger});

  /// Incrémenter depuis l’écran parent pour faire défiler jusqu’à « Avis des clients ».
  final ValueNotifier<int>? scrollToAvisTrigger;

  @override
  State<GrocerProfileViewScreen> createState() =>
      _GrocerProfileViewScreenState();
}

class _GrocerProfileViewScreenState extends State<GrocerProfileViewScreen> {
  final ApiService _api = ApiService();
  final GlobalKey _avisSectionKey = GlobalKey();

  bool _loading = true;
  String? _error;
  Map<String, dynamic>? _store;

  // Avis (pagination simple)
  bool _avisLoading = true;
  String? _avisError;
  List<Map<String, dynamic>> _avisList = [];
  int _avisPage = 1;
  final int _avisLimit = 5;
  int _avisTotalPages = 1;

  @override
  void initState() {
    super.initState();
    widget.scrollToAvisTrigger?.addListener(_onScrollToAvisTrigger);
    _load();
  }

  @override
  void dispose() {
    widget.scrollToAvisTrigger?.removeListener(_onScrollToAvisTrigger);
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant GrocerProfileViewScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.scrollToAvisTrigger != widget.scrollToAvisTrigger) {
      oldWidget.scrollToAvisTrigger?.removeListener(_onScrollToAvisTrigger);
      widget.scrollToAvisTrigger?.addListener(_onScrollToAvisTrigger);
    }
  }

  void _onScrollToAvisTrigger() => _scrollToAvisSection();

  void _scrollToAvisSection([int attempt = 0]) {
    if (attempt > 8) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final ctx = _avisSectionKey.currentContext;
      if (ctx != null) {
        Scrollable.ensureVisible(
          ctx,
          duration: const Duration(milliseconds: 450),
          curve: Curves.easeInOut,
          alignment: 0.12,
        );
      } else {
        Future<void>.delayed(
          const Duration(milliseconds: 200),
          () => _scrollToAvisSection(attempt + 1),
        );
      }
    });
  }

  Future<void> _load() async {
    final token = context.read<AuthProvider>().token;
    if (token == null) {
      setState(() {
        _loading = false;
        _error = 'Non connecté';
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final res = await _api.get('/epicier/profile', token: token);
      if (!mounted) return;

      // Selon Sequelize, la réponse est souvent déjà un Map
      final map = res is Map<String, dynamic>
          ? res
          : (res as Map?)?.cast<String, dynamic>() ?? <String, dynamic>{};

      setState(() {
        _store = map;
        _loading = false;
      });

      await _loadAvis(reset: true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _loadAvis({bool reset = false}) async {
    final token = context.read<AuthProvider>().token;
    if (token == null) return;
    if (!mounted) return;

    if (reset) _avisPage = 1;

    setState(() {
      _avisLoading = true;
      _avisError = null;
    });

    try {
      final res = await _api.get(
        '/epicier/avis?page=$_avisPage&limit=$_avisLimit',
        token: token,
      );

      if (!mounted) return;

      final map = res is Map<String, dynamic> ? res : <String, dynamic>{};
      final list = map['avis'] as List? ?? [];
      final pagination = map['pagination'] as Map<String, dynamic>? ?? {};

      setState(() {
        _avisList = list
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
        _avisTotalPages = (pagination['totalPages'] as num?)?.toInt() ?? 1;
        _avisLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _avisError = e.toString();
        _avisLoading = false;
      });
    }
  }

  Future<void> _signalAvis(int avisId) async {
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => AvisSignalSheet(avisId: avisId),
    );

    if (ok == true) {
      _loadAvis(reset: false);
    }
  }

  Widget _buildStars(int note) {
    return Row(
      children: List.generate(
        5,
        (i) => Icon(
          i < note ? Icons.star_rounded : Icons.star_outline_rounded,
          color: const Color(0xFFE8B923),
          size: 16,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = _store;

    return Scaffold(
      backgroundColor: GrocerTheme.background,
      body: SafeArea(
        top: false,
        child: _loading
          ? const Center(
              child: CircularProgressIndicator(color: GrocerTheme.primary),
            )
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error_outline,
                            size: 48, color: Colors.grey),
                        const SizedBox(height: 16),
                        Text(
                          _error!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.black87),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _load,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: GrocerTheme.primary,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Réessayer'),
                        ),
                      ],
                    ),
                  ),
                )
              : store == null
                  ? const SizedBox.shrink()
                  : RefreshIndicator(
                      onRefresh: _load,
                      color: GrocerTheme.primary,
                      child: ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          if (store['image_url'] != null &&
                              store['image_url'].toString().isNotEmpty)
                            ClipRRect(
                              borderRadius: BorderRadius.circular(18),
                              child: Image.network(
                                ApiConstants.formatImageUrl(
                                  store['image_url'].toString(),
                                ),
                                height: 180,
                                width: double.infinity,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  height: 180,
                                  color: GrocerTheme.border.withOpacity(0.15),
                                  child: const Icon(Icons.store, size: 64),
                                ),
                              ),
                            )
                          else
                            Container(
                              height: 180,
                              decoration: BoxDecoration(
                                color: GrocerTheme.border.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(18),
                              ),
                              child: const Icon(Icons.store, size: 64),
                            ),
                          const SizedBox(height: 16),
                          _SectionTitle(title: 'Infos'),
                          const SizedBox(height: 8),
                          _InfoRow(
                            icon: Icons.storefront_rounded,
                            label: 'Nom',
                            value: (store['nom_boutique'] ?? '').toString(),
                          ),
                          _InfoRow(
                            icon: Icons.phone_rounded,
                            label: 'Téléphone',
                            value: (store['telephone'] ?? '-').toString(),
                          ),
                          _InfoRow(
                            icon: Icons.description_rounded,
                            label: 'Description',
                            value: (store['description'] ?? '-').toString(),
                            multiline: true,
                          ),
                          const SizedBox(height: 16),
                          _SectionTitle(title: 'Localisation'),
                          const SizedBox(height: 8),
                          _InfoRow(
                            icon: Icons.location_on_rounded,
                            label: 'Adresse',
                            value: (store['adresse'] ?? '-').toString(),
                            multiline: true,
                          ),
                          _InfoRow(
                            icon: Icons.gps_fixed_rounded,
                            label: 'GPS',
                            value: _formatGps(store),
                          ),
                          const SizedBox(height: 16),
                          _SectionTitle(title: 'Horaires'),
                          const SizedBox(height: 8),
                          _AvailabilityList(store: store),
                          const SizedBox(height: 24),

                          Column(
                            key: _avisSectionKey,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _SectionTitle(title: 'Avis des clients'),
                              const SizedBox(height: 8),
                              if (_avisLoading)
                                const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 12),
                                  child: Center(
                                    child: SizedBox(
                                      height: 22,
                                      width: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: GrocerTheme.primary,
                                      ),
                                    ),
                                  ),
                                )
                              else if (_avisError != null)
                                Text(
                                  _avisError!,
                                  style: TextStyle(color: Colors.red.shade700),
                                )
                              else if (_avisList.isEmpty)
                                Text(
                                  'Aucun avis pour le moment.',
                                  style: TextStyle(color: Colors.grey.shade700),
                                )
                              else ...[
                                ..._avisList.map((a) {
                                  final avisId = (a['id'] as num?)?.toInt() ?? 0;
                                  final note = (a['note'] as num?)?.toInt() ?? 0;
                                  final clientNom =
                                      a['client_nom']?.toString() ?? 'Client';
                                  final commentaire =
                                      a['commentaire']?.toString() ?? '';

                                  return Card(
                                elevation: 0,
                                margin: const EdgeInsets.only(bottom: 10),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  side: BorderSide(color: GrocerTheme.border),
                                ),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(14),
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => GrocerAvisDetailsScreen(
                                          avisId: avisId,
                                        ),
                                      ),
                                    );
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.all(14),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            CircleAvatar(
                                              radius: 18,
                                              backgroundColor: GrocerTheme.primarySoft,
                                              child: Text(
                                                (clientNom.isNotEmpty
                                                        ? clientNom[0]
                                                        : '?')
                                                    .toUpperCase(),
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 10),
                                            Expanded(
                                              child: Text(
                                                clientNom,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 10),
                                        _buildStars(note),
                                        const SizedBox(height: 8),
                                        if (commentaire.isNotEmpty)
                                          Text(
                                            commentaire,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              color: Colors.grey.shade800,
                                            ),
                                          )
                                        else
                                          const Text(
                                            '(commentaire vide)',
                                            style: TextStyle(
                                              color: Colors.grey,
                                            ),
                                          ),
                                        const SizedBox(height: 10),
                                        Row(
                                          children: [
                                            TextButton.icon(
                                              onPressed: () => _signalAvis(
                                                  avisId),
                                              icon: const Icon(
                                                Icons.flag_rounded,
                                                size: 18,
                                              ),
                                              label: const Text(
                                                'Signaler',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            }),

                            if (_avisTotalPages > 1) ...[
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton(
                                      onPressed: _avisPage > 1
                                          ? () {
                                              setState(() => _avisPage--);
                                              _loadAvis(reset: false);
                                            }
                                          : null,
                                      child: const Text('Précédent'),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: OutlinedButton(
                                      onPressed: _avisPage < _avisTotalPages
                                          ? () {
                                              setState(() => _avisPage++);
                                              _loadAvis(reset: false);
                                            }
                                          : null,
                                      child: Text('Page $_avisPage'),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                            ],
                          ),

                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: ElevatedButton.icon(
                              onPressed: () async {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const GrocerProfileScreen(),
                                  ),
                                );
                                if (!mounted) return;
                                _load();
                              },
                              icon: const Icon(Icons.edit_rounded),
                              label: const Text('Modifier le profil'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: GrocerTheme.primary,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                        ],
                      ),
                    ),
      ),
    );
  }

  String _formatGps(Map<String, dynamic> store) {
    final lat = store['latitude'];
    final lng = store['longitude'];
    if (lat == null || lng == null) return 'Non défini';
    return '${lat.toString()}, ${lng.toString()}';
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w800,
        color: GrocerTheme.textDark,
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool multiline;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.multiline = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment:
            multiline ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: GrocerTheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 18, color: GrocerTheme.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$label :',
                  style: TextStyle(
                    fontSize: 12,
                    color: GrocerTheme.textMuted,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    color: GrocerTheme.textDark,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: multiline ? 4 : 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AvailabilityList extends StatelessWidget {
  final Map<String, dynamic> store;
  const _AvailabilityList({required this.store});

  @override
  Widget build(BuildContext context) {
    final list = store['disponibilites'];
    if (list == null || list is! List || list.isEmpty) {
      return Text(
        'Aucune disponibilité',
        style: TextStyle(color: GrocerTheme.textMuted),
      );
    }

    // format simple: lundi 09:00-14:00
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: list.map((d) {
        final dyn = d as dynamic;
        final jour = (dyn['jour'] ?? dyn.jour ?? '').toString();
        final hDebut = (dyn['heure_debut'] ?? dyn.heure_debut ?? '').toString();
        final hFin = (dyn['heure_fin'] ?? dyn.heure_fin ?? '').toString();
        final labelJour =
            jour.isNotEmpty ? '${jour[0].toUpperCase()}${jour.substring(1)}' : '-';
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              Icon(Icons.access_time_rounded,
                  size: 16, color: GrocerTheme.primary),
              const SizedBox(width: 10),
              Text(
                '$labelJour : $hDebut - $hFin',
                style: TextStyle(
                  fontSize: 14,
                  color: GrocerTheme.textDark,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

