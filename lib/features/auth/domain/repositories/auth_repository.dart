import 'package:my_pills/core/result/result.dart';
import 'package:my_pills/features/auth/domain/entities/auth_user.dart';

abstract class AuthRepository {
  Future<Result<AuthUser>> login({
    required String email,
    required String password,
  });

  Future<Result<AuthUser>> register({
    required String email,
    required String password,
    String? name,
  });

  Future<Result<void>> logout();

  Future<Result<AuthUser>> getCurrentUser();
}
