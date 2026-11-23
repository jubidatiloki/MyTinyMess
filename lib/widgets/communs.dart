import 'package:flutter/material.dart';

/// 12/11/2026
String formaterDate(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}/'
    '${d.month.toString().padLeft(2, '0')}/${d.year}';

/// Texte vide → null (pour les champs facultatifs).
String? texteOuNull(String texte) {
  final t = texte.trim();
  return t.isEmpty ? null : t;
}

int? entierOuNull(String texte) => int.tryParse(texte.trim());

/// Champ de recherche affiché en haut des listes.
class ChampRecherche extends StatelessWidget {
  const ChampRecherche({
    super.key,
    required this.indice,
    required this.onChanged,
  });

  final String indice;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: TextField(
        decoration: InputDecoration(
          hintText: indice,
          prefixIcon: const Icon(Icons.search),

          isDense: true,
        ),
        onChanged: onChanged,
      ),
    );
  }
}

/// Message affiché quand une liste est vide.
class ListeVide extends StatelessWidget {
  const ListeVide({super.key, required this.icone, required this.message});

  final IconData icone;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icone, size: 56, color: Theme.of(context).disabledColor),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

Future<bool> confirmer(BuildContext context, String question) async {
  final reponse = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      content: Text(question),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Annuler'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Confirmer'),
        ),
      ],
    ),
  );
  return reponse ?? false;
}

const _jours = [
  'lundi',
  'mardi',
  'mercredi',
  'jeudi',
  'vendredi',
  'samedi',
  'dimanche',
];
const _mois = [
  'janvier',
  'février',
  'mars',
  'avril',
  'mai',
  'juin',
  'juillet',
  'août',
  'septembre',
  'octobre',
  'novembre',
  'décembre',
];

/// « lundi 17 novembre »
String jourEnLettres(DateTime d) =>
    '${_jours[d.weekday - 1]} ${d.day} ${_mois[d.month - 1]}';

/// « 17 nov. » (court)
String jourCourt(DateTime d) =>
    '${d.day} ${_mois[d.month - 1].substring(0, d.month == 6 || d.month == 7 ? 4 : 3)}.';

/// Lundi de la semaine de [d].
DateTime debutSemaine(DateTime d) =>
    DateTime(d.year, d.month, d.day - (d.weekday - 1));

/// [n] jours plus tard (ou plus tôt), même aux changements d'heure, où une
/// journée ne dure pas 24 heures.
DateTime plusJours(DateTime d, int n) => DateTime(d.year, d.month, d.day + n);

/// « novembre 2026 »
String moisEnLettres(DateTime d) => '${_mois[d.month - 1]} ${d.year}';
