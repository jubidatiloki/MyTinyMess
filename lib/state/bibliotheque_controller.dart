import '../data/depot.dart';
import '../models/livre.dart';
import 'collection_controller.dart';
import 'lieux_controller.dart';

enum FiltreLivres {
  tous('Tous'),
  aLire('À lire'),
  enCours('En cours'),
  lus('Lus'),
  pretes('Prêtés'),
  empruntes('Empruntés');

  const FiltreLivres(this.libelle);
  final String libelle;

  bool garde(Livre l) => switch (this) {
    tous => true,
    aLire => l.statut == StatutLecture.aLire,
    enCours => l.statut == StatutLecture.enCours,
    lus => l.statut == StatutLecture.lu,
    pretes => l.possession == Possession.prete,
    empruntes => l.possession == Possession.emprunte,
  };
}

class BibliothequeController extends CollectionController<Livre> {
  BibliothequeController(Depot depot, {this.lieux}) : super(depot, cle);

  static const cle = 'livres';

  /// Emplacements personnalisés de la bibliothèque.
  LieuxController? lieux;

  @override
  Livre depuisJson(Map<String, dynamic> json) => Livre.fromJson(json);
  @override
  Map<String, dynamic> versJson(Livre element) => element.toJson();
  @override
  String idDe(Livre element) => element.id;

  /// Chemin de l'emplacement du livre (« Salon › Étagère 2 ») ou null.
  String? emplacementDe(Livre l) => lieux?.chemin(l.lieuId);

  /// Nombre de livres rangés directement dans ce lieu.
  int nombreDans(String lieuId) =>
      elements.where((l) => l.lieuId == lieuId).length;

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
