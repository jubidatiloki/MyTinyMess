import 'package:flutter/material.dart';

import '../../models/aliment.dart';
import '../../models/unite.dart';
import '../../widgets/communs.dart';

/// Nouvelle quantité et niveau de l'unité entamée (null = pleine).
typedef ChoixQuantite = ({int quantite, int? niveau});

/// Demande la nouvelle quantité d'un aliment (null = annulé).
Future<ChoixQuantite?> demanderQuantite(
  BuildContext context,
  Aliment aliment,
) => showDialog<ChoixQuantite>(
  context: context,
  builder: (_) => _FenetreQuantite(aliment: aliment),
);

/// « Entamé : reste environ 50 % », ou « Plein (pas entamé) ».
String texteNiveau(int? niveau) => niveau == null
    ? 'Plein (pas entamé)'
    : 'Entamé : reste environ $niveau %';

/// Curseur du niveau de l'unité entamée, par pas de 10 % ; tout à droite =
/// pleine (null).
class CurseurNiveau extends StatelessWidget {
  const CurseurNiveau({
    super.key,
    required this.niveau,
    required this.onChanged,
  });

  final int? niveau;
  final ValueChanged<int?> onChanged;

  @override
  Widget build(BuildContext context) {
    final v = niveau ?? 100;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(texteNiveau(niveau), key: const Key('texte-niveau')),
        ),
        Slider(
          key: const Key('curseur-niveau'),
          value: v.toDouble(),
          max: 100,
          divisions: 10,
          label: '$v %',
          semanticFormatterCallback: (x) => '${x.round()} %',
          onChanged: (x) => onChanged(x.round() >= 100 ? null : x.round()),
        ),
      ],
    );
  }
}

class _FenetreQuantite extends StatefulWidget {
  const _FenetreQuantite({required this.aliment});

  final Aliment aliment;

  @override
  State<_FenetreQuantite> createState() => _FenetreQuantiteState();
}

class _FenetreQuantiteState extends State<_FenetreQuantite> {
  late final _champ = TextEditingController(text: '${widget.aliment.quantite}');
  late int? _niveau = widget.aliment.niveau;
  final _form = GlobalKey<FormState>();

  @override
  void dispose() {
    _champ.dispose();
    super.dispose();
  }

  void _decaler(int delta) {
    final n = (entierOuNull(_champ.text) ?? 0) + delta;
    setState(() {
      _champ.text = '${n < 0 ? 0 : n}';
      // Une unité finie : la suivante est pleine.
      if (delta < 0) {
        _niveau = null;
      }
    });
  }

  void _valider() {
    if (_form.currentState!.validate()) {
      Navigator.pop<ChoixQuantite>(context, (
        quantite: entierOuNull(_champ.text)!,
        niveau: _niveau,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final unite = widget.aliment.unite;
    final n = entierOuNull(_champ.text) ?? 0;
    return AlertDialog(
      title: Text(widget.aliment.nom),
      content: Form(
        key: _form,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  IconButton(
                    tooltip: 'Un de moins',
                    icon: const Icon(Icons.remove_circle_outline),
                    onPressed: n > 0 ? () => _decaler(-1) : null,
                  ),
                  Expanded(
                    child: TextFormField(
                      key: const Key('champ-nouvelle-quantite'),
                      controller: _champ,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      decoration: InputDecoration(
                        labelText: 'Il en reste',
                        helperText: unite == null
                            ? null
                            : accorderUnite(unite, n),
                        helperMaxLines: 3,
                        errorMaxLines: 3,
                      ),
                      onChanged: (_) => setState(() {}),
                      onFieldSubmitted: (_) => _valider(),
                      validator: (v) {
                        final n = entierOuNull(v ?? '');
                        return n == null || n < 0
                            ? 'Nombre positif attendu'
                            : null;
                      },
                    ),
                  ),
                  IconButton(
                    tooltip: 'Un de plus',
                    icon: const Icon(Icons.add_circle_outline),
                    onPressed: () => _decaler(1),
                  ),
                ],
              ),
              if (n > 0) ...[
                const SizedBox(height: 16),
                CurseurNiveau(
                  niveau: _niveau,
                  onChanged: (v) => setState(() => _niveau = v),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        FilledButton(
          key: const Key('valider-quantite'),
          onPressed: _valider,
          child: const Text('Enregistrer'),
        ),
      ],
    );
  }
}
