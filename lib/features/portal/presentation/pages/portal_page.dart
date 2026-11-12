import 'package:flutter/material.dart';
import 'package:medicalbooking_portal/features/payments/domain/entities/checkout_start.dart';
import 'package:medicalbooking_portal/features/payments/presentation/pages/payment_dialog.dart';
import 'package:medicalbooking_portal/shared/presentation/layout/modal_route.dart';
import 'package:medicalbooking_portal/features/payments/presentation/widgets/payment_methods_section.dart';
import 'package:medicalbooking_portal/app/app_scope.dart';
import 'package:medicalbooking_portal/app/dependencies.dart';
import 'package:medicalbooking_portal/features/auth/domain/entities/patient.dart';
import 'package:medicalbooking_portal/shared/presentation/error_message.dart';
import 'package:medicalbooking_portal/app/routes.dart';
import 'package:medicalbooking_portal/app/widgets/page_shell.dart';
import 'package:medicalbooking_portal/core/design/tokens.dart';
import 'package:medicalbooking_portal/features/booking/domain/entities/appointment.dart';
import 'package:medicalbooking_portal/features/booking/presentation/widgets/appointment_card.dart';
import 'package:medicalbooking_portal/features/booking/presentation/widgets/next_appointment_card.dart';
import 'package:medicalbooking_portal/features/portal/presentation/widgets/summary_tiles.dart';
import 'package:medicalbooking_portal/features/lab_results/presentation/widgets/order_card.dart';
import 'package:medicalbooking_portal/features/lab_results/presentation/widgets/results_dialog.dart';
import 'package:medicalbooking_portal/features/portal/presentation/controllers/portal_controller.dart';
import 'package:medicalbooking_portal/features/portal/presentation/widgets/profile_summary.dart';
import 'package:medicalbooking_portal/features/profile/presentation/widgets/profile_prompt.dart';
import 'package:medicalbooking_portal/shared/presentation/layout/responsive.dart';
import 'package:medicalbooking_portal/shared/presentation/molecules/error_banner.dart';
import 'package:medicalbooking_portal/shared/presentation/molecules/info_banner.dart';
import 'package:medicalbooking_portal/shared/presentation/molecules/pagination_bar.dart';
import 'package:medicalbooking_portal/shared/presentation/molecules/pill_tabs.dart';
import 'package:medicalbooking_portal/shared/presentation/molecules/panel.dart';
import 'package:medicalbooking_portal/shared/presentation/organisms/site_footer.dart';

/// Container: loads the patient's appointments and lab orders.
class PortalPage extends StatefulWidget {
  const PortalPage({super.key, this.justBookedId});

  /// Set right after a reservation, to confirm it to the patient.
  final String? justBookedId;

  @override
  State<PortalPage> createState() => _PortalPageState();
}

/// Which appointments the list shows.
enum _Filter {
  all('Todas'),
  toPay('Por pagar'),
  confirmed('Confirmadas'),
  past('Anteriores');

  const _Filter(this.label);

  final String label;

  bool matches(AppointmentStatus status) => switch (this) {
    _Filter.all => true,
    _Filter.toPay => status == AppointmentStatus.pendingPayment,
    _Filter.confirmed => status == AppointmentStatus.confirmed,
    _Filter.past =>
      status != AppointmentStatus.pendingPayment &&
          status != AppointmentStatus.confirmed,
  };
}

class _PortalPageState extends State<PortalPage> {
  late final PortalController _controller;
  int _tab = 0;
  _Filter _filter = _Filter.all;
  int _appointmentPage = 0;
  int _appointmentSize = defaultPageSize;
  int _orderPage = 0;
  int _orderSize = defaultPageSize;

  @override
  void initState() {
    super.initState();
    final deps = AppScope.of(context);
    _controller = PortalController(
      getMyAppointments: deps.getMyAppointments,
      getMyLabOrders: deps.getMyLabOrders,
      cancelAppointment: deps.cancelAppointment,
      startCheckout: deps.startCheckout,
      getSavedCard: deps.getSavedCard,
      removeSavedCard: deps.removeSavedCard,
      session: deps.session,
    )..load();
    final patient = deps.session.patient;
    if (patient != null) deps.clinicalProfiles.load(patient.id);

    final id = widget.justBookedId;
    if (id == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Reserva $id creada. Tu horario se retiene ${Appointment.reservationHold.inMinutes} minutos.',
          ),
        ),
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _pay(Appointment appointment) async {
    final deps = AppScope.of(context);
    final start = await _controller.pay(appointment);
    if (!mounted) return;
    switch (start) {
      case RedirectTo(:final page):
        deps.openPage(page);
      case Embedded():
        final sent = await Navigator.of(context).push<bool>(
          modalRoute<bool>(
            settings: const RouteSettings(name: Routes.pay),
            builder: (_) =>
                PaymentDialog(appointment: appointment, checkout: start),
          ),
        );
        if (sent == true) await _controller.paymentSent(appointment);
      case null:
        break;
    }
  }

  Future<void> _confirmRemoveCard() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Quitar tu tarjeta guardada?'),
        content: const Text(
          'Tendrás que escribir la tarjeta de nuevo la próxima vez que pagues.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Volver'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Quitar tarjeta'),
          ),
        ],
      ),
    );
    if (confirmed == true) await _controller.removeCard();
  }

  Future<void> _confirmCancel(Appointment appointment) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Cancelar esta cita?'),
        content: const Text('El horario quedará libre para otros pacientes.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Volver'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Cancelar cita'),
          ),
        ],
      ),
    );
    if (confirmed == true) await _controller.cancel(appointment);
  }

  @override
  Widget build(BuildContext context) {
    final deps = AppScope.of(context);
    return PageShell(
      child: ListenableBuilder(
        listenable: _controller,
        builder: (context, _) {
          final patient = deps.session.patient;
          if (patient == null) return const SizedBox.shrink();
          final error = _controller.error;
          final notice = _controller.notice;
          return SingleChildScrollView(
            primary: true, // desktop web: lets the keyboard (arrows, Page Up/Down) scroll the page
            child: Column(
              children: [
                Stack(
                  children: [
                    const Positioned(top: 0, left: 0, right: 0, height: 190, child: _Band()),
                    Constrained(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 28, bottom: 40),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _Greeting(
                          name: patient.firstName,
                          onBook: () => Navigator.of(context).pushNamed(Routes.book),
                        ),
                        const SizedBox(height: 56),
                        LayoutBuilder(
                          builder: (context, constraints) {
                            // Wide: the appointments take the main column and the account sits beside them.
                            final wide = constraints.maxWidth >= 920;
                            final prompt = ListenableBuilder(
                              listenable: deps.clinicalProfiles,
                              builder: (context, _) => ProfilePrompt(
                                profile: deps.clinicalProfiles.of(patient.id),
                                onOpen: () => Navigator.of(context).pushNamed(Routes.profile),
                              ),
                            );
                            final main = _main(deps, patient, error, notice);
                            if (wide) {
                              return Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(child: main),
                                  const SizedBox(width: 28),
                                  SizedBox(
                                    width: 320,
                                    child: Column(
                                      children: [
                                        const SizedBox(height: 64),
                                        ProfileSummary(patient, vertical: true),
                                        const SizedBox(height: 16),
                                        prompt,
                                      ],
                                    ),
                                  ),
                                ],
                              );
                            }
                            // Phone: the clinical profile first (it unlocks the results), the account last.
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [prompt, const SizedBox(height: 16), main, const SizedBox(height: 16), ProfileSummary(patient)],
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                  ],
                ),
                SiteFooter(demo: AppScope.of(context).isDemo),
              ],
            ),
          );
        },
      ),
    );
  }

  /// The next appointment that still holds its slot, shown large while the list is unfiltered.
  Appointment? get _featured {
    if (_filter != _Filter.all) return null;
    final now = DateTime.now().toUtc();
    final upcoming = [
      for (final a in _controller.appointments)
        if (a.holdsSlot && a.slot.startUtc.isAfter(now)) a,
    ]..sort((a, b) => a.slot.startUtc.compareTo(b.slot.startUtc));
    return upcoming.isEmpty ? null : upcoming.first;
  }

  /// Tabs (with the appointment filters on the same row), notices and the content of the chosen tab.
  Widget _main(AppDependencies deps, Patient patient, ErrorView? error, String? notice) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      if (_tab == 0 && !_controller.loading) ...[
        if (_featured != null) ...[
          NextAppointmentCard(
            _featured!,
            processing: _controller.isProcessing(_featured!),
            onPay: _controller.working ? null : () => _pay(_featured!),
            onCancel: _controller.working ? null : () => _confirmCancel(_featured!),
          ),
          const SizedBox(height: 20),
        ],
        SummaryTiles(
          toPay: _controller.appointments.where((a) => a.status == AppointmentStatus.pendingPayment).length,
          confirmed: _controller.appointments.where((a) => a.status == AppointmentStatus.confirmed).length,
          resultsReady: _controller.orders.where((o) => o.hasValidatedResults).length,
          onToPay: () => setState(() {
            _filter = _Filter.toPay;
            _appointmentPage = 0;
          }),
          onConfirmed: () => setState(() {
            _filter = _Filter.confirmed;
            _appointmentPage = 0;
          }),
          onResults: () => setState(() => _tab = 1),
        ),
        const SizedBox(height: 20),
      ],
      SizedBox(
        width: double.infinity,
        child: Wrap(
          spacing: 16,
          runSpacing: 12,
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            PillTabs(
              selected: _tab,
              onSelected: (value) => setState(() => _tab = value),
              tabs: [
                PillTab('Citas', count: _controller.appointments.length, icon: Icons.event_available_outlined),
                PillTab('Resultados de laboratorio', count: _controller.orders.length, icon: Icons.science_outlined),
                const PillTab('Pagos', icon: Icons.credit_card_outlined),
              ],
            ),
            if (_tab == 0) _filters(),
          ],
        ),
      ),
      const SizedBox(height: 20),
      if (notice != null) ...[
        InfoBanner(message: notice, color: Tokens.success, icon: Icons.check_circle_outline),
        const SizedBox(height: 16),
      ],
      if (error != null) ...[
        ErrorBanner(error: error, onRetry: _controller.working ? null : _controller.load),
        const SizedBox(height: 16),
      ],
      if (_controller.loading)
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 40),
          child: Center(child: CircularProgressIndicator(color: Tokens.orange)),
        )
      else if (_tab == 0)
        ..._appointments(isDemo: deps.isDemo)
      else if (_tab == 2)
        PaymentMethodsSection(
          card: _controller.card,
          holderName: patient.displayName,
          demo: deps.isDemo,
          onRemove: _controller.working ? null : _confirmRemoveCard,
        )
      else
        ..._results(patient.displayName, isDemo: deps.isDemo),
    ],
  );

  Widget _filters() => Wrap(
    spacing: 8,
    runSpacing: 8,
    children: [
      for (final option in _Filter.values)
        FilterChip(
          label: Text(option.label),
          selected: _filter == option,
          showCheckmark: false,
          selectedColor: Tokens.blueSoft,
          onSelected: (_) => setState(() {
            _filter = option;
            _appointmentPage = 0;
          }),
        ),
    ],
  );

  List<Widget> _appointments({required bool isDemo}) {
    final all = _controller.appointments;
    final items = [
      for (final a in all)
        if (_filter.matches(a.status) && a.id != _featured?.id) a,
    ];
    return [
      if (all.isEmpty)
        _Empty(
          'Aún no tienes citas.',
          action: 'Agendar mi primera cita',
          onAction: () => Navigator.of(context).pushNamed(Routes.book),
        )
      else if (items.isEmpty && _featured == null)
        _Empty(
          'No tienes citas en "${_filter.label}".',
          action: 'Ver todas',
          onAction: () => setState(() => _filter = _Filter.all),
        ),
      for (final appointment in pageOf(
        items,
        _appointmentPage,
        _appointmentSize,
      )) ...[
        AppointmentCard(
          appointment,
          processing: _controller.isProcessing(appointment),
          onPay: _controller.working ? null : () => _pay(appointment),
          onCancel: _controller.working
              ? null
              : () => _confirmCancel(appointment),
        ),
        const SizedBox(height: 14),
      ],
      PaginationBar(
        total: items.length,
        page: _appointmentPage,
        pageSize: _appointmentSize,
        onPage: (value) => setState(() => _appointmentPage = value),
        onPageSize: (value) => setState(() {
          _appointmentSize = value;
          _appointmentPage = 0;
        }),
      ),
    ];
  }

  List<Widget> _results(String patientName, {required bool isDemo}) {
    final orders = _controller.orders;
    return [
      const InfoBanner(
        message: 'Los resultados se publican solo cuando el laboratorio los valida, y solo ves los tuyos.',
        color: Tokens.info,
        icon: Icons.lock_outline,
      ),
      const SizedBox(height: 16),
      if (orders.isEmpty)
        const _Empty(
          'Aún no tienes órdenes de laboratorio. Cuando tu médico te pida exámenes, aparecerán aquí.',
        ),
      for (final order in pageOf(orders, _orderPage, _orderSize)) ...[
        OrderCard(
          order: order,
          onViewResults: () => showResultsDialog(
            context,
            order: order,
            patientName: patientName,
          ),
        ),
        const SizedBox(height: 14),
      ],
      PaginationBar(
        total: orders.length,
        page: _orderPage,
        pageSize: _orderSize,
        onPage: (value) => setState(() => _orderPage = value),
        onPageSize: (value) => setState(() {
          _orderSize = value;
          _orderPage = 0;
        }),
      ),
    ];
  }
}

/// The name alone, with the portal tag beside it, and the main action at the right edge.
class _Greeting extends StatelessWidget {
  const _Greeting({required this.name, required this.onBook});

  final String? name;
  final VoidCallback onBook;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    child: Wrap(
      spacing: 24,
      runSpacing: 14,
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Wrap(
          spacing: 14,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              name == null ? 'Bienvenido' : 'Bienvenido, $name',
              style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w800, color: Colors.white),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.18),
                border: Border.all(color: Colors.white.withValues(alpha: 0.28)),
                borderRadius: BorderRadius.circular(999),
              ),
              child: const Text(
                'PORTAL DEL PACIENTE',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 11, letterSpacing: 1),
              ),
            ),
          ],
        ),
        FilledButton.icon(
          onPressed: onBook,
          icon: const Icon(Icons.add, size: 20),
          label: const Text('Agendar nueva cita'),
          style: FilledButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: Tokens.orangeDeep,
            minimumSize: const Size(0, 50),
            padding: const EdgeInsets.symmetric(horizontal: 26),
            elevation: 6,
            shadowColor: Colors.black.withValues(alpha: 0.3),
          ),
        ),
      ],
    ),
  );
}

/// The deep blue band behind the greeting, with soft shapes for depth. The cards of the page overlap its lower edge.
class _Band extends StatelessWidget {
  const _Band();

  @override
  Widget build(BuildContext context) => ClipRect(
    child: DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Tokens.blueDeep, Tokens.blue]),
      ),
      child: Stack(
        children: [
          Positioned(right: -80, top: -140, child: _Disc(420, fill: Colors.white.withValues(alpha: 0.07))),
          Positioned(right: 140, top: 30, child: _Disc(200, ring: Colors.white.withValues(alpha: 0.18))),
          Positioned(left: -60, bottom: -120, child: _Disc(300, fill: Tokens.orange.withValues(alpha: 0.30))),
        ],
      ),
    ),
  );
}

class _Disc extends StatelessWidget {
  const _Disc(this.size, {this.fill, this.ring});

  final double size;
  final Color? fill;
  final Color? ring;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(shape: BoxShape.circle, color: fill, border: ring == null ? null : Border.all(color: ring!)),
  );
}

class _Empty extends StatelessWidget {
  const _Empty(this.message, {this.action, this.onAction});

  final String message;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => Panel(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(message, style: const TextStyle(color: Tokens.muted)),
        if (action != null) ...[
          const SizedBox(height: 10),
          OutlinedButton(onPressed: onAction, child: Text(action!)),
        ],
      ],
    ),
  );
}
