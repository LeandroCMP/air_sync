import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../app/utils/formatters.dart';
import '../../../../app/widgets/section_card.dart';
import '../controllers/finance_controller.dart';

class FinancePage extends GetView<FinanceController> {
  const FinancePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Financeiro')),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        return RefreshIndicator(
          onRefresh: controller.load,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (controller.dre.value != null)
                SectionCard(
                  title: 'DRE (Resumo)',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Receita: ${Formatters.money(controller.dre.value!.revenue)}'),
                      Text('Custos: ${Formatters.money(controller.dre.value!.costs)}'),
                      Text('Despesas: ${Formatters.money(controller.dre.value!.expenses)}'),
                      Text('Lucro: ${Formatters.money(controller.dre.value!.profit)}'),
                    ],
                  ),
                ),
              SectionCard(
                title: 'A Receber',
                child: Column(
                  children: controller.receivables
                      .map(
                        (tx) => ListTile(
                          title: Text(tx.description),
                          subtitle: Text('Vencimento: ${tx.dueDate != null ? Formatters.date(tx.dueDate!) : '-'}'),
                          trailing: Text(Formatters.money(tx.amount)),
                          leading: Icon(tx.isPaid ? Icons.check : Icons.schedule, color: tx.isPaid ? Colors.green : Colors.orange),
                          onTap: tx.isPaid
                              ? null
                              : () => controller.pay(tx.id, tx.amount, 'PIX'),
                        ),
                      )
                      .toList(),
                ),
              ),
              SectionCard(
                title: 'A Pagar',
                child: Column(
                  children: controller.payables
                      .map(
                        (tx) => ListTile(
                          title: Text(tx.description),
                          trailing: Text(Formatters.money(tx.amount)),
                          leading: Icon(tx.isPaid ? Icons.check : Icons.schedule, color: tx.isPaid ? Colors.green : Colors.red),
                          onTap: tx.isPaid
                              ? null
                              : () => controller.pay(tx.id, tx.amount, 'CASH'),
                        ),
                      )
                      .toList(),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}
