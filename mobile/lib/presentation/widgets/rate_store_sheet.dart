import 'package:flutter/material.dart';
import '../../data/services/api_service.dart';
import '../../providers/auth_provider.dart';
import 'package:provider/provider.dart';

/// Labels for star rating (1–5).
const List<String> _ratingLabels = [
  'Très déçu',
  'Déçu',
  'Correct',
  'Très bien !',
  'Parfait !',
];

/// Bottom sheet: rate store (note + optional comment). One review per store; can modify.
class RateStoreSheet extends StatefulWidget {
  final int epicierId;
  final String nomBoutique;
  final VoidCallback? onSubmitted;

  const RateStoreSheet({
    super.key,
    required this.epicierId,
    required this.nomBoutique,
    this.onSubmitted,
  });

  @override
  State<RateStoreSheet> createState() => _RateStoreSheetState();
}

class _RateStoreSheetState extends State<RateStoreSheet> {
  static const Color _primary = Color(0xFF2D5016);
  static const Color _bgBeige = Color(0xFFFDF6F0);
  static const Color _starActive = Color(0xFFE8B923);
  static const Color _starInactive = Color(0xFFE0D5C7);

  final ApiService _api = ApiService();
  int _rating = 0;
  final TextEditingController _commentController = TextEditingController();
  bool _loading = true;
  bool _sending = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadExisting());
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _loadExisting() async {
    final token = context.read<AuthProvider>().token;
    if (token == null) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await _api.get('/avis/store/${widget.epicierId}', token: token);
      if (!mounted) return;
      final avis = res is Map ? res['avis'] : null;
      if (avis is Map) {
        _rating = int.tryParse(avis['note']?.toString() ?? '0') ?? 0;
        _commentController.text = avis['commentaire']?.toString() ?? '';
      }
      setState(() => _loading = false);
    } catch (e) {
      if (mounted) setState(() {
        _loading = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Future<void> _submit() async {
    if (_rating < 1 || _rating > 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez choisir une note (1 à 5 étoiles).')),
      );
      return;
    }
    final token = context.read<AuthProvider>().token;
    if (token == null) return;
    setState(() {
      _sending = true;
      _error = null;
    });
    try {
      await _api.post(
        '/avis',
        {
          'epicier_id': widget.epicierId,
          'note': _rating,
          'commentaire': _commentController.text.trim().isEmpty ? null : _commentController.text.trim(),
        },
        token: token,
      );
      if (!mounted) return;
      widget.onSubmitted?.call();
      Navigator.of(context).pop(true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Merci pour votre avis !')),
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _sending = false;
          _error = e.toString().replaceFirst('Exception: ', '');
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return DraggableScrollableSheet(
      initialChildSize: 0.55,
      minChildSize: 0.35,
      maxChildSize: 0.9,
      builder: (context, scrollController) => Container(
        decoration: const BoxDecoration(
          color: _bgBeige,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.star_rounded, color: _starActive, size: 26),
                const SizedBox(width: 8),
                const Text(
                  'Notez votre expérience',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2D1A0E),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                widget.nomBoutique,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
              ),
            ),
            const SizedBox(height: 16),
            Flexible(
              child: SingleChildScrollView(
                controller: scrollController,
                padding: EdgeInsets.only(
                  left: 20,
                  right: 20,
                  bottom: bottomInset + 24,
                ),
                child: _loading
                    ? const Padding(
                        padding: EdgeInsets.symmetric(vertical: 32),
                        child: Center(child: CircularProgressIndicator(color: _primary)),
                      )
                    : Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(5, (i) {
                              final value = i + 1;
                              final selected = _rating >= value;
                              return Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 3),
                                child: GestureDetector(
                                  onTap: () => setState(() => _rating = value),
                                  child: Icon(
                                    Icons.star_rounded,
                                    size: 40,
                                    color: selected ? _starActive : _starInactive,
                                  ),
                                ),
                              );
                            }),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _rating >= 1 && _rating <= 5 ? _ratingLabels[_rating - 1] : 'Choisissez une note',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFFB85C38),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            'COMMENTAIRE (OPTIONNEL)',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade600,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 6),
                          TextField(
                            controller: _commentController,
                            maxLines: 3,
                            minLines: 1,
                            decoration: InputDecoration(
                              hintText: 'Partagez votre avis...',
                              hintStyle: TextStyle(color: Colors.grey.shade500),
                              filled: true,
                              fillColor: const Color(0xFFF5EDE4),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            ),
                            onChanged: (_) => setState(() {}),
                          ),
                          if (_error != null) ...[
                            const SizedBox(height: 10),
                            Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 13)),
                          ],
                          const SizedBox(height: 24),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: _sending ? null : () => Navigator.of(context).pop(),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: _primary,
                                    side: const BorderSide(color: _primary),
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                  ),
                                  child: const Text('Annuler'),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: FilledButton(
                                  onPressed: _sending ? null : _submit,
                                  style: FilledButton.styleFrom(
                                    backgroundColor: _primary,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                  ),
                                  child: _sending
                                      ? const SizedBox(
                                          height: 20,
                                          width: 20,
                                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                        )
                                      : const Text('Envoyer'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
