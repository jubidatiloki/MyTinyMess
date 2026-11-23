import 'package:flutter/material.dart';

import '../../models/agenda.dart';
import '../../state/cuisine.dart';
import '../../theme.dart';
import '../../widgets/communs.dart';

/// Couleur des repas dans le calendrier (les événements sont en vert).
const couleurRepas = Color(0xFFE5A23A);

/// Grille d'un mois : une pastille verte pour les événements, une orange
/// pour les repas prévus. Sur grand écran, le titre des événements s'affiche.
class Calendrier extends StatelessWidget {
  const Calendrier({
    super.key,
    required this.cuisine,
    required this.mois,
    required this.choisi,
    required this.onChoisir,
  });

  final Cuisine cuisine;

  /// N'importe quel jour du mois affiché.
  final DateTime mois;
  final DateTime choisi;
  final ValueChanged<DateTime> onChoisir;

  @override
  Widget build(BuildContext context) {
    final p = PaletteOdv.de(context);
    final debut = debutSemaine(DateTime(mois.year, mois.month));
    final fin = DateTime(mois.year, mois.month + 1, 0);
    final jours = [
      for (
        var j = debut;
        !j.isAfter(fin) || j.weekday != DateTime.monday;
        j = plusJours(j, 1)
      )
        j,
    ];
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          children: [
            Row(
              children: [
                for (final l in const ['L', 'M', 'M', 'J', 'V', 'S', 'D'])
                  Expanded(
                    child: Center(
                      child: Text(
                        l,
                        style: TextStyle(color: p.texteSecondaire),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            for (var s = 0; s < jours.length; s += 7)
              Row(
                children: [
                  for (final j in jours.sublist(s, s + 7))
                    Expanded(
                      child: _Case(
                        jour: j,
                        horsMois: j.month != mois.month,
                        choisi: j == jourDe(choisi),
                        evenements: cuisine.evenements.du(j),
                        repas: cuisine.repas.entre(j, 1).length,
                        onTap: () => onChoisir(j),
                      ),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _Case extends StatelessWidget {
  const _Case({
    required this.jour,
    required this.horsMois,
    required this.choisi,
    required this.evenements,
    required this.repas,
    required this.onTap,
  });

  final DateTime jour;
  final bool horsMois;
  final bool choisi;
  final List<Evenement> evenements;
  final int repas;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = PaletteOdv.de(context);
    final aujourdhui = jourDe(DateTime.now()) == jour;
    Widget point(Color c) => Container(
      width: 6,
      height: 6,
      margin: const EdgeInsets.symmetric(horizontal: 1),
      decoration: BoxDecoration(color: c, shape: BoxShape.circle),
    );
    return Padding(
      padding: const EdgeInsets.all(2),
      child: Material(
        color: choisi ? p.menuSelection : Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: aujourdhui
              ? const BorderSide(color: vertOdv, width: 2)
              : BorderSide.none,
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          key: Key('cal-${jour.year}-${jour.month}-${jour.day}'),
          onTap: onTap,
          child: SizedBox(
            height: 60,
            child: LayoutBuilder(
              builder: (context, c) => Padding(
                padding: const EdgeInsets.all(4),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${jour.day}',
                      style: TextStyle(
                        fontSize: 13,
                        color: horsMois ? p.texteSecondaire : null,
                        fontWeight: aujourdhui ? FontWeight.w700 : null,
                      ),
                    ),
                    if (c.maxWidth >= 72 && evenements.isNotEmpty)
                      Text(
                        evenements.first.titre,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 10, color: p.accentDoux),
                      ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (evenements.isNotEmpty) point(vertOdv),
                        if (repas > 0) point(couleurRepas),
                        const SizedBox(height: 6),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
