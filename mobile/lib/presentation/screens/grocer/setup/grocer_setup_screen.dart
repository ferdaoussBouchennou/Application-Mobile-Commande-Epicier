import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart' as geo;
import 'package:http/http.dart' as http;
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' show LatLng;
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

  Future<void> _openMapPicker() async {
    final initialCenter = (_latitude != null && _longitude != null)
        ? LatLng(_latitude!, _longitude!)
        : const LatLng(33.5731, -7.5898);

    final result = await Navigator.push<_MapPickerResult>(
      context,
      MaterialPageRoute(
        builder: (_) => _MapPickerScreen(initialPosition: initialCenter),
      ),
    );

    if (result != null && mounted) {
      setState(() {
        _latitude = result.position.latitude;
        _longitude = result.position.longitude;
        if (result.address != null && result.address!.isNotEmpty) {
          _adresseController.text = result.address!;
        }
      });
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
                    onPressed: _openMapPicker,
                    icon: const Icon(Icons.map_rounded, size: 20),
                    label: const Text('Affiner sur la carte'),
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
          if (_latitude != null && _longitude != null) ...[
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: SizedBox(
                height: 180,
                child: IgnorePointer(
                  child: FlutterMap(
                    options: MapOptions(
                      initialCenter: LatLng(_latitude!, _longitude!),
                      initialZoom: 15,
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: 'https://mt1.google.com/vt/lyrs=m&x={x}&y={y}&z={z}',
                        maxZoom: 20,
                      ),
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: LatLng(_latitude!, _longitude!),
                            width: 40,
                            height: 40,
                            alignment: Alignment.topCenter,
                            child: Icon(Icons.location_pin, color: Colors.red.shade600, size: 40),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
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

class _MapPickerResult {
  final LatLng position;
  final String? address;
  _MapPickerResult({required this.position, this.address});
}

class _MapPickerScreen extends StatefulWidget {
  final LatLng initialPosition;
  const _MapPickerScreen({required this.initialPosition});

  @override
  State<_MapPickerScreen> createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends State<_MapPickerScreen> with TickerProviderStateMixin {
  late LatLng _selectedPosition;
  late final MapController _mapController;
  bool _isLocatingGps = false;
  bool _hasAutoLocated = false;
  bool _isSatelliteView = true;
  String? _resolvedAddress;
  bool _isReverseGeocoding = false;

  final _searchController = TextEditingController();
  List<Map<String, dynamic>> _searchResults = [];
  bool _isSearching = false;
  bool _showSearchResults = false;

  @override
  void initState() {
    super.initState();
    _selectedPosition = widget.initialPosition;
    _mapController = MapController();
    WidgetsBinding.instance.addPostFrameCallback((_) => _autoDetectLocation());
  }

  Future<void> _autoDetectLocation() async {
    if (_hasAutoLocated) return;
    _hasAutoLocated = true;

    final isStoredPosition = widget.initialPosition.latitude != 33.5731;
    if (isStoredPosition) {
      _reverseGeocode(_selectedPosition);
      return;
    }

    await _goToMyLocation();
  }

  Future<void> _goToMyLocation() async {
    setState(() => _isLocatingGps = true);
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showSnack('Activez les services de localisation');
        return;
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _showSnack('Permission de localisation refusée');
          return;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        _showSnack('Activez la localisation dans les paramètres');
        return;
      }
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, timeLimit: Duration(seconds: 10)),
      );
      if (!mounted) return;
      final newPos = LatLng(position.latitude, position.longitude);
      setState(() => _selectedPosition = newPos);
      _animatedMove(newPos, 17);
      _reverseGeocode(newPos);
    } catch (e) {
      if (mounted) _showSnack('Impossible d\'obtenir la position');
    } finally {
      if (mounted) setState(() => _isLocatingGps = false);
    }
  }

  Future<void> _reverseGeocode(LatLng pos) async {
    setState(() => _isReverseGeocoding = true);
    try {
      String? address;

      if (kIsWeb) {
        final url = Uri.parse(
          'https://nominatim.openstreetmap.org/reverse?format=json&lat=${pos.latitude}&lon=${pos.longitude}&zoom=19&addressdetails=1&accept-language=fr',
        );
        final response = await http.get(url, headers: {'User-Agent': 'MyHanut-App'});
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body) as Map<String, dynamic>;
          final addr = data['address'] as Map<String, dynamic>?;
          if (addr != null) {
            final city = addr['city'] ?? addr['town'] ?? addr['village'] ?? '';
            final parts = <String>[
              if (addr['house_number'] != null) addr['house_number'].toString(),
              if (addr['road'] != null) addr['road'].toString()
              else if (addr['pedestrian'] != null) addr['pedestrian'].toString(),
              if (addr['neighbourhood'] != null) addr['neighbourhood'].toString()
              else if (addr['quarter'] != null) addr['quarter'].toString(),
              if (addr['suburb'] != null) addr['suburb'].toString(),
              if (city.toString().isNotEmpty) city.toString(),
            ];
            if (parts.isNotEmpty) address = parts.join(', ');
          }
          if (address == null || address!.isEmpty) {
            final dn = data['display_name'] as String? ?? '';
            final segs = dn.split(', ');
            address = segs.take(segs.length > 4 ? 4 : segs.length).join(', ');
          }
        }
      } else {
        final placemarks = await geo.placemarkFromCoordinates(pos.latitude, pos.longitude);
        if (placemarks.isNotEmpty) {
          final p = placemarks.first;
          final parts = <String>[
            if (p.street != null && p.street!.isNotEmpty) p.street!,
            if (p.subLocality != null && p.subLocality!.isNotEmpty) p.subLocality!,
            if (p.locality != null && p.locality!.isNotEmpty) p.locality!,
            if (p.administrativeArea != null && p.administrativeArea!.isNotEmpty) p.administrativeArea!,
          ];
          if (parts.isNotEmpty) address = parts.join(', ');
        }
      }

      if (mounted) setState(() => _resolvedAddress = address);
    } catch (_) {
      if (mounted) setState(() => _resolvedAddress = null);
    } finally {
      if (mounted) setState(() => _isReverseGeocoding = false);
    }
  }

  void _animatedMove(LatLng dest, double zoom) {
    final camera = _mapController.camera;
    final latTween = Tween<double>(begin: camera.center.latitude, end: dest.latitude);
    final lngTween = Tween<double>(begin: camera.center.longitude, end: dest.longitude);
    final zoomTween = Tween<double>(begin: camera.zoom, end: zoom);

    final controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    final animation = CurvedAnimation(parent: controller, curve: Curves.easeInOut);

    controller.addListener(() {
      _mapController.move(
        LatLng(latTween.evaluate(animation), lngTween.evaluate(animation)),
        zoomTween.evaluate(animation),
      );
    });
    controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) controller.dispose();
    });
    controller.forward();
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
    );
  }

  Future<void> _searchPlace(String query) async {
    if (query.trim().length < 3) {
      setState(() { _searchResults = []; _showSearchResults = false; });
      return;
    }
    setState(() => _isSearching = true);
    try {
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/search?format=json&q=${Uri.encodeComponent(query.trim())}&limit=5&accept-language=fr&countrycodes=ma',
      );
      final response = await http.get(url, headers: {'User-Agent': 'MyHanut-App'});
      if (response.statusCode == 200 && mounted) {
        final results = (jsonDecode(response.body) as List).cast<Map<String, dynamic>>();
        setState(() {
          _searchResults = results;
          _showSearchResults = results.isNotEmpty;
        });
      }
    } catch (_) {}
    finally { if (mounted) setState(() => _isSearching = false); }
  }

  void _selectSearchResult(Map<String, dynamic> result) {
    final lat = double.tryParse(result['lat'].toString());
    final lng = double.tryParse(result['lon'].toString());
    if (lat == null || lng == null) return;

    final pos = LatLng(lat, lng);
    setState(() {
      _selectedPosition = pos;
      _showSearchResults = false;
      _searchController.clear();
    });
    _animatedMove(pos, 17);
    _reverseGeocode(pos);
    FocusScope.of(context).unfocus();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Carte
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _selectedPosition,
              initialZoom: 17,
              minZoom: 4,
              maxZoom: 19,
              onTap: (tapPosition, latLng) {
                setState(() => _selectedPosition = latLng);
                _reverseGeocode(latLng);
              },
            ),
            children: [
              if (_isSatelliteView)
                TileLayer(
                  urlTemplate: 'https://mt1.google.com/vt/lyrs=y&x={x}&y={y}&z={z}',
                  maxZoom: 20,
                )
              else
                TileLayer(
                  urlTemplate: 'https://mt1.google.com/vt/lyrs=m&x={x}&y={y}&z={z}',
                  maxZoom: 20,
                ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: _selectedPosition,
                    width: 60,
                    height: 60,
                    alignment: Alignment.topCenter,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.red.shade600,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 8, offset: const Offset(0, 3)),
                            ],
                          ),
                          child: const Icon(Icons.store_rounded, color: Colors.white, size: 22),
                        ),
                        CustomPaint(size: const Size(12, 8), painter: _TrianglePainter(Colors.red.shade600)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Barre de recherche
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
                child: Column(
                  children: [
                    Row(
                      children: [
                        _buildCircleButton(Icons.arrow_back_rounded, () => Navigator.pop(context)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(28),
                              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 10, offset: const Offset(0, 3))],
                            ),
                            child: TextField(
                              controller: _searchController,
                              onChanged: _searchPlace,
                              textInputAction: TextInputAction.search,
                              decoration: InputDecoration(
                                hintText: 'Rechercher un lieu, une rue...',
                                hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                                prefixIcon: Icon(Icons.search_rounded, color: Colors.grey.shade500, size: 22),
                                suffixIcon: _searchController.text.isNotEmpty
                                    ? IconButton(
                                        icon: Icon(Icons.close_rounded, color: Colors.grey.shade500, size: 20),
                                        onPressed: () {
                                          _searchController.clear();
                                          setState(() { _searchResults = []; _showSearchResults = false; });
                                          FocusScope.of(context).unfocus();
                                        },
                                      )
                                    : (_isSearching
                                        ? const Padding(
                                            padding: EdgeInsets.all(14),
                                            child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
                                          )
                                        : null),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (_showSearchResults)
                      Container(
                        margin: const EdgeInsets.only(top: 6, left: 52),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 10, offset: const Offset(0, 3))],
                        ),
                        constraints: const BoxConstraints(maxHeight: 250),
                        child: ListView.separated(
                          shrinkWrap: true,
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          itemCount: _searchResults.length,
                          separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey.shade200),
                          itemBuilder: (context, index) {
                            final r = _searchResults[index];
                            final name = r['display_name'] as String? ?? '';
                            final type = r['type'] as String? ?? '';
                            return ListTile(
                              dense: true,
                              leading: Icon(
                                _searchResultIcon(type),
                                color: GrocerTheme.primary,
                                size: 22,
                              ),
                              title: Text(
                                name.length > 80 ? '${name.substring(0, 80)}...' : name,
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              onTap: () => _selectSearchResult(r),
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),

          // Boutons droite : toggle vue, zoom, ma position
          Positioned(
            right: 16,
            bottom: 240,
            child: Column(
              children: [
                // Toggle satellite / standard
                Material(
                  color: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 3,
                  shadowColor: Colors.black26,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => setState(() => _isSatelliteView = !_isSatelliteView),
                    child: Container(
                      width: 44,
                      height: 44,
                      alignment: Alignment.center,
                      child: Icon(
                        _isSatelliteView ? Icons.map_rounded : Icons.satellite_alt_rounded,
                        color: const Color(0xFF2D1A0E),
                        size: 22,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                _buildCircleButton(Icons.add, () {
                  final z = _mapController.camera.zoom;
                  if (z < 19) _animatedMove(_mapController.camera.center, z + 1);
                }),
                const SizedBox(height: 8),
                _buildCircleButton(Icons.remove, () {
                  final z = _mapController.camera.zoom;
                  if (z > 4) _animatedMove(_mapController.camera.center, z - 1);
                }),
                const SizedBox(height: 16),
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: GrocerTheme.primary.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4))],
                  ),
                  child: Material(
                    color: GrocerTheme.primary,
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: _isLocatingGps ? null : _goToMyLocation,
                      child: SizedBox(
                        width: 48,
                        height: 48,
                        child: _isLocatingGps
                            ? const Padding(
                                padding: EdgeInsets.all(14),
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.my_location_rounded, color: Colors.white, size: 22),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Panneau bas
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 16, offset: const Offset(0, -4))],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: GrocerTheme.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.location_on_rounded, color: GrocerTheme.primary, size: 22),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (_resolvedAddress != null) ...[
                              Text(
                                _resolvedAddress!,
                                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: Color(0xFF2D1A0E)),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                            ] else if (_isReverseGeocoding) ...[
                              Row(
                                children: [
                                  SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.grey.shade400)),
                                  const SizedBox(width: 8),
                                  Text('Recherche de l\'adresse...', style: TextStyle(fontSize: 13, color: Colors.grey.shade500)),
                                ],
                              ),
                              const SizedBox(height: 2),
                            ] else
                              const Text('Position sélectionnée', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: Color(0xFF2D1A0E))),
                            Text(
                              '${_selectedPosition.latitude.toStringAsFixed(6)}, ${_selectedPosition.longitude.toStringAsFixed(6)}',
                              style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF8E1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.touch_app_rounded, size: 16, color: Colors.amber.shade800),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text('Appuyez sur la carte pour déplacer le marqueur', style: TextStyle(fontSize: 12, color: Colors.amber.shade900)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.pop(context, _MapPickerResult(
                        position: _selectedPosition,
                        address: _resolvedAddress,
                      )),
                      icon: const Icon(Icons.check_circle_rounded, size: 22),
                      label: const Text('Confirmer cette position', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: GrocerTheme.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _searchResultIcon(String type) {
    switch (type) {
      case 'restaurant': case 'cafe': case 'fast_food': return Icons.restaurant;
      case 'school': case 'university': case 'college': return Icons.school;
      case 'hospital': case 'pharmacy': case 'clinic': return Icons.local_hospital;
      case 'supermarket': case 'shop': case 'marketplace': return Icons.store;
      case 'mosque': case 'place_of_worship': return Icons.mosque;
      case 'residential': case 'house': case 'building': return Icons.home;
      case 'road': case 'street': case 'primary': case 'secondary': return Icons.route;
      default: return Icons.place;
    }
  }

  Widget _buildCircleButton(IconData icon, VoidCallback onTap) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      elevation: 3,
      shadowColor: Colors.black26,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(width: 44, height: 44, child: Icon(icon, color: const Color(0xFF2D1A0E), size: 22)),
      ),
    );
  }
}

class _TrianglePainter extends CustomPainter {
  final Color color;
  _TrianglePainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color..style = PaintingStyle.fill;
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width / 2, size.height)
      ..lineTo(size.width, 0)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
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
