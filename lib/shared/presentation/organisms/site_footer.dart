import 'package:flutter/material.dart';
import 'package:medicalbooking_portal/core/design/tokens.dart';
import 'package:medicalbooking_portal/shared/presentation/layout/responsive.dart';
import 'package:medicalbooking_portal/shared/presentation/organisms/site_header.dart';

class SiteFooter extends StatelessWidget {
  const SiteFooter({super.key, this.demo = true});

  /// The in-memory demo says its clinical data is fictitious; the API mode must not.
  final bool demo;

  @override
  Widget build(BuildContext context) => Constrained(
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        spacing: 16,
        runSpacing: 8,
        children: [
          Text(
            '© 2026 $brandName. Todos los derechos reservados.${demo ? ' Versión demo: los datos clínicos son ficticios.' : ''}',
            style: const TextStyle(fontSize: 12, color: Tokens.slate500),
          ),
          const Text(
            'Política de privacidad  •  Términos del servicio',
            style: TextStyle(fontSize: 12, color: Tokens.slate500),
          ),
        ],
      ),
    ),
  );
}
