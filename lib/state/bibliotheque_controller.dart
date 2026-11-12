import '../data/depot.dart';
import '../models/livre.dart';
import 'collection_controller.dart';

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
  BibliothequeController(Depot depot) : super(depot, cle);

  static const cle = 'livres';

  @override
  Livre depuisJson(Map<String, dynamic> json) => Livre.fromJson(json);
  @override
  Map<String, dynamic> versJson(Livre element) => element.toJson();
  @override
  String idDe(Livre element) => element.id;

  /// Livres correspondant à la recherche et au filtre, triés par titre.
  List<Livre> rechercher({
    String texte = '',
    FiltreLivres filtre = FiltreLivres.tous,
  }) {
    final t = normaliser(texte.trim());
    final resultat = elements.where((l) {
      if (!filtre.garde(l)) {
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
        ].join(' '),
      );
      return cible.contains(t);
    }).toList();
    resultat.sort((a, b) => normaliser(a.titre).compareTo(normaliser(b.titre)));
    return resultat;
  }
}
