import 'package:flutter/material.dart';
import 'package:medicalbooking_portal/core/design/tokens.dart';
import 'package:medicalbooking_portal/shared/presentation/layout/responsive.dart';
import 'package:medicalbooking_portal/shared/presentation/organisms/site_header.dart';

class SiteFooter extends StatelessWidget {
  const SiteFooter({super.key});

  @override
  Widget build(BuildContext context) => const Constrained(
    child: Padding(
      padding: EdgeInsets.symmetric(vertical: 20),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        spacing: 16,
        runSpacing: 8,
        children: [
          Text(
            '© 2026 $brandName. Todos los derechos reservados. Versión demo: los datos clínicos son ficticios.',
            style: TextStyle(fontSize: 12, color: Tokens.slate400),
          ),
          Text(
            'Política de privacidad  •  Términos del servicio',
            style: TextStyle(fontSize: 12, color: Tokens.slate400),
          ),
        ],
      ),
    ),
  );
}
