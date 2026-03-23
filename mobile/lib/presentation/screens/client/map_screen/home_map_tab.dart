import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../../../../providers/store_provider.dart';
import '../../../../core/constants/api_constants.dart';
import '../store_details_screen.dart';
import '../../../../screens/auth/welcome_screen.dart';
import '../../../../providers/auth_provider.dart';

class HomeMapTab extends StatefulWidget {
  const HomeMapTab({super.key});

  @override
  State<HomeMapTab> createState() => _HomeMapTabState();
}

class _HomeMapTabState extends State<HomeMapTab> {
  LatLng? _currentPosition;
  bool _isLoadingLocation = true;
  String _locationError = '';
  final MapController _mapController = MapController();
  final PageController _pageController = PageController(viewportFraction: 0.85);
  int _selectedStoreIndex = -1;
  bool _isSatellite = false;

  @override
  void initState() {
    super.initState();
    _determinePosition();
  }

  Future<void> _determinePosition() async {
    setState(() {
      _isLoadingLocation = true;
      _locationError = '';
    });

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Les services de localisation sont désactivés.');
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('La permission de localisation a été refusée.');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception(
            'Les permissions de localisation sont refusées de façon permanente.');
      }

      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );

      if (mounted) {
        setState(() {
          _currentPosition = LatLng(position.latitude, position.longitude);
          _isLoadingLocation = false;
        });

        // Update the provider with the location so distances can be calculated
        final storeProvider = context.read<StoreProvider>();
        storeProvider.setClientLocation(position.latitude, position.longitude);
        storeProvider.fetchStores();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _locationError = e.toString().replaceAll('Exception: ', '');
          _isLoadingLocation = false;
        });
        
        // S'assurer de charger les magasins même si la localisation échoue ou est refusée
        context.read<StoreProvider>().fetchStores();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingLocation) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: Color(0xFF2D5016)),
            SizedBox(height: 16),
            Text('Recherche de votre position...'),
          ],
        ),
      );
    }

    if (_locationError.isNotEmpty && _currentPosition == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.location_off_rounded, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              const Text(
                'Impossible d\'afficher la carte',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                _locationError,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _determinePosition,
                icon: const Icon(Icons.refresh),
                label: const Text('Réessayer'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2D5016),
                  foregroundColor: Colors.white,
                ),
              )
            ],
          ),
        ),
      );
    }

    // Default center to Casablanca if something goes wrong but we still want to show map
    final center = _currentPosition ?? const LatLng(33.5731, -7.5898);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
          child: Row(
            children: [
              Consumer<AuthProvider>(
                builder: (context, auth, _) {
                  if (auth.isLoggedIn) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: GestureDetector(
                      onTap: () {
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(builder: (context) => const WelcomeScreen()),
                          (route) => false,
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2D5016).withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.arrow_back_rounded,
                          color: Color(0xFF2D5016),
                          size: 20,
                        ),
                      ),
                    ),
                  );
                },
              ),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Trouver un épicier',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2D5016),
                      ),
                    ),
                    Text(
                      'Proche de chez vous',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.12),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                )
              ],
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(26),
              child: Stack(
                children: [
                  FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: center,
                      initialZoom: 14.0,
                      onTap: (_, __) {
                        setState(() {
                          _selectedStoreIndex = -1;
                        });
                      },
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: (_isSatellite == true) 
                          ? 'https://mt1.google.com/vt/lyrs=y&x={x}&y={y}&z={z}'
                          : 'https://mt1.google.com/vt/lyrs=m&x={x}&y={y}&z={z}',
                        userAgentPackageName: 'com.myhanut.app',
                        maxZoom: 20,
                      ),
                      Consumer<StoreProvider>(
                        builder: (context, storeProvider, child) {
                          final markers = <Marker>[];

                          // Client position marker
                          if (_currentPosition != null) {
                            markers.add(
                              Marker(
                                point: _currentPosition!,
                                width: 60,
                                height: 60,
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    Container(
                                      width: 22,
                                      height: 22,
                                      decoration: BoxDecoration(
                                        color: Colors.blue.withOpacity(0.2),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    Container(
                                      width: 14,
                                      height: 14,
                                      decoration: const BoxDecoration(
                                        color: Colors.blue,
                                        shape: BoxShape.circle,
                                        border: Border.fromBorderSide(BorderSide(color: Colors.white, width: 2.5)),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }

                          // Store markers (using filteredStores for search support)
                          final stores = storeProvider.filteredStores;
                          for (int i = 0; i < stores.length; i++) {
                            final store = stores[i];
                            if (store.latitude != null && store.longitude != null) {
                              final isSelected = _selectedStoreIndex == i;
                              markers.add(
                                Marker(
                                  point: LatLng(store.latitude!, store.longitude!),
                                  width: isSelected ? 100 : 64,
                                  height: isSelected ? 100 : 64,
                                  rotate: true,
                                  child: GestureDetector(
                                    onTap: () {
                                      if (isSelected) {
                                        // Second tap or tap while selected -> navigate to details
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => StoreDetailsScreen(storeId: store.id),
                                          ),
                                        );
                                      } else {
                                        // First tap -> select and center
                                        setState(() {
                                          _selectedStoreIndex = i;
                                        });
                                        _mapController.move(
                                          LatLng(store.latitude!, store.longitude!),
                                          15.0,
                                        );
                                        _pageController.animateToPage(
                                          i,
                                          duration: const Duration(milliseconds: 300),
                                          curve: Curves.easeInOut,
                                        );
                                      }
                                    },
                                    child: AnimatedScale(
                                      scale: isSelected ? 1.25 : 1.0,
                                      duration: const Duration(milliseconds: 250),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(9),
                                            decoration: BoxDecoration(
                                              color: (store.isOpen == true) ? const Color(0xFF2D5016) : Colors.grey,
                                              borderRadius: BorderRadius.circular(14),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black.withOpacity(0.25),
                                                  blurRadius: 10,
                                                  offset: const Offset(0, 4),
                                                )
                                              ],
                                            ),
                                            child: const Icon(Icons.shopping_basket_rounded, color: Colors.white, size: 26),
                                          ),
                                          if (isSelected)
                                            Container(
                                              margin: const EdgeInsets.only(top: 5),
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                              constraints: const BoxConstraints(maxWidth: 90),
                                              decoration: BoxDecoration(
                                                color: Colors.white,
                                                borderRadius: BorderRadius.circular(6),
                                                boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4)],
                                              ),
                                              child: Text(
                                                store.nomBoutique,
                                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }
                          }

                          return MarkerLayer(markers: markers);
                        },
                      ),
                    ],
                  ),
                  
                  // Top Search Bar Overlay
                  Positioned(
                    top: 16,
                    left: 16,
                    right: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(25),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          )
                        ],
                      ),
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: 'Rechercher un épicier...',
                          hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                          border: InputBorder.none,
                          icon: const Icon(Icons.search, color: Color(0xFF2D5016), size: 20),
                        ),
                        onChanged: (val) {
                          context.read<StoreProvider>().updateFilters(search: val);
                        },
                      ),
                    ),
                  ),

                  // Floating Action Buttons
                  Positioned(
                    right: 16,
                    bottom: 170,
                    child: Column(
                      children: [
                        _buildFloatingButton(
                          icon: (_isSatellite == true) ? Icons.map_rounded : Icons.satellite_alt_rounded,
                          onPressed: () => setState(() => _isSatellite = !(_isSatellite == true)),
                        ),
                        const SizedBox(height: 10),
                        _buildFloatingButton(
                          icon: Icons.explore_outlined,
                          onPressed: () => _mapController.rotate(0),
                        ),
                        const SizedBox(height: 10),
                        _buildFloatingButton(
                          icon: Icons.my_location,
                          onPressed: _determinePosition,
                        ),
                      ],
                    ),
                  ),

                  // Bottom Carousel
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 20,
                    child: SizedBox(
                      height: 130,
                      child: Consumer<StoreProvider>(
                        builder: (context, storeProvider, child) {
                          final stores = storeProvider.filteredStores;
                          if (stores.isEmpty) return const SizedBox();
                          
                          return PageView.builder(
                            controller: _pageController,
                            itemCount: stores.length,
                            onPageChanged: (index) {
                              setState(() {
                                _selectedStoreIndex = index;
                              });
                              final store = stores[index];
                              if (store.latitude != null && store.longitude != null) {
                                _mapController.move(
                                  LatLng(store.latitude!, store.longitude!),
                                  15.0,
                                );
                              }
                            },
                            itemBuilder: (context, index) {
                              final store = stores[index];
                              return GestureDetector(
                                onTap: () {
                                   Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => StoreDetailsScreen(storeId: store.id),
                                    ),
                                  );
                                },
                                child: Container(
                                  margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.08),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      )
                                    ],
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(12.0),
                                    child: Row(
                                      children: [
                                        Hero(
                                          tag: 'store-image-${store.id}',
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(14),
                                            child: store.imageUrl != null &&
                                                    store.imageUrl!.trim().isNotEmpty
                                              ? Image.network(
                                                  ApiConstants.formatImageUrl(store.imageUrl),
                                                  width: 75,
                                                  height: 75,
                                                  fit: BoxFit.cover,
                                                  errorBuilder: (_, __, ___) => Container(
                                                    color: Colors.grey[100],
                                                    child: const Icon(Icons.store, color: Colors.grey),
                                                  ),
                                                )
                                              : Container(
                                                  color: Colors.grey[100],
                                                  width: 75,
                                                  height: 75,
                                                  child: const Icon(Icons.store, color: Colors.grey),
                                                ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Text(
                                                store.nomBoutique,
                                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF2D5016)),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              const SizedBox(height: 3),
                                              Row(
                                                children: [
                                                  const Icon(Icons.star, color: Colors.amber, size: 14),
                                                  Text(' ${store.rating}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                                  const SizedBox(width: 10),
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                    decoration: BoxDecoration(
                                                      color: (store.isOpen == true ? Colors.green : Colors.red).withOpacity(0.1),
                                                      borderRadius: BorderRadius.circular(4),
                                                    ),
                                                    child: Text(store.isOpen == true ? 'OUVERT' : 'FERMÉ',
                                                      style: TextStyle(color: store.isOpen == true ? Colors.green[700] : Colors.red[700], fontSize: 9, fontWeight: FontWeight.bold),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 5),
                                              Text(
                                                store.adresse,
                                                style: TextStyle(color: Colors.grey[500], fontSize: 11),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFloatingButton({required IconData icon, required VoidCallback onPressed}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          customBorder: const CircleBorder(),
          child: Padding(
            padding: const EdgeInsets.all(10.0),
            child: Icon(icon, color: const Color(0xFF2D5016), size: 22),
          ),
        ),
      ),
    );
  }
}
