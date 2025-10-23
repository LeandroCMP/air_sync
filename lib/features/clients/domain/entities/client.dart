import 'package:equatable/equatable.dart';

class Client extends Equatable {
  const Client({
    required this.id,
    required this.name,
    required this.document,
    required this.phones,
    required this.emails,
    required this.updatedAt,
  });

  final String id;
  final String name;
  final String? document;
  final List<String> phones;
  final List<String> emails;
  final DateTime? updatedAt;

  @override
  List<Object?> get props => [id, name, document, phones, emails, updatedAt];
}
