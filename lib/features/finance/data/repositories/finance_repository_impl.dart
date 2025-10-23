import 'package:dartz/dartz.dart';

import '../../../../core/errors/error_mapper.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/dre_report.dart';
import '../../domain/entities/finance_transaction.dart';
import '../../domain/entities/kpi_report.dart';
import '../../domain/repositories/finance_repository.dart';
import '../datasources/finance_local_data_source.dart';
import '../datasources/finance_remote_data_source.dart';
import '../models/finance_transaction_model.dart';

class FinanceRepositoryImpl implements FinanceRepository {
  FinanceRepositoryImpl({required FinanceRemoteDataSource remoteDataSource, required FinanceLocalDataSource localDataSource})
      : _remoteDataSource = remoteDataSource,
        _localDataSource = localDataSource;

  final FinanceRemoteDataSource _remoteDataSource;
  final FinanceLocalDataSource _localDataSource;

  @override
  Future<Either<Failure, DreReport>> dre() async {
    try {
      final json = await _remoteDataSource.fetchDre();
      return Right(DreReport(
        revenue: (json['revenue'] as num? ?? 0).toDouble(),
        costs: (json['costs'] as num? ?? 0).toDouble(),
        expenses: (json['expenses'] as num? ?? 0).toDouble(),
      ));
    } catch (error) {
      return Left(mapExceptionToFailure(error));
    }
  }

  @override
  Future<Either<Failure, FinanceTransaction>> getById(String id) async {
    try {
      final json = await _remoteDataSource.fetchTransaction(id);
      final model = FinanceTransactionModel.fromJson(json);
      await _localDataSource.upsert(model);
      return Right(model);
    } catch (error) {
      return Left(mapExceptionToFailure(error));
    }
  }

  @override
  Future<Either<Failure, List<FinanceKpiReport>>> kpis() async {
    try {
      final jsonList = await _remoteDataSource.fetchKpis();
      final reports = jsonList
          .map(
            (e) => FinanceKpiReport(
              month: e['month'] as String? ?? '',
              revenue: (e['revenue'] as num? ?? 0).toDouble(),
              expenses: (e['expenses'] as num? ?? 0).toDouble(),
              receivables: (e['receivables'] as num? ?? 0).toDouble(),
              payables: (e['payables'] as num? ?? 0).toDouble(),
            ),
          )
          .toList();
      return Right(reports);
    } catch (error) {
      return Left(mapExceptionToFailure(error));
    }
  }

  @override
  Future<Either<Failure, List<FinanceTransaction>>> list({String? type}) async {
    try {
      final jsonList = await _remoteDataSource.fetchTransactions(type: type);
      final items = jsonList.map(FinanceTransactionModel.fromJson).toList();
      for (final item in items) {
        await _localDataSource.upsert(item);
      }
      return Right(items);
    } catch (error) {
      final cache = await _localDataSource.fetchAll();
      if (cache.isNotEmpty) {
        return Right(cache);
      }
      return Left(mapExceptionToFailure(error));
    }
  }

  @override
  Future<Either<Failure, void>> pay(String id, Map<String, dynamic> payload) async {
    try {
      await _remoteDataSource.pay(id, payload);
      return const Right(null);
    } catch (error) {
      return Left(mapExceptionToFailure(error));
    }
  }
}
