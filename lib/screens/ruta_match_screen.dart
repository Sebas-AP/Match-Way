import 'package:flutter/material.dart';
import 'package:appinio_swiper/appinio_swiper.dart';
import '../models/negocio_local.dart';
import '../theme/app_colors.dart';
import '../widgets/match_card.dart';
import '../services/ai_service.dart';
import '../services/firebase_service.dart';
import 'mapa_ruta_screen.dart';

class RutaMatchScreen extends StatefulWidget {
  const RutaMatchScreen({super.key});
  @override
  State<RutaMatchScreen> createState() => _RutaMatchScreenState();
}

class _RutaMatchScreenState extends State<RutaMatchScreen> {
  final AppinioSwiperController controller = AppinioSwiperController();
  final AIService _aiService = AIService();
  final FirebaseService _firebaseService = FirebaseService();
  
  List<NegocioLocal> tarjetas = [];
  List<NegocioLocal> matches = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    try {
      List<NegocioLocal> data = await _firebaseService.getNegocios();
      setState(() {
        tarjetas = data.reversed.toList();
        isLoading = false;
      });
    } catch (e) {
      print("Error cargando Firebase: $e");
      setState(() => isLoading = false);
    }
  }

  void _onSwipe(int prev, int? curr, SwiperActivity activity) {
    if (activity is Swipe && activity.direction == AxisDirection.right) {
      matches.add(tarjetas[prev]);
    }
    if (curr == null || curr == 0) _mostrarResultado();
  }

  void _mostrarResultado() async {
    showDialog(
      context: context, 
      barrierDismissible: false,
      builder: (_) => const AlertDialog(
        backgroundColor: TierraColors.crema,
        elevation: 10,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: TierraColors.terracota),
            SizedBox(height: 20),
            Text("Analizando tus gustos...\nTrazando ruta por Durango 📍", textAlign: TextAlign.center, style: TextStyle(color: TierraColors.chocolate, fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
      )
    );

    String res = await _aiService.generarRutaDescrita(matches);
    if (mounted) Navigator.pop(context);

    if (mounted) {
      showModalBottomSheet(
        context: context,
        backgroundColor: TierraColors.crema,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
        builder: (_) => Padding(
          padding: const EdgeInsets.all(30),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Ruta Match IA 🪄", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 15),
              Text(res, textAlign: TextAlign.center),
              const SizedBox(height: 25),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: TierraColors.agave, minimumSize: const Size(double.infinity, 50)),
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MapaRutaScreen())),
                child: const Text("Ver Mapa", style: TextStyle(color: Colors.white)),
              )
            ],
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TierraColors.crema,
      appBar: AppBar(title: const Text("Ruta Match", style: TextStyle(fontWeight: FontWeight.bold)), centerTitle: true, backgroundColor: Colors.transparent),
      body: isLoading 
        ? const Center(child: CircularProgressIndicator(color: TierraColors.terracota))
        : tarjetas.isEmpty
            ? const Center(child: Text("Cargando negocios del barrio..."))
            : Column(
                children: [
                  Expanded(child: AppinioSwiper(controller: controller, cardCount: tarjetas.length, onSwipeEnd: _onSwipe, cardBuilder: (context, i) => MatchCard(negocio: tarjetas[i]))),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        FloatingActionButton(onPressed: () => controller.swipeLeft(), backgroundColor: Colors.white, child: const Icon(Icons.close, color: Colors.grey)),
                        const SizedBox(width: 40),
                        FloatingActionButton(onPressed: () => controller.swipeRight(), backgroundColor: TierraColors.terracota, child: const Icon(Icons.favorite, color: Colors.white)),
                      ],
                    ),
                  )
                ],
              ),
    );
  }
}