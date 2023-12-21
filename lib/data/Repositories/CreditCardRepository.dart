import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../Models/CreditCardModel.dart';

class CreditCardRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String currentUserId = FirebaseAuth.instance.currentUser!.uid;
  CreditCardRepository._();
  static final CreditCardRepository _instance = CreditCardRepository._();

  factory CreditCardRepository(){
    return _instance;
  }

  Future<void> addCreditCard(CreditCard creditCard) async{
    DocumentReference documentReference = await _firestore.collection('creditCards').add(creditCard.toJSON());
    creditCard.id = documentReference.id;
    await _firestore.collection('creditCards').doc(documentReference.id).update(creditCard.toJSON());
  }

  Future<List<CreditCard>> getCreditCards() async{
    return await _firestore.collection('creditCards')
        .where('userId', isEqualTo: currentUserId)
        .get()
        .then((value) => value.docs.map((e) => CreditCard.fromJSON(e.data())).toList());
  }

}
