import 'package:flutter/material.dart';
import 'package:medicalbooking_portal/app/app_scope.dart';
import 'package:medicalbooking_portal/app/routes.dart';
import 'package:medicalbooking_portal/core/design/tokens.dart';
import 'package:medicalbooking_portal/core/format/es_format.dart';
import 'package:medicalbooking_portal/core/time/branch_time.dart';
import 'package:medicalbooking_portal/features/booking/domain/entities/appointment.dart';
import 'package:medicalbooking_portal/features/booking/domain/usecases/reserve_appointment.dart';
import 'package:medicalbooking_portal/features/booking/presentation/controllers/booking_controller.dart';
import 'package:medicalbooking_portal/features/booking/presentation/widgets/booking_aside.dart';
import 'package:medicalbooking_portal/features/booking/presentation/widgets/booking_summary.dart';
import 'package:medicalbooking_portal/features/booking/presentation/widgets/service_picker.dart';
import 'package:medicalbooking_portal/features/booking/presentation/widgets/slot_picker.dart';
import 'package:medicalbooking_portal/features/catalog/domain/entities/catalog.dart';
import 'package:medicalbooking_portal/shared/presentation/atoms/gradient_button.dart';
import 'package:medicalbooking_portal/shared/presentation/organisms/two_panel_modal.dart';

const _demoFootnote =
    'Demo: las 10:30 parecen libres, pero otro paciente siempre las toma al confirmar, '
    'para mostrar que la disponibilidad se valida de nuevo.';
const _liveFootnote =
    'Solo se muestran horarios libres, en hora de la sede (UTC-5). La disponibilidad se valida de nuevo al confirmar.';

/// Container: loads the services, then hands over to [_BookingFlow].
class BookingDialog extends StatefulWidget {
  const BookingDialog({super.key, this.serviceId});

  final String? serviceId;

  @override
  State<BookingDialog> createState() => _BookingDialogState();
}

class _BookingDialogState extends State<BookingDialog> {
  late final Future<Catalog> _catalog = AppScope.of(context).getCatalog();

  @override
  Widget build(BuildContext context) => FutureBuilder<Catalog>(
    future: _catalog,
    builder: (context, snapshot) {
      final catalog = snapshot.data;
      if (catalog == null) {
        return const Material(
          type: MaterialType.transparency,
          child: Center(child: CircularProgressIndicator(color: Colors.white)),
        );
      }
      return _BookingFlow(services: catalog.services, initialServiceId: widget.serviceId);
    },
  );
}

class _BookingFlow extends StatefulWidget {
  const _BookingFlow({required this.services, this.initialServiceId});

  final List<MedicalService> services;
  final String? initialServiceId;

  @override
  State<_BookingFlow> createState() => _BookingFlowState();
}

class _BookingFlowState extends State<_BookingFlow> {
  late final BookingController _controller;
  final _reason = TextEditingController();
  int _step = 1;

  @override
  void initState() {
    super.initState();
    final deps = AppScope.of(context);
    _controller = BookingController(
      getDaySlots: deps.getDaySlots,
      reserveAppointment: deps.reserveAppointment,
      session: deps.session,
      services: widget.services,
      initialServiceId: widget.initialServiceId,
    )..loadSlots();
  }

  @override
  void dispose() {
    _controller.dispose();
    _reason.dispose();
    super.dispose();
  }

  Future<void> _confirm() async {
    final navigator = Navigator.of(context);
    final appointment = await _controller.confirm(reason: _reason.text);
    if (appointment != null && mounted) {
      // Close the modal and show the portal with the new appointment on top.
      navigator.pushNamedAndRemoveUntil(Routes.portal, (route) => route.isFirst, arguments: appointment.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final deps = AppScope.of(context);
    final phone = MediaQuery.sizeOf(context).width < modalSplitWidth;
    final hold = Appointment.reservationHold.inMinutes;
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        final c = _controller;
        return TwoPanelModal(
          tag: 'Nueva cita',
          headline: 'Reservar una cita',
          bullets: const [],
          footerLabel: 'Hora de la sede',
          footerNote: 'UTC-5',
          aside: BookingAside(service: c.service, slot: c.selectedSlot, day: c.day, holdMinutes: hold),
          header: _Header(step: _step),
          // Pinned under the scrolling form, so "Continuar" is always visible with what was chosen.
          action: _step == 1 ? _Action(controller: c, onContinue: () => setState(() => _step = 2)) : null,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (phone) ...[_Stepper(step: _step), const SizedBox(height: 18)],
              if (_step == 1) ...[
                const _Label('1 · Servicio'),
                const SizedBox(height: 8),
                ServicePicker(services: c.services, selected: c.service, onSelect: c.selectService),
                const SizedBox(height: 18),
                SlotPicker(
                  days: c.days,
                  selectedDay: c.day,
                  slots: c.slots,
                  selectedSlot: c.selectedSlot,
                  loading: c.loadingSlots,
                  error: c.slotsError,
                  footnote: deps.isDemo ? _demoFootnote : _liveFootnote,
                  onDay: c.selectDay,
                  onSlot: c.selectSlot,
                ),
                const SizedBox(height: 18),
                const _Label('Motivo (opcional)'),
                const SizedBox(height: 6),
                TextField(
                  controller: _reason,
                  maxLength: ReserveAppointment.maxReasonLength,
                  decoration: const InputDecoration(hintText: 'Ej.: control de glucosa en ayunas', counterText: ''),
                ),
              ] else ...[
                BookingSummary(
                  service: c.service,
                  slot: c.selectedSlot,
                  conflictedSlot: c.conflictedSlot,
                  error: c.reserveError,
                  submitting: c.submitting,
                  canConfirm: c.canConfirm,
                  holdMinutes: hold,
                  onConfirm: _confirm,
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: c.submitting ? null : () => setState(() => _step = 1),
                    icon: const Icon(Icons.arrow_back, size: 16),
                    label: const Text('Cambiar servicio u hora'),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

/// What was chosen, plus the main button: the pinned footer of step 1.
class _Action extends StatelessWidget {
  const _Action({required this.controller, required this.onContinue});

  final BookingController controller;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final slot = controller.selectedSlot;
    final summary = slot == null
        ? 'Elige un horario para continuar'
        : '${controller.service.name} · ${dayLabel(branchTime(slot.startUtc))} · ${timeLabel(branchTime(slot.startUtc))}';
    final button = GradientButton(label: 'Continuar', trailing: Icons.arrow_forward, onPressed: slot == null ? null : onContinue);
    return LayoutBuilder(
      builder: (context, constraints) {
        final summaryText = Text(
          summary,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 13, color: Tokens.slate600, fontWeight: FontWeight.w600),
        );
        if (constraints.maxWidth >= 480) {
          return Row(children: [Expanded(child: summaryText), const SizedBox(width: 20), SizedBox(width: 200, child: button)]);
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [summaryText, const SizedBox(height: 10), button],
        );
      },
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text.toUpperCase(),
    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 0.6, color: Tokens.blueText),
  );
}

/// Wide screens: eyebrow, title and the two steps, pinned above the scrolling form.
class _Header extends StatelessWidget {
  const _Header({required this.step});

  final int step;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Container(width: 18, height: 2, color: Tokens.orange),
          const SizedBox(width: 8),
          const Text('NUEVA CITA', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.8, color: Tokens.orangeDeep)),
        ],
      ),
      const SizedBox(height: 6),
      const Text('Reservar una cita', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: Tokens.slate900)),
      const SizedBox(height: 14),
      _Stepper(step: step),
    ],
  );
}

class _Stepper extends StatelessWidget {
  const _Stepper({required this.step});

  final int step;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      _Step(1, 'Servicio y horario', active: step == 1, done: step > 1),
      Container(width: 40, height: 2, margin: const EdgeInsets.symmetric(horizontal: 10), color: Tokens.slate200),
      _Step(2, 'Confirmación', active: step == 2, done: false),
    ],
  );
}

class _Step extends StatelessWidget {
  const _Step(this.number, this.label, {required this.active, required this.done});

  final int number;
  final String label;
  final bool active;
  final bool done;

  @override
  Widget build(BuildContext context) {
    final on = active || done;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 22,
          height: 22,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: on ? Tokens.orange : Colors.white,
            shape: BoxShape.circle,
            border: on ? null : Border.all(color: Tokens.slate200, width: 2),
          ),
          child: done
              ? const Icon(Icons.check, size: 14, color: Colors.white)
              : Text('$number', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: on ? Colors.white : Tokens.muted)),
        ),
        const SizedBox(width: 8),
        Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: on ? Tokens.orangeDeep : Tokens.muted)),
      ],
    );
  }
}
