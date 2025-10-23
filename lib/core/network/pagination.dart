class Pagination<T> {
  Pagination({required this.items, required this.meta});

  final List<T> items;
  final PaginationMeta meta;
}

class PaginationMeta {
  PaginationMeta({required this.page, required this.limit, required this.total});

  final int page;
  final int limit;
  final int total;

  factory PaginationMeta.fromJson(Map<String, dynamic> json) => PaginationMeta(
        page: json['page'] as int? ?? 1,
        limit: json['limit'] as int? ?? 20,
        total: json['total'] as int? ?? 0,
      );
}
