class TripModel{
  String id;
  String driverId;
  String rideType;
  String start;
  String end;
  String date;
  String status;
  String destinationLat;
  String destinationLng;
  String startLat;
  String startLng;
  int gate;
  String price;
  String distance;
  String duration;
  int passengersCount;

  TripModel({
    required this.id,
    required this.driverId,
    required this.rideType,
    required this.start,
    required this.end,
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

  TripModel.fromJSON(Map<String, dynamic> json)
      : id = json['id'],
        driverId = json['driverId'],
        rideType = json['rideType'],
        start = json['start'],
        end = json['end'],
        date = json['date'],
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
      'end': end,
      'date': date,
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
