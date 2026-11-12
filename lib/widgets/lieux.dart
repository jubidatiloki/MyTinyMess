import 'package:flutter/material.dart';

import '../models/lieu.dart';
import '../state/lieux_controller.dart';

/// Ouvre la fenêtre de création ([lieu] == null) ou de modification d'un
/// emplacement. Renvoie le lieu enregistré, ou null si on annule.
/// [type] : type imposé (depuis un formulaire de livre ou de vin) ; sinon,
/// pour un nouvel emplacement de premier niveau, la fenêtre le demande.
Future<Lieu?> editerLieu(
  BuildContext context,
  LieuxController lieux, {
  Lieu? lieu,
  String? parentId,
  TypeLieu? type,
}) => showDialog<Lieu>(
  context: context,
  builder: (_) => _DialogueLieu(
    lieux: lieux,
    lieu: lieu,
    parentInitial: parentId,
    typeImpose: type,
  ),
);

class _DialogueLieu extends StatefulWidget {
  const _DialogueLieu({
    required this.lieux,
    this.lieu,
    this.parentInitial,
    this.typeImpose,
  });

  final LieuxController lieux;
  final Lieu? lieu;
  final String? parentInitial;
  final TypeLieu? typeImpose;

  @override
  State<_DialogueLieu> createState() => _DialogueLieuState();
}

class _DialogueLieuState extends State<_DialogueLieu> {
  late final _nom = TextEditingController(text: widget.lieu?.nom);
  late String? _parent = widget.lieu?.parentId ?? widget.parentInitial;
  late TypeLieu _type = _typeInitial();
  String? _erreur;

  TypeLieu _typeInitial() {
    final lieux = widget.lieux;
    final lieu = widget.lieu;
    if (lieu != null) {
      return lieux.typeDe(lieu);
    }
    final parent = lieux.parId(widget.parentInitial ?? '');
    if (parent != null) {
      return lieux.typeDe(parent);
    }
    return widget.typeImpose ?? TypeLieu.livres;
  }

  /// Le type se choisit seulement pour un nouvel emplacement de premier
  /// niveau ouvert depuis l'écran Emplacements.
  bool get _typeAuChoix =>
      widget.lieu == null &&
      widget.typeImpose == null &&
      widget.lieux.parId(widget.parentInitial ?? '') == null;

  @override
  void dispose() {
    _nom.dispose();
    super.dispose();
  }

  Future<void> _valider() async {
    final nom = _nom.text.trim();
    if (nom.isEmpty) {
      setState(() => _erreur = 'Donnez un nom');
      return;
    }
    final existant = widget.lieu;
    final Lieu resultat;
    if (existant == null) {
      resultat = await widget.lieux.creer(nom, parentId: _parent, type: _type);
    } else {
      resultat = Lieu(
        id: existant.id,
        nom: nom,
        parentId: _parent,
        type: _type,
      );
      await widget.lieux.enregistrer(resultat);
    }
    if (mounted) {
      Navigator.pop(context, resultat);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Un lieu ne peut pas être rangé dans lui-même ni dans son contenu, ni
    // dans un emplacement de l'autre type.
    final interdits = widget.lieu == null
        ? <String>{}
        : widget.lieux.descendantsEtSoi(widget.lieu!.id);
    final choix = widget.lieux
        .arbre(type: _type)
        .where((n) => !interdits.contains(n.lieu.id))
        .toList();
    if (_parent != null && !choix.any((n) => n.lieu.id == _parent)) {
      _parent = null;
    }
    return AlertDialog(
      title: Text(
        widget.lieu == null ? 'Nouvel emplacement' : 'Modifier l\'emplacement',
      ),
      content: SizedBox(
        width: 360,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_typeAuChoix) ...[
              SegmentedButton<TypeLieu>(
                key: const Key('choix-type-lieu'),
                segments: [
                  for (final t in TypeLieu.values)
                    ButtonSegment(
                      value: t,
                      label: Text('Pour les ${t.contenu}'),
                      icon: Icon(iconeTypeLieu(t)),
                    ),
                ],
                selected: {_type},
                onSelectionChanged: (s) => setState(() => _type = s.first),
              ),
              const SizedBox(height: 16),
            ] else
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Icon(iconeTypeLieu(_type), size: 18),
                    const SizedBox(width: 8),
                    Text('Pour les ${_type.contenu}'),
                  ],
                ),
              ),
            TextField(
              key: const Key('champ-nom-lieu'),
              controller: _nom,
              autofocus: true,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: 'Nom',
                hintText: 'Salon, bibliothèque, étagère 2…',
                errorText: _erreur,
              ),
              onSubmitted: (_) => _valider(),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String?>(
              key: const Key('champ-parent-lieu'),
              initialValue: _parent,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Rangé dans'),
              items: [
                const DropdownMenuItem(
                  value: null,
                  child: Text('— (premier niveau)'),
                ),
                for (final n in choix)
                  DropdownMenuItem(
                    value: n.lieu.id,
                    child: _NomIndente(noeud: n),
                  ),
              ],
              selectedItemBuilder: (context) => [
                const Text('— (premier niveau)'),
                for (final n in choix)
                  Text(
                    widget.lieux.chemin(n.lieu.id) ?? n.lieu.nom,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
              onChanged: (v) => setState(() => _parent = v),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        FilledButton(
          key: const Key('valider-lieu'),
          onPressed: _valider,
          child: const Text('Enregistrer'),
        ),
      ],
    );
  }
}

/// Nom d'un lieu décalé selon sa profondeur (dans les listes déroulantes).
class _NomIndente extends StatelessWidget {
  const _NomIndente({required this.noeud});

  final NoeudLieu noeud;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(left: 16.0 * noeud.profondeur),
    child: Text(noeud.lieu.nom, overflow: TextOverflow.ellipsis),
  );
}

/// Champ de formulaire « Emplacement » : liste des lieux + bouton pour en
/// créer un nouveau sans quitter le formulaire.
class ChampLieu extends StatelessWidget {
  const ChampLieu({
    super.key,
    required this.lieux,
    required this.type,
    required this.valeur,
    required this.onChanged,
    this.libelle = 'Emplacement',
  });

  final LieuxController lieux;
  final String? valeur;
  final ValueChanged<String?> onChanged;
  final String libelle;

  /// Seuls les emplacements de ce type sont proposés.
  final TypeLieu type;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: lieux,
      builder: (context, _) {
        final noeuds = lieux.arbre(type: type);
        final v = noeuds.any((n) => n.lieu.id == valeur) ? valeur : null;
        // Rien à choisir pour l'instant : on indique comment en créer.
        final aucun = noeuds.isEmpty ? 'Aucun — créez-en un avec +' : 'Aucun';
        return Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: DropdownButtonFormField<String?>(
                // La clé change avec la valeur : le champ se met à jour
                // quand un lieu vient d'être créé.
                key: ValueKey('champ-lieu-$v-${noeuds.length}'),
                initialValue: v,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: libelle,
                  prefixIcon: const Icon(Icons.place_outlined),
                ),
                items: [
                  DropdownMenuItem(value: null, child: Text(aucun)),
                  for (final n in noeuds)
                    DropdownMenuItem(
                      value: n.lieu.id,
                      child: _NomIndente(noeud: n),
                    ),
                ],
                selectedItemBuilder: (context) => [
                  Text(aucun),
                  for (final n in noeuds)
                    Text(
                      lieux.chemin(n.lieu.id) ?? n.lieu.nom,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
                onChanged: onChanged,
              ),
            ),
            IconButton(
              tooltip: 'Nouvel emplacement',
              icon: const Icon(Icons.add_location_alt_outlined),
              onPressed: () async {
                final cree = await editerLieu(
                  context,
                  lieux,
                  parentId: v,
                  type: type,
                );
                if (cree != null) {
                  onChanged(cree.id);
                }
              },
            ),
          ],
        );
      },
    );
  }
}

/// Puce de filtre « Tous les emplacements » / « Salon › Étagère 2 ».
class FiltreLieu extends StatelessWidget {
  const FiltreLieu({
    super.key,
    required this.lieux,
    required this.type,
    required this.valeur,
    required this.onChanged,
  });

  final LieuxController lieux;
  final String? valeur;
  final ValueChanged<String?> onChanged;

  /// Seuls les emplacements de ce type sont proposés.
  final TypeLieu type;

  Future<void> _choisir(BuildContext context) async {
    const tous = '';
    final choix = await showDialog<String>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Filtrer par emplacement'),
        children: [
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, tous),
            child: const Text('Tous les emplacements'),
          ),
          for (final n in lieux.arbre(type: type))
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context, n.lieu.id),
              child: _NomIndente(noeud: n),
            ),
        ],
      ),
    );
    if (choix != null) {
      onChanged(choix == tous ? null : choix);
    }
  }

  @override
  Widget build(BuildContext context) {
    final chemin = lieux.chemin(valeur);
    return InputChip(
      key: const Key('filtre-lieu'),
      avatar: const Icon(Icons.place_outlined, size: 18),
      label: Text(chemin ?? 'Tous les emplacements'),
      selected: chemin != null,
      showCheckmark: false,
      onPressed: () => _choisir(context),
      onDeleted: chemin == null ? null : () => onChanged(null),
    );
  }
}

IconData iconeTypeLieu(TypeLieu t) => switch (t) {
  TypeLieu.livres => Icons.menu_book_outlined,
  TypeLieu.cave => Icons.wine_bar_outlined,
};
