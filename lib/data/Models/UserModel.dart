class Student{
  String id;
  String username;
  String email;
  String phone;
  String? profilePicture;
  bool isDriver;
  String? vehicleType;
  String? vehicleModel;
  String? vehicleColor;
  String? vehiclePlates;


  Student({
    required this.id,
    required this.username,
    required this.email,
    required this.phone,
    this.profilePicture,
    required this.isDriver,
    this.vehicleType,
    this.vehicleModel,
    this.vehicleColor,
    this.vehiclePlates
  });

  Student.fromJson(Map<String, dynamic> json)
      : id = json['id'],
        username = json['username'],
        email = json['email'],
        phone = json['phone'],
        profilePicture = json['profilePicture'],
        isDriver = json['isDriver'],
        vehicleType = json['vehicleType'],
        vehicleModel = json['vehicleModel'],
        vehicleColor = json['vehicleColor'],
        vehiclePlates = json['vehiclePlates'];

  Map<String,dynamic> toJSON(){
    return {
      'id': id,
      'username': username,
      'email': email,
      'phone': phone,
      'profilePicture': profilePicture,
      'isDriver': isDriver,
      'vehicleType': vehicleType,
      'vehicleModel': vehicleModel,
      'vehicleColor': vehicleColor,
      'vehiclePlates': vehiclePlates,
    };
  }
}