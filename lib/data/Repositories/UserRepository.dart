import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../Models/UserModel.dart';

class UserRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  Student? currentUser;
  UserRepository._();
  static final UserRepository _instance = UserRepository._();

  factory UserRepository() {
    return _instance;
  }

  Future<Student?> getUser(String userId) async {
    var result = await Connectivity().checkConnectivity();
    if(result== ConnectivityResult.mobile || result == ConnectivityResult.wifi){
      DocumentSnapshot document =
      await _firestore.collection('users').doc(userId).get();
      return Student.fromJson(document.data() as Map<String, dynamic>);
    }else{
      return null;
    }
  }

  Future<Student> getCurrentUser() async{
    if(currentUser != null){
      return currentUser!;
    }
    var result = await Connectivity().checkConnectivity();
    if(result== ConnectivityResult.mobile || result == ConnectivityResult.wifi){
      DocumentSnapshot document = await _firestore.collection('users').doc(FirebaseAuth.instance.currentUser!.uid).get();
      currentUser = Student.fromJson(document.data() as Map<String, dynamic>);
      return currentUser!;
    } else {
      return await SharedPreferences.getInstance().then((prefs) {
        String json = prefs.getString('user') ?? '';
        return Student.fromJson(jsonDecode(json));
      });
      }
    }

  Future<void> setCurrentUser(Student user) async {
    // Save user to shared preferences
    await SharedPreferences.getInstance().then((prefs) {
      prefs.setString('user', jsonEncode(user.toJSON()));
    });
    currentUser = user;
  }

  Future<void> deleteCurrentUser() async {
    // Delete user from shared preferences
    await SharedPreferences.getInstance().then((prefs) {
      prefs.remove('user');
    });
  }

  Future<bool> updateCurrentUser(Student user) async {
    var result = await Connectivity().checkConnectivity();
    if(result== ConnectivityResult.mobile || result == ConnectivityResult.wifi){
      await _firestore.collection('users').doc(user.id).update(user.toJSON()).then((value) {
        setCurrentUser(user);
        return true;
      });
    }
    return false;
  }

  Future<void> createNewUser(Student user) async {
    var result = await Connectivity().checkConnectivity();
    if(result== ConnectivityResult.mobile || result == ConnectivityResult.wifi){
      await _firestore.collection('users').doc(user.id).set(user.toJSON());
    }
  }


}
