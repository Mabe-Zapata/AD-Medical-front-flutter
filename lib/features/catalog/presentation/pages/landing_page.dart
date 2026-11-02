import 'package:flutter/material.dart';
import 'package:medicalbooking_portal/app/app_scope.dart';
import 'package:medicalbooking_portal/app/routes.dart';
import 'package:medicalbooking_portal/app/widgets/app_header.dart';
import 'package:medicalbooking_portal/core/design/tokens.dart';
import 'package:medicalbooking_portal/features/catalog/domain/entities/catalog.dart';
import 'package:medicalbooking_portal/features/catalog/presentation/widgets/about_section.dart';
import 'package:medicalbooking_portal/features/catalog/presentation/widgets/catalog_section.dart';
import 'package:medicalbooking_portal/features/catalog/presentation/widgets/hero_section.dart';
import 'package:medicalbooking_portal/shared/presentation/organisms/site_footer.dart';

/// Container: loads the public catalog and wires the sections to navigation.
class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  final _keys = {for (final id in ['home', 'about', 'product']) id: GlobalKey()};
  late final Future<Catalog> _catalog = AppScope.of(context).getCatalog();

  void _scrollTo(String id) {
    final target = _keys[id]?.currentContext;
    if (target == null) return;
    Scrollable.ensureVisible(target, duration: const Duration(milliseconds: 500), curve: Curves.easeInOut);
  }

  @override
  Widget build(BuildContext context) {
    final navigator = Navigator.of(context);
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            HeroSection(
              key: _keys['home'],
              header: AppHeader(onSection: _scrollTo),
              onStart: () => navigator.pushNamed(Routes.book),
            ),
            FutureBuilder<Catalog>(
              future: _catalog,
              builder: (context, snapshot) {
                final catalog = snapshot.data;
                if (catalog == null) {
                  return const SizedBox(
                    height: 240,
                    child: Center(child: CircularProgressIndicator(color: Tokens.orange)),
                  );
                }
                return Column(
                  children: [
                    AboutSection(key: _keys['about'], branches: catalog.branches),
                    CatalogSection(
                      key: _keys['product'],
                      testTypes: catalog.testTypes,
                      services: catalog.services,
                      onBook: (serviceId) => navigator.pushNamed(Routes.book, arguments: serviceId),
                    ),
                  ],
                );
              },
            ),
            const SiteFooter(),
          ],
        ),
      ),
    );
  }
}
