import 'package:flutter_test/flutter_test.dart';
import 'package:goldfit_frontend/models/weather_data.dart';

void main() {
  group('WeatherData', () {
    test('creates instance with all required properties', () {
      final timestamp = DateTime.now();
      final weather = WeatherData(
        temperature: 72.5,
        condition: 'Sunny',
        location: 'San Francisco, CA',
        timestamp: timestamp,
      );

      expect(weather.temperature, 72.5);
      expect(weather.condition, 'Sunny');
      expect(weather.location, 'San Francisco, CA');
      expect(weather.timestamp, timestamp);
    });

    test('copyWith creates new instance with updated fields', () {
      final original = WeatherData(
        temperature: 68.0,
        condition: 'Cloudy',
        location: 'New York, NY',
        timestamp: DateTime.now(),
      );

      final updated = original.copyWith(
        temperature: 75.0,
        condition: 'Sunny',
      );

      expect(updated.temperature, 75.0);
      expect(updated.condition, 'Sunny');
      expect(updated.location, original.location);
      expect(updated.timestamp, original.timestamp);
    });

    test('toJson serializes all fields correctly', () {
      final timestamp = DateTime.now();
      final weather = WeatherData(
        temperature: 82.3,
        condition: 'Rainy',
        location: 'Seattle, WA',
        timestamp: timestamp,
      );

      final json = weather.toJson();

      expect(json['temperature'], 82.3);
      expect(json['condition'], 'Rainy');
      expect(json['location'], 'Seattle, WA');
      expect(json['timestamp'], timestamp.toIso8601String());
    });

    test('fromJson deserializes all fields correctly', () {
      final timestamp = DateTime.now();
      final json = {
        'temperature': 65.5,
        'condition': 'Partly Cloudy',
        'location': 'Los Angeles, CA',
        'timestamp': timestamp.toIso8601String(),
      };

      final weather = WeatherData.fromJson(json);

      expect(weather.temperature, 65.5);
      expect(weather.condition, 'Partly Cloudy');
      expect(weather.location, 'Los Angeles, CA');
      expect(weather.timestamp, timestamp);
    });

    test('toJson and fromJson round-trip preserves data', () {
      final original = WeatherData(
        temperature: 70.0,
        condition: 'Clear',
        location: 'Austin, TX',
        timestamp: DateTime.now(),
      );

      final json = original.toJson();
      final restored = WeatherData.fromJson(json);

      expect(restored.temperature, original.temperature);
      expect(restored.condition, original.condition);
      expect(restored.location, original.location);
      expect(restored.timestamp, original.timestamp);
    });

    test('equality operator works correctly', () {
      final timestamp = DateTime.now();
      final weather1 = WeatherData(
        temperature: 72.0,
        condition: 'Sunny',
        location: 'Miami, FL',
        timestamp: timestamp,
      );
      final weather2 = WeatherData(
        temperature: 72.0,
        condition: 'Sunny',
        location: 'Miami, FL',
        timestamp: timestamp,
      );
      final weather3 = WeatherData(
        temperature: 75.0,
        condition: 'Sunny',
        location: 'Miami, FL',
        timestamp: timestamp,
      );

      expect(weather1 == weather2, true);
      expect(weather1 == weather3, false);
    });

    test('hashCode is consistent with equality', () {
      final timestamp = DateTime.now();
      final weather1 = WeatherData(
        temperature: 72.0,
        condition: 'Sunny',
        location: 'Miami, FL',
        timestamp: timestamp,
      );
      final weather2 = WeatherData(
        temperature: 72.0,
        condition: 'Sunny',
        location: 'Miami, FL',
        timestamp: timestamp,
      );

      expect(weather1.hashCode, weather2.hashCode);
    });

    test('toString provides readable representation', () {
      final timestamp = DateTime.now();
      final weather = WeatherData(
        temperature: 72.0,
        condition: 'Sunny',
        location: 'Miami, FL',
        timestamp: timestamp,
      );

      final str = weather.toString();
      expect(str, contains('72.0'));
      expect(str, contains('Sunny'));
      expect(str, contains('Miami, FL'));
    });
  });
}
