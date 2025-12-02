import 'package:air_sync/models/subscription_models.dart';

abstract class SubscriptionsService {
  Future<SubscriptionCurrentModel> getCurrent();
  Future<SubscriptionCurrentModel> updateCurrent({
    int? billingDay,
    String? billingContactName,
    String? billingContactEmail,
    String? billingContactPhone,
    String? preferredPaymentMethod,
    String? notes,
  });

  Future<SubscriptionOverviewModel> overview();
  Future<SubscriptionAlertModel> alerts();

  Future<List<SubscriptionInvoiceModel>> invoices({
    String? status,
    DateTime? from,
    DateTime? to,
  });
  Future<SubscriptionPaymentIntentResult> createPaymentIntent({
    required String invoiceId,
    required String method,
    String? successUrl,
    String? cancelUrl,
  });

  Future<SubscriptionInvoiceModel> payInvoice({
    required String invoiceId,
    String? note,
    DateTime? paidAt,
    double? amount,
  });

  Future<SubscriptionInvoiceModel> negotiateInvoice({
    required String invoiceId,
    required String note,
    DateTime? newDueDate,
  });

  Future<List<SubscriptionInvoiceModel>> createCarnet({bool payUpfront = false});

  Future<void> runBillingNow();
}
