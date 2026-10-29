import 'package:flutter/material.dart';
import 'package:get/get.dart';

void showMessage(String title, String message) {
  Get.snackbar(title, message,
      snackPosition: SnackPosition.BOTTOM, margin: const EdgeInsets.all(16));
}
