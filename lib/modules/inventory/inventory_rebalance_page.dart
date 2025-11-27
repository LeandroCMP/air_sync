import 'package:air_sync/application/ui/theme_extensions.dart';
import 'package:air_sync/models/inventory_rebalance_model.dart';
import 'package:air_sync/modules/inventory/inventory_rebalance_controller.dart';
import 'package:air_sync/modules/purchases/models/purchase_prefill.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class InventoryRebalancePage extends GetView<InventoryRebalanceController> {
  const InventoryRebalancePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: context.themeDark,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('Sugestões de recompra', style: TextStyle(color: Colors.white)),
        actions: [
          IconButton(
            tooltip: 'Recarregar',
            onPressed: controller.load,
            icon: const Icon(Icons.refresh, color: Colors.white),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              TextField(
                onChanged: controller.setSearch,
                decoration: const InputDecoration(
                  labelText: 'Buscar item',
                  prefixIcon: Icon(Icons.search),
                ),
              ),
              const SizedBox(height: 12),
              Obx(
                () => Row(
                  children: [15, 30, 60]
                      .map(
                        (value) => Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text('$value dias'),
                            selected: controller.days.value == value,
                            onSelected: (_) => controller.setDays(value),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: Obx(
                  () {
                    if (controller.isLoading.value) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final items = controller.filteredSuggestions;
                    if (items.isEmpty) {
                      return Center(
                        child: Text(
                          'Nenhuma sugestão para o período selecionado.',
                          style: TextStyle(color: context.themeTextSubtle),
                          textAlign: TextAlign.center,
                        ),
                      );
                    }
                    return ListView.separated(
                      itemCount: items.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (_, index) {
                        final suggestion = items[index];
                        return _RebalanceCard(
                          suggestion: suggestion,
                          onCreatePurchase: () =>
                              _openPrefilledPurchase(context, suggestion),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openPrefilledPurchase(
    BuildContext context,
    InventoryRebalanceSuggestion suggestion,
  ) {
    final prefill = PurchasePrefillData(
      supplierId: suggestion.supplierId,
      items: [
        PurchasePrefillItem(
          itemId: suggestion.itemId,
          itemName: suggestion.name,
          quantity: suggestion.recommendedQty,
          unitCost: suggestion.unitCost ?? 0,
        ),
      ],
    );
    Get.toNamed('/purchases', arguments: {'prefillPurchase': prefill});
  }
}

class _RebalanceCard extends StatelessWidget {
  final InventoryRebalanceSuggestion suggestion;
  final VoidCallback onCreatePurchase;

  const _RebalanceCard({
    required this.suggestion,
    required this.onCreatePurchase,
  });

  @override
  Widget build(BuildContext context) {
    final number = NumberFormat.decimalPattern('pt_BR');
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.themeSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.themeBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            suggestion.name,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
          if ((suggestion.sku ?? '').isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                'SKU: ${suggestion.sku}',
                style: TextStyle(color: context.themeTextSubtle, fontSize: 12),
              ),
            ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              _MetricTile(
                label: 'Disponível',
                value: number.format(suggestion.available),
              ),
              _MetricTile(
                label: 'Uso diário',
                value: number.format(suggestion.dailyUsage),
              ),
              _MetricTile(
                label: 'Sugerido comprar',
                value: number.format(suggestion.recommendedQty),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: onCreatePurchase,
              icon: const Icon(Icons.shopping_cart_checkout_rounded),
              label: const Text('Gerar compra'),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  final String label;
  final String value;

  const _MetricTile({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: context.themeSurfaceAlt,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(color: context.themeTextSubtle, fontSize: 12),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

