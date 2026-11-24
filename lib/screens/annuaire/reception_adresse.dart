import 'dart:async';

import 'package:flutter/material.dart';

import '../../data/liens.dart';
import '../../data/partage_adresse.dart';
import '../../models/adresse.dart';
import '../../state/annuaire_controller.dart';
import '../repas/actions_repas.dart';
import 'adresse_detail_screen.dart';

/// Une adresse reçue par un lien : on la montre, puis un geste l'ajoute.
/// Une adresse déjà présente n'est jamais remplacée : sa fiche s'ouvre.
Future<void> recevoirAdresse(
  NavigatorState navigateur, {
  required Uri lien,
  required AnnuaireController annuaire,
  required OuvrirLien ouvrirLien,
  required Partager partager,
}) async {
  final a = lireLienPartage(lien);
  if (a == null) {
    await informer(
      navigateur.context,
      'Ce lien ne contient pas d\'adresse, ou il est incomplet. '
      'Demandez qu\'on vous l\'envoie de nouveau.',
    );
    return;
  }
  final presente = annuaire.parId(a.id);
  if (presente == null) {
    final ajouter = await showDialog<bool>(
      context: navigateur.context,
      builder: (context) => _Apercu(adresse: a),
    );
    if (ajouter != true || !navigateur.mounted) {
      return;
    }
    await annuaire.enregistrer(a);
  } else {
    await informer(
      navigateur.context,
      '« ${presente.nom} » est déjà dans votre annuaire.',
    );
  }
  if (navigateur.mounted) {
    // Sans attendre la fermeture de la fiche : un autre lien peut arriver.
    unawaited(
      navigateur.push(
        MaterialPageRoute<void>(
          builder: (_) => AdresseDetailScreen(
            annuaire: annuaire,
            id: a.id,
            ouvrirLien: ouvrirLien,
            partager: partager,
          ),
        ),
      ),
    );
  }
}

class _Apercu extends StatelessWidget {
  const _Apercu({required this.adresse});

  final Adresse adresse;

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Ajouter cette adresse ?'),
    content: SingleChildScrollView(child: Text(adresse.enTexte)),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context, false),
        child: const Text('Non merci'),
      ),
      FilledButton(
        key: const Key('ajouter-adresse-recue'),
        onPressed: () => Navigator.pop(context, true),
        child: const Text('Ajouter'),
      ),
    ],
  );
}
