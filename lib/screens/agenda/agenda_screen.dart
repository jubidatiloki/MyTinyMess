import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../../models/agenda.dart';
import '../../models/recette.dart';
import '../../state/cuisine.dart';
import '../../theme.dart';
import '../../widgets/communs.dart';
import '../../widgets/page.dart';
import '../repas/actions_repas.dart';
import '../repas/recette_detail_screen.dart';
import '../repas/recettes_screen.dart';

/// Rubrique « Agenda » : une semaine, avec pour chaque jour les événements
/// et les repas du midi et du soir.
class AgendaScreen extends StatefulWidget {
  const AgendaScreen({super.key, required this.cuisine, this.menu});

  final Cuisine cuisine;
  final Widget? menu;

  @override
  State<AgendaScreen> createState() => _AgendaScreenState();
}

class _AgendaScreenState extends State<AgendaScreen> {
  late DateTime _lundi = debutSemaine(DateTime.now());

  Cuisine get _c => widget.cuisine;

  /// Ajoute aux courses ce qui manque pour les repas prévus de la semaine.
  Future<void> _coursesDeLaSemaine() async {
    final noms = [
      for (final a in _c.frigo.elements)
        if (a.enStock) a.nom,
    ];
    var ajoutes = 0;
    var recettes = 0;
    for (final repas in _c.repas.entre(_lundi, 7)) {
      final r = _c.recettes.recette(repas.recetteId);
      if (r == null) {
        continue;
      }
      recettes++;
      ajoutes += await _c.courses.ajouterIngredients(
        _c.recettes.analyser(r, noms).manquants,
        origine: 'Repas : ${r.nom}',
      );
    }
    if (mounted) {
      await informer(
        context,
        recettes == 0
            ? 'Aucune recette prévue cette semaine.'
            : ajoutes == 0
            ? 'Rien à ajouter : tout est dans le frigo ou déjà sur la liste.'
            : '$ajoutes article${ajoutes > 1 ? 's' : ''} ajouté'
                  '${ajoutes > 1 ? 's' : ''} à la liste de courses.',
      );
    }
  }

  Future<void> _choisirRepas(DateTime jour, MomentRepas moment) async {
    final choix = await Navigator.push<_ChoixRepas>(
      context,
      MaterialPageRoute(
        builder: (_) => _ChoixRepasScreen(
          cuisine: _c,
          titre: '${moment.libelle}, ${jourEnLettres(jour)}',
          dejaPrevu: _c.repas.du(jour, moment) != null,
        ),
      ),
    );
    if (choix == null) {
      return;
    }
    if (choix.supprimer) {
      final r = _c.repas.du(jour, moment);
      if (r != null) {
        await _c.repas.supprimer(r.id);
      }
      return;
    }
    await _c.repas.prevoir(
      jour,
      moment,
      recette: choix.recette,
      libelle: choix.libelle,
    );
  }

  @override
  Widget build(BuildContext context) {
    final dimanche = _lundi.add(const Duration(days: 6));
    return PageOdv(
      titre: 'Agenda',
      sousTitre: 'Du ${jourCourt(_lundi)} au ${jourCourt(dimanche)}',
      menu: widget.menu,
      actions: [
        IconButton(
          tooltip: 'Courses de la semaine',
          icon: const Icon(Icons.add_shopping_cart),
          onPressed: _coursesDeLaSemaine,
        ),
      ],
      bouton: BoutonAjout(
        libelle: 'Ajouter un événement',
        onPressed: () {
          // Aujourd'hui si on regarde la semaine en cours, sinon le lundi.
          final aujourdhui = jourDe(DateTime.now());
          final cetteSemaine = debutSemaine(aujourdhui) == _lundi;
          editerEvenement(
            context,
            _c,
            jour: cetteSemaine ? aujourdhui : _lundi,
          );
        },
      ),
      corps: ListenableBuilder(
        listenable: _c.tout,
        builder: (context, _) => ListView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
          children: [
            Row(
              children: [
                IconButton(
                  tooltip: 'Semaine précédente',
                  icon: const Icon(Icons.chevron_left),
                  onPressed: () => setState(
                    () => _lundi = _lundi.subtract(const Duration(days: 7)),
                  ),
                ),
                Expanded(
                  child: Center(
                    child: TextButton(
                      onPressed: () =>
                          setState(() => _lundi = debutSemaine(DateTime.now())),
                      child: const Text('Cette semaine'),
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Semaine suivante',
                  icon: const Icon(Icons.chevron_right),
                  onPressed: () => setState(
                    () => _lundi = _lundi.add(const Duration(days: 7)),
                  ),
                ),
              ],
            ),
            for (var i = 0; i < 7; i++)
              _Jour(
                cuisine: _c,
                jour: _lundi.add(Duration(days: i)),
                onChoisirRepas: _choisirRepas,
              ),
          ],
        ),
      ),
    );
  }
}

class _Jour extends StatelessWidget {
  const _Jour({
    required this.cuisine,
    required this.jour,
    required this.onChoisirRepas,
  });

  final Cuisine cuisine;
  final DateTime jour;
  final Future<void> Function(DateTime, MomentRepas) onChoisirRepas;

  @override
  Widget build(BuildContext context) {
    final p = PaletteOdv.de(context);
    final aujourdhui = jourDe(DateTime.now()) == jourDe(jour);
    final evenements = cuisine.evenements.du(jour);
    final titre = jourEnLettres(jour);
    return Padding(
      key: Key('jour-${jour.year}-${jour.month}-${jour.day}'),
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: aujourdhui
              ? const BorderSide(color: vertOdv, width: 2)
              : BorderSide.none,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 8, 4),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${titre[0].toUpperCase()}${titre.substring(1)}'
                        '${aujourdhui ? ' · aujourd\'hui' : ''}',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: aujourdhui ? p.accentDoux : null,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Ajouter un événement ce jour',
                      icon: const Icon(Icons.add, size: 20),
                      onPressed: () =>
                          editerEvenement(context, cuisine, jour: jour),
                    ),
                  ],
                ),
              ),
              for (final e in evenements)
                ListTile(
                  dense: true,
                  leading: const Icon(Icons.event_note_outlined),
                  title: Text(e.titre),
                  subtitle: e.notes.isEmpty ? null : Text(e.notes),
                  trailing: Text(e.heure ?? 'Journée'),
                  onTap: () => editerEvenement(context, cuisine, evenement: e),
                ),
              for (final m in MomentRepas.values)
                _LigneRepas(
                  cuisine: cuisine,
                  jour: jour,
                  moment: m,
                  onChoisir: () => onChoisirRepas(jour, m),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LigneRepas extends StatelessWidget {
  const _LigneRepas({
    required this.cuisine,
    required this.jour,
    required this.moment,
    required this.onChoisir,
  });

  final Cuisine cuisine;
  final DateTime jour;
  final MomentRepas moment;
  final VoidCallback onChoisir;

  @override
  Widget build(BuildContext context) {
    final p = PaletteOdv.de(context);
    final repas = cuisine.repas.du(jour, moment);
    final recette = cuisine.recettes.recette(repas?.recetteId);
    final libelle = recette?.nom ?? repas?.libelle;
    return ListTile(
      dense: true,
      leading: Icon(
        moment == MomentRepas.midi
            ? Icons.wb_sunny_outlined
            : Icons.nightlight_outlined,
        color: p.texteSecondaire,
      ),
      title: Text(
        libelle ?? '${moment.libelle} : prévoir…',
        style: libelle == null ? TextStyle(color: p.texteSecondaire) : null,
      ),
      subtitle: libelle == null ? null : Text(moment.libelle),
      trailing: recette == null
          ? null
          : IconButton(
              tooltip: 'Voir la recette',
              icon: const Icon(Icons.menu_book_outlined),
              onPressed: () => ouvrirRecette(context, cuisine, recette),
            ),
      onTap: onChoisir,
    );
  }
}

/// Résultat du choix d'un repas.
class _ChoixRepas {
  const _ChoixRepas({this.recette, this.libelle, this.supprimer = false});

  final Recette? recette;
  final String? libelle;
  final bool supprimer;
}

/// Choix d'un repas : texte libre, propositions selon le frigo ou carnet.
class _ChoixRepasScreen extends StatefulWidget {
  const _ChoixRepasScreen({
    required this.cuisine,
    required this.titre,
    required this.dejaPrevu,
  });

  final Cuisine cuisine;
  final String titre;
  final bool dejaPrevu;

  @override
  State<_ChoixRepasScreen> createState() => _ChoixRepasScreenState();
}

class _ChoixRepasScreenState extends State<_ChoixRepasScreen> {
  final _libre = TextEditingController();
  String _texte = '';

  @override
  void dispose() {
    _libre.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.cuisine;
    final suggestions = c.recettes.suggestions(c.frigo.elements).take(5);
    final carnet = c.recettes.rechercher(texte: _texte);
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.titre, overflow: TextOverflow.ellipsis),
        actions: [
          if (widget.dejaPrevu)
            IconButton(
              tooltip: 'Retirer ce repas',
              icon: const Icon(Icons.delete_outline),
              onPressed: () =>
                  Navigator.pop(context, const _ChoixRepas(supprimer: true)),
            ),
        ],
      ),
      body: ListView(
        padding: margesCentrees(context),
        children: [
          TextField(
            key: const Key('champ-repas-libre'),
            controller: _libre,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              labelText: 'Repas libre',
              hintText: 'Restaurant, restes, pique-nique…',
              suffixIcon: IconButton(
                tooltip: 'Valider le repas libre',
                icon: const Icon(Icons.check),
                onPressed: () {
                  final t = _libre.text.trim();
                  if (t.isNotEmpty) {
                    Navigator.pop(context, _ChoixRepas(libelle: t));
                  }
                },
              ),
            ),
          ),
          if (suggestions.isNotEmpty) ...[
            const TitreSection('Avec ce qu\'il y a dans le frigo'),
            for (final s in suggestions)
              CarteLigne(
                leading: const IconeCarree(Icons.restaurant_menu),
                title: Text(s.recette.nom),
                subtitle: Text(
                  resumeSuggestion(s),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                onTap: () =>
                    Navigator.pop(context, _ChoixRepas(recette: s.recette)),
              ),
          ],
          const TitreSection('Carnet de recettes'),
          ChampRecherche(
            indice: 'Chercher une recette…',
            onChanged: (t) => setState(() => _texte = t),
          ),
          for (final r in carnet)
            CarteLigne(
              key: Key('choix-recette-${r.id}'),
              leading: const IconeCarree(Icons.menu_book_outlined),
              title: Text(r.nom),
              onTap: () => Navigator.pop(context, _ChoixRepas(recette: r)),
            ),
        ],
      ),
    );
  }
}

/// Fenêtre de création ([evenement] == null) ou de modification d'un
/// événement.
Future<void> editerEvenement(
  BuildContext context,
  Cuisine cuisine, {
  Evenement? evenement,
  DateTime? jour,
}) => showDialog<void>(
  context: context,
  builder: (_) => _DialogueEvenement(
    cuisine: cuisine,
    evenement: evenement,
    jour: jour ?? DateTime.now(),
  ),
);

class _DialogueEvenement extends StatefulWidget {
  const _DialogueEvenement({
    required this.cuisine,
    required this.jour,
    this.evenement,
  });

  final Cuisine cuisine;
  final DateTime jour;
  final Evenement? evenement;

  @override
  State<_DialogueEvenement> createState() => _DialogueEvenementState();
}

class _DialogueEvenementState extends State<_DialogueEvenement> {
  late final _titre = TextEditingController(text: widget.evenement?.titre);
  late final _notes = TextEditingController(text: widget.evenement?.notes);
  late DateTime _date = widget.evenement?.date ?? jourDe(widget.jour);
  late String? _heure = widget.evenement?.heure;
  String? _erreur;

  @override
  void dispose() {
    _titre.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _valider() async {
    if (_titre.text.trim().isEmpty) {
      setState(() => _erreur = 'Donnez un titre');
      return;
    }
    await widget.cuisine.evenements.enregistrer(
      Evenement(
        id: widget.evenement?.id ?? const Uuid().v4(),
        titre: _titre.text.trim(),
        date: _date,
        heure: _heure,
        notes: _notes.text.trim(),
      ),
    );
    if (mounted) {
      Navigator.pop(context);
    }
  }

  Future<void> _supprimer() async {
    await widget.cuisine.evenements.supprimer(widget.evenement!.id);
    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.evenement == null ? 'Nouvel événement' : 'Modifier l\'événement',
      ),
      content: SizedBox(
        width: 380,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              key: const Key('champ-titre-evenement'),
              controller: _titre,
              autofocus: true,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: 'Titre',
                hintText: 'Dîner chez Paul, dentiste…',
                errorText: _erreur,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.event_outlined),
                    label: Text(jourCourt(_date)),
                    onPressed: () async {
                      final d = await showDatePicker(
                        context: context,
                        initialDate: _date,
                        firstDate: DateTime(_date.year - 2),
                        lastDate: DateTime(_date.year + 5),
                      );
                      if (d != null) {
                        setState(() => _date = d);
                      }
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.schedule),
                    label: Text(_heure ?? 'Journée'),
                    onPressed: () async {
                      final t = await showTimePicker(
                        context: context,
                        initialTime: const TimeOfDay(hour: 12, minute: 0),
                      );
                      if (t != null) {
                        setState(
                          () => _heure =
                              '${t.hour.toString().padLeft(2, '0')}:'
                              '${t.minute.toString().padLeft(2, '0')}',
                        );
                      }
                    },
                  ),
                ),
                if (_heure != null)
                  IconButton(
                    tooltip: 'Toute la journée',
                    icon: const Icon(Icons.close),
                    onPressed: () => setState(() => _heure = null),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _notes,
              minLines: 1,
              maxLines: 4,
              decoration: const InputDecoration(labelText: 'Notes'),
            ),
          ],
        ),
      ),
      actions: [
        if (widget.evenement != null)
          TextButton(onPressed: _supprimer, child: const Text('Supprimer')),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        FilledButton(
          key: const Key('valider-evenement'),
          onPressed: _valider,
          child: const Text('Enregistrer'),
        ),
      ],
    );
  }
}
