import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' show LatLng;
import '../../../data/services/api_service.dart';
import '../../../data/models/user_model.dart';
import '../../../providers/auth_provider.dart';
import '../../widgets/admin/admin_header.dart';
import '../grocer/grocer_theme.dart';
import '../grocer/setup/grocer_setup_screen.dart' show DaySchedule;

import '../../widgets/admin/map_picker_screen.dart';

class AddEpicierScreen extends StatefulWidget {
  final UserModel? existingUser;
  const AddEpicierScreen({super.key, this.existingUser});

  @override
  State<AddEpicierScreen> createState() => _AddEpicierScreenState();
}

class _AddEpicierScreenState extends State<AddEpicierScreen> {
  final PageController _pageController = PageController();
  int _currentStep = 0;
  bool _isSubmitting = false;
  final ApiService _apiService = ApiService();

  // Step 1: Profil Personnel
  final _nomController = TextEditingController();
  final _prenomController = TextEditingController();
  final _emailController = TextEditingController();
  final _mdpController = TextEditingController();

  // Step 2: Boutique (General Info)
  final _nomBoutiqueController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _telephoneController = TextEditingController();

  // Step 3: Location
  final _adresseController = TextEditingController();
  double? _latitude;
  double? _longitude;
  bool _isLocating = false;

  // Step 4: Schedule
  final List<DaySchedule> _horaires = [
    DaySchedule(jour: 'lundi', label: 'Lundi'),
    DaySchedule(jour: 'mardi', label: 'Mardi'),
    DaySchedule(jour: 'mercredi', label: 'Mercredi'),
    DaySchedule(jour: 'jeudi', label: 'Jeudi'),
    DaySchedule(jour: 'vendredi', label: 'Vendredi'),
    DaySchedule(jour: 'samedi', label: 'Samedi'),
    DaySchedule(jour: 'dimanche', label: 'Dimanche', heureDebut: '09:00', heureFin: '14:00'),
  ];

  // Step 5: Photo & Fichiers
  XFile? _imageFile;
  PlatformFile? _docFile;
  final _picker = ImagePicker();

  final List<String> _stepTitles = [
    'Profil Perso',
    'Infos générales',
    'Localisation',
    'Horaires',
    'Fichiers',
  ];

  final List<IconData> _stepIcons = [
    Icons.person_rounded,
    Icons.store_rounded,
    Icons.location_on_rounded,
    Icons.schedule_rounded,
    Icons.camera_alt_rounded,
  ];

  @override
  void initState() {
    super.initState();
    if (widget.existingUser != null) {
      final u = widget.existingUser!;
      _nomController.text = u.nom;
      _prenomController.text = u.prenom;
      _emailController.text = u.email;
      if (u.store != null) {
        _nomBoutiqueController.text = u.store!['nom_boutique']?.toString() ?? '';
        _descriptionController.text = u.store!['description']?.toString() ?? '';
        _telephoneController.text = u.store!['telephone']?.toString() ?? '';
        _adresseController.text = u.store!['adresse']?.toString() ?? '';
        if (u.store!['latitude'] != null) {
          _latitude = double.tryParse(u.store!['latitude'].toString());
        }
        if (u.store!['longitude'] != null) {
          _longitude = double.tryParse(u.store!['longitude'].toString());
        }
      }
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _nomController.dispose();
    _prenomController.dispose();
    _emailController.dispose();
    _mdpController.dispose();
    _nomBoutiqueController.dispose();
    _descriptionController.dispose();
    _telephoneController.dispose();
    _adresseController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (!_validateCurrentStep()) return;
    if (_currentStep < 4) {
      FocusScope.of(context).unfocus();
      setState(() => _currentStep++);
      _pageController.animateToPage(_currentStep,
          duration: const Duration(milliseconds: 400), curve: Curves.easeInOut);
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      FocusScope.of(context).unfocus();
      setState(() => _currentStep--);
      _pageController.animateToPage(_currentStep,
          duration: const Duration(milliseconds: 400), curve: Curves.easeInOut);
    }
  }

  bool _validateCurrentStep() {
    switch (_currentStep) {
      case 0:
        if (_nomController.text.trim().isEmpty || 
            _prenomController.text.trim().isEmpty || 
            _emailController.text.trim().isEmpty || 
            (widget.existingUser == null && _mdpController.text.isEmpty)) {
          _showError('Tous les champs de connexion sont requis');
          return false;
        }
        if (!_emailController.text.contains('@')) {
          _showError('Email invalide');
          return false;
        }
        return true;
      case 1:
        if (_nomBoutiqueController.text.trim().isEmpty) {
          _showError('Le nom de la boutique est requis');
          return false;
        }
        if (_telephoneController.text.trim().isEmpty) {
          _showError('Le numéro de téléphone est requis');
          return false;
        }
        return true;
      case 2:
        if (_adresseController.text.trim().isEmpty) {
          _showError('L\'adresse est requise');
          return false;
        }
        return true;
      case 3:
        final hasOpenDay = _horaires.any((h) => h.isOpen);
        if (!hasOpenDay) {
          _showError('Sélectionnez au moins un jour d\'ouverture');
          return false;
        }
        return true;
      case 4:
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
          _showError('Permission refusée');
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
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, timeLimit: Duration(seconds: 15)),
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
        _showError('Impossible d\'obtenir la position : $e');
      }
    }
  }

  Future<void> _openMapPicker() async {
    final initialCenter = (_latitude != null && _longitude != null)
        ? LatLng(_latitude!, _longitude!)
        : const LatLng(33.5731, -7.5898);
    final result = await Navigator.push<MapPickerResult>(
      context,
      MaterialPageRoute(builder: (_) => MapPickerScreen(initialPosition: initialCenter)),
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
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery, maxWidth: 1200, imageQuality: 85);
    if (pickedFile != null) {
      setState(() => _imageFile = pickedFile);
    }
  }

  Future<void> _pickDocument() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx', 'jpg', 'png'],
      withData: true,
    );
    if (result != null) {
      setState(() => _docFile = result.files.single);
    }
  }

  Future<void> _submitRegistration() async {
    if (!_validateCurrentStep()) return;
    setState(() => _isSubmitting = true);
    try {
      final token = context.read<AuthProvider>().token;
      
      final horairesData = _horaires.map((h) => <String, dynamic>{
        'jour': h.jour,
        'heure_debut': h.heureDebut,
        'heure_fin': h.heureFin,
        'is_open': h.isOpen,
      }).toList();

      final Map<String, dynamic> fields = {
        'nom': _nomController.text.trim(),
        'prenom': _prenomController.text.trim(),
        'email': _emailController.text.trim(),
        'mdp': _mdpController.text,
        'nom_boutique': _nomBoutiqueController.text.trim(),
        'adresse': _adresseController.text.trim(),
        'telephone': _telephoneController.text.trim(),
        'description_boutique': _descriptionController.text.trim(),
        'horaires': jsonEncode(horairesData),
      };

      if (_latitude != null) fields['latitude'] = _latitude.toString();
      if (_longitude != null) fields['longitude'] = _longitude.toString();

      final Map<String, List<int>> files = {};
      final Map<String, String> filenames = {};

      if (_imageFile != null) {
        final bytes = await _imageFile!.readAsBytes();
        files['image_boutique'] = bytes;
        filenames['image_boutique'] = _imageFile!.name;
      }
      if (_docFile != null && _docFile!.bytes != null) {
        files['document_verification'] = _docFile!.bytes!;
        filenames['document_verification'] = _docFile!.name;
      }

      if (widget.existingUser != null) {
        await _apiService.putMultipart(
          '/admin/epiciers/${widget.existingUser!.id}',
          fields,
          token: token,
          files: files.isNotEmpty ? files : null,
          filenames: filenames.isNotEmpty ? filenames : null,
        );
      } else {
        await _apiService.postMultipart(
          '/admin/register-epicier',
          fields,
          token: token,
          files: files.isNotEmpty ? files : null,
          filenames: filenames.isNotEmpty ? filenames : null,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Action effectuée avec succès !')),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        _showError(e.toString().replaceAll('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
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
                  _buildStep0Profil(),
                  _buildStep1GeneralInfo(),
                  _buildStep2Location(),
                  _buildStep3Schedule(),
                  _buildStep4Media(),
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
              IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.arrow_back), padding: EdgeInsets.zero, alignment: Alignment.centerLeft),
              const SizedBox(width: 8),
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
                    Text(
                      widget.existingUser != null ? 'Modifier un épicier' : 'Créer un épicier',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: GrocerTheme.textDark,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Étape ${_currentStep + 1} sur 5 - ${_stepTitles[_currentStep]}',
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: List.generate(5, (index) {
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
                        width: isActive ? 34 : 28,
                        height: isActive ? 34 : 28,
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
                          size: isActive ? 16 : 14,
                          color: isActive || isCompleted ? Colors.white : GrocerTheme.border,
                        ),
                      ),
                      if (index < 4)
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
                      fontSize: 9,
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

  Widget _buildStep0Profil() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Profil Personnel', Icons.person_add_alt_1_rounded),
          const SizedBox(height: 8),
          const Text('Ces informations serviront pour la connexion', style: TextStyle(color: GrocerTheme.textMuted, fontSize: 13)),
          const SizedBox(height: 24),
          _buildLabeledField(
            label: 'Nom *',
            child: _buildInputField(controller: _nomController, hint: 'Ex: Doe', icon: Icons.person_outline),
          ),
          const SizedBox(height: 16),
          _buildLabeledField(
            label: 'Prénom *',
            child: _buildInputField(controller: _prenomController, hint: 'Ex: John', icon: Icons.person_outline),
          ),
          const SizedBox(height: 16),
          _buildLabeledField(
            label: 'Email professionnel *',
            child: _buildInputField(controller: _emailController, hint: 'contact@boutique.com', icon: Icons.alternate_email_rounded, keyboardType: TextInputType.emailAddress),
          ),
          const SizedBox(height: 16),
          _buildLabeledField(
            label: widget.existingUser == null ? 'Mot de passe initial *' : 'Nouveau Mot de passe (optionnel)',
            child: _buildInputField(controller: _mdpController, hint: widget.existingUser == null ? 'Mot de passe sécurisé' : 'Laissez vide pour conserver', icon: Icons.lock_outline_rounded),
          ),
        ],
      ),
    );
  }

  Widget _buildStep1GeneralInfo() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Informations de la boutique', Icons.info_outline_rounded),
          const SizedBox(height: 8),
          const Text('Ces informations seront visibles par les clients', style: TextStyle(color: GrocerTheme.textMuted, fontSize: 13)),
          const SizedBox(height: 24),
          _buildLabeledField(
            label: 'Nom de la boutique *',
            child: _buildInputField(controller: _nomBoutiqueController, hint: 'Épicerie Centrale', icon: Icons.storefront_rounded),
          ),
          const SizedBox(height: 16),
          _buildLabeledField(
            label: 'Numéro de téléphone *',
            child: _buildInputField(controller: _telephoneController, hint: '0555112233', icon: Icons.phone_rounded, keyboardType: TextInputType.phone),
          ),
          const SizedBox(height: 16),
          _buildLabeledField(
            label: 'Description',
            child: _buildInputField(controller: _descriptionController, hint: 'Produits frais, lait, pain...', icon: Icons.notes_rounded, maxLines: 4),
          ),
        ],
      ),
    );
  }

  Widget _buildStep2Location() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Emplacement', Icons.place_outlined),
          const SizedBox(height: 8),
          const Text('Aidez les clients à vous trouver facilement', style: TextStyle(color: GrocerTheme.textMuted, fontSize: 13)),
          const SizedBox(height: 24),
          _buildLabeledField(
            label: 'Adresse complète *',
            child: _buildInputField(controller: _adresseController, hint: '10 Rue des Fleurs, Quartier Centre', icon: Icons.location_on_rounded, maxLines: 2),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: GrocerTheme.primary.withOpacity(0.04),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: GrocerTheme.primary.withOpacity(0.15)),
            ),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: GrocerTheme.primary.withOpacity(0.1), shape: BoxShape.circle),
                      child: const Icon(Icons.gps_fixed_rounded, color: GrocerTheme.primary, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Position GPS', style: TextStyle(fontWeight: FontWeight.w700, color: GrocerTheme.primary.withOpacity(0.8))),
                          const SizedBox(height: 4),
                          Text(
                            _latitude != null ? '${_latitude!.toStringAsFixed(6)}, ${_longitude!.toStringAsFixed(6)}' : 'Non configurée',
                            style: TextStyle(color: _latitude != null ? GrocerTheme.textDark : GrocerTheme.textMuted),
                          ),
                        ],
                      ),
                    ),
                    if (_latitude != null) const Icon(Icons.check_circle_rounded, color: Colors.green),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _isLocating ? null : _getCurrentLocation,
                        icon: _isLocating 
                            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: GrocerTheme.primary))
                            : const Icon(Icons.my_location_rounded, size: 18),
                        label: const Text('Ma position', style: TextStyle(fontSize: 13)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: GrocerTheme.primary,
                          side: BorderSide(color: GrocerTheme.primary.withOpacity(0.5)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _openMapPicker,
                        icon: const Icon(Icons.map_rounded, size: 18),
                        label: const Text('Ouvrir la carte', style: TextStyle(fontSize: 13)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: GrocerTheme.primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (_latitude != null && _longitude != null) ...[
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: SizedBox(
                height: 160,
                child: IgnorePointer(
                  child: FlutterMap(
                    options: MapOptions(initialCenter: LatLng(_latitude!, _longitude!), initialZoom: 15),
                    children: [
                      TileLayer(urlTemplate: 'https://mt1.google.com/vt/lyrs=m&x={x}&y={y}&z={z}', maxZoom: 20),
                      MarkerLayer(
                        markers: [Marker(point: LatLng(_latitude!, _longitude!), child: Icon(Icons.location_pin, color: Colors.red.shade600, size: 40))],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStep3Schedule() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Horaires', Icons.access_time_rounded),
          const SizedBox(height: 8),
          const Text('Définissez les jours et heures d\'ouverture', style: TextStyle(color: GrocerTheme.textMuted, fontSize: 13)),
          const SizedBox(height: 24),
          ..._horaires.map((schedule) {
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: schedule.isOpen ? Colors.white : GrocerTheme.background,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: schedule.isOpen ? GrocerTheme.primary.withOpacity(0.3) : GrocerTheme.border.withOpacity(0.3)),
                boxShadow: schedule.isOpen ? [BoxShadow(color: GrocerTheme.primary.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))] : null,
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 40,
                    child: Switch(
                      value: schedule.isOpen,
                      activeColor: GrocerTheme.primary,
                      onChanged: (val) => setState(() => schedule.isOpen = val),
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 76,
                    child: Text(
                      schedule.label,
                      style: TextStyle(fontWeight: FontWeight.w700, color: schedule.isOpen ? GrocerTheme.textDark : GrocerTheme.textMuted),
                    ),
                  ),
                  Expanded(
                    child: schedule.isOpen ? Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        _buildTimePickerCard(schedule.heureDebut, (time) => setState(() => schedule.heureDebut = time)),
                        const Padding(padding: EdgeInsets.symmetric(horizontal: 6), child: Text('-', style: TextStyle(fontWeight: FontWeight.bold, color: GrocerTheme.textMuted))),
                        _buildTimePickerCard(schedule.heureFin, (time) => setState(() => schedule.heureFin = time)),
                      ],
                    ) : const Align(
                      alignment: Alignment.centerRight,
                      child: Text('Fermé', style: TextStyle(color: GrocerTheme.textMuted, fontStyle: FontStyle.italic, fontWeight: FontWeight.w500)),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildStep4Media() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Fichiers et Photos', Icons.folder_special_outlined),
          const SizedBox(height: 8),
          const Text('Ajoutez la photo de la boutique et les documents légaux', style: TextStyle(color: GrocerTheme.textMuted, fontSize: 13)),
          const SizedBox(height: 24),
          _buildFilePickerBtn(
            label: 'Photo de la devanture',
            fileName: _imageFile?.name,
            icon: Icons.add_photo_alternate_rounded,
            onTap: _pickImage,
          ),
          const SizedBox(height: 16),
          _buildFilePickerBtn(
            label: 'Document d\'identité / Kbis',
            fileName: _docFile?.name,
            icon: Icons.contact_page_rounded,
            onTap: _pickDocument,
          ),
          const SizedBox(height: 24),
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
                    'Une belle photo de la devanture attire 3x plus de clients !',
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

  Widget _buildBottomButtons() {
    final isLastStep = _currentStep == 4;
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -4))],
      ),
      child: Row(
        children: [
          if (_currentStep > 0)
            Expanded(
              flex: 2,
              child: OutlinedButton(
                onPressed: _isSubmitting ? null : _prevStep,
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
              onPressed: _isSubmitting ? null : (isLastStep ? _submitRegistration : _nextStep),
              style: ElevatedButton.styleFrom(
                backgroundColor: GrocerTheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
                disabledBackgroundColor: GrocerTheme.primary.withOpacity(0.5),
              ),
              child: _isSubmitting 
                  ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          isLastStep ? 'Terminer' : 'Suivant',
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                        ),
                        if (!isLastStep) ...[
                          const SizedBox(width: 8),
                          const Icon(Icons.arrow_forward_rounded, size: 20),
                        ],
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  // Common UI Parts like GrocerSetupScreen:
  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: GrocerTheme.primary, size: 22),
        const SizedBox(width: 10),
        Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: GrocerTheme.textDark)),
      ],
    );
  }

  Widget _buildLabeledField({required String label, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: GrocerTheme.textMuted)),
        const SizedBox(height: 8),
        child,
      ],
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool obscureText = false,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: GrocerTheme.border.withOpacity(0.2)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 3))],
      ),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
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

  Widget _buildFilePickerBtn({required String label, String? fileName, required IconData icon, required VoidCallback onTap}) {
    final hasFile = fileName != null && fileName.isNotEmpty;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: hasFile ? GrocerTheme.primary.withOpacity(0.5) : GrocerTheme.border.withOpacity(0.2)),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 3))],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: hasFile ? GrocerTheme.primary.withOpacity(0.1) : GrocerTheme.background, shape: BoxShape.circle),
              child: Icon(icon, color: hasFile ? GrocerTheme.primary : GrocerTheme.textMuted),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                  const SizedBox(height: 4),
                  Text(hasFile ? fileName : 'Sélectionner un fichier', style: TextStyle(color: hasFile ? GrocerTheme.primary : GrocerTheme.textMuted.withOpacity(0.6), fontSize: 12), overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            if (hasFile) const Icon(Icons.check_circle_rounded, color: GrocerTheme.primary),
          ],
        ),
      ),
    );
  }

  Widget _buildTimePickerCard(String time, Function(String) onTimeSelected) {
    return GestureDetector(
      onTap: () async {
        final parts = time.split(':');
        final initialTime = TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
        final selectedTime = await showTimePicker(context: context, initialTime: initialTime);
        if (selectedTime != null) {
          final h = selectedTime.hour.toString().padLeft(2, '0');
          final m = selectedTime.minute.toString().padLeft(2, '0');
          onTimeSelected('$h:$m');
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: GrocerTheme.primary.withOpacity(0.05),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: GrocerTheme.primary.withOpacity(0.15)),
        ),
        child: Text(time, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: GrocerTheme.primary, letterSpacing: 0.5)),
      ),
    );
  }
}
