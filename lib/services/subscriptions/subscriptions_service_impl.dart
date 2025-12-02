import 'package:air_sync/models/subscription_models.dart';
import 'package:air_sync/repositories/subscriptions/subscriptions_repository.dart';
import 'package:air_sync/services/subscriptions/subscriptions_service.dart';

class SubscriptionsServiceImpl implements SubscriptionsService {
  SubscriptionsServiceImpl({required SubscriptionsRepository repository})
    : _repository = repository;

  final SubscriptionsRepository _repository;

  @override
  Future<SubscriptionCurrentModel> getCurrent() => _repository.getCurrent();

  @override
  Future<SubscriptionCurrentModel> updateCurrent({
    int? billingDay,
    String? billingContactName,
    String? billingContactEmail,
    String? billingContactPhone,
    String? preferredPaymentMethod,
    String? notes,
  }) =>
      _repository.updateCurrent(
        billingDay: billingDay,
        billingContactName: billingContactName,
        billingContactEmail: billingContactEmail,
        billingContactPhone: billingContactPhone,
        preferredPaymentMethod: preferredPaymentMethod,
        notes: notes,
      );

  @override
  Future<SubscriptionOverviewModel> overview() => _repository.overview();

  @override
  Future<SubscriptionAlertModel> alerts() => _repository.alerts();

  @override
  Future<List<SubscriptionInvoiceModel>> invoices({String? status, DateTime? from, DateTime? to}) =>
      _repository.invoices(status: status, from: from, to: to);

  @override
  Future<SubscriptionPaymentIntentResult> createPaymentIntent({
    required String invoiceId,
    required String method,
    String? successUrl,
    String? cancelUrl,
  }) =>
      _repository.createPaymentIntent(
        invoiceId: invoiceId,
        method: method,
        successUrl: successUrl,
        cancelUrl: cancelUrl,
      );

  @override
  Future<SubscriptionInvoiceModel> payInvoice({
    required String invoiceId,
    String? note,
    DateTime? paidAt,
    double? amount,
  }) =>
      _repository.payInvoice(
        invoiceId: invoiceId,
        note: note,
        paidAt: paidAt,
        amount: amount,
      );

  @override
  Future<SubscriptionInvoiceModel> negotiateInvoice({
    required String invoiceId,
    required String note,
    DateTime? newDueDate,
  }) =>
      _repository.negotiateInvoice(
        invoiceId: invoiceId,
        note: note,
        newDueDate: newDueDate,
      );

  @override
  Future<List<SubscriptionInvoiceModel>> createCarnet({bool payUpfront = false}) =>
      _repository.createCarnet(payUpfront: payUpfront);

  @override
  Future<void> runBillingNow() => _repository.runBillingNow();
}
