import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/api_constants.dart';
import '../../../data/models/user_model.dart';
import 'package:url_launcher/url_launcher.dart';

class AdminEpicierProfileScreen extends StatelessWidget {
  final UserModel user;

  const AdminEpicierProfileScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final String storeName = user.store?['nom_boutique'] ?? user.fullName;
    final String? imageUrl = user.store?['image_url'];
    final String? docUrl = user.docVerf;
    final String address = user.store?['adresse'] ?? 'Non renseignée';
    final String phone = user.store?['telephone'] ?? 'N/A';
    final String description = user.store?['description'] ?? 'Aucune description fournie.';

    return Scaffold(
      backgroundColor: const Color(0xFFFDF6F0),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 250,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                   imageUrl != null 
                    ? Image.network(
                        ApiConstants.formatImageUrl(imageUrl),
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _buildPlaceholder(),
                      )
                    : _buildPlaceholder(),
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
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              storeName,
                              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF2D1A0E)),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "Gérant: ${user.fullName}",
                              style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                            ),
                          ],
                        ),
                      ),
                      _buildChip(
                        user.isActive ? 'ACTIF' : 'SUSPENDU',
                        user.isActive ? const Color(0xFF2D5016) : Colors.red,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _buildInfoCard([
                    _buildInfoRow(Icons.email_outlined, "Email", user.email),
                    const Divider(height: 24),
                    _buildInfoRow(Icons.phone_outlined, "Téléphone", phone),
                    const Divider(height: 24),
                    _buildInfoRow(Icons.location_on_outlined, "Adresse", address),
                  ]),
                  const SizedBox(height: 24),
                  const Text(
                    "Description",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2D1A0E)),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    description,
                    style: TextStyle(color: Colors.grey.shade700, fontSize: 15, height: 1.5),
                  ),
                  const SizedBox(height: 32),
                  const Text(
                    "Documents de vérification",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2D1A0E)),
                  ),
                  const SizedBox(height: 12),
                  _buildDocCard(docUrl),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      color: const Color(0xFFB5D39D),
      child: const Icon(Icons.store, size: 80, color: Color(0xFF2D5016)),
    );
  }

  Widget _buildChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12),
      ),
    );
  }

  Widget _buildInfoCard(List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10)],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFFF26444).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: const Color(0xFFF26444), size: 20),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
              Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDocCard(String? docUrl) {
    final bool hasDoc = docUrl != null && docUrl.isNotEmpty;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: hasDoc ? Colors.white : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: hasDoc ? const Color(0xFF2D5016).withOpacity(0.2) : Colors.grey.shade300),
      ),
      child: Row(
        children: [
          Icon(
            hasDoc ? Icons.description_rounded : Icons.error_outline_rounded,
            color: hasDoc ? const Color(0xFF2D5016) : Colors.grey,
            size: 30,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hasDoc ? "Justificatif d'activité" : "Aucun document",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  hasDoc ? "Cliquer pour visualiser" : "Document non fourni",
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
              ],
            ),
          ),
          if (hasDoc)
            IconButton(
              icon: const Icon(Icons.open_in_new_rounded, color: Color(0xFFF26444)),
              onPressed: () async {
                final url = Uri.parse(ApiConstants.formatImageUrl(docUrl));
                if (await canLaunchUrl(url)) {
                  await launchUrl(url);
                }
              },
            ),
        ],
      ),
    );
  }
}
