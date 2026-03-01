/// Weather data model for displaying current weather conditions
class WeatherData {
  final double temperature;
  final String condition;
  final String location;
  final DateTime timestamp;

  WeatherData({
    required this.temperature,
    required this.condition,
    required this.location,
    required this.timestamp,
  });

  /// Create a copy with modified fields
  WeatherData copyWith({
    double? temperature,
    String? condition,
    String? location,
    DateTime? timestamp,
  }) {
    return WeatherData(
      temperature: temperature ?? this.temperature,
      condition: condition ?? this.condition,
      location: location ?? this.location,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  /// Convert to JSON for serialization
  Map<String, dynamic> toJson() {
    return {
      'temperature': temperature,
      'condition': condition,
      'location': location,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  /// Create from JSON
  factory WeatherData.fromJson(Map<String, dynamic> json) {
    return WeatherData(
      temperature: (json['temperature'] as num).toDouble(),
      condition: json['condition'] as String,
      location: json['location'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
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
