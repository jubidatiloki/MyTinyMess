import 'package:flutter/material.dart';

import '../../data/liens.dart';
import '../../data/partage_adresse.dart';
import '../../models/adresse.dart';
import '../../state/annuaire_controller.dart';
import '../../state/collection_controller.dart';
import '../../widgets/page.dart';
import 'adresse_detail_screen.dart';
import 'annuaire_screen.dart';
import 'formulaire_adresse_screen.dart';

/// Champ « D'où vient-elle ? » : une adresse de l'annuaire (ou aucune).
/// Une adresse supprimée de l'annuaire est simplement ignorée.
class ChampAdresse extends StatelessWidget {
  const ChampAdresse({
    super.key,
    required this.annuaire,
    required this.valeur,
    required this.onChanged,
    this.libelle = 'D\'où vient-elle ?',
    this.typeNouvelle = TypeAdresse.commerce,
    this.ouvrirLien,
    this.partager,
  });

  final AnnuaireController annuaire;
  final String? valeur;
  final ValueChanged<String?> onChanged;
  final String libelle;

  /// Type proposé pour une adresse créée depuis ce champ.
  final TypeAdresse typeNouvelle;

  /// Pour ouvrir la fiche de l'adresse choisie (sinon, pas de bouton).
  final OuvrirLien? ouvrirLien;
  final Partager? partager;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: annuaire,
    builder: (context, _) {
      final a = annuaire.parId(valeur ?? '');
      Future<void> choisir() async {
        final choix = await choisirAdresse(
          context,
          annuaire,
          typeNouvelle: typeNouvelle,
        );
        if (choix != null) {
          onChanged(choix.isEmpty ? null : choix);
        }
      }

      // Tout le champ se touche (pas seulement son texte).
      return InkWell(
        key: const Key('champ-adresse-origine'),
        borderRadius: BorderRadius.circular(12),
        onTap: choisir,
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: libelle,
            prefixIcon: Icon(
              a == null ? Icons.storefront_outlined : iconeTypeAdresse(a.type),
            ),
            suffixIcon: a == null
                ? const Icon(Icons.arrow_drop_down)
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (ouvrirLien != null && partager != null)
                        IconButton(
                          tooltip: 'Voir la fiche',
                          icon: const Icon(Icons.open_in_new),
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute<void>(
                              builder: (_) => AdresseDetailScreen(
                                annuaire: annuaire,
                                id: a.id,
                                ouvrirLien: ouvrirLien!,
                                partager: partager!,
                              ),
                            ),
                          ),
                        ),
                      IconButton(
                        tooltip: 'Enlever l\'adresse',
                        icon: const Icon(Icons.close),
                        onPressed: () => onChanged(null),
                      ),
                    ],
                  ),
          ),
          child: Text(a?.nom ?? 'Choisir dans l\'annuaire'),
        ),
      );
    },
  );
}

/// Choix d'une adresse : id, '' pour « aucune », null si annulé.
Future<String?> choisirAdresse(
  BuildContext context,
  AnnuaireController annuaire, {
  TypeAdresse typeNouvelle = TypeAdresse.commerce,
}) => showDialog<String>(
  context: context,
  builder: (_) => _FenetreChoix(annuaire: annuaire, typeNouvelle: typeNouvelle),
);

class _FenetreChoix extends StatefulWidget {
  const _FenetreChoix({required this.annuaire, required this.typeNouvelle});

  final AnnuaireController annuaire;
  final TypeAdresse typeNouvelle;

  @override
  State<_FenetreChoix> createState() => _FenetreChoixState();
}

class _FenetreChoixState extends State<_FenetreChoix> {
  String _texte = '';

  Future<void> _nouvelle() async {
    final avant = {for (final a in widget.annuaire.elements) a.id};
    await Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => FormulaireAdresseScreen(
          annuaire: widget.annuaire,
          typeParDefaut: widget.typeNouvelle,
        ),
      ),
    );
    final creee = widget.annuaire.elements
        .where((a) => !avant.contains(a.id))
        .firstOrNull;
    if (creee != null && mounted) {
      Navigator.pop(context, creee.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = normaliser(_texte.trim());
    final liste = [...widget.annuaire.elements]
      ..retainWhere((a) => t.isEmpty || normaliser(a.nom).contains(t))
      ..sort((a, b) => normaliser(a.nom).compareTo(normaliser(b.nom)));
    return AlertDialog(
      title: const Text('D\'où vient-elle ?'),
      contentPadding: const EdgeInsets.fromLTRB(8, 16, 8, 0),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.annuaire.elements.length > 6)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  decoration: const InputDecoration(
                    hintText: 'Chercher dans l\'annuaire',
                    prefixIcon: Icon(Icons.search),
                    isDense: true,
                  ),
                  onChanged: (v) => setState(() => _texte = v),
                ),
              ),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  ListTile(
                    leading: const IconeCarree(Icons.add),
                    title: const Text('Nouvelle adresse'),
                    onTap: _nouvelle,
                  ),
                  ListTile(
                    leading: const IconeCarree(Icons.block),
                    title: const Text('Aucune'),
                    onTap: () => Navigator.pop(context, ''),
                  ),
                  for (final a in liste)
                    ListTile(
                      key: Key('choix-adresse-${a.id}'),
                      leading: IconeCarree(iconeTypeAdresse(a.type)),
                      title: Text(a.nom),
                      subtitle: Text(a.description ?? a.type.libelle),
                      onTap: () => Navigator.pop(context, a.id),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
      ],
    );
  }
}
