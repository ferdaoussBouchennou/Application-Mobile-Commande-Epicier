import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../data/models/reclamation.dart';
import '../../../../data/services/api_service.dart';
import '../../../../providers/auth_provider.dart';

class ClientReclamationsScreen extends StatefulWidget {
  const ClientReclamationsScreen({super.key});

  @override
  State<ClientReclamationsScreen> createState() => _ClientReclamationsScreenState();
}

class _ClientReclamationsScreenState extends State<ClientReclamationsScreen> {
  final _api = ApiService();
  bool _isLoading = true;
  List<Reclamation> _reclamations = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final auth = context.read<AuthProvider>();
      final res = await _api.get('/reclamations/mine', token: auth.token);
      if (!mounted) return;
      
      final List<Reclamation> list = [];
      if (res is List) {
        for (final r in res) {
          list.add(Reclamation.fromJson(r));
        }
      }
      
      setState(() {
        _reclamations = list;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Résolue': return Colors.green.shade700;
      case 'En cours': return Colors.blue.shade700;
      case 'Ouverte': return Colors.orange.shade700;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF2D5016);
    return Scaffold(
      backgroundColor: const Color(0xFFFDF6F0),
      appBar: AppBar(
        title: const Text('Mes Réclamations', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: primary,
        foregroundColor: Colors.white,
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        color: primary,
        child: _isLoading 
            ? const Center(child: CircularProgressIndicator(color: primary))
            : _error != null 
                ? Center(child: Text(_error!))
                : _reclamations.isEmpty 
                    ? const Center(child: Text('Aucune réclamation trouvée'))
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _reclamations.length,
                        itemBuilder: (context, index) {
                          final rec = _reclamations[index];
                          final dateStr = DateFormat('dd/MM/yyyy HH:mm').format(rec.dateCreation);
                          return Card(
                            margin: const EdgeInsets.only(bottom: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            elevation: 0,
                            borderOnForeground: false,
                            child: ExpansionTile(
                              tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                              expandedCrossAxisAlignment: CrossAxisAlignment.start,
                              backgroundColor: Colors.white,
                              collapsedBackgroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              collapsedShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              title: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    rec.motif,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: _getStatusColor(rec.statut).withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      rec.statut,
                                      style: TextStyle(
                                        color: _getStatusColor(rec.statut),
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 4.0),
                                child: Text(
                                  '#CMD-${rec.commandeId} · Créée le $dateStr',
                                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                                ),
                              ),
                              children: [
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Divider(),
                                      const SizedBox(height: 10),
                                      const Text(
                                        'Description:',
                                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(rec.description, style: const TextStyle(fontSize: 14)),
                                      
                                      if (rec.reponseEpicier != null && rec.reponseEpicier!.isNotEmpty) ...[
                                        const SizedBox(height: 20),
                                        Container(
                                          width: double.infinity,
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: Colors.blue.shade50,
                                            borderRadius: BorderRadius.circular(12),
                                            border: Border.all(color: Colors.blue.shade100),
                                          ),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              const Row(
                                                children: [
                                                  Icon(Icons.reply, size: 16, color: Colors.blue),
                                                  SizedBox(width: 8),
                                                  Text(
                                                    'Réponse de l\'épicier :',
                                                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue, fontSize: 14),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 8),
                                              Text(rec.reponseEpicier!, style: const TextStyle(fontSize: 14)),
                                            ],
                                          ),
                                        ),
                                      ],
                                      const Divider(),
                                      if (rec.photo != null) ...[
                                        const SizedBox(height: 16),
                                        const Text('Pièce jointe:', style: TextStyle(fontWeight: FontWeight.bold)),
                                        const SizedBox(height: 8),
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(12),
                                          child: GestureDetector(
                                            onTap: () {
                                              // Show full screen image
                                              showDialog(
                                                context: context,
                                                builder: (_) => Dialog(
                                                  child: Image.network(ApiConstants.formatImageUrl(rec.photo)),
                                                ),
                                              );
                                            },
                                            child: Image.network(
                                              ApiConstants.formatImageUrl(rec.photo),
                                              height: 120,
                                              width: 120,
                                              fit: BoxFit.cover,
                                              errorBuilder: (ctx, err, stack) => Container(
                                                height: 120,
                                                width: 120,
                                                color: Colors.grey.shade200,
                                                child: const Icon(Icons.broken_image_outlined, color: Colors.grey),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
      ),
    );
  }
}
