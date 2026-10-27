import 'models/materiel.dart';

const materielsDemo = <Materiel>[
  Materiel(
    id: 'm1',
    nom: 'Projecteur Acer514',
    reference: 'Acer514-12V_610',
    categorie: CategorieMateriel.projecteur,
    estLibre: true,
  ),
  Materiel(
    id: 'm2',
    nom: 'Rallonge_1',
    reference: 'Rallonge 12m',
    categorie: CategorieMateriel.rallonge,
    estLibre: true,
  ),
  Materiel(
    id: 'm3',
    nom: 'Projecteur EpsonP6',
    reference: 'Epson P6-A58',
    categorie: CategorieMateriel.projecteur,
    estLibre: false,
  ),
  Materiel(
    id: 'm4',
    nom: 'Rallonge_3',
    reference: 'Rallonge 12m',
    categorie: CategorieMateriel.rallonge,
    estLibre: false,
  ),
  // Réservés par le responsable connecté (liés à l'onglet Réservations)
  Materiel(
    id: 'm5',
    nom: 'Projecteur EpsonC10',
    reference: 'Epson C10-V12',
    categorie: CategorieMateriel.projecteur,
    estLibre: false,
    parMoi: true,
    debut: '08:00',
    fin: '13:00',
    motif: 'Cours de bases de données',
  ),
  Materiel(
    id: 'm6',
    nom: 'Rallonge_5',
    reference: 'Rallonge 15m grise',
    categorie: CategorieMateriel.rallonge,
    estLibre: false,
    parMoi: true,
    debut: '08:00',
    fin: '10:00',
    motif: 'Travaux pratiques',
  ),
];