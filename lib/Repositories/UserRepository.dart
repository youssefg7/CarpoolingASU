import '../Models/UserModel.dart';

abstract class UserRepository {
  Future<UserModel> getUserById(String id);
  Future<void> updateUser(UserModel user);
  Future<void> deleteUser();
}