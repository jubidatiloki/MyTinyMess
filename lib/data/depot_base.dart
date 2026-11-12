import 'dart:convert';

import 'package:sembast/sembast.dart';

import 'depot.dart';

/// Stockage dans la base de données locale (sembast) : une « table » par
/// clé (livres, bouteilles, lieux, preferences), un
/// enregistrement par élément, identifié par son `id`.
class DepotBase implements Depot {
  DepotBase(this._base);

  final Database _base;

  /// Informations internes (migration déjà faite…).
  static final _meta = StoreRef<String, Object?>('_meta');
  static const _cleMigration = 'repriseSharedPreferences';

  /// Champ technique qui garde l'ordre des éléments.
  static const _ordre = '_ordre';

  StoreRef<String, Map<String, Object?>> _table(String cle) =>
      stringMapStoreFactory.store(cle);

  @override
  Future<List<Map<String, dynamic>>> lire(String cle) async {
    final enregistrements = await _table(
      cle,
    ).find(_base, finder: Finder(sortOrders: [SortOrder(_ordre)]));
    return [
      for (final e in enregistrements)
        // Copie modifiable (les valeurs de la base sont en lecture seule).
        (jsonDecode(jsonEncode(e.value)) as Map<String, dynamic>)
          ..remove(_ordre),
    ];
  }

  @override
  Future<void> ecrire(String cle, List<Map<String, dynamic>> elements) async {
    final table = _table(cle);
    await _base.transaction((txn) async {
      final cles = <String>[
        for (var i = 0; i < elements.length; i++)
          elements[i]['id'] as String? ?? 'element-$i',
      ];
      // Supprime ce qui n'est plus dans la liste…
      final anciennes = await table.findKeys(txn);
      final aGarder = cles.toSet();
      final aSupprimer = anciennes.where((k) => !aGarder.contains(k));
      if (aSupprimer.isNotEmpty) {
        await table.records(aSupprimer).delete(txn);
      }
      // … et enregistre le reste dans l'ordre.
      for (var i = 0; i < elements.length; i++) {
        await table.record(cles[i]).put(txn, {...elements[i], _ordre: i});
      }
    });
  }

  /// Reprend une seule fois les données de l'ancien stockage ([ancien],
  /// versions ≤ 0.4) pour les [cles] encore vides dans la base.
  /// Renvoie le nombre d'éléments repris.
  Future<int> reprendreDepuis(Depot ancien, List<String> cles) async {
    final deja = _meta.record(_cleMigration);
    if (await deja.get(_base) != null) {
      return 0;
    }
    var total = 0;
    for (final cle in cles) {
      if ((await lire(cle)).isNotEmpty) {
        continue;
      }
      final donnees = await ancien.lire(cle);
      if (donnees.isNotEmpty) {
        await ecrire(cle, donnees);
        total += donnees.length;
      }
    }
    await deja.put(_base, DateTime.now().toIso8601String());
    return total;
  }
}
