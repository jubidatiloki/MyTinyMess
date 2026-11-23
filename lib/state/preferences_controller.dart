import 'package:flutter/material.dart';

import '../data/depot.dart';
import '../models/section.dart';

enum ChoixTheme {
  sombre('Sombre', ThemeMode.dark),
  clair('Clair', ThemeMode.light),
  systeme('Comme l\'appareil', ThemeMode.system);

  const ChoixTheme(this.libelle, this.mode);
  final String libelle;
  final ThemeMode mode;
}

/// Préférences de l'utilisateur, enregistrées sur l'appareil.
class PreferencesController extends ChangeNotifier {
  PreferencesController(this._depot);

  static const cle = 'preferences';

  final Depot _depot;
  ChoixTheme _theme = ChoixTheme.sombre;
  Section _ecranDemarrage = Section.accueil;
  bool _menuFixe = true;
  bool _agendaCalendrier = false;
  Set<String> _replies = {};

  ChoixTheme get theme => _theme;
  Section get ecranDemarrage => _ecranDemarrage;

  /// Menu latéral toujours visible à gauche (sur les écrans assez larges).
  bool get menuFixe => _menuFixe;

  /// Agenda affiché en calendrier (mois) plutôt qu'en semaine.
  bool get agendaCalendrier => _agendaCalendrier;

  /// Groupes d'emplacements repliés sur la vue d'ensemble : nom du type
  /// (« cave ») ou identifiant d'un emplacement.
  Set<String> get replies => Set.unmodifiable(_replies);

  Future<void> charger() async {
    final donnees = await _depot.lire(cle);
    if (donnees.isNotEmpty) {
      final p = donnees.first;
      _theme = ChoixTheme.values.firstWhere(
        (t) => t.name == p['theme'],
        orElse: () => ChoixTheme.sombre,
      );
      _ecranDemarrage = Section.demarrages.firstWhere(
        (s) => s.name == p['ecranDemarrage'],
        orElse: () => Section.accueil,
      );
      _menuFixe = p['menuFixe'] as bool? ?? true;
      _agendaCalendrier = p['agendaCalendrier'] as bool? ?? false;
      _replies = {...?(p['replies'] as List?)?.cast<String>()};
    }
    notifyListeners();
  }

  Future<void> changerTheme(ChoixTheme t) async {
    _theme = t;
    await _sauver();
  }

  Future<void> changerEcranDemarrage(Section s) async {
    _ecranDemarrage = s;
    await _sauver();
  }

  Future<void> changerMenuFixe(bool fixe) async {
    _menuFixe = fixe;
    await _sauver();
  }

  Future<void> changerAgendaCalendrier(bool calendrier) async {
    _agendaCalendrier = calendrier;
    await _sauver();
  }

  Future<void> basculerRepli(String groupe) async {
    if (!_replies.remove(groupe)) {
      _replies.add(groupe);
    }
    await _sauver();
  }

  Future<void> changerReplies(Set<String> groupes) async {
    _replies = {...groupes};
    await _sauver();
  }

  Future<void> _sauver() async {
    notifyListeners();
    await _depot.ecrire(cle, [
      {
        'theme': _theme.name,
        'ecranDemarrage': _ecranDemarrage.name,
        'menuFixe': _menuFixe,
        'agendaCalendrier': _agendaCalendrier,
        'replies': _replies.toList(),
      },
    ]);
  }
}
