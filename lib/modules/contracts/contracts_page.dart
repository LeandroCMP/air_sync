import 'package:air_sync/application/ui/theme_extensions.dart';
import 'package:air_sync/models/client_model.dart';
import 'package:air_sync/models/equipment_model.dart';
import 'package:air_sync/repositories/equipments/equipments_repository.dart';
import 'package:air_sync/services/client/client_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'contracts_controller.dart';
import 'package:intl/intl.dart';

class ContractsPage extends GetView<ContractsController> {
  const ContractsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.themeBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('Contratos', style: TextStyle(color: Colors.white)),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: context.themeGreen,
        onPressed: () => _openCreateDialog(context),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: Obx(() {
        final money = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
        if (controller.isLoading.value) return const LinearProgressIndicator(minHeight: 2);
        if (controller.items.isEmpty) {
          return const Center(child: Text('Sem contratos', style: TextStyle(color: Colors.white70)));
        }
        return ListView.separated(
          itemCount: controller.items.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (_, i) {
            final c = controller.items[i];
            return ListTile(
              title: Text('${c.planName} • ${money.format(c.priceMonthly)}', style: const TextStyle(color: Colors.white)),
              subtitle: Text('Intervalo: ${c.intervalMonths}m • SLA: ${c.slaHours}h • Status: ${c.status.isEmpty ? '—' : c.status}', style: const TextStyle(color: Colors.white70)),
              onTap: () => _openDetails(context, c),
            );
          },
        );
      }),
    );
  }

  void _openCreateDialog(BuildContext context) {
    final planCtrl = TextEditingController();
    final intervalCtrl = TextEditingController(text: '12');
    final slaCtrl = TextEditingController(text: '24');
    final priceCtrl = TextEditingController(text: '0');
    final notesCtrl = TextEditingController();

    ClientModel? selectedClient;
    final selectedEquipments = <String>{}.obs;
    final clients = <ClientModel>[].obs;
    final equipments = <EquipmentModel>[].obs;
    final isLoadingEquip = false.obs;

    Future<void> loadClients() async {
      final svc = Get.find<ClientService>();
      final list = await svc.list(limit: 100);
      clients.assignAll(list);
    }

    Future<void> loadEquipments(String clientId) async {
      isLoadingEquip(true);
      try {
        final repo = Get.find<EquipmentsRepository>();
        final list = await repo.listByClient(clientId);
        equipments.assignAll(list);
      } finally {
        isLoadingEquip(false);
      }
    }

    loadClients();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.themeDark,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Obx(() => Padding(
            padding: EdgeInsets.only(left: 20, right: 20, bottom: MediaQuery.of(context).viewInsets.bottom + 30, top: 30),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Novo contrato', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                  const SizedBox(height: 12),
                  const Text('Cliente', style: TextStyle(color: Colors.white70)),
                  const SizedBox(height: 6),
                  InkWell(
                    onTap: () => _openClientPicker(context, clients, (c) {
                      selectedClient = c;
                      selectedEquipments.clear();
                      equipments.clear();
                      loadEquipments(c.id);
                    }),
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(border: Border.all(color: Colors.white24), borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      alignment: Alignment.centerLeft,
                      child: Text(selectedClient?.name ?? 'Selecionar cliente', style: const TextStyle(color: Colors.white)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: planCtrl,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(labelText: 'Plano (nome) *'),
                  ),
                  const SizedBox(height: 8),
                  Row(children: [
                    Expanded(
                      child: TextField(
                        controller: intervalCtrl,
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(labelText: 'Intervalo (meses) *'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: slaCtrl,
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(labelText: 'SLA (horas) *'),
                      ),
                    ),
                  ]),
                  const SizedBox(height: 8),
                  TextField(
                    controller: priceCtrl,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(labelText: 'Preço mensal *', prefixText: 'R\$ '),
                  ),
                  const SizedBox(height: 12),
                  const Text('Equipamentos (opcional)', style: TextStyle(color: Colors.white70)),
                  const SizedBox(height: 6),
                  if (isLoadingEquip.value) const LinearProgressIndicator(minHeight: 2) else if (selectedClient == null)
                    const Text('Selecione um cliente para listar os equipamentos', style: TextStyle(color: Colors.white54))
                  else if (equipments.isEmpty)
                    const Text('Cliente sem equipamentos', style: TextStyle(color: Colors.white54))
                  else
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: equipments
                          .map((e) => FilterChip(
                                selected: selectedEquipments.contains(e.id),
                                label: Text((e.model ?? e.brand ?? e.type ?? 'Equipamento')),
                                onSelected: (v) {
                                  if (v) {
                                    selectedEquipments.add(e.id);
                                  } else {
                                    selectedEquipments.remove(e.id);
                                  }
                                },
                              ))
                          .toList(),
                    ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: notesCtrl,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(labelText: 'Observações (opcional)'),
                  ),
                  const SizedBox(height: 16),
                  Row(children: [
                    Expanded(
                      child: SizedBox(
                        height: 45,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: context.themeGreen, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25))),
                          onPressed: () async {
                            if (selectedClient == null) return;
                            final plan = planCtrl.text.trim();
                            final interval = int.tryParse(intervalCtrl.text.trim()) ?? 0;
                            final sla = int.tryParse(slaCtrl.text.trim()) ?? 0;
                            final price = double.tryParse(priceCtrl.text.trim().replaceAll(',', '.')) ?? 0;
                            if (plan.isEmpty || interval <= 0 || sla <= 0 || price <= 0) return;
                            await controller.create(
                              clientId: selectedClient!.id,
                              planName: plan,
                              intervalMonths: interval,
                              slaHours: sla,
                              priceMonthly: price,
                              equipmentIds: selectedEquipments.toList(),
                              notes: notesCtrl.text.trim().isEmpty ? null : notesCtrl.text.trim(),
                            );
                            Get.back();
                          },
                          child: Text('Salvar', style: TextStyle(fontWeight: FontWeight.bold, color: context.themeGray)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    SizedBox(
                      height: 45,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.redAccent), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25))),
                        onPressed: () => Get.back(),
                        child: const Text('Cancelar', style: TextStyle(color: Colors.redAccent)),
                      ),
                    ),
                  ]),
                ],
              ),
            ),
          )),
    );
  }

  void _openClientPicker(BuildContext context, RxList<ClientModel> clients, void Function(ClientModel) onPick) {
    final searchCtrl = TextEditingController();
    final filtered = <ClientModel>[].obs;
    filtered.assignAll(clients);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.themeDark,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => Padding(
        padding: EdgeInsets.only(left: 16, right: 16, bottom: MediaQuery.of(context).viewInsets.bottom + 20, top: 16),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('Selecionar cliente', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 10),
          TextField(
            controller: searchCtrl,
            onChanged: (v) {
              final q = v.trim().toUpperCase();
              filtered.assignAll(
                clients.where(
                  (c) =>
                      c.name.toUpperCase().contains(q) ||
                      c.primaryPhone.toUpperCase().contains(q),
                ),
              );
            },
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Buscar por nome/telefone'),
          ),
          const SizedBox(height: 10),
          Flexible(
            child: Obx(() => ListView.builder(
                  shrinkWrap: true,
                  itemCount: filtered.length,
                  itemBuilder: (_, i) {
                    final c = filtered[i];
                    return ListTile(
                      title: Text(c.name, style: const TextStyle(color: Colors.white)),
                      subtitle: Text(c.primaryPhone, style: const TextStyle(color: Colors.white70)),
                      onTap: () { Get.back(); onPick(c); },
                    );
                  },
                )),
          ),
        ]),
      ),
    );
  }

  void _openDetails(BuildContext context, dynamic c) {
    final money = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    Get.bottomSheet(
      SafeArea(
        child: Container(
          decoration: BoxDecoration(color: Theme.of(context).scaffoldBackgroundColor, borderRadius: const BorderRadius.vertical(top: Radius.circular(16))),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const SizedBox(height: 8),
            Container(width: 36, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 8),
            ListTile(
              title: Text(c.planName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              subtitle: Text('Preço mensal: ${money.format(c.priceMonthly)}', style: const TextStyle(color: Colors.white70)),
            ),
            ListTile(
              title: const Text('Detalhes', style: TextStyle(color: Colors.white)),
              subtitle: Text('Intervalo: ${c.intervalMonths} meses • SLA: ${c.slaHours} horas\nStatus: ${c.status.isEmpty ? '—' : c.status}\nCliente: ${c.clientId}', style: const TextStyle(color: Colors.white70)),
            ),
            if ((c.notes ?? '').toString().isNotEmpty)
              ListTile(title: const Text('Observações', style: TextStyle(color: Colors.white)), subtitle: Text(c.notes, style: const TextStyle(color: Colors.white70))),
            const SizedBox(height: 12),
          ]),
        ),
      ),
      isScrollControlled: true,
    );
  }
}



