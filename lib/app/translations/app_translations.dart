import 'package:get/get.dart';

class AppTranslations extends Translations {
  @override
  Map<String, Map<String, String>> get keys => {
        'pt_BR': {
          'login_title': 'Bem-vindo ao AirSync',
          'email': 'E-mail',
          'password': 'Senha',
          'enter': 'Entrar',
          'clients': 'Clientes',
          'orders': 'Ordens de Serviço',
          'inventory': 'Estoque',
          'finance': 'Financeiro',
          'more': 'Mais',
          'sync': 'Sincronização',
        },
        'en_US': {
          'login_title': 'Welcome to AirSync',
          'email': 'E-mail',
          'password': 'Password',
          'enter': 'Sign in',
          'clients': 'Clients',
          'orders': 'Orders',
          'inventory': 'Inventory',
          'finance': 'Finance',
          'more': 'More',
          'sync': 'Sync',
        },
      };
}
