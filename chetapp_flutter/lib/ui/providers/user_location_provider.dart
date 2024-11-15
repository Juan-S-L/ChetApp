import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

class UserLocationProvider {
  LatLng? _userLocation;

  LatLng? get userLocation => _userLocation;

  //! Verificar permisos y obtener ubicación
  Future<LatLng?> determinePosition() async {
    LocationPermission permission = await Geolocator.checkPermission();
    
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Permiso de ubicación denegado');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error('Permiso de ubicación denegado permanentemente');
    }

    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    _userLocation = LatLng(position.latitude, position.longitude);
    return _userLocation;
  }
}
