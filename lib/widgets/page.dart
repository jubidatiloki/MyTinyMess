import 'package:flutter/material.dart';

import '../theme.dart';

/// Largeur maximale du contenu des pages (lisible sur grand écran).
const largeurContenu = 760.0;

/// Limite la largeur de [child] et le centre.
class Centre extends StatelessWidget {
  const Centre({super.key, required this.child, this.largeur = largeurContenu});

  final Widget child;
  final double largeur;

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.topCenter,
    child: ConstrainedBox(
      constraints: BoxConstraints(maxWidth: largeur),
      // Toute la largeur de la colonne : le contenu s'aligne sur le titre.
      child: SizedBox(width: double.infinity, child: child),
    ),
  );
}

/// Marges d'une liste défilante pleine largeur dont le contenu reste
/// centré à [largeurContenu] (formulaires).
EdgeInsets margesCentrees(BuildContext context, {double vertical = 16}) {
  final largeur = MediaQuery.sizeOf(context).width;
  final cote = largeur > largeurContenu + 32
      ? (largeur - largeurContenu) / 2
      : 16.0;
  return EdgeInsets.fromLTRB(cote, vertical, cote, vertical + 16);
}

/// Page standard : titre (et sous-titre) à gauche dans une barre discrète,
/// contenu centré à largeur limitée.
class PageOdv extends StatelessWidget {
  const PageOdv({
    super.key,
    required this.titre,
    required this.corps,
    this.titreWidget,
    this.sousTitre,
    this.actions,
    this.menu,
    this.bouton,
  });

  final String titre;

  /// Remplace le titre texte (ex. titre qui se met à jour).
  final Widget? titreWidget;
  final String? sousTitre;
  final List<Widget>? actions;
  final Widget? menu;
  final Widget? bouton;
  final Widget corps;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, contraintes) {
        // Marge qui aligne le titre et les actions sur la colonne centrée.
        final marge = contraintes.maxWidth > largeurContenu
            ? (contraintes.maxWidth - largeurContenu) / 2
            : 0.0;
        return Scaffold(
          drawer: menu,
          appBar: AppBar(
            toolbarHeight: sousTitre == null ? 64 : 72,
            // Avec ☰, le bouton occupe déjà la place à gauche.
            titleSpacing: menu == null ? marge + 20 : 4,
            title: titreWidget ?? TitrePage(titre: titre, sousTitre: sousTitre),
            actions: [
              ...?actions,
              SizedBox(width: marge + 8),
            ],
          ),
          floatingActionButton: bouton,
          body: Centre(child: corps),
        );
      },
    );
  }
}

/// Texte sur une ligne, rétréci (et non coupé) s'il manque de place.
class TexteAjuste extends StatelessWidget {
  const TexteAjuste(this.texte, {super.key, this.style});

  final String texte;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) => FittedBox(
    fit: BoxFit.scaleDown,
    alignment: AlignmentDirectional.centerStart,
    child: Text(texte, style: style, maxLines: 1),
  );
}

/// Titre de barre qui peut être long (nom de recette…) : il passe à la ligne,
/// puis rétrécit si la barre est pleine.
class TitreLong extends StatelessWidget {
  const TitreLong(this.texte, {super.key});

  final String texte;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 56,
    child: LayoutBuilder(
      builder: (context, c) => FittedBox(
        fit: BoxFit.scaleDown,
        alignment: AlignmentDirectional.centerStart,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: c.maxWidth),
          child: Text(texte, softWrap: true, overflow: TextOverflow.visible),
        ),
      ),
    ),
  );
}

/// Titre de page sur une ou deux lignes.
class TitrePage extends StatelessWidget {
  const TitrePage({super.key, required this.titre, this.sousTitre});

  final String titre;
  final String? sousTitre;

  @override
  Widget build(BuildContext context) {
    final p = PaletteOdv.de(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        TexteAjuste(titre),
        if (sousTitre != null)
          TexteAjuste(
            sousTitre!,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w400,
              color: p.texteSecondaire,
            ),
          ),
      ],
    );
  }
}

/// Petit titre vert au-dessus d'un groupe de réglages.
class TitreSection extends StatelessWidget {
  const TitreSection(this.texte, {super.key});

  final String texte;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(4, 20, 4, 8),
    child: Text(
      texte,
      style: TextStyle(
        color: PaletteOdv.de(context).accentDoux,
        fontSize: 13,
        fontWeight: FontWeight.w500,
      ),
    ),
  );
}

/// Carte qui regroupe des lignes, séparées par un trait.
class CarteGroupe extends StatelessWidget {
  const CarteGroupe({super.key, required this.enfants});

  final List<Widget> enfants;

  @override
  Widget build(BuildContext context) {
    final lignes = <Widget>[];
    for (var i = 0; i < enfants.length; i++) {
      if (i > 0) {
        lignes.add(const Divider(indent: 64, height: 1));
      }
      lignes.add(enfants[i]);
    }
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(children: lignes),
    );
  }
}

/// Icône dans un petit carré arrondi (début de ligne de réglage).
class IconeCarree extends StatelessWidget {
  const IconeCarree(this.icone, {super.key, this.couleur});

  final IconData icone;
  final Color? couleur;

  @override
  Widget build(BuildContext context) => Container(
    width: 36,
    height: 36,
    decoration: BoxDecoration(
      color: PaletteOdv.de(context).champ,
      borderRadius: BorderRadius.circular(10),
    ),
    child: Icon(icone, size: 20, color: couleur),
  );
}

/// Ligne de liste présentée en carte arrondie (livres, vins…).
class CarteLigne extends StatelessWidget {
  const CarteLigne({
    super.key,
    required this.title,
    this.leading,
    this.subtitle,
    this.trailing,
    this.actions,
    this.onTap,
  });

  final Widget title;
  final Widget? leading;
  final Widget? subtitle;
  final Widget? trailing;

  /// Boutons de la ligne : à droite du texte, ou dessous sur un écran étroit
  /// pour laisser toute la place au texte (jamais coupé).
  final List<Widget>? actions;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Card(
      clipBehavior: Clip.antiAlias,
      child: LayoutBuilder(
        builder: (context, contraintes) {
          final boutons = actions;
          final dessous = boutons != null && contraintes.maxWidth < 480;
          final ligne = ListTile(
            contentPadding: const EdgeInsets.fromLTRB(14, 6, 10, 6),
            leading: leading,
            title: title,
            subtitle: subtitle,
            trailing: boutons == null || dessous
                ? trailing
                : ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: contraintes.maxWidth / 2,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: boutons.length == 1
                          ? [Flexible(child: boutons.single)]
                          : boutons,
                    ),
                  ),
            onTap: onTap,
          );
          if (!dessous) {
            return ligne;
          }
          return InkWell(
            onTap: onTap,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ligne,
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 0, 10, 4),
                  child: Wrap(
                    alignment: WrapAlignment.end,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: boutons,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    ),
  );
}

/// Gros bouton « Enregistrer » collé en bas des formulaires (bien visible,
/// à placer dans `Scaffold.bottomNavigationBar`).
class BarreEnregistrer extends StatelessWidget {
  const BarreEnregistrer({
    super.key,
    required this.onPressed,
    this.libelle = 'Enregistrer',
  });

  final VoidCallback onPressed;
  final String libelle;

  @override
  Widget build(BuildContext context) => Material(
    color: Theme.of(context).scaffoldBackgroundColor,
    child: SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        // heightFactor 1 : la barre garde la hauteur du bouton (sinon elle
        // occuperait tout l'écran et cacherait le formulaire).
        child: Center(
          heightFactor: 1,
          child: SizedBox(
            width: largeurContenu,
            height: 52,
            child: FilledButton.icon(
              key: const Key('bouton-enregistrer'),
              onPressed: onPressed,
              icon: const Icon(Icons.check),
              label: Text(libelle, style: const TextStyle(fontSize: 16)),
              style: FilledButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

/// Bouton flottant large avec libellé (« + Ajouter un livre »).
class BoutonAjout extends StatelessWidget {
  const BoutonAjout({
    super.key,
    required this.libelle,
    required this.onPressed,
  });

  final String libelle;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => FloatingActionButton.extended(
    heroTag: null,
    tooltip: libelle,
    onPressed: onPressed,
    icon: const Icon(Icons.add),
    label: Text(libelle),
  );
}
