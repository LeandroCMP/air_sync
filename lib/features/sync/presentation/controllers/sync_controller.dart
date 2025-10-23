import 'package:get/get.dart';

import '../../domain/entities/sync_change.dart';
import '../../domain/usecases/process_sync_queue_usecase.dart';
import '../../domain/usecases/sync_now_usecase.dart';

class SyncController extends GetxController {
  SyncController(this._syncNowUseCase, this._processQueueUseCase);

  final SyncNowUseCase _syncNowUseCase;
  final ProcessSyncQueueUseCase _processQueueUseCase;

  final changes = <SyncChange>[].obs;
  final lastSync = Rxn<DateTime>();
  final isSyncing = false.obs;
  final error = RxnString();

  Future<void> sync() async {
    isSyncing.value = true;
    error.value = null;
    final result = await _syncNowUseCase.call(lastSync.value);
    isSyncing.value = false;
    result.fold(
      (failure) => error.value = failure.message,
      (data) {
        changes.assignAll(data);
        lastSync.value = DateTime.now();
        Get.snackbar('Sincronização concluída', '${data.length} alterações recebidas');
      },
    );
  }

  Future<void> processQueue() async {
    final result = await _processQueueUseCase.call();
    result.fold(
      (failure) => Get.snackbar('Erro', failure.message),
      (_) => Get.snackbar('Fila offline', 'Todos os eventos foram enviados'),
    );
  }
}
