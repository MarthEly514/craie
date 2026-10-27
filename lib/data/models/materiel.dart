enum CategorieMateriel { rallonge, projecteur }

class Materiel {
  final String id;
  final String nom;
  final String reference;
  final CategorieMateriel categorie;
  final bool estLibre;
  final String etat;
  final bool parMoi; // réservé par le responsable connecté
  final String? debut;
  final String? fin;
  final String? motif;

  const Materiel({
    required this.id,
    required this.nom,
    required this.reference,
    required this.categorie,
    required this.estLibre,
    this.etat = 'Bon',
    this.parMoi = false,
    this.debut,
    this.fin,
    this.motif,
  });

  Materiel copyWith({
    bool? estLibre,
    bool? parMoi,
    String? debut,
    String? fin,
    String? motif,
  }) {
    return Materiel(
      id: id,
      nom: nom,
      reference: reference,
      categorie: categorie,
      etat: etat,
      estLibre: estLibre ?? this.estLibre,
      parMoi: parMoi ?? this.parMoi,
      debut: debut ?? this.debut,
      fin: fin ?? this.fin,
      motif: motif ?? this.motif,
    );
  }
}
