import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medicalbooking_portal/shared/presentation/molecules/pagination_bar.dart';

void main() {
  group('pageOf', () {
    final items = List.generate(12, (i) => i + 1);

    test('shows five at first, as the product asks', () {
      expect(defaultPageSize, 5);
      expect(pageOf(items, 0, defaultPageSize), [1, 2, 3, 4, 5]);
    });

    test('shows the rest on the last page and never runs past the end', () {
      expect(pageOf(items, 2, 5), [11, 12]);
      expect(pageOf(items, 9, 5), [11, 12]);
    });

    test('an empty list has an empty page', () {
      expect(pageOf(const <int>[], 0, 5), isEmpty);
    });
  });

  group('PaginationBar', () {
    Future<void> pump(
      WidgetTester tester, {
      required int total,
      int page = 0,
      int size = 5,
      ValueChanged<int>? onPage,
      ValueChanged<int>? onSize,
    }) {
      return tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PaginationBar(
              total: total,
              page: page,
              pageSize: size,
              onPage: onPage ?? (_) {},
              onPageSize: onSize ?? (_) {},
            ),
          ),
        ),
      );
    }

    testWidgets('is hidden when everything fits on the smallest page', (
      tester,
    ) async {
      await pump(tester, total: 5);

      expect(find.textContaining('Mostrando'), findsNothing);
    });

    testWidgets('says which rows are shown and moves between pages', (
      tester,
    ) async {
      final pages = <int>[];
      await pump(tester, total: 12, onPage: pages.add);

      expect(find.text('Mostrando 1–5 de 12'), findsOneWidget);
      expect(find.text('1 de 3'), findsOneWidget);
      // There is no page before the first one.
      expect(
        tester
            .widget<IconButton>(
              find.widgetWithIcon(IconButton, Icons.chevron_left),
            )
            .onPressed,
        isNull,
      );

      await tester.tap(find.byTooltip('Página siguiente'));
      expect(pages, [1]);
    });

    testWidgets('the last page ends at the total and has no next page', (
      tester,
    ) async {
      await pump(tester, total: 12, page: 2);

      expect(find.text('Mostrando 11–12 de 12'), findsOneWidget);
      expect(
        tester
            .widget<IconButton>(
              find.widgetWithIcon(IconButton, Icons.chevron_right),
            )
            .onPressed,
        isNull,
      );
    });

    testWidgets('lets the person choose how many rows per page', (
      tester,
    ) async {
      final sizes = <int>[];
      await pump(tester, total: 30, onSize: sizes.add);

      await tester.tap(find.byType(DropdownButton<int>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('10').last);
      await tester.pumpAndSettle();

      expect(sizes, [10]);
    });
  });
}
