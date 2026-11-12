import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:medicalbooking_portal/core/design/tokens.dart';

/// Below this width the modal becomes a full-screen sheet with a compact brand header.
const modalSplitWidth = 760.0;

/// Modal with a brand panel on the left and the task on the right. On phones it is a full-screen
/// sheet: a short brand header on top and the task below. Presentational: [child] is the task.
class TwoPanelModal extends StatefulWidget {
  const TwoPanelModal({
    super.key,
    required this.tag,
    required this.headline,
    required this.bullets,
    required this.footerLabel,
    required this.footerNote,
    required this.child,
    this.action,
    this.aside,
    this.asideWidth = 310,
    this.header,
  });

  final String tag;
  final String headline;
  final List<String> bullets;
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
  Widget _task(EdgeInsets padding, {Widget? header}) => Column(
    children: [
      if (header != null) Padding(padding: EdgeInsets.fromLTRB(padding.left, padding.top, padding.right, 0), child: header),
      Expanded(
        child: Scrollbar(
          controller: _scroll,
          thumbVisibility: true,
          child: SingleChildScrollView(
            controller: _scroll,
            padding: header == null ? padding : padding.copyWith(top: 18),
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            child: widget.child,
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
                      ? _task(const EdgeInsets.fromLTRB(36, 28, 36, 20))
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
        Container(
          width: double.infinity,
          decoration: const BoxDecoration(gradient: Tokens.brandGradient),
          padding: EdgeInsets.fromLTRB(20, MediaQuery.paddingOf(context).top + 12, 8, 18),
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
    padding: const EdgeInsets.fromLTRB(36, 36, 32, 28),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _TagPill(modal.tag),
        const SizedBox(height: 28),
        Text(
          modal.headline,
          style: const TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.w800, height: 1.15),
        ),
        const SizedBox(height: 28),
        Container(height: 1, color: Colors.white.withValues(alpha: 0.25)),
        const SizedBox(height: 22),
        for (final bullet in modal.bullets)
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  margin: const EdgeInsets.only(top: 7, right: 12),
                  decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                ),
                Expanded(
                  child: Text(bullet, style: const TextStyle(color: Colors.white, fontSize: 14.5, height: 1.4)),
                ),
              ],
            ),
          ),
        const Spacer(),
        Container(height: 1, color: Colors.white.withValues(alpha: 0.25)),
        const SizedBox(height: 16),
        Row(
          children: [
            const Icon(Icons.verified_outlined, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                modal.footerLabel.toUpperCase(),
                style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.8),
              ),
            ),
            Flexible(
              child: Text(modal.footerNote, textAlign: TextAlign.end, style: const TextStyle(color: Colors.white70, fontSize: 12)),
            ),
          ],
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
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(999)),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.add_circle, color: Colors.white, size: 14),
        const SizedBox(width: 6),
        Text(
          text.toUpperCase(),
          style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.8),
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
    icon: Icon(Icons.close, color: dark ? Tokens.slate600 : Colors.white),
    style: IconButton.styleFrom(backgroundColor: dark ? Tokens.slate100 : Colors.white.withValues(alpha: 0.2)),
  );
}
