import 'package:google_generative_ai/google_generative_ai.dart';
import '../models/negocio_local.dart';

class AIService {
  static const String _apiKey = 'TU_API_KEY_AQUI'; // <--- PEGA TU KEY AQUÍ

  Future<String> generarRutaDescrita(List<NegocioLocal> likes) async {
    if (likes.isEmpty) return "¡Selecciona algunos lugares para crear tu ruta!";

    try {
      final model = GenerativeModel(model: 'gemini-1.5-flash', apiKey: _apiKey);
      final nombres = likes.map((n) => n.nombre).toList();
      
      final prompt = 'Actúa como guía en Durango. Crea una ruta corta y emocionante uniendo estos lugares: ${nombres.join(", ")}. Máximo 3 líneas.';
      
      final response = await model.generateContent([Content.text(prompt)]);
      return response.text?.trim() ?? "¡Ruta lista para explorar!";
    } catch (e) {
      return "Tienes una ruta increíble empezando por ${likes.first.nombre}. ¡A explorar Durango!";
    }
  }
}