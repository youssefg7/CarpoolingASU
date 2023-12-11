class TicketModel{
  String id;
  String userId;
  String tripId;
  String status;


TicketModel({
    required this.id,
    required this.userId,
    required this.tripId,
    required this.status,
  });

  TicketModel.fromJSON(Map<String, dynamic> json)
      : id = json['id'],
        userId = json['userId'],
        tripId = json['tripId'],
        status = json['status'];

  Map<String, dynamic> toJSON(){
    return {
      'id': id,
      'userId': userId,
      'tripId': tripId,
      'status': status,
    };
  }

}