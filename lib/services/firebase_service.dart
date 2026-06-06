import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/negocio_local.dart';

class FirebaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<List<NegocioLocal>> getNegocios() async {
    QuerySnapshot snapshot = await _db.collection('negocios').get();
    return snapshot.docs.map((doc) {
      Map data = doc.data() as Map<String, dynamic>;
      return NegocioLocal(
        nombre: data['nombre'] ?? '',
        descripcion: data['descripcion'] ?? '',
        categoria: data['categoria'] ?? 'General',
        imagenUrl: data['imagenUrl'] ?? 'https://via.placeholder.com/400x600.png',
      );
    }).toList();
  }

  Future<void> seedDatabaseIfEmpty() async {
    QuerySnapshot snapshot = await _db.collection('negocios').limit(1).get();
    
    if (snapshot.docs.isEmpty) {
      print("🗂️ Generando datos semilla en Firebase...");
      for (var negocio in listaNegociosMock) {
        await _db.collection('negocios').add({
          'nombre': negocio.nombre,
          'descripcion': negocio.descripcion,
          'categoria': negocio.categoria,
          'imagenUrl': negocio.imagenUrl,
        });
      }
      print("✅ Datos subidos a la nube.");
    }
  }
}