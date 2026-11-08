import 'package:flutter/material.dart';
import 'package:medicalbooking_portal/app/app_scope.dart';
import 'package:medicalbooking_portal/app/routes.dart';
import 'package:medicalbooking_portal/core/design/tokens.dart';
import 'package:medicalbooking_portal/features/booking/domain/entities/appointment.dart';
import 'package:medicalbooking_portal/features/booking/domain/usecases/reserve_appointment.dart';
import 'package:medicalbooking_portal/features/booking/presentation/controllers/booking_controller.dart';
import 'package:medicalbooking_portal/features/booking/presentation/widgets/booking_summary.dart';
import 'package:medicalbooking_portal/features/booking/presentation/widgets/service_picker.dart';
import 'package:medicalbooking_portal/features/booking/presentation/widgets/slot_picker.dart';
import 'package:medicalbooking_portal/features/catalog/domain/entities/catalog.dart';
import 'package:medicalbooking_portal/shared/presentation/atoms/gradient_button.dart';
import 'package:medicalbooking_portal/shared/presentation/atoms/section_label.dart';
import 'package:medicalbooking_portal/shared/presentation/organisms/two_panel_modal.dart';

const _demoFootnote =
    'Las horas tachadas no están disponibles. Demo: las 10:30 parecen libres, pero otro paciente '
    'siempre las toma al confirmar, para mostrar que la disponibilidad se valida de nuevo.';
const _liveFootnote =
    'Solo se muestran los horarios libres, en hora de la sede (UTC-5). '
    'La disponibilidad se valida de nuevo al confirmar.';

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
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        final c = _controller;
        return TwoPanelModal(
          tag: 'Reserva de cita',
          headline: 'Tu cita de laboratorio, en dos pasos.',
          bullets: const [
            'Elige el servicio y un horario libre en tiempo real.',
            'El horario se retiene ${15} minutos mientras confirmas.',
            'Puedes cancelar tu cita desde tu portal cuando quieras.',
          ],
          footerLabel: 'Hora de la sede',
          footerNote: 'UTC-5',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionLabel('Nueva cita'),
              const SizedBox(height: 8),
              const Text(
                'Reservar una cita',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: Tokens.slate900),
              ),
              const SizedBox(height: 14),
              _Progress(step: _step, label: _step == 1 ? 'Servicio y horario' : 'Confirmación'),
              const SizedBox(height: 22),
              if (_step == 1) ...[
                const _Heading(1, 'Elige un servicio'),
                const SizedBox(height: 12),
                ServicePicker(services: c.services, selected: c.service, onSelect: c.selectService),
                const SizedBox(height: 24),
                const _Heading(2, 'Elige fecha y hora'),
                const SizedBox(height: 12),
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
                const SizedBox(height: 24),
                const _Heading(3, 'Motivo (opcional)'),
                const SizedBox(height: 12),
                TextField(
                  controller: _reason,
                  maxLines: 2,
                  maxLength: ReserveAppointment.maxReasonLength,
                  decoration: const InputDecoration(hintText: 'Ej.: control de glucosa en ayunas'),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: GradientButton(
                    label: 'Continuar',
                    trailing: Icons.arrow_forward,
                    onPressed: c.selectedSlot == null ? null : () => setState(() => _step = 2),
                  ),
                ),
              ] else ...[
                BookingSummary(
                  service: c.service,
                  slot: c.selectedSlot,
                  conflictedSlot: c.conflictedSlot,
                  error: c.reserveError,
                  submitting: c.submitting,
                  canConfirm: c.canConfirm,
                  holdMinutes: Appointment.reservationHold.inMinutes,
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

class _Progress extends StatelessWidget {
  const _Progress({required this.step, required this.label});

  final int step;
  final String label;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          for (var i = 1; i <= 2; i++)
            Expanded(
              child: Container(
                height: 4,
                margin: EdgeInsets.only(right: i == 1 ? 6 : 0),
                decoration: BoxDecoration(
                  gradient: i <= step ? Tokens.brandGradient : null,
                  color: i <= step ? null : Tokens.slate200,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
        ],
      ),
      const SizedBox(height: 8),
      Text(
        'PASO $step DE 2: ${label.toUpperCase()}',
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.8, color: Tokens.orangeDeep),
      ),
    ],
  );
}

class _Heading extends StatelessWidget {
  const _Heading(this.number, this.title);

  final int number;
  final String title;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Container(
        width: 26,
        height: 26,
        alignment: Alignment.center,
        decoration: const BoxDecoration(gradient: Tokens.brandGradient, shape: BoxShape.circle),
        child: Text('$number', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w800)),
      ),
      const SizedBox(width: 10),
      Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Tokens.slate900)),
    ],
  );
}
