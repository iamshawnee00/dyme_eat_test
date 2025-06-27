import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

// A simple service to handle location fetching and permissions.
class LocationService {
  Future<Position> getCurrentPosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error(
          'Location permissions are permanently denied, we cannot request permissions.');
    }

    return await Geolocator.getCurrentPosition();
  }
}

// A simple provider for our new service.
final locationServiceProvider = Provider<LocationService>((ref) {
  return LocationService();
});

// A FutureProvider that will fetch the user's current location.
// The .autoDispose keeps it from holding onto the location when not needed.
final userLocationProvider = FutureProvider.autoDispose<Position>((ref) async {
  return ref.read(locationServiceProvider).getCurrentPosition();
});
