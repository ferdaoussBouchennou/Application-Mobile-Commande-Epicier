import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../data/services/api_service.dart';
import '../../../../core/constants/api_constants.dart';
import '../grocer_theme.dart';
import '../grocer_main_screen.dart';

class GrocerSetupScreen extends StatefulWidget {
  const GrocerSetupScreen({super.key});

  @override
  State<GrocerSetupScreen> createState() => _GrocerSetupScreenState();
}

class _GrocerSetupScreenState extends State<GrocerSetupScreen> {
  final PageController _pageController = PageController();
  int _currentStep = 0;
  bool _isSubmitting = false;
  final ApiService _apiService = ApiService();

  // Step 1: General Info
  final _nomBoutiqueController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _telephoneController = TextEditingController();

  // Step 2: Location
  final _adresseController = TextEditingController();
  double? _latitude;
  double? _longitude;
  bool _isLocating = false;

  // Step 3: Schedule
  final List<DaySchedule> _horaires = [
    DaySchedule(jour: 'lundi', label: 'Lundi'),
    DaySchedule(jour: 'mardi', label: 'Mardi'),
    DaySchedule(jour: 'mercredi', label: 'Mercredi'),
    DaySchedule(jour: 'jeudi', label: 'Jeudi'),
    DaySchedule(jour: 'vendredi', label: 'Vendredi'),
    DaySchedule(jour: 'samedi', label: 'Samedi'),
    DaySchedule(jour: 'dimanche', label: 'Dimanche', heureDebut: '09:00', heureFin: '14:00'),
  ];

  // Step 4: Photo
  Uint8List? _imageBytes;
  String? _imageFilename;
  String? _uploadedImageUrl;

  final List<String> _stepTitles = [
    'Infos générales',
    'Localisation',
    'Horaires',
    'Photo boutique',
  ];

  final List<IconData> _stepIcons = [
    Icons.store_rounded,
    Icons.location_on_rounded,
    Icons.schedule_rounded,
    Icons.camera_alt_rounded,
  ];

  bool _isLoadingProfile = true;

  @override
  void initState() {
    super.initState();
    _loadStoreProfile();
  }

  Future<void> _loadStoreProfile() async {
    final auth = context.read<AuthProvider>();
    final token = auth.token;
    if (token == null) {
      setState(() => _isLoadingProfile = false);
      return;
    }
    try {
      final data = await _apiService.get('/epicier/profile', token: token);
      if (data != null && mounted) {
        setState(() {
          _nomBoutiqueController.text = data['nom_boutique'] ?? '';
          _telephoneController.text = data['telephone'] ?? '';
          _descriptionController.text = data['description'] ?? '';
          final adresse = data['adresse'] ?? '';
          if (adresse != 'À configurer' && adresse != 'Adresse à configurer') {
            _adresseController.text = adresse;
          }
          if (data['latitude'] != null) {
            _latitude = double.tryParse(data['latitude'].toString());
          }
          if (data['longitude'] != null) {
            _longitude = double.tryParse(data['longitude'].toString());
          }
          _isLoadingProfile = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingProfile = false);
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _nomBoutiqueController.dispose();
    _descriptionController.dispose();
    _telephoneController.dispose();
    _adresseController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (!_validateCurrentStep()) return;
    if (_currentStep < 3) {
      setState(() => _currentStep++);
      _pageController.animateToPage(_currentStep,
          duration: const Duration(milliseconds: 400), curve: Curves.easeInOut);
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
      _pageController.animateToPage(_currentStep,
          duration: const Duration(milliseconds: 400), curve: Curves.easeInOut);
    }
  }

  bool _validateCurrentStep() {
    switch (_currentStep) {
      case 0:
        if (_nomBoutiqueController.text.trim().isEmpty) {
          _showError('Le nom de la boutique est requis');
          return false;
        }
        if (_telephoneController.text.trim().isEmpty) {
          _showError('Le numéro de téléphone est requis');
          return false;
        }
        return true;
      case 1:
        if (_adresseController.text.trim().isEmpty) {
          _showError('L\'adresse est requise');
          return false;
        }
        return true;
      case 2:
        final hasOpenDay = _horaires.any((h) => h.isOpen);
        if (!hasOpenDay) {
          _showError('Sélectionnez au moins un jour d\'ouverture');
          return false;
        }
        return true;
      case 3:
        return true;
      default:
        return true;
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isLocating = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showError('Veuillez activer les services de localisation');
        setState(() => _isLocating = false);
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _showError('Permission de localisation refusée');
          setState(() => _isLocating = false);
          return;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        _showError('Veuillez activer la localisation dans les paramètres');
        setState(() => _isLocating = false);
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );
      if (mounted) {
        setState(() {
          _latitude = position.latitude;
          _longitude = position.longitude;
          _isLocating = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLocating = false);
        _showError('Impossible d\'obtenir la position GPS : $e');
      }
    }
  }

  Future<void> _enterManualCoordinates() async {
    final latController = TextEditingController(text: _latitude?.toString() ?? '');
    final lngController = TextEditingController(text: _longitude?.toString() ?? '');

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Coordonnées GPS', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: latController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
              decoration: const InputDecoration(labelText: 'Latitude', hintText: 'Ex: 33.5731'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: lngController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
              decoration: const InputDecoration(labelText: 'Longitude', hintText: 'Ex: -7.5898'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: GrocerTheme.primary),
            child: const Text('Valider', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (result == true) {
      final lat = double.tryParse(latController.text.trim());
      final lng = double.tryParse(lngController.text.trim());
      if (lat != null && lng != null) {
        setState(() {
          _latitude = lat;
          _longitude = lng;
        });
      } else {
        _showError('Coordonnées invalides');
      }
    }
  }

  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final XFile? picked = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1200,
        imageQuality: kIsWeb ? null : 85,
      );
      if (picked != null) {
        final bytes = await picked.readAsBytes();
        setState(() {
          _imageBytes = bytes;
          _imageFilename = picked.name.isNotEmpty ? picked.name : 'store_photo.jpg';
        });
      }
    } catch (e) {
      _showError('Erreur lors de la sélection : $e');
    }
  }

  Future<void> _takePhoto() async {
    if (kIsWeb) {
      _pickImage();
      return;
    }
    try {
      final picker = ImagePicker();
      final XFile? picked = await picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1200,
        imageQuality: 85,
      );
      if (picked != null) {
        final bytes = await picked.readAsBytes();
        setState(() {
          _imageBytes = bytes;
          _imageFilename = picked.name.isNotEmpty ? picked.name : 'store_photo.jpg';
        });
      }
    } catch (e) {
      _showError('Erreur lors de la capture : $e');
    }
  }

  Future<void> _submitRegistration() async {
    if (!_validateCurrentStep()) return;

    setState(() => _isSubmitting = true);
    final auth = context.read<AuthProvider>();
    final token = auth.token;

    if (token == null) {
      _showError('Session expirée, veuillez vous reconnecter');
      setState(() => _isSubmitting = false);
      return;
    }

    try {
      if (_imageBytes != null && _imageFilename != null) {
        _uploadedImageUrl = await _apiService.uploadStoreImage(
          token: token,
          bytes: _imageBytes!,
          filename: _imageFilename!,
        );
      }

      final horairesData = _horaires
          .map((h) => <String, dynamic>{
                'jour': h.jour,
                'heure_debut': h.heureDebut,
                'heure_fin': h.heureFin,
                'is_open': h.isOpen,
              })
          .toList();

      final body = <String, dynamic>{
        'nom_boutique': _nomBoutiqueController.text.trim(),
        'description': _descriptionController.text.trim(),
        'telephone': _telephoneController.text.trim(),
        'adresse': _adresseController.text.trim(),
        'horaires': horairesData,
      };

      if (_latitude != null) body['latitude'] = _latitude;
      if (_longitude != null) body['longitude'] = _longitude;
      if (_uploadedImageUrl != null) body['image_url'] = _uploadedImageUrl;

      await _apiService.put('/epicier/complete-registration', body, token: token);

      auth.markSetupComplete();

      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const GrocerMainScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      _showError(e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingProfile) {
      return Scaffold(
        backgroundColor: GrocerTheme.background,
        body: const Center(
          child: CircularProgressIndicator(color: GrocerTheme.primary),
        ),
      );
    }

    return Scaffold(
      backgroundColor: GrocerTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildStepIndicator(),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildStep1GeneralInfo(),
                  _buildStep2Location(),
                  _buildStep3Schedule(),
                  _buildStep4Photo(),
                ],
              ),
            ),
            _buildBottomButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: GrocerTheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.storefront_rounded, color: GrocerTheme.primary, size: 28),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Configurez votre boutique',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: GrocerTheme.textDark,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Étape ${_currentStep + 1} sur 4 - ${_stepTitles[_currentStep]}',
                      style: TextStyle(
                        fontSize: 13,
                        color: GrocerTheme.textMuted.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStepIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
      child: Row(
        children: List.generate(4, (index) {
          final isActive = index == _currentStep;
          final isCompleted = index < _currentStep;
          return Expanded(
            child: GestureDetector(
              onTap: index <= _currentStep ? () {
                setState(() => _currentStep = index);
                _pageController.animateToPage(index,
                    duration: const Duration(milliseconds: 400), curve: Curves.easeInOut);
              } : null,
              child: Column(
                children: [
                  Row(
                    children: [
                      if (index > 0)
                        Expanded(
                          child: Container(
                            height: 3,
                            decoration: BoxDecoration(
                              color: isCompleted || isActive
                                  ? GrocerTheme.primary
                                  : GrocerTheme.border.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        width: isActive ? 40 : 32,
                        height: isActive ? 40 : 32,
                        decoration: BoxDecoration(
                          color: isActive
                              ? GrocerTheme.primary
                              : isCompleted
                                  ? GrocerTheme.primary.withOpacity(0.8)
                                  : Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isActive || isCompleted
                                ? GrocerTheme.primary
                                : GrocerTheme.border.withOpacity(0.4),
                            width: 2,
                          ),
                          boxShadow: isActive
                              ? [BoxShadow(color: GrocerTheme.primary.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 2))]
                              : [],
                        ),
                        child: Icon(
                          isCompleted ? Icons.check_rounded : _stepIcons[index],
                          size: isActive ? 20 : 16,
                          color: isActive || isCompleted ? Colors.white : GrocerTheme.border,
                        ),
                      ),
                      if (index < 3)
                        Expanded(
                          child: Container(
                            height: 3,
                            decoration: BoxDecoration(
                              color: isCompleted
                                  ? GrocerTheme.primary
                                  : GrocerTheme.border.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _stepTitles[index],
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                      color: isActive ? GrocerTheme.primary : GrocerTheme.textMuted.withOpacity(0.6),
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  // ──────────── STEP 1: General Info ────────────

  Widget _buildStep1GeneralInfo() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Informations de votre boutique', Icons.info_outline_rounded),
          const SizedBox(height: 8),
          Text(
            'Ces informations seront visibles par vos clients',
            style: TextStyle(fontSize: 13, color: GrocerTheme.textMuted.withOpacity(0.6)),
          ),
          const SizedBox(height: 24),
          _buildLabeledField(
            label: 'Nom de la boutique *',
            child: _buildInputField(
              controller: _nomBoutiqueController,
              hint: 'Ex: Épicerie du Quartier',
              icon: Icons.store_rounded,
            ),
          ),
          const SizedBox(height: 20),
          _buildLabeledField(
            label: 'Numéro de téléphone *',
            child: _buildInputField(
              controller: _telephoneController,
              hint: 'Ex: 0612345678',
              icon: Icons.phone_rounded,
              keyboardType: TextInputType.phone,
            ),
          ),
          const SizedBox(height: 20),
          _buildLabeledField(
            label: 'Description',
            child: _buildInputField(
              controller: _descriptionController,
              hint: 'Décrivez votre boutique en quelques mots...',
              icon: Icons.description_rounded,
              maxLines: 4,
            ),
          ),
        ],
      ),
    );
  }

  // ──────────── STEP 2: Location ────────────

  Widget _buildStep2Location() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Localisation de votre boutique', Icons.map_rounded),
          const SizedBox(height: 8),
          Text(
            'Aidez vos clients à vous trouver facilement',
            style: TextStyle(fontSize: 13, color: GrocerTheme.textMuted.withOpacity(0.6)),
          ),
          const SizedBox(height: 24),
          _buildLabeledField(
            label: 'Adresse complète *',
            child: _buildInputField(
              controller: _adresseController,
              hint: 'Ex: 12 Rue de la Liberté, Casablanca',
              icon: Icons.location_on_rounded,
              maxLines: 2,
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: GrocerTheme.border.withOpacity(0.2)),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4)),
              ],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: GrocerTheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.gps_fixed_rounded, color: GrocerTheme.primary, size: 22),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Position GPS',
                            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: GrocerTheme.textDark),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _latitude != null
                                ? '${_latitude!.toStringAsFixed(6)}, ${_longitude!.toStringAsFixed(6)}'
                                : 'Non définie',
                            style: TextStyle(
                              fontSize: 12,
                              color: _latitude != null ? GrocerTheme.primary : GrocerTheme.textMuted.withOpacity(0.5),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_latitude != null)
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: GrocerTheme.trendPositive.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.check, color: GrocerTheme.trendPositive, size: 18),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isLocating ? null : _getCurrentLocation,
                    icon: _isLocating
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.my_location_rounded, size: 20),
                    label: Text(_isLocating ? 'Localisation...' : 'Utiliser ma position actuelle'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: GrocerTheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _enterManualCoordinates,
                    icon: const Icon(Icons.edit_location_alt_rounded, size: 20),
                    label: const Text('Saisir les coordonnées manuellement'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: GrocerTheme.primary,
                      side: const BorderSide(color: GrocerTheme.border),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF8E1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFFFE082)),
            ),
            child: Row(
              children: [
                const Icon(Icons.lightbulb_outline, color: Color(0xFFF9A825), size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'La position GPS permet à vos clients de vous trouver sur la carte',
                    style: TextStyle(fontSize: 12, color: Colors.amber.shade900),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ──────────── STEP 3: Schedule ────────────

  Widget _buildStep3Schedule() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Horaires d\'ouverture', Icons.access_time_rounded),
          const SizedBox(height: 8),
          Text(
            'Définissez vos horaires pour chaque jour',
            style: TextStyle(fontSize: 13, color: GrocerTheme.textMuted.withOpacity(0.6)),
          ),
          const SizedBox(height: 20),
          ..._horaires.map((day) => _buildDayScheduleCard(day)),
        ],
      ),
    );
  }

  Widget _buildDayScheduleCard(DaySchedule day) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: day.isOpen ? GrocerTheme.primary.withOpacity(0.3) : GrocerTheme.border.withOpacity(0.15),
        ),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 6, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              SizedBox(
                width: 90,
                child: Text(
                  day.label,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: day.isOpen ? GrocerTheme.textDark : GrocerTheme.textMuted.withOpacity(0.5),
                  ),
                ),
              ),
              const Spacer(),
              Text(
                day.isOpen ? 'Ouvert' : 'Fermé',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: day.isOpen ? GrocerTheme.primary : GrocerTheme.textMuted.withOpacity(0.5),
                ),
              ),
              const SizedBox(width: 8),
              Switch.adaptive(
                value: day.isOpen,
                activeColor: GrocerTheme.primary,
                onChanged: (val) {
                  setState(() => day.isOpen = val);
                },
              ),
            ],
          ),
          if (day.isOpen) ...[
            const Divider(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildTimeSelector(
                    label: 'Ouverture',
                    value: day.heureDebut,
                    onTap: () => _selectTime(day, isStart: true),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Icon(Icons.arrow_forward_rounded, color: GrocerTheme.textMuted.withOpacity(0.4), size: 20),
                ),
                Expanded(
                  child: _buildTimeSelector(
                    label: 'Fermeture',
                    value: day.heureFin,
                    onTap: () => _selectTime(day, isStart: false),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTimeSelector({required String label, required String value, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: GrocerTheme.background,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: GrocerTheme.border.withOpacity(0.2)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.access_time, size: 16, color: GrocerTheme.primary.withOpacity(0.7)),
            const SizedBox(width: 8),
            Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: GrocerTheme.textDark),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectTime(DaySchedule day, {required bool isStart}) async {
    final parts = (isStart ? day.heureDebut : day.heureFin).split(':');
    final initial = TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: GrocerTheme.primary),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      final formatted = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      setState(() {
        if (isStart) {
          day.heureDebut = formatted;
        } else {
          day.heureFin = formatted;
        }
      });
    }
  }

  // ──────────── STEP 4: Photo ────────────

  Widget _buildStep4Photo() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Photo de votre boutique', Icons.photo_library_rounded),
          const SizedBox(height: 8),
          Text(
            'Ajoutez une photo pour attirer plus de clients',
            style: TextStyle(fontSize: 13, color: GrocerTheme.textMuted.withOpacity(0.6)),
          ),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: _pickImage,
            child: Container(
              width: double.infinity,
              height: 220,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _imageBytes != null
                      ? GrocerTheme.primary.withOpacity(0.4)
                      : GrocerTheme.border.withOpacity(0.3),
                  width: 2,
                  strokeAlign: BorderSide.strokeAlignInside,
                ),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 4)),
                ],
              ),
              child: _imageBytes != null
                  ? Stack(
                      fit: StackFit.expand,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(18),
                          child: Image.memory(_imageBytes!, fit: BoxFit.cover),
                        ),
                        Positioned(
                          top: 10,
                          right: 10,
                          child: GestureDetector(
                            onTap: () => setState(() {
                              _imageBytes = null;
                              _imageFilename = null;
                            }),
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.6),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.close, color: Colors.white, size: 18),
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 10,
                          left: 10,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: GrocerTheme.primary.withOpacity(0.85),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.check_circle, color: Colors.white, size: 16),
                                SizedBox(width: 6),
                                Text('Photo sélectionnée', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: GrocerTheme.primary.withOpacity(0.08),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.add_a_photo_rounded, size: 40, color: GrocerTheme.primary.withOpacity(0.6)),
                        ),
                        const SizedBox(height: 14),
                        const Text(
                          'Appuyez pour sélectionner une photo',
                          style: TextStyle(color: GrocerTheme.textMuted, fontWeight: FontWeight.w600, fontSize: 14),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'JPG, PNG • Max 5 Mo',
                          style: TextStyle(color: GrocerTheme.textMuted.withOpacity(0.5), fontSize: 12),
                        ),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 16),
          if (kIsWeb)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _pickImage,
                icon: const Icon(Icons.upload_file_rounded, size: 20),
                label: const Text('Choisir une photo'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: GrocerTheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
              ),
            )
          else
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickImage,
                    icon: const Icon(Icons.photo_library_rounded, size: 20),
                    label: const Text('Galerie'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: GrocerTheme.primary,
                      side: const BorderSide(color: GrocerTheme.border),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _takePhoto,
                    icon: const Icon(Icons.camera_alt_rounded, size: 20),
                    label: const Text('Caméra'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: GrocerTheme.primary,
                      side: const BorderSide(color: GrocerTheme.border),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: GrocerTheme.primary.withOpacity(0.04),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: GrocerTheme.primary.withOpacity(0.15)),
            ),
            child: Row(
              children: [
                Icon(Icons.tips_and_updates_rounded, color: GrocerTheme.primary.withOpacity(0.6), size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Une belle photo de votre devanture attire 3x plus de clients !',
                    style: TextStyle(fontSize: 12, color: GrocerTheme.primary.withOpacity(0.8)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ──────────── Bottom Buttons ────────────

  Widget _buildBottomButtons() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -4)),
        ],
      ),
      child: Row(
        children: [
          if (_currentStep > 0)
            Expanded(
              flex: 2,
              child: OutlinedButton(
                onPressed: _prevStep,
                style: OutlinedButton.styleFrom(
                  foregroundColor: GrocerTheme.textMuted,
                  side: BorderSide(color: GrocerTheme.border.withOpacity(0.4)),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('Retour', style: TextStyle(fontWeight: FontWeight.w600)),
              ),
            ),
          if (_currentStep > 0) const SizedBox(width: 12),
          Expanded(
            flex: 3,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : (_currentStep < 3 ? _nextStep : _submitRegistration),
              style: ElevatedButton.styleFrom(
                backgroundColor: GrocerTheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
                disabledBackgroundColor: GrocerTheme.primary.withOpacity(0.5),
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _currentStep < 3 ? 'Suivant' : 'Terminer',
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          _currentStep < 3 ? Icons.arrow_forward_rounded : Icons.check_circle_rounded,
                          size: 20,
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  // ──────────── Common Widgets ────────────

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: GrocerTheme.primary, size: 22),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: GrocerTheme.textDark,
          ),
        ),
      ],
    );
  }

  Widget _buildLabeledField({required String label, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: GrocerTheme.textMuted),
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: GrocerTheme.border.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 3)),
        ],
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        style: const TextStyle(fontSize: 14, color: GrocerTheme.textDark),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: GrocerTheme.textMuted.withOpacity(0.4)),
          prefixIcon: maxLines == 1 ? Icon(icon, color: GrocerTheme.primary.withOpacity(0.6), size: 20) : null,
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: maxLines > 1 ? 14 : 16),
        ),
      ),
    );
  }
}

class DaySchedule {
  final String jour;
  final String label;
  bool isOpen;
  String heureDebut;
  String heureFin;

  DaySchedule({
    required this.jour,
    required this.label,
    this.isOpen = true,
    this.heureDebut = '08:00',
    this.heureFin = '22:00',
  });
}
