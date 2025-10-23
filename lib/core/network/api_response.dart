class ApiResponse<T> {
  ApiResponse({required this.data, this.meta});

  final T data;
  final ApiPaginationMeta? meta;
}

class ApiPaginationMeta {
  ApiPaginationMeta({required this.total, required this.page, required this.limit});

  final int total;
  final int page;
  final int limit;

  factory ApiPaginationMeta.fromJson(Map<String, dynamic> json) => ApiPaginationMeta(
        total: json['total'] as int? ?? 0,
        page: json['page'] as int? ?? 1,
        limit: json['limit'] as int? ?? 0,
      );
}
