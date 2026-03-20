import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:goldfit_frontend/shared/models/weather_data.dart';

/// Service to get current weather using OpenWeather API and Geolocator
class WeatherService {
  /// Fetches the current weather for the user's location.
  Future<WeatherData?> getCurrentWeather() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return null;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return null;
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      return null;
    } 

    try {
      // Get current position
      Position position = await Geolocator.getCurrentPosition();
      
      // Get precise location name via Reverse Geocoding
      String preciseLocation = 'Hanoi';
      try {
        List<Placemark> placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
        if (placemarks.isNotEmpty) {
          Placemark place = placemarks[0];
          // Use subLocality (phường/quận) and locality (thành phố)
          preciseLocation = [place.subLocality, place.locality]
              .where((s) => s != null && s.isNotEmpty)
              .join(', ');
          if (preciseLocation.isEmpty) {
            preciseLocation = place.name ?? 'Unknown Location';
          }
        }
      } catch (e) {
        print('Error in reverse geocoding: $e');
      }

      // Get API Key from .env
      final apiKey = dotenv.env['OPENWEATHER_API_KEY'];
      if (apiKey == null || apiKey == 'PLACEHOLDER_OPENWEATHER_KEY') {
        return null; // Return fallback if no valid key
      }
      
      // Call OpenWeather API
      final url = 'https://api.openweathermap.org/data/2.5/weather?lat=${position.latitude}&lon=${position.longitude}&appid=$apiKey&units=metric';
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final weather = data['weather'][0]['main'];
        final temp = (data['main']['temp'] as num).toDouble();
        
        return WeatherData(
          temperature: temp,
          condition: weather,
          location: preciseLocation,
          timestamp: DateTime.now(),
        );
      }
    } catch (e) {
      // ignore: avoid_print
      print('Error getting weather: $e');
    }
    
    return null;
  }
}
