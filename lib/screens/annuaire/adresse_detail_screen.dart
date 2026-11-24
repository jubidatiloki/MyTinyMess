import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/liens.dart';
import '../../data/partage_adresse.dart';
import '../../models/adresse.dart';
import '../../state/annuaire_controller.dart';
import '../../widgets/communs.dart';
import '../../widgets/page.dart';
import '../repas/actions_repas.dart';
import 'annuaire_screen.dart';
import 'formulaire_adresse_screen.dart';

/// Fiche d'une bonne adresse : toucher une ligne appelle, écrit ou ouvre.
class AdresseDetailScreen extends StatelessWidget {
  const AdresseDetailScreen({
    super.key,
    required this.annuaire,
    required this.id,
    required this.ouvrirLien,
    required this.partager,
  });

  final AnnuaireController annuaire;
  final String id;
  final OuvrirLien ouvrirLien;
  final Partager partager;

  Future<void> _ouvrir(BuildContext context, Uri lien) async {
    if (!await ouvrirLien(lien) && context.mounted) {
      await informer(
        context,
        'Aucune application de cet appareil n\'a pu ouvrir ce lien.',
      );
    }
  }

  /// Menu de partage de l'appareil ; sinon la fiche est copiée.
  Future<void> _partager(BuildContext context, Adresse a) async {
    if (!await partager(textePartage(a), a.nom) && context.mounted) {
      await _copier(context, a);
    }
  }

  Future<void> _copier(BuildContext context, Adresse a) async {
    var copie = true;
    try {
      await Clipboard.setData(ClipboardData(text: textePartage(a)));
    } catch (_) {
      copie = false;
    }
    if (context.mounted) {
      await informer(
        context,
        copie
            ? 'Fiche copiée : collez-la dans un message pour la partager.'
            : 'La copie n\'a pas fonctionné sur cet appareil.',
      );
    }
  }

  Future<void> _supprimer(BuildContext context, Adresse a) async {
    if (await confirmer(context, 'Supprimer « ${a.nom} » de l\'annuaire ?') &&
        context.mounted) {
      Navigator.pop(context);
      await annuaire.supprimer(a.id);
    }
  }

  Widget _ligne(
    BuildContext context,
    IconData icone,
    String libelle,
    String texte, [
    Uri? lien,
  ]) => ListTile(
    key: Key('ligne-$libelle'),
    leading: IconeCarree(icone),
    title: Text(texte),
    subtitle: Text(libelle),
    trailing: lien == null ? null : const Icon(Icons.open_in_new, size: 18),
    onTap: lien == null ? null : () => _ouvrir(context, lien),
  );

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: annuaire,
    builder: (context, _) {
      final a = annuaire.parId(id);
      if (a == null) {
        return const Scaffold();
      }
      final lignes = [
        if (a.telephone != null)
          _ligne(
            context,
            Icons.phone_outlined,
            'Téléphone',
            a.telephone!,
            a.lienTelephone,
          ),
        if (a.email != null)
          _ligne(context, Icons.mail_outline, 'E-mail', a.email!, a.lienEmail),
        if (a.site != null)
          _ligne(context, Icons.public, 'Site', a.site!, a.lienSite),
        if (a.lieu != null)
          _ligne(
            context,
            Icons.place_outlined,
            'Adresse',
            a.lieu!,
            a.lienCarte,
          ),
        if (a.quand != null)
          _ligne(context, Icons.schedule, 'Horaires ou dates', a.quand!),
        if (a.recommandePar != null)
          _ligne(
            context,
            Icons.thumb_up_outlined,
            'Recommandé par',
            a.recommandePar!,
          ),
      ];
      return Scaffold(
        appBar: AppBar(
          title: TitreLong(a.nom),
          actions: [
            IconButton(
              tooltip: a.favori ? 'Retirer des favoris' : 'Mettre en favori',
              icon: Icon(
                a.favori ? Icons.star : Icons.star_border,
                color: a.favori ? couleurFavori : null,
              ),
              onPressed: () => annuaire.basculerFavori(a.id),
            ),
            IconButton(
              tooltip: 'Modifier',
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (_) =>
                      FormulaireAdresseScreen(annuaire: annuaire, adresse: a),
                ),
              ),
            ),
            IconButton(
              tooltip: 'Supprimer',
              icon: const Icon(Icons.delete_outline),
              onPressed: () => _supprimer(context, a),
            ),
          ],
        ),
        body: ListView(
          padding: margesCentrees(context),
          children: [
            CarteGroupe(
              enfants: [
                ListTile(
                  leading: IconeCarree(iconeTypeAdresse(a.type)),
                  title: Text(a.description ?? a.type.libelle),
                  subtitle: a.description == null ? null : Text(a.type.libelle),
                ),
                ...lignes,
              ],
            ),
            if (a.avis.isNotEmpty) ...[
              const TitreSection('Mon avis'),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(a.avis),
                ),
              ),
            ],
            if (a.etiquettes.isNotEmpty) ...[
              const SizedBox(height: 16),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final e in a.etiquettes)
                    Chip(label: Text('#$e', maxLines: 3, softWrap: true)),
                ],
              ),
            ],
            const SizedBox(height: 20),
            FilledButton.icon(
              key: const Key('partager-fiche'),
              icon: const Icon(Icons.share_outlined),
              label: const Text('Partager'),
              onPressed: () => _partager(context, a),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              key: const Key('copier-fiche'),
              icon: const Icon(Icons.copy_outlined),
              label: const Text('Copier la fiche'),
              onPressed: () => _copier(context, a),
            ),
          ],
        ),
      );
    },
  );
}
