class Salle {
  final String id;
  final String nom;
  final String zone; // sert au filtre : 'Zone master' | 'Iran'
  final String lieu; // affiché : 'Zone master (Zogbadjè)'
  final List<String> equipements;
  final bool estLibre;
  final bool parMoi; // réservée par le responsable connecté
  final String? debut;
  final String? fin;
  final String? motif;

  const Salle({
    required this.id,
    required this.nom,
    required this.zone,
    required this.lieu,
    this.equipements = const [],
    required this.estLibre,
    this.parMoi = false,
    this.debut,
    this.fin,
    this.motif,
  });

  Salle copyWith({
    bool? estLibre,
    bool? parMoi,
    String? debut,
    String? fin,
    String? motif,
  }) {
    return Salle(
      id: id,
      nom: nom,
      zone: zone,
      lieu: lieu,
      equipements: equipements,
      estLibre: estLibre ?? this.estLibre,
      parMoi: parMoi ?? this.parMoi,
      debut: debut ?? this.debut,
      fin: fin ?? this.fin,
      motif: motif ?? this.motif,
    );
  }
}