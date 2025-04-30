// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/material.dart';
import 'package:get/get.dart';

mixin MessagesMixin on GetxController {
  void messageListener(Rxn<MessageModel> message) {
    ever<MessageModel?>(message, (model) {
      if (model != null) {
        Get.snackbar(
          model.title,
          model.message,
          backgroundColor: model.type.color(),
          colorText: Colors.white,
        );
      }
    });
  }
}

class MessageModel {
  final String title;
  final String message;
  final MessageType type;

  MessageModel({
    required this.title,
    required this.message,
    required this.type,
  });

  MessageModel.success({
    required this.title,
    required this.message,
  }) : type = MessageType.success;

  MessageModel.error({
    required this.title,
    required this.message,
  }) : type = MessageType.error;

  MessageModel.info({
    required this.title,
    required this.message,
  }) : type = MessageType.info;
}

enum MessageType { success, error, info }

extension MessageTypeExtension on MessageType {
  Color color() {
    switch (this) {
      case MessageType.success:
        return Colors.green[800] ?? Colors.green;
      case MessageType.error:
        return Colors.red[800] ?? Colors.red;
      case MessageType.info:
        return Colors.blue[200] ?? Colors.blue;
    }
  }
}
