import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' show LatLng;
import 'package:http/http.dart' as http;
import 'package:geocoding/geocoding.dart' as geo;
import '../../screens/grocer/grocer_theme.dart';

class MapPickerResult {
  final LatLng position;
  final String? address;
  MapPickerResult({required this.position, this.address});
}

class MapPickerScreen extends StatefulWidget {
  final LatLng initialPosition;
  const MapPickerScreen({super.key, required this.initialPosition});

  @override
  State<MapPickerScreen> createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends State<MapPickerScreen> with TickerProviderStateMixin {
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
                      onPressed: () => Navigator.pop(context, MapPickerResult(
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
