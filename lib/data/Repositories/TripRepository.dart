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
    var result = await _firestore.collection('trips').where(
        'date', isEqualTo: Timestamp.fromDate(date)).where('rideType', isEqualTo: rideType).get();
    for (var element in result.docs) {
      trips.add(Trip.fromJSON(element.data()));
      _database.addTrip(Trip.fromJSON(element.data()));
    }
    return trips;
  }

  Future<List<Trip>> getTripsByIdsAndStatus(List<String> ids, String status) async {
    var connection = await Connectivity().checkConnectivity();
    if(!(connection == ConnectivityResult.mobile || connection == ConnectivityResult.wifi)){
      return await _database.getTripsByIdsAndStatus(ids, status);
    }
    return await _firestore.collection('trips')
        .where('id', whereIn: ids)
        .where('status', isEqualTo: status)
        .get()
        .then((value) {
      return value.docs.map((e) => Trip.fromJSON(e.data())).toList();
    });
  }

  Future<List<Trip>> searchTrips(String userId, String rideType) async{
    ReservationRepository reservationRepository = ReservationRepository();
    List<Reservation> pastReservations = await reservationRepository.getReservations();
    List<String> pastTripsIds = pastReservations.map((e) => e.tripId).toList();
    QuerySnapshot result;
    if(pastTripsIds.isNotEmpty){
       result = await _firestore.collection('trips')
            .where('id', whereNotIn: pastTripsIds)
            .where('status', isEqualTo: 'upcoming')
            .where('rideType', isEqualTo: rideType)
            .get();
    }else{
      result = await _firestore.collection('trips')
          .where('driverId', isNotEqualTo: userId)
          .where('status', isEqualTo: 'upcoming')
          .where('rideType', isEqualTo: rideType)
          .get();
    }

    return result.docs.map((e) => Trip.fromJSON(e.data() as Map<String,dynamic>)).toList();


  }

  Future<List<Trip>> getTripsByIds(List<String> ids) async {
    var connection = await Connectivity().checkConnectivity();
    if(!(connection == ConnectivityResult.mobile || connection == ConnectivityResult.wifi)){
      return await _database.getTripsByIds(ids);
    }

    return await _firestore.collection('trips')
        .where('id', whereIn: ids)
        .get()
        .then((value) {
      return value.docs.map((e) => Trip.fromJSON(e.data())).toList();
    });
  }

  Future<void> updateTrip(Trip trip) async {
    await _firestore.collection('trips').doc(trip.id).update(trip.toJSON())
        .then((value) {
      _database.updateTrip(trip);
    });
  }


}