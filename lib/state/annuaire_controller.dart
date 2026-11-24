import '../data/depot.dart';
import '../models/adresse.dart';
import 'collection_controller.dart';

/// L'annuaire des bonnes adresses.
class AnnuaireController extends CollectionController<Adresse> {
  AnnuaireController(Depot depot) : super(depot, cle);

  static const cle = 'annuaire';

  @override
  Adresse depuisJson(Map<String, dynamic> json) => Adresse.fromJson(json);
  @override
  Map<String, dynamic> versJson(Adresse element) => element.toJson();
  @override
  String idDe(Adresse element) => element.id;

  /// Types utilisés, dans l'ordre du modèle.
  List<TypeAdresse> get types => [
    for (final t in TypeAdresse.values)
      if (elements.any((a) => a.type == t)) t,
  ];

  /// Étiquettes utilisées (une seule fois chacune), par ordre alphabétique.
  List<String> get etiquettes {
    final vues = <String, String>{};
    for (final a in elements) {
      for (final e in a.etiquettes) {
        vues.putIfAbsent(normaliser(e), () => e);
      }
    }
    return [for (final cle in vues.keys.toList()..sort()) vues[cle]!];
  }

  Future<void> basculerFavori(String id) async {
    final a = parId(id);
    if (a != null) {
      await enregistrer(a.avecFavori(!a.favori));
    }
  }

  /// Adresses par type, favoris d'abord puis par nom.
  List<Adresse> rechercher({
    String texte = '',
    TypeAdresse? type,
    String? etiquette,
    bool favoris = false,
  }) {
    final t = normaliser(texte.trim());
    final e = etiquette == null ? null : normaliser(etiquette);
    final resultat = elements
        .where(
          (a) =>
              (type == null || a.type == type) &&
              (!favoris || a.favori) &&
              (e == null || a.etiquettes.any((x) => normaliser(x) == e)) &&
              (t.isEmpty ||
                  normaliser(
                    [
                      a.nom,
                      a.type.libelle,
                      a.description ?? '',
                      a.lieu ?? '',
                      a.telephone ?? '',
                      a.email ?? '',
                      a.site ?? '',
                      a.quand ?? '',
                      a.recommandePar ?? '',
                      a.avis,
                      ...a.etiquettes,
                    ].join(' '),
                  ).contains(t)),
        )
        .toList();
    resultat.sort((a, b) {
      if (a.type != b.type) {
        return a.type.index - b.type.index;
      }
      if (a.favori != b.favori) {
        return a.favori ? -1 : 1;
      }
      return normaliser(a.nom).compareTo(normaliser(b.nom));
    });
    return resultat;
  }
}
