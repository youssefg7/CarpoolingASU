
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../Models/ReservationModel.dart';
import '../myDatabase.dart';

class ReservationRepository{
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final MyDB _database = MyDB();
  final String currentUserId = FirebaseAuth.instance.currentUser!.uid;

  ReservationRepository._();
  static final ReservationRepository _instance = ReservationRepository._();

  factory ReservationRepository(){
    return _instance;
  }

  Future<void> addReservation(Reservation reservation) async{
    DocumentReference documentReference = await _firestore.collection('reservations').add(reservation.toJSON());
    reservation.id = documentReference.id;
    await _firestore.collection('reservations').doc(documentReference.id).update(reservation.toJSON()).then((value) {
      _database.addReservation(reservation);
    });
  }

  Future<void> updateReservation(Reservation reservation) async{
    await _firestore.collection('reservations').doc(reservation.id).update(reservation.toJSON())
        .then((value) {
      _database.updateReservation(reservation);
    });
  }

  Future<List<Reservation>> getReservations() async{
    var connection = await Connectivity().checkConnectivity();
    if(!(connection == ConnectivityResult.mobile || connection == ConnectivityResult.wifi)){
      return await _database.getReservations();
    }
    List<Reservation> reservations = [];
    await _firestore.collection('reservations').where('userId', isEqualTo: currentUserId).get().then((value) {
      for (var element in value.docs) {
        reservations.add(Reservation.fromJSON(element.data()));
        _database.addReservation(Reservation.fromJSON(element.data()));
      }
    });
    return reservations;
  }

  Future<List<Reservation>> getReservationsByPaymentStatus(String paymentStatus) async{
    var connection = await Connectivity().checkConnectivity();
    if(!(connection == ConnectivityResult.mobile || connection == ConnectivityResult.wifi)){
      return await _database.getReservationsByPaymentStatus(paymentStatus);
    }

    return await _firestore.collection('reservations')
        .where('userId', isEqualTo: currentUserId)
        .where('paymentStatus', isEqualTo: paymentStatus)
        .get()
        .then((value){
          for (var element in value.docs) {
            _database.addReservation(Reservation.fromJSON(element.data()));
          }
          return value.docs.map((e) => Reservation.fromJSON(e.data())).toList();
    });
  }


}