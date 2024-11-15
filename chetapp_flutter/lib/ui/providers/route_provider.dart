// ui/providers/route_provider.dart
import 'dart:convert';
import 'dart:math';
import 'package:flutter/services.dart' show rootBundle;
import 'package:latlong2/latlong.dart';

class RouteProvider {
  List<List<LatLng>> rutasDeBus = [];

  //! Cargar rutas desde el archivo JSON
  Future<void> cargarRutas() async {
    try {
      final String response = await rootBundle.loadString('assets/json/rutas.json');
      final data = json.decode(response);

      // Mapeo correcto de las rutas y paradas
      rutasDeBus = (data['rutas'] as List<dynamic>).map<List<LatLng>>((ruta) {
        return (ruta['paradas'] as List<dynamic>).map<LatLng>((parada) {
          return LatLng(parada['lat'].toDouble(), parada['lng'].toDouble());
        }).toList();
      }).toList();

      print('Rutas cargadas: ${rutasDeBus.length}');
      for (var ruta in rutasDeBus) {
        print('Ruta: $ruta');
      }
    } catch (e) {
      print('Error al cargar rutas: $e');
    }
  }

  //! Filtrar rutas cercanas al usuario y al destino usando Haversine
  List<List<LatLng>> filtrarRutasCercanas(LatLng usuario, LatLng destino) {
    const double radioCercano = 10000.0; // Aumentamos a 10 km para pruebas

    print('Radio de búsqueda: $radioCercano metros');

    List<List<LatLng>> rutasEncontradas = rutasDeBus.where((ruta) {
      bool cercaUsuario = ruta.any((parada) {
        double distanciaUsuario = _calcularDistancia(usuario, parada);
        print('Distancia del usuario a la parada: $distanciaUsuario metros');
        return distanciaUsuario <= radioCercano;
      });

      bool cercaDestino = ruta.any((parada) {
        double distanciaDestino = _calcularDistancia(destino, parada);
        print('Distancia del destino a la parada: $distanciaDestino metros');
        return distanciaDestino <= radioCercano;
      });

      return cercaUsuario && cercaDestino;
    }).toList();

    if (rutasEncontradas.isEmpty) {
      print('No se encontraron rutas cercanas.');
    } else {
      print('Rutas encontradas: ${rutasEncontradas.length}');
    }

    return rutasEncontradas;
  }

  //! Fórmula de Haversine para calcular la distancia entre dos puntos
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

  //! Obtener rutas para OSRM
  List<LatLng> obtenerRutaParaOSRM(int indiceRuta) {
    if (indiceRuta < rutasDeBus.length) {
      return rutasDeBus[indiceRuta];
    } else {
      print('Índice de ruta fuera de rango.');
      return [];
    }
  }
}
