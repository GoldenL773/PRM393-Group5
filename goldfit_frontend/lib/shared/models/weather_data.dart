import 'package:goldfit_frontend/shared/models/clothing_item.dart';

/// Weather data model for displaying current weather conditions
class WeatherData {
  final double temperature;
  final String condition;
  final String location;
  final DateTime timestamp;
  final bool isDay;
  final Season season;

  WeatherData({
    required this.temperature,
    required this.condition,
    required this.location,
    required this.timestamp,
    this.isDay = true,
    this.season = Season.summer,
  });

  /// Create a copy with modified fields
  WeatherData copyWith({
    double? temperature,
    String? condition,
    String? location,
    DateTime? timestamp,
    bool? isDay,
    Season? season,
  }) {
    return WeatherData(
      temperature: temperature ?? this.temperature,
      condition: condition ?? this.condition,
      location: location ?? this.location,
      timestamp: timestamp ?? this.timestamp,
      isDay: isDay ?? this.isDay,
      season: season ?? this.season,
    );
  }

  /// Convert to JSON for serialization
  Map<String, dynamic> toJson() {
    return {
      'temperature': temperature,
      'condition': condition,
      'location': location,
      'timestamp': timestamp.toIso8601String(),
      'isDay': isDay,
      'season': season.toString().split('.').last,
    };
  }

  /// Create from JSON
  factory WeatherData.fromJson(Map<String, dynamic> json) {
    return WeatherData(
      temperature: (json['temperature'] as num?)?.toDouble() ?? 20.0,
      condition: json['condition'] as String? ?? 'Sunny',
      location: json['location'] as String? ?? 'Unknown',
      timestamp: json['timestamp'] != null 
          ? DateTime.parse(json['timestamp'] as String)
          : DateTime.now(),
      isDay: json['isDay'] as bool? ?? true,
      season: Season.values.firstWhere(
        (s) => s.toString().split('.').last == json['season'],
        orElse: () => Season.summer,
      ),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is WeatherData &&
        other.temperature == temperature &&
        other.condition == condition &&
        other.location == location &&
        other.timestamp == timestamp;
  }

  @override
  int get hashCode {
    return Object.hash(temperature, condition, location, timestamp);
  }

  @override
  String toString() {
    return 'WeatherData(temperature: $temperature, condition: $condition, location: $location, timestamp: $timestamp)';
  }
}
