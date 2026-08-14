import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';

void main() {
  runApp(const GpsAutocaravanaApp());
}

class GpsAutocaravanaApp extends StatelessWidget {
  const GpsAutocaravanaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GPS Autocaravana',
      theme: ThemeData(
        colorSchemeSeed: Colors.blue,
        useMaterial3: true,
      ),
      home: const MapaPrincipal(),
    );
  }
}

class MapaPrincipal extends StatefulWidget {
  const MapaPrincipal({super.key});

  @override
  State<MapaPrincipal> createState() => _MapaPrincipalState();
}

class _MapaPrincipalState extends State<MapaPrincipal> {
  final MapController _mapController = MapController();
  LatLng? _posicionActual;
  String _estado = 'Buscando tu ubicación...';

  // Málaga por defecto, hasta que tengamos la ubicación real
  static const LatLng _centroPorDefecto = LatLng(36.7213, -4.4214);

  @override
  void initState() {
    super.initState();
    _obtenerUbicacion();
  }

  Future<void> _obtenerUbicacion() async {
    try {
      setState(() => _estado = 'Comprobando servicio de GPS...');
      bool servicioActivo = await Geolocator.isLocationServiceEnabled();
      if (!servicioActivo) {
        setState(() => _estado = 'Activa el GPS del móvil para continuar');
        return;
      }

      setState(() => _estado = 'Comprobando permisos...');
      LocationPermission permiso = await Geolocator.checkPermission();
      if (permiso == LocationPermission.denied) {
        permiso = await Geolocator.requestPermission();
        if (permiso == LocationPermission.denied) {
          setState(() => _estado = 'Permiso denegado. Pulsa el botón de abajo para reintentar');
          return;
        }
      }
      if (permiso == LocationPermission.deniedForever) {
        setState(() => _estado = 'Permiso bloqueado permanentemente. Ve a Ajustes del móvil > Apps > GPS Autocaravana > Permisos > Ubicación, y actívalo a mano');
        return;
      }

      setState(() => _estado = 'Obteniendo tu posición...');
      final posicion = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
      final nuevaPosicion = LatLng(posicion.latitude, posicion.longitude);

      setState(() {
        _posicionActual = nuevaPosicion;
        _estado = '';
      });
      _mapController.move(nuevaPosicion, 15);

      // Escuchar cambios de posición en tiempo real
      Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10,
        ),
      ).listen((posicion) {
        setState(() {
          _posicionActual = LatLng(posicion.latitude, posicion.longitude);
        });
      });
    } catch (e) {
      setState(() => _estado = 'ERROR: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: const MapOptions(
              initialCenter: _centroPorDefecto,
              initialZoom: 6,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.crdrosoy.gps_autocaravana',
              ),
              if (_posicionActual != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _posicionActual!,
                      width: 40,
                      height: 40,
                      child: const Icon(
                        Icons.navigation,
                        color: Colors.blue,
                        size: 36,
                      ),
                    ),
                  ],
                ),
            ],
          ),
          if (_estado.isNotEmpty)
            Positioned(
              top: 50,
              left: 16,
              right: 16,
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(_estado, textAlign: TextAlign.center),
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (_posicionActual != null) {
            _mapController.move(_posicionActual!, 16);
          } else {
            _obtenerUbicacion();
          }
        },
        child: const Icon(Icons.my_location),
      ),
    );
  }
}
