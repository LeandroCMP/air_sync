import 'package:air_sync/models/finance_transaction.dart';
import 'package:air_sync/services/finance/finance_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class FinanceController extends GetxController {
  final FinanceService _service = Get.find<FinanceService>();
  final RxBool loading = false.obs;
  final RxList<FinanceTransactionModel> receivables = <FinanceTransactionModel>[].obs;
  final RxList<FinanceTransactionModel> payables = <FinanceTransactionModel>[].obs;

  @override
  Future<void> onReady() async {
    await load();
    super.onReady();
  }

  Future<void> load() async {
    loading(true);
    try {
      final now = DateTime.now();
      final from = DateTime(now.year, now.month, 1);
      final to = DateTime(now.year, now.month + 1, 1);
      final ar = await _service.list(type: 'receivable', status: 'pending', from: from, to: to);
      final ap = await _service.list(type: 'payable', status: 'pending', from: from, to: to);
      receivables.assignAll(ar);
      payables.assignAll(ap);
    } finally {
      loading(false);
    }
  }

  Future<void> pay(FinanceTransactionModel tx, {double? amount, String method = 'PIX'}) async {
    final remaining = (tx.amount - tx.paidAmount).clamp(0.0, double.infinity) as double;
    final value = amount ?? remaining;
    await _service.pay(id: tx.id, method: method, amount: value);
    await load();
  }
}

class FinancePage extends StatelessWidget {
  const FinancePage({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<FinanceController>(
      init: FinanceController(),
      builder: (c) {
        return Scaffold(
          appBar: AppBar(title: const Text('Financeiro')),
          body: c.loading.value
              ? const LinearProgressIndicator(minHeight: 2)
              : DefaultTabController(
                  length: 2,
                  child: Column(
                    children: [
                      const TabBar(tabs: [Tab(text: 'A Receber'), Tab(text: 'A Pagar')]),
                      Expanded(
                        child: TabBarView(
                          children: [
                            _TxList(items: c.receivables, onPay: c.pay),
                            _TxList(items: c.payables, onPay: c.pay),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
        );
      },
    );
  }
}

class _TxList extends StatelessWidget {
  final List<FinanceTransactionModel> items;
  final Future<void> Function(FinanceTransactionModel, {double? amount, String method}) onPay;
  const _TxList({required this.items, required this.onPay});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const Center(child: Text('Sem lançamentos pendentes', style: TextStyle(color: Colors.white70)));
    }
    return ListView.separated(
      itemCount: items.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (_, i) {
        final tx = items[i];
        final double remaining = (tx.amount - tx.paidAmount) < 0 ? 0.0 : (tx.amount - tx.paidAmount);
        return ListTile(
          title: Text(tx.description, style: const TextStyle(color: Colors.white)),
          subtitle: Text(
            '${tx.type} • ${tx.status} • ${tx.dueDate?.toLocal().toString().split(".").first ?? "-"}',
            style: const TextStyle(color: Colors.white70),
          ),
          trailing: remaining > 0
              ? OutlinedButton(
                  onPressed: () => _openPayDialog(context, tx, remaining),
                  child: const Text('Pagar'),
                )
              : const Icon(Icons.check, color: Colors.green),
        );
      },
    );
  }

  void _openPayDialog(BuildContext context, FinanceTransactionModel tx, double remaining) {
    final amountCtrl = TextEditingController(text: remaining.toStringAsFixed(2));
    String method = 'PIX';
    Get.defaultDialog(
      title: 'Registrar pagamento',
      content: Column(
        children: [
          TextField(
            controller: amountCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Valor'),
          ),
          const SizedBox(height: 8),
          DropdownButton<String>(
            value: method,
            items: const [
              DropdownMenuItem(value: 'PIX', child: Text('PIX')),
              DropdownMenuItem(value: 'CASH', child: Text('Dinheiro')),
              DropdownMenuItem(value: 'CARD', child: Text('Cartão')),
            ],
            onChanged: (v) { if (v != null) method = v; },
          ),
        ],
      ),
      textConfirm: 'Confirmar',
      textCancel: 'Cancelar',
      onConfirm: () async {
        final value = double.tryParse(amountCtrl.text.replaceAll(',', '.')) ?? remaining;
        await onPay(tx, amount: value, method: method);
        Get.back();
      },
    );
  }
}
