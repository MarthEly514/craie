
enum TypeRessource { salle, materiel }

class Reservation {
  final String id;
  final String nom;
  final String sousTitre;
  final TypeRessource type;

  const Reservation({
    required this.id,
    required this.nom,
    required this.sousTitre,
    required this.type,
  });
}