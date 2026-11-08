import 'package:flutter/material.dart';
import 'package:medicalbooking_portal/core/design/tokens.dart';
import 'package:medicalbooking_portal/shared/presentation/layout/responsive.dart';

const brandName = 'Medilo';

/// Transparent header drawn over the page background. Presentational: it
/// only reports taps, navigation is decided by the container that uses it.
class SiteHeader extends StatelessWidget {
  const SiteHeader({
    super.key,
    required this.signedIn,
    required this.onSection,
    required this.onSignIn,
    required this.onRegister,
    required this.onOpenPortal,
    required this.onSignOut,
  });

  final bool signedIn;
  final void Function(String id) onSection;
  final VoidCallback onSignIn;
  final VoidCallback onRegister;
  final VoidCallback onOpenPortal;
  final VoidCallback onSignOut;

  static const sections = {'home': 'Inicio', 'about': 'Nosotros', 'product': 'Pruebas'};

  @override
  Widget build(BuildContext context) {
    final wide = isWide(context);
    return SizedBox(
      height: 88,
      child: Row(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(999),
            onTap: () => onSection('home'),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const _LogoMark(),
                const SizedBox(width: 14),
                Text(
                  brandName,
                  style: TextStyle(
                    fontSize: wide ? 24 : 20,
                    fontWeight: FontWeight.w800,
                    color: Tokens.slate900,
                    letterSpacing: -0.3,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          if (wide)
            for (final entry in sections.entries)
              Padding(
                padding: const EdgeInsets.only(right: 40),
                child: InkWell(
                  onTap: () => onSection(entry.key),
                  child: Text(
                    entry.value,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Tokens.slate700),
                  ),
                ),
              )
          else
            PopupMenuButton<String>(
              icon: const Icon(Icons.menu, color: Tokens.slate900),
              onSelected: onSection,
              itemBuilder: (context) => [
                for (final entry in sections.entries) PopupMenuItem(value: entry.key, child: Text(entry.value)),
              ],
            ),
          if (signedIn) ...[
            TextButton(onPressed: onOpenPortal, child: const Text('Mi portal')),
            IconButton(
              tooltip: 'Cerrar sesión',
              onPressed: onSignOut,
              icon: const Icon(Icons.logout, size: 20, color: Tokens.muted),
            ),
          ] else ...[
            if (wide) TextButton(onPressed: onRegister, child: const Text('Crear cuenta')),
            const SizedBox(width: 8),
            _SignInPill(label: wide ? 'INICIAR SESIÓN' : 'ENTRAR', onPressed: onSignIn),
          ],
        ],
      ),
    );
  }
}

class _LogoMark extends StatelessWidget {
  const _LogoMark();

  @override
  Widget build(BuildContext context) => Container(
    width: 48,
    height: 48,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      gradient: const LinearGradient(
        begin: Alignment.bottomLeft,
        end: Alignment.topRight,
        colors: [Color(0xFFF06110), Color(0xFFF9822A)],
      ),
      boxShadow: [BoxShadow(color: Tokens.orange.withValues(alpha: 0.2), blurRadius: 8, offset: const Offset(0, 3))],
    ),
    child: Center(
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withValues(alpha: 0.4), width: 2),
        ),
        child: const Icon(Icons.add, color: Colors.white, size: 20),
      ),
    ),
  );
}

class _SignInPill extends StatelessWidget {
  const _SignInPill({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      gradient: Tokens.brandGradient,
      borderRadius: BorderRadius.circular(999),
      boxShadow: [BoxShadow(color: Tokens.orange.withValues(alpha: 0.4), blurRadius: 18, offset: const Offset(0, 6))],
    ),
    child: Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
          child: Text(
            label,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 12, letterSpacing: 1),
          ),
        ),
      ),
    ),
  );
}
