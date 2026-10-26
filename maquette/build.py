#!/usr/bin/env python3
"""Assemble craie.god2 : les écrans de la maquette de Craie.

Usage : python3 maquette/build.py   (écrit craie.god2 à la racine du projet)
"""
import base64
import json
from pathlib import Path

RACINE = Path(__file__).resolve().parent.parent
ICI = Path(__file__).resolve().parent


# ---- Petites pièces de balisage ----------------------------------------

def ic(nom, cls=''):
    return f'<svg class="ic {cls}"><use href="#i-{nom}"/></svg>'


BARRE = (
    '<div class="barre-etat"><span>9:41</span><span class="ile"></span><span class="etat-icones">'
    + ic('signal') + ic('wifi') + ic('batterie') + '</span></div>'
)


def app(corps, cls=''):
    return f'<div class="app {cls}">{BARRE}\n{corps}\n<div class="indicateur"></div>\n</div>'


def entete(titre, retour=False, droite='', compact=False):
    gauche = f'<div class="bouton-rond" aria-label="Retour">{ic("retour")}</div>' if retour else ''
    return (f'<div class="entete{" compact" if compact else ""}">{gauche}'
            f'<h1 class="titre-ecran">{titre}</h1>{droite}</div>')


def rond(icone, label, point=False):
    p = '<span class="point"></span>' if point else ''
    return f'<div class="bouton-rond" aria-label="{label}">{ic(icone)}{p}</div>'


def corps(*parts, cls=''):
    return f'<div class="corps {cls}">' + '\n'.join(parts) + '</div>'


ROLES = {
    'adm': [('Comptes', 'groupe', 'adm-comptes'), ('Profil', 'utilisateur', 'adm-profil')],
    'ges': [('Ressources', 'salle', 'ges-salles'), ('Attributions', 'calendrier', 'ges-attributions'),
            ('Profil', 'utilisateur', 'ges-profil')],
    'res': [('Disponibilités', 'recherche', 'res-dispo'), ('Réservations', 'liste', 'res-mes'),
            ('Profil', 'utilisateur', 'res-profil')],
}


def onglets(role, actif):
    items = ''.join(
        f'<div class="onglet{" actif" if nom == actif else ""}" aria-label="{nom}">'
        f'<span class="pastille">{ic(icone)}</span><span>{nom}</span></div>'
        for nom, icone, _ in ROLES[role])
    return f'<nav class="onglets">{items}</nav>'


def segments(*items):
    """items : (libellé, actif)"""
    return '<div class="segments">' + ''.join(
        f'<div class="segment{" actif" if a else ""}">{t}</div>' for t, a in items) + '</div>'


def puces(*items, cls=''):
    """items : (libellé, état) avec état '', 'actif' ou 'pris'"""
    return f'<div class="puces {cls}">' + ''.join(
        f'<div class="puce {e}">{t}</div>' for t, e in items) + '</div>'


def jours(actif=1):
    nom = [('Lun', 26), ('Mar', 27), ('Mer', 28), ('Jeu', 29), ('Ven', 30)]
    return '<div class="jours">' + ''.join(
        f'<div class="jour{" actif" if i == actif else ""}">{n}<b>{d}</b></div>'
        for i, (n, d) in enumerate(nom)) + '</div>'


def statut(texte, cls):
    return f'<span class="statut {cls}">{texte}</span>'


def ligne(icone, titre, sous, fin='', teinte='', cls=''):
    return (f'<div class="ligne {cls}"><div class="vignette {teinte}">{ic(icone)}</div>'
            f'<div class="texte"><span class="titre">{titre}</span><span class="sous">{sous}</span></div>{fin}</div>')


def ligne_compte(initiales, nom, sous, fin, teinte=''):
    return (f'<div class="ligne"><div class="avatar {teinte}">{initiales}</div>'
            f'<div class="texte"><span class="titre">{nom}</span><span class="sous">{sous}</span></div>{fin}</div>')


def champ(libelle, valeur, icone='', fin='', etat=''):
    i = ic(icone) if icone else ''
    f = f'<span class="fin">{fin}</span>' if fin else ''
    return (f'<div class="champ"><label>{libelle}</label>'
            f'<div class="saisie {etat}">{i}<span>{valeur}</span>{f}</div></div>')


def btn(texte, cls='', icone=''):
    i = ic(icone) if icone else ''
    return f'<div class="btn {cls}">{i}{texte}</div>'


def info(k, v):
    return f'<div class="info"><span>{k}</span><span>{v}</span></div>'


def fab(texte):
    return f'<div class="fab">{ic("plus")}{texte}</div>'


def feuille(contenu):
    return f'<div class="feuille-fond"></div><div class="feuille"><div class="poignee"></div>{contenu}</div>'


def succes(icone, cls, titre, texte):
    return (f'<div class="rond-grand {cls}">{ic(icone)}</div>'
            f'<h2 class="gros-titre">{titre}</h2><p class="texte-doux">{texte}</p>')


def case(coche=False, ronde=False):
    c = ' coche' if coche else ''
    r = ' ronde' if ronde else ''
    return f'<div class="case{c}{r}">{ic("check") if coche else ""}</div>'


# ---- Les écrans --------------------------------------------------------

ECRANS = []


def L(selecteur, vers, texte=None):
    lien = {'selecteur': selecteur, 'vers': vers}
    if texte:
        lien['texte'] = texte
    return lien


def ecran(id_, nom, html, liens=(), role=None, sans_retour=False, adresse=None):
    """role : ajoute les liens de la barre d’onglets. Le retour est toujours lié."""
    tous = list(liens)
    if role:
        tous += [L(f'.onglet[aria-label="{n}"]', v) for n, _, v in ROLES[role]]
    if not sans_retour:
        tous += [L('[aria-label="Retour"]', 'retour'), L('.feuille-fond', 'retour')]
    ecran_ = {'id': id_, 'nom': nom, 'adresse': adresse or f'craie.app/{id_}', 'fenetre': True,
              'balisage': html}
    if tous:
        ecran_['liens'] = tous
    ECRANS.append(ecran_)


# 00 · Ouverture et connexion

LOGO = ('<div class="logo">Craie<svg class="trait" viewBox="0 0 200 18" preserveAspectRatio="none">'
        '<use href="#trait"/></svg></div>')

ecran('ouverture', '00 Ouverture', app(
    '<div class="ouverture-coeur">' + LOGO
    + '<p class="accroche">Les salles et le matériel, au bon créneau.</p></div>'),
    [L('.app', 'bienvenue-1')], sans_retour=True)

ACCUEILS = [
    ('salles', 'Toutes vos salles, au même endroit',
     'Retrouvez les salles de l’établissement et voyez en un coup d’œil celles qui sont libres.'),
    ('materiel', 'Le matériel qu’il vous faut',
     'Vidéoprojecteurs, rallonges, ordinateurs : réservez ce dont votre cours a besoin.'),
    ('creneaux', 'Pas de conflit, pas de doute',
     'Une salle déjà prise ne peut pas être réservée deux fois sur le même créneau.'),
]
for n, (img, titre, texte) in enumerate(ACCUEILS, 1):
    suite = f'bienvenue-{n + 1}' if n < 3 else 'connexion'
    ecran(f'bienvenue-{n}', f'0{n} Bienvenue', app(
        '<div class="accueil">'
        f'<svg class="illu" viewBox="0 0 240 200"><use href="#img-{img}"/></svg>'
        f'<h1 class="gros-titre">{titre}</h1><p>{texte}</p>'
        '<div class="progres">' + ''.join(f'<i class="{"fait" if k < n else ""}"></i>' for k in range(3)) + '</div>'
        '</div>'
        '<div class="accueil-bas">'
        + btn('Continuer' if n < 3 else 'C’est parti', 'lime') + btn('Passer', 'clair')
        + '<div class="pied-lien">Déjà un compte ? <b>Se connecter</b></div></div>'),
        [L('.btn', suite, 'Continuer' if n < 3 else 'C’est parti'), L('.btn', 'connexion', 'Passer'),
         L('.pied-lien', 'connexion')])

ecran('connexion', '04 Connexion', app(
    '<div class="connexion"><h1 class="titre-ecran">Connexion</h1>'
    + champ('', 'Adresse e-mail', 'mail', etat='vide').replace('<label></label>', '')
    + champ('', '••••••••••', 'cadenas', ic('oeil'), etat='focus').replace('<label></label>', '')
    + '<div class="lien">Mot de passe oublié ?</div>'
    + btn('Se connecter')
    + '<div class="ou"><span>ou</span></div>'
    + btn('Continuer comme administrateur', 'clair', 'bouclier')
    + btn('Continuer comme gestionnaire', 'lime', 'salle')
    + btn('Continuer comme responsable de filière', 'clair', 'utilisateur')
    + '<div class="pied-lien">Pas de compte ? Demandez-le à <b>votre administrateur</b></div></div>'),
    [L('.btn', 'res-dispo', 'Se connecter'),
     L('.btn', 'adm-comptes', 'administrateur'),
     L('.btn', 'ges-salles', 'gestionnaire'),
     L('.btn', 'res-dispo', 'responsable')], sans_retour=True)


# A · Administrateur

def profil(role, nom, initiales, fonction, mail, teinte):
    return app(
        entete('Profil')
        + corps(
            '<div style="display:flex;flex-direction:column;align-items:center;gap:8px;padding:6px 0 10px">'
            f'<div class="avatar geant {teinte}">{initiales}</div>'
            f'<span class="gros-titre" style="font-size:22px">{nom}</span>'
            f'{statut(fonction, "neutre")}</div>',
            '<div class="carte"><div class="infos">'
            + info('E-mail', mail) + info('Notifications', 'Activées') + info('Mot de passe', 'Modifier')
            + '</div></div>',
            '<div class="pousse"></div>',
            btn('Se déconnecter', 'clair', 'sortie'))
        + onglets(role, 'Profil'))


COMPTES = [
    ('PD', 'Paul Dossou', 'Gestionnaire', statut('Actif', 'libre'), 'lime'),
    ('CA', 'Carine Agbo', 'Responsable · Génie Logiciel', statut('Actif', 'libre'), ''),
    ('MS', 'Marius Sossou', 'Responsable · Intelligence Artificielle', statut('Actif', 'libre'), ''),
    ('EH', 'Estelle Houénou', 'Gestionnaire', statut('Suspendu', 'pris'), 'lime'),
    ('RL', 'Rodrigue Lawson', 'Responsable · Imagerie Médicale', statut('Actif', 'libre'), ''),
]

ecran('adm-comptes', 'A1 Comptes', app(
    entete('Comptes', droite=rond('recherche', 'Rechercher'))
    + corps(
        '<div class="tuiles"><div class="tuile lime"><b>4</b><span class="sous">Gestionnaires</span></div>'
        '<div class="tuile"><b>12</b><span class="sous">Responsables de filière</span></div></div>',
        segments(('Tous', True), ('Gestionnaires', False), ('Responsables', False)),
        '<div class="liste">' + ''.join(ligne_compte(*c) for c in COMPTES) + '</div>')
    + fab('Nouveau compte') + onglets('adm', 'Comptes')),
    [L('.fab', 'adm-nouveau'), L('.ligne', 'adm-compte')], role='adm', sans_retour=True)

ecran('adm-nouveau', 'A2 Nouveau compte', app(
    entete('Nouveau compte', retour=True, compact=True)
    + corps(
        segments(('Gestionnaire', False), ('Responsable de filière', True)),
        champ('Nom complet', 'Carine Agbo', 'utilisateur', etat='focus'),
        champ('Adresse e-mail', 'carine.agbo@ifri.edu', 'mail'),
        champ('Filière', 'Génie Logiciel', 'groupe', ic('bas')),
        champ('Mot de passe provisoire', 'craie-4827', 'cadenas', 'Générer'),
        '<div class="note">' + ic('attention') + '<span>La personne devra choisir son mot de passe à sa première connexion.</span></div>',
        '<div class="pousse"></div>',
        btn('Créer le compte'))),
    [L('.btn', 'adm-cree', 'Créer le compte')])

ecran('adm-cree', 'A3 Compte créé', app(
    corps(succes('check', 'ok', 'Compte créé',
                 'Carine Agbo peut maintenant se connecter et réserver des salles pour la filière Génie Logiciel.'),
          cls='centre')
    + '<div class="bas">' + btn('Retour aux comptes') + btn('Créer un autre compte', 'clair') + '</div>'),
    [L('.btn', 'adm-comptes', 'Retour aux comptes'), L('.btn', 'adm-nouveau', 'Créer un autre compte')],
    sans_retour=True)

FICHE_COMPTE = (
    entete('Compte', retour=True, compact=True)
    + corps(
        '<div class="carte" style="align-items:center;text-align:center;gap:8px">'
        '<div class="avatar geant">CA</div><span class="gros-titre" style="font-size:22px">Carine Agbo</span>'
        f'<span class="sous">Responsable de filière</span>{statut("Actif", "libre")}</div>',
        '<div class="carte"><div class="infos">'
        + info('E-mail', 'carine.agbo@ifri.edu') + info('Filière', 'Génie Logiciel')
        + info('Créé le', '14 sept. 2026') + info('Dernière connexion', 'Aujourd’hui, 08:12')
        + '</div></div>',
        '<div class="pousse"></div>',
        btn('Suspendre le compte', 'clair', 'pause'),
        btn('Supprimer le compte', 'contour-danger', 'corbeille')))

ecran('adm-compte', 'A4 Fiche du compte', app(FICHE_COMPTE),
      [L('.btn', 'adm-suspendre', 'Suspendre'), L('.btn', 'adm-supprimer', 'Supprimer')])

ecran('adm-suspendre', 'A5 Suspendre', app(FICHE_COMPTE + feuille(
    '<h2 class="gros-titre">Suspendre ce compte ?</h2>'
    '<p class="texte-doux" style="max-width:none">Carine Agbo ne pourra plus se connecter. '
    'Ses réservations en cours seront libérées.</p>'
    + btn('Suspendre', 'lime') + btn('Annuler', 'clair'))),
    [L('.btn', 'adm-comptes', 'Suspendre'), L('.btn', 'retour', 'Annuler')])

ecran('adm-supprimer', 'A6 Supprimer', app(FICHE_COMPTE + feuille(
    '<h2 class="gros-titre">Supprimer ce compte ?</h2>'
    '<p class="texte-doux" style="max-width:none">Cette action est définitive. '
    'L’historique des réservations est conservé.</p>'
    + btn('Supprimer définitivement', 'danger') + btn('Annuler', 'clair'))),
    [L('.btn', 'adm-comptes', 'Supprimer'), L('.btn', 'retour', 'Annuler')])

ecran('adm-profil', 'A7 Profil', profil('adm', 'Administration', 'AD', 'Administrateur', 'admin@ifri.edu', 'encre'),
      [L('.btn', 'connexion', 'Se déconnecter')], role='adm', sans_retour=True)

# G · Gestionnaire

SALLES = [
    ('A101', 'Bâtiment A · 40 places', 'Vidéoprojecteur', 'Libre', 'libre'),
    ('B204', 'Bâtiment B · 30 places', 'Vidéoprojecteur', 'Attribuée', 'attribue'),
    ('Amphi 1', 'Bâtiment C · 200 places', 'Sono, vidéoprojecteur', 'Libre', 'libre'),
    ('Labo info 2', 'Bâtiment B · 25 places', '25 postes', 'Attribuée', 'attribue'),
    ('C12', 'Bâtiment C · 35 places', 'Tableau blanc', 'Libre', 'libre'),
]
MATERIEL = [
    ('projecteur', 'Vidéoprojecteur Epson', 'N° 03 · Bon état', 'Libre', 'libre'),
    ('projecteur', 'Vidéoprojecteur BenQ', 'N° 05 · Bon état', 'Attribué', 'attribue'),
    ('prise', 'Rallonge 10 m', 'N° 07 · Bon état', 'Libre', 'libre'),
    ('prise', 'Rallonge 5 m', 'N° 11 · À réparer', 'Hors service', 'pris'),
    ('ordinateur', 'Ordinateur portable', 'N° 02 · Bon état', 'Libre', 'libre'),
]


def liste_salles(fin_statut=True):
    return '<div class="liste">' + ''.join(
        ligne('salle', n, f'{b} · {e}', statut(s, c))
        for n, b, e, s, c in SALLES) + '</div>'


def liste_materiel():
    return '<div class="liste">' + ''.join(
        ligne(i, n, d, statut(s, c), {'libre': '', 'attribue': '', 'pris': 'corail'}[c])
        for i, n, d, s, c in MATERIEL) + '</div>'


ecran('ges-salles', 'G1 Salles', app(
    entete('Ressources', droite=rond('recherche', 'Rechercher'))
    + corps(segments(('Salles', True), ('Matériel', False)), liste_salles())
    + fab('Ajouter') + onglets('ges', 'Ressources')),
    [L('.fab', 'ges-salle-nouveau'), L('.segment', 'ges-materiel', 'Matériel'), L('.ligne', 'ges-salle-fiche')],
    role='ges', sans_retour=True)

ecran('ges-materiel', 'G2 Matériel', app(
    entete('Ressources', droite=rond('recherche', 'Rechercher'))
    + corps(segments(('Salles', False), ('Matériel', True)), liste_materiel())
    + fab('Ajouter') + onglets('ges', 'Ressources')),
    [L('.fab', 'ges-materiel-nouveau'), L('.segment', 'ges-salles', 'Salles'), L('.ligne', 'ges-materiel-fiche')],
    role='ges', sans_retour=True)


def formulaire_salle(nouveau):
    return app(
        entete('Nouvelle salle' if nouveau else 'Salle B204', retour=True, compact=True)
        + corps(
            champ('Nom ou numéro', 'B204', 'salle', etat='focus' if nouveau else ''),
            champ('Capacité', '30 places', 'groupe'),
            champ('Emplacement', 'Bâtiment B · 2e étage', 'salle'),
            '<span class="titre-section">Équipements fixes</span>',
            puces(('Vidéoprojecteur', 'actif'), ('Climatisation', 'actif'), ('Tableau blanc', ''),
                  ('Prises en nombre', '')),
            '<div class="pousse"></div>',
            btn('Enregistrer la salle'),
            '' if nouveau else btn('Supprimer la salle', 'contour-danger', 'corbeille')))


ecran('ges-salle-nouveau', 'G3 Nouvelle salle', formulaire_salle(True), [L('.btn', 'ges-salles', 'Enregistrer')])
ecran('ges-salle-fiche', 'G4 Fiche salle', formulaire_salle(False),
      [L('.btn', 'ges-salles', 'Enregistrer'), L('.btn', 'ges-salles', 'Supprimer')])


def formulaire_materiel(nouveau):
    return app(
        entete('Nouveau matériel' if nouveau else 'Rallonge 10 m', retour=True, compact=True)
        + corps(
            champ('Désignation', 'Rallonge 10 m', 'prise', etat='focus' if nouveau else ''),
            '<span class="titre-section">Type</span>',
            puces(('Vidéoprojecteur', ''), ('Rallonge', 'actif'), ('Ordinateur', ''), ('Autre', '')),
            champ('Numéro d’inventaire', 'N° 07', 'liste'),
            '<span class="titre-section">État</span>',
            puces(('Bon état', 'actif'), ('À réparer', '')),
            '<div class="pousse"></div>',
            btn('Enregistrer le matériel'),
            '' if nouveau else btn('Supprimer le matériel', 'contour-danger', 'corbeille')))


ecran('ges-materiel-nouveau', 'G5 Nouveau matériel', formulaire_materiel(True),
      [L('.btn', 'ges-materiel', 'Enregistrer')])
ecran('ges-materiel-fiche', 'G6 Fiche matériel', formulaire_materiel(False),
      [L('.btn', 'ges-materiel', 'Enregistrer'), L('.btn', 'ges-materiel', 'Supprimer')])

ecran('ges-attributions', 'G7 Emploi du temps', app(
    entete('Attributions')
    + corps(
        jours(1),
        '<div class="horaire"><div class="heure">08:00</div><div class="cours">'
        '<div><span class="titre">L2 Génie Logiciel</span><br><span class="sous">Algorithmique · 36 étudiants</span></div>'
        f'<div class="attrib">{statut("Salle B204", "attribue")}{statut("Vidéoprojecteur 03", "attribue")}</div></div></div>',
        '<div class="horaire"><div class="heure">10:00</div><div class="cours a-faire">'
        '<div><span class="titre">L3 Imagerie Médicale</span><br><span class="sous">Réseaux · 28 étudiants</span></div>'
        f'<div class="attrib">{statut("À attribuer", "attribue")}</div></div></div>',
        '<div class="horaire"><div class="heure">14:00</div><div class="cours">'
        '<div><span class="titre">L1 Informatique</span><br><span class="sous">Mathématiques · 40 étudiants</span></div>'
        f'<div class="attrib">{statut("Salle A101", "attribue")}</div></div></div>',
        '<div class="horaire"><div class="heure">16:00</div><div class="cours libre"><span>Aucun cours</span></div></div>')
    + onglets('ges', 'Attributions')),
    [L('.cours.a-faire', 'ges-attribuer')], role='ges', sans_retour=True)

ecran('ges-attribuer', 'G8 Attribuer', app(
    entete('Attribuer', retour=True, compact=True)
    + corps(
        '<div class="carte encre"><span class="titre">L3 Imagerie Médicale · Réseaux</span>'
        '<span class="sous">Mardi 27 octobre · 10:00 – 12:00 · 28 étudiants</span></div>',
        '<span class="titre-section">Salle</span>',
        '<div class="liste">'
        + ligne('salle', 'A101', '40 places · Libre', case(True, True), cls='choisie')
        + ligne('salle', 'Labo info 2', '25 places · Trop petite', case(False, True), 'lime', 'eteinte')
        + '</div>',
        '<span class="titre-section">Matériel</span>',
        '<div class="liste">'
        + ligne('projecteur', 'Vidéoprojecteur Epson', 'N° 03 · Libre', case(True), cls='choisie')
        + ligne('prise', 'Rallonge 10 m', 'N° 07 · Libre', case(False))
        + '</div>',
        '<div class="pousse"></div>',
        btn('Attribuer à la classe'))),
    [L('.btn', 'ges-attribue', 'Attribuer')])

ecran('ges-attribue', 'G9 Attribué', app(
    corps(succes('check', 'ok', 'Attribution enregistrée',
                 'La salle A101 et le vidéoprojecteur 03 sont réservés à la L3 Imagerie Médicale, mardi de 10:00 à 12:00.'),
          cls='centre')
    + '<div class="bas">' + btn('Retour à l’emploi du temps') + '</div>'),
    [L('.btn', 'ges-attributions', 'Retour')], sans_retour=True)

ecran('ges-profil', 'G10 Profil', profil('ges', 'Paul Dossou', 'PD', 'Gestionnaire', 'paul.dossou@ifri.edu', 'lime'),
      [L('.btn', 'connexion', 'Se déconnecter')], role='ges', sans_retour=True)

# R · Responsable de filière


def ligne_dispo(icone, titre, sous, libre):
    return ligne(icone, titre, sous, statut('Libre' if libre else 'Pris', 'libre' if libre else 'pris'),
                 '' if libre else 'corail', '' if libre else 'eteinte')


CRENEAUX = puces(('08:00', ''), ('10:00', 'actif'), ('14:00', ''), ('16:00', ''))

ecran('res-dispo', 'R1 Disponibilités', app(
    entete('Disponibilités', droite=rond('cloche', 'Notifications', point=True))
    + corps(
        jours(1), CRENEAUX,
        segments(('Salles', True), ('Matériel', False)),
        '<div class="liste">'
        + ligne_dispo('salle', 'B204', 'Bâtiment B · 30 places', True)
        + ligne_dispo('salle', 'A101', 'Bâtiment A · 40 places', True)
        + ligne_dispo('salle', 'Amphi 1', 'Bâtiment C · 200 places', False)
        + ligne_dispo('salle', 'C12', 'Bâtiment C · 35 places', True)
        + '</div>')
    + onglets('res', 'Disponibilités')),
    [L('[aria-label="Notifications"]', 'res-notifs'), L('.segment', 'res-materiel', 'Matériel'),
     L('.ligne.eteinte', 'res-conflit'), L('.ligne', 'res-fiche')],
    role='res', sans_retour=True)

ecran('res-materiel', 'R2 Matériel disponible', app(
    entete('Disponibilités', droite=rond('cloche', 'Notifications', point=True))
    + corps(
        jours(1), CRENEAUX,
        segments(('Salles', False), ('Matériel', True)),
        '<div class="liste">'
        + ligne_dispo('projecteur', 'Vidéoprojecteur Epson', 'N° 03', True)
        + ligne_dispo('projecteur', 'Vidéoprojecteur BenQ', 'N° 05', False)
        + ligne_dispo('prise', 'Rallonge 10 m', 'N° 07', True)
        + ligne_dispo('ordinateur', 'Ordinateur portable', 'N° 02', True)
        + '</div>')
    + onglets('res', 'Disponibilités')),
    [L('[aria-label="Notifications"]', 'res-notifs'), L('.segment', 'res-dispo', 'Salles'),
     L('.ligne.eteinte', 'res-conflit'), L('.ligne', 'res-fiche-mat')],
    role='res', sans_retour=True)


def creneaux_du_jour(pris):
    return '<div class="liste">' + ''.join(
        ligne('horloge', h, 'Mardi 27 octobre',
              statut('Pris' if h in pris else 'Libre', 'pris' if h in pris else 'libre'),
              'corail' if h in pris else '', 'eteinte' if h in pris else '')
        for h in ('08:00 – 10:00', '10:00 – 12:00', '14:00 – 16:00', '16:00 – 18:00')) + '</div>'


ecran('res-fiche', 'R3 Fiche salle', app(
    entete('Salle', retour=True, compact=True)
    + corps(
        '<div class="carte encre" style="flex-direction:row;align-items:center;gap:14px">'
        f'<div class="vignette encre grand" style="background:var(--encre-2)">{ic("salle")}</div>'
        '<div style="display:flex;flex-direction:column"><span class="gros-titre">B204</span>'
        '<span class="sous">Bâtiment B · 2e étage · 30 places</span></div></div>',
        puces(('Vidéoprojecteur', ''), ('Climatisation', ''), ('Prises', '')),
        '<span class="titre-section">Mardi 27 octobre</span>',
        creneaux_du_jour({'08:00 – 10:00'}),
        '<div class="pousse"></div>',
        btn('Réserver cette salle'))),
    [L('.btn', 'res-reserver', 'Réserver')])

ecran('res-fiche-mat', 'R4 Fiche matériel', app(
    entete('Matériel', retour=True, compact=True)
    + corps(
        '<div class="carte encre" style="flex-direction:row;align-items:center;gap:14px">'
        f'<div class="vignette encre grand" style="background:var(--encre-2)">{ic("projecteur")}</div>'
        '<div style="display:flex;flex-direction:column"><span class="gros-titre" style="font-size:22px">Vidéoprojecteur Epson</span>'
        '<span class="sous">N° 03 · Bon état</span></div></div>',
        '<span class="titre-section">Mardi 27 octobre</span>',
        creneaux_du_jour({'14:00 – 16:00'}),
        '<div class="pousse"></div>',
        btn('Réserver ce matériel'))),
    [L('.btn', 'res-reserver-mat', 'Réserver')])


def reserver(salle):
    ressource = ('B204', 'Bâtiment B · 30 places', 'salle') if salle else (
        'Vidéoprojecteur Epson', 'N° 03', 'projecteur')
    ajout = ('<div class="ligne">' + case(True) +
             '<div class="texte"><span class="titre">Ajouter le vidéoprojecteur 03</span>'
             '<span class="sous">Disponible sur ce créneau</span></div></div>') if salle else ''
    return app(
        entete('Réserver', retour=True, compact=True)
        + corps(
            ligne(ressource[2], ressource[0], ressource[1]),
            champ('Date', 'Mardi 27 octobre', 'calendrier', ic('bas')),
            '<span class="titre-section">Créneau</span>',
            puces(('08:00', 'pris'), ('10:00', 'actif'), ('14:00', ''), ('16:00', '')),
            champ('Motif', 'TP Algorithmique · L2 GL', 'crayon'),
            ajout,
            '<div class="note">' + ic('horloge')
            + '<span>Pensez à libérer la ressource après usage. Sinon, elle l’est automatiquement à la fin du créneau.</span></div>',
            '<div class="pousse"></div>',
            btn('Confirmer la réservation')))


ecran('res-reserver', 'R5 Réserver une salle', reserver(True),
      [L('.puce.pris', 'res-conflit', '08:00'), L('.btn', 'res-confirme', 'Confirmer')])
ecran('res-reserver-mat', 'R6 Réserver du matériel', reserver(False),
      [L('.puce.pris', 'res-conflit', '08:00'), L('.btn', 'res-confirme', 'Confirmer')])

ecran('res-conflit', 'R7 Créneau indisponible', app(
    entete('Indisponible', retour=True, compact=True)
    + corps(
        succes('attention', 'alerte', 'Déjà réservée',
               'B204 est prise mardi de 08:00 à 10:00 par la L3 Imagerie Médicale.'),
        cls='centre')
    + '<div class="corps" style="flex:none;padding-bottom:34px">'
    '<span class="titre-section">À la place</span><div class="liste">'
    + ligne('salle', 'B204 · 10:00 – 12:00', 'Même salle, créneau suivant', statut('Libre', 'libre'))
    + ligne('salle', 'A101 · 08:00 – 10:00', 'Bâtiment A · 40 places', statut('Libre', 'libre'))
    + '</div>' + btn('Voir les disponibilités', 'clair') + '</div>'),
    [L('.btn', 'res-dispo', 'Voir les disponibilités'), L('.ligne', 'res-reserver')])

ecran('res-confirme', 'R8 Réservation confirmée', app(
    corps(succes('check', 'ok', 'C’est réservé',
                 'B204 et le vidéoprojecteur 03 sont à vous mardi 27 octobre, de 10:00 à 12:00.'),
          cls='centre')
    + '<div class="bas">' + btn('Voir mes réservations') + btn('Retour aux disponibilités', 'clair') + '</div>'),
    [L('.btn', 'res-mes', 'Voir mes réservations'), L('.btn', 'res-dispo', 'Retour')], sans_retour=True)


def reservations(sheet=''):
    return app(
        entete('Réservations')
        + corps(
            segments(('En cours', True), ('À venir', False), ('Passées', False)),
            '<div class="carte"><div style="display:flex;gap:14px;align-items:center">'
            f'<div class="vignette">{ic("salle")}</div>'
            '<div class="texte" style="display:flex;flex-direction:column;flex:1"><span class="titre">B204 + Vidéoprojecteur 03</span>'
            '<span class="sous">Aujourd’hui · 10:00 – 12:00</span></div>'
            + statut('En cours', 'libre') + '</div>'
            '<div class="rangee"><div class="btn-petit clair">Détails</div>'
            f'<div class="btn-petit">{ic("check", "petit")}Libérer</div></div></div>',
            '<div class="carte"><div style="display:flex;gap:14px;align-items:center">'
            f'<div class="vignette lime">{ic("prise")}</div>'
            '<div class="texte" style="display:flex;flex-direction:column;flex:1"><span class="titre">Rallonge 10 m</span>'
            '<span class="sous">Aujourd’hui · 10:00 – 12:00</span></div>'
            + statut('En cours', 'libre') + '</div>'
            '<div class="rangee"><div class="btn-petit clair">Détails</div>'
            f'<div class="btn-petit">{ic("check", "petit")}Libérer</div></div></div>')
        + onglets('res', 'Réservations') + sheet)


ecran('res-mes', 'R9 Mes réservations', reservations(),
      [L('.btn-petit', 'res-liberer', 'Libérer')], role='res', sans_retour=True)

ecran('res-liberer', 'R10 Libérer', reservations(
    feuille(
        '<h2 class="gros-titre">Libérer B204 ?</h2>'
        '<p class="texte-doux" style="max-width:none">Le créneau de 10:00 à 12:00 redevient disponible '
        'pour les autres filières.</p>'
        + btn('Libérer maintenant') + btn('Garder la réservation', 'clair'))),
    [L('.btn', 'res-liberee', 'Libérer'), L('.btn', 'retour', 'Garder')], sans_retour=True)

ecran('res-liberee', 'R11 Libérée', app(
    corps(succes('check', 'ok', 'Merci, c’est libéré',
                 'B204 est de nouveau disponible pour les autres filières.'), cls='centre')
    + '<div class="bas">' + btn('Retour aux réservations') + '</div>'),
    [L('.btn', 'res-mes', 'Retour')], sans_retour=True)

ecran('res-notifs', 'R12 Notifications', app(
    entete('Notifications', retour=True, compact=True)
    + corps(
        '<div class="notif neuve"><div class="vignette lime">' + ic('horloge') + '</div>'
        '<div class="texte"><span class="titre">B204 libérée automatiquement</span>'
        '<span class="sous">Votre créneau de 08:00 à 10:00 est terminé : la salle est de nouveau disponible.</span></div>'
        '<span class="quand">Il y a 2 h</span></div>',
        '<div class="notif"><div class="vignette">' + ic('check') + '</div>'
        '<div class="texte"><span class="titre">Réservation confirmée</span>'
        '<span class="sous">B204 · mardi 27 octobre · 10:00 – 12:00.</span></div>'
        '<span class="quand">Hier</span></div>',
        '<div class="notif"><div class="vignette corail">' + ic('attention') + '</div>'
        '<div class="texte"><span class="titre">Créneau refusé</span>'
        '<span class="sous">Amphi 1 était déjà réservé mercredi à 14:00.</span></div>'
        '<span class="quand">Lun.</span></div>')),
    [])

ecran('res-profil', 'R13 Profil',
      profil('res', 'Carine Agbo', 'CA', 'Responsable · Génie Logiciel', 'carine.agbo@ifri.edu', ''),
      [L('.btn', 'connexion', 'Se déconnecter')], role='res', sans_retour=True)


# ---- Le fichier --------------------------------------------------------

def police(fichier, poids):
    donnees = base64.b64encode((RACINE / 'polices' / fichier).read_bytes()).decode()
    return (f"@font-face {{ font-family: 'WuraMi'; font-weight: {poids}; font-style: normal; font-display: block; "
            f"src: url(data:font/woff2;base64,{donnees}) format('woff2'); }}\n")


STYLES = (police('WuraMiByGemmaS.woff2', 400) + police('WuraMiByGemmaS-SemiBold.woff2', 600)
          + police('WuraMiByGemmaS-Bold.woff2', 700) + (ICI / 'craie.css').read_text(encoding='utf8'))

DOCUMENT = {
    'format': 'god2',
    'version': 1,
    'nom': 'Craie · Salles et matériel',
    'auteurs': ['Enock', 'Dieudonné', 'Ozias', 'Cédric'],
    'formats': [{'nom': 'Téléphone', 'largeur': 390, 'hauteur': 844}],
    'ecrans': ECRANS,
    'symboles': (ICI / 'symboles.svg').read_text(encoding='utf8'),
    'styles': STYLES,
    'jetons': [['--encre', 'Encre'], ['--lime', 'Citron'], ['--lime-clair', 'Citron clair'],
               ['--surface', 'Surface'], ['--fond', 'Fond'], ['--toile', 'Toile'],
               ['--discret', 'Discret'], ['--corail', 'Pris']],
    'stylesTexte': [['.logo', 'Logo'], ['.titre-ecran', 'Titre d’écran'], ['.gros-titre', 'Grand titre'],
                    ['.titre', 'Titre de ligne'], ['.sous', 'Détail'], ['.btn', 'Bouton'],
                    ['.statut', 'Statut'], ['.titre-section', 'Titre de section']],
    'calques': {
        'noms': {'ligne': 'Ligne', 'carte': 'Carte', 'btn': 'Bouton', 'btn-petit': 'Petit bouton',
                 'onglets': 'Barre d’onglets', 'onglet': 'Onglet', 'entete': 'En-tête', 'segments': 'Segments',
                 'segment': 'Segment', 'puce': 'Puce', 'statut': 'Statut', 'champ': 'Champ', 'saisie': 'Saisie',
                 'fab': 'Bouton flottant', 'feuille': 'Feuille', 'barre-etat': 'Barre d’état',
                 'vignette': 'Icône', 'avatar': 'Avatar', 'jour': 'Jour', 'note': 'Note', 'tuile': 'Tuile',
                 'notif': 'Notification', 'cours': 'Cours', 'bouton-rond': 'Bouton rond', 'logo': 'Logo'},
        'composants': ['btn', 'btn-petit', 'ligne', 'puce', 'statut', 'champ', 'segments', 'onglets', 'fab',
                       'avatar', 'carte', 'tuile', 'note', 'notif'],
        'images': ['illu'],
    },
}

sortie = RACINE / 'craie.god2'
sortie.write_text(json.dumps(DOCUMENT, ensure_ascii=False, indent=1), encoding='utf8')
print(f'{sortie} : {len(ECRANS)} écrans, {sortie.stat().st_size // 1024} Ko')
