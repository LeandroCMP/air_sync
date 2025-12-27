import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:air_sync/application/ui/input_formatters.dart';
import 'package:get/get.dart';

import 'company_profile_controller.dart';

class CompanyProfilePage extends GetView<CompanyProfileController> {
  const CompanyProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Perfil da Empresa'),
      ),
      body: Obx(() {
        final isLoading = controller.isLoading.value;
        return Stack(
          children: [
            IgnorePointer(
              ignoring: isLoading,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: controller.formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _SectionCard(
                        title: 'Dados gerais',
                        child: Column(
                          children: [
                            TextFormField(
                              controller: controller.nameCtrl,
                              decoration: const InputDecoration(
                                labelText: 'Nome da empresa',
                              ),
                              validator:
                                  (value) =>
                                      value == null || value.trim().isEmpty
                                          ? 'Informe o nome'
                                          : null,
                            ),
                            const SizedBox(height: 12),
                            Obx(
                              () => DropdownButtonFormField<PixKeyType>(
                                decoration: const InputDecoration(
                                  labelText: 'Tipo da chave PIX',
                                ),
                                value: controller.pixType.value,
                                items:
                                    PixKeyType.values
                                        .map(
                                          (type) =>
                                              DropdownMenuItem<PixKeyType>(
                                                value: type,
                                                child: Text(type.label),
                                              ),
                                        )
                                        .toList(),
                                onChanged:
                                    (type) =>
                                        type == null
                                            ? null
                                            : controller.setPixType(type),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Obx(() {
                              final type = controller.pixType.value;
                              final keyboard = _pixKeyboardType(type);
                              final formatters = _pixFormatters(type);
                              final hint = _pixHint(type);
                              return TextFormField(
                                controller: controller.pixKeyCtrl,
                                decoration: InputDecoration(
                                  labelText: 'Chave PIX',
                                  hintText: hint,
                                ),
                                keyboardType: keyboard,
                                inputFormatters: formatters,
                              );
                            }),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      _SectionCard(
                        title: 'WhatsApp oficial',
                        child: Obx(() {
                          final status = controller.whatsappStatus.value;
                          final loading = controller.whatsappLoading.value;
                          final actionLoading = controller.whatsappActionLoading.value;
                          final connected = status?.isConnected == true;
                          final expired = status?.isExpired == true;
                          final phoneId = status?.phoneId ?? '';
                          final statusLabel = status?.label ?? 'Nao conectado';
                          final statusColor =
                              connected
                                  ? Colors.green
                                  : expired
                                      ? Colors.orange
                                      : Colors.white70;
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: statusColor.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: statusColor.withValues(alpha: 0.5),
                                      ),
                                    ),
                                    child: Text(
                                      loading ? 'Carregando...' : statusLabel,
                                      style: TextStyle(
                                        color: statusColor,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  const Spacer(),
                                  TextButton.icon(
                                    onPressed:
                                        loading ? null : controller.loadWhatsappStatus,
                                    icon: const Icon(Icons.refresh),
                                    label: const Text('Atualizar status'),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              if (phoneId.isNotEmpty)
                                Text(
                                  'Phone ID: $phoneId',
                                  style: const TextStyle(color: Colors.white70),
                                ),
                              if ((status?.message ?? '').isNotEmpty) ...[
                                const SizedBox(height: 6),
                                Text(
                                  status!.message!,
                                  style: const TextStyle(color: Colors.orangeAccent),
                                ),
                              ],
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      onPressed:
                                          actionLoading ? null : controller.connectWhatsapp,
                                      icon: const Icon(Icons.link),
                                      label: const Text('Conectar WhatsApp'),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed:
                                          (!connected && !expired) || actionLoading
                                              ? null
                                              : controller.disconnectWhatsapp,
                                      icon: const Icon(Icons.link_off),
                                      label: const Text('Desconectar'),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              TextField(
                                controller: controller.whatsappTestPhoneCtrl,
                                decoration: const InputDecoration(
                                  labelText: 'Numero para teste (E.164)',
                                  hintText: '+5511999999999',
                                ),
                                keyboardType: TextInputType.phone,
                              ),
                              const SizedBox(height: 8),
                              Align(
                                alignment: Alignment.centerRight,
                                child: ElevatedButton.icon(
                                  onPressed:
                                      actionLoading ? null : controller.sendWhatsappTest,
                                  icon: const Icon(Icons.send),
                                  label: const Text('Enviar teste'),
                                ),
                              ),
                            ],
                          );
                        }),
                      ),
                      const SizedBox(height: 16),
                      _SectionCard(
                        title: 'Taxas de cartão de crédito',
                        action: TextButton.icon(
                          onPressed: controller.addCreditFee,
                          icon: const Icon(Icons.add),
                          label: const Text('Adicionar parcela'),
                        ),
                        child: Obx(() {
                          final draftFees = controller.creditFees;
                          return Column(
                            children:
                                draftFees.asMap().entries.map((entry) {
                                  final index = entry.key;
                                  final draft = entry.value;
                                  return _CreditFeeRow(
                                    key: ValueKey('fee_row_$index'),
                                    draft: draft,
                                    onRemove:
                                        draftFees.length == 1
                                            ? null
                                            : () => controller.removeCreditFee(
                                              index,
                                            ),
                                  );
                                }).toList(),
                          );
                        }),
                      ),
                      const SizedBox(height: 16),
                      _SectionCard(
                        title: 'Taxas adicionais',
                        child: Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: controller.debitFeeCtrl,
                                decoration: const InputDecoration(
                                  labelText: 'Taxa no débito (%)',
                                ),
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                inputFormatters: [PercentInputFormatter()],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextFormField(
                                controller: controller.chequeFeeCtrl,
                                decoration: const InputDecoration(
                                  labelText: 'Taxa no cheque (%)',
                                ),
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                inputFormatters: [PercentInputFormatter()],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: controller.save,
                              icon: const Icon(Icons.save_outlined),
                              label: const Text('Salvar'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: controller.exportProfile,
                              icon: const Icon(Icons.download_outlined),
                              label: const Text('Exportar'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: () => _showImportDialog(context),
                        icon: const Icon(Icons.upload_outlined),
                        label: const Text('Importar'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (isLoading)
              const Positioned.fill(
                child: ColoredBox(
                  color: Colors.black38,
                  child: Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              ),
          ],
        );
      }),
    );
  }

  Future<void> _showImportDialog(BuildContext context) async {
    final controller = TextEditingController();
    final result = await Get.dialog<String?>(
      AlertDialog(
        title: const Text('Importar perfil'),
        content: SizedBox(
          width: 400,
          child: TextField(
            controller: controller,
            minLines: 6,
            maxLines: 12,
            decoration: const InputDecoration(
              hintText: 'Cole aqui o JSON exportado',
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: null),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Get.back(result: controller.text),
            child: const Text('Importar'),
          ),
        ],
      ),
    );
    if (result == null || result.trim().isEmpty) return;
    await this.controller.importProfile(result.trim());
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child, this.action});

  final String title;
  final Widget child;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                if (action != null) action!,
              ],
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

class _CreditFeeRow extends StatelessWidget {
  const _CreditFeeRow({super.key, required this.draft, this.onRemove});

  final CreditFeeDraft draft;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: draft.installmentsCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Parcelas'),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9]')),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: draft.feeCtrl,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(labelText: 'Percentual (%)'),
              inputFormatters: [PercentInputFormatter()],
            ),
          ),
          if (onRemove != null) ...[
            const SizedBox(width: 12),
            IconButton(
              onPressed: onRemove,
              icon: const Icon(Icons.delete_outline),
            ),
          ],
        ],
      ),
    );
  }
}

TextInputType _pixKeyboardType(PixKeyType type) {
  switch (type) {
    case PixKeyType.phone:
      return TextInputType.phone;
    case PixKeyType.email:
      return TextInputType.emailAddress;
    case PixKeyType.cpf:
    case PixKeyType.cnpj:
      return const TextInputType.numberWithOptions(decimal: false);
    case PixKeyType.random:
      return TextInputType.text;
  }
}

List<TextInputFormatter> _pixFormatters(PixKeyType type) {
  switch (type) {
    case PixKeyType.phone:
      return [PhoneInputFormatter()];
    case PixKeyType.email:
      return const [];
    case PixKeyType.cpf:
    case PixKeyType.cnpj:
      return [CnpjCpfInputFormatter()];
    case PixKeyType.random:
      return [FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9@._-]'))];
  }
}

String? _pixHint(PixKeyType type) {
  switch (type) {
    case PixKeyType.phone:
      return '(11) 99999-9999';
    case PixKeyType.email:
      return 'contato@empresa.com';
    case PixKeyType.cpf:
      return '000.000.000-00';
    case PixKeyType.cnpj:
      return '00.000.000/0000-00';
    case PixKeyType.random:
      return 'Ex.: 123e4567-e89b-12d3-a456-426614174000';
  }
}
