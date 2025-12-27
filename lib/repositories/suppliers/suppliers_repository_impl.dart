import 'package:air_sync/application/core/network/api_client.dart';
import 'package:air_sync/models/supplier_model.dart';
import 'package:get/get.dart';

import 'suppliers_repository.dart';

class SuppliersRepositoryImpl implements SuppliersRepository {
  final ApiClient _api = Get.find<ApiClient>();

  @override
  Future<List<SupplierModel>> list({String? text}) async {
    final res = await _api.dio.get(
      '/v1/suppliers',
      queryParameters: (text != null && text.isNotEmpty) ? {'text': text} : null,
    );
    final data = res.data;
    if (data is List) {
      return data
          .map((e) => SupplierModel.fromMap(Map<String, dynamic>.from(e)))
          .toList();
    }
    return [];
  }

  @override
  Future<SupplierModel> create({
    required String name,
    String? docNumber,
    String? phone,
    String? email,
    String? notes,
  }) async {
    final payload = {
      'name': name,
      if (docNumber != null) 'docNumber': docNumber,
      if (phone != null) 'phone': phone,
      if (email != null) 'email': email,
      if (notes != null) 'notes': notes,
    };
    final res = await _api.dio.post('/v1/suppliers', data: payload);
    return SupplierModel.fromMap(Map<String, dynamic>.from(res.data));
  }

  @override
  Future<void> update(String id, Map<String, dynamic> fields) async {
    await _api.dio.patch('/v1/suppliers/$id', data: fields);
  }

  @override
  Future<void> delete(String id) async {
    await _api.dio
        .delete('/v1/suppliers/$id')
        .timeout(const Duration(seconds: 12));
  }
}
