import 'package:air_sync/application/ui/theme_extensions.dart';
import 'package:air_sync/application/utils/formatters/cep_input_formatter.dart';
import 'package:air_sync/models/client_model.dart';
import 'package:air_sync/models/location_model.dart';
import 'package:air_sync/models/equipment_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:air_sync/modules/equipments/widgets/maintenance_history_card.dart';

import 'package:air_sync/application/utils/formatters/btus_input_formatter.dart';

import '../client/client_controller.dart';
import '../client/client_page.dart' show showClientFormSheet;
import 'client_details_controller.dart';

class ClientDetailsPage extends GetView<ClientDetailsController> {
  const ClientDetailsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: context.themeDark,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Obx(() {
          final client = controller.client.value;
          return Text(
            client?.name ?? 'Cliente',
            style: const TextStyle(color: Colors.white),
          );
        }),
        actions: [
          IconButton(
            tooltip: 'Atualizar',
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: controller.refreshClient,
          ),
          IconButton(
            tooltip: 'Editar',
            icon: const Icon(Icons.edit, color: Colors.white),
            onPressed: () => _openEdit(context),
          ),
        ],
      ),
      floatingActionButton: Obx(() {
        final client = controller.client.value;
        if (client == null || client.primaryPhone.isEmpty) {
          return const SizedBox.shrink();
        }
        return FloatingActionButton.extended(
          backgroundColor: context.themeGreen,
          icon: const Icon(Icons.phone, color: Colors.white),
          label: Text(
            client.primaryPhone,
            style: const TextStyle(color: Colors.white),
          ),
          onPressed: () => controller.openDialer(client.primaryPhone),
        );
      }),
      body: SafeArea(

        child: Obx(() {

          final client = controller.client.value;

          final isRefreshing = controller.isRefreshing.value;



          if (client == null) {

            if (isRefreshing) {

              return const Center(child: CircularProgressIndicator());

            }

            return const Center(

              child: Text(

                'Cliente não encontrado.',

                style: TextStyle(color: Colors.white70),

              ),

            );

          }



          final summaryEntries = _buildDetailSummaryEntries(

            client,

            controller,

          );



          return RefreshIndicator(

            onRefresh: controller.refreshClient,

            child: CustomScrollView(

              physics: const BouncingScrollPhysics(

                parent: AlwaysScrollableScrollPhysics(),

              ),

              slivers: [

                SliverToBoxAdapter(

                  child: Padding(

                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),

                    child: _HeaderCard(client: client),

                  ),

                ),

                if (summaryEntries.isNotEmpty)

                  SliverToBoxAdapter(

                    child: Padding(

                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),

                      child: _DetailSummaryRow(entries: summaryEntries),

                    ),

                  ),

                ..._buildDetailSections(client, controller),

                const SliverPadding(padding: EdgeInsets.only(bottom: 120)),

              ],

            ),

          );

        }),

      ),
    );
  }

  void _openEdit(BuildContext context) {
    final client = controller.client.value;
    if (client == null) return;

    if (!Get.isRegistered<ClientController>()) {
      Get.snackbar('Atenção', 'Não foi possível carregar o editor de clientes');
      return;
    }

    final listController = Get.find<ClientController>();
    showClientFormSheet(context, listController, client: client).then((_) {
      controller.refreshClient();
    });
  }
}

List<_DetailSummaryInfo> _buildDetailSummaryEntries(
  ClientModel client,
  ClientDetailsController controller,
) {
  final contacts = client.phones.length + client.emails.length;
  final locations = controller.locations.length;
  final equipments = controller.locationEquipments.values.fold<int>(
    0,
    (sum, list) => sum + list.length,
  );
  final tags = client.tags.length;

  return [
    _DetailSummaryInfo(
      label: 'Contatos',
      value: contacts.toString(),
      color: Colors.lightBlueAccent,
      icon: Icons.chat_bubble_outline,
    ),
    _DetailSummaryInfo(
      label: 'Endereços',
      value: locations.toString(),
      color: Colors.tealAccent,
      icon: Icons.location_on_outlined,
    ),
    _DetailSummaryInfo(
      label: 'Equipamentos',
      value: equipments.toString(),
      color: Colors.orangeAccent,
      icon: Icons.build_outlined,
    ),
    _DetailSummaryInfo(
      label: 'Etiquetas',
      value: tags.toString(),
      color: Colors.purpleAccent,
      icon: Icons.sell_outlined,
    ),
  ];
}

List<Widget> _buildDetailSections(
  ClientModel client,
  ClientDetailsController controller,
) {
  final sections = <Widget>[
    SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: _ContactsSection(client: client),
      ),
    ),
    SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: _LocationsSection(controller: controller),
      ),
    ),
  ];

  if (client.tags.isNotEmpty) {
    sections.add(
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: _TagsSection(tags: client.tags),
        ),
      ),
    );
  }

  final notes = (client.notes ?? '').trim();
  if (notes.isNotEmpty) {
    sections.add(
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: _NotesSection(notes: notes),
        ),
      ),
    );
  }

  sections.add(
    SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: _MetaSection(client: client),
      ),
    ),
  );

  return sections;
}

class _DetailSummaryRow extends StatelessWidget {
  const _DetailSummaryRow({required this.entries});

  final List<_DetailSummaryInfo> entries;

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      height: 120,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: entries.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (_, index) {
          final entry = entries[index];
          final background = Colors.white.withValues(alpha: 0.04);
          final borderColor = Colors.white.withValues(alpha: 0.06);
          return SizedBox(
            width: 150,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: background,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: borderColor),
                boxShadow: [
                  BoxShadow(
                    color: entry.color.withValues(alpha: 0.08),
                    blurRadius: 18,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: entry.color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      entry.icon,
                      color: Color.lerp(entry.color, Colors.white, 0.4),
                      size: 18,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    entry.label,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.72),
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    entry.value,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 22,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _DetailSummaryInfo {
  const _DetailSummaryInfo({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  final String label;
  final String value;
  final Color color;
  final IconData icon;
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({required this.client});

  final ClientModel client;

  @override
  Widget build(BuildContext context) {
    final statusColor =
        client.isDeleted ? Colors.redAccent : Colors.greenAccent;
    final docNumber = client.docNumber;
    return Container(
      decoration: BoxDecoration(
        color: context.themeGray,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: context.themeLightGray,
                child: Text(
                  client.name.isNotEmpty
                      ? client.name.characters.first.toUpperCase()
                      : '?',
                  style: const TextStyle(color: Colors.white, fontSize: 20),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      client.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      client.isDeleted ? 'Inativo' : 'Ativo',
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (docNumber != null && docNumber.isNotEmpty)
            _InfoRow(title: 'Documento', value: docNumber),
        ],
      ),
    );
  }
}

class _ContactsSection extends StatelessWidget {
  const _ContactsSection({required this.client});

  final ClientModel client;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.themeGray,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Contatos',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          if (client.phones.isNotEmpty)
            _ChipGroup(title: 'Telefones', values: client.phones),
          if (client.emails.isNotEmpty) ...[
            if (client.phones.isNotEmpty) const SizedBox(height: 16),
            _ChipGroup(title: 'E-mails', values: client.emails),
          ],
          if (client.phones.isEmpty && client.emails.isEmpty)
            const Text(
              'Sem contatos cadastrados.',
              style: TextStyle(color: Colors.white70),
            ),
        ],
      ),
    );
  }
}

Future<void> _openLocationFormSheet(
  BuildContext context,
  ClientDetailsController controller, {
  LocationModel? location,
}) async {
  final isEditing = location != null;
  final formKey = GlobalKey<FormState>();
  final referenceController = TextEditingController(
    text: location?.label ?? '',
  );
  final zipController = TextEditingController(
    text: _formatZip(location?.zip) ?? '',
  );
  final streetController = TextEditingController(text: location?.street ?? '');
  final numberController = TextEditingController(text: location?.number ?? '');
  final cityController = TextEditingController(text: location?.city ?? '');
  final stateController = TextEditingController(text: location?.state ?? '');
  final notesController = TextEditingController(text: location?.notes ?? '');

  var lastCepLookup = zipController.text.replaceAll(RegExp(r'\D'), '');

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: context.themeDark,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (sheetCtx) {
      final bottom = MediaQuery.of(sheetCtx).viewInsets.bottom;

      return Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 24,
          bottom: bottom + 24,
        ),
        child: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Obx(() {
              final isSaving = controller.isSavingLocation.value;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Text(
                        isEditing ? 'Editar endereo' : 'Novo endereo',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white70),
                        onPressed:
                            isSaving
                                ? null
                                : () {
                                  if (Get.isBottomSheetOpen ?? false) {
                                    Get.back();
                                  } else if (Navigator.of(sheetCtx).canPop()) {
                                    Navigator.of(sheetCtx).pop();
                                  }
                                },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: referenceController,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(labelText: 'Referncia*'),
                    style: const TextStyle(color: Colors.white),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Informe uma referncia para o endereo';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: zipController,
                    decoration: InputDecoration(
                      labelText: 'CEP',
                      suffixIcon:
                          controller.isFetchingCep.value
                              ? const Padding(
                                padding: EdgeInsets.all(10),
                                child: SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                              )
                              : null,
                    ),
                    style: const TextStyle(color: Colors.white),
                    keyboardType: TextInputType.number,
                    inputFormatters: [CepInputFormatter()],
                    onChanged: (value) async {
                      final digits = value.replaceAll(RegExp(r'\D'), '');
                      if (digits.length == 8 && digits != lastCepLookup) {
                        lastCepLookup = digits;
                        final result = await controller.lookupCep(value);
                        if (!sheetCtx.mounted) return;
                        if (zipController.text.replaceAll(RegExp(r'\D'), '') !=
                            digits) {
                          return;
                        }
                        final street = result['street'];
                        if (street != null &&
                            street.isNotEmpty &&
                            streetController.text.trim().isEmpty) {
                          streetController.text = street;
                        }
                        final city = result['city'];
                        if (city != null &&
                            city.isNotEmpty &&
                            cityController.text.trim().isEmpty) {
                          cityController.text = city;
                        }
                        final state = result['state'];
                        if (state != null && state.isNotEmpty) {
                          stateController.text = state.toUpperCase();
                        }
                        final district = result['district'];
                        if (district != null &&
                            district.isNotEmpty &&
                            notesController.text.trim().isEmpty) {
                          notesController.text = district;
                        }
                      } else if (digits.length < 8) {
                        lastCepLookup = digits;
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: streetController,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(labelText: 'Rua'),
                    style: const TextStyle(color: Colors.white),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: numberController,
                          decoration: const InputDecoration(labelText: 'Nmero'),
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                      const SizedBox(width: 12),
                      SizedBox(
                        width: 90,
                        child: TextFormField(
                          controller: stateController,
                          textCapitalization: TextCapitalization.characters,
                          decoration: const InputDecoration(labelText: 'UF'),
                          style: const TextStyle(color: Colors.white),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                              RegExp('[A-Za-z]'),
                            ),
                            LengthLimitingTextInputFormatter(2),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: cityController,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(labelText: 'Cidade'),
                    style: const TextStyle(color: Colors.white),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: notesController,
                    decoration: const InputDecoration(
                      labelText: 'Observações (opcional)',
                    ),
                    style: const TextStyle(color: Colors.white),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed:
                          isSaving
                              ? null
                              : () async {
                                if (!(formKey.currentState?.validate() ?? false)) return;
                                final success =
                                    isEditing
                                        ? await controller.updateLocation(
                                          location: location,
                                          reference: referenceController.text,
                                          street: streetController.text,
                                          number: numberController.text,
                                          city: cityController.text,
                                          state: stateController.text,
                                          zip: zipController.text,
                                          notes: notesController.text,
                                        )
                                        : await controller.createLocation(
                                          reference: referenceController.text,
                                          street: streetController.text,
                                          number: numberController.text,
                                          city: cityController.text,
                                          state: stateController.text,
                                          zip: zipController.text,
                                          notes: notesController.text,
                                        );
                                if (success) {
                                  if (Get.isBottomSheetOpen ?? false) {
                                    Get.back();
                                  } else if (sheetCtx.mounted &&
                                      Navigator.of(sheetCtx).canPop()) {
                                    Navigator.of(sheetCtx).pop();
                                  }
                                }
                              },
                      icon:
                          isSaving
                              ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                              : const Icon(Icons.check),
                      label: Text(
                        isSaving
                            ? 'Salvando...'
                            : (isEditing
                                ? 'Salvar alteraes'
                                : 'Cadastrar endereo'),
                      ),
                    ),
                  ),
                ],
              );
            }),
          ),
        ),
      );
    },
  );

  referenceController.dispose();
  zipController.dispose();
  streetController.dispose();
  numberController.dispose();
  cityController.dispose();
  stateController.dispose();
  notesController.dispose();
}

class _LocationsSection extends StatelessWidget {
  const _LocationsSection({required this.controller});

  final ClientDetailsController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final loadingLocations = controller.isLoadingLocations.value;
      final saving = controller.isSavingLocation.value;
      final locations = controller.locations;

      return Container(
        decoration: BoxDecoration(
          color: context.themeGray,
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'Endereços',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed:
                      saving
                          ? null
                          : () => _openLocationFormSheet(context, controller),
                  style: TextButton.styleFrom(
                    foregroundColor: context.themeGreen,
                  ),
                  icon: const Icon(Icons.add),
                  label: const Text('Adicionar endereço'),
                ),
              ],
            ),
            if (loadingLocations) ...[
              const SizedBox(height: 12),
              const LinearProgressIndicator(minHeight: 2),
            ] else if (locations.isEmpty) ...[
              const SizedBox(height: 12),
              const Text(
                'Nenhum endereço cadastrado.',
                style: TextStyle(color: Colors.white70),
              ),
            ] else ...[
              const SizedBox(height: 12),
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: locations.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (_, index) {
                  final location = locations[index];
                  final isDeleting = controller.deletingLocationIds.contains(
                    location.id,
                  );
                  return _LocationTile(
                    controller: controller,
                    location: location,
                    isDeleting: isDeleting,
                    onEdit:
                        () => _openLocationFormSheet(
                          context,
                          controller,
                          location: location,
                        ),
                    onDelete: () async {
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder:
                            (dialogContext) => AlertDialog(
                              title: const Text('Remover endereço'),
                              content: Text(
                                'Deseja remover o endereço "${location.label}"?',
                              ),
                              actions: [
                                TextButton(
                                  onPressed:
                                      () => Navigator.of(
                                        dialogContext,
                                      ).pop(false),
                                  child: const Text('Cancelar'),
                                ),
                                TextButton(
                                  onPressed:
                                      () =>
                                          Navigator.of(dialogContext).pop(true),
                                  child: const Text('Remover'),
                                ),
                              ],
                            ),
                      );
                      if (confirmed == true) {
                        await controller.deleteLocation(location);
                      }
                    },
                  );
                },
              ),
            ],
          ],
        ),
      );
    });
  }
}

class _LocationTile extends StatelessWidget {
  const _LocationTile({
    required this.controller,
    required this.location,
    required this.onEdit,
    required this.onDelete,
    required this.isDeleting,
  });

  final ClientDetailsController controller;
  final LocationModel location;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final bool isDeleting;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final streetLine = location.addressLine;
    final cityState = location.cityState;
    final zip = _formatZip(location.zip);
    final notes = location.notes?.trim();

    return Container(
      decoration: BoxDecoration(
        color: context.themeDark.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  location.label,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (isDeleting)
                const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                PopupMenuButton<_LocationAction>(
                  onSelected: (action) {
                    switch (action) {
                      case _LocationAction.edit:
                        onEdit();
                        break;
                      case _LocationAction.delete:
                        onDelete();
                        break;
                    }
                  },
                  itemBuilder:
                      (_) => const [
                        PopupMenuItem(
                          value: _LocationAction.edit,
                          child: Text('Editar'),
                        ),
                        PopupMenuItem(
                          value: _LocationAction.delete,
                          child: Text('Excluir'),
                        ),
                      ],
                ),
            ],
          ),
          if (streetLine.isNotEmpty || cityState.isNotEmpty || zip != null) ...[
            const SizedBox(height: 6),
            Text(
              [
                if (streetLine.isNotEmpty) streetLine,
                if (cityState.isNotEmpty) cityState,
                if (zip != null) zip,
              ].join(' • '),
              style: const TextStyle(color: Colors.white70),
            ),
          ],
          if (notes != null && notes.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(notes, style: const TextStyle(color: Colors.white60)),
          ],
          const SizedBox(height: 16),
          _LocationEquipmentList(controller: controller, location: location),
        ],
      ),
    );
  }
}

enum _LocationAction { edit, delete }

class _LocationEquipmentList extends StatefulWidget {
  const _LocationEquipmentList({
    required this.controller,
    required this.location,
  });

  final ClientDetailsController controller;
  final LocationModel location;

  @override
  State<_LocationEquipmentList> createState() => _LocationEquipmentListState();
}

class _LocationEquipmentListState extends State<_LocationEquipmentList> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.controller.loadEquipmentsForLocation(widget.location.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final loading = widget.controller.isEquipmentLoading(widget.location.id);
      final equipments = widget.controller.equipmentsFor(widget.location.id);
      final deletingIds = widget.controller.deletingEquipmentIds;
      final saving = widget.controller.isSavingLocation.value;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Equipamentos',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Flexible(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed:
                        saving
                            ? null
                            : () => _openEquipmentFormSheet(
                              context,
                              widget.controller,
                              location: widget.location,
                            ),
                    icon: const Icon(Icons.add),
                    label: const Text(
                      'Adicionar equipamento',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (loading) ...[
            const SizedBox(height: 8),
            const LinearProgressIndicator(minHeight: 2),
          ] else if (equipments.isEmpty) ...[
            const SizedBox(height: 8),
            const Text(
              'Nenhum equipamento cadastrado para este endereço.',
              style: TextStyle(color: Colors.white70),
            ),
          ] else ...[
            const SizedBox(height: 8),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: equipments.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (_, index) {
                final equipment = equipments[index];
                final isDeleting = deletingIds.contains(equipment.id);
                return _EquipmentCard(
                  controller: widget.controller,
                  location: widget.location,
                  equipment: equipment,
                  isDeleting: isDeleting,
                );
              },
            ),
          ],
        ],
      );
    });
  }
}

class _EquipmentCard extends StatelessWidget {
  const _EquipmentCard({
    required this.controller,
    required this.location,
    required this.equipment,
    required this.isDeleting,
  });

  final ClientDetailsController controller;
  final LocationModel location;
  final EquipmentModel equipment;
  final bool isDeleting;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final details = <String>[];
    if ((equipment.brand ?? '').isNotEmpty) {
      details.add('Marca: ${equipment.brand}');
    }
    if ((equipment.model ?? '').isNotEmpty) {
      details.add('Modelo: ${equipment.model}');
    }
    if ((equipment.type ?? '').isNotEmpty) {
      details.add('Tipo: ${equipment.type}');
    }
    if (equipment.btus != null) {
      details.add('${equipment.btus} BTUs');
    }
    if ((equipment.serial ?? '').isNotEmpty) {
      details.add('Série: ${equipment.serial}');
    }

    return Container(
      decoration: BoxDecoration(
        color: context.themeGray.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  equipment.room ?? 'Ambiente não informado',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (isDeleting)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                PopupMenuButton<_EquipmentAction>(
                  onSelected: (action) async {
                    switch (action) {
                      case _EquipmentAction.edit:
                        _openEquipmentFormSheet(
                          context,
                          controller,
                          location: location,
                          equipment: equipment,
                        );
                        break;
                      case _EquipmentAction.history:
                        await _showEquipmentHistorySheet(
                          context,
                          controller,
                          equipment,
                        );
                        break;
                      case _EquipmentAction.pdf:
                        await controller.openEquipmentPdf(equipment.id);
                        break;
                      case _EquipmentAction.delete:
                        final confirmed = await showDialog<bool>(
                          context: context,
                          builder:
                              (dialogContext) => AlertDialog(
                                title: const Text('Remover equipamento'),
                                content: Text(
                                  'Deseja remover o equipamento "${equipment.room ?? equipment.model ?? equipment.id}"?',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed:
                                        () => Navigator.of(
                                          dialogContext,
                                        ).pop(false),
                                    child: const Text('Cancelar'),
                                  ),
                                  TextButton(
                                    onPressed:
                                        () => Navigator.of(
                                          dialogContext,
                                        ).pop(true),
                                    child: const Text('Remover'),
                                  ),
                                ],
                              ),
                        );
                        if (confirmed == true) {
                          await controller.deleteEquipment(equipment);
                        }
                        break;
                    }
                  },
                  itemBuilder:
                      (_) => const [
                        PopupMenuItem(
                          value: _EquipmentAction.edit,
                          child: Text('Editar'),
                        ),
                        PopupMenuItem(
                          value: _EquipmentAction.history,
                          child: Text('Histórico de manutenções'),
                        ),
                        PopupMenuItem(
                          value: _EquipmentAction.pdf,
                          child: Text('Gerar PDF'),
                        ),
                        PopupMenuItem(
                          value: _EquipmentAction.delete,
                          child: Text('Excluir'),
                        ),
                      ],
                ),
            ],
          ),
          if (details.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              details.join(' • '),
              style: const TextStyle(color: Colors.white70),
            ),
          ],
          if ((equipment.notes ?? '').trim().isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              equipment.notes!.trim(),
              style: const TextStyle(color: Colors.white60),
            ),
          ],
        ],
      ),
    );
  }
}

enum _EquipmentAction { edit, history, pdf, delete }

String? _formatZip(String? zip) {
  if (zip == null) return null;
  final digits = zip.replaceAll(RegExp(r'\D'), '');
  if (digits.isEmpty) return null;
  if (digits.length == 8) {
    return '${digits.substring(0, 5)}-${digits.substring(5)}';
  }
  return digits;
}

Future<void> _openEquipmentFormSheet(
  BuildContext context,
  ClientDetailsController controller, {
  required LocationModel location,
  EquipmentModel? equipment,
}) async {
  final isEditing = equipment != null;
  final formKey = GlobalKey<FormState>();

  final roomController = TextEditingController(text: equipment?.room ?? '');
  final brandController = TextEditingController(text: equipment?.brand ?? '');
  final modelController = TextEditingController(text: equipment?.model ?? '');
  final typeController = TextEditingController(text: equipment?.type ?? '');
  final btusValue = equipment?.btus;
  final btusController = TextEditingController(
    text:
        btusValue != null
            ? NumberFormat.decimalPattern('pt_BR').format(btusValue)
            : '',
  );
  final serialController = TextEditingController(text: equipment?.serial ?? '');
  final notesController = TextEditingController(text: equipment?.notes ?? '');
  final installDateNotifier = ValueNotifier<DateTime?>(equipment?.installDate);
  var sheetClosed = false;

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: context.themeDark,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (sheetCtx) {
      final bottom = MediaQuery.of(sheetCtx).viewInsets.bottom;

      Future<void> pickDate() async {
        final current = installDateNotifier.value ?? DateTime.now();
        final picked = await showDatePicker(
          context: sheetCtx,
          initialDate: current,
          firstDate: DateTime(1990),
          lastDate: DateTime.now().add(const Duration(days: 3650)),
        );
        if (picked != null) {
          installDateNotifier.value = picked;
        }
      }

      return Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 24,
          bottom: bottom + 24,
        ),
        child: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Obx(() {
              final isSaving = controller.isSavingLocation.value;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Text(
                        isEditing ? 'Editar equipamento' : 'Novo equipamento',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white70),
                        onPressed:
                            isSaving
                                ? null
                                : () {
                                  if (Get.isBottomSheetOpen ?? false) {
                                    Get.back();
                                  } else if (Navigator.of(sheetCtx).canPop()) {
                                    Navigator.of(sheetCtx).pop();
                                  }
                                },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Campos marcados com * são obrigatórios.',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Endereço: ${location.label}',
                    style: const TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: roomController,
                    decoration: const InputDecoration(labelText: 'Ambiente*'),
                    style: const TextStyle(color: Colors.white),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Informe o ambiente do equipamento';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: brandController,
                    decoration: const InputDecoration(
                      labelText: 'Marca (opcional)',
                    ),
                    style: const TextStyle(color: Colors.white),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: modelController,
                    decoration: const InputDecoration(
                      labelText: 'Modelo (opcional)',
                    ),
                    style: const TextStyle(color: Colors.white),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: typeController,
                    decoration: const InputDecoration(
                      labelText: 'Tipo (opcional)',
                    ),
                    style: const TextStyle(color: Colors.white),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: btusController,
                    decoration: const InputDecoration(
                      labelText: 'BTUs (opcional)',
                      helperText: 'Ex.: 18.000',
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [BtusInputFormatter()],
                    style: const TextStyle(color: Colors.white),
                  ),
                  const SizedBox(height: 12),
                  ValueListenableBuilder<DateTime?>(
                    valueListenable: installDateNotifier,
                    builder: (_, value, __) {
                      final text =
                          value != null
                              ? DateFormat('dd/MM/yyyy').format(value)
                              : 'Não informado';
                      return Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Instalação: $text',
                              style: const TextStyle(color: Colors.white70),
                            ),
                          ),
                          TextButton.icon(
                            onPressed: isSaving ? null : pickDate,
                            icon: const Icon(Icons.date_range),
                            label: const Text('Selecionar'),
                          ),
                          if (value != null)
                            IconButton(
                              tooltip: 'Limpar data',
                              onPressed:
                                  isSaving
                                      ? null
                                      : () => installDateNotifier.value = null,
                              icon: const Icon(Icons.close, size: 18),
                            ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: serialController,
                    decoration: const InputDecoration(
                      labelText: 'Numero de serie (opcional)',
                    ),
                    style: const TextStyle(color: Colors.white),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: notesController,
                    decoration: const InputDecoration(
                      labelText: 'Observações (opcional)',
                    ),
                    style: const TextStyle(color: Colors.white),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed:
                          isSaving
                              ? null
                              : () async {
                                if (!(formKey.currentState?.validate() ?? false)) return;
                                final btusText = btusController.text.trim();
                                final cleanedBtus = btusText
                                    .replaceAll('.', '')
                                    .replaceAll(',', '');
                                final btus =
                                    cleanedBtus.isEmpty
                                        ? null
                                        : int.tryParse(cleanedBtus);
                                final success =
                                    isEditing
                                        ? await controller.updateEquipment(
                                          location: location,
                                          equipment: equipment,
                                          room: roomController.text,
                                          brand: brandController.text,
                                          model: modelController.text,
                                          type: typeController.text,
                                          btus: btus,
                                          installDate:
                                              installDateNotifier.value,
                                          serial: serialController.text,
                                          notes: notesController.text,
                                        )
                                        : await controller.createEquipment(
                                          location: location,
                                          room: roomController.text,
                                          brand: brandController.text,
                                          model: modelController.text,
                                          type: typeController.text,
                                          btus: btus,
                                          installDate:
                                              installDateNotifier.value,
                                          serial: serialController.text,
                                          notes: notesController.text,
                                        );
                                if (success) {
                                  if (Get.isBottomSheetOpen ?? false) {
                                    Get.back();
                                  } else if (sheetCtx.mounted &&
                                      Navigator.of(sheetCtx).canPop()) {
                                    Navigator.of(sheetCtx).pop();
                                  }
                                }
                              },
                      icon:
                          isSaving
                              ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                              : const Icon(Icons.check),
                      label: Text(
                        isSaving
                            ? 'Salvando...'
                            : (isEditing
                                ? 'Salvar alteraes'
                                : 'Cadastrar equipamento'),
                      ),
                    ),
                  ),
                ],
              );
            }),
          ),
        ),
      );
    },
  ).whenComplete(() {
    sheetClosed = true;
  });

  if (sheetClosed) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      roomController.dispose();
      brandController.dispose();
      modelController.dispose();
      typeController.dispose();
      btusController.dispose();
      serialController.dispose();
      notesController.dispose();
      installDateNotifier.dispose();
    });
  }
}

Future<void> _showEquipmentHistorySheet(
  BuildContext context,
  ClientDetailsController controller,
  EquipmentModel equipment,
) async {
  await controller.loadEquipmentHistory(equipment.id);
  if (!context.mounted) return;

  await showModalBottomSheet<void>(
    context: context,
    backgroundColor: context.themeDark,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
        child: Obx(() {
          final loading = controller.isEquipmentHistoryLoading(equipment.id);
          final history = controller.historyFor(equipment.id);

          if (loading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (history.isEmpty) {
            return const Center(
              child: Text(
                'Não há manutenções registradas para este equipamento.',
                style: TextStyle(color: Colors.white70),
                textAlign: TextAlign.center,
              ),
            );
          }

          return ListView.separated(
            itemCount: history.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder:
                (_, index) => MaintenanceHistoryCard(
                  entry: history[index],
                  compact: true,
                ),
          );
        }),
      );
    },
  );
}

class _TagsSection extends StatelessWidget {
  const _TagsSection({required this.tags});

  final List<String> tags;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.themeGray,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(20),
      child: _ChipGroup(title: 'Etiquetas', values: tags),
    );
  }
}

class _NotesSection extends StatelessWidget {
  const _NotesSection({required this.notes});

  final String notes;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.themeGray,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Observações',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Text(notes, style: const TextStyle(color: Colors.white70)),
        ],
      ),
    );
  }
}

class _MetaSection extends StatelessWidget {
  const _MetaSection({required this.client});

  final ClientModel client;

  @override
  Widget build(BuildContext context) {
    final format = DateFormat('dd/MM/yyyy HH:mm');
    final createdAt = client.createdAt;
    final updatedAt = client.updatedAt;
    final npsValue = client.nps;
    return Container(
      decoration: BoxDecoration(
        color: context.themeGray,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Histórico',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          _InfoRow(
            title: 'Criado em',
            value:
                createdAt != null
                    ? format.format(createdAt.toLocal())
                    : '-',
          ),
          _InfoRow(
            title: 'Atualizado em',
            value:
                updatedAt != null
                    ? format.format(updatedAt.toLocal())
                    : '-',
          ),
          _InfoRow(
            title: 'NPS',
            value: npsValue != null ? npsValue.toStringAsFixed(1) : '-',
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.title, required this.value});

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 130,
            child: Text(
              title,
              style: const TextStyle(
                color: Colors.white70,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

class _ChipGroup extends StatelessWidget {
  const _ChipGroup({required this.title, required this.values});

  final String title;
  final List<String> values;

  @override
  Widget build(BuildContext context) {
    if (values.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children:
              values
                  .map(
                    (value) => Chip(
                      label: Text(value),
                      backgroundColor: Colors.white.withValues(alpha: 0.12),
                    ),
                  )
                  .toList(),
        ),
      ],
    );
  }
}
