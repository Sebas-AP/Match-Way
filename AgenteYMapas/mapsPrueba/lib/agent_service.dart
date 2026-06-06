import 'dart:convert';
import 'package:http/http.dart' as http;

// ⚠️  Cambia esta IP a la IP LAN de tu computadora cuando uses un dispositivo real.
// En emulador Android usa: http://10.0.2.2:8000
// En dispositivo real usa: http://<tu-ip-local>:8000  (ejecuta `ip a` o `hostname -I`)
const String kAgentBaseUrl = 'http://192.168.3.78:8000';

class AgentMessage {
  final String role; // 'user' | 'assistant'
  final String content;
  const AgentMessage({required this.role, required this.content});
  Map<String, dynamic> toJson() => {'role': role, 'content': content};
}

class PlaceRecommendation {
  final String id;
  final String title;
  final String description;
  final double lat;
  final double lng;

  const PlaceRecommendation({
    required this.id,
    required this.title,
    required this.description,
    required this.lat,
    required this.lng,
  });

  factory PlaceRecommendation.fromJson(Map<String, dynamic> json) {
    return PlaceRecommendation(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String? ?? '',
      lat: (json['lat'] as num).toDouble(),
      lng: (json['lng'] as num).toDouble(),
    );
  }
}

class AgentResponse {
  final String type; // 'message' | 'recommendations'
  final String text;
  final List<PlaceRecommendation>? places;

  const AgentResponse({required this.type, required this.text, this.places});
}

class AgentService {
  static Future<AgentResponse> sendMessage(
    String message,
    List<AgentMessage> history,
  ) async {
    final response = await http
        .post(
          Uri.parse('$kAgentBaseUrl/api/recommend'),
          headers: {'Content-Type': 'application/json; charset=utf-8'},
          body: jsonEncode({
            'message': message,
            'history': history.map((m) => m.toJson()).toList(),
          }),
        )
        .timeout(const Duration(seconds: 90));

    if (response.statusCode != 200) {
      throw Exception('Error del servidor (${response.statusCode})');
    }

    final data =
        jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    final type = data['type'] as String;
    final text = data['text'] as String;

    List<PlaceRecommendation>? places;
    if (type == 'recommendations' && data['places'] != null) {
      places = (data['places'] as List)
          .map((p) => PlaceRecommendation.fromJson(p as Map<String, dynamic>))
          .toList();
    }

    return AgentResponse(type: type, text: text, places: places);
  }
}
