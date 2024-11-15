// ui/providers/bus_simulator.dart
import 'dart:async';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';

class BusSimulator {
  final List<LatLng> ruta;
  int _currentStopIndex = 0;
  late Timer _timer;

  final LatLng usuario;
  final double velocidad;

  BusSimulator(this.ruta, this.usuario, {this.velocidad = 10.0});

  //! Iniciar la simulación del movimiento del bus
  void startSimulation(void Function(LatLng, double) onUpdate) {
    _timer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (_currentStopIndex < ruta.length) {
        final currentPos = ruta[_currentStopIndex];

        //! Calcular tiempo estimado hasta el usuario desde la posición actual
        double tiempoRestante = _calcularTiempo(currentPos, usuario);

        onUpdate(currentPos, tiempoRestante);
        _currentStopIndex++;
      } else {
        _timer.cancel();
      }
    });
  }

  void stopSimulation() {
    _timer.cancel();
  }

  //! Fórmula para calcular el tiempo entre dos puntos en segundos
  double _calcularTiempo(LatLng inicio, LatLng destino) {
    double distancia = Geolocator.distanceBetween(
      inicio.latitude, inicio.longitude, 
      destino.latitude, destino.longitude,
    );
    return distancia / velocidad;
  }
}
