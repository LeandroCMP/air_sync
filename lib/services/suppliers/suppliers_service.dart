import 'package:air_sync/models/supplier_model.dart';

abstract class SuppliersService {
  Future<List<SupplierModel>> list({String? text});
  Future<SupplierModel> create({
    required String name,
    String? docNumber,
    String? phone,
    String? email,
    String? notes,
  });
  Future<void> update(String id, Map<String, dynamic> fields);
  Future<void> delete(String id);
}

