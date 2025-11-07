import 'dart:convert';

import 'package:air_sync/application/ui/input_formatters.dart';
import 'package:air_sync/application/ui/loader/loader_mixin.dart';
import 'package:air_sync/application/ui/messages/messages_mixin.dart';
import 'package:air_sync/models/company_profile_model.dart';
import 'package:air_sync/services/company_profile/company_profile_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

class CompanyProfileController extends GetxController
    with LoaderMixin, MessagesMixin {
  CompanyProfileController({required CompanyProfileService service})
    : _service = service;

  final CompanyProfileService _service;

  final formKey = GlobalKey<FormState>();
  final nameCtrl = TextEditingController();
  final pixKeyCtrl = TextEditingController();
  final debitFeeCtrl = TextEditingController();
  final chequeFeeCtrl = TextEditingController();

  final RxList<CreditFeeDraft> creditFees = <CreditFeeDraft>[].obs;
  final Rxn<CompanyProfileModel> profile = Rxn<CompanyProfileModel>();
  final isLoading = false.obs;
  final message = Rxn<MessageModel>();
  final Rx<PixKeyType> pixType = Rx<PixKeyType>(PixKeyType.phone);

  @override
  void onInit() {
    messageListener(message);
    super.onInit();
  }

  @override
  Future<void> onReady() async {
    await loadProfile();
    super.onReady();
  }

  Future<void> loadProfile() async {
    isLoading(true);
    try {
      final loaded = await _service.loadProfile();
      profile.value = loaded;
      nameCtrl.text = loaded.name;
      final inferredType = _inferPixType(loaded.pixKey);
      pixType.value = inferredType;
      _applyPixMask(loaded.pixKey);
      pixType.value = _inferPixType(loaded.pixKey);
      debitFeeCtrl.text =
          loaded.debitFeePercent == 0
              ? ''
              : loaded.debitFeePercent.toStringAsFixed(
                loaded.debitFeePercent % 1 == 0 ? 0 : 2,
              );
      chequeFeeCtrl.text =
          loaded.chequeFeePercent == 0
              ? ''
              : loaded.chequeFeePercent.toStringAsFixed(
                loaded.chequeFeePercent % 1 == 0 ? 0 : 2,
              );
      final drafts =
          loaded.creditFees
              .map(
                (fee) => CreditFeeDraft(
                  installments: fee.installments,
                  percent: fee.feePercent,
                ),
              )
              .toList();
      if (drafts.isEmpty) {
        drafts.add(CreditFeeDraft());
      }
      _replaceCreditFees(drafts);
    } catch (_) {
      message(
        MessageModel.error(
          title: 'Perfil',
          message: 'Não foi possível carregar o perfil da empresa.',
        ),
      );
    } finally {
      isLoading(false);
    }
  }

  void addCreditFee() => creditFees.add(CreditFeeDraft());

  void removeCreditFee(int index) {
    if (creditFees.length <= 1) return;
    final removed = creditFees.removeAt(index);
    removed.dispose();
  }

  Future<void> save() async {
    final validationError = _validateCreditFees();
    if (validationError != null) {
      message(MessageModel.info(title: 'Validação', message: validationError));
      return;
    }
    if (!formKey.currentState!.validate()) return;
    final built = _buildProfile();
    isLoading(true);
    try {
      final updated = await _service.saveProfile(built);
      profile.value = updated;
      message(MessageModel.success(title: 'Perfil', message: 'Dados salvos.'));
    } catch (error) {
      message(
        MessageModel.error(
          title: 'Perfil',
          message: 'Não foi possível salvar o perfil.',
        ),
      );
    } finally {
      isLoading(false);
    }
  }

  Future<void> exportProfile() async {
    isLoading(true);
    try {
      final export = await _service.exportProfile();
      final json = export.profile.toMap();
      final pretty = const JsonEncoder.withIndent('  ').convert({
        'exportedAt': export.exportedAt.toIso8601String(),
        'profile': json,
      });
      await Clipboard.setData(ClipboardData(text: pretty));
      message(
        MessageModel.success(
          title: 'Exportação',
          message: 'JSON copiado para a área de transferência.',
        ),
      );
    } catch (_) {
      message(
        MessageModel.error(
          title: 'Exportação',
          message: 'Falha ao exportar o perfil.',
        ),
      );
    } finally {
      isLoading(false);
    }
  }

  Future<void> importProfile(String rawJson) async {
    try {
      final decoded = jsonDecode(rawJson) as Map<String, dynamic>;
      final profileMap =
          decoded['profile'] is Map
              ? Map<String, dynamic>.from(decoded['profile'])
              : decoded;
      final profile = CompanyProfileModel.fromMap(profileMap);
      isLoading(true);
      await _service.importProfile(profile);
      await loadProfile();
      message(
        MessageModel.success(
          title: 'Importação',
          message: 'Perfil importado com sucesso.',
        ),
      );
    } catch (_) {
      message(
        MessageModel.error(
          title: 'Importação',
          message: 'Não foi possível importar o perfil.',
        ),
      );
    } finally {
      isLoading(false);
    }
  }

  CompanyProfileModel _buildProfile() {
    final current = profile.value;
    final fees =
        creditFees.map((CreditFeeDraft draft) => draft.toModel()).toList()
          ..sort((a, b) => a.installments.compareTo(b.installments));
    return CompanyProfileModel(
      id: current?.id ?? '',
      name: nameCtrl.text.trim(),
      pixKey: _sanitizePixKey(pixKeyCtrl.text),
      creditFees: fees,
      debitFeePercent: _parseDouble(debitFeeCtrl.text),
      chequeFeePercent: _parseDouble(chequeFeeCtrl.text),
    );
  }

  double _parseDouble(String text) {
    final normalized = text.replaceAll(',', '.').trim();
    if (normalized.isEmpty) return 0;
    return double.tryParse(normalized) ?? 0;
  }

  void _replaceCreditFees(List<CreditFeeDraft> drafts) {
    for (final fee in creditFees) {
      fee.dispose();
    }
    creditFees.assignAll(drafts);
  }

  void setPixType(PixKeyType type) {
    if (pixType.value == type) return;
    final raw = pixKeyCtrl.text;
    pixType.value = type;
    _applyPixMask(raw);
  }

  void _applyPixMask(String source) {
    final type = pixType.value;
    final sanitized = _sanitizeForType(source, type);
    String masked;
    switch (type) {
      case PixKeyType.phone:
        masked =
            PhoneInputFormatter()
                .formatEditUpdate(
                  const TextEditingValue(),
                  TextEditingValue(text: sanitized),
                )
                .text;
        break;
      case PixKeyType.email:
        masked = sanitized;
        break;
      case PixKeyType.cpf:
      case PixKeyType.cnpj:
        masked =
            CnpjCpfInputFormatter()
                .formatEditUpdate(
                  const TextEditingValue(),
                  TextEditingValue(text: sanitized),
                )
                .text;
        break;
      case PixKeyType.random:
        masked = sanitized;
        break;
    }
    pixKeyCtrl
      ..text = masked
      ..selection = TextSelection.collapsed(offset: masked.length);
  }

  String? _validateCreditFees() {
    final seen = <int>{};
    for (final fee in creditFees) {
      final model = fee.toModel();
      if (model.installments <= 0) {
        return 'Informe parcelas maiores que zero.';
      }
      if (model.feePercent < 0) {
        return 'Percentuais não podem ser negativos.';
      }
      if (!seen.add(model.installments)) {
        return 'Há parcelas duplicadas (${model.installments}x).';
      }
    }
    return null;
  }

  String _sanitizePixKey(String raw) {
    return _sanitizeForType(raw, pixType.value);
  }

  String _sanitizeForType(String raw, PixKeyType type) {
    final trimmed = raw.trim();
    switch (type) {
      case PixKeyType.phone:
        return trimmed.replaceAll(RegExp(r'[^0-9]'), '');
      case PixKeyType.email:
        return trimmed;
      case PixKeyType.cpf:
      case PixKeyType.cnpj:
        return trimmed.replaceAll(RegExp(r'[^0-9]'), '');
      case PixKeyType.random:
        return trimmed;
    }
  }

  PixKeyType _inferPixType(String raw) {
    final value = raw.trim();
    if (value.isEmpty) return PixKeyType.phone;
    if (value.contains('@')) return PixKeyType.email;
    final digits = value.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length >= 10 && digits.length <= 13) return PixKeyType.phone;
    if (digits.length == 11) return PixKeyType.cpf;
    if (digits.length == 14) return PixKeyType.cnpj;
    return PixKeyType.random;
  }

  @override
  void onClose() {
    nameCtrl.dispose();
    pixKeyCtrl.dispose();
    debitFeeCtrl.dispose();
    chequeFeeCtrl.dispose();
    for (final fee in creditFees) {
      fee.dispose();
    }
    super.onClose();
  }
}

class CreditFeeDraft {
  CreditFeeDraft({int? installments, double? percent})
    : installmentsCtrl = TextEditingController(
        text: installments?.toString() ?? '',
      ),
      feeCtrl = TextEditingController(
        text:
            percent == null
                ? ''
                : percent % 1 == 0
                ? percent.toStringAsFixed(0)
                : percent.toString(),
      );

  final TextEditingController installmentsCtrl;
  final TextEditingController feeCtrl;

  CompanyCreditFee toModel() {
    final installments = int.tryParse(installmentsCtrl.text.trim()) ?? 0;
    final percent =
        double.tryParse(feeCtrl.text.trim().replaceAll(',', '.')) ?? 0;
    return CompanyCreditFee(installments: installments, feePercent: percent);
  }

  void dispose() {
    installmentsCtrl.dispose();
    feeCtrl.dispose();
  }
}

enum PixKeyType { phone, email, cpf, cnpj, random }

extension PixKeyTypeLabel on PixKeyType {
  String get label {
    switch (this) {
      case PixKeyType.phone:
        return 'Telefone';
      case PixKeyType.email:
        return 'E-mail';
      case PixKeyType.cpf:
        return 'CPF';
      case PixKeyType.cnpj:
        return 'CNPJ';
      case PixKeyType.random:
        return 'Chave aleatória';
    }
  }
}
