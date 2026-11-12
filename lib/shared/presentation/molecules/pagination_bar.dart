import 'package:flutter/material.dart';
import 'package:medicalbooking_portal/core/design/tokens.dart';

/// How many rows a list shows at first, and the sizes the person can choose.
const defaultPageSize = 5;
const pageSizes = [5, 10, 20];

/// The part of [items] shown on [page] (starting at 0). A page past the end shows the last one.
List<T> pageOf<T>(List<T> items, int page, int size) {
  if (items.isEmpty) return const [];
  final last = (items.length - 1) ~/ size;
  final start = (page.clamp(0, last)) * size;
  return items.sublist(start, (start + size).clamp(0, items.length));
}

/// Presentational: "Mostrando 1–5 de 12", the page size and previous/next. Hidden when everything fits on
/// the smallest page and nothing can change.
class PaginationBar extends StatelessWidget {
  const PaginationBar({
    super.key,
    required this.total,
    required this.page,
    required this.pageSize,
    required this.onPage,
    required this.onPageSize,
  });

  final int total;
  final int page;
  final int pageSize;
  final ValueChanged<int> onPage;
  final ValueChanged<int> onPageSize;

  @override
  Widget build(BuildContext context) {
    if (total <= pageSizes.first) return const SizedBox.shrink();
    final pages = ((total - 1) ~/ pageSize) + 1;
    final current = page.clamp(0, pages - 1);
    final from = current * pageSize + 1;
    final to = ((current + 1) * pageSize).clamp(0, total);
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Wrap(
        spacing: 16,
        runSpacing: 8,
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text(
            'Mostrando $from–$to de $total',
            style: const TextStyle(color: Tokens.muted, fontSize: 13),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Por página',
                style: TextStyle(color: Tokens.muted, fontSize: 13),
              ),
              const SizedBox(width: 8),
              DropdownButton<int>(
                value: pageSize,
                underline: const SizedBox.shrink(),
                items: [
                  for (final size in pageSizes)
                    DropdownMenuItem(value: size, child: Text('$size')),
                ],
                onChanged: (value) => onPageSize(value ?? defaultPageSize),
              ),
              const SizedBox(width: 8),
              IconButton(
                tooltip: 'Página anterior',
                onPressed: current == 0 ? null : () => onPage(current - 1),
                icon: const Icon(Icons.chevron_left),
              ),
              Text(
                '${current + 1} de $pages',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: Tokens.slate700,
                ),
              ),
              IconButton(
                tooltip: 'Página siguiente',
                onPressed: current >= pages - 1
                    ? null
                    : () => onPage(current + 1),
                icon: const Icon(Icons.chevron_right),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
