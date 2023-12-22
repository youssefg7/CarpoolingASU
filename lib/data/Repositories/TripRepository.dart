import 'dart:async';

import 'package:carpool_flutter/data/Models/TripModel.dart';
import 'package:carpool_flutter/data/Repositories/ReservationRepository.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../Models/ReservationModel.dart';
import '../myDatabase.dart';

class TripRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final MyDB _database = MyDB();

  TripRepository._();

  static final TripRepository _instance = TripRepository._();

  factory TripRepository(){
    return _instance;
  }


  Future<List<Trip>> getTripsByDateAndRideType(DateTime date, String rideType) async {
    var connection = await Connectivity().checkConnectivity();
    if(!(connection == ConnectivityResult.mobile || connection == ConnectivityResult.wifi)){
      return await _database.getTripsByDateAndRideType(date, rideType);
    }
    List<Trip> trips = [];
    var result = await _firestore.collection('trips')
        .where('date', isEqualTo: Timestamp.fromDate(date))
        .where('rideType', isEqualTo: rideType)
        .get();
    for (var element in result.docs) {
      trips.add(Trip.fromJSON(element.data()));
      _database.addTrip(Trip.fromJSON(element.data()));
    }
    return orderTripsByDate(trips, false);
  }

  Future<List<Trip>> getTripsByIdsAndStatus(List<String> ids, String status) async {
    var connection = await Connectivity().checkConnectivity();
    if(!(connection == ConnectivityResult.mobile || connection == ConnectivityResult.wifi)){
      return await _database.getTripsByIdsAndStatus(ids, status);
    }
    return await _firestore.collection('trips')
        .where('id', whereIn: ids)
        .where('status', isEqualTo: status)
        .orderBy('date', descending: true)
        .get()
        .then((value) {
      return value.docs.map((e) => Trip.fromJSON(e.data())).toList();
    });
  }

  StreamController<List<Trip>> _tripsController = StreamController<List<Trip>>.broadcast();
  Stream<List<Trip>> getTripsByIdsAndStatusStream(List<String> ids, String status, String rideType) {
    _firestore.collection('trips')
        .where('id', whereNotIn: ids)
        .where('status', isEqualTo: status)
        .where('rideType', isEqualTo: rideType)
        .snapshots()
        .map((event) => event.docs.map((e) => Trip.fromJSON(e.data())).toList())
        .listen((List<Trip> trips) {
      _database.batchInsertTrips(trips);
      _tripsController.add(trips);
    });

    return _tripsController.stream;
  }



  Future<List<Trip>> getTripsByIds(List<String> ids) async {
    var connection = await Connectivity().checkConnectivity();
    if(!(connection == ConnectivityResult.mobile || connection == ConnectivityResult.wifi)){
      List<Trip> trips = await _database.getTripsByIds(ids);
      return orderTripsByDate(trips, false);
    }
    List<Trip> trips = await _firestore.collection('trips')
        .where('id', whereIn: ids)
        .get()
        .then((value) {
      return value.docs.map((e) => Trip.fromJSON(e.data())).toList();
    });
    return orderTripsByDate(trips, false);

  }

  Future<void> updateTrip(Trip trip) async {
    await _firestore.collection('trips').doc(trip.id).update(trip.toJSON())
        .then((value) {
      _database.updateTrip(trip);
    });
  }

  List<Trip> orderTripsByDate(List<Trip> trips, bool ascending){
    if(ascending) {
      trips.sort((a, b) => a.date.compareTo(b.date));
    } else {
      trips.sort((a, b) => b.date.compareTo(a.date));
    }
    return trips;
  }

}