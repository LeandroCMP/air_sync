import 'package:air_sync/application/ui/loader/loader_mixin.dart';
import 'package:air_sync/application/ui/messages/messages_mixin.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:air_sync/models/air_conditioner_model.dart';
import 'package:air_sync/models/residence_model.dart';
import 'package:dio/dio.dart';

class AirConditionerController extends GetxController with MessagesMixin, LoaderMixin {
  final Rx<ResidenceModel?> residence = Rx<ResidenceModel?>(null);

  AirConditionerController();

  final formKey = GlobalKey<FormState>();

  // Form fields for air conditioner
  final roomController = TextEditingController();
  final modelController = TextEditingController();
  final btusController = TextEditingController();

  RxList<AirConditionerModel> airConditioners = <AirConditionerModel>[].obs;

  final isLoading = false.obs;
  final message = Rxn<MessageModel>();

  @override
  void onInit() {
    loaderListener(isLoading);
    messageListener(message);
    super.onInit();
    residence.value = Get.arguments is ResidenceModel ? Get.arguments as ResidenceModel : null;
    if (residence.value != null) {
      airConditioners.assignAll(residence.value!.airConditioners);
    }
  }

  Future<void> registerAirConditioner() async {
    isLoading(true);
    try {
      final airConditioner = AirConditionerModel(
        id: '',
        room: roomController.text.trim(),
        model: modelController.text.trim(),
        btus: int.parse(btusController.text.trim()),
      );

      airConditioners.add(airConditioner);
      if (residence.value != null) {
        residence.value = residence.value!.copyWith(
          airConditioners: [...residence.value!.airConditioners, airConditioner],
        );
      }

      isLoading(false);
      await Future.delayed(const Duration(milliseconds: 300));
      Get.back();

      message(
        MessageModel.success(
          title: 'Sucesso!',
          message: 'Equipamento cadastrado com sucesso!',
        ),
      );

      clearForm();
    } catch (e) {
      message(
        MessageModel.error(
          title: 'Erro!',
          message: _apiError(e, 'Erro inesperado ao cadastrar o equipamento.'),
        ),
      );
    } finally {
      isLoading(false);
    }
  }

  void clearForm() {
    roomController.clear();
    modelController.clear();
    btusController.clear();
  }

  @override
  void onClose() {
    roomController.dispose();
    modelController.dispose();
    btusController.dispose();
    super.onClose();
  }

  String _apiError(Object error, String fallback) {
  if (error is DioException) {
    final data = error.response?.data;
    if (data is Map) {
      final nested = data['error'];
      if (nested is Map && nested['message'] is String && (nested['message'] as String).trim().isNotEmpty) {
        return (nested['message'] as String).trim();
      }
      if (data['message'] is String && (data['message'] as String).trim().isNotEmpty) {
        return (data['message'] as String).trim();
      }
    }
    if (data is String && data.trim().isNotEmpty) return data.trim();
    if ((error.message ?? '').isNotEmpty) return error.message!;
  } else if (error is Exception) {
    final text = error.toString();
    if (text.trim().isNotEmpty) return text;
  }
  return fallback;
}

}
