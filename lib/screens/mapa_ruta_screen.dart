import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class MapaRutaScreen extends StatelessWidget {
  const MapaRutaScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Mapa de Ruta")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.map_outlined, size: 100, color: TierraColors.terracota),
            const Text("Tu itinerario está listo", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text("Volver"))
          ],
        ),
      ),
    );
  }
}