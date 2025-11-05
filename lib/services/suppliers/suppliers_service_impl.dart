import 'package:air_sync/models/supplier_model.dart';
import 'package:air_sync/repositories/suppliers/suppliers_repository.dart';
import 'package:air_sync/services/suppliers/suppliers_service.dart';

class SuppliersServiceImpl implements SuppliersService {
  final SuppliersRepository _repo;
  SuppliersServiceImpl({required SuppliersRepository repo}) : _repo = repo;

  @override
  Future<SupplierModel> create({
    required String name,
    String? docNumber,
    String? phone,
    String? email,
    String? notes,
  }) =>
      _repo.create(
        name: name,
        docNumber: docNumber,
        phone: phone,
        email: email,
        notes: notes,
      );

  @override
  Future<List<SupplierModel>> list({String? text}) => _repo.list(text: text);

  @override
  Future<void> update(String id, Map<String, dynamic> fields) => _repo.update(id, fields);

  @override
  Future<void> delete(String id) => _repo.delete(id);
}

