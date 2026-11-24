import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../../models/adresse.dart';
import '../../state/annuaire_controller.dart';
import '../../widgets/communs.dart';
import '../../widgets/page.dart';
import 'annuaire_screen.dart';

/// Ajout (adresse == null) ou modification d'une bonne adresse.
class FormulaireAdresseScreen extends StatefulWidget {
  const FormulaireAdresseScreen({
    super.key,
    required this.annuaire,
    this.adresse,
    this.typeParDefaut,
  });

  final AnnuaireController annuaire;
  final Adresse? adresse;
  final TypeAdresse? typeParDefaut;

  @override
  State<FormulaireAdresseScreen> createState() =>
      _FormulaireAdresseScreenState();
}

class _FormulaireAdresseScreenState extends State<FormulaireAdresseScreen> {
  final _form = GlobalKey<FormState>();
  late final Adresse? _a = widget.adresse;
  late TypeAdresse _type =
      _a?.type ?? widget.typeParDefaut ?? TypeAdresse.personne;
  late bool _favori = _a?.favori ?? false;
  late final _nom = TextEditingController(text: _a?.nom);
  late final _description = TextEditingController(text: _a?.description);
  late final _telephone = TextEditingController(text: _a?.telephone);
  late final _email = TextEditingController(text: _a?.email);
  late final _site = TextEditingController(text: _a?.site);
  late final _lieu = TextEditingController(text: _a?.lieu);
  late final _quand = TextEditingController(text: _a?.quand);
  late final _recommandePar = TextEditingController(text: _a?.recommandePar);
  late final _avis = TextEditingController(text: _a?.avis);
  late final _etiquettes = TextEditingController(
    text: _a?.etiquettes.join(', '),
  );

  @override
  void dispose() {
    for (final c in [
      _nom,
      _description,
      _telephone,
      _email,
      _site,
      _lieu,
      _quand,
      _recommandePar,
      _avis,
      _etiquettes,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _enregistrer() async {
    if (!_form.currentState!.validate()) {
      return;
    }
    await widget.annuaire.enregistrer(
      Adresse(
        id: _a?.id ?? const Uuid().v4(),
        nom: _nom.text.trim(),
        type: _type,
        description: texteOuNull(_description.text),
        telephone: texteOuNull(_telephone.text),
        email: texteOuNull(_email.text),
        site: texteOuNull(_site.text),
        lieu: texteOuNull(_lieu.text),
        quand: texteOuNull(_quand.text),
        recommandePar: texteOuNull(_recommandePar.text),
        avis: _avis.text.trim(),
        etiquettes: Adresse.lireEtiquettes(_etiquettes.text),
        favori: _favori,
      ),
    );
    if (mounted) {
      Navigator.pop(context);
    }
  }

  Widget _champ(
    String cle,
    TextEditingController controleur,
    String libelle, {
    String? indice,
    IconData? icone,
    TextInputType? clavier,
    String? Function(String)? verifier,
    int lignes = 1,
    bool phrase = true,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 18),
    child: TextFormField(
      key: Key('champ-adresse-$cle'),
      controller: controleur,
      keyboardType: clavier,
      minLines: lignes > 1 ? lignes : null,
      maxLines: lignes > 1 ? 8 : 1,
      textCapitalization: phrase
          ? TextCapitalization.sentences
          : TextCapitalization.none,
      decoration: InputDecoration(
        labelText: libelle,
        hintText: indice,
        alignLabelWithHint: lignes > 1,
        prefixIcon: icone == null ? null : Icon(icone),
      ),
      validator: verifier == null ? null : (v) => verifier((v ?? '').trim()),
    ),
  );

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: TitreLong(
        _a == null ? 'Nouvelle bonne adresse' : 'Modifier l\'adresse',
      ),
    ),
    bottomNavigationBar: BarreEnregistrer(
      libelle: 'Enregistrer l\'adresse',
      onPressed: _enregistrer,
    ),
    body: Form(
      key: _form,
      // Colonne (et non liste paresseuse) : tous les champs sont vérifiés,
      // même ceux qui ne sont pas à l'écran.
      child: SingleChildScrollView(
        padding: margesCentrees(context),
        child: Column(
          children: [
            _champ(
              'nom',
              _nom,
              'Nom *',
              verifier: (v) => v.isEmpty ? 'Le nom est obligatoire' : null,
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 18),
              child: DropdownButtonFormField<TypeAdresse>(
                key: const Key('champ-adresse-type'),
                initialValue: _type,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Type'),
                items: [
                  for (final t in TypeAdresse.values)
                    DropdownMenuItem(
                      value: t,
                      child: Row(
                        children: [
                          Icon(iconeTypeAdresse(t), size: 20),
                          const SizedBox(width: 10),
                          Flexible(child: TexteAjuste(t.libelle)),
                        ],
                      ),
                    ),
                ],
                onChanged: (t) => setState(() => _type = t ?? _type),
              ),
            ),
            _champ(
              'description',
              _description,
              'En quelques mots',
              indice: 'Boulanger, plombier, festival de jazz…',
            ),
            _champ(
              'lieu',
              _lieu,
              'Adresse ou ville',
              icone: Icons.place_outlined,
            ),
            _champ(
              'telephone',
              _telephone,
              'Téléphone',
              icone: Icons.phone_outlined,
              clavier: TextInputType.phone,
            ),
            _champ(
              'email',
              _email,
              'E-mail',
              icone: Icons.mail_outline,
              clavier: TextInputType.emailAddress,
              phrase: false,
              verifier: (v) => v.isEmpty || RegExp(r'^\S+@\S+$').hasMatch(v)
                  ? null
                  : 'E-mail non valable',
            ),
            _champ(
              'site',
              _site,
              'Site internet',
              indice: 'www.exemple.fr',
              icone: Icons.public,
              clavier: TextInputType.url,
              phrase: false,
              verifier: (v) => v.isEmpty || Adresse.lienWeb(v) != null
                  ? null
                  : 'Adresse de site non valable',
            ),
            _champ(
              'quand',
              _quand,
              'Horaires ou dates',
              indice: 'Fermé le lundi, 1er week-end de juillet…',
              icone: Icons.schedule,
            ),
            _champ(
              'recommande',
              _recommandePar,
              'Recommandé par',
              icone: Icons.thumb_up_outlined,
            ),
            _champ(
              'avis',
              _avis,
              'Mon avis',
              indice: 'Pourquoi c\'est une bonne adresse',
              lignes: 3,
            ),
            _champ(
              'etiquettes',
              _etiquettes,
              'Étiquettes',
              indice: 'Lyon, cadeaux, enfants (séparées par des virgules)',
              icone: Icons.label_outline,
            ),
            SwitchListTile(
              key: const Key('champ-adresse-favori'),
              title: const Text('Favori'),
              secondary: const Icon(Icons.star_border),
              value: _favori,
              onChanged: (v) => setState(() => _favori = v),
            ),
          ],
        ),
      ),
    ),
  );
}
