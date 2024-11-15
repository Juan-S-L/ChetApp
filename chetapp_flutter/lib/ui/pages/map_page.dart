// ui/pages/map_page.dart
import 'package:flutter/material.dart';
import 'package:chetapp_flutter/ui/providers/route_provider.dart';
import 'package:chetapp_flutter/ui/widgets/search_bar_widget.dart';
import 'package:chetapp_flutter/ui/providers/user_location_provider.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final MapController _mapController = MapController();
  final UserLocationProvider _locationProvider = UserLocationProvider();
  final List<Marker> _markers = [];
  final List<Polyline> _busRoutesPolylines = [];

  final RouteProvider _routeProvider = RouteProvider();

  LatLng? _userLocation;

  //! Posición inicial del mapa en Villavicencio
  final LatLng _initialPosition = const LatLng(4.13605770622296, -73.62637989076588);

  //! Limites de Villavicencio
  final LatLngBounds _villavicencioBounds = LatLngBounds(
    const LatLng(3.9000, -74.0500), // Suroeste
    const LatLng(4.3600, -73.3500), // Noreste
  );

  @override
  void initState() {
    super.initState();
    _initializeMap();
  }

  //! Inicializar el mapa y verificar la ubicación
  Future<void> _initializeMap() async {
    try {
      await _routeProvider.cargarRutas();
      print('Rutas cargadas correctamente');
    } catch (e) {
      print('Error al cargar las rutas: $e');
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _getUserLocation();
    });
  }

  //! Obtener la ubicación del usuario
  Future<void> _getUserLocation() async {
    try {
      LatLng? location = await _locationProvider.determinePosition();
      if (location != null) {
        setState(() {
          _userLocation = location;
          _addUserMarker(_userLocation!);
          _mapController.move(_userLocation!, 15.0);
        });
      }
    } catch (e) {
      print('Error al obtener la ubicación: $e');
    }
  }

  //! Filtrar la ruta de bus más cercana al destino y calcular la ruta óptima
  Future<void> calcularRutaBusMasOptima(LatLng destino) async {
    if (_userLocation == null) return;

    List<LatLng> mejorRuta = [];
    double distanciaMinima = double.infinity;

    // Iterar sobre las rutas disponibles y encontrar la más cercana al destino
    for (List<LatLng> ruta in _routeProvider.rutasDeBus) {
      for (LatLng parada in ruta) {
        double distancia = _calcularDistancia(parada, destino);
        if (distancia < distanciaMinima) {
          distanciaMinima = distancia;
          mejorRuta = ruta;
        }
      }
    }

    if (mejorRuta.isNotEmpty) {
      // Dibujar la ruta seleccionada en el mapa
      setState(() {
        _busRoutesPolylines.clear();
        _busRoutesPolylines.add(
          Polyline(
            points: mejorRuta,
            strokeWidth: 4.0,
            color: Colors.blue,
          ),
        );
      });

      // Ahora calcula la ruta desde la ubicación del usuario hasta la parada más cercana de la ruta
      LatLng paradaMasCercana = _encontrarParadaMasCercana(mejorRuta, _userLocation!);
      await calcularRutaGraphHopper(paradaMasCercana);
    }
  }

  //! Calcular la ruta óptima con GraphHopper y dibujarla en el mapa
  Future<void> calcularRutaGraphHopper(LatLng destino) async {
    if (_userLocation == null) return;

    final String apiKey = "fe5b26cf-0f0a-4f60-8ae2-22ca2fdd6c19"; // Tu API Key de GraphHopper
    final String graphhopperUrl =
        'https://graphhopper.com/api/1/route?point=${_userLocation!.latitude},${_userLocation!.longitude}&point=${destino.latitude},${destino.longitude}&vehicle=foot&locale=es&points_encoded=false&key=$apiKey';

    try {
      final response = await http.get(Uri.parse(graphhopperUrl));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['paths'] != null && data['paths'].isNotEmpty) {
          final List<dynamic> points = data['paths'][0]['points']['coordinates'];

          // Convertir los puntos en coordenadas LatLng
          final puntosRutaOptima = points.map((point) => LatLng(point[1], point[0])).toList();

          // Dibujar la ruta en el mapa
          setState(() {
            _busRoutesPolylines.add(
              Polyline(
                points: puntosRutaOptima,
                strokeWidth: 4.0,
                color: Colors.green,
              ),
            );
          });
        }
      } else {
        print('Error en la respuesta de GraphHopper: ${response.statusCode}');
      }
    } catch (e) {
      print('Error al calcular la ruta: $e');
    }
  }

  //! Encontrar la parada más cercana al usuario
  LatLng _encontrarParadaMasCercana(List<LatLng> ruta, LatLng usuario) {
    LatLng paradaMasCercana = ruta.first;
    double distanciaMinima = _calcularDistancia(usuario, paradaMasCercana);

    for (LatLng parada in ruta) {
      double distancia = _calcularDistancia(usuario, parada);
      if (distancia < distanciaMinima) {
        distanciaMinima = distancia;
        paradaMasCercana = parada;
      }
    }

    return paradaMasCercana;
  }

  //! Calcular la distancia entre dos puntos
  double _calcularDistancia(LatLng punto1, LatLng punto2) {
    const double radioTierra = 6371000; // Radio de la Tierra en metros
    double dLat = _gradosARadianes(punto2.latitude - punto1.latitude);
    double dLon = _gradosARadianes(punto2.longitude - punto1.longitude);

    double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_gradosARadianes(punto1.latitude)) *
            cos(_gradosARadianes(punto2.latitude)) *
            sin(dLon / 2) * sin(dLon / 2);

    double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return radioTierra * c;
  }

  double _gradosARadianes(double grados) {
    return grados * pi / 180;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _initialPosition,
              initialZoom: 13.0,
              maxZoom: 18.0,
              minZoom: 11.0,
              cameraConstraint: CameraConstraint.contain(bounds: _villavicencioBounds),
              onMapReady: () {
                print("Mapa listo");
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                subdomains: const ['a', 'b', 'c'],
              ),
              PolylineLayer(
                polylines: _busRoutesPolylines,
              ),
              MarkerLayer(
                markers: _markers,
              ),
            ],
          ),
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: SearchBarWidget(onPlaceSelected: _onPlaceSelected),
          ),
          Positioned(
            bottom: 20,
            right: 20,
            child: FloatingActionButton(
              onPressed: _getUserLocation,
              child: const Icon(Icons.my_location_rounded),
            ),
          ),
        ],
      ),
    );
  }

  //! Lógica al seleccionar un lugar
  void _onPlaceSelected(double lat, double lon) {
    final LatLng destino = LatLng(lat, lon);

    print('Coordenadas del usuario: $_userLocation');
    print('Coordenadas del destino: $destino');

    if (_userLocation != null) {
      _addMarker(destino, Colors.red, "Destino");
      calcularRutaBusMasOptima(destino);
    }
  }

  //! Agregar un marcador en la ubicación del usuario
  void _addUserMarker(LatLng position) {
    setState(() {
      _markers.add(
        Marker(
          width: 80.0,
          height: 80.0,
          point: position,
          child: const Icon(
            Icons.person_pin_circle_rounded,
            color: Colors.blue,
            size: 40.0,
          ),
        ),
      );
    });
  }

  //! Agregar un marcador con color y etiqueta
  void _addMarker(LatLng position, Color color, String label) {
    setState(() {
      _markers.add(
        Marker(
          width: 80.0,
          height: 80.0,
          point: position,
          child: Column(
            children: [
              Icon(
                Icons.location_on,
                color: color,
                size: 40.0,
              ),
              Text(label, style: const TextStyle(color: Colors.black)),
            ],
          ),
        ),
      );
    });
  }
}
