import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:medicalbooking_portal/core/design/tokens.dart';

/// Below this width the modal becomes a full-screen sheet with a compact brand header.
const modalSplitWidth = 760.0;

/// Modal with a brand panel on the left and the task on the right. On phones it is a full-screen
/// sheet: a short brand header on top and the task below. Presentational: [child] is the task.
///
/// The brand panel is orange with a blue band at the bottom, so the two brand colors sit side by side.
class TwoPanelModal extends StatefulWidget {
  const TwoPanelModal({
    super.key,
    required this.tag,
    required this.headline,
    required this.bullets,
    this.bulletIcons = const [Icons.event_available_outlined, Icons.science_outlined, Icons.verified_user_outlined],
    required this.footerLabel,
    required this.footerNote,
    required this.child,
    this.action,
    this.aside,
    this.asideWidth = 310,
    this.header,
    this.centered = false,
  });

  final String tag;
  final String headline;
  final List<String> bullets;

  /// One icon per bullet, in order; a bullet past the end of the list gets a check.
  final List<IconData> bulletIcons;
  final String footerLabel;
  final String footerNote;

  /// The task. It scrolls inside the modal when it does not fit.
  final Widget child;

  /// The main button of the task. It stays pinned below the scrolling area, so it is always within reach.
  final Widget? action;

  /// Replaces the brand panel on a wide screen (e.g. a live summary). On a phone the brand header still shows.
  final Widget? aside;
  final double asideWidth;

  /// Pinned above the scrolling task on a wide screen (title and steps); on a phone the brand header carries them.
  final Widget? header;

  /// Centers the task vertically while it fits (short forms such as sign-in); long tasks keep scrolling from the top.
  final bool centered;

  @override
  State<TwoPanelModal> createState() => _TwoPanelModalState();
}

class _TwoPanelModalState extends State<TwoPanelModal> {
  final _scroll = ScrollController();

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return size.width >= modalSplitWidth ? _wide(context, size) : _sheet(context);
  }

  /// The task with a visible scrollbar (so people see there is more below) and the pinned action underneath.
  Widget _task(EdgeInsets padding, {Widget? header, bool centered = false}) => Column(
    children: [
      if (header != null) Padding(padding: EdgeInsets.fromLTRB(padding.left, padding.top, padding.right, 0), child: header),
      Expanded(
        child: Scrollbar(
          controller: _scroll,
          thumbVisibility: true,
          child: LayoutBuilder(
            builder: (context, box) {
              final inset = header == null ? padding : padding.copyWith(top: 18);
              return SingleChildScrollView(
                controller: _scroll,
                padding: inset,
                keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                // Centered tasks sit in the middle when they fit and scroll from the top when they do not.
                child: centered
                    ? ConstrainedBox(
                        constraints: BoxConstraints(minHeight: box.maxHeight - inset.vertical),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [widget.child],
                        ),
                      )
                    : widget.child,
              );
            },
          ),
        ),
      ),
      if (widget.action != null)
        Container(
          width: double.infinity,
          padding: EdgeInsets.fromLTRB(padding.left, 12, padding.right, 14),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: Tokens.slate200)),
          ),
          child: widget.action,
        ),
    ],
  );

  Widget _wide(BuildContext context, Size size) => Center(
    child: Material(
      color: Colors.white,
      elevation: 24,
      borderRadius: BorderRadius.circular(24),
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        width: math.min(1040, size.width - 32),
        height: math.min(760, size.height - 32),
        child: Row(
          children: [
            if (widget.aside != null)
              SizedBox(width: widget.asideWidth, child: widget.aside)
            else
              Expanded(flex: 4, child: _BrandPanel(widget)),
            Expanded(
              flex: 6,
              child: Stack(
                children: [
                  widget.header == null
                      ? _task(const EdgeInsets.fromLTRB(36, 28, 36, 20), centered: widget.centered)
                      : _task(const EdgeInsets.fromLTRB(36, 26, 36, 12), header: widget.header),
                  const Positioned(top: 12, right: 12, child: _CloseButton(dark: true)),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );

  Widget _sheet(BuildContext context) => Scaffold(
    backgroundColor: Colors.white,
    body: Column(
      children: [
        ClipRRect(
          borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28)),
          child: Container(
            width: double.infinity,
            decoration: const BoxDecoration(gradient: Tokens.brandGradient),
            child: Stack(
              children: [
                Positioned(
                  right: -50,
                  top: -50,
                  child: Container(
                    width: 150,
                    height: 150,
                    decoration: const BoxDecoration(color: Tokens.blue, shape: BoxShape.circle),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(20, MediaQuery.paddingOf(context).top + 12, 8, 22),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _TagPill(widget.tag),
                            const SizedBox(height: 10),
                            Text(
                              widget.headline,
                              style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800, height: 1.15),
                            ),
                          ],
                        ),
                      ),
                      const _CloseButton(dark: false),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        Expanded(child: _task(const EdgeInsets.fromLTRB(20, 20, 20, 16))),
      ],
    ),
  );
}

class _BrandPanel extends StatelessWidget {
  const _BrandPanel(this.modal);

  final TwoPanelModal modal;

  @override
  Widget build(BuildContext context) => Container(
    decoration: const BoxDecoration(gradient: Tokens.brandGradient),
    child: Stack(
      children: [
        Positioned(
          right: -110,
          top: -110,
          child: Container(
            width: 320,
            height: 320,
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.08), shape: BoxShape.circle),
          ),
        ),
        Positioned(
          right: -30,
          top: -30,
          child: Container(
            width: 170,
            height: 170,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
            ),
          ),
        ),
        Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(36, 36, 32, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _TagPill(modal.tag),
                    const SizedBox(height: 22),
                    Text(
                      modal.headline,
                      style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w800, height: 1.12),
                    ),
                    const SizedBox(height: 24),
                    for (final (i, bullet) in modal.bullets.indexed) ...[
                      _BulletCard(icon: i < modal.bulletIcons.length ? modal.bulletIcons[i] : Icons.check, text: bullet),
                      const SizedBox(height: 12),
                    ],
                  ],
                ),
              ),
            ),
            // The blue half of the brand: a band that closes the panel with the account note.
            Container(
              height: 84,
              padding: const EdgeInsets.symmetric(horizontal: 36),
              decoration: const BoxDecoration(
                color: Tokens.blue,
                borderRadius: BorderRadius.only(topRight: Radius.circular(84)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.verified_outlined, color: Colors.white, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    modal.footerLabel.toUpperCase(),
                    style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.8),
                  ),
                  const SizedBox(width: 12),
                  Flexible(
                    child: Text(modal.footerNote, style: const TextStyle(color: Tokens.blueSoft, fontSize: 12)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

class _BulletCard extends StatelessWidget {
  const _BulletCard({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.14),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
    ),
    child: Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(color: Tokens.blue, borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.4)),
        ),
      ],
    ),
  );
}

class _TagPill extends StatelessWidget {
  const _TagPill(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
    decoration: BoxDecoration(color: Tokens.blueSoft, borderRadius: BorderRadius.circular(999)),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.add_circle, color: Tokens.blueDeep, size: 14),
        const SizedBox(width: 8),
        Text(
          text.toUpperCase(),
          style: const TextStyle(color: Tokens.blueDeep, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.9),
        ),
      ],
    ),
  );
}

class _CloseButton extends StatelessWidget {
  const _CloseButton({required this.dark});

  final bool dark;

  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: 'Cerrar',
    onPressed: () => Navigator.of(context).maybePop(),
    icon: Icon(Icons.close, color: dark ? Tokens.blueDeep : Colors.white),
    style: IconButton.styleFrom(backgroundColor: dark ? Tokens.blueTint : Colors.white.withValues(alpha: 0.2)),
  );
}
