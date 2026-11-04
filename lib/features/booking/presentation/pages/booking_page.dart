import 'package:flutter/material.dart';
import 'package:medicalbooking_portal/app/app_scope.dart';
import 'package:medicalbooking_portal/app/routes.dart';
import 'package:medicalbooking_portal/app/widgets/page_shell.dart';
import 'package:medicalbooking_portal/core/design/tokens.dart';
import 'package:medicalbooking_portal/features/booking/domain/entities/appointment.dart';
import 'package:medicalbooking_portal/features/booking/domain/usecases/reserve_appointment.dart';
import 'package:medicalbooking_portal/features/booking/presentation/controllers/booking_controller.dart';
import 'package:medicalbooking_portal/features/booking/presentation/widgets/booking_summary.dart';
import 'package:medicalbooking_portal/features/booking/presentation/widgets/service_picker.dart';
import 'package:medicalbooking_portal/features/booking/presentation/widgets/slot_picker.dart';
import 'package:medicalbooking_portal/features/catalog/domain/entities/catalog.dart';
import 'package:medicalbooking_portal/shared/presentation/layout/responsive.dart';
import 'package:medicalbooking_portal/shared/presentation/molecules/panel.dart';
import 'package:medicalbooking_portal/shared/presentation/organisms/site_footer.dart';

const _demoFootnote =
    'Las horas tachadas no están disponibles. Demo: las 10:30 parecen libres, pero otro paciente '
    'siempre las toma al confirmar, para mostrar que la disponibilidad se valida de nuevo.';
const _liveFootnote =
    'Solo se muestran los horarios libres, en hora de la sede (UTC-5). '
    'La disponibilidad se valida de nuevo al confirmar.';

/// Container: loads the services, then hands over to [_BookingView].
class BookingPage extends StatefulWidget {
  const BookingPage({super.key, this.serviceId});

  final String? serviceId;

  @override
  State<BookingPage> createState() => _BookingPageState();
}

class _BookingPageState extends State<BookingPage> {
  late final Future<Catalog> _catalog = AppScope.of(context).getCatalog();

  @override
  Widget build(BuildContext context) => PageShell(
    child: FutureBuilder<Catalog>(
      future: _catalog,
      builder: (context, snapshot) {
        final catalog = snapshot.data;
        if (catalog == null) {
          return const Center(child: CircularProgressIndicator(color: Tokens.orange));
        }
        return _BookingView(services: catalog.services, initialServiceId: widget.serviceId);
      },
    ),
  );
}

class _BookingView extends StatefulWidget {
  const _BookingView({required this.services, this.initialServiceId});

  final List<MedicalService> services;
  final String? initialServiceId;

  @override
  State<_BookingView> createState() => _BookingViewState();
}

class _BookingViewState extends State<_BookingView> {
  late final BookingController _controller;
  final _reason = TextEditingController();

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
      navigator.pushReplacementNamed(Routes.portal, arguments: appointment.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final wide = isWide(context);
    final deps = AppScope.of(context);
    final session = deps.session;
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        final c = _controller;
        final form = Column(
          children: [
            _StepCard(
              number: 1,
              title: 'Elige un servicio',
              child: ServicePicker(services: c.services, selected: c.service, onSelect: c.selectService),
            ),
            const SizedBox(height: 20),
            _StepCard(
              number: 2,
              title: 'Elige fecha y hora',
              child: SlotPicker(
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
            ),
            const SizedBox(height: 20),
            _StepCard(
              number: 3,
              title: 'Motivo (opcional)',
              child: TextField(
                controller: _reason,
                maxLines: 3,
                maxLength: ReserveAppointment.maxReasonLength,
                decoration: const InputDecoration(hintText: 'Ej.: control de glucosa en ayunas'),
              ),
            ),
          ],
        );
        final summary = BookingSummary(
          service: c.service,
          slot: c.selectedSlot,
          conflictedSlot: c.conflictedSlot,
          error: c.reserveError,
          submitting: c.submitting,
          canConfirm: c.canConfirm,
          holdMinutes: Appointment.reservationHold.inMinutes,
          onConfirm: _confirm,
        );
        return SingleChildScrollView(
            primary: true, // desktop web: lets the keyboard (arrows, Page Up/Down) scroll the page
          child: Column(
            children: [
              Constrained(
                child: Padding(
                  padding: const EdgeInsets.only(top: 8, bottom: 40),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Reservar una cita',
                        style: TextStyle(fontSize: 36, fontWeight: FontWeight.w800, color: Tokens.slate900),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Sesión iniciada como ${session.patient?.displayName}. Las horas se muestran en hora de la sede (UTC-5).',
                        style: const TextStyle(color: Tokens.muted),
                      ),
                      const SizedBox(height: 28),
                      wide
                          ? Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(child: form),
                                const SizedBox(width: 24),
                                SizedBox(width: 340, child: summary),
                              ],
                            )
                          : Column(children: [form, const SizedBox(height: 20), summary]),
                    ],
                  ),
                ),
              ),
              SiteFooter(demo: AppScope.of(context).isDemo),
            ],
          ),
        );
      },
    );
  }
}

class _StepCard extends StatelessWidget {
  const _StepCard({required this.number, required this.title, required this.child});

  final int number;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) => Panel(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 28,
              height: 28,
              alignment: Alignment.center,
              decoration: const BoxDecoration(gradient: Tokens.brandGradient, shape: BoxShape.circle),
              child: Text('$number', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w800)),
            ),
            const SizedBox(width: 10),
            Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Tokens.slate900)),
          ],
        ),
        const SizedBox(height: 20),
        child,
      ],
    ),
  );
}
