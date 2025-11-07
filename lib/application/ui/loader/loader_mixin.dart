import 'package:flutter/material.dart';
import 'package:get/get.dart';

// Overlay global de loading com lógica robusta contra corridas de estado.
class _GlobalLoaderController {
  static int _openCount = 0; // contador de requisições de loading
  static int _seq = 0; // ticket para descartar callbacks antigos
  static bool _isShowing = false; // estado do dialog

  static void _showDialog() {
    _isShowing = true;
    Get.dialog(
      const Center(
        child: SizedBox(
          width: 50,
          height: 50,
          child: CircularProgressIndicator(strokeWidth: 3),
        ),
      ),
      barrierDismissible: false,
    ).whenComplete(() {
      _isShowing = false;
    });
  }

  static void open() {
    _openCount++;
    final ticket = ++_seq;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Se outro open/close ocorreu depois, descarta este callback
      if (_seq != ticket) return;
      // Se durante o intervalo o contador voltou a 0, não abre
      if (_openCount == 0) return;
      // Não abre overlay se há bottom sheet aberta
      if (Get.isBottomSheetOpen ?? false) return;
      // Se já está mostrando, não abre outro
      if (_isShowing) return;
      _showDialog();
    });
  }

  // Incrementa somente o contador, sem abrir diálogo (ex.: tela Home)
  static void incrementOnly() {
    _openCount++;
  }

  static void close() {
    if (_openCount > 0) _openCount--;
    final ticket = ++_seq;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Descarta se outro evento ocorreu depois
      if (_seq != ticket) return;
      if (_openCount == 0 && _isShowing) {
        if (Get.isDialogOpen ?? false) {
          Get.back<void>();
        }
        _isShowing = false;
      }
    });
  }
}

mixin LoaderMixin on GetxController {
  void loaderListener(RxBool loaderRx) {
    ever<bool>(loaderRx, (loading) {
      if (loading) {
        // Evita overlay em rotas com indicador inline (Home, Suppliers, Equipments, Fleet, Orders, Purchases)
        const inlineRoutes = {
          '/home',
          '/suppliers',
          '/equipments',
          '/fleet',
          '/orders',
          '/OrdersPage',
          '/purchases',
          '/inventory',
          '/users',
          '/login',
          '/OrderDetailPage',
          '/OrderCreatePage',
          'OrderDetailPage',
          'OrderCreatePage',
          'OrdersPage',
        };
        final currentRoute = Get.currentRoute;
        if (currentRoute.isEmpty || inlineRoutes.contains(currentRoute)) {
          _GlobalLoaderController.incrementOnly();
        } else {
          _GlobalLoaderController.open();
        }
      } else {
        _GlobalLoaderController.close();
      }
    });
  }
}
