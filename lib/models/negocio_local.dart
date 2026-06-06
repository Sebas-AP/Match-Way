class NegocioLocal {
  final String nombre;
  final String descripcion;
  final String categoria;
  final String imagenUrl;

  NegocioLocal({
    required this.nombre,
    required this.descripcion,
    required this.categoria,
    required this.imagenUrl,
  });
}

final List<NegocioLocal> listaNegociosMock = [
  NegocioLocal(
    nombre: "Tacos de Alacrán 'El Jefe'",
    descripcion: "Sabor exótico y tradicional del centro histórico.",
    categoria: "Gastronomía",
    imagenUrl: "https://images.unsplash.com/photo-1565299585323-38d6b0865b47?auto=format&fit=crop&q=80&w=800",
  ),
  NegocioLocal(
    nombre: "Taller Cantera Viva",
    descripcion: "Artesanías talladas a mano por maestros duranguenses.",
    categoria: "Artesanía",
    imagenUrl: "https://images.unsplash.com/photo-1610715936287-6c2ab20a8bc0?auto=format&fit=crop&q=80&w=800",
  ),
  NegocioLocal(
    nombre: "Mezcalería 'Raíces'",
    descripcion: "Degustación de mezcal artesanal de Nombre de Dios.",
    categoria: "Bebidas",
    imagenUrl: "https://images.unsplash.com/photo-1514362545857-3bc16c4c7d1b?auto=format&fit=crop&q=80&w=800",
  ),
  NegocioLocal(
    nombre: "Gorditas Doña Mary",
    descripcion: "Receta familiar con guisos caseros inigualables.",
    categoria: "Gastronomía",
    imagenUrl: "https://images.unsplash.com/photo-1504674900247-0877df9cc836?auto=format&fit=crop&q=80&w=800",
  ),
];