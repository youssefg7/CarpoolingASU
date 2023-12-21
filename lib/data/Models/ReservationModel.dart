
class Reservation{
String? id;
String tripId;
String userId;
String status;
String paymentMethod;
String paymentStatus;

Reservation({
  this.id,
  required this.tripId,
  required this.userId,
  required this.status,
  required this.paymentMethod,
  required this.paymentStatus,
});

Reservation.fromJSON(Map<String, dynamic> json)
    : id = json['id'],
      tripId = json['tripId'],
      userId = json['userId'],
      status = json['status'],
      paymentMethod = json['paymentMethod'],
      paymentStatus = json['paymentStatus'];

Map<String, dynamic> toJSON(){
  return {
    'id': id,
    'tripId': tripId,
    'userId': userId,
    'status': status,
    'paymentMethod': paymentMethod,
    'paymentStatus': paymentStatus,
  };
}
}