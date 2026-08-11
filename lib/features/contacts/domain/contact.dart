import 'package:equatable/equatable.dart';

class Contact extends Equatable {
  final String uid;
  final String displayName;
  final DateTime addedAt;

  const Contact({
    required this.uid,
    required this.displayName,
    required this.addedAt,
  });

  @override
  List<Object?> get props => [uid, displayName, addedAt];
}
