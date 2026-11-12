import '../data/depot.dart';
import '../models/livre.dart';
import 'collection_controller.dart';
import 'lieux_controller.dart';

enum FiltreLivres {
  tous('Tous'),
  aLire('À lire'),
  enCours('En cours'),
  lus('Lus'),
  souhaits('Liste de souhaits'),
  pretes('Prêtés'),
  empruntes('Empruntés');

  const FiltreLivres(this.libelle);
  final String libelle;

  bool garde(Livre l) => switch (this) {
    // « Tous » = la bibliothèque : sans la liste de souhaits.
    tous => !l.estSouhait,
    aLire => l.statut == StatutLecture.aLire,
    enCours => l.statut == StatutLecture.enCours,
    lus => l.statut == StatutLecture.lu,
    souhaits => l.estSouhait,
    pretes => l.possession == Possession.prete,
    empruntes => l.possession == Possession.emprunte,
  };
}

class BibliothequeController extends CollectionController<Livre> {
  BibliothequeController(Depot depot, {this.lieux}) : super(depot, cle);

  static const cle = 'livres';

  /// Emplacements personnalisés (communs avec la cave).
  LieuxController? lieux;

  /// Livres possédés (hors liste de souhaits).
  int get nombreLivres => elements.where((l) => !l.estSouhait).length;

  /// Livres de la liste de souhaits.
  int get nombreSouhaits => elements.where((l) => l.estSouhait).length;

  @override
  Livre depuisJson(Map<String, dynamic> json) => Livre.fromJson(json);
  @override
  Map<String, dynamic> versJson(Livre element) => element.toJson();
  @override
  String idDe(Livre element) => element.id;

  /// Chemin de l'emplacement du livre (« Salon › Étagère 2 ») ou null.
  String? emplacementDe(Livre l) => lieux?.chemin(l.lieuId);

  /// Nombre de livres dans ce lieu, y compris dans ce qu'il contient
  /// (« Salon » compte aussi les livres de ses étagères).
  int nombreDans(String lieuId) {
    final dedans = lieux?.descendantsEtSoi(lieuId) ?? {lieuId};
    return elements.where((l) => dedans.contains(l.lieuId)).length;
  }

  /// Livres correspondant à la recherche, au filtre et à l'emplacement
  /// ([lieuId] : ce lieu et tout ce qu'il contient), triés par titre.
  List<Livre> rechercher({
    String texte = '',
    FiltreLivres filtre = FiltreLivres.tous,
    String? lieuId,
  }) {
    final t = normaliser(texte.trim());
    final dansLieu = lieuId == null
        ? null
        : (lieux?.descendantsEtSoi(lieuId) ?? {lieuId});
    final resultat = elements.where((l) {
      if (!filtre.garde(l)) {
        return false;
      }
      if (dansLieu != null && !dansLieu.contains(l.lieuId)) {
        return false;
      }
      if (t.isEmpty) {
        return true;
      }
      final cible = normaliser(
        [
          l.titre,
          l.auteur,
          l.genre ?? '',
          l.isbn ?? '',
          l.personne ?? '',
          emplacementDe(l) ?? '',
        ].join(' '),
      );
      return cible.contains(t);
    }).toList();
    resultat.sort((a, b) => normaliser(a.titre).compareTo(normaliser(b.titre)));
    return resultat;
  }
}
