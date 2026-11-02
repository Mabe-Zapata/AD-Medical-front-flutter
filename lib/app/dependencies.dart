import 'package:medicalbooking_portal/features/auth/data/repositories/demo_auth_repository.dart';
import 'package:medicalbooking_portal/features/auth/domain/usecases/sign_in.dart';
import 'package:medicalbooking_portal/features/auth/domain/usecases/sign_out.dart';
import 'package:medicalbooking_portal/features/auth/presentation/controllers/session_controller.dart';
import 'package:medicalbooking_portal/features/booking/data/repositories/demo_appointment_repository.dart';
import 'package:medicalbooking_portal/features/booking/domain/usecases/get_day_slots.dart';
import 'package:medicalbooking_portal/features/booking/domain/usecases/get_my_appointments.dart';
import 'package:medicalbooking_portal/features/booking/domain/usecases/reserve_appointment.dart';
import 'package:medicalbooking_portal/features/catalog/data/repositories/demo_catalog_repository.dart';
import 'package:medicalbooking_portal/features/catalog/domain/usecases/get_catalog.dart';
import 'package:medicalbooking_portal/features/lab_results/data/repositories/demo_lab_results_repository.dart';
import 'package:medicalbooking_portal/features/lab_results/domain/usecases/get_my_lab_orders.dart';
import 'package:medicalbooking_portal/infrastructure/demo/demo_database.dart';

/// Composition root: the only place that knows the concrete repositories.
/// Swap the `demo` factory for one backed by the REST API when it exists.
class AppDependencies {
  AppDependencies._({
    required this.session,
    required this.getCatalog,
    required this.getDaySlots,
    required this.reserveAppointment,
    required this.getMyAppointments,
    required this.getMyLabOrders,
    this.demoCredentials,
  });

  factory AppDependencies.demo({Duration latency = const Duration(milliseconds: 600)}) {
    final db = DemoDatabase(latency: latency);
    final auth = DemoAuthRepository(db);
    final appointments = DemoAppointmentRepository(db);
    return AppDependencies._(
      session: SessionController(signIn: SignIn(auth), signOut: SignOut(auth)),
      getCatalog: GetCatalog(DemoCatalogRepository(db)),
      getDaySlots: GetDaySlots(appointments),
      reserveAppointment: ReserveAppointment(appointments),
      getMyAppointments: GetMyAppointments(appointments),
      getMyLabOrders: GetMyLabOrders(DemoLabResultsRepository(db)),
      demoCredentials: (email: DemoDatabase.demoEmail, password: DemoDatabase.demoPassword),
    );
  }

  /// Only set by the demo build, to prefill and explain the login form.
  final ({String email, String password})? demoCredentials;

  final SessionController session;
  final GetCatalog getCatalog;
  final GetDaySlots getDaySlots;
  final ReserveAppointment reserveAppointment;
  final GetMyAppointments getMyAppointments;
  final GetMyLabOrders getMyLabOrders;
}
