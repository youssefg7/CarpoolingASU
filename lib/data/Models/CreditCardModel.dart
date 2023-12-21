
import 'package:firebase_auth/firebase_auth.dart';

class CreditCard{
  String id;
  String userId = FirebaseAuth.instance.currentUser!.uid;
  String cardNumber;
  String cardHolderName;
  int expiryMonth;
  int expiryYear;
  String cvv;

  CreditCard({
    required this.id,
    required this.userId,
    required this.cardNumber,
    required this.cardHolderName,
    required this.expiryMonth,
    required this.expiryYear,
    required this.cvv,
  });

  CreditCard.fromJSON(Map<String, dynamic> json)
      : id = json['id'],
        userId = json['userId'],
        cardNumber = json['cardNumber'],
        cardHolderName = json['cardHolderName'],
        expiryMonth = json['expiryMonth'],
        expiryYear = json['expiryYear'],
        cvv = json['cvvCode'];

  Map<String, dynamic> toJSON(){
    return {
      'id': id,
      'userId': userId,
      'cardNumber': cardNumber,
      'cardHolderName': cardHolderName,
      'expiryMonth': expiryMonth,
      'expiryYear': expiryYear,
      'cvv': cvv,
    };
  }




}