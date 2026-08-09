import 'package:equatable/equatable.dart';

class AuthUser extends Equatable {
  final String uid;
  final String? displayName;
  final bool isAnonymous;

  const AuthUser({
    required this.uid,
    this.displayName,
    this.isAnonymous = false,
  });

  @override
  List<Object?> get props => [uid, displayName, isAnonymous];
}
