// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:air_sync/models/user_model.dart';
import 'package:get/get.dart';

class AuthServiceApplication extends GetxService {
  Rxn<UserModel> user = Rxn<UserModel>();
  AuthServiceApplication({required this.user});
}
