import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'agent_panel.dart';
import 'agent_service.dart';

void main() {
  runApp(const MapsApp());
}

class MapsApp extends StatelessWidget {
  const MapsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DurangoGuía',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const MapScreen(),
    );
  }
}

// Modelo interno para marcadores del mapa
class _MapPlace {
  final String id;
  final String title;
  final String description;
  final LatLng position;

  const _MapPlace({
    required this.id,
    required this.title,
    required this.description,
    required this.position,
  });

  double distanceTo(LatLng other) {
    const r = 6371000.0;
    final dLat = _rad(other.latitude - position.latitude);
    final dLng = _rad(other.longitude - position.longitude);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_rad(position.latitude)) *
            cos(_rad(other.latitude)) *
            sin(dLng / 2) *
            sin(dLng / 2);
    return r * 2 * atan2(sqrt(a), sqrt(1 - a));
  }

  static double _rad(double deg) => deg * pi / 180;

  factory _MapPlace.fromJson(Map<String, dynamic> json) => _MapPlace(
        id: json['id'] as String,
        title: json['title'] as String,
        description: json['description'] as String? ?? '',
        position: LatLng(
          (json['lat'] as num).toDouble(),
          (json['lng'] as num).toDouble(),
        ),
      );
}

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  GoogleMapController? _mapController;
  final Set<Marker> _markers = {};
  final List<_MapPlace> _allPlaces = [];
  final TextEditingController _jsonController = TextEditingController();

  LatLng? _userLocation;
  double _radiusKm = 10.0;
  bool _loadingLocation = true;
  String? _locationError;

  @override
  void initState() {
    super.initState();
    _initLocation();
  }

  Future<void> _initLocation() async {
    setState(() {
      _loadingLocation = true;
      _locationError = null;
    });
    try {
      final pos = await _determinePosition();
      setState(() {
        _userLocation = LatLng(pos.latitude, pos.longitude);
        _loadingLocation = false;
      });
      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(_userLocation!, 13),
      );
      _refreshMarkers();
    } catch (e) {
      setState(() {
        _loadingLocation = false;
        _locationError = e.toString();
      });
    }
  }

  Future<Position> _determinePosition() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw Exception('Servicio de ubicación desactivado.');
    }
    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
      if (perm == LocationPermission.denied) {
        throw Exception('Permiso de ubicación denegado.');
      }
    }
    if (perm == LocationPermission.deniedForever) {
      throw Exception('Permiso denegado permanentemente.');
    }
    return Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
  }

  void _refreshMarkers() {
    if (_userLocation == null) return;
    final nearby = _allPlaces.where(
      (p) => p.distanceTo(_userLocation!) <= _radiusKm * 1000,
    );

    setState(() {
      _markers.clear();
      for (final p in nearby) {
        final dist = p.distanceTo(_userLocation!);
        final label = dist < 1000
            ? '${dist.toStringAsFixed(0)} m'
            : '${(dist / 1000).toStringAsFixed(1)} km';
        _markers.add(Marker(
          markerId: MarkerId(p.id),
          position: p.position,
          infoWindow: InfoWindow(
            title: p.title,
            snippet:
                '${p.description.isNotEmpty ? '${p.description} · ' : ''}$label',
          ),
        ));
      }
    });
  }

  // ─── Integración con el agente ───────────────────────────────────────────

  void _openAgentPanel() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => AgentPanel(onPlaceSelected: _onAgentPlaceSelected),
    );
  }

  void _onAgentPlaceSelected(PlaceRecommendation place) {
    final latLng = LatLng(place.lat, place.lng);

    setState(() {
      _markers.removeWhere((m) => m.markerId.value == 'agent_selected');
      _markers.add(Marker(
        markerId: const MarkerId('agent_selected'),
        position: latLng,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        infoWindow: InfoWindow(
          title: place.title,
          snippet: place.description,
        ),
      ));
    });

    _mapController?.animateCamera(CameraUpdate.newLatLngZoom(latLng, 16));

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.place, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Expanded(child: Text('${place.title} marcado en el mapa')),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.blue.shade700,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // ─── JSON manual (para cuando llegue la BD) ──────────────────────────────

  void _addPlacesFromJson(String jsonInput) {
    try {
      final data = jsonDecode(jsonInput);
      final List<dynamic> raw =
          data is List ? data : (data['places'] as List<dynamic>? ?? [data]);
      final places =
          raw.map((e) => _MapPlace.fromJson(e as Map<String, dynamic>)).toList();
      setState(() {
        _allPlaces
          ..clear()
          ..addAll(places);
      });
      _refreshMarkers();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${places.length} lugar(es) cargados')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Error JSON: $e'),
            backgroundColor: Colors.red),
      );
    }
  }

  void _showJsonInput() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          left: 16, right: 16, top: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Cargar lugares (JSON)',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            const Text(
              '[{"id":"1","title":"Lugar","description":"Desc","lat":-24.0,"lng":-104.6}]',
              style: TextStyle(fontSize: 11, color: Colors.grey),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _jsonController,
              maxLines: 5,
              decoration: const InputDecoration(border: OutlineInputBorder()),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _addPlacesFromJson(_jsonController.text);
                _jsonController.clear();
              },
              child: const Text('Cargar en el mapa'),
            ),
          ],
        ),
      ),
    );
  }

  void _showRadiusDialog() {
    double tmp = _radiusKm;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, set) => AlertDialog(
          title: const Text('Radio de búsqueda'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('${tmp.toStringAsFixed(0)} km'),
              Slider(
                value: tmp,
                min: 1,
                max: 50,
                divisions: 49,
                onChanged: (v) => set(() => tmp = v),
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancelar')),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                setState(() => _radiusKm = tmp);
                _refreshMarkers();
              },
              child: const Text('Aplicar'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _mapController?.dispose();
    _jsonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final center = _userLocation ?? const LatLng(24.0277, -104.6532);

    return Scaffold(
      appBar: AppBar(
        title: const Text('DurangoGuía'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.radar),
            tooltip: 'Radio',
            onPressed: _showRadiusDialog,
          ),
          IconButton(
            icon: const Icon(Icons.upload_file),
            tooltip: 'Cargar JSON',
            onPressed: _showJsonInput,
          ),
          IconButton(
            icon: const Icon(Icons.my_location),
            tooltip: 'Mi ubicación',
            onPressed: _initLocation,
          ),
        ],
      ),
      body: Stack(
        children: [
          GoogleMap(
            onMapCreated: (c) {
              _mapController = c;
              if (_userLocation != null) {
                c.animateCamera(CameraUpdate.newLatLngZoom(_userLocation!, 13));
              }
            },
            initialCameraPosition: CameraPosition(target: center, zoom: 13),
            markers: _markers,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: true,
          ),

          // Spinner de ubicación
          if (_loadingLocation)
            Positioned(
              top: 16,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: const [
                      BoxShadow(color: Colors.black26, blurRadius: 4)
                    ],
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      SizedBox(width: 8),
                      Text('Obteniendo ubicación...'),
                    ],
                  ),
                ),
              ),
            ),

          // Error de ubicación
          if (_locationError != null)
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.location_off, color: Colors.red, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                        child: Text(_locationError!,
                            style: const TextStyle(fontSize: 12))),
                    TextButton(
                        onPressed: _initLocation,
                        child: const Text('Reintentar')),
                  ],
                ),
              ),
            ),

          // Info chip
          if (_userLocation != null && !_loadingLocation)
            Positioned(
              top: 16,
              left: 16,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: const [
                    BoxShadow(color: Colors.black26, blurRadius: 4)
                  ],
                ),
                child: Text(
                  _markers.isEmpty
                      ? 'Sin lugares cargados'
                      : '${_markers.length} lugar(es) · ${_radiusKm.toStringAsFixed(0)} km',
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 12),
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'agent_fab',
        onPressed: _openAgentPanel,
        icon: const Icon(Icons.smart_toy_outlined),
        label: const Text('Agente Guía'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
      ),
    );
  }
}
