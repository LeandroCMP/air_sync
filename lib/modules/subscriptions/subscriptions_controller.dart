import 'dart:async';

import 'package:air_sync/application/auth/auth_service_application.dart';
import 'package:air_sync/application/core/network/app_config.dart';
import 'package:air_sync/application/ui/loader/loader_mixin.dart';
import 'package:air_sync/application/ui/messages/messages_mixin.dart';
import 'package:air_sync/models/subscription_models.dart';
import 'package:air_sync/services/subscriptions/subscriptions_service.dart';
import 'package:dio/dio.dart';
import 'package:get/get.dart';

class SubscriptionsController extends GetxController with LoaderMixin, MessagesMixin {
  SubscriptionsController({
    required SubscriptionsService service,
    required AuthServiceApplication auth,
  })  : _service = service,
        _auth = auth,
        _appConfig = Get.find<AppConfig>();

  final SubscriptionsService _service;
  final AuthServiceApplication _auth;
  final AppConfig _appConfig;

  final Rxn<SubscriptionCurrentModel> current = Rxn<SubscriptionCurrentModel>();
  final Rxn<SubscriptionOverviewModel> overview = Rxn<SubscriptionOverviewModel>();
  final Rxn<SubscriptionAlertModel> alerts = Rxn<SubscriptionAlertModel>();
  final invoices = <SubscriptionInvoiceModel>[].obs;
  final invoiceStatusFilter = 'all'.obs;
  final Rxn<DateTime> invoiceFrom = Rxn<DateTime>();
  final Rxn<DateTime> invoiceTo = Rxn<DateTime>();
  final RxInt invoicePage = 1.obs;
  final RxInt invoiceLimit = 50.obs;
  final isLoading = false.obs;
  final isCreatingCarnet = false.obs;
  final message = Rxn<MessageModel>();
  final isOwner = false.obs;
  final restricted = false.obs;
  final lastIntentByInvoice = <String, SubscriptionPaymentIntentResult>{}.obs;

  @override
  void onInit() {
    loaderListener(isLoading);
    messageListener(message);
    isOwner.value = _auth.user.value?.isOwner ?? false;
    ever(_auth.user, (user) => isOwner.value = user?.isOwner ?? false);
    final args = Get.arguments;
    if (args is Map && args['restricted'] == true) {
      restricted.value = true;
    }
    super.onInit();
  }

  @override
  Future<void> onReady() async {
    if (isOwner.value || restricted.value) {
      await refreshAll();
    }
    super.onReady();
  }

  Future<void> refreshAll() async {
    if (isLoading.value) return;
    isLoading.value = true;
    try {
      await Future.wait([
        loadCurrent(),
        loadOverview(),
      ]);
    } catch (error) {
      message(
        MessageModel.error(
          title: 'Assinatura',
          message: _resolveErrorMessage(
            error,
            'Não foi possível carregar os dados principais.',
          ),
        ),
      );
    } finally {
      isLoading.value = false;
    }

    try {
      await loadAlerts();
    } catch (error) {
      message(
        MessageModel.error(
          title: 'Alertas',
          message: _resolveErrorMessage(
            error,
            'Não foi possível atualizar os alertas da assinatura.',
          ),
        ),
      );
    }

    try {
      await loadInvoices();
    } catch (error) {
      message(
        MessageModel.error(
          title: 'Faturas',
          message: _resolveErrorMessage(
            error,
            'Não foi possível atualizar a lista de faturas.',
          ),
        ),
      );
    }
  }

  Future<void> loadCurrent() async {
    final data = await _withTimeout(_service.getCurrent());
    current(data);
  }

  Future<void> loadOverview() async {
    final data = await _withTimeout(_service.overview());
    overview(data);
  }

  Future<void> loadAlerts({int attempt = 0}) async {
    try {
      final data = await _withTimeout(_service.alerts());
      alerts(data);
    } catch (error) {
      if (_isDuplicateKeyError(error) && attempt < 3) {
        if (attempt == 0) {
          message(
            MessageModel.info(
              title: 'Assinatura',
              message: 'Configuração em andamento, tentando novamente...',
            ),
          );
        }
        final delay = Duration(seconds: 2 * (attempt + 1));
        Get.log(
          'subscriptions_alerts_retry duplicate key, attempt ${attempt + 1}',
        );
        await Future.delayed(delay);
        await loadAlerts(attempt: attempt + 1);
        return;
      }
      rethrow;
    }
  }

  Future<void> loadInvoices() async {
    final list = await _withTimeout(_service.invoices(
      status: invoiceStatusFilter.value == 'all' ? null : invoiceStatusFilter.value,
      from: invoiceFrom.value,
      to: invoiceTo.value,
      page: invoicePage.value,
      limit: invoiceLimit.value,
    ));
    invoices.assignAll(list);
  }

  void setInvoiceRange({DateTime? from, DateTime? to}) {
    invoiceFrom.value = from;
    invoiceTo.value = to;
    unawaited(loadInvoices());
  }

  void clearInvoiceRange() {
    invoiceFrom.value = null;
    invoiceTo.value = null;
    unawaited(loadInvoices());
  }

  Future<SubscriptionPaymentIntentResult?> createPaymentIntent({
    required String invoiceId,
    required String method,
    String? successUrl,
    String? cancelUrl,
    bool cacheResult = true,
  }) async {
    try {
      final intent = await _service.createPaymentIntent(
        invoiceId: invoiceId,
        method: method,
        successUrl: successUrl ?? _defaultSuccessUrlForTenant(),
        cancelUrl: cancelUrl ?? _defaultCancelUrlForTenant(),
      );
      if (cacheResult) {
        lastIntentByInvoice[invoiceId] = intent;
        lastIntentByInvoice.refresh();
      }
      await loadInvoices();
      return intent;
    } catch (error) {
      message(
        MessageModel.error(
          title: 'Pagamento',
          message: _resolveErrorMessage(error, 'Falha ao iniciar pagamento.'),
        ),
      );
      return null;
    }
  }

  void setInvoiceFilter(String status) {
    invoiceStatusFilter.value = status;
    unawaited(loadInvoices());
  }

  Future<void> updateCurrentSettings({
    int? billingDay,
    String? billingContactName,
    String? billingContactEmail,
    String? billingContactPhone,
    String? preferredPaymentMethod,
    String? notes,
  }) async {
    try {
      final updated = await _service.updateCurrent(
        billingDay: billingDay,
        billingContactName: billingContactName,
        billingContactEmail: billingContactEmail,
        billingContactPhone: billingContactPhone,
        preferredPaymentMethod: preferredPaymentMethod,
        notes: notes,
      );
      current(updated);
      await Future.wait([loadOverview(), loadAlerts()]);
      message(
        MessageModel.success(
          title: 'Assinatura',
          message: 'Preferências atualizadas.',
        ),
      );
    } catch (error) {
      message(
        MessageModel.error(
          title: 'Assinatura',
          message: _resolveErrorMessage(error, 'Não foi possível atualizar os dados.'),
        ),
      );
    }
  }

  Future<void> registerManualPayment({
    required String invoiceId,
    String? note,
    DateTime? paidAt,
    double? amount,
    String? idempotencyKey,
  }) async {
    try {
      await _service.payInvoice(
        invoiceId: invoiceId,
        note: note,
        paidAt: paidAt,
        amount: amount,
        idempotencyKey: idempotencyKey,
      );
      await loadInvoices();
      message(
        MessageModel.success(
          title: 'Pagamento',
          message: 'Pagamento registrado manualmente.',
        ),
      );
    } catch (error) {
      message(
        MessageModel.error(
          title: 'Pagamento',
          message: _resolveErrorMessage(error, 'Falha ao registrar pagamento.'),
        ),
      );
    }
  }

  Future<void> negotiateInvoice({
    required String invoiceId,
    required String note,
    DateTime? newDueDate,
  }) async {
    try {
      await _service.negotiateInvoice(
        invoiceId: invoiceId,
        note: note,
        newDueDate: newDueDate,
      );
      await loadInvoices();
      message(
        MessageModel.success(
          title: 'Negociação',
          message: 'Solicitação enviada ao financeiro.',
        ),
      );
    } catch (error) {
      message(
        MessageModel.error(
          title: 'Negociação',
          message: _resolveErrorMessage(error, 'Falha ao renegociar fatura.'),
        ),
      );
    }
  }

  Future<void> createCarnet({required bool payUpfront}) async {
    if (isCreatingCarnet.value) return;
    isCreatingCarnet.value = true;
    try {
      await _withTimeout(
        _service.createCarnet(payUpfront: payUpfront),
        customTimeout: const Duration(seconds: 20),
      );
      await refreshAll();
      final msg = payUpfront
          ? 'Carnê gerado à vista com 20% de desconto sobre 6 meses.'
          : 'Carnê semestral gerado em 6 parcelas mensais.';
      message(MessageModel.success(title: 'Carnê', message: msg));
    } catch (error) {
      message(
        MessageModel.error(
          title: 'Carnê',
          message: _resolveErrorMessage(
            error,
            'Não foi possível gerar o carnê.',
          ),
        ),
      );
    } finally {
      isCreatingCarnet.value = false;
    }
  }

String _resolveErrorMessage(Object error, String fallback) {
  if (error is DioException) {
    final data = error.response?.data;
    if (data is Map) {
      final nested = data['error'];
      if (nested is Map && nested['message'] is String) {
        final msg = (nested['message'] as String).trim();
        if (msg.isNotEmpty) return msg;
      }
      if (data['message'] is String) {
        final msg = (data['message'] as String).trim();
        if (msg.isNotEmpty) return msg;
      }
    }
    if (data is String && data.trim().isNotEmpty) return data.trim();
    if ((error.message ?? '').isNotEmpty) return error.message!;
  }
  return fallback;
}

  String _defaultSuccessUrlForTenant() {
    final base = _appConfig.baseUrl;
    return '$base/subscriptions/stripe/success';
  }

  String _defaultCancelUrlForTenant() {
    final base = _appConfig.baseUrl;
    return '$base/subscriptions/stripe/cancel';
  }

  Future<T> _withTimeout<T>(
    Future<T> future, {
    Duration customTimeout = const Duration(seconds: 20),
  }) {
    return future.timeout(customTimeout, onTimeout: () {
      throw TimeoutException('Tempo limite atingido. Verifique sua conexão.');
    });
  }

  bool _isDuplicateKeyError(Object error) {
    if (error is DioException) {
      final data = error.response?.data;
      if (data is Map) {
        final code = data['code']?.toString();
        final message = data['message']?.toString().toLowerCase() ?? '';
        if (code == 'UNHANDLED_ERROR' && message.contains('duplicate key')) {
          return true;
        }
      }
    }
    return false;
  }
}



