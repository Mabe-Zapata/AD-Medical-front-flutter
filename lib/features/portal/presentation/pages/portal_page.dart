import 'package:flutter/material.dart';
import 'package:medicalbooking_portal/app/app_scope.dart';
import 'package:medicalbooking_portal/app/routes.dart';
import 'package:medicalbooking_portal/app/widgets/page_shell.dart';
import 'package:medicalbooking_portal/core/design/tokens.dart';
import 'package:medicalbooking_portal/features/booking/domain/entities/appointment.dart';
import 'package:medicalbooking_portal/features/booking/presentation/widgets/appointment_card.dart';
import 'package:medicalbooking_portal/features/lab_results/presentation/widgets/order_card.dart';
import 'package:medicalbooking_portal/features/lab_results/presentation/widgets/results_dialog.dart';
import 'package:medicalbooking_portal/features/portal/presentation/controllers/portal_controller.dart';
import 'package:medicalbooking_portal/features/portal/presentation/widgets/profile_summary.dart';
import 'package:medicalbooking_portal/shared/presentation/atoms/gradient_button.dart';
import 'package:medicalbooking_portal/shared/presentation/layout/responsive.dart';
import 'package:medicalbooking_portal/shared/presentation/molecules/info_banner.dart';
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

class _PortalPageState extends State<PortalPage> {
  late final PortalController _controller;
  int _tab = 0;

  @override
  void initState() {
    super.initState();
    final deps = AppScope.of(context);
    _controller = PortalController(
      getMyAppointments: deps.getMyAppointments,
      getMyLabOrders: deps.getMyLabOrders,
      session: deps.session,
    )..load();

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

  @override
  Widget build(BuildContext context) {
    final session = AppScope.of(context).session;
    return PageShell(
      child: ListenableBuilder(
        listenable: _controller,
        builder: (context, _) {
          final patient = session.patient;
          if (patient == null) return const SizedBox.shrink();
          return SingleChildScrollView(
            child: Column(
              children: [
                Constrained(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 8, bottom: 40),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: 24,
                          runSpacing: 12,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(
                              'Hola, ${patient.firstName}',
                              style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w800, color: Tokens.slate900),
                            ),
                            GradientButton(
                              label: 'Nueva cita',
                              onPressed: () => Navigator.of(context).pushNamed(Routes.book),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        ProfileSummary(patient),
                        const SizedBox(height: 28),
                        SegmentedButton<int>(
                          segments: [
                            ButtonSegment(value: 0, label: Text('Citas (${_controller.appointments.length})')),
                            ButtonSegment(value: 1, label: Text('Resultados de laboratorio (${_controller.orders.length})')),
                          ],
                          selected: {_tab},
                          onSelectionChanged: (selection) => setState(() => _tab = selection.first),
                        ),
                        const SizedBox(height: 20),
                        if (_controller.loading)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 40),
                            child: Center(child: CircularProgressIndicator(color: Tokens.orange)),
                          )
                        else if (_tab == 0)
                          ..._appointments()
                        else
                          ..._results(patient.fullName),
                      ],
                    ),
                  ),
                ),
                const SiteFooter(),
              ],
            ),
          );
        },
      ),
    );
  }

  List<Widget> _appointments() {
    final items = _controller.appointments;
    if (items.isEmpty) return [const _Empty('Aún no tienes citas.')];
    return [
      for (final appointment in items) ...[AppointmentCard(appointment), const SizedBox(height: 14)],
    ];
  }

  List<Widget> _results(String patientName) {
    final orders = _controller.orders;
    return [
      const InfoBanner(
        message: 'Los resultados se publican solo cuando el laboratorio los valida, y solo ves los tuyos.',
        color: Tokens.info,
        icon: Icons.lock_outline,
      ),
      const SizedBox(height: 16),
      if (orders.isEmpty) const _Empty('Aún no tienes órdenes de laboratorio.'),
      for (final order in orders) ...[
        OrderCard(
          order: order,
          onViewResults: () => showResultsDialog(context, order: order, patientName: patientName),
        ),
        const SizedBox(height: 14),
      ],
    ];
  }
}

class _Empty extends StatelessWidget {
  const _Empty(this.message);

  final String message;

  @override
  Widget build(BuildContext context) => Panel(child: Text(message, style: const TextStyle(color: Tokens.muted)));
}
