import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medicalbooking_portal/features/catalog/domain/entities/catalog.dart';
import 'package:medicalbooking_portal/features/catalog/presentation/widgets/catalog_section.dart';

const _services = [
  MedicalService(id: 's1', name: 'Servicio uno', durationMin: 20, basePrice: 8),
  MedicalService(id: 's2', name: 'Servicio dos', durationMin: 15, basePrice: 6),
  MedicalService(id: 's3', name: 'Servicio tres', durationMin: 30, basePrice: 25),
  MedicalService(id: 's4', name: 'Servicio cuatro', durationMin: 30, basePrice: 30),
  MedicalService(id: 's5', name: 'Servicio cinco', durationMin: 20, basePrice: 15),
];

Widget _host(List<MedicalService> services, {void Function(String)? onBook}) => MaterialApp(
  home: Scaffold(
    body: SingleChildScrollView(
      child: ServiceCarousel(services: services, onBook: onBook ?? (_) {}),
    ),
  ),
);

void main() {
  testWidgets('shows four services per group and moves between groups with the arrows', (tester) async {
    tester.view.physicalSize = const Size(1200, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(_host(_services));

    expect(find.text('Servicio uno'), findsOneWidget);
    expect(find.text('Servicio cuatro'), findsOneWidget);
    expect(find.text('Servicio cinco'), findsNothing);
    expect(find.bySemanticsLabel('Grupo 2 de 2'), findsOneWidget);

    await tester.tap(find.byTooltip('Grupo siguiente'));
    await tester.pumpAndSettle();

    expect(find.text('Servicio cinco'), findsOneWidget);
    expect(find.text('Servicio uno'), findsNothing);
  });

  testWidgets('a group of services reserves the one tapped', (tester) async {
    tester.view.physicalSize = const Size(1200, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    String? booked;

    await tester.pumpWidget(_host(_services, onBook: (id) => booked = id));
    await tester.tap(find.widgetWithText(FilledButton, 'Reservar').at(2));

    expect(booked, 's3');
  });

  testWidgets('without services it says how to see them instead of an empty list', (tester) async {
    await tester.pumpWidget(_host(const []));

    expect(find.text('Inicia sesión para ver los servicios que puedes reservar.'), findsOneWidget);
    expect(find.byTooltip('Grupo siguiente'), findsNothing);
  });
}
