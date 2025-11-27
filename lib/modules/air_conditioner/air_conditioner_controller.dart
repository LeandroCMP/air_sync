import 'package:air_sync/application/ui/loader/loader_mixin.dart';
import 'package:air_sync/application/ui/messages/messages_mixin.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:air_sync/models/air_conditioner_model.dart';
import 'package:air_sync/models/residence_model.dart';

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
    } catch (_) {
      message(
        MessageModel.error(
          title: 'Erro!',
          message: 'Erro inesperado ao cadastrar o equipamento.',
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
}
