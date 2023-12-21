import 'package:cloud_firestore/cloud_firestore.dart';

class Trip{
  String id;
  String driverId;
  String rideType;
  String start;
  String destination;
  DateTime date;
  String status;
  double destinationLat;
  double destinationLng;
  double startLat;
  double startLng;
  int gate;
  String price;
  String distance;
  String duration;
  int passengersCount;

  Trip({
    required this.id,
    required this.driverId,
    required this.rideType,
    required this.start,
    required this.destination,
    required this.date,
    required this.status,
    required this.destinationLat,
    required this.destinationLng,
    required this.startLat,
    required this.startLng,
    required this.gate,
    required this.price,
    required this.distance,
    required this.duration,
    required this.passengersCount,
  });

  Trip.fromJSON(Map<String, dynamic> json)
      : id = json['id'],
        driverId = json['driverId'],
        rideType = json['rideType'],
        start = json['start'],
        destination = json['destination'],
        date = json['date'].toDate(),
        status = json['status'],
        destinationLat = json['destinationLat'],
        destinationLng = json['destinationLng'],
        startLat = json['startLat'],
        startLng = json['startLng'],
        gate = json['gate'],
        price = json['price'],
        distance = json['distance'],
        duration = json['duration'],
        passengersCount = json['passengersCount'];

  Map<String, dynamic> toJSON(){
    return {
      'id': id,
      'driverId': driverId,
      'rideType': rideType,
      'start': start,
      'destination': destination,
      'date': Timestamp.fromDate(date),
      'status': status,
      'destinationLat': destinationLat,
      'destinationLng': destinationLng,
      'startLat': startLat,
      'startLng': startLng,
      'gate': gate,
      'price': price,
      'distance': distance,
      'duration': duration,
      'passengersCount': passengersCount,
    };
  }
}
